#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=postgres -t --no-align -c"

# Generate random number between 0 and 1000
SECRET_NUMBER=$(( ( RANDOM % 1000 ) + 0 ))

# Initialize guess count
GUESSES=0

# Prompt for username
echo -e "Enter your username:"
read NAME

# Check if the user exists in the database
USER_DATA=$($PSQL "SELECT username, games_played, best_game FROM games WHERE username='$NAME'")

# If user doesn't exist, welcome them as a new user
if [[ -z $USER_DATA ]]; then
  echo "Welcome, $NAME! It looks like this is your first time here."

  # Insert the new user into the database with default values
  $PSQL "INSERT INTO games(username, games_played, best_game) VALUES ('$NAME', 1, 1000)"
  GAMES_PLAYED=1
  BEST_GAME=1000

else
  # Parse the retrieved data for returning users
  IFS="|" read USERNAME GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  
  # Increment games played
  ((GAMES_PLAYED++))

  # Update games played in the database
  $PSQL "UPDATE games SET games_played=$GAMES_PLAYED WHERE username='$USERNAME'"

  # Welcome back message with games played and best game stats
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Prompt the user to guess the secret number
echo -e "Guess the secret number between 1 and 1000:"

# Loop to keep asking for guesses until the user guesses correctly
while true; do
  read GUESS

  # Increment guess count
  ((GUESSES++))

  # Validate input (ensure it's an integer)
  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo -e "That is not an integer, guess again:"
  else
    # Provide hints and guidance for guesses
    if [[ $GUESS -lt $SECRET_NUMBER ]]; then
      echo -e "It's higher than that, guess again:"
    elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
      echo -e "It's lower than that, guess again:"
    else
      # Correct guess! Check if it's the best game
      if [[ $GUESSES -lt $BEST_GAME ]]; then
        # Update the best game in the database if current game is better
        $PSQL "UPDATE games SET best_game=$GUESSES WHERE username='$USERNAME'"
      fi

      # Display the success message
      echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
      exit
    fi
  fi
done
