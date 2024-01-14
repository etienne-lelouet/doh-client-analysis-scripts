#!/bin/bash

rm -f /tmp/*-parsedata_temp

echo "#######################parse_results_parallel#######################"

for soft in $1/*; do
	if ! [ -d "$soft" ]; then
		continue
	fi
	for delay in "$soft"/*; do
		if ! [ -d "$delay" ]; then
			continue
		fi
		delay_max_filename="/tmp/$(basename $delay)-parsedata_temp"
		if ! [ -f "$delay_max_filename" ]; then
			echo "-1" >"$delay_max_filename"
		fi
		echo "#######################parsing $delay#######################"
		./parse_results_parallel.sh "$delay"
		echo "delay_max_filename is $delay_max_filename"
		curr_max=$(cat "$delay_max_filename")
		echo "curr max is $curr_max"
		echo "exp max is $(cat /tmp/max_queries_responses_value)"
		echo "$curr_max" "$(cat /tmp/max_queries_responses_value)" | tr ' ' '\n' | sort -g | tail -n 1 >"$delay_max_filename"
		echo "curr max for $(basename $delay) is now $(cat $delay_max_filename)"
	done
done
echo "#######################gen_queries#######################"
for soft in $1/*; do
	if ! [ -d "$soft" ]; then
		continue
	fi
	for delay in "$soft"/*; do
		if ! [ -d "$delay" ]; then
			continue
		fi
		delay_max_filename="/tmp/$(basename $delay)-parsedata_temp"
		./outfiles/gen_queries.sh "$delay" $(cat "$delay_max_filename")
	done
done
