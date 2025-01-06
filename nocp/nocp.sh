#!/bin/bash

cd /usr/local/noCPanel/nocp

# Function to display the main menu
show_main_menu() {
    while true; do
        CHOICE=$(dialog --clear --title "Main Menu" \
            --menu "Choose an option:" 15 50 4 \
            1 "List users" \
            2 "Add a new user" \
            3 "Delete a user" \
            4 "System information" \
            5 "Exit" \
            3>&1 1>&2 2>&3)

        # Exit status
        EXIT_STATUS=$?
        if [[ $EXIT_STATUS -ne 0 ]]; then
            clear
            exit 0
        fi

        case $CHOICE in
            1)
                # Run list_users.sh
                ./list_users.sh
                ;;
            2)
                # Run server_config.sh
                ./add_user.sh
                ;;
            3)
                # Run server_config.sh
                ./delete_user.sh
                ;;
            4)
                # Run list_vhosts.sh
                ./system_status.sh
                ;;
            5)
                # Exit
                clear
                exit 0
                ;;
            *)
                dialog --msgbox "Invalid choice, try again!" 8 40
                ;;
        esac
    done
}

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
    echo "Dialog is not installed. Installing it now..."
    sudo apt update && sudo apt install dialog -y
fi

# Run the main menu
show_main_menu
