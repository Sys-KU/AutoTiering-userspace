#!/usr/bin/python3

import sys
import csv
import matplotlib.pyplot as plt
import argparse
import subprocess
import numpy as np
import monitor

DATE = ""

MMTEST_DIR="."
LOG_DIR = MMTEST_DIR + "/logs"
PLOT_DIR= MMTEST_DIR + "/plots"

class Meminfo(monitor._Monitor):
    def __init__(self, name):
        super().__init__(name)
        self.active = {"Node 0": [], "Node 1": [], "Node 2": [], "Node 3": []}
        self.inactive = {"Node 0": [], "Node 1": [], "Node 2": [], "Node 3": []}

    def add_active(self, node, data):
        if self.check_node(node) == -1:
            return
        self.active["Node {}".format(node)].append(data)

    def add_inactive(self, node, data):
        if self.check_node(node) == -1:
            return
        self.inactive["Node {}".format(node)].append(data)

    def set_active(self, node, data):
        if self.check_node(node) == -1:
            return
        self.active["Node {}".format(node)] = data

    def set_inactive(self, node, data):
        if self.check_node(node) == -1:
            return
        self.inactive["Node {}".format(node)] = data

    def get_active(self, node):
        if self.check_node(node) == -1:
            return
        return self.active["Node {}".format(node)]

    def get_inactive(self, node):
        if self.check_node(node) == -1:
            return
        return self.inactive["Node {}".format(node)]


def plot(bench_name, meminfo):
    global PLOT_DIR
    global DATE
    global NUM_NODES
    NODES = list(range(NUM_NODES))
    ACTIVE, INACTIVE = [0, 1]

    fig, ax = plt.subplots(nrows=2, ncols=len(meminfo),
            sharex='col', sharey='row')

    colors = ["maroon", "darkorange", "green", "darkcyan", "royalblue"]

    max_meminfo = 0
    max_order = len(meminfo) - 1
    for m in meminfo:
        order = m.get_order()
        title = m.get_label()

        if max_order != 0:
            ax_active = ax[ACTIVE, order]
            ax_inactive = ax[INACTIVE, order]
        else:
            ax_active = ax[ACTIVE]
            ax_inactive = ax[INACTIVE]

        ax_active.set_title("Active, {}".format(title))
        ax_inactive.set_title("Inactive, {}".format(title))

        for memory_state in [ACTIVE, INACTIVE]:
            if max_order != 0:
                ax_memory_state = ax[memory_state, order]
            else:
                ax_memory_state = ax[memory_state]

            y = []
            for node in NODES:
                if memory_state == ACTIVE:
                    mem = m.get_active(node)
                    if mem == []:
                        continue
                    label = mem.pop(0)

                    mem = list(map(float, mem))
                    mem = [val/1024 for val in mem] # KB --> MB

                elif memory_state == INACTIVE:
                    if mem == []:
                        continue
                    mem = m.get_inactive(node)
                    label = mem.pop(0)

                    mem = list(map(float, mem))
                    mem = [val/1024 for val in mem] # KB --> MB

                else:
                    print("ERROR: Memory state must be either 'Active' or 'Inactive'")
                    return -1

                ax_memory_state.plot([], label=label, color=colors[node])
                ax_memory_state.legend()
                ax_memory_state.set_xlabel("Time(s)")
                ax_memory_state.set_ylabel("Memory Usage(MiB)")

                y.append(mem)

            x = list(range(len(y[0])))
            y_stack = np.vstack(y)
            ax_memory_state.stackplot(x, y_stack, colors=colors)

            for i in range(0, len(y[0])):
                y_sum = sum( [ y[node][i] for node in NODES ] )
                max_meminfo = max(max_meminfo, y_sum)


    plt.subplots_adjust(top=0.95, bottom=0.05, right=0.95, left=0.05)
    fig.set_size_inches(20, 15)
    fig.suptitle("{}, Memory Usage, WSS: {:.0f}MB".format(bench_name, max_meminfo))

    plt.savefig(PLOT_DIR + "/{0}/{1}-{0}-meminfo_v2.png".format(bench_name, DATE),
            format='png')
    # plt.show()
    plt.close()


def read(meminfo):
    global LOG_DIR
    global DATE
    global NUM_NODES

    for memory_state in ["Active", "Inactive"]:
        for m in meminfo:
            test_name = m.get_test_name()
            filename = "{}/{}/iter-1/node-meminfo-{}".format(LOG_DIR, test_name, memory_state)
            with open(filename, newline='') as csv_file:
                line = csv.reader(csv_file, delimiter=',')
                for entry in line:
                    NUM_NODES = len(entry)
                    for node in range(len(entry)):
                        value = entry[node]
                        if memory_state == "Active":
                            m.add_active(node, value)
                        elif memory_state == "Inactive":
                            m.add_inactive(node, value)
                        else:
                            print("ERROR: Memory state must be either 'Active' or 'Inactive'")
                            return -1
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
