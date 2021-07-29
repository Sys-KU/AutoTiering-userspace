#!/bin/bash

BENCH_DIR=./workloads/specaccel/benchspec/ACCEL/503.postencil/exe

MAX_THREADS=$(grep -c processor /proc/cpuinfo)
BENCH_RUN=""

export OMP_DYNAMIC=FALSE
#export OMP_PROC_BIND=true
export OMP_SCHEDULE=static
#export OMP_DISPLAY_ENV=VERBOSE
export OMP_DISPLAY_AFFINITY=TRUE

export OMP_NUM_THREADS=$NTHREADS
if [[ $CONFIG_PINNED == "yes" ]]; then
	export KMP_AFFINITY="compact"
elif [[ $NTHREADS -eq $MAX_THREADS ]]; then
	export KMP_AFFINITY="proclist=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31],explicit" #,verbose
else
	export KMP_AFFINITY="compact,verbose"
	BENCH_RUN+="taskset -c 8,9,10,11,12,13,14,15,24,25,26,27,28,29,30,31 "
fi

if [[ "x${BENCH_SIZE}" == "x4GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 2048 2048 125 50"
elif [[ "x${BENCH_SIZE}" == "x8GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 2048 2048 250 50"
elif [[ "x${BENCH_SIZE}" == "x16GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 2048 2048 500 30"
elif [[ "x${BENCH_SIZE}" == "x30GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 2048 2048 930 30"
elif [[ "x${BENCH_SIZE}" == "x30GB_SMALL"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 2048 2048 930 30"
elif [[ "x${BENCH_SIZE}" == "x30GB_LONG"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 2048 2048 930 60"
elif [[ "x${BENCH_SIZE}" == "x32GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 2048 2048 1000 30"
elif [[ "x${BENCH_SIZE}" == "x40GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 2048 2048 1200 50"
elif [[ "x${BENCH_SIZE}" == "x48GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 4096 4096 385 30"
elif [[ "x${BENCH_SIZE}" == "x16GB_SB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 2048 2048 500 30"
elif [[ "x${BENCH_SIZE}" == "x64GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 4096 4096 550 30"
elif [[ "x${BENCH_SIZE}" == "x80GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 4096 4096 725 30"
elif [[ "x${BENCH_SIZE}" == "x96GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 4096 4096 770 30"
elif [[ "x${BENCH_SIZE}" == "x128GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 4096 4096 1024 30"
elif [[ "x${BENCH_SIZE}" == "x128GB_LONG"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 4096 4096 1024 60"
elif [[ "x${BENCH_SIZE}" == "x160GB"  ]]; then
	BENCH_RUN+="${BENCH_DIR}/stencil_exe_base.compsys -- 4096 4096 1280 30"
else
	err "ERROR: Retry with available SIZE. refer to benches/_503.postencil.sh"
	exit -1
fi

export BENCH_RUN
