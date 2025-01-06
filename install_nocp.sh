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
#!/bin/bash

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

# Display the random password
echo "MySQL root password has been set to: ${ROOT_PASSWORD}"

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

# Finish
echo "Installation is complete"
echo "You can access your panel by typing: nocp"
echo "Root password: ${ROOT_PASSWORD}" > /root/mysql_root_password.txt
chmod 600 /root/mysql_root_password.txt
echo "The root password has been saved to /root/mysql_root_password.txt (secure file)."
