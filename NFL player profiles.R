
library(tidyverse)
library(nflreadr)
library(ggrepel)
library(scales)
library(rlang)


season <- 2024


ngs_pass <- load_nextgen_stats(seasons = season, stat_type = "passing")
ngs_rec  <- load_nextgen_stats(seasons = season, stat_type = "receiving")
ngs_rush <- load_nextgen_stats(seasons = season, stat_type = "rushing")

pass_szn <- ngs_pass %>% filter(week == 0)
rec_szn  <- ngs_rec  %>% filter(week == 0)
rush_szn <- ngs_rush %>% filter(week == 0)


qb_min_att  <- 200 
wr_min_tgts <- 100
rb_min_att  <- 100
te_min_tgts <- 50

qb <- pass_szn %>%
  select(
    NAME = player_display_name,
    POS  = player_position,
    IAY  = avg_intended_air_yards,
    TTT  = avg_time_to_throw,
    ATT  = attempts,
    CPOE = completion_percentage_above_expectation
  )

rec <- rec_szn %>%
  select(
    NAME  = player_display_name,
    POS   = player_position,
    AIAY  = avg_intended_air_yards,
    YACOE = avg_yac_above_expectation,
    SEP = avg_separation,
    TGT   = targets,
    PCT_IAY = percent_share_of_intended_air_yards,
    CAT_PCT = catch_percentage
  )

rb <- rush_szn %>%
  select(
    NAME    = player_display_name,
    POS     = player_position,
    EFF     = efficiency,
    RYOE_PA = rush_yards_over_expected_per_att,
    RATT    = rush_attempts
  )

# ---- helpers to avoid zero-dimension plot errors ----
add_smooth_if <- function(df) if (nrow(df) >= 1) geom_smooth(method = "lm", se = FALSE, linetype = 2) else NULL
add_labels_if <- function(df, aes_map) if (nrow(df) >= 1) ggrepel::geom_text_repel(aes_map, max.overlaps = 25) else NULL
print_or_note <- function(df, plot_expr) if (nrow(df) == 0) message("No rows after filtering.") else print(plot_expr)

#QB Plot — Intended Air YDs vs Time to Throw
qb_df <- qb %>% filter(POS == "QB", !is.na(IAY), !is.na(TTT), ATT >= qb_min_att)
qb_plot <- ggplot(qb_df, aes(IAY, TTT)) +
  geom_point(aes(size = ATT, color = CPOE), alpha = 0.7) +
  add_smooth_if(qb_df) +
  add_labels_if(qb_df, aes(label = NAME)) +
  scale_color_gradient2(low = "blue", mid = "grey", high = "red", midpoint = 0, name = "CPOE") +
  labs(title = paste0(season, " QBs: Intended Air Yards vs Time to Throw"),
       x = "Intended Air Yards", y = "Time to Throw (s)", size = "Attempts") +
  theme_minimal()
print_or_note(qb_df, qb_plot)

#WR Plot — AIAY vs YACOE
wr_df <- rec %>% filter(POS == "WR", !is.na(AIAY), !is.na(YACOE), TGT >= wr_min_tgts)
wr_plot <- ggplot(wr_df, aes(AIAY, YACOE, size = TGT)) +
  geom_point(aes(color = SEP),alpha = 0.7) +
  geom_hline(yintercept = 0.5, linetype = 3) +
  add_smooth_if(wr_df) +
  add_labels_if(wr_df, aes(label = NAME)) +
  scale_color_gradient2(low = "blue", mid = "grey", high = "red", midpoint = 3, name = "AVG Separation(YDS)")+
  labs(title = paste0(season, " WR: Average Intended Air Yards vs YAC Over Expected"),
       x = "Average Intended Air Yards", y = "Yards After Catch Over Expected", size = "Targets") +
  theme_minimal()
print_or_note(wr_df, wr_plot)


#Tight end plot - ADOT vs YACOE
te_df <- rec %>% filter(POS == "TE", !is.na(AIAY), !is.na(YACOE), TGT >= te_min_tgts)
te_plot <- ggplot(te_df, aes(AIAY, YACOE)) +
  geom_point(aes(size = TGT, color = SEP), alpha = 0.7) +
  geom_hline(yintercept = 0.5, linetype = 3) +
  add_smooth_if(te_df) +
  add_labels_if(te_df, aes(label = NAME)) +
  scale_color_gradient2(low = "blue", mid= "grey", high ="red",midpoint = 3.5,)+
  labs(title = paste0(season, " TE: Average Intended Air Yards vs YAC Over Expected"),
       x = "Average Intended Air Yards", y = "Yards After Catch Over Expected", size = "Targets") +
  theme_minimal()
print_or_note(te_df, te_plot)

#RB Plot — Efficiency vs Rush Yards Over Expected per Attempt
rb_df <- rb %>% filter(POS == "RB", !is.na(EFF), !is.na(RYOE_PA), RATT >= rb_min_att)
rb_plot <- ggplot(rb_df, aes(EFF, RYOE_PA, size = RATT)) +
  geom_point(alpha = 0.7) +
  add_smooth_if(rb_df) +
  add_labels_if(rb_df, aes(label = NAME)) +
  labs(title = paste0(season, " RBs: Rushing Efficiency vs RYOE per Attempt"),
       x = "Efficiency (yds traveled per yard gained — lower is better)",
       y = "RYOE per Attempt", size = "Rush Attempts") +
  theme_minimal()
print_or_note(rb_df, rb_plot)



# Check Col names if needed 
list(passing_cols = names(pass_szn), receiving_cols = names(rec_szn), rushing_cols = names(rush_szn))

