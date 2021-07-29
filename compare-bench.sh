#!/bin/bash

# -------------------- Preprocessing -------------------- #

CONFIG_STDDEV="no"

SCRIPT_DIR=$PWD
source ${SCRIPT_DIR}/_message.sh

# -------------------- Function  -------------------- #

function func_usage() {
	echo "./compare-bench [-sh] [-b bench_name] [-d directory] [-t tests]"
}

function in_array() {
	local needle array value
	needle="${1}"
	shift
	array=("${@}")

	for value in ${array[@]}; do
		[ "${value}" == "${needle}" ] && echo "true" && return;
	done

	echo "false"
}


# -------------------- Script Start  -------------------- #

ARGS=`getopt -o b:d:t:sh --long bench_name:,directory:,tests:,stddev,help -n compare-bench.sh -- "$@"`
#echo $?
if [ $? -ne 0 ]; then
        echo "Terminating..." >&2
        func_usage
        exit 1
fi

eval set -- "${ARGS}"
while true; do
        case "$1" in
                -b|--bench-name)
                        BENCH_NAME="$2"
                        shift 2
                        ;;
                -d|--directory)
                        LOG_DIR="$2"
                        shift 2
                        ;;
                -t|--tests)
			TMP="$2"
			OLD_IFS="$IFS"
			IFS=","
			TESTS=( $TMP )
			IFS="$OLD_IFS"
                        shift 2
                        ;;
		-s|--stddev)
			CONFIG_STDDEV="yes"
			shift 1
			;;
                -h|--help)
                        func_usage
                        exit
                        ;;
                --)
                        break
                        ;;
                *)
                        info ERROR: Unrecognized option $1
                        func_usage
                        exit -1
                        ;;
        esac
done

if [ -z  "${BENCH_NAME}" ]; then
        echo "ERROR: Benchmark name parameter must be specified"
        func_usage
        exit -1
fi

RESULTS=()
STDDEVS=()
for TEST in ${TESTS[@]}; do
	ITERS=($(ls ${LOG_DIR}/${TEST}))
	RESULT_ITER=()
	SUM=0
	for ITER in ${ITERS[@]}; do
		OUTPUT_LOG=${LOG_DIR}/${TEST}/${ITER}/output.log
		case ${BENCH_NAME} in
			"graphmat")
				METRIC="PR Time"
				RESULT=$(cat $OUTPUT_LOG | grep "${METRIC}" | awk '{print $(NF-1)}')
				METRIC="PR_Time(ms)"
				;;
			"graph500")
				METRIC="harmonic_mean"
				RESULT=$(cat $OUTPUT_LOG | grep "${METRIC}" | awk '{print $(NF)}')
				METRIC="harmonic_mean_TEPS"
				;;
			"553.pclvrleaf")
				METRIC="Wall clock"
				RESULT=$(cat $OUTPUT_LOG | grep -A1 finishing | grep "${METRIC}" | awk '{print $(NF)}')
				METRIC="Wall_clock"
				;;
			"555.pseismic")
				METRIC="Elapsed time in seconds"
				RESULT=$(cat $OUTPUT_LOG | grep "${METRIC}" | awk '{print $(NF)}' | tail -1)
				METRIC="Elapsed_time(s)"
				;;
			"liblinear")
				METRIC="train_time"
				RESULT=$(cat $OUTPUT_LOG | grep "${METRIC}" | awk '{print $(NF)}')
				METRIC="train_time(s)"
				;;
			*)
				METRIC="execution_time"
				RESULT=$(cat $OUTPUT_LOG | grep --binary-files=text "${METRIC}" | awk '{print $(NF-1)}')
				;;
		esac
		RESULT_ITER+=( "${RESULT}" )
	done
	RESULT_AVG=$(./average.py ${RESULT_ITER[@]})
	RESULTS+=( "${RESULT_AVG}" )
	STDDEV=$(./stddev.py ${RESULT_ITER[@]})
	STDDEVS+=( "${STDDEV}" )

	echo $METRIC ${RESULT_ITER[@]} > ${LOG_DIR}/$TEST-result.log
done

# Processing result
TMPS="${RESULTS[@]}"
results=$(
printf "${METRIC},"
for tmp in ${TMPS[@]}; do
	printf ${tmp}
	printf ","
done
)
results=${results%,}

# Processing stddev
TMPS="${STDDEVS[@]}"
stddevs=$(
printf "stddev,"
for tmp in ${TMPS[@]}; do
	printf ${tmp}
	printf ","
done
)
stddevs=${stddevs%,}

if [[ $CONFIG_STDDEV == "yes" ]]; then
	echo ${stddevs}
else
	echo ${results}
fi
