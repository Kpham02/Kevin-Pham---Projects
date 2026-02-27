from nba_api.stats.endpoints import playergamelog
from nba_api.stats.static import players
from sklearn.linear_model import LinearRegression
import matplotlib.pyplot as plt
import pandas as pd


# Ask for player input and search for player
player_name = input("Enter player name: ")
search = players.find_players_by_full_name(player_name)
if not search:
    print("Player not found. Try Again")
    exit()

player = search[0]
player_id = player['id']
full_name = player['full_name']

# Load season regular season game log
season = '2025-26' #Change Season
gamelog = playergamelog.PlayerGameLog(player_id=player_id, season=season, season_type_all_star='Regular Season')
df = gamelog.get_data_frames()[0]

# Convert and sort dates so most recent games come first
df['GAME_DATE'] = pd.to_datetime(df['GAME_DATE'], format='%b %d, %Y')
df = df.sort_values('GAME_DATE', ascending=False)

# Reformat match up display
df['OPPONENT'] = df['MATCHUP'].apply(lambda x: x.split(' ')[-1])
df['HOME_AWAY'] = df['MATCHUP'].apply(lambda x: x.split(' ')[1])
df['MATCHUP'] = df['HOME_AWAY'] + ' ' + df['OPPONENT']

# Add combined steals and blocks column
df['STL/BLK'] = df['STL'] + df['BLK']

# Select columns for display
display_df = df[['GAME_DATE', 'MATCHUP', 'MIN', 'PTS', 'REB', 'AST', 'FG_PCT', 'FGA', 'FG3_PCT', 'FG3A', 'TOV', 'STL/BLK']]


# Rename columns for display
display_df = display_df.rename(columns={
    'GAME_DATE': 'Date',
    'MATCHUP': 'Matchup',
    'MIN': 'Min',
    'PTS': 'Pts',
    'REB': 'Reb',
    'AST': 'Ast',
    'TOV': 'TO',
    'STL/BLK': 'STL/BLK'
})

# Reformat date for display
display_df['Date'] = display_df['Date'].dt.strftime('%m/%d')

# Print last 10 game box scores
print(f"\nLast 10 regular season games for {full_name} ({season}):\n")
print(display_df.head(10).to_string(index=False))

# Reset data frame for regression
df = df.iloc[::-1].reset_index(drop=True)
df['GAME_NUM'] = range(1, len(df) + 1)

# Define features and targets
X = df[['GAME_NUM']]
targets = ['MIN', 'PTS', 'REB', 'AST', 'STL/BLK']
predictions = {}

for stat in targets:
    y = df[stat]
    model = LinearRegression()
    model.fit(X, y)

    next_game_num = pd.DataFrame({'GAME_NUM': [df['GAME_NUM'].max() + 1]})
    pred_value = model.predict(next_game_num)[0]
    predictions[stat] = round(pred_value, 1)

# Display predicted stat line
print("\nPredicted Next Game Stat Line:")
print(f"Minutes: {predictions['MIN']} | Points: {predictions['PTS']} | Rebounds: {predictions['REB']} | Assists: {predictions['AST']} | STL/BLK: {predictions['STL/BLK']}")

# Getting data from last 10 games for plotting
plot_df = df.tail(10).copy()
plot_df['LABEL'] = plot_df['GAME_DATE'].dt.strftime('%m/%d') + ' ' + df['MATCHUP'].tail(10).values

# Add predicted game with label "Next Game"
next_game = {
    'LABEL': 'Next Game',
    'PTS': predictions['PTS'],
    'REB': predictions['REB'],
    'AST': predictions['AST']
}
#Combine next game and plot df
plot_df = pd.concat([
    plot_df[['LABEL', 'PTS', 'REB', 'AST']],
    pd.DataFrame([next_game])
], ignore_index=True)

#Plotting Data
plt.figure(figsize=(10, 6))
plt.plot(plot_df['LABEL'], plot_df['PTS'], marker='o', label='Points')
plt.plot(plot_df['LABEL'], plot_df['REB'], marker='s', label='Rebounds')
plt.plot(plot_df['LABEL'], plot_df['AST'], marker='^', label='Assists')

plt.title(f"{full_name} - Last 10 Games + Predicted Stats")
plt.xlabel("Game Date + Opponent")
plt.legend()
plt.grid(True)
plt.xticks(rotation=25)
plt.tight_layout()
plt.show()