#!/bin/bash

BENCH_DIR=./workloads/specaccel/benchspec/ACCEL/553.pclvrleaf/exe

MAX_THREADS=$(grep -c processor /proc/cpuinfo)
BENCH_RUN=""

export KMP_LIBRARY=throughput
#export OMP_DYNAMIC=FALSE
export OMP_NUM_THREADS=${NTHREADS}
#export KMP_HW_SUBSET=2S,16C,1T
#export FORT_BUFFERED=true

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
	BENCH_RUN+="${BENCH_DIR}/pclvrleaf_base.intel-omp"
elif [[ "${BENCH_SIZE}" == "30GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pclvrleaf_base.intel-omp"
elif [[ "${BENCH_SIZE}" == "32GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pclvrleaf_base.intel-omp"
elif [[ "${BENCH_SIZE}" == "48GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pclvrleaf_base.intel-omp"
elif [[ "${BENCH_SIZE}" == "48GB_long"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pclvrleaf_base.intel-omp"
elif [[ "${BENCH_SIZE}" == "64GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pclvrleaf_base.intel-omp"
elif [[ "${BENCH_SIZE}" == "64GB_long"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pclvrleaf_base.intel-omp"
elif [[ "${BENCH_SIZE}" == "96GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pclvrleaf_base.intel-omp"
elif [[ "${BENCH_SIZE}" == "128GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pclvrleaf_base.intel-omp"
elif [[ "${BENCH_SIZE}" == "160GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/pclvrleaf_base.intel-omp"
else
	err "ERROR: Retry with available SIZE. refer to benches/_553.pclvrleaf.sh"
	exit -1
fi

# Workload size is determined by intput file "clover.in"
cp ${BENCH_DIR}/clover_${BENCH_SIZE}.in ./clover.in

export BENCH_RUN
