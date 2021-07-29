#!/bin/bash
BENCH_DIR=./workloads/GraphMat
source ~/intel/oneapi/setvars.sh

MAX_THREADS=$(grep -c processor /proc/cpuinfo)

sleep 2

export OMP_NUM_THREADS=${NTHREADS}
export KMP_LIBRARY=throughput
export OMP_DYNAMIC=FALSE
BENCH_RUN=""

if [[ $CONFIG_PINNED == "yes" ]]; then
	export KMP_AFFINITY="compact"
elif [[ $NTHREADS -eq $MAX_THREADS ]]; then
	export KMP_AFFINITY="proclist=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31],explicit" #,verbose
else
	export KMP_AFFINITY="compact,verbose"
	BENCH_RUN+="taskset -c 8,9,10,11,12,13,14,15,24,25,26,27,28,29,30,31 "
#	BENCH_RUN+="taskset -c 0,1,2,3,4,5,6,7,16,17,18,19,20,21,22,23 "
fi

case ${BENCH_SIZE} in
    "twitter"|"twitter_long")
        BENCH_RUN+="${BENCH_DIR}/bin/PageRank ${BENCH_DIR}/data/twitter_rv.bin.net"
        ;;
    *)
        err "Error: "${BENCH_NAME}: {twitter}"
        exit 1
esac

export BENCH_RUN
