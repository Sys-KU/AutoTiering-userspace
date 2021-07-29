# AutoTiering-userspace scripts
This repo contains the userspace experiment scripts in the following Linux kernel:   
* [AutoTiering](https://github.com/csl-ajou/AutoTiering)

## Requirements 
* To run these scripts, you should build and install the AutoTiering Linux kernel with the multi-socket tiered memory system.

## Usage
* `run-example.sh`
  * Run all example cases (graph500 with 64GB)
* `run-all-multi.sh`
  * Run the multi-programmed case
* `collect-data.sh`
  * Collect the result from logs
* `make_graph.sh`
  * Plot graphs of results, memory usages, LAP page distributions and migration stats from logs 
