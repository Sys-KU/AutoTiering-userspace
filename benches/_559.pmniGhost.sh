#!/bin/bash

BENCH_DIR=./workloads/specaccel/benchspec/ACCEL/559.pmniGhost/exe

MAX_THREADS=$(grep -c processor /proc/cpuinfo)
BENCH_RUN=""

export OMP_NUM_THREADS=${NTHREADS}
export KMP_LIBRARY=throughput
#export KMP_BLOCKTIME=infinite
export OMP_DYNAMIC=FALSE
#export KMP_HW_SUBSET=2S,16C,1T

# source /opt/intel/oneapi/setvars.sh
source ~/intel/oneapi/setvars.sh

if [[ $CONFIG_PINNED == "yes" ]]; then
	export KMP_AFFINITY="compact"
	BENCH_RUN+="taskset -c 0-$(($NTHREADS-1)) "
elif [[ $NTHREADS -eq $MAX_THREADS ]]; then
	export KMP_AFFINITY="proclist=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31],explicit"
else # multi-socket binding
	export KMP_AFFINITY="compact,verbose"
	BENCH_RUN+="taskset -c 8,9,10,11,12,13,14,15,24,25,26,27,28,29,30,31 "
fi

if [[ "${BENCH_SIZE}" == "4GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/miniGhost_base.intel-omp --scaling 1
	--nx 425 --ny 425 --nz 500 --num_vars 5  --percent_sum 0 --num_spikes 1
	--num_tsteps 50 --stencil 21 --comm_method 10 --error_tol 5
	--debug_grid 1 --report_diffusion 2"
elif [[ "${BENCH_SIZE}" == "30GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/miniGhost_base.intel-omp --scaling 1
	--nx 1100 --ny 1100 --nz 500 --num_vars 5  --percent_sum 0 --num_spikes 1
	--num_tsteps 10 --stencil 21 --comm_method 10 --error_tol 5
	--debug_grid 1 --report_diffusion 1"
elif [[ "${BENCH_SIZE}" == "32GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/miniGhost_base.intel-omp --scaling 1
	--nx 900 --ny 900 --nz 900 --num_vars 5  --percent_sum 0 --num_spikes 1
	--num_tsteps 10 --stencil 21 --comm_method 10 --error_tol 5
	--debug_grid 1 --report_diffusion 1"
elif [[ "${BENCH_SIZE}" == "48GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/miniGhost_base.intel-omp --scaling 1
	--nx 1010 --ny 1010 --nz 1010 --num_vars 5 --percent_sum 0 --num_spikes 1
	--num_tsteps 10 --stencil 21 --comm_method 10 --error_tol 5
	--debug_grid 1 --report_diffusion 5 --report_perf 2"
elif [[ "${BENCH_SIZE}" == "64GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/miniGhost_base.intel-omp --scaling 1
	--nx 1700 --ny 1700 --nz 500 --num_vars 5  --percent_sum 0 --num_spikes 1
	--num_tsteps 10 --stencil 21 --comm_method 10 --error_tol 5
	--debug_grid 1 --report_diffusion 10"
elif [[ "${BENCH_SIZE}" == "64GB_long"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/miniGhost_base.intel-omp --scaling 1
	--nx 1700 --ny 1700 --nz 500 --num_vars 5  --percent_sum 0 --num_spikes 1
	--num_tsteps 100 --stencil 21 --comm_method 10 --error_tol 5
	--debug_grid 1 --report_diffusion 10"
elif [[ "${BENCH_SIZE}" == "96GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/miniGhost_base.intel-omp --scaling 1
	--nx 2080 --ny 2080 --nz 500 --num_vars 5  --percent_sum 0 --num_spikes 1
	--num_tsteps 10 --stencil 21 --comm_method 10 --error_tol 5
	--debug_grid 1 --report_diffusion 10"
elif [[ "${BENCH_SIZE}" == "128GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/miniGhost_base.intel-omp --scaling 1
	--nx 2270 --ny 2270 --nz 500 --num_vars 5  --percent_sum 0 --num_spikes 1
	--num_tsteps 10 --stencil 21 --comm_method 10 --error_tol 5
	--debug_grid 1 --report_diffusion 10"
elif [[ "${BENCH_SIZE}" == "160GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/miniGhost_base.intel-omp --scaling 1
	--nx 2680 --ny 2680 --nz 500 --num_vars 5  --percent_sum 0 --num_spikes 1
	--num_tsteps 10 --stencil 21 --comm_method 10 --error_tol 5
	--debug_grid 1 --report_diffusion 10"
else
	err "ERROR: Retry with available SIZE. refer to benches/_559.pmniGhost.sh"
	exit -1
fi

export BENCH_RUN
