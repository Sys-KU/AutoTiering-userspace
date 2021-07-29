#!/bin/bash
BENCH_BIN=./workloads/graph500/omp-csr

export SKIP_VALIDATION=1
export VERBOSE=1
export KMP_LIBRARY=throughput
export KMP_BLOCKTIME=infinite
export OMP_DYNAMIC=FALSE

MAX_THREADS=$(grep -c processor /proc/cpuinfo)
BENCH_RUN=""

export KMP_LIBRARY=throughput
export OMP_NUM_THREADS=${NTHREADS}
if [[ $CONFIG_PINNED == "yes" ]]; then
	export KMP_AFFINITY="compact"
elif [[ $NTHREADS -eq $MAX_THREADS ]]; then
	export KMP_AFFINITY="proclist=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31],explicit" #,verbose
else
	export KMP_AFFINITY="compact,verbose"
	BENCH_RUN+="taskset -c 8,9,10,11,12,13,14,15,24,25,26,27,28,29,30,31 "
fi

if [[ "${BENCH_SIZE}" == "4GB" ]]; then
	BENCH_RUN+="${BENCH_BIN}/omp-csr -s 23 -e 16 -V"
elif [[ "${BENCH_SIZE}" == "8GB" ]]; then
	BENCH_RUN+="${BENCH_BIN}/omp-csr -s 24 -e 16 -V"
elif [[ "${BENCH_SIZE}" == "15GB" ]]; then
	BENCH_RUN+="${BENCH_BIN}/omp-csr -s 25 -e 16 -V"
elif [[ "${BENCH_SIZE}" == "15GB_long" ]]; then
	unset SKIP_VALIDATION
	BENCH_RUN+="${BENCH_BIN}/omp-csr -s 25 -e 16 -V"
elif [[ "${BENCH_SIZE}" == "30GB" ]]; then
	BENCH_RUN+="${BENCH_BIN}/omp-csr -s 25 -e 28 -V"
elif [[ "${BENCH_SIZE}" == "32GB" ]]; then
	BENCH_RUN+="${BENCH_BIN}/omp-csr -s 26 -e 15 -V"
elif [[ "${BENCH_SIZE}" == "48GB" ]]; then
	BENCH_RUN+="${BENCH_BIN}/omp-csr -s 26 -e 23 -V"
elif [[ "${BENCH_SIZE}" == "56GB" ]]; then
	BENCH_RUN+="${BENCH_BIN}/omp-csr -s 26 -e 26 -V"
elif [[ "${BENCH_SIZE}" == "64GB" ]]; then
	BENCH_RUN+="${BENCH_BIN}/omp-csr -s 27 -e 15 -V"
elif [[ "${BENCH_SIZE}" == "64GB_long" ]]; then
	unset SKIP_VALIDATION
	BENCH_RUN+="${BENCH_BIN}/omp-csr -s 27 -e 15 -V"
elif [[ "${BENCH_SIZE}" == "96GB" ]]; then
	BENCH_RUN+="${BENCH_BIN}/omp-csr -s 27 -e 23 -V"
elif [[ "${BENCH_SIZE}" == "128GB" ]]; then
	BENCH_RUN+="${BENCH_BIN}/omp-csr -s 28 -e 15 -V"
elif [[ "${BENCH_SIZE}" == "160GB" ]]; then
	BENCH_RUN+="${BENCH_BIN}/omp-csr -s 28 -e 20 -V"
else
	err "ERROR: Retry with available SIZE. refer to benches/_graph500.sh"
	exit -1
fi

export BENCH_RUN
