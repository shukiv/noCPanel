#!/bin/bash

# Ensure the user_main.sh script is executable
if [[ ! -x ./user_main.sh ]]; then
    echo "Error: user_main.sh script is not found or not executable."
    exit 1
fi

# Get all normal users (users with a home directory)
USER_LIST=$(awk -F: '/\/home\// {print $1}' /etc/passwd)

# Check if any users exist
if [[ -z "$USER_LIST" ]]; then
    dialog --title "Error" --msgbox "No users found with home directories." 8 40
    exit 1
fi

# Convert user list to a dialog-friendly format
USER_ENTRIES=()
while read -r user; do
    USER_ENTRIES+=("$user" "$user")
done <<< "$USER_LIST"

# Display the user selection menu
USER=$(dialog --clear --title "Select User" --menu "Choose a user to manage:" 15 50 10 "${USER_ENTRIES[@]}" 2>&1 >/dev/tty)

# Check if a user was selected
if [[ $? -eq 0 ]]; then
    clear
    # Call the user_main.sh script with the selected username
    ./user_main.sh "$USER"
else
    clear
    echo "No user selected."
    exit 1
fi
