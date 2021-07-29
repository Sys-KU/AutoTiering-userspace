#!/bin/bash
case $BENCH_NAME in
	"hpcc")
		rm -f hpcc*
		;;
	"553.pclvrleaf")
		rm -f clover.*
		;;
	"555.pseismic")
		rm -f *.dat
		rm -f *.pnm
		rm -f timestamp*
		;;
	"560.pilbdc")
		rm -f *_chk
		;;
	*)
		;;
esac
