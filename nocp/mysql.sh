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
if [ -z "$MYSQL_USER" ]; then
    dialog --msgbox "MySQL username is not set correctly in the config file." 10 30
    exit 1
fi

# Prompt for the MySQL password if not set
if [ -z "$MYSQL_PASS" ]; then
    MYSQL_PASS=$(dialog --title "MySQL Password" --inputbox "Enter the MySQL password or leave blank to auto-generate one:" 10 50 3>&1 1>&2 2>&3)
    if [ -z "$MYSQL_PASS" ]; then
        MYSQL_PASS=$(openssl rand -base64 12)
        dialog --msgbox "Auto-generated MySQL password: $MYSQL_PASS" 10 50
    fi
fi

# Check if the username was provided as a command line argument
if [ -z "$1" ]; then
    dialog --msgbox "No username provided. Please pass a username as a command line argument." 10 30
    exit 1
fi

SELECTED_USER="$1"

# Function to list MySQL users for the selected Linux user
list_mysql_users() {
    SELECTED_USER=$1
    mysql_users=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SELECT User FROM mysql.user WHERE User LIKE '${SELECTED_USER}_%';" | grep "${SELECTED_USER}_")

    if [ -z "$mysql_users" ]; then
        dialog --msgbox "No MySQL users found for Linux user: $SELECTED_USER" 10 30
    else
        dialog --title "MySQL Users for $SELECTED_USER" --msgbox "MySQL Users:\n$mysql_users" 15 50
    fi
}

# Function to list databases for the selected user
list_databases() {
    SELECTED_USER=$1
    databases=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SHOW DATABASES;" | grep "^user_${SELECTED_USER}_")

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

# Function to ask for confirmation before deleting the database and its associated user
confirm_delete() {
    SELECTED_USER=$1
    DB_NAME=$2

    # Ask for confirmation before deletion
    dialog --title "Confirm Deletion" --yesno "Are you sure you want to delete the database: $DB_NAME and its associated user?" 7 50
    response=$?

    if [ $response -eq 0 ]; then
        # Delete the database
        mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "DROP DATABASE $DB_NAME;"
        if [ $? -eq 0 ]; then
            dialog --msgbox "Database $DB_NAME deleted successfully." 10 30
        else
            dialog --msgbox "Failed to delete the database: $DB_NAME." 10 30
            return
        fi

        # Determine the associated MySQL user (assumes naming convention)
        DB_USER="${SELECTED_USER}_dbuser"

        # Delete the associated MySQL user
        mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "DROP USER '$DB_USER'@'localhost';"
        if [ $? -eq 0 ]; then
            dialog --msgbox "MySQL user $DB_USER deleted successfully." 10 30
        else
            dialog --msgbox "Failed to delete the MySQL user: $DB_USER." 10 30
        fi
    else
        dialog --msgbox "Database deletion canceled." 10 30
    fi
}

# Function to create a new database and MySQL user for the selected user
create_database_and_user() {
    SELECTED_USER=$1
    DB_NAME=$(dialog --title "Create Database" --inputbox "Enter the database name (without prefix):" 10 30 3>&1 1>&2 2>&3)

    if [ -n "$DB_NAME" ]; then
        FULL_DB_NAME="user_${SELECTED_USER}_${DB_NAME}"
        DB_USER="${SELECTED_USER}_dbuser"
        DB_PASS=$(dialog --title "MySQL User Password" --inputbox "Enter the MySQL user password or leave blank to auto-generate one:" 10 50 3>&1 1>&2 2>&3)
        if [ -z "$DB_PASS" ]; then
            DB_PASS=$(openssl rand -base64 12)
            dialog --msgbox "Auto-generated password for MySQL user $DB_USER: $DB_PASS" 10 50
        fi

        mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "CREATE DATABASE $FULL_DB_NAME;"
        mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
        mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "GRANT ALL PRIVILEGES ON $FULL_DB_NAME.* TO '$DB_USER'@'localhost';"
        mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "FLUSH PRIVILEGES;"

        dialog --msgbox "Database and user created successfully.\n\nDatabase: $FULL_DB_NAME\nUser: $DB_USER\nPassword: $DB_PASS" 15 50
    else
        dialog --msgbox "No database name entered." 10 30
    fi
}

# Main menu loop
while true; do
    option=$(dialog --title "User: $SELECTED_USER" --menu "Choose an option" 15 50 6 \
        1 "List MySQL Users" \
        2 "List and Delete Databases" \
        3 "Create a New Database" \
        4 "Create a Database and MySQL User" \
        5 "Exit" 3>&1 1>&2 2>&3)

    case $option in
        1) list_mysql_users "$SELECTED_USER" ;;
        2) list_databases "$SELECTED_USER" ;;
        3) create_database "$SELECTED_USER" ;;
        4) create_database_and_user "$SELECTED_USER" ;;
        5) break ;;
        *) dialog --msgbox "Invalid option!" 10 30 ;;
    esac
done

clear
