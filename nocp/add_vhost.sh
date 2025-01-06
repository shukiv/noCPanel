#!/bin/bash

# Ensure a user is provided as an argument
if [[ -z "$1" ]]; then
    dialog --title "Error" --msgbox "No user provided. Please provide a username as an argument." 8 50
    exit 1
fi

USER="$1"
VHOST_DIR="/etc/apache2/sites-available"

# Prompt for the domain name
DOMAIN=$(dialog --title "Add Virtual Host" --inputbox "Enter the domain name (e.g., example.com):" 10 50 3>&1 1>&2 2>&3)

# Check if the input was cancelled or empty
if [[ $? -ne 0 || -z "$DOMAIN" ]]; then
    dialog --title "Cancelled" --msgbox "Domain addition cancelled." 8 50
    exit 0
fi

# Check if the domain configuration already exists for any user
CONF_FILE=$(find "$VHOST_DIR" -type f -name "*-${DOMAIN}.conf" 2>/dev/null)
if [[ -n "$CONF_FILE" ]]; then
    dialog --title "Error" --msgbox "The virtual host for $DOMAIN already exists in:\n\n$CONF_FILE" 10 50
    exit 1
fi

# Create the document root under the user's home directory
DOC_ROOT="/home/$USER/$DOMAIN"
sudo mkdir -p "$DOC_ROOT"
sudo chown "$USER:$USER" "$DOC_ROOT"
sudo chmod 755 "$DOC_ROOT"

# Test Apache & PHP by creating a PHP info page
echo "Creating index page..."
echo "<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>noCPanel - Under Construction</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            text-align: center;
            background-color: #f9f9f9;
            color: #333;
        }
        .container {
            margin-top: 20vh;
        }
        h1 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
        }
        img {
            max-width: 200px;
            margin: 1rem 0;
        }
        p {
            font-size: 1.2rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>${DOMAIN}<h1>
        <img src="construction-site.png" alt="Under Construction">
	<?php phpinfo(INFO_GENERAL); ?>
        <p>Coming Soon!</p>
    </div>
</body>
</html>" | sudo tee "$DOC_ROOT"/index.php > /dev/null
sudo chown "$USER:$USER" "$DOC_ROOT"/index.php > /dev/null

# Create the virtual host configuration
NEW_CONF_FILE="${VHOST_DIR}/${USER}@${DOMAIN}.conf"
sudo tee "$NEW_CONF_FILE" >/dev/null <<EOF
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
sudo a2ensite "${USER}@${DOMAIN}.conf" >/dev/null 2>&1
sudo systemctl reload apache2

# Confirm success
if [[ $? -eq 0 ]]; then
    dialog --title "Success" --msgbox "Virtual host for $DOMAIN created successfully." 8 50
else
    dialog --title "Error" --msgbox "Failed to create virtual host for $DOMAIN." 8 50
fi
