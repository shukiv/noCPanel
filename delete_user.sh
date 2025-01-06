#!/bin/bash

# Function to list all users with home directories
get_user_list() {
    awk -F: '/\/home\// {print $1}' /etc/passwd
}

# Function to list virtual hosts associated with a user
list_user_vhosts() {
    local username=$1
    local vhost_dir="/etc/apache2/sites-available"
    local pattern="${username}@*.conf"

    if [[ -d $vhost_dir ]]; then
        ls "$vhost_dir"/$pattern 2>/dev/null || echo "None"
    else
        echo "None"
    fi
}

# Function to delete the user's virtual hosts
delete_user_vhosts() {
    local username=$1
    local vhost_available_dir="/etc/apache2/sites-available"
    local vhost_enabled_dir="/etc/apache2/sites-enabled"
    local pattern="${username}@*.conf"

    # Delete from sites-available
    if [[ -d $vhost_available_dir ]]; then
        for vhost_file in "$vhost_available_dir"/$pattern; do
            if [[ -f $vhost_file ]]; then
                echo "Deleting virtual host (available): $vhost_file"
                sudo rm -f "$vhost_file"
            fi
        done
    fi

    # Delete from sites-enabled
    if [[ -d $vhost_enabled_dir ]]; then
        for vhost_file in "$vhost_enabled_dir"/$pattern; do
            if [[ -f $vhost_file ]]; then
                echo "Deleting virtual host (enabled): $vhost_file"
                sudo rm -f "$vhost_file"
            fi
        done
    fi

    # Reload Apache to apply changes
    sudo systemctl reload apache2
}

# Function to delete a user
delete_user() {
    local username=$1
    sudo deluser --remove-home "$username"
    sudo delgroup "$username"
}

# Main script
while true; do
    # Get the list of users with home directories
    USER_LIST=$(get_user_list)

    # Check if any users are available
    if [[ -z "$USER_LIST" ]]; then
        dialog --title "Error" --msgbox "No users found with home directories." 8 40
        exit 1
    fi

    # Build dialog menu options dynamically
    MENU_OPTIONS=()
    for user in $USER_LIST; do
        MENU_OPTIONS+=("$user" "User with home directory")
    done

    # Prompt the user to select a user
    USER_TO_DELETE=$(dialog --clear --title "Select User to Delete" \
        --menu "Choose a user to delete:" 15 50 10 "${MENU_OPTIONS[@]}" 3>&1 1>&2 2>&3)

    # Exit if user presses Cancel or ESC
    if [[ $? -ne 0 ]]; then
        clear
        exit 0
    fi

    # Get the virtual hosts associated with the user
    VHOSTS=$(list_user_vhosts "$USER_TO_DELETE")

    # Show confirmation dialog
    dialog --title "Confirm Deletion" --yesno \
        "Are you sure you want to delete the user '$USER_TO_DELETE' and the following virtual hosts?\n\n$VHOSTS" 15 60

    # If the user confirms
    if [[ $? -eq 0 ]]; then
        # Delete the virtual hosts
        delete_user_vhosts "$USER_TO_DELETE"

        # Delete the user
        delete_user "$USER_TO_DELETE"

        dialog --title "Success" --msgbox "User '$USER_TO_DELETE' and associated virtual hosts have been deleted." 8 40
    else
        dialog --msgbox "Deletion cancelled." 8 40
    fi
done
