# Use an official Ubuntu base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages and dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    apache2 \
    php8.3 \
    php8.3-fpm \
    libapache2-mod-php8.3 \
    php8.3-mysql \
    mysql-server \
    phpmyadmin \
    nodejs \
    npm \
    git \
    unzip

# Install PHP 8.3 (if needed) and Node.js LTS (if not already installed)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set up Composer and add to PATH
RUN echo 'export PATH="$PATH:/usr/local/bin"' >> ~/.bashrc && \
    source ~/.bashrc && \
    composer global require laravel/installer

# Configure Apache
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

# Create a simple PHP dashboard and README.md
RUN mkdir -p /var/www/html && \
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php && \
    echo "<?php
\$webRoot = \"/var/www/html\";

if (\$_SERVER[\"REQUEST_METHOD\"] === \"POST\" && isset(\$_POST[\"newDir\"])) {
    \$newDir = \$_POST[\"newDir\"];
    \$newDirPath = \$webRoot . '/' . \$newDir;

    if (!is_dir(\$newDirPath)) {
        mkdir(\$newDirPath, 0755); 
        \$successMsg = \"Directory '\$newDir' created successfully!\";
    } else {
        \$errorMsg = \"Directory '\$newDir' already exists!\";
    }
}

if (\$_SERVER[\"REQUEST_METHOD\"] === \"POST\" && isset(\$_POST[\"deleteDir\"])) {
    \$dirToDelete = \$_POST[\"deleteDir\"];
    \$dirToDeletePath = \$webRoot . '/' . \$dirToDelete;

    if (is_dir(\$dirToDeletePath)) {
        rmdir(\$dirToDeletePath); 
        \$successMsg = \"Directory '\$dirToDelete' deleted successfully!\";
    } else {
        \$errorMsg = \"Directory '\$dirToDelete' does not exist!\";
    }
}

\$dirs = array_filter(glob(\$webRoot . '/*'), 'is_dir');
?>" > /var/www/html/index.php

# Create README.md
RUN echo "Your User Name For MySQL = root\nYour User Password For MySQL = yourpassword\nYou Can test PHP by Dashboard http://localhost/ or http://localhost/index.php\nYou Can test PHP by Visiting http://localhost/info.php\nYou Can Access phpMyAdmin By Visiting http://localhost/phpmyadmin" > /var/www/html/README.md

# Expose ports
EXPOSE 80 3306

# Start Apache and MySQL
CMD service mysql start && apachectl -D FOREGROUND
