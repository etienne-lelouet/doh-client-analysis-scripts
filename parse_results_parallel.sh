#!/bin/bash
if [ -z ${1+x} ]; then
	echo "please give the path to the output folder"
fi

export ENV_FILE="${1}/env"

source $ENV_FILE

export OUTFILES_BASEDIR="${1}"

export RUNFILE="${OUTFILES_BASEDIR}/${RUNFILE_FILENAME}"
export CAPTURE_OUTFILE="${OUTFILES_BASEDIR}/${CAPTURE_OUTFILE_FILENAME}"
export EXPECTED_QUERIES_OUTFILE_BOTH="${OUTFILES_BASEDIR}/${EXPECTED_QUERIES_OUTFILE_BOTH_FILENAME}"
export EXPECTED_QUERIES_OUTFILE_UDP="${OUTFILES_BASEDIR}/${EXPECTED_QUERIES_OUTFILE_UDP_FILENAME}"
export EXPECTED_QUERIES_OUTFILE_DOH="${OUTFILES_BASEDIR}/${EXPECTED_QUERIES_OUTFILE_DOH_FILENAME}"
export EXPECTED_QUERIES_OUTFILE_ALL="${OUTFILES_BASEDIR}/${EXPECTED_QUERIES_OUTFILE_ALL_FILENAME}"
export DOH_QUERIES_OUTFILE="${OUTFILES_BASEDIR}/${DOH_QUERIES_OUTFILE_FILENAME}"
export UDP_QUERIES_OUTFILE="${OUTFILES_BASEDIR}/${UDP_QUERIES_OUTFILE_FILENAME}"
export TEMPLIST="${OUTFILES_BASEDIR}/${TEMPLIST_FILENAME}"
export NO_MATCH="${OUTFILES_BASEDIR}/${NO_MATCH_FILENAME}"
export ENV_FILE="${OUTFILES_BASEDIR}/${ENV_FILE_FILENAME}"
export SSLKEYLOGPATH="${OUTFILES_BASEDIR}/${SSLKEYLOGFILE}"

export CAPTURE_CLEANED="${OUTFILES_BASEDIR}/capture_filtered.pcap"

tshark -o tls.keylog_file:"${SSLKEYLOGPATH}" -r "${CAPTURE_OUTFILE}" -Y "${RESOLVER_MATCH}" -F pcap -w "${CAPTURE_CLEANED}temp" 2>/dev/null
editcap --inject-secrets tls,"${SSLKEYLOGPATH}" "${CAPTURE_CLEANED}temp" ${CAPTURE_CLEANED} 2>/dev/null
rm -rf "${CAPTURE_CLEANED}temp"

# to ensure we correctly emptied the runfile
RUNFILE_HEAD=$(head -n 1 $RUNFILE)
echo "####################################${RUNFILE_HEAD}####################################"
echo "$RUNFILE_HEAD" >$RUNFILE

tshark -r "${CAPTURE_OUTFILE}" -Y "dns && udp && dns.qry.type == 1 && dns.flags.response == 0" -T fields -e dns.qry.name 2>/dev/null | tr ',' '\n' >${UDP_QUERIES_OUTFILE}
export N_DNS_QUERIES=$(wc -l <${UDP_QUERIES_OUTFILE})
echo "counted UDP queries"

tshark -r "${CAPTURE_CLEANED}" -Y "dns && http2 && dns.qry.type == 1 && dns.flags.response == 0" -T fields -e dns.qry.name 2>/dev/null | tr ',' '\n' >${DOH_QUERIES_OUTFILE}
export N_DOH_QUERIES=$(wc -l <${DOH_QUERIES_OUTFILE})
echo "counted DOH queries"

printf "dns_queries: %d - doh_queries: %d\n" "${N_DNS_QUERIES}" "${N_DOH_QUERIES}" >>"${RUNFILE}"

export NUMBER_TCP_STREAMS=$(tshark -r "${CAPTURE_CLEANED}" -qz conv,tcp 2>/dev/null | grep -Ec '^.*?[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*$')
printf "number_tcp_streams: %d\n" ${NUMBER_TCP_STREAMS} >>"${RUNFILE}"

echo "parsing $NUMBER_TCP_STREAMS conversations"

tshark -r "${CAPTURE_CLEANED}" -qz conv,tcp | grep -E '^.*?[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*$' | parallel "./stream-parse_code.sh {#} $NUMBER_TCP_STREAMS {}"

cat ${RUNFILE}_temp* >${RUNFILE}aggreg

sort ${RUNFILE}aggreg >${RUNFILE}aggreg_sorted

cat ${RUNFILE} ${RUNFILE}aggreg_sorted >${RUNFILE}_tmp

mv ${RUNFILE}_tmp ${RUNFILE}

rm ${RUNFILE}_temp* ${RUNFILE}aggreg ${RUNFILE}aggreg_sorted

head -n "${EXPECTED_DOH_QUERIES}" "${DOMAIN_NAME_LIST_FILE}" >"${TEMPLIST}"

>"${EXPECTED_QUERIES_OUTFILE_BOTH}"
>"${EXPECTED_QUERIES_OUTFILE_DOH}"
>"${EXPECTED_QUERIES_OUTFILE_UDP}"
>"${NO_MATCH}"

NCPUS=$(cat /proc/cpuinfo | grep processor | wc -l)

split -n l/"${NCPUS}" "${TEMPLIST}" "${TEMPLIST}_split"

parallel ./dns_filelist-parse_code.sh "{} {#} ${NCPUS}" ::: "${TEMPLIST}_split"*

rm "${TEMPLIST}_split"*

if ls ${OUTFILES_BASEDIR} | grep "${EXPECTED_QUERIES_OUTFILE_DOH_FILENAME}_temp"; then
	cat "${EXPECTED_QUERIES_OUTFILE_DOH}_temp"* >${EXPECTED_QUERIES_OUTFILE_DOH}
	rm -f "${EXPECTED_QUERIES_OUTFILE_DOH}_temp"*
fi

if ls ${OUTFILES_BASEDIR} | grep "${EXPECTED_QUERIES_OUTFILE_UDP_FILENAME}_temp"; then
	cat "${EXPECTED_QUERIES_OUTFILE_UDP}_temp"* >${EXPECTED_QUERIES_OUTFILE_UDP}
	rm -f "${EXPECTED_QUERIES_OUTFILE_UDP}_temp"*
fi

if ls ${OUTFILES_BASEDIR} | grep "${EXPECTED_QUERIES_OUTFILE_BOTH_FILENAME}_temp"; then
	cat "${EXPECTED_QUERIES_OUTFILE_BOTH}_temp"* >${EXPECTED_QUERIES_OUTFILE_BOTH}
	rm -f "${EXPECTED_QUERIES_OUTFILE_BOTH}_temp"*
fi

if ls ${OUTFILES_BASEDIR} | grep "${NO_MATCH_FILENAME}_temp"; then
	cat "${NO_MATCH}_temp"* >${NO_MATCH}
	rm -f "${NO_MATCH}_temp"*
fi

FOUND_EXPECTED_DOH_QUERIES=$(wc -l <"${EXPECTED_QUERIES_OUTFILE_DOH}")
echo "FOUND_EXPECTED_DOH_QUERIES=${FOUND_EXPECTED_DOH_QUERIES}"
FOUND_EXPECTED_DNS_QUERIES=$(wc -l <"${EXPECTED_QUERIES_OUTFILE_UDP}")
echo "FOUND_EXPECTED_DNS_QUERIES=${FOUND_EXPECTED_DNS_QUERIES}"
FOUND_EXPECTED_BOTH_QUERIES=$(wc -l <"${EXPECTED_QUERIES_OUTFILE_BOTH}")
echo "FOUND_EXPECTED_BOTH_QUERIES=${FOUND_EXPECTED_BOTH_QUERIES}"
NO_MATCH_QUERIES=$(wc -l <"${NO_MATCH}")
echo "NO_MATCH_QUERIES=${NO_MATCH_QUERIES}"

cat "${EXPECTED_QUERIES_OUTFILE_DOH}" "${EXPECTED_QUERIES_OUTFILE_UDP}" "${EXPECTED_QUERIES_OUTFILE_BOTH}" | sort -u >"${EXPECTED_QUERIES_OUTFILE_ALL}"

NUMBER_UNIQ_EXPECTED_QUERIES=$(wc -l <"${EXPECTED_QUERIES_OUTFILE_ALL}")
echo "NUMBER_UNIQ_EXPECTED_QUERIES: ${NUMBER_UNIQ_EXPECTED_QUERIES}" >>"${RUNFILE}"

cat "$RUNFILE"

>"/tmp/max_queries_responses_value"
>"/tmp/max_queries_responses_values_tmp"
tshark -r "${CAPTURE_CLEANED}" -Y "dns && http2 && dns.flags.response == 0" -T fields -e dns.qry.name | tr ',' '\n' | wc -l >>"/tmp/max_queries_responses_values_tmp"
tshark -r "${CAPTURE_CLEANED}" -Y "dns && http2 && dns.flags.response == 1" -T fields -e dns.qry.name | tr ',' '\n' | wc -l >>"/tmp/max_queries_responses_values_tmp"
cat "/tmp/max_queries_responses_values_tmp"
cat "/tmp/max_queries_responses_values_tmp" | tr ' ' '\n' | sort -g | tail -n 1 >"/tmp/max_queries_responses_value"

# bash outfiles_data_extract.sh ${OUTFILES_BASEDIR}
