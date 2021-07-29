#!/bin/bash
export SCRIPTDIR=$(pwd)
source $SCRIPTDIR/_message.sh

TRACE_DIR=./traces
HISTORY=./run_history

DATES=()
BENCH_NAME=""
CONFIG_ALL=0
CONFIG_PRINT=0
CONFIG_PRINT_TARGET=""
CONFIG_NODE_MEMINFO=0
CONFIG_MIGRATION_STAT=0
CONFIG_RECENT=0

function func_usage() {
	echo "$0 [-amnrh] [-b benchmark] [-d date] [-p print_target]"
	echo "-b| --benchmark      Select to run benchamrk        e.g) graph500, graphmat, etc."
	echo "-d| --date           Date of run benchmark          e.g) 202001142237"
	echo "-a| --all            Collect all data on target Benchmark"
	echo "-p| --print          Print benchmark result, vmstat and summary or all e.g) result, vmstat, summary, all"
	echo "-m| --migration-stat Totalize page migration(promotion, demotion, else)"
	echo "-n| --node-meminfo   Totalize Active and Inactive memory per node"
	echo "-r| --recent         Collect recently executed Benchmark results"
	echo "-h| --help           Print this help"
	echo
}

function func_collect_data() {
	local tests=("$@")
	BENCH_LOG_DIR=./logs/${BENCH_NAME}
	RESULT_LOG="${BENCH_LOG_DIR}/${DATE}-*-result.log"
	VMSTAT_LOG="${BENCH_LOG_DIR}/${DATE}-*-vmstat.log"
	SUMMARY_LOG="${BENCH_LOG_DIR}/${DATE}-summary.log"
	STDDEV_LOG="${BENCH_LOG_DIR}/${DATE}-stddev.log"
	TEST_NUM=0

	if [[ ! -w ${BENCH_LOG_DIR} ]]; then
		sudo chown $(logname):sudo ${BENCH_LOG_DIR}
	fi

	tests=$(
	for test in ${tests[@]}; do
		TEST_CHECK=$(ls ${BENCH_LOG_DIR} | grep ${test})
		if [[ -z ${TEST_CHECK} ]]; then
			continue
		fi
		printf ${test}
		printf ","
	done
	)
	tests=${tests%,}
	TEST_NUM=$(echo $tests | awk -F "," '{print NF}')

	if [ ${CONFIG_PRINT} -eq 1 ]; then
		case ${CONFIG_PRINT_TARGET} in
			"result"|"iter"|"iteration")
				cat ${RESULT_LOG}
				;;
			"vmstat")
				cat ${VMSTAT_LOG}
				;;
			"summary")
				cat ${SUMMARY_LOG}
				;;
			"stddev")
				cat ${STDDEV_LOG}
				;;
			"all")
				cat ${VMSTAT_LOG}; echo
				cat ${RESULT_LOG}; echo
				cat ${SUMMARY_LOG}
				;;
			*)
				err "ERROR: ${CONFIG_PRINT_TARGET} is unavailable print target"
				func_usage
				exit -1
				;;
		esac
		return 0;
	fi

	./compare-bench.sh -d ${BENCH_LOG_DIR} -b ${BENCH_NAME} --tests ${tests} > ${SUMMARY_LOG}
	./compare-bench.sh -d ${BENCH_LOG_DIR} -b ${BENCH_NAME} --tests ${tests} --stddev > ${STDDEV_LOG}
}

# Script Start
ARGS=`getopt -o b:d:p:amnrh --long benchmark:,date:,print:,all,migration-stat,node-meminfo,recent,help -n collect_data.sh -- "$@"`
#echo $?
if [ $? -ne 0 ]; then
	info "Terminating..." >&2
	func_usage
	exit 1
fi

eval set -- "${ARGS}"
while true; do
	case "$1" in
		-b|--benchmark)
			BENCH_NAME="$2"
			export BENCH_NAME
			shift 2
			;;
		-d|--date)
			DATE="$2"
			shift 2
			;;
		-a|--all)
			CONFIG_ALL=1
			shift
			;;
		-p|--print)
			CONFIG_PRINT=1
			CONFIG_PRINT_TARGET="$2"
			shift 2
			;;
		-n|--node-meminfo)
			CONFIG_NODE_MEMINFO=1
			shift 1
			;;
		-m|--migration-stat)
			CONFIG_MIGRATION_STAT=1
			shift 1
			;;
		-r|--recent)
			CONFIG_RECENT=1
			shift 1;
			;;
		-h|--help)
			func_usage
			exit
			;;
		--)
			break
			;;
		*)
			err "ERROR: Unrecognized option $1"
			func_usage
			exit
			;;
	esac
done

if [ ${CONFIG_RECENT} -eq 1 ]; then
	if [ ! -e ${HISTORY} ]; then
		err "history file not exist!"
		func_usage
		exit -1
	fi
	BENCH_NAME=$(cat ${HISTORY} | tail -n 1 | awk '{print $3}')
	export BENCH_NAME
	DATE=$(cat ${HISTORY} | tail -n 1 | awk '{print $5}')
	CONFIG_NODE_MEMINFO=1
	CONFIG_MIGRATION_STAT=1
fi

if [ -z  "${BENCH_NAME}" ]; then
	err "ERROR: Benchmark name parameter must be specified"
	func_usage
	exit -1
elif [ -z  "${DATE}" ]; then
	if [ ${CONFIG_ALL} -eq 1 ]; then
		DATES=$(ls -l logs/${BENCH_NAME}/ | awk '{print $9}' | awk -F - '{print $1}' | sort -u); 
		DATE=""
	else
		err "ERROR: Date parameter must be specified"
		func_usage
		exit -1
	fi
else
	if [ ${CONFIG_PRINT} -eq 1 ]; then
		case ${CONFIG_PRINT_TARGET} in
			"vmstat"|"result"|"summary"|"all"|"stddev")
				;;
			*)
				err "ERROR: Print target is unavailable"
				func_usage
				exit -1
				;;
		esac
	fi
fi



DATES+=( "${DATE}" )

for DATE in ${DATES[@]}; do
	TESTS=($(ls logs/${BENCH_NAME} | grep ${DATE}- | grep -v "log" | sort))
	info "(${BENCH_NAME}, ${DATE}): Data is collecting..."
	for TEST in ${TESTS[@]}; do

		if [ ${CONFIG_PRINT} -eq 1 ]; then
			continue
		fi
		sudo find logs/${BENCH_NAME}/${TEST} -type d,f -exec chown $(logname):sudo {} \;

		if [ ${CONFIG_NODE_MEMINFO} -eq 1 ]; then
			export TEST
			bash ${TRACE_DIR}/trace-numa-meminfo.sh
		fi

		if [ ${CONFIG_MIGRATION_STAT} -eq 1 ]; then
			export TEST
			bash ${TRACE_DIR}/trace-migration-stat.sh
		fi
	done
	func_collect_data "${TESTS[@]}"
done
