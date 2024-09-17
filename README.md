# PHP & MySQL Docker Setup

This repository provides a Docker setup to quickly deploy a web server environment with Apache, PHP, MySQL, phpMyAdmin, Node.js, npm, Composer, and Laravel. It also includes a simple PHP dashboard for managing directories.

## Prerequisites

- Docker installed on your machine
- Docker Compose (optional, but recommended for managing multi-container applications)

## Setup

### 1. Clone the Repository

```bash
git clone https://github.com/houaryx/php_server_setup.git
cd php_server_setup
chmod +x wsl_server.sh
./wsl_server.sh
`````
### 2. Build the Docker Image
- To build the Docker image, run:
```bash
docker build -t my-php-app .
```
### 3. Run the Docker Container
- To run the Docker container with port mappings:
```bash
docker run -p 8080:80 -p 3306:3306 --name my-running-app my-php-app

```
- Port 8080 will be used for accessing the web server.
- Port 3306 will be used for accessing the MySQL database.

### 3. Accessing Services
- PHP Dashboard: http://localhost:8080/
- phpMyAdmin: http://localhost:8080/phpmyadmin
- PHP Info: http://localhost:8080/info.php

### 4. Using the PHP Dashboard
- The PHP dashboard at http://localhost:8080/ allows you to:
- Create New Directories: Enter a name and click "Create Directory."
- Delete Directories: Enter the name of an existing directory and click "Delete Directory."
- View Existing Directories: The list of directories under /var/www/html will be displayed.
### MySQL Credentials
- Username: root
- Password: yourpassword (replace with your desired password in the Dockerfile or through environment variables)
