#!/bin/bash
#!/bin/bash

# Connect to the number_guess database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate a random secret number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Prompt the user for their username
echo "Enter your username:"
read USERNAME

# Check if the user already exists in the 'players' table
USER_ID=$($PSQL "SELECT user_id FROM players WHERE username='$USERNAME'")

# If the user doesn't exist, insert them into the 'players' table
if [[ -z $USER_ID ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER_RESULT=$($PSQL "INSERT INTO players(username) VALUES('$USERNAME')")
  USER_ID=$($PSQL "SELECT user_id FROM players WHERE username='$USERNAME'")
else
  # If the user exists, fetch their game statistics
  GAMES_PLAYED=$($PSQL "SELECT COUNT(game_id) FROM games WHERE user_id=$USER_ID")
  BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games WHERE user_id=$USER_ID")
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Prompt the user to start guessing the number
echo "Guess the secret number between 1 and 1000:"
GUESSES=0

while true
do
  read GUESS
  ((GUESSES++))

  # Check if the guess is a valid integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Compare the guess to the secret number
  if [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    # If the guess is correct, record the game result and congratulate the user
    echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, secret_number, number_of_guesses) VALUES($USER_ID, $SECRET_NUMBER, $GUESSES)")
    break
  fi
done
