#!/bin/bash

if [ -z ${1+x}  ]
then
    echo "first arg must be set"
    exit
fi

if ! [ -f $1  ]
then
    echo "$1 does not exist or is not a file"
    exit
fi

if ! [ -x $1  ]
then
    echo "$1 must be executable"
    exit
fi

if [ -z ${2+x}  ]
then
    echo "second arg must be set"
    exit
fi

if ! [ -f $2  ]
then
    echo "$2 does not exist or is not a file"
    exit
fi

while read -r line
do
    echo '############################################################################################'
	echo $line
    echo "$line" | xargs ./$1
    retval=$?
    echo '############################################################################################'
    if [ "$retval" -gt 0 ]
    then
        echo "script failed, exiting"
        exit
    else
        echo "script succeeded, continuing"
    fi
done < $2

echo "all executions succeded"