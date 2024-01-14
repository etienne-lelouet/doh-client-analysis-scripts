#!/bin/bash

if [ -z ${1+x} ]; then
	SLEEP_TIMER=10
else
	SLEEP_TIMER=$1
fi

export OUTFILES_DATA_IND="0"

while true; do
	for f in exp_params/fivetabs/*; do
		./launch_multiple.sh ./firefox-generate-results.sh  "$f"
	done
	export OUTFILES_DATA_IND=$(echo "$OUTFILES_DATA_IND + 1" | bc)
	echo "sleeping for $SLEEP_TIMER"
	sleep "$SLEEP_TIMER"
done
