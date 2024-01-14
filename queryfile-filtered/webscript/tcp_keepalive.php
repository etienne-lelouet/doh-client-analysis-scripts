<?php
$delay_ms = 1000;
$duration_s = 60;
$index = 0;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
	echo "use a get request";
	http_response_code(400);
	return;
}

if (isset($_GET['clearcache'])) {
	$files = glob('tcp_keepalive_cachedir/*');
	foreach ($files as $file) {
		if (is_file($file)) {
			unlink($file);
		}
	}
	return;
}

if (isset($_GET["delay"])) {
	if (!is_numeric($_GET["delay"])) {
		echo "invalid value for delay";
		http_response_code(400);
		return;
	}
	$delay_ms = $_GET["delay"];
}

if (isset($_GET["duration"])) {
	if (!is_numeric($_GET["duration"])) {
		echo "invalid value for duration";
		http_response_code(400);
		return;
	}
	$duration_s = $_GET["duration"];
}

if (isset($_GET["index"])) {
	if (!is_numeric($_GET["delay"])) {
		echo "invalid value for delay";
		http_response_code(400);
		return;
	}
	$index = $_GET["index"];
}

$nqueries = floor(($duration_s * 1000) * (1 / $delay_ms));
$offset_start = $index * $nqueries;

$filename = sprintf("tcp_keepalive_cachedir/tcp_keepalive_%s_%s_%s.html", $delay_ms, $duration_s, $index);

if (!file_exists('tcp_keepalive_cachedir')) {
	mkdir('tcp_keepalive_cachedir', 0755, true);
}

if (file_exists($filename)) {
	echo "using cache from $filename";
	readfile($filename);
	return;
}

echo "saving contents";
ob_start();

?>

<!DOCTYPE html>

<body bgcolor="green">
	<div id="args" data-delay-ms="<?php echo $delay_ms ?>"></div>
	<span>
		<?php
		echo "$nqueries queries, starting at $offset_start\n"
		?>
	</span>
	<script>
		var arecords = [<?php
						$file = file("domainlist", FILE_IGNORE_NEW_LINES);
						$domainnames = array_splice($file, $offset_start, $nqueries);
						foreach ($domainnames as $domain) {
							echo "\"$domain\",";
						}
						?>];

		params = document.getElementById("args");
		delay = params.getAttribute("data-delay-ms");
		arecords.forEach((element, i) => {
			setTimeout(() => {
				console.log(element + " " + i);
				fetch("https://" + element, {
					method: "HEAD"
				}).then((response) => {
					console.log(response.url + " DONE");
				}).catch(error => console.error(error))
			}, i * delay);
		});
	</script>
</body>

<?php

$content = ob_get_contents();
$f = fopen($filename, "w");
fwrite($f, $content);
fclose($f);
echo "saved file to $filename";
?>