#!/bin/bash

# -------------------- Preprocessing -------------------- #
export SCRIPTDIR=$(pwd)
source $SCRIPTDIR/_message.sh

MACHINE=$(uname -n)
if [ -z $NTHREADS ];then
	NTHREADS=$(grep -c processor /proc/cpuinfo)
fi
export NTHREADS
NCPU_NODES=$(cat /sys/devices/system/node/has_cpu | awk -F '-' '{print $NF+1}')
NMEM_NODES=$(cat /sys/devices/system/node/has_memory | awk -F '-' '{print $NF+1}')
MEM_NODES=($(ls /sys/devices/system/node | grep node | awk -F 'node' '{print $NF}'))
MONITOR_UPDATE_FREQUENCY=1
CONFIG_AUTONUMA=no
CONFIG_CPM=no
CONFIG_EXCH=no
CONFIG_OPM=no
CONFIG_DATE=no
CONFIG_SEQUENCE=no
CONFIG_NVM=no
CONFIG_COMMENT=no
CONFIG_INTERLEAVE=no
CONFIG_PINNED=no
CONFIG_PERF=no
CONFIG_THP=no
CONFIG_TIERING=no
CONFIG_TRACE=no
LOAD_BALANCE=1
THP=0
PINCPU=0
BG=BG

NUM_ITER=1
AUTONUMA=AN
CPM=OFF
EXCH=OFF
OPM=OFF
PERF_METRIC=""

# -------------------- Function  -------------------- #

function func_clean_page_cache() {
	# Drop page cache
	sudo sysctl vm.drop_caches=3
	return
}

function func_kswapd() {
	ONOFF=$1
	nodes=($(ls /sys/devices/system/node/ | grep node))
	case $ONOFF in
		[Oo][Nn])
			FAILURE_NUM=0
			;;
		[Oo][Ff][Ff])
			FAILURE_NUM=16
			;;
		*)
			echo "usage: $0 [on|off]"
			exit -1
			;;
	esac

	for node in ${nodes[@]}; do
		if [[ ! -e /sys/devices/system/node/$node/kswapd_failures ]]; then
			err "kswapd_failure interface is not supported"
			continue
		fi
		echo $FAILURE_NUM | sudo tee /sys/devices/system/node/$node/kswapd_failures > /dev/null
		info "Set kswapd failure number: $node: $FAILURE_NUM"
	done
}

function func_thp_set() {
	thp=$1
	if [[ $thp == 1 ]];then
		# Use huge page
		echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
		echo always | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
	else
		# Use 4KB page(Disable huge page)
		echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
	fi
}

function func_config_log() {

	mkdir -p $LOG_DIR

	sudo sysctl kernel > ${LOG_DIR}/sysctl.kernel.log
	sudo sysctl vm > ${LOG_DIR}/sysctl.vm.log
	cat /sys/kernel/mm/page_balancing/* > ${LOG_DIR}/autotiering.config
	cat /sys/kernel/mm/page_balancing/*
}

function func_config_demotion_path() {
	node=$1
	path=$2
	FILE_PATH=/sys/devices/system/node/node$1/demotion_path

	if [[ -e ${FILE_PATH} ]]; then
		echo $path | sudo tee ${FILE_PATH} > /dev/null
		info "Set demotion_path  [${node} --> ${path}]"
	else
		err "The demotion_path [$node --> $path] does not exist. You should execute AutoTiering kernel"
	fi
}

function func_config_promotion_path() {
	node=$1
	path=$2
	FILE_PATH=/sys/devices/system/node/node$1/promotion_path

	if [[ -e ${FILE_PATH} ]]; then
		echo $path | sudo tee ${FILE_PATH} > /dev/null
		info "Set promotion_path [${node} --> ${path}]"
	else
		err "The promotion_path [$node --> $path] does not exist. You should execute AutoTiering kernel"
	fi
}

function func_config_migration_path() {
	node=$1
	path=$2
	FILE_PATH=/sys/devices/system/node/node$1/migration_path

	if [ $CONFIG_NVM == "no" ];then
		if [[ $node -ne 0 && $node -ne 1 ]];then
			return
		fi
	fi
	if [[ -e ${FILE_PATH} ]]; then
		echo $path | sudo tee ${FILE_PATH} > /dev/null
		info "Set migration_path [${node} --> ${path}]"
	else
		err "The migration_path [$node --> $path] does not exist. You should execute AutoTiering kernel"
	fi
}

function func_initialize_migration_path() {
	for node in ${MEM_NODES[@]}; do
		func_config_demotion_path  $node -1
		func_config_promotion_path $node -1
		func_config_migration_path $node -1
	done
}

function func_prepare_migration_path() {
	for node in ${MEM_NODES[@]}; do
		case $node in
			0)
				func_config_migration_path $node 1
				func_config_promotion_path $node -1
				func_config_demotion_path  $node 2
				;;
			1)
				func_config_migration_path $node 0
				func_config_promotion_path $node -1
				func_config_demotion_path  $node 3
				;;
			2)
				func_config_migration_path $node 3
				func_config_promotion_path $node 0
				func_config_demotion_path  $node -1
				;;
			3)
				func_config_migration_path $node 2
				func_config_promotion_path $node 1
				func_config_demotion_path  $node -1
				;;
			*)
				err "Add NUMA node$node interfaces"
				;;
		esac
	done
}

function func_config_extended_balancing() {
	local CPM_OPT=$1
	local OPM_OPT=$2
	local EXCH_OPT=$3
	mode=0

	if [[ $CONFIG_CPM == "yes" || $CONFIG_EXCH == "yes" || $CONFIG_OPM == "yes" ]]; then
		if [[ $AUTONUMA == "OFF" ]]; then
			err "EXTENDED_BALANCING works only with AN enabled"
			func_usage
			func_err
		fi
	fi

	CHECK_EXTENDED=$(ls /proc/sys/kernel/numa_balancing* | grep extended)
	if [[ -z ${CHECK_EXTENDED} ]]; then
		err "numa_balancing_extended is not supported!"
		return
	fi

	case $CPM_OPT in
		[Nn][Oo]) # Conservative numa balancing OFF
			mode=$(($mode & 6)) # 110
			;;
		[Yy][Ee][Ss]) # Conservative promotion/migration
			mode=$(($mode | 1<<0))
			;;
		*)
			err "Usage: {OFF|ON} are available numa_balancing conservative promotion/migration"
			func_err
			;;
	esac

	case $OPM_OPT in
		[Nn][Oo]) # Aggressive promotion/migration OFF
			mode=$(($mode & 5)) #101
			sudo sysctl kernel.numa_balancing_scan_period_max_ms=60000
			sudo sysctl kernel.numa_balancing_scan_size_mb=256
			echo 0 | sudo tee /sys/kernel/mm/page_balancing/background_demotion > /dev/null
			echo 0 | sudo tee /sys/kernel/mm/page_balancing/batch_demotion > /dev/null
			;;
		[Yy][Ee][Ss]) # Aggressive promotion/migration OFF
			mode=$(($mode | 1<<1))
			sudo sysctl kernel.numa_balancing_scan_period_max_ms=1000
			sudo sysctl kernel.numa_balancing_scan_size_mb=2048
			case $BG in
				[Ff][Gg])
					echo 0 | sudo tee /sys/kernel/mm/page_balancing/background_demotion > /dev/null
					echo 0 | sudo tee /sys/kernel/mm/page_balancing/batch_demotion > /dev/null
					;;
				[Bb][Gg])
					echo 1 | sudo tee /sys/kernel/mm/page_balancing/background_demotion > /dev/null
					if [[ $THP -ne 1 ]]; then
						echo 1 | sudo tee /sys/kernel/mm/page_balancing/batch_demotion > /dev/null
					else
						# THP option
						echo 0 | sudo tee /sys/kernel/mm/page_balancing/batch_demotion > /dev/null
						sudo sysctl kernel.numa_balancing_scan_period_max_ms=10000
						sudo sysctl kernel.numa_balancing_scan_size_mb=256
					fi
					;;
				*)
					err "$BG is not valied. {FG|BG} are available OPM options"
					exit -1
			esac
			;;
		*)
			err "Usage: {OFF|ON} are available numa_balancing aggressive promotion/migration"
			func_err
			;;
	esac

	case $EXCH_OPT in
		[Nn][Oo]) # page exchange OFF
			mode=$(($mode & 3)) #011
			;;
		[Yy][Ee][Ss]) # page exchange ON
			mode=$(($mode | 1<<2))
			;;
		*)
			err "Usage: {OFF|EX} are available numa_balancing exchange values"
			func_err
			;;
	esac

	if [[ $mode > 7 || $mode < 0 ]]; then
		err "numa_balancing_extended range is 0 to 7"
		func_err
	fi

	sudo sysctl kernel.numa_balancing_extended=$mode
}

function func_config_autonuma() {
	local NUMA_OPT=$1

	func_initialize_migration_path > /dev/null
	case $NUMA_OPT in
		[Oo][Ff][Ff]) # AutoNUMA balancing OFF
			sudo sysctl kernel.numa_balancing=0
			;;
		[Aa][Nn]) # AutoNUMA balancing ON
			sudo sysctl kernel.numa_balancing=1
			func_prepare_migration_path
			;;
		[Mm][Tt]) # Memory tiering ON
			echo 15 | sudo tee /proc/sys/vm/zone_reclaim_mode
			echo 2 | sudo tee /proc/sys/kernel/numa_balancing
			echo 30 | sudo tee /proc/sys/kernel/numa_balancing_rate_limit_mbps
			;;
		*)
			err "Usage: {OFF|AN|MT} are available numa_balancing modes"
			func_err
			;;
	esac


}

function func_config_tiering() {
	case $CONFIG_TIERING in
		[Nn][Oo]) # Memory tiering OFF
			;;
		[Yy][Ee][Ss]) # Memory tiering ON
			echo 15 | sudo tee /proc/sys/vm/zone_reclaim_mode
			echo 30 | sudo tee /proc/sys/kernel/numa_balancing_rate_limit_mbps
			sudo sysctl kernel.numa_balancing=2
			;;
		*)
			err "Usage: invalid parameter $CONFIG_TIERING for Intel	Tiering"
			func_err
			;;
	esac
}

function func_check_file_output() {
	case $BENCH_NAME in
		553.pclvrleaf)
			cat clover.out >> $LOG_DIR/output.log
			rm clover.out
			;;
		*)
			;;
	esac
}

function func_monitor_migration() {
	MIG_LOG=${LOG_DIR}/proc-zoneinfo-${BENCH_NAME}.gz
	rm -f ${MIG_LOG}
	while [ 1 ]; do
		echo time: `date +%s` | gzip >> ${MIG_LOG}
		cat /proc/zoneinfo | grep -E "hmem_demote|hmem_promote|hmem_migrate" |\
			gzip >> ${MIG_LOG}
		sleep $MONITOR_UPDATE_FREQUENCY
	done
}

function func_monitor_meminfo() {
	MEMINFO_LOG=${LOG_DIR}/numa-meminfo-${BENCH_NAME}.gz
	rm -f ${MEMINFO_LOG}
	while [ 1 ]; do
		echo time: `date +%s` | gzip >> ${MEMINFO_LOG}
		cat /sys/devices/system/node/node*/meminfo | gzip >> ${MEMINFO_LOG}
		sleep $MONITOR_UPDATE_FREQUENCY
	done
}

function func_monitor_vmstat() {
	VMSTAT_LOG=${LOG_DIR}/proc-vmstat-${BENCH_NAME}.gz
	rm -f ${VMSTAT_LOG}
	while [ 1 ]; do
		echo time: `date +%s` | gzip >> ${VMSTAT_LOG}
		cat /proc/vmstat | grep -E "migrate|promote|demote|exchange" |\
			gzip >> ${VMSTAT_LOG}
		sleep $MONITOR_UPDATE_FREQUENCY
	done
}

function func_monitor_lapinfo() {
	if [[ ! -e /proc/lapinfo ]]; then
		err "/proc/lapinfo interface is not supported"
		return -1
	fi

	LAP_LOG=${LOG_DIR}/proc-lapinfo-${BENCH_NAME}.gz
	rm -f ${LAP_LOG}
	while [ 1 ]; do
		echo time: `date +%s` | gzip >> ${LAP_LOG}
		cat /proc/lapinfo | gzip >> ${LAP_LOG}
		sleep $MONITOR_UPDATE_FREQUENCY
	done
}

function func_monitor_page_profile() {
	PAGE_PROFILE_LOG=${LOG_DIR}/proc-page-profile-${BENCH_NAME}.gz
	rm -f ${PAGE_PROFILE_LOG}

	echo "" | sudo tee /sys/kernel/debug/tracing/trace
	echo 1 | sudo tee /sys/kernel/debug/tracing/tracing_on
	sudo cat /sys/kernel/debug/tracing/trace_pipe >> ${LOG_DIR}/proc-page-profile-${BENCH_NAME}
}

function func_monitor_start() {

	WATCH_PIDS=()
	func_monitor_migration &
	WATCH_PIDS+=("$!")
	echo "Started monitor migratoin-stat gzip pid $!"

	func_monitor_meminfo &
	WATCH_PIDS+=("$!")
	info "Started monitor numa-meminfo gzip pid $!"

	func_monitor_vmstat &
	WATCH_PIDS+=("$!")
	info "Started monitor vmstat gzip pid $!"

	func_monitor_lapinfo &
	WATCH_PIDS+=("$!")
	info "Started monitor lapinfo gzip pid $!"

	if [[ $CONFIG_TRACE == "yes" ]]; then
		func_monitor_page_profile &
		WATCH_PIDS+=("$!")
		info "Started monitor fault latency profiling gzip pid $!"
	fi
}

function func_monitor_end() {
	for pid in ${WATCH_PIDS[@]}; do
		sudo kill -9 $pid
		info "Shutting down monitor: ${pid}"
	done
	sudo pkill cat
}

function func_prepare() {
	info "Preparing benchmark start..."
	# MSR
	sudo modprobe msr
	sleep 1

	# Disable prefetcher and turbo-boost, Set Max CPU frequency
	sudo ./init_scripts/prefetchers.sh disable > /dev/null
	sudo ./init_scripts/turbo-boost.sh disable > /dev/null
	sudo ./init_scripts/set_max_freq.sh > /dev/null
	# cat /proc/cmdline
	# cat /proc/cpuinfo/ | grep MHz
	sleep 1

	# Check NVM NUMA node
	MAX_NODES=$(numactl -H | head -n 1 | awk '{ print $2 }')
	if [[ ${MAX_NODES} -ne 4 && ${CONFIG_TIERING} == "no" ]]; then
		sudo init_scripts/devdax_to_kmem.sh > /dev/null
		STATE=$?
		if [ $STATE -ne 0 ];then
			err "NVDIMM is not supported. Use ndctl"
		else
			CONFIG_NVM=yes
		fi
	else
		CONFIG_NVM=yes
	fi
	sleep 1

	# Select numa balancing option
	func_config_autonuma ${AUTONUMA}
	sleep 1

	# Enable Intel Tiering
	func_config_tiering
	sleep 1

	# Select numa balancing extended option
	func_config_extended_balancing ${CONFIG_CPM} ${CONFIG_OPM} ${CONFIG_EXCH}
	sleep 1

	# Enable kswapd for taking stable results
	func_kswapd ON
	sleep 1

	# Drop page cache
	func_clean_page_cache
	sleep 1

	# Set THP option
	func_thp_set $THP
	sleep 1

	if [[ ${CONFIG_PERF} == "no" ]]; then
		# Disable perf sampling
		sudo sysctl kernel.perf_event_max_sample_rate=1
	else
		sudo sysctl kernel.perf_event_max_sample_rate=100000
	fi

	# Check input date
	if [[ ${CONFIG_DATE} == "no" ]]; then
		DATE=$(date +%Y%m%d%H%M)
	fi

	# Check benchmark sequence
	if [[ ${CONFIG_SEQUENCE} == "no" ]]; then
		SEQUENCE="a"
	fi

	export BENCH_SIZE
	export BENCH_NAME

	# Check NUMA configuration
	if [[ $CONFIG_PINNED == "yes" ]]; then
		NTHREADS=$(cat /sys/devices/system/cpu/possible | awk -F '-' '{print ($NF+1)/2}')
		export CONFIG_PINNED
		export NTHREADS
		export PINCPU
	fi

	# Check # of threads limitation
	if [[ $CONFIG_MAX_THREADS == "yes" ]]; then
		NTHREADS=$MAX_THREADS
		export NTHREADS
	fi
	echo "The number of threads: $NTHREADS"

	# The source will bring ${BENCH_RUN}
	if [[ -e ./benches/_${BENCH_NAME}.sh ]]; then
		source ./benches/_${BENCH_NAME}.sh
	else
		err "_${BENCH_NAME}.sh does not exist"
		func_err
	fi
}

function func_finish() {
	# Initialization to linux default configuration
	sudo sysctl kernel.numa_balancing=1
	sleep 1

	func_initialize_migration_path
	sleep 1

	func_clean_page_cache
	sleep 1

	# Default perf sampling rate
	sudo sysctl kernel.perf_event_max_sample_rate=100000

	# Post-processing of specific benchmarks
	source ./benches/finish.sh
	sleep 1
}

function func_err() {
	func_finish
	exit -1
}

function func_main() {
	TEST_NAME="${DATE}-${SEQUENCE}"
	TEST_NAME+="-${AUTONUMA}"
	TEST_NAME+="-${CPM}"
	TEST_NAME+="-${EXCH}"
	TEST_NAME+="-${OPM}"

	TIME="/usr/bin/time"
	if [[ $CONFIG_NUMACTL == "yes" ]];then
		NUMACTL="numactl"
		if [[ $CONFIG_INTERLEAVE == "yes" ]];then
			NUMACTL+=" --interleave=0-1"
		fi

		if [[ $CONFIG_PINNED == "yes" ]];then
			NUMACTL+=" --cpunodebind=$PINCPU"
		fi

		if [[ $CONFIG_MEMBIND == "yes" ]];then
			NUMACTL+=" --preferred=$MEMBIND_NODE"
		fi
	fi

	for ITER in $(seq 1 ${NUM_ITER}); do
		LOG_DIR=/tmp/logs/${BENCH_NAME}/${TEST_NAME}/iter-${ITER}

		func_config_log

		if [[ -n ${MONITOR} && $ITER -eq 1 ]]; then
			func_monitor_start
		fi

		if [[ $CONFIG_PERF == "yes" ]];then
			info "perf monitoring on, metric: $PERF_METRIC"
			PERF="perf stat -o ${LOG_DIR}/perf.log --cpu=0-$(($NTHREADS-1)) -e $PERF_METRIC"
		fi

		func_clean_page_cache

		info "NUMA_OPT: ${AUTONUMA}"
		info "CPM_OPT: ${CPM}"
		info "OPM_OPT: ${OPM}"
		info "EXCH_OPT: ${EXCH}"
		info "Working-Set Size: ${BENCH_SIZE}"
		info "[ITER ${ITER}] ${BENCH_NAME}, Sequence: ${SEQUENCE}, DATE: ${DATE}"
		info "$(date)"

		date > ${LOG_DIR}/real_time.log

		# Run Benchmark
		${TIME} -f "execution_time %e (s)" \
			${PERF} ${NUMACTL} ${BENCH_RUN} 2>&1 \
			| tee ${LOG_DIR}/output.log

		date >> ${LOG_DIR}/real_time.log

		if [[ -n ${MONITOR} && $ITER -eq 1 ]]; then
			func_monitor_end
			echo 0 | sudo tee /sys/kernel/debug/tracing/tracing_on
		fi


		info "[ITER ${ITER}] ${BENCH_NAME} end..."
		sleep 5
		func_check_file_output

		mkdir -p logs/${BENCH_NAME}/${TEST_NAME}
		cp -r ${LOG_DIR} logs/${BENCH_NAME}/${TEST_NAME}
		rm -rf ${LOG_DIR}
	done

	if [[ ${CONFIG_COMMENT} == yes ]];then
		echo "$COMMENT" > logs/${BENCH_NAME}/${DATE}-comment.log
	fi
}

function func_usage() {
	echo
	echo -e "$0 \t[-mIpTh] [-i iter] [-b benchmark] [-d date] [-C comment]\n\t\t[--autonuma] [--tiering] [--cpm] [--exchange] [--opm fg|bg]\n\t\t[--sequence seq] [--socket num] [--max-threads num]"
	echo
	echo "-b| --benchmark   Select to run benchamrk. e.g) graph500, graphmat, etc."
	echo "-d| --date        Benchmark start time. (default: current time)"
	echo "-m| --monitor     Enable monitor(memory usage, migration stats)."
	echo "-w| --wss         Working set size."
	echo "    --autonuma    Automatic NUMA balancing policy"
	echo "    --tiering     Intel Tieirng"
	echo "-c| --cpm         Conservative promotion/migration policy"
	echo "-o| --opm         Opportunistic promotion/migration policy. You should select [fg|bg]"
	echo "-e| --exchange    Page exchange policy"
	echo "-s| --sequence    Order the benchmark using the alphabet.(default: 'a')"
	echo "-C| --comment     Comment this benchmark's feature"
	echo "-i| --iter        Iteration (default: 1)"
	echo "-I| --interleave  Allocate memory interleaved"
	echo "    --socket      Pin threads to CPU socket"
	echo "    --max-threads Limit the number of maximum threads"
	echo "-p| --perf        Use perf tool to evaluate benchmark performace"
	echo "-T| --thp         Enable transparent hugepage"
	echo "-h| --help        Print this help."
	echo
}


# -------------------- Script Start  -------------------- #

# Write run history
RUN_BENCH="$0 $*, $(date +%Y%m%d%H%M)"

RUN_HISTORY=run_history
echo "$(hostname):$RUN_BENCH" >> $RUN_HISTORY

ARGS=`getopt -o b:mtC:w:caed:s:i:IpTh --long benchmark:,monitor,trace,comment:,wss:,cpm,opm:,exchange,date:,sequence:,iter:,interleave,perf,thp,help,autonuma,tiering,socket:,membind:,max-threads: -n run-bench.sh -- "$@"`
if [ $? -ne 0 ]; then
	echo "Terminating..." >&2
	func_usage
	exit -1
fi

eval set -- "${ARGS}"

while true; do
	case "$1" in
		-b|--benchmark)
			BENCH_NAME+=( "$2" )
			shift 2
			;;
		-m|--monitor)
			MONITOR="$1"
			shift 1
			;;
		-t|--trace)
			CONFIG_TRACE="yes"
			shift 1
			;;
		-C|--comment)
			CONFIG_COMMENT=yes
			COMMENT="$2"
			shift 2
			;;
		-w|--wss)
			BENCH_SIZE="$2"
			shift 2
			;;
		-I|--interleave)
			CONFIG_INTERLEAVE="yes"
			CONFIG_NUMACTL="yes"
			shift 1
			;;
		--socket)
			CONFIG_PINNED="yes"
			CONFIG_NUMACTL="yes"
			PINCPU="$2"
			if [[ $PINCPU < 0 || $PINCPU > $NCPU_NODES ]]; then
				err "This CPU is out of range"
				func_usage
				exit -1
			fi
			shift 2
			;;
		--membind)
			CONFIG_MEMBIND="yes"
			CONFIG_NUMACTL="yes"
			MEMBIND_NODE="$2"
			if [[ $MEMBIND_NODE < 0 || $MEMBIND_NODE > $NMEM_NODES ]]; then
				err "This memory node is out of range"
				func_usage
				exit -1
			fi
			shift 2
			;;
		--max-threads)
			CONFIG_MAX_THREADS="yes"
			MAX_THREADS="$2"
			shift 2
			;;
		--autonuma)
			CONFIG_AUTONUMA="yes"
			AUTONUMA=AN
			shift 1
			;;
		--tiering)
			CONFIG_TIERING="yes"
			shift 1
			;;
		-c|--cpm)
			CHECK_CPM=$(ls /proc/sys/kernel/numa_balancing* | grep extended)
			if [[ -z ${CHECK_CPM} ]]; then
				err "numa_balancing extended is not supported!"
				func_usage
				exit -1
			fi
			CONFIG_CPM=yes
			CPM=CPM
			shift 1
			;;
		-o|--opm)
			CHECK_EXCH=$(ls /proc/sys/kernel/numa_balancing* | grep extended)
			if [[ -z ${CHECK_EXCH} ]]; then
				err "numa_balancing extended is not supported!"
				func_usage
				exit -1
			fi
			CONFIG_OPM="yes"
			OPM=OPM
			BG=$2
			shift 2
			;;
		-e|--exchange)
			CHECK_EXCH=$(ls /proc/sys/kernel/numa_balancing* | grep extended)
			if [[ -z ${CHECK_EXCH} ]]; then
				err "numa_balancing extended is not supported!"
				func_usage
				exit -1
			fi
			CONFIG_EXCH="yes"
			EXCH="EX"
			shift 1
			;;
		-d|--date)
			DATE="$2"
			CONFIG_DATE=yes
			shift 2
			;;
		-s|--sequence)
			SEQUENCE="$2"
			CONFIG_SEQUENCE=yes
			shift 2
			;;
		-i|--iter)
			NUM_ITER=$2
			shift 2
			;;
		-p|--perf)
			CONFIG_PERF=yes
			# Total cycles
			PERF_METRIC+="cycles"
			# MEM access
			#PERF_METRIC+="MEM_LOAD_L3_MISS_RETIRED.LOCAL_DRAM"
			#PERF_METRIC+=",MEM_LOAD_RETIRED.LOCAL_PMM"
			#PERF_METRIC+=",MEM_LOAD_L3_MISS_RETIRED.REMOTE_DRAM"
			#PERF_METRIC+=",MEM_LOAD_L3_MISS_RETIRED.REMOTE_PMM"
			# TLB MISS
			# PERF_METRIC+=",dTLB-load-misses"
			# PERF_METRIC+=",dTLB-store-misses"
			# PERF_METRIC+=",iTLB-load-misses"
			# Page_Walks_Utilization
			# PERF_METRIC+=",ITLB_MISSES.WALK_PENDING"
			# PERF_METRIC+=",DTLB_LOAD_MISSES.WALK_PENDING"
			# PERF_METRIC+=",DTLB_STORE_MISSES.WALK_PENDING"
			# PERF_METRIC+=",EPT.WALK_PENDING"
			# User/Kernel cycle
			shift 1
			;;
		-t|--thp)
			CONFIG_THP=yes
			THP=1
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
			err "Unrecognized option $1"
			func_usage
			exit -1
			;;
	esac
done

if [ -z  "${BENCH_NAME}" ]; then
	err "Benchmark name parameter must be specified"
	func_usage
	exit -1
fi

func_prepare
func_main
func_finish
