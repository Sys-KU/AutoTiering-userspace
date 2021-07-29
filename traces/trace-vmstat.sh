#!/bin/bash
NODES=(0 1 2 3)
STATS=(demote_src promote_src migrate_src)

function func_trace_vmstat() {
        local name=$1
        local numa=$2
        WORK_LOG_DIR=work/log/${name}/iter-0
        LOG_DIR=logs/${BENCH_NAME}/${name}
        gzip -d -k ${WORK_LOG_DIR}/proc-vmstat-${BENCH_NAME}.gz
        VMSTATS=()
        for stat in ${STATS[@]}; do
                VMSTATS+=( "${LOG_DIR}/migration-stat-${stat}" )
                cat ${WORK_LOG_DIR}/proc-vmstat-${BENCH_NAME} |\
                        grep ${stat} |\
                        awk 'NR==1 {s=$2} {print $2-s}' > ${LOG_DIR}/migration-stat-${stat}
        done

        echo "${STATS[0]} ${STATS[1]} ${STATS[2]}" > ${LOG_DIR}/migration-stat
        paste -d" " ${VMSTATS[@]} >> ${LOG_DIR}/migration-stat

        rm ${VMSTATS[@]}
        unset VMSTATS

        rm ${WORK_LOG_DIR}/proc-vmstat-${BENCH_NAME}
}
TEST_NAME=$1
NUMA_OPT=$2

func_trace_vmstat ${TEST_NAME} ${NUMA_OPT}
