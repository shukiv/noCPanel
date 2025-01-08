#!/bin/bash

# Ensure a user is passed as an argument
if [[ -z "$1" ]]; then
    dialog --title "Error" --msgbox "No user provided. Please provide a username as an argument." 8 50
    exit 1
fi

USER="$1"
VHOST_DIR="/etc/apache2/sites-available"
ENABLED_DIR="/etc/apache2/sites-enabled"
WP_ARCHIVE="/usr/local/noCPanel/application_installer/wordpress.tar.gz"
MYSQL_SCRIPT="./mysql.sh" # Path to mysql.sh script
CONFIG_FILE="/usr/local/noCPanel/mysql_db_config.conf"

# Read MySQL credentials from the configuration file
if [ ! -f "$CONFIG_FILE" ]; then
    dialog --msgbox "MySQL configuration file not found: $CONFIG_FILE" 10 30
    exit 1
fi

source "$CONFIG_FILE"

# Check if the vhost directory exists
if [[ ! -d "$VHOST_DIR" ]]; then
    dialog --title "Error" --msgbox "The directory $VHOST_DIR does not exist." 8 50
    exit 1
fi

# Find vhost files matching the user pattern
VHOST_FILES=$(find "$VHOST_DIR" -type f -name "${USER}@*.conf" 2>/dev/null)

# Check if any vhost files were found
if [[ -z "$VHOST_FILES" ]]; then
    dialog --title "No Virtual Hosts" --msgbox "No virtual hosts found for user $USER." 8 50
    exit 0
fi

# Build the dialog menu options
VHOST_ENTRIES=()
while IFS= read -r FILE; do
    DOMAIN=$(basename "$FILE" | sed -E "s/^${USER}@(.*)\.conf$/\1/")
    VHOST_ENTRIES+=("$FILE" "$DOMAIN")
done <<< "$VHOST_FILES"

# Display a menu to select an action
CHOICE=$(dialog --clear --title "Virtual Hosts for $USER" \
    --menu "Choose an action:" 15 60 10 \
    "Delete Virtual Host" "Delete a virtual host" \
    "Install WordPress" "Install WordPress on a virtual host" 2>&1 >/dev/tty)

if [[ $? -ne 0 ]]; then
    clear
    echo "No action taken."
    exit 0
fi

if [[ "$CHOICE" == "Delete Virtual Host" ]]; then
    # Select a virtual host to delete
    CHOSEN_VHOST=$(dialog --clear --title "Virtual Hosts for $USER" \
        --menu "Select a virtual host to delete:" 15 60 10 \
        "${VHOST_ENTRIES[@]}" 2>&1 >/dev/tty)
    DOMAIN=$(basename "$CHOSEN_VHOST" | sed -E "s/^${USER}@(.*)\.conf$/\1/")

    # Confirm deletion
    dialog --title "Confirm Deletion" --yesno "Are you sure you want to delete the virtual host:\n\n$DOMAIN" 10 50
    if [[ $? -eq 0 ]]; then
        # Disable and delete virtual host
        sudo a2dissite "$USER@$DOMAIN" >/dev/null 2>&1
        sudo rm -f "$VHOST_DIR/$USER@$DOMAIN.conf" "$ENABLED_DIR/$USER@$DOMAIN.conf"
        sudo systemctl reload apache2

        DOC_ROOT="/home/$USER/$DOMAIN"
        if [[ -d "$DOC_ROOT" ]]; then
            dialog --title "Delete Document Root" --yesno "The document root folder:\n\n$DOC_ROOT\n\nexists. Do you want to delete it?" 12 50
            if [[ $? -eq 0 ]]; then
                sudo rm -rf "$DOC_ROOT"
                dialog --title "Success" --msgbox "Virtual host $DOMAIN and its document root folder were deleted successfully." 8 50
            else
                dialog --title "Document Root Retained" --msgbox "Virtual host $DOMAIN deleted, but the document root folder was not removed." 8 50
            fi
        else
            dialog --title "Success" --msgbox "Virtual host $DOMAIN was deleted successfully. No document root folder found." 8 50
        fi
    else
        dialog --title "Cancelled" --msgbox "Deletion cancelled." 8 40
    fi

elif [[ "$CHOICE" == "Install WordPress" ]]; then
    # Install WordPress Logic
    CHOSEN_VHOST=$(dialog --clear --title "Virtual Hosts for $USER" \
        --menu "Select a virtual host to install WordPress:" 15 60 10 \
        "${VHOST_ENTRIES[@]}" 2>&1 >/dev/tty)
    DOMAIN=$(basename "$CHOSEN_VHOST" | sed -E "s/^${USER}@(.*)\.conf$/\1/")
    DOC_ROOT="/home/$USER/$DOMAIN"

    if [[ ! -d "$DOC_ROOT" ]]; then
        dialog --title "Error" --msgbox "Document root $DOC_ROOT does not exist." 8 50
        exit 1
    fi

    while true; do
        # Check for existing databases for the user
        DATABASES=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SHOW DATABASES;" | grep "^user_${USER}_")

        if [[ -z "$DATABASES" ]]; then
            dialog --title "No Databases" --msgbox "No databases found for user $USER. Running database creation script." 8 50
            "$MYSQL_SCRIPT" "$USER"
        else
            DB_ENTRIES=()
            while IFS= read -r DB; do
                DB_ENTRIES+=("$DB" "")
            done <<< "$DATABASES"
            DB_ENTRIES+=("Create New" "Create a new database")
            
            SELECTED_DB=$(dialog --clear --title "Select Database" \
                --menu "Choose a database for WordPress or create a new one:" 15 60 10 \
                "${DB_ENTRIES[@]}" 2>&1 >/dev/tty)

            if [[ $? -ne 0 ]]; then
                clear
                echo "No database selected."
                exit 1
            fi

            if [[ "$SELECTED_DB" == "Create New" ]]; then
                "$MYSQL_SCRIPT" "$USER"
            else
                DB_NAME="$SELECTED_DB"
                DB_USER="$DB_NAME"
                DB_PASS=$(dialog --title "Database Password" --inputbox "Enter the password for MySQL user $DB_USER:" 10 50 3>&1 1>&2 2>&3)
                break
            fi
        fi
    done

    sudo tar -xzf "$WP_ARCHIVE" -C "$DOC_ROOT" --strip-components=1
    sudo chown -R "$USER:$USER" "$DOC_ROOT"
    sudo find "$DOC_ROOT" -type d -exec chmod 755 {} \;
    sudo find "$DOC_ROOT" -type f -exec chmod 644 {} \;

    cp "$DOC_ROOT/wp-config-sample.php" "$DOC_ROOT/wp-config.php"
    sed -i "s/'database_name_here'/'$DB_NAME'/" "$DOC_ROOT/wp-config.php"
    sed -i "s/'username_here'/'$DB_USER'/" "$DOC_ROOT/wp-config.php"
    sed -i "s/'password_here'/'$DB_PASS'/" "$DOC_ROOT/wp-config.php"

    dialog --title "Success" --msgbox "WordPress was successfully installed in $DOC_ROOT with database $DB_NAME." 8 50
fi

clear
exit 0
