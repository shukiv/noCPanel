#!/bin/bash

# MySQL database credentials
DB_USER="root"
DB_PASS="your_password"
DB_NAME="nocpanel"

# Function to add/update user to MySQL database
add_update_user() {
  local username=$1
  local password=$2
  local last_name=$3

  # Check if the user already exists in the database
  EXISTING_USER=$(mysql -u$DB_USER -p$DB_PASS -D$DB_NAME -se "SELECT COUNT(*) FROM users WHERE username='$username'")

  if [ "$EXISTING_USER" -eq 0 ]; then
    # User doesn't exist, insert into the database
    mysql -u$DB_USER -p$DB_PASS -D$DB_NAME -e "INSERT INTO users (username, password, last_name) VALUES ('$username', '$password', '$last_name')"
    dialog --msgbox "User $username has been added to the database." 6 40
  else
    # User exists, update the database
    mysql -u$DB_USER -p$DB_PASS -D$DB_NAME -e "UPDATE users SET password='$password', last_name='$last_name' WHERE username='$username'"
    dialog --msgbox "User $username has been updated in the database." 6 40
  fi
}

# Dialog to ask for username
USERNAME=$(dialog --title "Add/Update User" --inputbox "Enter the username:" 8 40 3>&1 1>&2 2>&3)
if [ -z "$USERNAME" ]; then
  dialog --msgbox "You must provide a username." 6 40
  exit 1
fi

# Dialog to ask for password
PASSWORD=$(dialog --title "Add/Update User" --inputbox "Enter the password:" 8 40 3>&1 1>&2 2>&3)
if [ -z "$PASSWORD" ]; then
  dialog --msgbox "You must provide a password." 6 40
  exit 1
fi

# Dialog to ask for last name
LAST_NAME=$(dialog --title "Add/Update User" --inputbox "Enter the last name:" 8 40 3>&1 1>&2 2>&3)
if [ -z "$LAST_NAME" ]; then
  dialog --msgbox "You must provide a last name." 6 40
  exit 1
fi

# Call the function to add/update the user in the database
add_update_user "$USERNAME" "$PASSWORD" "$LAST_NAME"
