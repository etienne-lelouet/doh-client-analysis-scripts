#!/bin/bash

TEMP_OUTPUT_FILE=${RUNFILE}_temp$(cat /proc/sys/kernel/random/uuid)

echo "JOB $1/$2"
echo "$3"

read -r SRCIP_SRCPORT DSTIP_DSTPORT RELATIVE_START DURATION <<<$(echo "${3}" | tr -s ' ' | sed -nE 's/^(([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]+)\s<->\s(([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]+)(\s([0-9]+\s([0-9]+[\.,]?[0-9]*)\s?[a-zA-Z]+)){3}\s([0-9]+[\.,]?[0-9]*)\s([0-9]+[\.,]?[0-9]*)$/\1 \3 \8 \9/p')
read -r SRCIP SRCPORT <<<$(echo "${SRCIP_SRCPORT}" | cut -d ':' --output-delimiter=" " -f 1,2)
read -r DSTIP DSTPORT <<<$(echo "${DSTIP_DSTPORT}" | cut -d ':' --output-delimiter=" " -f 1,2)

CONVERSATION_FILTER="(ip.addr eq ${SRCIP} and ip.addr eq ${DSTIP}) and (tcp.port eq ${SRCPORT} and tcp.port eq ${DSTPORT})"

NUMBER_DOH_QUERIES_IN_STREAM=$(tshark -r "${CAPTURE_CLEANED}" -Y "${CONVERSATION_FILTER} && (http2 && dns && dns.qry.type == 1 && dns.flags.response == 0)" -T fields -e frame.time_relative 2>/dev/null | tr ',' '[\n*]' | wc -l)

read -r TERM_SRCPORT FIN RESET <<<$(tshark -r "${CAPTURE_CLEANED}" -Y "${CONVERSATION_FILTER} && (tcp.flags.fin == 1 or tcp.flags.reset == 1)" -T fields -e tcp.srcport -e tcp.flags.fin -e tcp.flags.reset 2>/dev/null | head -n 1)

if [ -z ${TERM_SRCPORT} ]; then
	echo "TERM_SRCPORT empty !"
	FIN=0
	RESET=0
	CLOSED_BY="NOT_CLOSED"
else
	CLOSED_BY=$([ "$TERM_SRCPORT" -eq "$SRCPORT" ] && echo "CLIENT" || echo "SERV")
fi

echo "${SRCIP}":"${SRCPORT}",queries: "${NUMBER_DOH_QUERIES_IN_STREAM}",relative_start: "${RELATIVE_START}",duration: "${DURATION}",closed_by: "$CLOSED_BY",fin: "${FIN}",reset: "${RESET}" >> "${TEMP_OUTPUT_FILE}"

# tshark -r "${CAPTURE_CLEANED}" -Y "${CONVERSATION_FILTER} && http2 && dns && dns.qry.type == 1 && dns.flags.response == 0" -T fields -e frame.time_relative -e dns.qry.name | grep -E '^.*?,.*$' | while read -r group; do
# 	count=$(echo "${group}" | tr ',' '[\n*]' | wc -l)
# 	date=$(echo "${group}" | sed -nE 's/^(.*)+\s+.*$/\1/p')
# 	names=$(echo "${group}" | sed -nE 's/^.*+\s+(.*)$/\1/p')
# 	echo "aggregation: date: ${date} count: ${count}, names:\"${names}\"" >> "${TEMP_OUTPUT_FILE}"
# done
