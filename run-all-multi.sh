#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "Please run as root or sudo"
    exit -1
fi

# ./run-multi.sh 559.pmniGhost graphmat 64GB twitter
# ./run-multi.sh 559.pmniGhost 553.pclvrleaf 64GB 64GB
# ./run-multi.sh 559.pmniGhost graph500 64GB 64GB
./run-multi.sh graph500 graphmat 64GB twitter
