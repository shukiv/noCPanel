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

# Generate a random password
ROOT_PASSWORD=$(openssl rand -base64 12)

# Run MySQL commands
mysql --user=root <<EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Disallow root login remotely
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Reload privilege tables
FLUSH PRIVILEGES;
EOF

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

# Get the package
git clone https://github.com/shukiv/noCPanel/
mv noCPanel/ /usr/local/
ln -s /usr/local/noCPanel/nocp/nocp.sh /usr/bin/nocp

# Finish
echo "Installation is complete"
echo "You can access your panel by typing: nocp"

# Display the mysql random password and write to file
echo "MySQL root password has been set to: ${ROOT_PASSWORD}"
echo "Root password: ${ROOT_PASSWORD}" > /root/mysql_root_password.txt
echo "MYSQL_USER="root" MYSQL_PASS="${ROOT_PASSWORD}"" > /usr/local/noCPanel/mysql_db_config.conf
chmod 600 /root/mysql_root_password.txt
# echo "The root password has been saved to /root/mysql_root_password.txt (secure file)."
