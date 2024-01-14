#!/bin/bash
docker kill $(docker ps -q)

set -e
set -u

renum='^[0-9]+$'
reresolv='^(cloudflare)|(google)|(quad9)$'
reempty='^$'
reempty2='^\s*$'

XDISPLAY=":0"
X11_SOCKET='/tmp/.X11-unix'
NETWORK='dns-net'
NUMBER_OF_TABS=1

HEADLESS=false

SSLKEYLOGFILE='keys.log'

CONFIG_GENERAL_ROOT=$(pwd)

DOCKER_BUILD_PATH="${CONFIG_GENERAL_ROOT}/docker"
FIREFOX_DOCKERFILE_PATH="${DOCKER_BUILD_PATH}/Dockerfile-firefox"
FIREFOX_PROFILE_ROOT="${CONFIG_GENERAL_ROOT}/config-firefox/"
FIREFOX_ARCHIVE_PATH="${DOCKER_BUILD_PATH}/firefox.tar.bz2"
DNSCRYPT_DOCKERFILE_PATH="${DOCKER_BUILD_PATH}/Dockerfile-dnscrypt"

SOFTWARE="dnscrypt"
FIREFOX_DOCKER_IMAGE="etienne/firefox"
DNSCRYPT_DOCKER_IMAGE="etienne/dnscrypt-proxy"

DNSCRYPT_CONFIG_ROOT="${CONFIG_GENERAL_ROOT}/dnscrypt-proxy/config"
DNSCRYPT_CONFIG_FILE_SUFFIX='.toml'

WEBSERVER_LIST_FILE="webservers"
WEBSERVER_LIST="${CONFIG_GENERAL_ROOT}/webservers"
N_WEBSERVERS=$(wc -l <${WEBSERVER_LIST})
SCRIPT_NAME="tcp_keepalive.php"

DOMAIN_NAME_LIST_FILE="$(pwd)/queryfile-filtered/queryfiles/domainlist"

RESOLVER_MATCH_FILE="resolver_match"

YES=false

EXPERIMENT_DURATION_MINUTES="10" # 10m +2 for security
DELAY="1000"

RESET=false
EXPERIMENT="tcp-keepalive"

usage() { # Function: Print a help message.
	echo "Usage: $0 (cloudflare | quad9) [ -e RESET (if set, deletes and restore the selected profile.) ] [ -i DELAY ] [ -m DURATION_MINUTES ] [ -y YES ] [ -n NUMBER OF TABS ]"
	exit
}

if [ -z ${OUTFILES_DATA_IND+x} ]; then
	OUTFILES_DATA_IND=""
fi

if [ -z ${1+x} ]; then
	usage
fi

RESOLVER=${1}
if ! [[ ${RESOLVER} =~ ${reresolv} ]]; then
	usage
fi

shift

while getopts "i:m:f:n:eyhH" option; do
	case ${option} in
	h)
		usage
		;;
	y)
		YES=true
		;;
	e)
		RESET=true
		;;
	i)
		if ! [[ ${OPTARG} =~ ${renum} ]]; then
			echo "ERROR ! ${option}'s argument must match ${renum}"
			usage
		else
			DELAY=${OPTARG}
		fi
		;;
	m)
		EXPERIMENT_DURATION_MINUTES=${OPTARG}
		;;
	n)
		NUMBER_OF_TABS=${OPTARG}
		;;
	H)
		HEADLESS=true
		;;
	\?)
		echo "ERROR! Option ${OPTARG} is undefined"
		usage
		;;
	:)
		echo "ERROR! Option ${OPTARG} requires an argument"
		usage
		;;
	esac
done

RESOLVER_MATCH=$(grep "${RESOLVER}" "${RESOLVER_MATCH_FILE}" | sed -nE 's/^.*?:(.*)$/\1/p')

EXPERIMENT_DURATION_SECONDS=$(echo "$EXPERIMENT_DURATION_MINUTES*60" | bc)
printf -v EXPERIMENT_DURATION_SECONDS %.0f "$EXPERIMENT_DURATION_SECONDS"

FIREFOX_PROFILE_FULLPATH="${FIREFOX_PROFILE_ROOT}/no-doh"
FIREFOX_PROFILE_ARCHIVE_FULLPATH="${FIREFOX_PROFILE_FULLPATH}.tar.bz2"
DNSCRYPT_CONFIG_FULLPATH="${DNSCRYPT_CONFIG_ROOT}/config_public_resolvers/${RESOLVER}${DNSCRYPT_CONFIG_FILE_SUFFIX}"

if ! docker image ls | grep -q ${DNSCRYPT_DOCKER_IMAGE} || ! docker image ls | grep -q ${FIREFOX_DOCKER_IMAGE}; then
	docker build -t ${FIREFOX_DOCKER_IMAGE} -f ${FIREFOX_DOCKERFILE_PATH} ${DOCKER_BUILD_PATH}
	docker build -t ${DNSCRYPT_DOCKER_IMAGE} -f ${DNSCRYPT_DOCKERFILE_PATH} ${DOCKER_BUILD_PATH}
elif docker image ls | grep -q ${DNSCRYPT_DOCKER_IMAGE} && ! docker image ls | grep -q ${DNSCRYPT_DOCKER_IMAGE}; then
	docker build -t ${DNSCRYPT_DOCKER_IMAGE} -f ${DNSCRYPT_DOCKERFILE_PATH} ${DOCKER_BUILD_PATH}
fi

CONTAINER_IP='172.18.3.16'
if ! docker network ls | grep -q ${NETWORK}; then
	docker network create --subnet "172.18.3.0/24" ${NETWORK}
fi

INTERFACE="br-$(docker network ls --filter name="${NETWORK}" --format "{{.ID}}")"
HOST_ADRESS_DOCKER_NETWORK=$(docker network inspect "${NETWORK}" | jq -r '.[0].IPAM.Config[0].Gateway')

if [ ${RESET} = true ]; then
	sudo rm -rf "${FIREFOX_PROFILE_FULLPATH}" >/dev/null 2>&1
	sudo tar -xvf "${FIREFOX_PROFILE_ARCHIVE_FULLPATH}" -C "${FIREFOX_PROFILE_ROOT}/" >/dev/null 2>&1
fi

if ! [ "$HEADLESS" = true ]; then
	xhost + >/dev/null 2>&1
fi

# start iteration

DATE=$(date +%y.%m.%d-%H.%M.%S-%a)
OUTFILES_BASEDIR="${CONFIG_GENERAL_ROOT}/outfiles/results/data$OUTFILES_DATA_IND/${SOFTWARE}-${RESOLVER}/${DELAY}ms/"

if ! [ -d "${OUTFILES_BASEDIR}" ]; then
	mkdir -p "${OUTFILES_BASEDIR}"
fi

RUNFILE_FILENAME="runfile"
RUNFILE="${OUTFILES_BASEDIR}/${RUNFILE_FILENAME}"

CAPTURE_OUTFILE_FILENAME="capture.pcap"
CAPTURE_OUTFILE="${OUTFILES_BASEDIR}/${CAPTURE_OUTFILE_FILENAME}"

EXPECTED_QUERIES_OUTFILE_BOTH_FILENAME="expected_realized_both"
EXPECTED_QUERIES_OUTFILE_BOTH="${OUTFILES_BASEDIR}/${EXPECTED_QUERIES_OUTFILE_BOTH_FILENAME}"

EXPECTED_QUERIES_OUTFILE_UDP_FILENAME="expected_realized_udp"
EXPECTED_QUERIES_OUTFILE_UDP="${OUTFILES_BASEDIR}/${EXPECTED_QUERIES_OUTFILE_UDP_FILENAME}"

EXPECTED_QUERIES_OUTFILE_DOH_FILENAME="expected_realized_doh"
EXPECTED_QUERIES_OUTFILE_DOH="${OUTFILES_BASEDIR}/${EXPECTED_QUERIES_OUTFILE_DOH_FILENAME}"

EXPECTED_QUERIES_OUTFILE_ALL_FILENAME="expected_realized_all"
EXPECTED_QUERIES_OUTFILE_ALL="${OUTFILES_BASEDIR}/${EXPECTED_QUERIES_OUTFILE_ALL_FILENAME}"

DOH_QUERIES_OUTFILE_FILENAME="realized_doh"
DOH_QUERIES_OUTFILE="${OUTFILES_BASEDIR}/${DOH_QUERIES_OUTFILE_FILENAME}"

UDP_QUERIES_OUTFILE_FILENAME="realized_udp"
UDP_QUERIES_OUTFILE="${OUTFILES_BASEDIR}/${UDP_QUERIES_OUTFILE_FILENAME}"

TEMPLIST_FILENAME="expected_queries"
TEMPLIST="${OUTFILES_BASEDIR}/${TEMPLIST_FILENAME}"

NO_MATCH_FILENAME="no_match"
NO_MATCH="${OUTFILES_BASEDIR}/${NO_MATCH_FILENAME}"

ENV_FILE_FILENAME="env"
ENV_FILE="${OUTFILES_BASEDIR}/${ENV_FILE_FILENAME}"

SSLKEYLOGFILE='keys.log'
SSLKEYLOGPATH="${OUTFILES_BASEDIR}/${SSLKEYLOGFILE}"

if ! [ -f "${RUNFILE}" ]; then
	touch "${RUNFILE}"
fi

if ! [ -r "${RUNFILE}" ]; then
	chmod +r "${RUNFILE}"
fi

if ! [ -w "${RUNFILE}" ]; then
	chmod +w "${RUNFILE}"
fi

# checks that the capture output file exists and is writeable
if ! [ -f "${CAPTURE_OUTFILE}" ]; then
	touch "${CAPTURE_OUTFILE}"
fi

if ! [ -r "${CAPTURE_OUTFILE}" ]; then
	chmod +r "${CAPTURE_OUTFILE}"
fi

if ! [ -w "$CAPTURE_OUTFILE" ]; then
	chmod +w "${CAPTURE_OUTFILE}"
fi

# checks that the TLS keys dump file exists and is writeable
if ! [ -f "${SSLKEYLOGPATH}" ]; then
	touch "${SSLKEYLOGPATH}"
fi

if ! [ -r "${SSLKEYLOGPATH}" ]; then
	chmod +r "${SSLKEYLOGPATH}"
fi

if ! [ -w "${SSLKEYLOGPATH}" ]; then
	chmod +w "${SSLKEYLOGPATH}"
fi

EXPECTED_DOH_QUERIES=$(echo "($NUMBER_OF_TABS * $EXPERIMENT_DURATION_SECONDS * 1000) / $DELAY" | bc)

echo "runtime: ${EXPERIMENT_DURATION_MINUTES}m (${EXPERIMENT_DURATION_SECONDS}s), number of tabs: $NUMBER_OF_TABS, delay: ${DELAY}ms, expected queries: ${EXPECTED_DOH_QUERIES}, resolver: ${RESOLVER}, software: ${SOFTWARE}" | tee -a "${RUNFILE}"

# to be able to capture traces in non-root mode requires to be in the wireshark group and to have set-up wireshark accordingly
# To do so, run as root :
# dpkg-reconfigure wireshark-common (select "YES" at the prompt)
# usermod -a -G wireshark [YOUR USER NAME]

# run the capture and redirects output to /dev/null since all the output we need is in the capture file
tshark -i "${INTERFACE}" -w "${CAPTURE_OUTFILE}" >/dev/null 2>&1 &

# get our tshark instance's PID so we can stop it later
TSHARK_PID=$!

# waits for the capture to start
sleep 1

# allow anyone to connect to the x server (disable access control) used as a last ressort because setting and mounting XAUTHORITY did not work

# docker is run as non-root because our user is a member of the "docker" group. The docker daemon still runs as root. To add your user to the docker group, run (as root) :
# usermod -a -G docker [YOUR USER NAME]

# run firefox, pass the DISPLAY env var and mount the X11 unix socket so we can monitor execution
# pass the selected profile as arg.

CONTAINER_ID=$(
	docker run \
		-d \
		--rm \
		--network "${NETWORK}" \
		-e SSLKEYLOGFILE=/"${SSLKEYLOGFILE}" \
		-e DISPLAY="${XDISPLAY}" \
		-v "${SSLKEYLOGPATH}":/"${SSLKEYLOGFILE}" \
		-v "${X11_SOCKET}":"${X11_SOCKET}" \
		-v "${FIREFOX_PROFILE_ROOT}":"${FIREFOX_PROFILE_ROOT}" \
		-v "${DNSCRYPT_CONFIG_FULLPATH}:/config-dnscrypt" \
		--ip "${CONTAINER_IP}" \
		--dns "${CONTAINER_IP}" \
		"${DNSCRYPT_DOCKER_IMAGE}" \
		-config /config-dnscrypt
)

sleep 1

i=0
for i in $(seq 0 $((NUMBER_OF_TABS - 1))); do
	WEBSERVER_NO=$(echo "($i % $N_WEBSERVERS) + 1" | bc)
	WEBSERVER_ROOT=$(sed -n ${WEBSERVER_NO}p ${WEBSERVER_LIST})

	if [ "$WEBSERVER_ROOT" = "localhost" ]; then
		WEBSERVER_ROOT="$HOST_ADRESS_DOCKER_NETWORK"
	elif [ "$WEBSERVER_ROOT" = "container_localhost" ]; then
		WEBSERVER_ROOT="localhost"
	fi

	PAGE_URL_NOARGS="${WEBSERVER_ROOT}/"
	PAGE_URL_WITH_ARGS=$(printf "%s/%s?delay=%s&duration=%s&index=%s" "${WEBSERVER_ROOT}" "${SCRIPT_NAME}" "${DELAY}" "${EXPERIMENT_DURATION_SECONDS}" "${i}")

	if [ "$HEADLESS" = true ]; then
		docker exec \
			-d \
			-e SSLKEYLOGFILE="/${SSLKEYLOGFILE}" \
			"${CONTAINER_ID}" \
			"/firefox/firefox" \
			--profile "${FIREFOX_PROFILE_FULLPATH}" \
			--new-tab --url "${PAGE_URL_WITH_ARGS}" \
			--headless
	else
		docker exec \
			-d \
			-e SSLKEYLOGFILE="/${SSLKEYLOGFILE}" \
			"${CONTAINER_ID}" \
			"/firefox/firefox" \
			--profile "${FIREFOX_PROFILE_FULLPATH}" \
			--new-tab --url "${PAGE_URL_WITH_ARGS}"
	fi
	sleep 1
done

./timer.sh $((EXPERIMENT_DURATION_SECONDS + 10))

docker stop "${CONTAINER_ID}"

# re enables X server access control
if ! [ $HEADLESS = true ]; then
	xhost - >/dev/null 2>&1
fi

# stops the capture
kill "${TSHARK_PID}"

# [OPTIONAL] launch wireshark. -o option sets the path to the file containing the enciphering keys used by firefox
# wireshark -o tls.keylog_file:${SSLKEYLOGPATH} -f "ip.addr == ${RESOLVER_MATCH}" ${CAPTURE_OUTFILE} &

>$ENV_FILE

env_save="reempty reempty2 OUTFILES_BASEDIR NO_MATCH_FILENAME SSLKEYLOGFILE TEMPLIST_FILENAME CAPTURE_OUTFILE_FILENAME UDP_QUERIES_OUTFILE_FILENAME DOH_QUERIES_OUTFILE_FILENAME RESOLVER_MATCH RUNFILE_FILENAME EXPECTED_QUERIES_OUTFILE_BOTH_FILENAME EXPECTED_QUERIES_OUTFILE_DOH_FILENAME EXPECTED_QUERIES_OUTFILE_UDP_FILENAME EXPECTED_QUERIES_OUTFILE_ALL_FILENAME EXPECTED_DOH_QUERIES ENV_FILE_FILENAME DOMAIN_NAME_LIST_FILE"

for t in ${env_save[@]}; do
	echo "export $t='${!t}'" | tee -a "$ENV_FILE"
done

if [ "$YES" = true ]; then
	echo "parsing results"
	bash parse_results_parallel.sh ${OUTFILES_BASEDIR}
	bash outfiles/gen_queries.sh "${OUTFILES_BASEDIR}"
	# bash parse_results_parallel.sh ${OUTFILES_BASEDIR}
else
	echo "not parsing results"
fi
