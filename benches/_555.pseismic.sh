#!/bin/bash

BENCH_DIR=./workloads/specaccel/benchspec/ACCEL/555.pseismic/exe

MAX_THREADS=$(grep -c processor /proc/cpuinfo)
BENCH_RUN=""

export KMP_LIBRARY=throughput
#export KMP_BLOCKTIME=infinite
export OMP_DYNAMIC=FALSE
#export KMP_HW_SUBSET=2S,16C,1T
#export FORT_BUFFERED=true
export OMP_NUM_THREADS=${NTHREADS}

source ~/intel/oneapi/setvars.sh

if [[ $CONFIG_PINNED == "yes" ]]; then
	export KMP_AFFINITY="compact"
elif [[ $NTHREADS -eq $MAX_THREADS ]]; then
	export KMP_AFFINITY="proclist=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31],explicit" #,verbose
else
	export KMP_AFFINITY="compact,verbose"
	BENCH_RUN+="taskset -c 8,9,10,11,12,13,14,15,24,25,26,27,28,29,30,31 "
fi

if [[ "${BENCH_SIZE}" == "4GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pseismic_base.intel-omp 280 280 280 2 10 5"
elif [[ "${BENCH_SIZE}" == "30GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pseismic_base.intel-omp 200 830 830 2 10 5"
elif [[ "${BENCH_SIZE}" == "32GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pseismic_base.intel-omp 200 930 930 2 10 5"
elif [[ "${BENCH_SIZE}" == "48GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pseismic_base.intel-omp 300 930 930 2 10 5"
elif [[ "${BENCH_SIZE}" == "64GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pseismic_base.intel-omp 400 930 930 2 10 5"
elif [[ "${BENCH_SIZE}" == "96GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pseismic_base.intel-omp 625 930 930 2 10 5"
elif [[ "${BENCH_SIZE}" == "128GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pseismic_base.intel-omp 800 930 930 2 10 5"
elif [[ "${BENCH_SIZE}" == "160GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pseismic_base.intel-omp 1035 930 930 2 10 5"
else
	err "ERROR: Retry with available SIZE. refer to benches/_555.pseismic.sh"
	exit -1
fi

export BENCH_RUN
