#!/bin/bash

# Path to the configuration file
CONFIG_FILE="/usr/local/noCPanel/mysql_db_config.conf"

# Read MySQL credentials from the config file
if [ ! -f "$CONFIG_FILE" ]; then
    dialog --msgbox "Configuration file not found: $CONFIG_FILE" 10 30
    exit 1
fi

# Source the configuration file to get MySQL credentials
source "$CONFIG_FILE"

# Check if the credentials are valid
if [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASS" ]; then
    dialog --msgbox "MySQL credentials are not set correctly in the config file." 10 30
    exit 1
fi

# Check if the username was provided as a command line argument
if [ -z "$1" ]; then
    dialog --msgbox "No username provided. Please pass a username as a command line argument." 10 30
    exit 1
fi

SELECTED_USER="$1"

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to list databases for the selected user
list_databases() {
    SELECTED_USER=$1
    databases=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW DATABASES;" | grep "^user_${SELECTED_USER}_")

    # Check if there are databases associated with the user
    if [ -z "$databases" ]; then
        dialog --msgbox "No databases found for this user." 10 30
    else
        DB_NAME=$(dialog --title "Select a Database" --menu "Choose a database to delete:" 15 50 6 $(for db in $databases; do echo "$db $db"; done) 3>&1 1>&2 2>&3)

        if [ -n "$DB_NAME" ]; then
            confirm_delete "$SELECTED_USER" "$DB_NAME"
        else
            dialog --msgbox "No database selected." 10 30
        fi
    fi
}

# Function to ask for confirmation before deleting the database
confirm_delete() {
    SELECTED_USER=$1
    DB_NAME=$2

    # Ask for confirmation before deletion
    dialog --title "Confirm Deletion" --yesno "Are you sure you want to delete the database: $DB_NAME?" 7 50
    response=$?

    if [ $response -eq 0 ]; then
        # Perform the deletion
        mysql -u$MYSQL_USER -p$MYSQL_PASS -e "DROP DATABASE $DB_NAME;"
        dialog --msgbox "Database $DB_NAME deleted successfully." 10 30
    else
        dialog --msgbox "Database deletion canceled." 10 30
    fi
}

# Function to create a new database for the selected user
create_database() {
    SELECTED_USER=$1
    DB_NAME=$(dialog --title "Create Database" --inputbox "Enter the database name (without prefix):" 10 30 3>&1 1>&2 2>&3)

    if [ -n "$DB_NAME" ]; then
        FULL_DB_NAME="user_${SELECTED_USER}_${DB_NAME}"
        mysql -u$MYSQL_USER -p$MYSQL_PASS -e "CREATE DATABASE $FULL_DB_NAME;"
        dialog --msgbox "Database $FULL_DB_NAME created successfully." 10 30
    else
        dialog --msgbox "No database name entered." 10 30
    fi
}

# Main menu loop
while true; do
    # Show the menu for database options
    option=$(dialog --title "User: $SELECTED_USER" --menu "Choose an option" 15 50 4 \
        1 "List and Delete Databases" \
        2 "Create a New Database" \
        3 "Exit" 3>&1 1>&2 2>&3)

    case $option in
        1) list_databases "$SELECTED_USER" ;;  # List and delete databases
        2) create_database "$SELECTED_USER" ;;  # Create a new database
        3) break ;;  # Exit the script
        *) dialog --msgbox "Invalid option!" 10 30 ;;  # Invalid option handler
    esac
done

clear
