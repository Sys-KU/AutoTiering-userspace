#!/bin/bash

GRAPH_DIR="./make_graph"

if [ $EUID -ne 0 ]; then
    echo "Please run as root or sudo"
    exit -1
fi

function func_usage() {
	echo
	echo "$0 [-h] [-b benchmark] [-d date]"
	echo "-b| --benchmark  Select to run benchamrk. e.g) specjbb2015, graph500-omp, etc."
	echo "-d| --date	Set benchmark start time. "
	echo "-h| --help        Prints this help."
	echo
}

# Script Start
ARGS=`getopt -o b:d:h --long benchmark:,date:,help -n make_graph.sh -- "$@"`
if [ $? -ne 0 ]; then
	echo "Terminating..." >&2
	func_usage
	exit 1
fi

declare -a CONFIG
export CONFIG
eval set -- "${ARGS}"

while true; do
	case "$1" in
		-b|--benchmark)
			BENCH="$2"
			shift 2
			;;
		-d|--date)
			DATE="$2"
			shift 2
			;;
		-h|--help)
			func_usage
			exit
			;;
		--)
			break
			;;
		*)
			echo "ERROR: Unrecognized option $1"
			func_usage
			exit
			;;
	esac
done

if [ -z  "${BENCH}" ]; then
	echo "ERROR: Benchmark name parameter must be specified"
	func_usage
	exit -1
fi

${GRAPH_DIR}/result.py -b ${BENCH} -d ${DATE}
${GRAPH_DIR}/meminfo.py -b ${BENCH} -d ${DATE}
${GRAPH_DIR}/meminfo_v2.py -b ${BENCH} -d ${DATE}
${GRAPH_DIR}/lapinfo.py -b ${BENCH} -d ${DATE}
${GRAPH_DIR}/migration_stat.py -b ${BENCH} -d ${DATE}
${GRAPH_DIR}/migration_fail.py -b ${BENCH} -d ${DATE}

echo "Make graphs Done!"
