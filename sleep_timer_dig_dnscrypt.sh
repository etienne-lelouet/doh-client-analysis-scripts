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
DIG_DNSCRYPT_SCRIPT="$SCRIPTPATH/dig_dnscrypt-generate-results.sh"
PARAMS_FILE="$SCRIPTPATH/exp_params"

while true; do
	while read -r line; do
		echo '############################################################################################'
		echo $line
		echo "$line" | xargs "$DIG_DNSCRYPT_SCRIPT"
		retval=$?
		echo '############################################################################################'
		if [ "$retval" -gt 0 ]; then
<<<<<<< Updated upstream
			echo "$DIG_DNSCRYPT_SCRIPT with args $line failed with code $retval, exiting"
			exit
		else
			echo "$DIG_DNSCRYPT_SCRIPT with args $line succeeded, continuing"
=======
			echo "$script with args $line failed, exiting"
			exit
		else
			echo "$script with args $line succeeded, continuing"
>>>>>>> Stashed changes
			rsync -a --progress "$SCRIPTPATH/outfiles/results/" jeanpierre.moe:/var/www/static/results/
		fi
	done <"$PARAMS_FILE"
	export OUTFILES_DATA_IND=$(date +%y.%m.%d-%H.%M.%S-%a)
	echo "sleeping for $SLEEP_TIMER minutes"
	./timer.sh $(echo "$SLEEP_TIMER * 60" | bc)
done
