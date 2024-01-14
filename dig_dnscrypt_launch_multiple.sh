#!/bin/bash

export OUTFILES_DATA_IND="$(date +%y.%m.%d-%H.%M.%S-%a)"

SCRIPTPATH="$(
	cd -- "$(dirname "$0")" >/dev/null 2>&1
	pwd -P
)"
DIG_DNSCRYPT_SCRIPT="$SCRIPTPATH/dig_dnscrypt-generate-results.sh"
PARAMS_FILE="$SCRIPTPATH/exp_params"

while read -r line; do
	echo '############################################################################################'
	echo $line
	echo "$line" | xargs "$DIG_DNSCRYPT_SCRIPT"
	retval=$?
	echo '############################################################################################'
	if [ "$retval" -gt 0 ]; then
		echo "$script with args $line failed, exiting"
		exit
	else
		echo "$script with args $line succeeded, continuing"
		rsync -a --progress "$SCRIPTPATH/outfiles/results/data$OUTFILES_DATA_IND" jeanpierre.moe:/var/www/static/results/
	fi
done <"$PARAMS_FILE"
