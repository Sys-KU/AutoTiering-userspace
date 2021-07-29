#!/bin/bash
BENCH=graph500

# Scan: 1000ms 2048mb
./mem_fault_lat.py -b $BENCH -d cont_monitor_8_b cont_monitor_8_c
./mem_fault_lat.py -b $BENCH -d cont_monitor_8_b cont_monitor_8_d
./mem_fault_lat.py -b $BENCH -d cont_monitor_8_c cont_monitor_8_d
