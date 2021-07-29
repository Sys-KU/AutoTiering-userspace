#!/usr/bin/python3

import sys
import csv
import matplotlib.pyplot as plt
import argparse
import subprocess
import numpy as np
import monitor
from matplotlib.patches import Ellipse, Polygon
from matplotlib.lines import Line2D
from matplotlib.patches import Patch

DATE = ""

MMTEST_DIR="."
LOG_DIR = MMTEST_DIR + "/logs"
PLOT_DIR= MMTEST_DIR + "/plots"

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
        self.active = {"Node 0": [], "Node 1": [], "Node 2": [], "Node 3": []}
        self.inactive = {"Node 0": [], "Node 1": [], "Node 2": [], "Node 3": []}

        self.lruinfo = [ 
                         { "Node 0": [],
                           "Node 1": [],
                           "Node 2": [],
                           "Node 3": []
                          } for i in range(len(LRU_LIST))
                        ]

    def add_active(self, node, data):
        if self.check_node(node) == -1:
            return
        self.active["Node {}".format(node)].append(data)

    def add_inactive(self, node, data):
        if self.check_node(node) == -1:
            return
        self.inactive["Node {}".format(node)].append(data)

    def add_nodeinfo(self, node, lru, data):
        if self.check_node(node) == -1:
            return
        self.lruinfo[lru]["Node {}".format(node)].append(data)

    def set_active(self, node, data):
        if self.check_node(node) == -1:
            return
        self.active["Node {}".format(node)] = data

    def set_inactive(self, node, data):
        if self.check_node(node) == -1:
            return
        self.inactive["Node {}".format(node)] = data

    def set_lruinfo(self, node, data, lru):
        if self.check_node(node) == -1:
            return
        self.lruinfo[lru]["Node {}".format(node)] = data

    def get_active(self, node):
        if self.check_node(node) == -1:
            return
        return self.active["Node {}".format(node)]

    def get_inactive(self, node):
        if self.check_node(node) == -1:
            return
        return self.inactive["Node {}".format(node)]

    def get_nodeinfo(self, node, lru):
        if self.check_node(node) == -1:
            return
        return self.lruinfo[lru]["Node {}".format(node)]

    def get_lruinfo(self, lru):
        return self.lruinfo[lru]


def plot(bench_name, meminfo):
    global PLOT_DIR
    global DATE
    global NUM_NODES
    NODES = list(range(NUM_NODES))
    # print(NUM_NODES)
    fig, ax = plt.subplots(nrows=len(meminfo), ncols=2,
            sharex='all', sharey='all')

    colors = ["maroon", "maroon", "darkorange", "darkorange", "green" ,"green", "darkcyan", "darkcyan"]
    leg_colors = ["maroon", "darkorange", "green", "darkcyan"]
    hatches = ["//////", "xxx"]

    node_leg = [Patch(facecolor=leg_colors[node], edgecolor='black',
        label="Node {}".format(node)) for node in NODES]

    for mem in meminfo:
        inactive_anon = []
        active_anon = []
        inactive_file = []
        active_file = []

        for node in NODES:
            inactive_anon.append(mem.get_nodeinfo(node, LRU_INACTIVE_ANON))
            inactive_anon[node].pop(0)
            inactive_anon[node] = list(map(float, inactive_anon[node]))
            inactive_anon[node] = [val/1024/1024 for val in inactive_anon[node]]

            active_anon.append(mem.get_nodeinfo(node, LRU_ACTIVE_ANON))
            active_anon[node].pop(0)
            active_anon[node] = list(map(float, active_anon[node]))
            active_anon[node] = [val/1024/1024 for val in active_anon[node]]

            inactive_file.append(mem.get_nodeinfo(node, LRU_INACTIVE_FILE))
            inactive_file[node].pop(0)
            inactive_file[node] = list(map(float, inactive_file[node]))
            inactive_file[node] = [val/1024/1024 for val in inactive_file[node]]

            active_file.append(mem.get_nodeinfo(node, LRU_ACTIVE_FILE))
            active_file[node].pop(0)
            active_file[node] = list(map(float, active_file[node]))
            active_file[node] = [val/1024/1024 for val in active_file[node]]

        x = list(range(len(inactive_anon[0])))

        y_inactive_anon = [inactive_anon[node] for node in NODES]
        y_active_anon = [active_anon[node] for node in NODES]
        y_anon_pairs = list(zip(y_inactive_anon, y_active_anon))

        y_anon_list = []
        for i in y_anon_pairs:
            for j in i:
                y_anon_list.append(j)

        y_inactive_file = [inactive_file[node] for node in NODES]
        y_active_file = [active_file[node] for node in NODES]
        y_file_pairs = list(zip(y_inactive_file, y_active_file))

        y_file_list = []
        for i in y_file_pairs:
            for j in i:
                y_file_list.append(j)

        y_anon = np.vstack(y_anon_list)
        y_file = np.vstack(y_file_list)
        # print(len(x), len(y_anon[0]))
        ax[meminfo.index(mem), 0].stackplot(x, y_anon, colors=colors, edgecolor='black')
        ax[meminfo.index(mem), 1].stackplot(x, y_file, colors=colors, edgecolor='black')
        ax[meminfo.index(mem), 0].set_ylabel(mem.get_label(), labelpad=10)

    fig.text(0.53, 0.95, '{}'.format(bench_name), ha='center', fontsize='16')

    ax[0, 0].set_title("Anonymous Region", fontsize='14')
    ax[0, 1].set_title("File-backed Region", fontsize='14')

    plt.legend(handles=node_leg, bbox_to_anchor=(0.67, -0.75), ncol=4)
    plt.subplots_adjust(top=0.90, bottom=0.18, right=0.93, left=0.13)

    fig.add_subplot(111, frame_on=False)
    plt.tick_params(labelcolor="none", bottom=False, left=False)

    plt.xlabel("Time(s)", fontsize='12', labelpad=10)
    plt.ylabel("Memory Usage(GiB)", fontsize='12', labelpad=20)

    fig.set_size_inches(8, 6)

    plt.savefig(PLOT_DIR + "/{0}/{1}-{0}-meminfo.pdf".format(bench_name, DATE),
            format='pdf')
    plt.savefig(PLOT_DIR + "/{0}/{1}-{0}-meminfo.png".format(bench_name, DATE),
            format='png')
    # plt.show()
    plt.close()
    return


def read(meminfo):
    global LOG_DIR
    global DATE
    global NUM_NODES

    for m in meminfo:
        test_name = m.get_test_name()
        for lru_name in LRU_NAME_LIST:
            lru = LRU_NAME_LIST.index(lru_name)
            filename = "{}/{}/iter-1/node-meminfo-{}".format(LOG_DIR, test_name, lru_name)
            with open(filename, newline='') as csv_file:
                data = csv.reader(csv_file, delimiter=',')
                for line in data:
                    NUM_NODES = len(line)
                    for node in range(NUM_NODES):
                        value = line[node]
                        m.add_nodeinfo(node, lru, value)
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
    if read(meminfo) == -1:
        print("ERROR: File read error")
        return -1

    plot(BENCH_NAME, meminfo)

    print("Done! : {}".format(s_name))


if __name__ == '__main__':
    main()
