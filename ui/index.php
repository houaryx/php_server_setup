<?php
$webRoot = __DIR__; // Use __DIR__ for current directory

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

    if ($dirToDelete !== 'phpmyadmin' && is_dir($dirToDeletePath)) {
        rmdir($dirToDeletePath); // Remove directory
        $successMsg = "Directory '$dirToDelete' deleted successfully!";
    } elseif ($dirToDelete === 'phpmyadmin') {
        $errorMsg = "Cannot delete 'phpmyadmin' directory.";
    } else {
        $errorMsg = "Directory '$dirToDelete' does not exist!";
    }
}

// Handle directory renaming
if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_POST["renameDirOld"]) && isset($_POST["renameDirNew"])) {
    $renameDirOld = $_POST["renameDirOld"];
    $renameDirNew = $_POST["renameDirNew"];
    $renameDirOldPath = $webRoot . '/' . $renameDirOld;
    $renameDirNewPath = $webRoot . '/' . $renameDirNew;

    if (is_dir($renameDirOldPath) && !is_dir($renameDirNewPath)) {
        rename($renameDirOldPath, $renameDirNewPath); // Rename directory
        $successMsg = "Directory '$renameDirOld' renamed to '$renameDirNew' successfully!";
    } elseif (is_dir($renameDirNewPath)) {
        $errorMsg = "Directory '$renameDirNew' already exists!";
    } else {
        $errorMsg = "Directory '$renameDirOld' does not exist!";
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

    <!-- Tailwind CSS CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- ShadCN CDN for modal and UI components -->
    <script src="https://unpkg.com/shadcn/dist/shadcn.min.js"></script>
    <!-- Varcal Theme -->
    <link rel="stylesheet" href="https://unpkg.com/@varcal/theme/dist/varcal.min.css">

    <style>
        /* Custom fade-out animation */
        .fade-out {
            animation: fadeOut 1s ease forwards;
        }
        @keyframes fadeOut {
            0% { opacity: 1; }
            100% { opacity: 0; transform: translateY(-20px); }
        }

        /* Glass effect */
        .glass-effect {
            backdrop-filter: blur(10px);
            background: rgba(0, 0, 0, 0.4);
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
    </style>
</head>
<body class="bg-gray-900 text-gray-200 py-10">
    <div class="container mx-auto max-w-xl">
        <h1 class="text-center text-3xl font-bold mb-6">Server Dashboard</h1>
        <h5 class="text-center mb-4 text-gray-400">PHP 8.3 + Apache + MySQL + Laravel</h5>

        <!-- Success/Error Messages -->
        <?php if (isset($successMsg) || isset($errorMsg)): ?>
            <div class="alert p-4 mb-4 rounded-lg shadow-lg glass-effect" id="alert">
                <?php if (isset($successMsg)): ?>
                    <div class="text-green-400"><?= $successMsg ?>
                        <button type="button" class="ml-auto text-green-300" onclick="closeAlert()">✖</button>
                    </div>
                <?php endif; ?>
                <?php if (isset($errorMsg)): ?>
                    <div class="text-red-400"><?= $errorMsg ?>
                        <button type="button" class="ml-auto text-red-300" onclick="closeAlert()">✖</button>
                    </div>
                <?php endif; ?>
            </div>
        <?php endif; ?>

        <!-- Form to create a new directory -->
        <form action="" method="POST" class="mb-6 glass-effect p-6">
            <div class="flex">
                <input type="text" name="newDir" class="w-full px-4 py-2 border rounded-l-lg bg-gray-800 text-gray-200" placeholder="Enter new directory name" required>
                <button type="submit" class="bg-blue-600 text-white px-4 py-2 rounded-r-lg">Create</button>
            </div>
        </form>

        <!-- Directory Listing -->
        <h3 class="text-xl font-bold mb-4">Available Websites</h3>
        <ul class="space-y-2">
            <?php if (empty($dirs)): ?>
                <li class="p-4 bg-gray-800 shadow rounded-lg glass-effect">No directories found.</li>
            <?php else: ?>
                <?php foreach ($dirs as $dir): ?>
                    <li class="flex justify-between items-center p-4 bg-gray-800 shadow rounded-lg glass-effect">
                        <a href="<?= basename($dir) ?>" target="_blank" class="text-blue-400 font-bold"><?= basename($dir) ?></a>
                        <div class="flex space-x-2">
                            <?php if (basename($dir) !== 'phpmyadmin'): ?>
                                <button class="bg-yellow-600 text-white px-4 py-2 rounded-lg" data-dir="<?= basename($dir) ?>" onclick="openRenameModal('<?= basename($dir) ?>')">Rename</button>
                                <form action="" method="POST">
                                    <input type="hidden" name="deleteDir" value="<?= basename($dir) ?>">
                                    <button type="submit" class="bg-red-600 text-white px-4 py-2 rounded-lg">Delete</button>
                                </form>
                            <?php endif; ?>
                        </div>
                    </li>
                <?php endforeach; ?>
            <?php endif; ?>
        </ul>
    </div>

    <!-- Rename Modal -->
    <div class="hidden fixed inset-0 bg-gray-600 bg-opacity-75 z-50 flex justify-center items-center" id="renameModal">
        <div class="bg-gray-800 rounded-lg shadow-lg p-6 w-full max-w-md glass-effect">
            <h3 class="text-lg font-bold mb-4 text-gray-200">Rename Directory</h3>
            <form id="renameForm" action="" method="POST">
                <div class="mb-3">
                    <label for="renameDirOld" class="block mb-1 text-gray-300">Current Directory Name</label>
                    <input type="text" class="w-full px-3 py-2 border rounded-lg bg-gray-700 text-gray-200" id="renameDirOld" name="renameDirOld" readonly>
                </div>
                <div class="mb-3">
                    <label for="renameDirNew" class="block mb-1 text-gray-300">New Directory Name</label>
                    <input type="text" class="w-full px-3 py-2 border rounded-lg bg-gray-700 text-gray-200" id="renameDirNew" name="renameDirNew" required>
                </div>
                <div class="flex justify-end space-x-2">
                    <button type="submit" class="bg-blue-600 text-white px-4 py-2 rounded-lg">Rename</button>
                    <button type="button" class="bg-gray-600 text-white px-4 py-2 rounded-lg" onclick="closeRenameModal()">Cancel</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        // Automatically close alerts after 5 seconds with animation
        setTimeout(() => {
            const alertElement = document.getElementById('alert');
            if (alertElement) {
                alertElement.classList.add('fade-out');
                setTimeout(() => alertElement.remove(), 1000);
            }
        }, 5000);

        // Close alert on button click
        function closeAlert() {
            const alertElement = document.getElementById('alert');
            if (alertElement) {
                alertElement.classList.add('fade-out');
                setTimeout(() => alertElement.remove(), 1000);
            }
        }

        // Open rename modal and set directory name
        function openRenameModal(dirName) {
            document.getElementById("renameDirOld").value = dirName;
            document.getElementById("renameModal").classList.remove("hidden");
        }

        // Close rename modal
        function closeRenameModal() {
            document.getElementById("renameModal").classList.add("hidden");
        }
    </script>
</body>
</html>
