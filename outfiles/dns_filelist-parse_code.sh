file="$1"

if ! [ -s $file ]; then
	exit
fi

TEMP_OUTPUT_FILE_BOTH=${EXPECTED_QUERIES_OUTFILE_BOTH}_temp$(cat /proc/sys/kernel/random/uuid)
TEMP_OUTPUT_FILE_DOH=${EXPECTED_QUERIES_OUTFILE_DOH}_temp$(cat /proc/sys/kernel/random/uuid)
TEMP_OUTPUT_FILE_DNS=${EXPECTED_QUERIES_OUTFILE_UDP}_temp$(cat /proc/sys/kernel/random/uuid)
TEMP_OUTPUT_FILE_NO=${NO_MATCH}_temp$(cat /proc/sys/kernel/random/uuid)

while read -r line; do

	if [[ ${line} =~ ${reempty} ]]; then
		exit
	fi
	if [[ ${line} =~ ${reempty2} ]]; then
		exit
	fi
	escaped_line=$(printf '%s\n' "${line}" | sed -e 's/[]\/$*.^[]/\\&/g')
	temp=$(grep -E "^.*\s*,?${escaped_line},?.*$" "${DOH_QUERIES_OUTFILE}")
	is_doh=$?
	temp=$(grep -E "^.*\s*,?${escaped_line},?.*$" "${UDP_QUERIES_OUTFILE}")
	is_dns=$?

	if [ $is_doh -eq 0 ] && [ $is_dns -eq 0 ]; then
		echo "${temp}" | while read -r match; do # au cas ou il y ait plusieurs resultats
			date=$(echo "${match}" | sed -nE 's/^(.*)+\s+.*$/\1/p')
			echo "${date} ${line}" >>"${TEMP_OUTPUT_FILE_BOTH}"
		done
	elif [ $is_doh -eq 0 ]; then
		echo "${temp}" | while read -r match; do # au cas ou il y ait plusieurs resultats
			date=$(echo "${match}" | sed -nE 's/^(.*)+\s+.*$/\1/p')
			echo "${date} ${line}" >>"${TEMP_OUTPUT_FILE_DOH}"
		done
	elif [ $is_dns -eq 0 ]; then
		echo "${temp}" | while read -r match; do # au cas ou il y ait plusieurs resultats
			date=$(echo "${match}" | sed -nE 's/^(.*)+\s+.*$/\1/p')
			echo "${date} ${line}" >>"${TEMP_OUTPUT_FILE_DNS}"
		done
	else
		# echo "could not find ${line} in the list of queries"
		echo "${line}" >>"${TEMP_OUTPUT_FILE_NO}"
	fi
done <$file

echo "$2 / $3 dns queries parses done"
