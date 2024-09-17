#!/bin/bash

# Function to display status messages
function status_message() {
    clear
    echo "======================================="
    echo "+ $1"
    echo "======================================="
    echo  "DEV : @houaryx"
}

# Function to prompt for MySQL username and password
function prompt_mysql_credentials() {
    read -p "Enter MySQL username [default: 'root']: " mysql_user
    mysql_user=${mysql_user:-root}
    read -sp "Enter MySQL password: " mysql_password
    echo
}

# Function to check if a package is installed
function check_package_installed() {
    dpkg -l | grep -q "$1"
}

# Function to install a package if not installed
function install_package() {
    if ! check_package_installed "$1"; then
        status_message "Installing $1"
        sudo apt install -y "$1"
    else
        read -p "$1 is already installed. Do you want to reinstall it? [y/N]: " choice
        if [[ "$choice" == [Yy] ]]; then
            status_message "Reinstalling $1"
            sudo apt install --reinstall -y "$1"
        else
            echo "$1 will not be reinstalled."
        fi
    fi
}

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Prompt for MySQL credentials
prompt_mysql_credentials

# Update the system
status_message "Updating the system"
sudo apt update && sudo apt upgrade -y

# Uninstall PHP and Nginx
status_message "Removing PHP, PHP-FPM, and Nginx"
sudo apt purge php8.3* nginx nginx-common nginx-full -y
sudo apt autoremove -y

# Install Apache2
install_package "apache2"

# Install PHP 8.3 for Apache2
status_message "Installing PHP 8.3 for Apache2"
sudo apt install software-properties-common ca-certificates lsb-release apt-transport-https -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
install_package "php8.3"
install_package "php8.3-fpm"
install_package "libapache2-mod-php8.3"
install_package "php8.3-mysql"

# Enable PHP in Apache2
status_message "Enabling PHP in Apache2"
sudo a2enmod php8.3
sudo systemctl restart apache2

# Reinstall MySQL Server
status_message "Reinstalling MySQL Server"
sudo apt purge mysql-server mysql-client mysql-common -y
sudo apt autoremove -y
install_package "mysql-server"

# Start MySQL service
status_message "Starting MySQL service"
sudo systemctl start mysql

# Secure MySQL Installation using Python for user password setting
status_message "Configuring MySQL Root Password using Python"

python3 <<EOF
import subprocess

# MySQL credentials from the bash script
mysql_user = '$mysql_user'
mysql_password = '$mysql_password'

# Run MySQL secure installation using Python
commands = [
    f"ALTER USER '{mysql_user}'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY '{mysql_password}';",
    "FLUSH PRIVILEGES;"
]

# Execute MySQL commands
for command in commands:
    subprocess.run(['mysql', '-u', mysql_user, '-e', command], check=True)

print("MySQL credentials configured.")
EOF

# Install phpMyAdmin
install_package "phpmyadmin"

# Ensure Apache is serving phpMyAdmin
status_message "Configuring Apache for phpMyAdmin"
sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

# Create the dashboard PHP file
status_message "Creating Dashboard in /var/www/html/index.php"

# Ensure proper permissions for /var/www/html
status_message "Setting proper permissions for /var/www/html"
sudo chmod 775 /var/www/html
sudo chown -R www-data:www-data /var/www/html

# Create a README.md file
status_message "Creating README.md"

cat << EOF > /var/www/html/README.md
Your User Name For MySQL = $mysql_user
Your User Password For MySQL = $mysql_password
You Can test PHP by Dashboard http://localhost/ or http://localhost/index.php
You Can test PHP by Visiting http://localhost/info.php
You Can Access phpMyAdmin By Visiting http://localhost/phpmyadmin
EOF

# Install Node.js (LTS) and npm
install_package "nodejs"
install_package "npm"

# Install Composer
install_package "composer"

# Install Git
install_package "git"

# Clone the repository
status_message "Cloning repository"
sudo rm /var/www/html/index.php
sudo git clone https://github.com/houaryx/php_server_setup/tree/main/ui/css /var/www/html/

# Install Laravel CLI globally
status_message "Installing Laravel CLI"
sudo composer global require laravel/installer

# Ensure the global Composer bin directory is in PATH
echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Final status message
status_message "Setup complete. Your server is ready."

