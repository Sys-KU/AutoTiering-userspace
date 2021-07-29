#!/bin/bash
NODES=(0 1 2 3)
TRACE_DIR=traces

STATS=(hmem_demote_src hmem_promote_local_src hmem_promote_remote_src hmem_migrate_src)
FAILS=(hmem_promote_local_fail_src hmem_promote_remote_fail_src hmem_migrate_fail_src)
PGSTATS=(pgmigrate_success pgmigrate_success_twice)
PGEXCHS=(pgexchange_success pgexchange_fail)
PGACTIVATE=(pgactivate_deferred pgactivate_deferred_local)
PGREPROMOTE=(pgrepromote)
TOTAL_STATS=(hmem_promote_local_src hmem_promote_remote_src hmem_migrate_src hmem_demote_src pgdemote_file)
TOTAL_FAILS=(hmem_promote_local_fail_src hmem_promote_remote_fail_src hmem_migrate_fail_src pgpromote_empty_pool_fail)
LOWFREQ_FAIL=(pgpromote_low_freq_fail)
LAP_STATS=("pages" "demotion")

function func_trace_migration_stat() {
	local name=$1
	BASE_LOG_DIR=logs/${BENCH_NAME}/${name}
	VMSTAT_LOG=${BASE_LOG_DIR}-vmstat.log

	# ITERS=($(ls ${BASE_LOG_DIR}))
	ITERS=(iter-1)
	for ITER in ${ITERS[@]}; do
		LOG_DIR=${BASE_LOG_DIR}/${ITER}

		# Available Node check
		MEM_LOG=${LOG_DIR}/numa-meminfo-${BENCH_NAME}
		if [ -e ${MEM_LOG}.gz ];then
			gzip -d -k ${MEM_LOG}.gz
			for node in ${NODES[@]}; do
				NODE_CHECK=$(grep -c "Node $node" ${MEM_LOG})
				if [[ $NODE_CHECK -eq 0 ]];then
					unset NODES[$node]
				fi
			done
		fi
		rm -f ${MEM_LOG}
		NUM_NODES=${#NODES[@]}

		if [ -e ${LOG_DIR}/proc-zoneinfo-${BENCH_NAME}.gz ];then
			gzip -d -k ${LOG_DIR}/proc-zoneinfo-${BENCH_NAME}.gz
		else
			continue
		fi

		# migration success stat
		for stat in ${STATS[@]}; do
			VMSTATS=()
			for node in ${NODES[@]}; do
				VMSTATS+=( "${LOG_DIR}/migration-stat-${node}-${stat}" )
				echo "Node${node}" > ${VMSTATS[$node]}
				if [[ $NUM_NODES > 2 ]]; then
					cat ${LOG_DIR}/proc-zoneinfo-${BENCH_NAME} | grep ${stat} |\
						awk -f ${TRACE_DIR}/migration.awk.script | grep "Node${node}" | \
						awk '{print $2}' >> ${VMSTATS[$node]}
				else
					cat ${LOG_DIR}/proc-zoneinfo-${BENCH_NAME} | grep ${stat} |\
						awk -f ${TRACE_DIR}/migration_two_node.awk.script | grep "Node${node}" | \
						awk '{print $2}' >> ${VMSTATS[$node]}
				fi
			done
			paste -d" " ${VMSTATS[@]} > ${LOG_DIR}/migration-stat-${stat}

			rm -f ${VMSTATS[@]}
			unset VMSTATS
		done

		# migration fail stat
		for stat in ${FAILS[@]}; do
			VMSTATS=()
			for node in ${NODES[@]}; do
				VMSTATS+=( "${LOG_DIR}/migration-stat-${node}-${stat}" )
				echo "Node${node}" > ${VMSTATS[$node]}
				if [[ $NUM_NODES > 2 ]]; then
					cat ${LOG_DIR}/proc-zoneinfo-${BENCH_NAME} | grep ${stat} |\
						awk -f ${TRACE_DIR}/migration.awk.script | grep "Node${node}" | \
						awk '{print $2}' >> ${VMSTATS[$node]}
				else
					cat ${LOG_DIR}/proc-zoneinfo-${BENCH_NAME} | grep ${stat} |\
						awk -f ${TRACE_DIR}/migration_two_node.awk.script | grep "Node${node}" | \
						awk '{print $2}' >> ${VMSTATS[$node]}
				fi
			done
			paste -d" " ${VMSTATS[@]} > ${LOG_DIR}/migration-stat-${stat}

			rm -f ${VMSTATS[@]}
			unset VMSTATS
		done

		if [ -e ${LOG_DIR}/proc-vmstat-${BENCH_NAME}.gz ];then
			gzip -d -k ${LOG_DIR}/proc-vmstat-${BENCH_NAME}.gz
		else
			continue
		fi

		# pgmigrate stat
		VMSTATS=()
		for i in `seq 0 $((${#PGSTATS[@]}-1))`; do
			stat=${PGSTATS[$i]}
			CHECK_STAT=$(cat ${LOG_DIR}/proc-vmstat-${BENCH_NAME} | grep -w ${stat})
			if [[ -z $CHECK_STAT ]];then
				continue
			fi
			VMSTATS+=("${LOG_DIR}/migration-stat-${stat}")
			echo ${stat} > ${VMSTATS[$i]}
			cat ${LOG_DIR}/proc-vmstat-${BENCH_NAME} | grep -w ${stat} |\
				awk -f ${TRACE_DIR}/pgmigrate.awk.script >> ${VMSTATS[$i]}
		done
		paste -d" " ${VMSTATS[@]} > ${LOG_DIR}/migration-stat-pgmigrate
		rm -f ${VMSTATS[@]}
		unset VMSTATS

		# pgexchage stat
		VMSTATS=()
		for i in `seq 0 $((${#PGEXCHS[@]}-1))`; do
			stat=${PGEXCHS[$i]}
			CHECK_STAT=$(cat ${LOG_DIR}/proc-vmstat-${BENCH_NAME} | grep -w ${stat})
			if [[ -z $CHECK_STAT ]];then
				continue
			fi
			VMSTATS+=("${LOG_DIR}/migration-stat-${stat}")
			echo ${stat} > ${VMSTATS[$i]}
			cat ${LOG_DIR}/proc-vmstat-${BENCH_NAME} | grep -w ${stat} |\
				awk -f ${TRACE_DIR}/pgmigrate.awk.script >> ${VMSTATS[$i]}
		done
		if [[ -z ${VMSTATS[@]} ]];then
			echo > ${LOG_DIR}/migration-stat-pgexchange
		else
			paste -d" " ${VMSTATS[@]} > ${LOG_DIR}/migration-stat-pgexchange
		fi
		rm -f ${VMSTATS[@]}
		unset VMSTATS

		# pgactivate stat
		VMSTATS=()
		for i in `seq 0 $((${#PGACTIVATE[@]}-1))`; do
			stat=${PGACTIVATE[$i]}
			VMSTATS+=("${LOG_DIR}/migration-stat-${stat}")
			echo ${stat} > ${VMSTATS[$i]}
			cat ${LOG_DIR}/proc-vmstat-${BENCH_NAME} | grep -w ${stat} |\
				awk -f ${TRACE_DIR}/pgmigrate.awk.script >> ${VMSTATS[$i]}
		done
		paste -d" " ${VMSTATS[@]} > ${LOG_DIR}/migration-stat-pgactivate
		rm -f ${VMSTATS[@]}
		unset VMSTATS

		# pgrepromote stat
		VMSTATS=()
		for i in `seq 0 $((${#PGREPROMOTE[@]}-1))`; do
			stat=${PGREPROMOTE[$i]}
			VMSTATS+=("${LOG_DIR}/migration-stat-${stat}")
			echo ${stat} > ${VMSTATS[$i]}
			cat ${LOG_DIR}/proc-vmstat-${BENCH_NAME} | grep -w ${stat} |\
				awk -f ${TRACE_DIR}/pgmigrate.awk.script >> ${VMSTATS[$i]}
		done
		paste -d" " ${VMSTATS[@]} > ${LOG_DIR}/migration-stat-repromote
		rm -f ${VMSTATS[@]}
		unset VMSTATS

		# low_freq_fail stat
		VMSTATS=()
		for i in `seq 0 $((${#LOWFREQ_FAIL[@]}-1))`; do
			stat=${LOWFREQ_FAIL[$i]}
			VMSTATS+=("${LOG_DIR}/migration-stat-${stat}")
			echo ${stat} > ${VMSTATS[$i]}
			cat ${LOG_DIR}/proc-vmstat-${BENCH_NAME} | grep -w ${stat} |\
				awk -f ${TRACE_DIR}/pgmigrate.awk.script >> ${VMSTATS[$i]}
		done
		paste -d" " ${VMSTATS[@]} > ${LOG_DIR}/migration-stat-lowfreq_fail
		rm -f ${VMSTATS[@]}
		unset VMSTATS

		# total migration/promotion stat
		VMSTATS=()
		for i in `seq 0 $((${#TOTAL_STATS[@]}-1))`; do
			stat=${TOTAL_STATS[$i]}
			VMSTATS+=("${LOG_DIR}/migration-total-stat-${stat}")
			#echo ${stat} > ${VMSTATS[$i]}
			cat ${LOG_DIR}/proc-vmstat-${BENCH_NAME} | grep -w ${stat} |\
				awk -f ${TRACE_DIR}/total.awk.script >> ${VMSTATS[$i]}
		done
		paste -d" " ${VMSTATS[@]} > ${LOG_DIR}/migration-total-stat
		rm -f ${VMSTATS[@]}
		unset VMSTATS

		# total migration/promotion fail stat
		VMSTATS=()
		for i in `seq 0 $((${#TOTAL_FAILS[@]}-1))`; do
			stat=${TOTAL_FAILS[$i]}
			VMSTATS+=("${LOG_DIR}/migration-total-fail-stat-${stat}")
			#echo ${stat} > ${VMSTATS[$i]}
			cat ${LOG_DIR}/proc-vmstat-${BENCH_NAME} | grep -w ${stat} |\
				awk -f ${TRACE_DIR}/total.awk.script >> ${VMSTATS[$i]}
		done
		paste -d" " ${VMSTATS[@]} > ${LOG_DIR}/migration-total-fail-stat
		rm -f ${VMSTATS[@]}
		unset VMSTATS

		rm ${LOG_DIR}/proc-zoneinfo-${BENCH_NAME}
		rm ${LOG_DIR}/proc-vmstat-${BENCH_NAME}

		# Least Accesed page list statistics
		if [ -e ${LOG_DIR}/proc-lapinfo-${BENCH_NAME}.gz ];then
			gzip -d -k ${LOG_DIR}/proc-lapinfo-${BENCH_NAME}.gz
		else
			continue
		fi

		# LAP stat
		VMSTATS=()
		for i in `seq 0 $((${#LAP_STATS[@]}-1))`; do
			stat=${LAP_STATS[$i]}
			VMSTATS+=("${LOG_DIR}/lapinfo-${stat}")

			cat ${LOG_DIR}/proc-lapinfo-${BENCH_NAME} \
				| grep -A1 "${stat}" \
				| grep Node \
				| awk -f ${TRACE_DIR}/lapinfo.awk.script \
				> ${VMSTATS[$i]}

			echo > ${VMSTATS[$i]}-total
			for node in ${NODES[@]}; do
				cat ${VMSTATS[$i]} | grep "Node$node" \
					> ${VMSTATS[$i]}-node${node}

				cat ${VMSTATS[$i]}-node${node} \
					| awk -F "," -f ${TRACE_DIR}/total_lap_demotion.awk.script\
					>> ${VMSTATS[$i]}-total
			done
		done
		#rm -f ${VMSTATS[@]}
		unset VMSTATS
		rm ${LOG_DIR}/proc-lapinfo-${BENCH_NAME}
	done

	echo ${TOTAL_STATS[@]} > ${VMSTAT_LOG}
	for ITER in ${ITERS[@]}; do
		LOG_DIR=${BASE_LOG_DIR}/${ITER}
		cat ${LOG_DIR}/migration-total-stat >> ${VMSTAT_LOG}
	done

	echo ${TOTAL_FAILS[@]} >> ${VMSTAT_LOG}
	for ITER in ${ITERS[@]}; do
		LOG_DIR=${BASE_LOG_DIR}/${ITER}
		cat ${LOG_DIR}/migration-total-fail-stat >> ${VMSTAT_LOG}
	done
}

func_trace_migration_stat ${TEST}
