#!/usr/bin/python3

import sys
import csv
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import argparse
import subprocess
import numpy as np
import pandas as pd
import monitor
from matplotlib.patches import Ellipse, Polygon
from matplotlib.lines import Line2D
from matplotlib.patches import Patch

DATE = ""

MMTEST_DIR="."
LOG_DIR = MMTEST_DIR + "/logs"
PLOT_DIR= MMTEST_DIR + "/plots"


class Lapinfo(monitor._Monitor):
    def __init__(self, name):
        super().__init__(name)

def stack_plot(benchname, lapinfo):
    global LOG_DIR
    global DATE
    global NUM_NODES

    NUM_NODES=[i for i in range(0,4)]

    levels = [i for i in range(9)]
    labels = ["Level{}".format(i) for i in range(9)]

    n_levels = len(levels)

    colormap="OrRd"

    # Define your mappable for colorbar creation
    sm = plt.cm.ScalarMappable(cmap=plt.get_cmap(colormap, n_levels),
            norm=plt.Normalize(vmin=levels[0], vmax=levels[-1] + 1))
    sm._A = []

    for m in lapinfo:
        fig, ax = plt.subplots(nrows=4, sharey=False, sharex='all', figsize=[10, 10])
        test_name = m.get_test_name()
        for node in NUM_NODES:
            filename = "{}/{}/iter-1/lapinfo-pages-node{}".format(LOG_DIR, test_name, node)
            NAMES = ["Node"]
            NAMES = NAMES + ["Node{}-level{}".format(node, i) for i in levels]

            try:
                df = pd.read_csv(filename, header=None, names=NAMES)
            except FileNotFoundError:
                return -1

            snsdf = df.loc[:, NAMES[1:]]

            area = snsdf.plot(linewidth=0.0, kind='area', cmap=colormap, ax=ax[node], legend=None)
            ax[node].set_title("Node {}".format(node))

            if node == 3:
                ax[node].set_xlabel("Time(s)")
            else:
                ax[node].tick_params(bottom=False)

            ylabels = ['{:,.0f}'.format(x) + 'K' for x in area.get_yticks()/1000]
            ticks_loc = area.get_yticks().tolist()
            area.yaxis.set_major_locator(mticker.FixedLocator(ticks_loc))
            area.set_yticklabels(ylabels)

            cbar_ax = fig.add_axes([0.90, 0.10, 0.025, 0.8])
            cbar = fig.colorbar(sm, cax=cbar_ax, ticks=levels)
            cbar.ax.set_yticklabels(labels, va='bottom')
            cbar.ax.set_title("LAP levels")

        fig.text(0.025, 0.50, "# of page per NUMA node at LAP level", va='center', rotation='vertical')
        fig.subplots_adjust(top=0.9, left=0.11, right=0.85)
        fig.suptitle(benchname)

        plt.savefig(PLOT_DIR + "/{}/{}-{}-lapinfo-{}-stack.png".format(benchname, DATE, benchname, m.label))
        #plt.show()
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
        print("Help: ./lapinfo.py -h")
        return

    CASE_LIST = subprocess.check_output(
            "ls " + LOG_DIR + " | grep {}- | grep -v log".format(DATE),
            shell=True, universal_newlines=True)
    CASE_LIST = CASE_LIST.strip().split("\n")
    #print(CASE_LIST)

    lapinfo = [Lapinfo(case) for case in CASE_LIST]

    if stack_plot(BENCH_NAME, lapinfo) == -1:
        print("ERROR: File read error")
        return -1

    print("Done! : {}".format(s_name))

if __name__ == '__main__':
    main()
