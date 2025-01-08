#!/bin/bash

echo "Starting the uninstallation of noCPanel and its dependencies..."

# Stop and disable Apache2
echo "Stopping and disabling Apache2..."
sudo systemctl stop apache2
sudo systemctl disable apache2

# Stop and disable MySQL/MariaDB
echo "Stopping and disabling MySQL/MariaDB..."
sudo systemctl stop mariadb
sudo systemctl disable mariadb

# Remove installed packages
echo "Removing installed packages..."
sudo apt-get purge -y dialog apache2 mariadb-server php php-mysql libapache2-mod-php php-cli php-common php-mbstring php-xml php-json php-zip

# Install ceretbot and it's Cloudflare plugin
sudo apt-get purge -y certbot python3-certbot-dns-cloudflare python3-certbot-apache

# Clean up autoremove
echo "Cleaning up unused packages..."
sudo apt-get autoremove -y
sudo apt-get autoclean -y

# Remove noCPanel directory and symbolic link
TARGET_DIR="/usr/local/noCPanel"
SYMLINK="/usr/bin/nocp"

echo "Removing noCPanel directory and files..."
if [ -d "$TARGET_DIR" ]; then
    sudo rm -rf "$TARGET_DIR"
    echo "Removed $TARGET_DIR"
else
    echo "$TARGET_DIR does not exist, skipping..."
fi

echo "Removing symbolic link $SYMLINK..."
if [ -L "$SYMLINK" ]; then
    sudo rm -f "$SYMLINK"
    echo "Removed symbolic link $SYMLINK"
else
    echo "Symbolic link $SYMLINK does not exist, skipping..."
fi

# Remove PHP info page
INFO_PAGE="/var/www/html/info.php"
echo "Removing PHP info page..."
if [ -f "$INFO_PAGE" ]; then
    sudo rm -f "$INFO_PAGE"
    echo "Removed $INFO_PAGE"
else
    echo "$INFO_PAGE does not exist, skipping..."
fi

# Remove MySQL root password file
MYSQL_PASS_FILE="/root/mysql_root_password.txt"
echo "Removing MySQL root password file..."
if [ -f "$MYSQL_PASS_FILE" ]; then
    sudo rm -f "$MYSQL_PASS_FILE"
    echo "Removed $MYSQL_PASS_FILE"
else
    echo "$MYSQL_PASS_FILE does not exist, skipping..."
fi

# Final cleanup
echo "Performing final cleanup..."
sudo apt-get update -y

echo "Uninstallation completed!"
