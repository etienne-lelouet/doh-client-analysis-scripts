if [ -z ${1+x} ]; then
	echo "please give the path to the output folder"
fi

export ENV_FILE="${1}/env"

source $ENV_FILE

export OUTFILES_BASEDIR="${1}"

export SSLKEYLOGPATH="${OUTFILES_BASEDIR}/${SSLKEYLOGFILE}"
export CAPTURE_OUTFILE="${OUTFILES_BASEDIR}/${CAPTURE_OUTFILE_FILENAME}"
export CAPTURE_CLEANED="${OUTFILES_BASEDIR}/capture_filtered.pcap"

tshark -o tls.keylog_file:"${SSLKEYLOGPATH}" -r "${CAPTURE_OUTFILE}" -Y "${RESOLVER_MATCH}" -F pcap -w "${CAPTURE_CLEANED}temp"
editcap --inject-secrets tls,"${SSLKEYLOGPATH}" "${CAPTURE_CLEANED}temp" ${CAPTURE_CLEANED}
rm -rf "${CAPTURE_CLEANED}temp"