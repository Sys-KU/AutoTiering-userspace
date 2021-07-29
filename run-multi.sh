#!/bin/bash

BENCH1=$1
BENCH2=$2
WSS_1=$3
WSS_2=$4

LONG=(1 0)

SINGLE=1
ISOLATED=1
THREAD_16=1
THREAD_32=1
RUN=1

COLLECT=1
PRINT=1

for long in ${LONG[@]}; do
	if [ $SINGLE -eq 1 ]; then
		DATE=multi_socket_16thread
		if [ $RUN -eq 1 ]; then
			# ### Solo Run, Multi socket binding with 16 thread (Baseline)####
			sudo ./run-bench.sh -b ${BENCH1} -d ${DATE} --wss ${WSS_1} --sequence a --max-thread 16 --iter 1 --autonuma
			sudo ./run-bench.sh -b ${BENCH1} -d ${DATE} --wss ${WSS_1} --sequence b --max-thread 16 --iter 1 --autonuma --cpm
			sudo ./run-bench.sh -b ${BENCH1} -d ${DATE} --wss ${WSS_1} --sequence c --max-thread 16 --iter 1 --autonuma --opm bg

			### Solo Run, Multi socket binding with 16 thread (Baseline) ####
			sudo ./run-bench.sh -b ${BENCH2} -d ${DATE} --wss ${WSS_2} --sequence a --max-thread 16 --iter 1 --autonuma
			sudo ./run-bench.sh -b ${BENCH2} -d ${DATE} --wss ${WSS_2} --sequence b --max-thread 16 --iter 1 --autonuma --cpm
			sudo ./run-bench.sh -b ${BENCH2} -d ${DATE} --wss ${WSS_2} --sequence c --max-thread 16 --iter 1 --autonuma --opm bg
		fi
		if [ $COLLECT -eq 1 ]; then
			if [ $PRINT -eq 1 ]; then
				sudo ./collect-data.sh -b ${BENCH1} -d ${DATE} -p summary
				sudo ./collect-data.sh -b ${BENCH2} -d ${DATE} -p summary
			else
				sudo ./collect-data.sh -b ${BENCH1} -d ${DATE}
				sudo ./collect-data.sh -b ${BENCH2} -d ${DATE}
			fi
		fi

		DATE=multi_socket_32thread
		if [ $RUN -eq 1 ]; then
			#### Solo Run, Multi socket binding with 32 thread (Baseline) #### 
			sudo ./run-bench.sh -b ${BENCH1} -d ${DATE} --wss ${WSS_1} --sequence a --max-thread 16 --iter 1 --autonuma
			sudo ./run-bench.sh -b ${BENCH1} -d ${DATE} --wss ${WSS_1} --sequence b --max-thread 16 --iter 1 --autonuma --cpm
			sudo ./run-bench.sh -b ${BENCH1} -d ${DATE} --wss ${WSS_1} --sequence c --max-thread 16 --iter 1 --autonuma --opm bg

			#### Solo Run, Multi socket binding with 32 thread (Baseline) #### 
			sudo ./run-bench.sh -b ${BENCH2} -d ${DATE} --wss ${WSS_2} --sequence a --max-thread 32 --iter 1 --autonuma
			sudo ./run-bench.sh -b ${BENCH2} -d ${DATE} --wss ${WSS_2} --sequence b --max-thread 32 --iter 1 --autonuma --cpm
			sudo ./run-bench.sh -b ${BENCH2} -d ${DATE} --wss ${WSS_2} --sequence c --max-thread 32 --iter 1 --autonuma --opm bg
		fi
		if [ $COLLECT -eq 1 ]; then
			if [ $PRINT -eq 1 ]; then
				sudo ./collect-data.sh -b ${BENCH1} -d ${DATE} -p summary
				sudo ./collect-data.sh -b ${BENCH2} -d ${DATE} -p summary
			else
				sudo ./collect-data.sh -b ${BENCH1} -d ${DATE}
				sudo ./collect-data.sh -b ${BENCH2} -d ${DATE}
			fi
		fi

		DATE=single_socket_16thread
		if [ $RUN -eq 1 ]; then
			# ### Solo Run, Multi socket binding with 16 thread (Baseline)####
			sudo ./run-bench.sh -b ${BENCH1} -d ${DATE} --wss ${WSS_1} --socket 0 --sequence a --max-thread 16 --iter 1 --autonuma
			sudo ./run-bench.sh -b ${BENCH1} -d ${DATE} --wss ${WSS_1} --socket 0 --sequence b --max-thread 16 --iter 1 --autonuma --cpm
			sudo ./run-bench.sh -b ${BENCH1} -d ${DATE} --wss ${WSS_1} --socket 0 --sequence c --max-thread 16 --iter 1 --autonuma --opm bg

			### Solo Run, Multi socket binding with 16 thread (Baseline) ####
			sudo ./run-bench.sh -b ${BENCH2} -d ${DATE} --wss ${WSS_2} --socket 0 --sequence a --max-thread 16 --iter 1 --autonuma
			sudo ./run-bench.sh -b ${BENCH2} -d ${DATE} --wss ${WSS_2} --socket 0 --sequence b --max-thread 16 --iter 1 --autonuma --cpm
			sudo ./run-bench.sh -b ${BENCH2} -d ${DATE} --wss ${WSS_2} --socket 0 --sequence c --max-thread 16 --iter 1 --autonuma --opm bg
		fi
		if [ $COLLECT -eq 1 ]; then
			if [ $PRINT -eq 1 ]; then
				sudo ./collect-data.sh -b ${BENCH1} -d ${DATE} -p summary
				sudo ./collect-data.sh -b ${BENCH2} -d ${DATE} -p summary
			else
				sudo ./collect-data.sh -b ${BENCH1} -d ${DATE} 
				sudo ./collect-data.sh -b ${BENCH2} -d ${DATE} 
			fi
		fi
	fi

	if [ $ISOLATED -eq 1 ]; then
		if [[ ${long} -eq 1 ]]; then
			DATE=socket0_${BENCH1}_long_socket1_${BENCH2}
			WSS1=${WSS_1}_long
			WSS2=${WSS_2}

			KILL_BENCH=($(echo ${BENCH1} | tr "." " "))
			KILL=${KILL_BENCH[1]}
			if [[ ${BENCH1} == "graphmat" ]]; then
				KILL=PageRank
			elif [[ ${BENCH1} == "graph500" ]]; then
				KILL=omp-csr
			elif [[ ${BENCH1} == "559.pmniGhost" ]]; then
				KILL=miniGhost
			fi
			echo $DATE $WSS1 $WSS2 $KILL
		else
			DATE=socket0_${BENCH1}_socket1_${BENCH2}_long
			WSS1=${WSS_1}
			WSS2=${WSS_2}_long

			KILL_BENCH=($(echo ${BENCH2} | tr "." " "))
			KILL=${KILL_BENCH[1]}
			if [[ ${BENCH2} == "graphmat" ]]; then
				KILL=PageRank
			elif [[ ${BENCH2} == "graph500" ]]; then
				KILL=omp-csr
			elif [[ ${BENCH2} == "559.pmniGhost" ]]; then
				KILL=miniGhost
			fi
			echo $DATE $WSS1 $WSS2 $KILL
		fi

		## Single socket binding ####
		if [ $RUN -eq 1 ]; then
			if [[ ${long} -eq 1 ]]; then # bench1:long bench2:short
				./run-bench.sh --benchmark $BENCH1 --date $DATE --socket 0  --wss $WSS1 --sequence a --iter 1 --autonuma &
				sleep 3
				./run-bench.sh --benchmark $BENCH2 --date $DATE --socket 1  --wss $WSS2 --sequence a --iter 1 --autonuma
				sudo pkill $KILL

				./run-bench.sh --benchmark $BENCH1 --date $DATE --socket 0  --wss $WSS1 --sequence b --iter 1 --autonuma --cpm &
				sleep 3
				./run-bench.sh --benchmark $BENCH2 --date $DATE --socket 1  --wss $WSS2 --sequence b --iter 1 --autonuma --cpm
				sudo pkill $KILL

				./run-bench.sh --benchmark $BENCH1 --date $DATE --socket 0  --wss $WSS1 --sequence c --iter 1 --autonuma --opm bg &
				sleep 3
				./run-bench.sh --benchmark $BENCH2 --date $DATE --socket 1  --wss $WSS2 --sequence c --iter 1 --autonuma --opm bg
				sudo pkill $KILL
			else
				./run-bench.sh --benchmark $BENCH2 --date $DATE --socket 0  --wss $WSS2 --sequence a --iter 1 --autonuma &
				sleep 3
				./run-bench.sh --benchmark $BENCH1 --date $DATE --socket 1  --wss $WSS1 --sequence a --iter 1 --autonuma
				sudo pkill $KILL

				./run-bench.sh --benchmark $BENCH2 --date $DATE --socket 0  --wss $WSS2 --sequence b --iter 1 --autonuma --cpm &
				sleep 3
				./run-bench.sh --benchmark $BENCH1 --date $DATE --socket 1  --wss $WSS1 --sequence b --iter 1 --autonuma --cpm
				sudo pkill $KILL

				./run-bench.sh --benchmark $BENCH2 --date $DATE --socket 0  --wss $WSS2 --sequence c --iter 1 --autonuma --opm bg &
				sleep 3
				./run-bench.sh --benchmark $BENCH1 --date $DATE --socket 1  --wss $WSS1 --sequence c --iter 1 --autonuma --opm bg
				sudo pkill $KILL
			fi
		fi
		if [ $COLLECT -eq 1 ]; then
			if [ $PRINT -eq 1 ]; then
				sudo ./collect-data.sh -b ${BENCH1} -d ${DATE} -p summary
				sudo ./collect-data.sh -b ${BENCH2} -d ${DATE} -p summary
			else
				sudo ./collect-data.sh -b ${BENCH1} -d ${DATE} 
				sudo ./collect-data.sh -b ${BENCH2} -d ${DATE} 
			fi
		fi
	fi


	if [ $THREAD_16 -eq 1 ]; then
		if [[ ${long} -eq 1 ]]; then
			DATE=multi_socket_16thread_${BENCH1}_long_${BENCH2}
			WSS1=${WSS_1}_long
			WSS2=${WSS_2}

			KILL_BENCH=($(echo ${BENCH1} | tr "." " "))
			KILL=${KILL_BENCH[1]}
			if [[ ${BENCH1} == "graphmat" ]]; then
				KILL=PageRank
			elif [[ ${BENCH1} == "graph500" ]]; then
				KILL=omp-csr
			elif [[ ${BENCH1} == "559.pmniGhost" ]]; then
				KILL=miniGhost
			fi
			echo $DATE $WSS1 $WSS2 $KILL
		else
			DATE=multi_socket_16thread_${BENCH1}_${BENCH2}_long
			WSS1=${WSS_1}
			WSS2=${WSS_2}_long

			KILL_BENCH=($(echo ${BENCH2} | tr "." " "))
			KILL=${KILL_BENCH[1]}
			if [[ ${BENCH2} == "graphmat" ]]; then
				KILL=PageRank
			elif [[ ${BENCH2} == "graph500" ]]; then
				KILL=omp-csr
			elif [[ ${BENCH2} == "559.pmniGhost" ]]; then
				KILL=miniGhost
			fi
			echo $DATE $WSS1 $WSS2 $KILL
		fi
		#### Multi socket binding 16 threads ####
		if [ $RUN -eq 1 ]; then
			if [[ ${long} -eq 1 ]]; then # bench1:long bench2:short
				./run-bench.sh --benchmark $BENCH1 --date $DATE --max-threads 16  --wss $WSS1 --sequence a --iter 1 --autonuma  &
				sleep 3
				./run-bench.sh --benchmark $BENCH2 --date $DATE --max-threads 16  --wss $WSS2 --sequence a --iter 1 --autonuma
				sudo pkill $KILL

				./run-bench.sh --benchmark $BENCH1 --date $DATE --max-threads 16  --wss $WSS1 --sequence b --iter 1 --autonuma --cpm &
				sleep 3
				./run-bench.sh --benchmark $BENCH2 --date $DATE --max-threads 16  --wss $WSS2 --sequence b --iter 1 --autonuma --cpm
				sudo pkill $KILL

				./run-bench.sh --benchmark $BENCH1 --date $DATE --max-threads 16  --wss $WSS1 --sequence c --iter 1 --autonuma --opm bg &
				sleep 3
				./run-bench.sh --benchmark $BENCH2 --date $DATE --max-threads 16  --wss $WSS2 --sequence c --iter 1 --autonuma --opm bg
				sudo pkill $KILL
			else # bench1:short bench2:long
				./run-bench.sh --benchmark $BENCH2 --date $DATE --max-threads 16  --wss $WSS2 --sequence a --iter 1 --autonuma  &
				sleep 3
				./run-bench.sh --benchmark $BENCH1 --date $DATE --max-threads 16  --wss $WSS1 --sequence a --iter 1 --autonuma
				sudo pkill $KILL

				./run-bench.sh --benchmark $BENCH2 --date $DATE --max-threads 16  --wss $WSS2 --sequence b --iter 1 --autonuma --cpm &
				sleep 3
				./run-bench.sh --benchmark $BENCH1 --date $DATE --max-threads 16  --wss $WSS1 --sequence b --iter 1 --autonuma --cpm
				sudo pkill $KILL

				./run-bench.sh --benchmark $BENCH2 --date $DATE --max-threads 16  --wss $WSS2 --sequence c --iter 1 --autonuma --opm bg &
				sleep 3
				./run-bench.sh --benchmark $BENCH1 --date $DATE --max-threads 16  --wss $WSS1 --sequence c --iter 1 --autonuma --opm bg
				sudo pkill $KILL
			fi
			echo "#### Done Multi socket binding 16 threads ####"
		fi
		if [ $COLLECT -eq 1 ]; then
			if [ $PRINT -eq 1 ]; then
				sudo ./collect-data.sh -b ${BENCH1} -d ${DATE} -p summary
				sudo ./collect-data.sh -b ${BENCH2} -d ${DATE} -p summary
			else
				sudo ./collect-data.sh -b ${BENCH1} -d ${DATE} 
				sudo ./collect-data.sh -b ${BENCH2} -d ${DATE} 
			fi
		fi
	fi


	if [ $THREAD_32 -eq 1 ]; then
		if [[ ${long} -eq 1 ]]; then
			DATE=multi_socket_32thread_${BENCH1}_long_${BENCH2}
			WSS1=${WSS_1}_long
			WSS2=${WSS_2}

			KILL_BENCH=($(echo ${BENCH1} | tr "." " "))
			KILL=${KILL_BENCH[1]}
			if [[ ${BENCH1} == "graphmat" ]]; then
				KILL=PageRank
			elif [[ ${BENCH1} == "graph500" ]]; then
				KILL=omp-csr
			elif [[ ${BENCH1} == "559.pmniGhost" ]]; then
				KILL=miniGhost
			fi
			echo $DATE $WSS1 $WSS2 $KILL
		else
			DATE=multi_socket_32thread_${BENCH1}_${BENCH2}_long
			WSS1=${WSS_1}
			WSS2=${WSS_2}_long

			KILL_BENCH=($(echo ${BENCH2} | tr "." " "))
			KILL=${KILL_BENCH[1]}
			if [[ ${BENCH2} == "graphmat" ]]; then
				KILL=PageRank
			elif [[ ${BENCH2} == "graph500" ]]; then
				KILL=omp-csr
			elif [[ ${BENCH2} == "559.pmniGhost" ]]; then
				KILL=miniGhost
			fi
			echo $DATE $WSS1 $WSS2 $KILL
		fi

		##### Multi socket binding 32 threads ####
		if [ $RUN -eq 1 ]; then
			if [[ ${long} -eq 1 ]]; then # bench1:long bench2:short
				./run-bench.sh --benchmark $BENCH1 --date $DATE --max-threads 32  --wss $WSS1 --sequence a --iter 1 --autonuma  &
				sleep 3
				./run-bench.sh --benchmark $BENCH2 --date $DATE --max-threads 32  --wss $WSS2 --sequence a --iter 1 --autonuma
				pkill $KILL

				./run-bench.sh --benchmark $BENCH1 --date $DATE --max-threads 32  --wss $WSS1 --sequence b --iter 1 --autonuma --cpm &
				sleep 3
				./run-bench.sh --benchmark $BENCH2 --date $DATE --max-threads 32  --wss $WSS2 --sequence b --iter 1 --autonuma --cpm
				pkill $KILL

				./run-bench.sh --benchmark $BENCH1 --date $DATE --max-threads 32  --wss $WSS1 --sequence c --iter 1 --autonuma --opm bg &
				sleep 3
				./run-bench.sh --benchmark $BENCH2 --date $DATE --max-threads 32  --wss $WSS2 --sequence c --iter 1 --autonuma --opm bg
				pkill $KILL
			else # bench1:short bench2:long
				./run-bench.sh --benchmark $BENCH2 --date $DATE --max-threads 32  --wss $WSS2 --sequence a --iter 1 --autonuma  &
				sleep 3
				./run-bench.sh --benchmark $BENCH1 --date $DATE --max-threads 32  --wss $WSS1 --sequence a --iter 1 --autonuma
				pkill $KILL

				./run-bench.sh --benchmark $BENCH2 --date $DATE --max-threads 32  --wss $WSS2 --sequence b --iter 1 --autonuma --cpm &
				sleep 3
				./run-bench.sh --benchmark $BENCH1 --date $DATE --max-threads 32  --wss $WSS1 --sequence b --iter 1 --autonuma --cpm
				pkill $KILL

				./run-bench.sh --benchmark $BENCH2 --date $DATE --max-threads 32  --wss $WSS2 --sequence c --iter 1 --autonuma --opm bg &
				sleep 3
				./run-bench.sh --benchmark $BENCH1 --date $DATE --max-threads 32  --wss $WSS1 --sequence c --iter 1 --autonuma --opm bg
				pkill $KILL
			fi
			echo "#### Done Multi socket binding 16 threads ####"
		fi
		if [ $COLLECT -eq 1 ]; then
			if [ $PRINT -eq 1 ]; then
				sudo ./collect-data.sh -b ${BENCH1} -d ${DATE} -p summary
				sudo ./collect-data.sh -b ${BENCH2} -d ${DATE} -p summary
			else
				sudo ./collect-data.sh -b ${BENCH1} -d ${DATE} 
				sudo ./collect-data.sh -b ${BENCH2} -d ${DATE} 
			fi
		fi
	fi
done
