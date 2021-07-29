#!/usr/bin/python3

import sys
import csv
import matplotlib.pyplot as plt
import argparse
import subprocess
import numpy as np

result_value=[]
stddev_value=[]
comment=""
times=[]

MMTEST_DIR="."
LOG_DIR = MMTEST_DIR + "/logs"
PLOT_DIR= MMTEST_DIR + "/plots"

def normalize(base, target):
    if base == 0:
        return 0
    return target/base


def boxplot(data, bench_name, date, labels, metric):
    global PLOT_DIR
    global comment

    result_image = PLOT_DIR + "/{0}/{1}-{0}-boxplot.png".format(bench_name, date)
    # print(data)

    data_min = {}
    data_max = {}
    data_mean = {}
    data_minmax = {}
    for seq in data.keys():
        data[seq] = list(map(float, data[seq][1:]))
        # print("{}: {}".format(seq, data[seq]))

        data_min[seq] = min(data[seq])
        data_max[seq] = max(data[seq])
        data_mean[seq] = sum(data[seq]) / len(data[seq])
        data_minmax[seq] = [[data_mean[seq] - data_min[seq]], [data_max[seq] - data_mean[seq]]]
        # print(data_min, data_max, data_mean, data_minmax)

    width = 0.10
    index = np.arange(len(data))
    # print(index)
    fig, result = plt.subplots()

    result.set_xlabel("NUMA balancing option", fontsize='x-large')
    result.set_ylabel(metric, fontsize='x-large')
    result.set_axisbelow(True)
    result.tick_params(axis='x', labelsize='large')
    result.tick_params(axis='y', labelsize='large')
    result.grid(b=True, linestyle='solid', axis='y')

    # result.boxplot(list(data.values()), meanline=True)
    i = 0
    for key in data_mean.keys():
        y = float(data_mean[key])
        result.bar(index[i], y, edgecolor='black', width=width, yerr=data_minmax[key])
        i = i + 1

    result.set_xticklabels(labels, rotation=45)
    result.set_title(bench_name + " " + comment)

    plt.subplots_adjust(top=0.90, bottom=0.35, right=0.95, left=0.12)
    fig.set_size_inches(8, 5)

    try:
        plt.savefig(result_image, format="png")
    except FileNotFoundError as e:
        subprocess.run("mkdir -p {}/{}".format(PLOT_DIR, bench_name),
                shell=True, universal_newlines=True)
        plt.savefig(result_image, format="png")
    # plt.show()
    plt.close()


def plot(data, bench_name, date, labels, metric):
    global PLOT_DIR
    global comment
    result_image = PLOT_DIR + "/{0}/{1}-{0}-summary.png".format(bench_name, date)
    if metric == "stddev":
        result_image = PLOT_DIR + "/{0}/{1}-{0}-stddev.png".format(bench_name, date)
    y=data[1:]

    fig, result = plt.subplots()

    width = 0.15
    index = np.arange(len(y))

    result.set_xlabel("NUMA balancing option", fontsize='x-large')
    result.set_ylabel("Normalized " + metric, fontsize='x-large')
    result.set_axisbelow(True)
    result.tick_params(axis='x', labelsize='large')
    result.tick_params(axis='y', labelsize='large')
    result.grid(b=True, linestyle='solid', axis='y')

    base = float(y[0])
    for i in range(0, len(index)):
        t1 = float(y[i])
        t1 = normalize(base, t1)
        b, = result.bar(index[i], t1, width=width, edgecolor='black') #color=colors[i], 

    result.set_xticks(index)
    result.set_xticklabels(labels, rotation=45)
    result.set_title(bench_name + " " + comment)

    plt.subplots_adjust(top=0.90, bottom=0.35, right=0.95, left=0.12)
    fig.set_size_inches(8, 5)

    try:
        plt.savefig(result_image, format="png")
    except FileNotFoundError as e:
        subprocess.run("mkdir -p {}/{}".format(PLOT_DIR, bench_name),
                shell=True, universal_newlines=True)
        plt.savefig(result_image, format="png")

    # plt.show()
    plt.close()


def read_data(date):
    global LOG_DIR
    global comment

    # Read benchmark result summary log
    filename = LOG_DIR + "/{}-summary.log".format(date)
    with open(filename, newline='') as csv_file:
        line = csv.reader(csv_file, delimiter=',')
        for entry in line:
            for value in entry:
                result_value.append(value)

    # Read benchmark stddev log
    filename = LOG_DIR + "/{}-stddev.log".format(date)
    with open(filename, newline='') as csv_file:
        line = csv.reader(csv_file, delimiter=',')
        for entry in line:
            for value in entry:
                stddev_value.append(value)

    # Read benchmark comment log if exist
    filename = LOG_DIR + "/{}-comment.log".format(date)
    try:
        with open(filename, newline='') as csv_file:
            line = csv.reader(csv_file)
            for entry in line:
                comment = "".join(entry)
    except FileNotFoundError:
        comment = ""

    SEQ_LIST = subprocess.check_output("ls {} | grep {}-.*-result.log"
                                        .format(LOG_DIR, date),
                                        shell=True, universal_newlines=True)
    SEQ_LIST = SEQ_LIST.strip().split("\n")
    seq_value = {}
    for seq in SEQ_LIST:
        seq_label = seq.split("-")[1]
        seq_value[seq_label] = []
        filename = LOG_DIR + "/{}".format(seq)
        with open(filename, newline='') as csv_file:
            line = csv.reader(csv_file, delimiter=' ')
            for entry in line:
                for value in entry:
                    seq_value[seq_label].append(value)
    return result_value, stddev_value, seq_value

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
    else:
        print("Help: ./result.py -h")
        return

    CASE_LIST = subprocess.check_output("ls {} | grep {} | grep -v log"
                                        .format(LOG_DIR, DATE),
                                        shell=True, universal_newlines=True)
    CASE_LIST = CASE_LIST.strip().split("\n")
    labels = []
    for case in CASE_LIST:
        tmp_str = case.split("-")
        label = ""
        for i in range(0, len(tmp_str)):
            if i > 1 and tmp_str[i] != 'OFF':
                label = label + "-" + tmp_str[i]
        labels.append(label[1:])

    # Read data from log files
    result_data, stddev_data, seq_data = read_data(DATE)

    # Plot result, stddev, boxplot
    plot(result_data, BENCH_NAME, DATE, labels, result_data[0])
    # plot(stddev_data, BENCH_NAME, DATE, labels, stddev_data[0])
    # boxplot(seq_data, BENCH_NAME, DATE, labels, seq_data["a"][0])

    print("Done! : {}".format(s_name))

if __name__ == '__main__':
    main()
