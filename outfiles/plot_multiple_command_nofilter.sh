#!/bin/bash

DELAYS_TOKEEP="^.*(50ms|1000ms|60000ms).*$"

SOFTWARE_NAME=$1

echo "looking for all hdfs with SOFTWARE: $SOFTWARE_NAME" >&2

find data/ -type f -wholename *"$SOFTWARE_NAME"*/runfile.hdf | sort -t/ -k2,2 -k3,3n | grep -E "$DELAYS_TOKEEP"

