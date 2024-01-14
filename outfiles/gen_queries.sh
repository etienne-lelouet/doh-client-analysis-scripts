SCRIPTPATH="$(
	cd -- "$(dirname "$0")" >/dev/null 2>&1
	pwd -P
)"

export renum='^-?[0-9]+$'

export cache=false
export max_queries=false
export display=false

TEMP=$(getopt -n gen_queries.sh -o '' --long cache,display, -- "$@")

if [ $? != 0 ]; then
	echo "Terminating..." >&2
	exit 1
fi

eval set -- "$TEMP"

while true; do
	case "$1" in
	-max_queries)
		if [[ "$2" =~ $renum ]]; then
			export max_queries="$2"
		else
			printf "max_queries does not match expected pattern: expected %s, found %s\n" "$renum" "$2"
			exit 1
		fi
		shift 2
		;;
	--cache)
		export cache=true
		shift
		;;
	--display)
		export display=true
		shift
		;;
	--)
		shift
		break
		;;
	*)
		echo "Internal error!"
		exit 1
		;;
	esac
done

if ! [ -z ${1+x} ]; then
	if ! [ -z ${1} ]; then
		if ! [ -d $1 ]; then
			echo "$1 is not a directory"
			exit
		fi
	else
		echo "$1 is not a directory"
		exit
	fi
else
	echo "$1 is not a directory"
	exit
fi
export f="$1"

echo $f

source "$SCRIPTPATH/.env/bin/activate"

if ! [ -f "$f/runfile" ]; then
	echo "$f/runfile does not exist"
	exit
else
	ls -lah "$f/runfile"
fi

if ! [ -f "$f/runfile.hdf" ]; then
	echo "$f/runfile.hdf does not exist"
	"$SCRIPTPATH/parse_run_file.py" \
		--input "$f/runfile" \
		--output "$f/runfile.hdf" \
		--outputExpected "$f/queriesexpected.hdf"
elif [ $cache = true ]; then
	echo "using cache for $f/runfile.hdf"
else
	echo "ignoring cache for $f/runfile.hdf"
	"$SCRIPTPATH/parse_run_file.py" \
		--input "$f/runfile" \
		--output "$f/runfile.hdf" \
		--outputExpected "$f/queriesexpected.hdf"
fi

if ! [ -f "$f/queries.csv" ]; then
	echo "$f/queries.csv does not exist"
	tshark -r "$f/capture_filtered.pcap" -Y "dns && http2 && dns.flags.response == 0" -T fields -e frame.time_relative -e dns.qry.name -E separator=, -E aggregator=";" -E header=y >"$f/queries.csv"
elif [ $cache = true ]; then
	echo "using cache for $f/queries.csv"
else
	echo "ignoring cache for $f/queries.csv"
	tshark -r "$f/capture_filtered.pcap" -Y "dns && http2 && dns.flags.response == 0" -T fields -e frame.time_relative -e dns.qry.name -E separator=, -E aggregator=";" -E header=y >"$f/queries.csv"
fi

if ! [ -f "$f/responses.csv" ]; then
	echo "$f/responses.csv does not exist"
	tshark -r "$f/capture_filtered.pcap" -Y "dns && http2 && dns.flags.response == 1" -T fields -e frame.time_relative -e dns.qry.name -E separator=, -E aggregator=";" -E header=y >"$f/responses.csv"
elif [ $cache = true ]; then
	echo "using cache for $f/responses.csv"
else
	echo "ignoring cache for $f/responses.csv"
	tshark -r "$f/capture_filtered.pcap" -Y "dns && http2 && dns.flags.response == 1" -T fields -e frame.time_relative -e dns.qry.name -E separator=, -E aggregator=";" -E header=y >"$f/responses.csv"
fi

if ! [ -f "$f/capture_filtered.hdf" ]; then
	echo "$f/capture_filtered.hdf does not exist"
	"$SCRIPTPATH/parse_requests_csv.py" \
		--input-queries "$f/queries.csv" \
		--input-responses "$f/responses.csv" \
		--output "$f/capture_filtered.hdf"
elif [ $cache = true ]; then
	echo "using cache for $f/capture_filtered.hdf"
else
	echo "ignoring cache for $f/capture_filtered.hdf"
	"$SCRIPTPATH/parse_requests_csv.py" \
		--input-queries "$f/queries.csv" \
		--input-responses "$f/responses.csv" \
		--output "$f/capture_filtered.hdf"
fi

"$SCRIPTPATH/plot_gantt_style.py" \
	--height 8.0 --height-ratio 80 \
	--input-connections "$f/runfile.hdf" \
	--output "$f/profile.svg"

if ! [ -f "$f/profile.svg" ]; then
	echo "$f/profile.svg does not exist"
	exit
else
	ls -lah "$f/profile.svg"

	if [ $display = true ]; then
		xdg-open "$f/profile.svg"
	fi
fi
