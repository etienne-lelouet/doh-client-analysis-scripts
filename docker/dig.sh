#!/bin/bash

NREQUESTS=600
DELAY=50
DOMAINLIST_PATH='/home/etienne/stage/perfs-doh/benchs/tcp-keepalive/domains'
renum='^[0-9]+$'

usage() { # Function: Print a help message.
    echo "Usage: $0 [ -i DELAY ] [ -m NREQUESTS ] [ -p PATH_TO_DOMAINLIST ]"
    exit
}

while getopts ":i:p:n:m:f:p:r:t:c:eh" option; do
    case ${option} in
    i)
        if ! [[ ${OPTARG} =~ ${renum} ]]; then
            echo "ERROR ! ${option}'s argument must match ${renum}"
            usage
        else
            DELAY=${OPTARG}
        fi
        ;;
    m)
        if ! [[ ${OPTARG} =~ ${renum} ]]; then
            echo "ERROR ! ${option}'s argument must match ${renum}"
            usage
        else
            NREQUESTS=${OPTARG}
        fi
        ;;
    p)
        if ! [ -f "${OPTARG}" ]; then
            printf '%s Does not exist\n' ${OPTARG}
            exit
        fi
        if ! [ -r "${OPTARG}" ]; then
            printf '%s is not writeable\n' ${OPTARG}
            exit
        fi
        DOMAINLIST_PATH="${OPTARG}"
        ;;
    ?)
        echo "ERROR! Option ${OPTARG} is undefined"
        usage
        ;;
    :)
        echo "ERROR! Option ${OPTARG} requires an argument"
        usage
        ;;
    esac
done

head -n "${NREQUESTS}" "${DOMAINLIST_PATH}" | /digdrift "${DELAY}"

# DELAY=$(echo "scale=4; ${DELAY}/1000" | bc -l | awk '{printf "%.4f\n", $0}')

# for i in $(seq 1 "${NREQUESTS}"); do
#     DOMAINNAME=$(sed -n "${i}p" ${DOMAINLIST_PATH})
#     printf '%s: %d/%d\n' "${DOMAINNAME}" "${i}" "${NREQUESTS}"
#     dig "${DOMAINNAME}" >/dev/null 2>&1 &
#     sleep ${DELAY}
# done
