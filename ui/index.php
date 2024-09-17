<?php
$webRoot = __DIR__; // Use __DIR__ for the current directory

// Check if phpMyAdmin exists
$phpMyAdminExists = is_dir($webRoot . '/phpmyadmin');

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
