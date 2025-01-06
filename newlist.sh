#!/bin/bash

# Ensure a user and domain are provided as arguments
if [[ -z "$1" ]]; then
    dialog --title "Error" --msgbox "No user provided. Please provide a username as an argument." 8 50
    exit 1
fi

USER="$1"
VHOST_DIR="/etc/apache2/sites-available"

# Prompt for the domain name
DOMAIN=$(dialog --title "Add Virtual Host" --inputbox "Enter the domain name to add (e.g., example.com):" 10 50 3>&1 1>&2 2>&3)

# Check if the input was cancelled or empty
if [[ $? -ne 0 || -z "$DOMAIN" ]]; then
    dialog --title "Cancelled" --msgbox "Domain addition cancelled." 8 50
    exit 0
fi

# Check if the domain configuration already exists
CONF_FILE="${VHOST_DIR}/${USER}_${DOMAIN}.conf"
if [[ -f "$CONF_FILE" ]]; then
    dialog --title "Error" --msgbox "The virtual host for $DOMAIN already exists at $CONF_FILE." 8 50
    exit 1
fi

# Create the document root
DOC_ROOT="/home/$USER/$DOMAIN"
sudo mkdir -p "$DOC_ROOT"
sudo chown "$USER:$USER" "$DOC_ROOT"
sudo chmod 755 "$DOC_ROOT"

# Create the virtual host configuration
sudo tee "$CONF_FILE" >/dev/null <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot $DOC_ROOT
    <Directory $DOC_ROOT>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Enable the site and reload Apache
sudo a2ensite "${USER}_${DOMAIN}.conf" >/dev/null 2>&1
sudo systemctl reload apache2

# Confirm success
if [[ $? -eq 0 ]]; then
    dialog --title "Success" --msgbox "Virtual host $DOMAIN created successfully." 8 50
else
    dialog --title "Error" --msgbox "Failed to create virtual host for $DOMAIN." 8 50
fi
