#!/bin/bash
NODES=(0 1 2 3)

function func_trace_numa_meminfo() {
        local name=$1
	BASE_LOG_DIR=logs/${BENCH_NAME}/${name}
	#ITERS=($(ls ${BASE_LOG_DIR}))
	ITERS=(iter-1)
	for ITER in ${ITERS[@]}; do
		LOG_DIR=${BASE_LOG_DIR}/${ITER}
		gzip -d -k ${LOG_DIR}/numa-meminfo-${BENCH_NAME}.gz
		for page_state in Active Inactive; do
			MEMINFOS=()
			MEMINFOS_ANON=()
			MEMINFOS_FILE=()
			for node in ${NODES[@]}; do
				MEM_LOG=${LOG_DIR}/numa-meminfo-${node}-${page_state}
				if [[ $(grep -c "Node ${node}" ${LOG_DIR}/numa-meminfo-${BENCH_NAME}) == "0" ]];then
					# Skip
					continue
				fi
				MEMINFOS+=( "${MEM_LOG}" )
				MEMINFOS_ANON+=( "${MEM_LOG}-anon" )
				MEMINFOS_FILE+=( "${MEM_LOG}-file" )
				echo "Node${node}" > ${MEM_LOG}
				cat ${LOG_DIR}/numa-meminfo-${BENCH_NAME} | \
					grep "Node ${node}" | grep "${page_state}:" |\
					awk '{print $(NF-1)}' \
					>> ${MEM_LOG}
				echo "Node${node}" > ${MEM_LOG}-anon
				cat ${LOG_DIR}/numa-meminfo-${BENCH_NAME} | \
					grep "Node ${node}" | grep "${page_state}(anon):" |\
					awk '{print $(NF-1)}' \
					>> ${MEM_LOG}-anon
				echo "Node${node}" > ${MEM_LOG}-file
				cat ${LOG_DIR}/numa-meminfo-${BENCH_NAME} | \
					grep "Node ${node}" | grep "${page_state}(file):" |\
					awk '{print $(NF-1)}' \
					>> ${MEM_LOG}-file
			done
			paste -d"," ${MEMINFOS[@]} > ${LOG_DIR}/node-meminfo-${page_state}
			paste -d"," ${MEMINFOS_ANON[@]} > ${LOG_DIR}/node-meminfo-${page_state}-anon
			paste -d"," ${MEMINFOS_FILE[@]} > ${LOG_DIR}/node-meminfo-${page_state}-file

			rm ${MEMINFOS[@]}
			rm ${MEMINFOS_ANON[@]}
			rm ${MEMINFOS_FILE[@]}

			unset MEMINFOS
			unset MEMINFOS_ANON
			unset MEMINFOS_FILE
		done

		rm ${LOG_DIR}/numa-meminfo-${BENCH_NAME}
	done
}

func_trace_numa_meminfo ${TEST}
