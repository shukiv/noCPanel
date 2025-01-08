# noCPanel - Web Hosting Control Panel 

A lightweight, simple, and customizable web hosting control panel written entirely in Bash. This script will install a LAMP server and automates common hosting tasks, such as setting up web servers, managing domains, configuring SSL, and more—all without the overhead of typical resource-heavy control panels.

## Features

- **Domain Management**  
  Easily add, remove, and manage multiple domains.

- **Web Server Configuration**  
  Auto-configure Apache or Nginx for new domains.

- **SSL/TLS Certificates**  
  Generate and install SSL certificates via Let’s Encrypt (optional).

- **SFTP & Database Management**  
  Basic scripts to handle FTP user creation and MySQL database setup.

- **User-Friendly**  
  Command line prompts guide you through the setup and configuration process.

- **Lightweight & Minimal**  
  Only depends on standard Bash utilities; doesn’t require a heavy front-end GUI.

## Requirements

- **Operating System**: Linux-based server (tested on Debian 12 only)  
- **Bash Shell**: Version 4 or higher recommended  
- **Root/Sudo Access**: Required to install packages and configure services  
- **Installed Packages** (depending on which features you plan to use):
  - `curl` or `wget`  
  - `apache2` or `nginx`  
  - `ufw` or `firewalld` (optional, for firewall management)  
  - `mariadb-server` or `mysql-server` (optional, for database support)  
  - `pure-ftpd` or another FTP server (optional, for FTP support)

> **Note**: If you use different software (e.g., a different web server or database), you’ll need to update the script accordingly.

## Getting Started

### 1. Clone This Repository

A bash control panel for websites.

INSTALLATION

apt-get update && apt-get install curl -y

curl -sSL https://raw.githubusercontent.com/shukiv/noCPanel/main/install_nocp.sh | bash
