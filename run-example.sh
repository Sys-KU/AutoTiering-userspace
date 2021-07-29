#!/bin/bash
DATE=$(date +%Y%m%d%H%M)

if [ $EUID -ne 0 ]; then
    echo "Please run as root or sudo"
    exit -1
fi

./run-bench.sh --benchmark graph500 --monitor --wss 64GB --date $DATE --sequence a --autonuma
./run-bench.sh --benchmark graph500 --monitor --wss 64GB --date $DATE --sequence b --cpm
./run-bench.sh --benchmark graph500 --monitor --wss 64GB --date $DATE --sequence c --cpm --exchange
./run-bench.sh --benchmark graph500 --monitor --wss 64GB --date $DATE --sequence d --opm fg --exchange
./run-bench.sh --benchmark graph500 --monitor --wss 64GB --date $DATE --sequence e --opm bg
