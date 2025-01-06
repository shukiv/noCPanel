#!/bin/bash

#apt-get purge dialog apache2 mysql-server php php-mysql libapache2-mod-php php-cli php-common php-mbstring php-xml php-json php-zip

# Update the system
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Install Base Packages
echo "Installing base packages..."
sudo apt install dialog -y

# Install Apache2
echo "Installing Apache2..."
sudo apt install apache2 -y

# Enable Apache2 to start on boot
sudo systemctl enable apache2
sudo systemctl start apache2

# Install MySQL
echo "Installing MySQL..."
sudo apt install mariadb-server -y

# Automate MySQL secure installation
echo "Securing MySQL installation..."
sudo mysql_secure_installation

# Install PHP
echo "Installing PHP and required extensions..."
sudo apt install php php-mysql libapache2-mod-php php-cli php-common php-mbstring php-xml php-json php-zip -y

# Enable mod_rewrite for Apache
echo "Enabling mod_rewrite and other conf for Apache..."
sudo a2enmod rewrite
sudo systemctl restart apache2

# Test Apache & PHP by creating a PHP info page
echo "Creating PHP info page..."
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php > /dev/null

# Restart Apache to apply changes
echo "Restarting Apache..."
sudo systemctl restart apache2

# Output installation details
echo "LAMP stack installation completed!"
echo "You can test the setup by accessing the following URL: http://localhost/info.php"

# Clean up
echo "Cleaning up..."
sudo apt autoremove -y
