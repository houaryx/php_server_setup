#!/bin/bash

# Function to display status messages
function status_message() {
    echo "############################################"
    echo "# $1"
    echo "############################################"
}

# Function to prompt for MySQL username and password
function prompt_mysql_credentials() {
    read -p "Enter MySQL username [default: 'root']: " mysql_user
    mysql_user=${mysql_user:-root}
    read -sp "Enter MySQL password: " mysql_password
    echo
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
status_message "Installing Apache2"
sudo apt install apache2 -y

# Install PHP 8.3 for Apache2
status_message "Installing PHP 8.3 for Apache2"
sudo apt install software-properties-common ca-certificates lsb-release apt-transport-https -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install php8.3 php8.3-fpm libapache2-mod-php8.3 php8.3-mysql -y

# Enable PHP in Apache2
status_message "Enabling PHP in Apache2"
sudo a2enmod php8.3
sudo systemctl restart apache2

# Reinstall MySQL Server
status_message "Reinstalling MySQL Server"
sudo apt purge mysql-server mysql-client mysql-common -y
sudo apt autoremove -y
sudo apt install mysql-server -y

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
status_message "Installing phpMyAdmin"
sudo apt install phpmyadmin -y

# Ensure Apache is serving phpMyAdmin
status_message "Configuring Apache for phpMyAdmin"
sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

# Create the dashboard PHP file
status_message "Creating Dashboard in /var/www/html/index.php"

cat << 'EOF' > /var/www/html/index.php
<?php
$webRoot = "/var/www/html";

// Handle directory creation
if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_POST["newDir"])) {
    $newDir = $_POST["newDir"];
    $newDirPath = $webRoot . '/' . $newDir;

    if (!is_dir($newDirPath)) {
        mkdir($newDirPath, 0755); // Create directory
        $successMsg = "Directory '$newDir' created successfully!";
    } else {
        $errorMsg = "Directory '$newDir' already exists!";
    }
}

// Handle directory deletion
if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_POST["deleteDir"])) {
    $dirToDelete = $_POST["deleteDir"];
    $dirToDeletePath = $webRoot . '/' . $dirToDelete;

    if (is_dir($dirToDeletePath)) {
        rmdir($dirToDeletePath); // Remove directory
        $successMsg = "Directory '$dirToDelete' deleted successfully!";
    } else {
        $errorMsg = "Directory '$dirToDelete' does not exist!";
    }
}

// Get the list of directories
$dirs = array_filter(glob($webRoot . '/*'), 'is_dir');
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Website Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            padding: 20px;
            background-color: #f8f9fa;
        }
        .container {
            max-width: 800px;
        }
        .directory-list {
            margin-top: 20px;
        }
        footer {
            margin-top: 20px;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="text-center mb-4">Website Dashboard</h1>

        <!-- Success/Error Messages -->
        <?php if (isset($successMsg)): ?>
            <div class="alert alert-success"><?= $successMsg ?></div>
        <?php endif; ?>
        <?php if (isset($errorMsg)): ?>
            <div class="alert alert-danger"><?= $errorMsg ?></div>
        <?php endif; ?>

        <!-- Form to create a new directory -->
        <form action="" method="POST" class="mb-4">
            <div class="input-group mb-3">
                <input type="text" name="newDir" class="form-control" placeholder="Enter new directory name" required>
                <button type="submit" class="btn btn-primary">Create Directory</button>
            </div>
        </form>

        <!-- Form to delete a directory -->
        <form action="" method="POST" class="mb-4">
            <div class="input-group mb-3">
                <input type="text" name="deleteDir" class="form-control" placeholder="Enter directory name to delete" required>
                <button type="submit" class="btn btn-danger">Delete Directory</button>
            </div>
        </form>

        <!-- Directory Listing -->
        <h3>Available Websites</h3>
        <ul class="list-group directory-list">
            <?php if (empty($dirs)): ?>
                <li class="list-group-item">No directories found.</li>
            <?php else: ?>
                <?php foreach ($dirs as $dir): ?>
                    <li class="list-group-item">
                        <a href="<?= basename($dir) ?>" target="_blank"><?= basename($dir) ?></a>
                    </li>
                <?php endforeach; ?>
            <?php endif; ?>
        </ul>

        <!-- MySQL Credentials Display -->
        <h2>MySQL Username</h2>
        <p><?= htmlspecialchars($mysql_user) ?></p>
        <h2>MySQL Password</h2>
        <p><?= htmlspecialchars($mysql_password) ?></p>
    </div>

    <footer>
        <p>Developed by Ahmed Khalid - <a href="https://github.com/houaryx" target="_blank">github.com/houaryx</a></p>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.6/dist/umd/popper.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.min.js"></script>
</body>
</html>
EOF

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
status_message "Installing Node.js (LTS) and npm"
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Install Composer
status_message "Installing Composer"
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# Add Composer to PATH in .bashrc or .zshrc
status_message "Adding Composer to PATH"

if [ -f "$HOME/.bashrc" ]; then
    echo 'export PATH="$PATH:/usr/local/bin"' >> $HOME/.bashrc
    source $HOME/.bashrc
elif [ -f "$HOME/.zshrc" ]; then
    echo 'export PATH="$PATH:/usr/local/bin"' >> $HOME/.zshrc
    source $HOME
