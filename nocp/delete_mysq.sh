#!/bin/bash

CONFIG_FILE="/usr/local/noCPanel/mysql_db_config.conf"

# Function to load MySQL credentials from the config file
load_mysql_credentials() {
    if [[ -f $CONFIG_FILE ]]; then
        MYSQL_USER=$(awk -F= '/MYSQL_USER/ {print $2}' "$CONFIG_FILE" | tr -d ' ')
        MYSQL_PASS=$(awk -F= '/MYSQL_PASS/ {print $2}' "$CONFIG_FILE" | tr -d ' ')
    else
        echo "Error: MySQL configuration file not found at $CONFIG_FILE."
        exit 1
    fi
}

# Function to list all users within UID range 3000-4000
get_user_list() {
    awk -F: '($3 >= 3000 && $3 <= 4000) {print $1}' /etc/passwd
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
        for symlink in "$vhost_enabled_dir"/$pattern; do
            if [[ -L $symlink ]]; then
                echo "Deleting symbolic link (enabled): $symlink"
                sudo rm -f "$symlink"
            fi
        done
    fi

    # Reload Apache to apply changes
    sudo systemctl reload apache2
}

# Function to delete databases associated with a user
delete_user_databases() {
    local username=$1
    local db_prefix="user_${username}_"

    # Load MySQL credentials
    load_mysql_credentials

    echo "$MYSQL_USER $MYSQL_PASS" > debug.log

    # Get a list of databases matching the user's prefix
    DATABASES=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SHOW DATABASES LIKE '${db_prefix}%';" -s --skip-column-names)

    if [[ -z "$DATABASES" ]]; then
        echo "No databases found for user $username."
    else
        for db in $DATABASES; do
            echo "Dropping database: $db"
            mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "DROP DATABASE \`$db\`;"
        done
    fi
}

# Function to delete a user
delete_user() {
    local username=$1
    sudo deluser --remove-home "$username"
    sudo delgroup "$username"
}

# Main script
while true; do
    # Get the list of users within the UID range
    USER_LIST=$(get_user_list)

    # Check if any users are available
    if [[ -z "$USER_LIST" ]]; then
        dialog --title "Error" --msgbox "No users found with UIDs in the range 3000-4000." 8 40
        exit 1
    fi

    # Build dialog menu options dynamically
    MENU_OPTIONS=()
    for user in $USER_LIST; do
        MENU_OPTIONS+=("$user" "User with UID 3000-4000")
    done

    # Prompt the user to select a user
    USER_TO_DELETE=$(dialog --clear --title "Select User to Delete" \
        --menu "Choose a user to delete (UID 3000-4000):" 15 50 10 "${MENU_OPTIONS[@]}" 3>&1 1>&2 2>&3)

    # Exit if user presses Cancel or ESC
    if [[ $? -ne 0 ]]; then
        clear
        exit 0
    fi

    # Get the virtual hosts associated with the user
    VHOSTS=$(list_user_vhosts "$USER_TO_DELETE")

    # Show confirmation dialog
    dialog --title "Confirm Deletion" --yesno \
        "Are you sure you want to delete the user '$USER_TO_DELETE', the following virtual hosts, and their databases?\n\n$VHOSTS" 15 60

    # If the user confirms
    if [[ $? -eq 0 ]]; then
        # Delete the virtual hosts
#        delete_user_vhosts "$USER_TO_DELETE"

        # Delete the databases
        delete_user_databases "$USER_TO_DELETE"

        # Delete the user
#        delete_user "$USER_TO_DELETE"

        dialog --title "Success" --msgbox "User '$USER_TO_DELETE', associated virtual hosts, and databases have been deleted." 8 40
    else
        dialog --msgbox "Deletion cancelled." 8 40
    fi
done
