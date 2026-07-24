<?php
$hostname   = gethostname();
$server_ip  = $_SERVER['SERVER_ADDR'] ?? 'unknown';
$client_ip  = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
?>
<!DOCTYPE html>
<html>
<head>
<title>home_web</title>
<style>
body { font-family: Arial, sans-serif; margin: 40px; }
h1 { color: #333; }
.info { margin-top: 20px; }
.info p { margin: 6px 0; }
</style>
</head>
<body>
<h1>home_web default page</h1>

<div class="info">
<p><strong>Server Hostname:</strong> <?php echo htmlspecialchars($hostname); ?></p>
<p><strong>Server IP:</strong> <?php echo htmlspecialchars($server_ip); ?></p>
<p><strong>Your IP:</strong> <?php echo htmlspecialchars($client_ip); ?></p>
</div>
</body>
</html>
