<?php
// TODO: rajouter le expected queries et le realized queries

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

$delayArr = [];
$softArr = [];
$resolverArr = [];
$imageArr = [];

parse_str(implode('&', array_slice($argv, 1)), $_GET);

if ($_GET['restricteddelays'] == NULL) {
	$restrictedDelays = [];
} else {
	$restrictedDelays = $_GET['restricteddelays'];
}


$dirSoft = new DirectoryIterator("data/");
foreach ($dirSoft as $softInfo) {
	if (!$softInfo->isDir() || $softInfo->isDot()) {
		continue;
	}
	$softresolver = $softInfo->getFilename();
	$softresolversplit = explode("-", $softresolver);
	$soft = $softresolversplit[0];
	if (!in_array($soft, $softArr)) {
		array_push($softArr, $soft);
	}
	$resolver = $softresolversplit[1];
	if (!in_array($resolver, $resolverArr)) {
		array_push($resolverArr, $resolver);
	}
	$dirDelays = new DirectoryIterator($softInfo->getPathName());
	foreach ($dirDelays as $delayInfo) {
		if (!$delayInfo->isDir() || $delayInfo->isDot()) {
			continue;
		}
		$delayVal = $delayInfo->getFilename();
		if (in_array($delayVal, $restrictedDelays)) {
			continue;
		}
		$delay = intval(str_replace("ms",  "", $delayVal));
		if (!in_array($delay, $delayArr)) {
			array_push($delayArr, $delay);
		}
		$profilepath = $delayInfo->getPathName() . "/profile.svg";
		if (file_exists($profilepath)) {
			$imageArr[$delay][$soft][$resolver] = $profilepath;
			// array_push($imageArr, ["soft" => $soft, "resolver" => $resolver, "delay" => $delay, "path" => $profilepath]);
		} else {
			echo nl2br(sprintf("%s does not exists\n", $profilepath));
		}
	}
}

$dataWidth = count($softArr);
$dataLen = count($resolverArr);
$maxColsInViewPort = 3;
$totalwitdh = ceil($dataWidth / $maxColsInViewPort) * 100;
sort($softArr, SORT_STRING);
sort($resolverArr, SORT_STRING);
sort($delayArr, SORT_NUMERIC);
?>

<!DOCTYPE html>
<style>
	.containermain {
		display: flex;
		flex-direction: column;
		flex-wrap: nowrap;
	}

	.containerdelay {
		display: flex;
		flex-direction: row;
		flex-wrap: nowrap;
	}

	.containersoft {
		display: flex;
		flex-direction: column;
		flex-wrap: nowrap;
	}

	.containerresolver {
		display: flex;
		flex-direction: row;
		flex-wrap: nowrap;
	}

	img {
		max-height: 100%;
		max-width: 100%;
	}
</style>

<body>
	<div class="containermain">
		<?php foreach ($delayArr as $delay) : ?>
			<span><?= $delay ?></span>
			<div class="containerdelay">
				<?php foreach ($softArr as $soft) : ?>
					<div class="containersoft">
						<span><?= $soft ?></span>
						<?php foreach ($resolverArr as $resolver) : ?>
							<span><?= $resolver ?></span>
							<div class="item">
								<img src="<?= $imageArr[$delay][$soft][$resolver] ?>" />
							</div>
						<?php endforeach ?>
					</div>
				<?php endforeach ?>
			</div>
		<?php endforeach ?>
</body>