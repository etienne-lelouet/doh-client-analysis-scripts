#!/bin/bash

if [ -z ${OAR_JOB_ID+x} ]; then
    echo "OAR_JOB_ID is not set, using first job return by oarstat -u"
    OAR_JOB_ID=$(oarstat -u | sed -nE '0,/^([0-9]+)\s+.*$/{s/^([0-9]+)\s+.*$/\1/p}')
    if [ -z ${OAR_JOB_ID} ]; then
        echo 'OAR_JOB_ID is still unset, did you make a reservation ?'
        exit
    fi
    export OAR_JOB_ID=$OAR_JOB_ID
fi

NODELISTFILE='NODELIST'
>"$NODELISTFILE"
oarprint host | tee -a "$NODELISTFILE"

if ! [ -z $1 ]; then
    read -p "Running with one arg will deploy the dns-g5k image on all nodes, this will take several minutes,  Are you sure? " -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kadeploy3 -k -e dns-g5k -f "$NODELISTFILE"

    fi

fi

sort -u "$OAR_NODE_FILE" >"$NODELISTFILE"
echo $OAR_JOB_ID >JOBID

TARGET=$(sed -n '1p' "$NODELISTFILE")

ssh root@"${TARGET}" "mkdir -p /root/tcp-keepalive"
rsync -a --progress ./ root@"${TARGET}":~/tcp-keepalive/

ssh -t root@"${TARGET}" "cd /root/tcp-keepalive ; bash --login"
