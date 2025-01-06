#!/bin/bash

# Prompt for the username
USERNAME=$(dialog --title "Add User" --inputbox "Enter the username to add:" 10 40 3>&1 1>&2 2>&3)

# Check if the input was cancelled or empty
if [[ $? -ne 0 || -z "$USERNAME" ]]; then
    dialog --title "Error" --msgbox "You must enter a valid username!" 8 40
    exit 1
fi

# Check if the user already exists
if id "$USERNAME" &>/dev/null; then
    dialog --title "Error" --msgbox "The user $USERNAME already exists!" 8 40
    exit 1
fi

# Prompt for the password
PASSWORD=$(dialog --title "Add User" --passwordbox "Enter the password for $USERNAME:" 10 40 3>&1 1>&2 2>&3)

# Check if the input was cancelled or empty
if [[ $? -ne 0 || -z "$PASSWORD" ]]; then
    dialog --title "Error" --msgbox "You must enter a valid password!" 8 40
    exit 1
fi

# Create the user using adduser
sudo adduser --disabled-password --gecos "" "$USERNAME"
sudo adduser www-data "$USERNAME"
sudo chmod 750 /home/"$USERNAME"

if [[ $? -ne 0 ]]; then
    dialog --title "Error" --msgbox "Failed to create the user $USERNAME!" 8 40
    exit 1
fi

# Set the user's password
echo "$USERNAME:$PASSWORD" | sudo chpasswd
if [[ $? -eq 0 ]]; then
    dialog --title "Success" --msgbox "User $USERNAME has been created successfully!" 8 40
else
    dialog --title "Error" --msgbox "Failed to set the password for $USERNAME!" 8 40
fi
