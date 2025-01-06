#!/bin/bash

# Check if the username is provided as a command line argument
if [ -z "$1" ]; then
    echo "Error: Username is required."
    echo "Usage: $0 <username>"
    exit 1
fi

# Get the username from the command line argument
username=$1

# Check if the user exists
if ! id "$username" &>/dev/null; then
    echo "Error: User $username does not exist!"
    exit 1
fi

# Use dialog to prompt for the domain name
domain=$(dialog --title "Enter Domain Name" --inputbox "Enter the domain name for the virtual host:" 10 30 3>&1 1>&2 2>&3)

# Check if the user pressed cancel or left the field empty
if [ $? -ne 0 ] || [ -z "$domain" ]; then
    dialog --msgbox "You must enter a valid domain name!" 10 30
    exit 1
fi

# Create the document root under the user's home directory
docroot="/home/$username/$domain"
mkdir -p "$docroot"

# Set the correct ownership and permissions
chown -R "$username:$username" "$docroot"
chmod -R 755 "$docroot"

# Create the Apache virtual host configuration file
vhost_file="/etc/apache2/sites-available/$username-$domain.conf"

cat <<EOF > "$vhost_file"
<VirtualHost *:80>
    ServerAdmin webmaster@$domain
    ServerName $domain
    DocumentRoot $docroot

    <Directory $docroot>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Enable the site and reload Apache
a2ensite "$username-$domain.conf" > /dev/null
systemctl reload apache2

# Confirm success
dialog --msgbox "Virtual host for $domain has been created and enabled successfully!" 10 30
