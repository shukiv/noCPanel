#!/bin/bash

# Ensure a user is passed as an argument
if [[ -z "$1" ]]; then
    dialog --title "Error" --msgbox "No user provided. Please provide a username as an argument." 8 50
    exit 1
fi

USER="$1"
VHOST_DIR="/etc/apache2/sites-available"
ENABLED_DIR="/etc/apache2/sites-enabled"

# Check if the vhost directory exists
if [[ ! -d "$VHOST_DIR" ]]; then
    dialog --title "Error" --msgbox "The directory $VHOST_DIR does not exist." 8 50
    exit 1
fi

# Find vhost files matching the user pattern
VHOST_FILES=$(find "$VHOST_DIR" -type f -name "${USER}-*.conf" 2>/dev/null)

# Check if any vhost files were found
if [[ -z "$VHOST_FILES" ]]; then
    dialog --title "No Virtual Hosts" --msgbox "No virtual hosts found for user $USER." 8 50
    exit 0
fi

# Build the dialog menu options
VHOST_ENTRIES=()
while IFS= read -r FILE; do
    # Extract domain from the filename
    DOMAIN=$(basename "$FILE" | sed -E "s/^${USER}-(.*)\.conf$/\1/")
    VHOST_ENTRIES+=("$FILE" "$DOMAIN")
done <<< "$VHOST_FILES"

# Display a menu to select a virtual host
CHOSEN_VHOST=$(dialog --clear --title "Virtual Hosts for $USER" \
    --menu "Select a virtual host to delete:" 15 60 10 \
    "${VHOST_ENTRIES[@]}" 2>&1 >/dev/tty)

# Check if a vhost was selected
if [[ $? -ne 0 ]]; then
    clear
    echo "No action taken."
    exit 0
fi

# Extract the domain name
DOMAIN=$(basename "$CHOSEN_VHOST" | sed -E "s/^${USER}-(.*)\.conf$/\1/")

# Confirm deletion of the virtual host
dialog --title "Confirm Deletion" --yesno "Are you sure you want to delete the virtual host:\n\n$DOMAIN" 10 50
if [[ $? -eq 0 ]]; then
    # Disable the site and remove both vhost files
    sudo a2dissite "$USER-$DOMAIN" >/dev/null 2>&1
    sudo rm -f "$VHOST_DIR/$USER-$DOMAIN.conf" "$ENABLED_DIR/$USER-$DOMAIN.conf"
    sudo systemctl reload apache2

    if [[ $? -eq 0 ]]; then
        # Ask if the document root should be deleted
        DOC_ROOT="/home/$USER/$DOMAIN"
        if [[ -d "$DOC_ROOT" ]]; then
            dialog --title "Delete Document Root" --yesno "The document root folder:\n\n$DOC_ROOT\n\nexists. Do you want to delete it?" 12 50
            if [[ $? -eq 0 ]]; then
                sudo rm -rf "$DOC_ROOT"
                if [[ $? -eq 0 ]]; then
                    dialog --title "Success" --msgbox "Virtual host $DOMAIN and its document root folder were deleted successfully." 8 50
                else
                    dialog --title "Partial Success" --msgbox "Virtual host $DOMAIN deleted, but failed to delete the document root folder." 8 50
                fi
            else
                dialog --title "Document Root Retained" --msgbox "Virtual host $DOMAIN deleted, but the document root folder was not removed." 8 50
            fi
        else
            dialog --title "Success" --msgbox "Virtual host $DOMAIN was deleted successfully. No document root folder found." 8 50
        fi
    else
        dialog --title "Error" --msgbox "Failed to delete the virtual host $DOMAIN." 8 50
    fi
else
    dialog --title "Cancelled" --msgbox "Deletion cancelled." 8 40
fi

clear
exit 0

