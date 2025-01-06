#!/bin/bash

# Ensure a user is passed as an argument
if [[ -z "$1" ]]; then
    dialog --title "Error" --msgbox "No user provided." 8 40
    exit 1
fi

USER="$1"

# Check if the required scripts are available
if [[ ! -x ./add_vhost.sh || ! -x ./list_vhost.sh ]]; then
    dialog --title "Error" --msgbox "Required scripts add_vhost.sh or list_vhost.sh not found or not executable." 8 60
    exit 1
fi

# Main menu options
while true; do
    CHOICE=$(dialog --clear --title "Manage User: $USER" \
        --menu "Choose an action for $USER:" 15 50 10 \
        1 "Add Virtual Host" \
        2 "List Virtual Hosts" \
	3 "Databases" \
        4 "Exit" \
        2>&1 >/dev/tty)

    clear

    case "$CHOICE" in
        1) 
            # Call add_vhost.sh with the user
            ./add_vhost.sh "$USER"
            ;;
        2) 
            # Call list_vhost.sh with the user
            ./list_vhost.sh "$USER"
            ;;
        3) 
            # Call list_vhost.sh with the user
            ./mysql.sh "$USER"
            ;;
        4) 
            # Exit the menu
            exit 0
            ;;
        *)
            # Handle unexpected input
            dialog --title "Error" --msgbox "Invalid choice. Please try again." 8 40
            ;;
    esac
done
