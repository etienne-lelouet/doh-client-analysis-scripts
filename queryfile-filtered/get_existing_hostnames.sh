#!/bin/bash

input="Arecords_clean"
output="noerror_Arecords"
output_error="error_Arecords"

i=0
error=0
noerror=0
max=$(wc -l < ${input})

echo -n "" > ${output}
echo -n "" > ${output_error}

while IFS= read -r line
do
    STATUS=$(dig $line | sed -nE 's/^.*?status: ([A-Z]+),.*$/\1/p')
    if ! [[ ${STATUS} == "NOERROR" ]]; then
        echo -e ${line} | sed -nE 's/^(\S*+).*$/\1/p' >> ${output_error}
        ((error=error+1))
    else 
        echo -e ${line} | sed -nE 's/^(\S*+).*$/\1/p' >> ${output}
        ((noerror=noerror+1))
    fi
    ((i=i+1))
    echo -ne "\033[2K\r${i}/${max}, error: ${error} , noerror: ${noerror}"
done < "$input"