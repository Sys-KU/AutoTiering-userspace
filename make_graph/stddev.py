#!/usr/bin/python3 

import sys
import csv
import matplotlib.pyplot as plt
import argparse
import subprocess
import numpy as np

stddev_value=[]
times=[]

MMTEST_DIR="/home/kjh/git/benchmark/sdhm/autonuma"
LOG_DIR = MMTEST_DIR + "/logs"
PLOT_DIR= MMTEST_DIR + "/plots"

def normalize(base, target):
    return target/base


def plot(data, bench_name, date, labels):
    global PLOT_DIR
    stddev_image = PLOT_DIR + "/{}/{}-{}-stddev.png".format(bench_name, date, bench_name)
    metric=data[0]
    y=data[1:]


    #labels=["0x{}".format(label) for label in range(len(y))]
    #colors=["lightgrey", "silver", "gray", "dimgray", "slategray", "black"]

    fig, stddev = plt.subplots()

    width = 0.15
    index = np.arange(len(y))

    stddev.set_xlabel("NUMA balancing option", fontsize='x-large')
    stddev.set_ylabel(metric, fontsize='x-large')
    stddev.set_axisbelow(True)
    stddev.tick_params(axis='x', labelsize='large')
    stddev.tick_params(axis='y', labelsize='large')
    stddev.grid(b=True, linestyle='solid', axis='y')
    print(labels)
    print(y)

    base = float(y[0])
    for i in range(0, len(index)):
        t1 = float(y[i])
        #t1 = normalize(base, t1)
        b, = stddev.bar(index[i], t1, width=width, edgecolor='black') #color=colors[i], 

    stddev.set_xticks(index)
    stddev.set_xticklabels(labels, rotation=45)
    stddev.set_title(bench_name)

    plt.subplots_adjust(top=0.90, bottom=0.35, right=0.95, left=0.12)
    fig.set_size_inches(8, 5)

    plt.savefig(stddev_image, format="png")
    #plt.savefig("images/specjbb2015.pdf", format="pdf")
    #plt.show()
    plt.close()


def read_data(bench_name, date):
    global LOG_DIR
    filename = LOG_DIR + "/{}-{}-stddev.log".format(date, bench_name)
    with open(filename, newline='') as csv_file:
        line = csv.reader(csv_file, delimiter=',')
        for entry in line:
            for jops in entry:
                stddev_value.append(jops)
    return stddev_value

def main():
    global LOG_DIR
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
            #print(DATE)
    else:
        print("Help: ./stddev.py -h")
        return


    CASE_LIST = subprocess.check_output("ls {} | grep {}-{} | grep -v log"
                                        .format(LOG_DIR, DATE, BENCH_NAME),
                                        shell=True, universal_newlines=True)
    CASE_LIST = CASE_LIST.strip().split("\n")
    labels = []
    for case in CASE_LIST:
        tmp_str = case.split("-")
        labels.append(tmp_str[-2] + '-' + tmp_str[-1])

    data = read_data(BENCH_NAME, DATE)
    plot(data, BENCH_NAME, DATE, labels)

    print("Done! : {}".format(s_name))

if __name__ == '__main__':
    main()
