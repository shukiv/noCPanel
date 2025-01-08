#!/bin/bash

# Ensure the user_main.sh script is executable
if [[ ! -x ./user_main.sh ]]; then
    echo "Error: user_main.sh script is not found or not executable."
    exit 1
fi

# Get users with UIDs in the range 3000-4000
USER_LIST=$(awk -F: '($3 >= 3000 && $3 <= 4000) {print $1}' /etc/passwd)

# Check if any users exist in the specified range
if [[ -z "$USER_LIST" ]]; then
    dialog --title "Error" --msgbox "No users found with UIDs in the range 3000-4000." 8 40
    exit 1
fi

# Convert user list to a dialog-friendly format
USER_ENTRIES=()
while read -r user; do
    USER_ENTRIES+=("$user" "$user")
done <<< "$USER_LIST"

# Display the user selection menu
USER=$(dialog --clear --title "Select User" --menu "Choose a user to manage (UID 3000-4000):" 15 50 10 "${USER_ENTRIES[@]}" 2>&1 >/dev/tty)

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

