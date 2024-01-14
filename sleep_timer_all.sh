#!/bin/bash

if [ -z ${1+x} ]; then
	SLEEP_TIMER=10
else
	SLEEP_TIMER=$1
fi

export OUTFILES_DATA_IND="$(date +%y.%m.%d-%H.%M.%S-%a)"

SCRIPTPATH="$(
	cd -- "$(dirname "$0")" >/dev/null 2>&1
	pwd -P
)"

FIREFOX_SCRIPT="$SCRIPTPATH/firefox-generate_results.sh"
DNSCRYPT_SCRIPT="$SCRIPTPATH/dnscrypt-generate_results.sh"
CHROMIUM_SCRIPT="$SCRIPTPATH/chromium-generate_results.sh"
PARAMS_FILE="$SCRIPTPATH/exp_params"

while true; do
	for script in "$CHROMIUM_SCRIPT" "$FIREFOX_SCRIPT" "$DNSCRYPT_SCRIPT"; do
		while read -r line; do
			echo '############################################################################################'
			echo $line
			echo "$line" | xargs "$script"
			retval=$?
			echo '############################################################################################'
			if [ "$retval" -gt 0 ]; then
				echo "$script with args $line failed, exiting"
				exit
			else
				echo "$script with args $line succeeded, continuing"
				rsync -a --progress "$SCRIPTPATH/outfiles/results/" jeanpierre.moe:/var/www/static/results/
			fi
		done <"$PARAMS_FILE"
	done
	export OUTFILES_DATA_IND=$(date +%y.%m.%d-%H.%M.%S-%a)
	echo "sleeping for $SLEEP_TIMER minutes"
	./timer.sh $(echo "$SLEEP_TIMER * 60" | bc)
done
