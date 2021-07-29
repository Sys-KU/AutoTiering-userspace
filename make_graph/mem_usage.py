#!/usr/bin/python3

import sys
import csv
import matplotlib.pyplot as plt
import argparse
import subprocess
import numpy as np
import pandas as pd
import monitor
from matplotlib.patches import Ellipse, Polygon
from matplotlib.lines import Line2D
from matplotlib.patches import Patch

DATE = ""

DIR="."
LOG_DIR = DIR + "/logs"
PLOT_DIR= DIR

LRU_BASE = 0
LRU_ACTIVE = 1
LRU_FILE = 2

LRU_INACTIVE_ANON = LRU_BASE
LRU_ACTIVE_ANON = LRU_BASE + LRU_ACTIVE
LRU_INACTIVE_FILE = LRU_BASE + LRU_FILE
LRU_ACTIVE_FILE = LRU_BASE + LRU_FILE + LRU_ACTIVE

LRU_LIST = [
    LRU_INACTIVE_ANON,
    LRU_ACTIVE_ANON,
    LRU_INACTIVE_FILE,
    LRU_ACTIVE_FILE
]

LRU_NAME_LIST = [
    "Inactive-anon",
    "Active-anon",
    "Inactive-file",
    "Active-file"
]

class Meminfo(monitor._Monitor):
    def __init__(self, name):
        super().__init__(name)

def read(benchname, meminfo):
    global LOG_DIR
    global DATE
    global NUM_NODES

    colors = ["maroon", "maroon", "darkorange", "darkorange", "green" ,"green", "darkcyan", "darkcyan"]

    anon = 0
    file = 1

    # anon plot
    fig_anon, ax_anon = plt.subplots(nrows=2, sharey='all', sharex='all', figsize=[4, 6])

    # anon,file plot
    fig, ax = plt.subplots(nrows=2, ncols=2, sharey=False, sharex='all', figsize=[8, 6])

    for m in meminfo:
        if m.cpmopt == "CPM":
            continue;

        test_name = m.get_test_name()
        anon_dfs = []
        file_dfs = []
        NAMES = []
        for lru_name in LRU_NAME_LIST:
            lru = LRU_NAME_LIST.index(lru_name)
            filename = "{}/{}/iter-1/node-meminfo-{}".format(LOG_DIR, test_name, lru_name)
            df = pd.read_csv(filename)
            if lru == LRU_INACTIVE_ANON or lru == LRU_ACTIVE_ANON:
                anon_dfs.append(df)
            if lru == LRU_INACTIVE_FILE or lru == LRU_ACTIVE_FILE:
                file_dfs.append(df)

        NAMES = []
        for node in range(4):
            for lru in ["Inactive", "Active"]:
                NAMES.append("Node{}-{}".format(node, lru))

        anon_df = pd.concat(anon_dfs, axis=1)
        file_df = pd.concat(file_dfs, axis=1)
        sort_anon_df = anon_df.sort_index(axis=1)
        sort_file_df = file_df.sort_index(axis=1)

        sort_anon_df.columns = NAMES
        sort_file_df.columns = NAMES

        # anon plot

        if m.apmopt == "OFF" and m.cpmopt == "OFF": # Baseline
           # ax[m.order].set_ylabel("Baseline")
           ax_anon[m.order].set_title("Baseline", fontsize='16')

        if m.apmopt == "APM":
            m.order = 1
            ax_anon[m.order].set_xlabel("Time(s)", fontsize='16')
           # ax[m.order].set_ylabel("APM")
            ax_anon[m.order].set_title("APM", fontsize='16')
        else:
            ax_anon[m.order].tick_params(bottom=False)

        area = sort_anon_df.plot.area(ax=ax_anon[m.order], linewidth=0.0, legend=None, color=colors)
        start, y_lim = area.get_ylim()
        y_lim = int(y_lim)

        frequency = 1024*1024
        ax_anon[m.order].set_yticks(np.arange(0, y_lim, frequency*10))
        ylabels = ['{:,.0f}'.format(y) for y in area.get_yticks()/frequency]
        area.set_yticklabels(ylabels)

        # anon,file plot
        if m.apmopt == "OFF" and m.cpmopt == "OFF": # Baseline
            ax[m.order, anon].set_ylabel("Baseline", fontsize='16')
            ax[m.order, anon].set_title("Anonymous Region", fontsize='16')
            ax[m.order, file].set_title("File-backed Region", fontsize='16')

        if m.apmopt == "APM":
            m.order = 1
            ax[m.order, anon].set_ylabel("APM", fontsize='16')

            ax[m.order, anon].set_xlabel("Time(s)", fontsize='16')
            ax[m.order, file].set_xlabel("Time(s)", fontsize='16')
        else:
            ax[m.order, anon].tick_params(bottom=False)
            ax[m.order, file].tick_params(bottom=False)

        area_anon = sort_anon_df.plot.area(ax=ax[m.order, anon], linewidth=0.0, legend=None, color=colors)
        area_file = sort_file_df.plot.area(ax=ax[m.order, file], linewidth=0.0, legend=None, color=colors)

        start, y_lim = area_anon.get_ylim()
        y_lim = int(y_lim)
        frequency = 1024*1024
        ax[m.order, anon].set_yticks(np.arange(0, y_lim, frequency*10))
        ylabels = ['{:,.0f}'.format(y) for y in area_anon.get_yticks()/frequency]
        area_anon.set_yticklabels(ylabels)

        start, y_lim = area_file.get_ylim()
        y_lim = int(y_lim)
        frequency = 1024*1024
        ax[m.order, file].set_yticks(np.arange(0, y_lim, frequency*2))
        ylabels = ['{:,.0f}'.format(y) for y in area_file.get_yticks()/(frequency)]
        area_file.set_yticklabels(ylabels)

    fig_anon.text(0.025, 0.55, "Memory Usages(GiB)", fontsize='14', va='center', rotation='vertical')
    fig_anon.subplots_adjust(top=0.9, bottom=0.20, left=0.16, right=0.95)
    fig_anon.suptitle(benchname, fontsize='14')
    fig_anon.savefig(PLOT_DIR + "/mem_usage-{}-anon.pdf".format(benchname), format='pdf')


    fig.text(0.025, 0.55, "Memory Usages(GiB)", fontsize='14', va='center', rotation='vertical')
    fig.subplots_adjust(top=0.9, bottom=0.20, left=0.16, right=0.95)
    fig.suptitle(benchname, fontsize='14')
    fig.savefig(PLOT_DIR + "/mem_usage-{}.pdf".format(benchname), format='pdf')
#    plt.show()
    plt.close()

    return 0


def main():
    global LOG_DIR
    global DATE
    s_name = sys.argv[0]

    parser = argparse.ArgumentParser()
    parser.add_argument("-b", "--benchmark", type=str, nargs=1,
                        help="Select benchmark to draw graph")
    parser.add_argument("-d", "--date", type=str, nargs=1,
                        help="Choose a time for benchmarks to graph")

    args = parser.parse_args()

    if args.benchmark:
        if len(args.benchmark) != 1:
            print("Only 1 Args available: [Benchmark Name]")
            return
        BENCH_NAME = args.benchmark[0]
        LOG_DIR = LOG_DIR + "/" + BENCH_NAME

        if args.date:
            if len(args.date) != 1:
                print("Only 1 Args available: [Date]")
                return
            DATE = args.date[0]
    else:
        print("Help: ./meminfo.py -h")
        return

    CASE_LIST = subprocess.check_output(
            "ls " + LOG_DIR + " | grep {} | grep -v log".format(DATE),
            shell=True, universal_newlines=True)
    CASE_LIST = CASE_LIST.strip().split("\n")
    #print(CASE_LIST)

    meminfo = [Meminfo(case) for case in CASE_LIST]
    if read(BENCH_NAME, meminfo) == -1:
        print("ERROR: File read error")
        return -1

    print("Done! : {} -b {} -d {}".format(s_name, BENCH_NAME, DATE))


if __name__ == '__main__':
    main()
