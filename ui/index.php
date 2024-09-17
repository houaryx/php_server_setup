<?php
$webRoot = __DIR__ ;

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

// Handle directory rename
if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_POST["renameDirOld"]) && isset($_POST["renameDirNew"])) {
    $oldName = $_POST["renameDirOld"];
    $newName = $_POST["renameDirNew"];
    $oldPath = $webRoot . '/' . $oldName;
    $newPath = $webRoot . '/' . $newName;

    if (is_dir($oldPath)) {
        if (!is_dir($newPath)) {
            rename($oldPath, $newPath);
            $successMsg = "Directory '$oldName' renamed to '$newName'!";
        } else {
            $errorMsg = "Directory '$newName' already exists!";
        }
    } else {
        $errorMsg = "Directory '$oldName' does not exist!";
    }
}

// Get the list of directories
$dirs = array_filter(glob($webRoot . '/*'), 'is_dir');

require "css/ui.php";
