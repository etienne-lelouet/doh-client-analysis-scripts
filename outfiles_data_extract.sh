#!/bin/bash

if [ -z ${1+x} ]; then
	echo "working dir must be set"
	exit
fi

SCRIPT="datavis/datavis.py"

OUTFILES_BASEDIR="${1}"

DATA_FILE="${OUTFILES_BASEDIR}/runfile"

TEST_PARAMS=$(sed -nE 's/^runtime:\s([0-9]+).*?delay:\s([0-9]+).*$/\1 \2/p' "${DATA_FILE}")
EXP_LEN=$(echo "${TEST_PARAMS}" | sed -nE 's/^(\S*)\s(\S*)$/\1/p')
EXP_DELAY=$(echo "${TEST_PARAMS}" | sed -nE 's/^(\S*)\s(\S*)$/\2/p')


CONNEXION_LEN="${OUTFILES_BASEDIR}/connexion_len"
CONNEXION_NUMBER_REQUESTS="${OUTFILES_BASEDIR}/connexion_number_requests"
AGGREGATION_COUNT_REQUESTS="${OUTFILES_BASEDIR}/aggregation_count_requests"
CONNEXION_OPEN_FLOATPRECISION="${OUTFILES_BASEDIR}/connexion_open_floatprecision"
CONNEXION_OPEN_INTPRECISION="${OUTFILES_BASEDIR}/connexion_open_intprecision"

CONNEXION_LEN_IMG="${OUTFILES_BASEDIR}/connexion_len.png"
CONNEXION_NUMBER_REQUESTS_IMG="${OUTFILES_BASEDIR}/connexion_number_requests.png"
AGGREGATION_COUNT_REQUESTS_IMG="${OUTFILES_BASEDIR}/aggregation_count_requests.png"

CONNEXION_LEN_UNIQ="${OUTFILES_BASEDIR}/connexion_len_uniq"
CONNEXION_NUMBER_REQUESTS_UNIQ="${OUTFILES_BASEDIR}/connexion_number_requests_uniq"
AGGREGATION_COUNT_REQUESTS_UNIQ="${OUTFILES_BASEDIR}/aggregation_count_requests_uniq"

FIN_BY_CLIENT="${OUTFILES_BASEDIR}/fin_by_client"
FIN_BY_SERVER="${OUTFILES_BASEDIR}/fin_by_server"
RESET_BY_CLIENT="${OUTFILES_BASEDIR}/reset_by_client"
RESET_BY_SERVER="${OUTFILES_BASEDIR}/reset_by_server"

# FIN_BY_CLIENT_PERC_FILE="${OUTFILES_BASEDIR}fin_by_client_perc"
# FIN_BY_SERVER_PERC_FILE="${OUTFILES_BASEDIR}fin_by_server_perc"
# RESET_BY_CLIENT_PERC_FILE="${OUTFILES_BASEDIR}reset_by_client_perc"
# RESET_BY_SERVER_PERC_FILE="${OUTFILES_BASEDIR}reset_by_server_perc"

CLOSE_CSV="${OUTFILES_BASEDIR}/close_csv"
CLOSE_PERC_CSV="${OUTFILES_BASEDIR}/close_perc_csv"

if ! [ -f "${DATA_FILE}" ]; then
	printf '%s Does not exist\n' ${DATA_FILE}
	exit
fi
if ! [ -r "${DATA_FILE}" ]; then
	printf '%s is not writeable\n' ${DATA_FILE}
	exit
fi

echo "extracting results"

for i in "${CONNEXION_LEN}" "${CONNEXION_NUMBER_REQUESTS}" "${AGGREGATION_COUNT_REQUESTS}" "${CONNEXION_LEN_UNIQ}" "${CONNEXION_NUMBER_REQUESTS_UNIQ}" "${AGGREGATION_COUNT_REQUESTS_UNIQ}" "${CONNEXION_OPEN_FLOATPRECISION}" "${CONNEXION_OPEN_INTPRECISION}" "${FIN_BY_CLIENT}" "${FIN_BY_SERVER}" "${RESET_BY_CLIENT}" "${RESET_BY_SERVER}" "${CLOSE_CSV}" "${CLOSE_PERC_CSV}"; do
	if ! [ -f "${i}" ]; then
		touch "${i}"
	fi
	if ! [ -r "${i}" ]; then
		chmod +r "${i}"
	fi
	if ! [ -w "${i}" ]; then
		chmod +w "${i}"
	fi
	echo -n "" >${i}
done

echo "0" >"${FIN_BY_CLIENT}"
echo "0" >"${FIN_BY_SERVER}"
echo "0" >"${RESET_BY_CLIENT}"
echo "0" >"${RESET_BY_SERVER}"

grep -E 'closed_by' "${DATA_FILE}" | while read -r line; do
	NUMBER=$(echo "${line}" | cut -d ',' -f 2 | sed -En 's/queries: ([0-9]+)/\1/p')
	START=$(echo "${line}" | cut -d ',' -f 3 | sed -En 's/relative_start: ([0-9]+)/\1/p')
	LEN=$(echo "${line}" | cut -d ',' -f 4 | sed -En 's/duration: ([0-9]+)/\1/p')
	CLOSED_BY=$(echo "${line}" | cut -d ',' -f 5 | sed -En 's/closed_by: (.+)/\1/p')
	FIN=$(echo "${line}" | cut -d ',' -f 6 | sed -En 's/fin: ([0-9])/\1/p')
	RESET=$(echo "${line}" | cut -d ',' -f 7 | sed -En 's/reset: ([0-9])/\1/p')
	echo "${NUMBER}" >>"${CONNEXION_NUMBER_REQUESTS}"
	echo "${LEN}" >>"${CONNEXION_LEN}"

	if [[ "$CLOSED_BY" == "CLIENT" ]]; then
		if [[ "$FIN" == "1" ]]; then
			NUMBER=$(cat "${FIN_BY_CLIENT}")
			NUMBER=$((NUMBER + 1))
			echo "$NUMBER" >"${FIN_BY_CLIENT}"
		elif [[ "$RESET" == "1" ]]; then
			NUMBER=$(cat "${RESET_BY_CLIENT}")
			NUMBER=$((NUMBER + 1))
			echo "$NUMBER" >"${RESET_BY_CLIENT}"
		fi
	elif [[ "$CLOSED_BY" == "SERVER" ]]; then
		if [[ "$FIN" == "1" ]]; then
			NUMBER=$(cat "${FIN_BY_SERVER}")
			NUMBER=$((NUMBER + 1))
			echo "$NUMBER" >"${FIN_BY_SERVER}"
		elif [[ "$RESET" == "1" ]]; then
			NUMBER=$(cat "${RESET_BY_SERVER}")
			NUMBER=$((NUMBER + 1))
			echo "$NUMBER" >"${RESET_BY_SERVER}"
		fi
	fi

	STARTFLOAT=$(printf "%.4f" ${START})
	STARTINT=$(printf "%.0f" ${START})
	printf "%s,open\n" "${STARTFLOAT}" >>"${CONNEXION_OPEN_FLOATPRECISION}"
	printf "%s,open\n" "${STARTINT}" >>"${CONNEXION_OPEN_INTPRECISION}"
	CLOSE=$(echo "print(${START}+${LEN})" | python3)
	CLOSEFLOAT=$(printf "%.1f" ${CLOSE})
	CLOSEINT=$(printf "%.0f" ${CLOSE})
	printf "%s,close\n" "${CLOSEFLOAT}" >>"${CONNEXION_OPEN_FLOATPRECISION}"
	printf "%s,open\n" "${CLOSEINT}" >>"${CONNEXION_OPEN_INTPRECISION}"
done

NUMBER_FIN_BY_CLIENT=$(cat "${FIN_BY_CLIENT}")
NUMBER_RESET_BY_CLIENT=$(cat "${RESET_BY_CLIENT}")
NUMBER_FIN_BY_SERVER=$(cat "${FIN_BY_SERVER}")
NUMBER_RESET_BY_SERVER=$(cat "${RESET_BY_SERVER}")
echo "perc_fin_by_client,perc_reset_by_client,perc_fin_by_server,perc_reset_by_server" > ${CLOSE_CSV}
echo "$NUMBER_FIN_BY_CLIENT,$NUMBER_RESET_BY_CLIENT,$NUMBER_FIN_BY_SERVER,$NUMBER_RESET_BY_SERVER" >> ${CLOSE_CSV}

SUM=$(echo "${NUMBER_FIN_BY_CLIENT} + ${NUMBER_RESET_BY_CLIENT} + ${NUMBER_FIN_BY_SERVER} + ${NUMBER_RESET_BY_SERVER}" | bc)

if [ ${NUMBER_FIN_BY_CLIENT} == "0" ];
then
	PERC_FIN_BY_CLIENT="0"
else
	PERC_FIN_BY_CLIENT=$(echo "(100 * ${NUMBER_FIN_BY_CLIENT}) / ${SUM}" | bc)
fi

if [ ${NUMBER_RESET_BY_CLIENT} == "0" ];
then
	PERC_RESET_BY_CLIENT="0"
else
	PERC_RESET_BY_CLIENT=$(echo "(100 * ${NUMBER_RESET_BY_CLIENT}) / ${SUM}" | bc)
fi

if [ ${NUMBER_FIN_BY_SERVER} == "0" ];
then
	PERC_FIN_BY_SERVER="0"
else
	PERC_FIN_BY_SERVER=$(echo "(100 * ${NUMBER_FIN_BY_SERVER}) / ${SUM}" | bc)
fi

if [ ${NUMBER_RESET_BY_SERVER} == "0" ];
then
	PERC_RESET_BY_SERVER="0"
else
	PERC_RESET_BY_SERVER=$(echo "(100 * ${NUMBER_RESET_BY_SERVER}) / ${SUM}" | bc)
fi
echo "perc_fin_by_client,perc_reset_by_client,perc_fin_by_server,perc_reset_by_server" > ${CLOSE_PERC_CSV}
echo "$PERC_FIN_BY_CLIENT,$PERC_RESET_BY_CLIENT,$PERC_FIN_BY_SERVER,$PERC_RESET_BY_SERVER" >> ${CLOSE_PERC_CSV}

if ! [ $(wc -l <"${CONNEXION_OPEN_FLOATPRECISION}") -eq 0 ]; then
	sort -t ':' -k 1,1 -no "${CONNEXION_OPEN_FLOATPRECISION}" "${CONNEXION_OPEN_FLOATPRECISION}"

fi

if ! [ $(wc -l <"${CONNEXION_OPEN_INTPRECISION}") -eq 0 ]; then
	sort -t ':' -k 1,1 -no "${CONNEXION_OPEN_INTPRECISION}" "${CONNEXION_OPEN_INTPRECISION}"

fi

if ! [ $(wc -l <"${CONNEXION_NUMBER_REQUESTS}") -eq 0 ]; then
	sort -o "${CONNEXION_NUMBER_REQUESTS}" "${CONNEXION_NUMBER_REQUESTS}"
	uniq "${CONNEXION_NUMBER_REQUESTS}" "${CONNEXION_NUMBER_REQUESTS_UNIQ}"

fi

if ! [ $(wc -l <"${CONNEXION_LEN}") -eq 0 ]; then
	sort -o "${CONNEXION_LEN}" "${CONNEXION_LEN}"
	uniq "${CONNEXION_LEN}" "${CONNEXION_LEN_UNIQ}"
fi

## AGGREGATION_NUMBER_REQUESTS

grep -E '^.*aggregation.*$' "${DATA_FILE}" | while read -r line; do
	COUNT=$(echo "${line}" | sed -nE 's/^.*count: ([0-9]+),.*$/\1/p')
	echo "${COUNT}" >>"${AGGREGATION_COUNT_REQUESTS}"
done

if ! [ $(wc -l <"${AGGREGATION_COUNT_REQUESTS}") -eq 0 ]; then
	sort -o "${AGGREGATION_COUNT_REQUESTS}" "${AGGREGATION_COUNT_REQUESTS}"
	uniq "${AGGREGATION_COUNT_REQUESTS}" "${AGGREGATION_COUNT_REQUESTS_UNIQ}"
fi

echo "done extracting results"