#!/usr/bin/python3
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('pdf')
import matplotlib.pyplot as plt
import subprocess
import argparse
import sys
import scipy.stats as stats

matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42

PLOT_DIR = "./plots"
_LOG_DIR = "./logs"


class Latency():
    TYPE = ["ondemand_exchange", "promotion", "demotion", "migration"]
    BOUND = 150

    def __init__(self, bench, logdir, caselist, perflist):
        self.BENCH_NAME = bench
        self.LOG_DIR = logdir
        self.CASE_LIST = caselist
        self.FULL_PATH = [f"{logdir}/{case}/iter-1"
                          for case in caselist]
        self.PERF_PATH = [f"{logdir}/{perf}/iter-1"
                          for perf in perflist]


def analyze(latency, FG_DATA, BG_DATA):
    bg = BG_DATA[BG_DATA["time"] < Latency.BOUND]
    fg = FG_DATA[FG_DATA["time"] < Latency.BOUND]
    bg_outliers = BG_DATA[BG_DATA['time'] >= Latency.BOUND]
    fg_outliers = FG_DATA[FG_DATA['time'] >= Latency.BOUND]

    print(f"Note: {Latency.BOUND} us latency data has been filterd")
    print("")

    print(f"---------------- {latency.BENCH_NAME} ----------------")
    print("OPM (BD)")
    print("Proportion of fault types")

    bg_promotion = bg[bg["type"] == "promotion"]
    print(f"Promotion         : \t{len(bg_promotion)}\t"
          f"({len(bg_promotion) / len(bg) * 100:.2f}%)")
    if len(bg_promotion) != 0:
        print(f"\tLocal Promo. : {len(bg_promotion[bg_promotion['promotion_type'] == 2]) / len(bg_promotion) * 100:.2f}%")
        print(f"\tRemote Promo.: {len(bg_promotion[bg_promotion['promotion_type'] == 3]) / len(bg_promotion) * 100:.2f}%")
    print("")

    bg_regular_promotion = bg_promotion[bg_promotion["reserved"] == 0]
    print(f"Regular Promotion  : \t{len(bg_regular_promotion)}\t"
          f"({len(bg_regular_promotion) / len(bg) * 100:.2f}%)")
    if len(bg_regular_promotion) != 0:
        print(f"\tLocal Reg. Promo. : {len(bg_regular_promotion[bg_regular_promotion['promotion_type'] == 2]) / len(bg_regular_promotion) * 100:.2f}%")
        print(f"\tRemote Reg. Promo.: {len(bg_regular_promotion[bg_regular_promotion['promotion_type'] == 3]) / len(bg_regular_promotion) * 100:.2f}%")

    bg_reserved_promotion = bg_promotion[bg_promotion["reserved"] == 1]
    print(f"Reserved Page Promotion  : \t{len(bg_reserved_promotion)}\t"
          f"({len(bg_reserved_promotion) / len(bg) * 100:.2f}%)")
    if len(bg_reserved_promotion) != 0:
        print(f"\tLocal Rsv. Promo. : {len(bg_reserved_promotion[bg_reserved_promotion['promotion_type'] == 2]) / len(bg_reserved_promotion) * 100:.2f}%")
        print(f"\tRemote Rsv. Promo.: {len(bg_reserved_promotion[bg_reserved_promotion['promotion_type'] == 3]) / len(bg_reserved_promotion) * 100:.2f}%")
    print("")

    bg_migration = bg[bg["type"] == "migration"]
    print(f"Migration         : \t{len(bg_migration)}\t"
          f"({len(bg_migration) / len(bg) * 100:.2f}%)")

    print(f"Mig.   (DRAM->DRAM): \t"
          f"{len(bg_migration[(bg_migration['dst'] == 0) | (bg_migration['dst'] == 1)])}")
    print(f"Mig. (DCPMM->DCPMM): \t"
          f"{len(bg_migration[(bg_migration['dst'] == 2) | (bg_migration['dst'] == 3)])}")

    bg_regular_migration = bg_migration[bg_migration["reserved"] == 0]
    print(f"Regular Migration  : \t{len(bg_regular_migration)}\t"
          f"({len(bg_regular_migration) / len(bg) * 100:.2f}%)")
    if len(bg_regular_migration) != 0:
        print(f"Regular Mig.   (DRAM->DRAM): \t"
            f"{len(bg_regular_migration[(bg_regular_migration['dst'] == 0) | (bg_regular_migration['dst'] == 1)])}")
        print(f"Regular Mig. (DCPMM->DCPMM): \t"
            f"{len(bg_regular_migration[(bg_regular_migration['dst'] == 2) | (bg_regular_migration['dst'] == 3)])}")

    bg_reserved_migration = bg_migration[bg_migration["reserved"] == 1]
    print(f"Reserved Page Migration  : \t{len(bg_reserved_migration)}\t"
          f"({len(bg_reserved_migration) / len(bg) * 100:.2f}%)")
    if len(bg_reserved_migration) != 0:
        print(f"Reserved Mig.   (DRAM->DRAM): \t"
            f"{len(bg_reserved_migration[(bg_reserved_migration['dst'] == 0) | (bg_reserved_migration['dst'] == 1)])}")
        print(f"Reserved Mig. (DCPMM->DCPMM): \t"
            f"{len(bg_reserved_migration[(bg_reserved_migration['dst'] == 2) | (bg_reserved_migration['dst'] == 3)])}")

    print("")
    print(f"Reserved Page Promo/Mig.     : \t{len(bg[bg['reserved'] == 1])}\t"
          f"({len(bg[bg['reserved'] == 1]) / len(bg) * 100:.2f}%)")
    print(f"Demotion          : \t{len(bg[bg['type'] == 'demotion'])}\t"
          f"({len(bg[bg['type'] == 'demotion']) / len(bg) * 100:.2f}%)")
    print("")

    print("Average Fault Latency")
    print(f"Avg. for all         : \t{bg['time'].mean():.2f} us")
    print(f"Avg. all w/o demotion: \t{bg[bg['type'] != 'demotion']['time'].mean():.2f} us")
    print(f"Avg. Promotion       : \t{bg[bg['type'] == 'promotion']['time'].mean():.2f} us")
    print(f"\tAvg. Local Promo.  : {bg_promotion[bg_promotion['promotion_type'] == 2]['time'].mean():.2f} us")
    print(f"\tAvg. Remote Promo. : {bg_promotion[bg_promotion['promotion_type'] == 3]['time'].mean():.2f} us")
    print("")
    print(f"Avg. Regular Promotion       : \t{bg_regular_promotion['time'].mean():.2f} us")
    if len(bg_regular_promotion) != 0:
        print(f"\tLocal Reg. Promo. : {bg_regular_promotion[bg_regular_promotion['promotion_type'] == 2]['time'].mean():.2f} us")
        print(f"\tRemote Reg. Promo.: {bg_regular_promotion[bg_regular_promotion['promotion_type'] == 3]['time'].mean():.2f} us")
    print("")
    print(f"Avg. Rserved Promotion       : \t{bg_reserved_promotion['time'].mean():.2f} us")
    if len(bg_reserved_promotion) != 0:
        print(f"\tLocal Rsv. Promo. : {bg_reserved_promotion[bg_reserved_promotion['promotion_type'] == 2]['time'].mean():.2f} us")
        print(f"\tRemote Rsv. Promo.: {bg_reserved_promotion[bg_reserved_promotion['promotion_type'] == 3]['time'].mean():.2f} us")
    print("")
    print(f"Avg. Migration       : \t{bg_migration['time'].mean():.2f} us")
    print(f"Avg. Mig. (DRAM->DRAM): \t"
          f"{bg_migration[(bg_migration['dst'] == 0) | (bg_migration['dst'] == 1)]['time'].mean():.2f} us")
    print(f"Avg. Mig. (DCPMM->DCPMM): \t"
          f"{bg_migration[(bg_migration['dst'] == 2) | (bg_migration['dst'] == 3)]['time'].mean():.2f} us")
    print("")
    print(f"Avg. Regular Migration: \t{bg_regular_migration['time'].mean():.2f} us")
    if len(bg_regular_migration) != 0:
        print(f"Regular Mig.   (DRAM->DRAM): \t"
              f"{bg_regular_migration[(bg_regular_migration['dst'] == 0) | (bg_regular_migration['dst'] == 1)]['time'].mean():.2f}")
        print(f"Regular Mig. (DCPMM->DCPMM): \t"
              f"{bg_regular_migration[(bg_regular_migration['dst'] == 2) | (bg_regular_migration['dst'] == 3)]['time'].mean():.2f}")
    print("")
    print(f"Avg. Reserved Migration       : \t{bg_reserved_migration['time'].mean():.2f} us")
    if len(bg_reserved_migration) != 0:
        print(f"Reserved Mig.   (DRAM->DRAM): \t"
              f"{bg_reserved_migration[(bg_reserved_migration['dst'] == 0) | (bg_reserved_migration['dst'] == 1)]['time'].mean():.2f}")
        print(f"Reserved Mig. (DCPMM->DCPMM): \t"
              f"{bg_reserved_migration[(bg_reserved_migration['dst'] == 2) | (bg_reserved_migration['dst'] == 3)]['time'].mean():.2f}")
    print("")
    print(f"Avg. Reserved Page Promo/Mig. Latency: \t{bg[bg['reserved'] == 1]['time'].mean():.2f} us")
    print(f"Avg. Demotion        : \t{bg[bg['type'] == 'demotion']['time'].mean():.2f} us")
    print("")

    print("Misc.")
    print(f"Outliers (>= {Latency.BOUND} us): \t"
          f"{len(bg_outliers) / len(BG_DATA) * 100:.2f} %")
    print(f"Avg. # of Batch: \t"
          f"{bg[bg['type'] == 'demotion']['batch'].mean():.2f}")
    print("")

    print("OPMX")
    print("Proportion of fault types")
    fg_promotion = fg[fg["type"] == "promotion"]
    print(f"Promotion         : \t{len(fg[fg['type'] == 'promotion'])}\t"
          f"({len(fg[fg['type'] == 'promotion']) / len(fg) * 100:.2f}%)")
    if len(fg_promotion) != 0:
        print(f"\tLocal Promo. : {len(fg_promotion[fg_promotion['promotion_type'] == 2]) / len(fg_promotion) * 100:.2f}%")
        print(f"\tRemote Promo.: {len(fg_promotion[fg_promotion['promotion_type'] == 3]) / len(fg_promotion) * 100:.2f}%")

    # fg_regular_promotion = fg_promotion[fg_promotion["reserved"] == 0]
    # print(f"Regular Promotion  : \t{len(fg_regular_promotion)}\t"
    #       f"({len(fg_regular_promotion) / len(fg) * 100:.2f}%)")
    # if len(fg_regular_promotion) != 0:
    #     print(f"\tLocal Reg. Promo. : {len(fg_regular_promotion[fg_regular_promotion['promotion_type'] == 2]) / len(fg_regular_promotion) * 100:.2f}%")
    #     print(f"\tRemote Reg. Promo.: {len(fg_regular_promotion[fg_regular_promotion['promotion_type'] == 3]) / len(fg_regular_promotion) * 100:.2f}%")

    # fg_reserved_promotion = fg_promotion[fg_promotion["reserved"] == 1]
    # print(f"Reserved Page Promotion  : \t{len(fg_reserved_promotion)}\t"
    #       f"({len(fg_reserved_promotion) / len(fg) * 100:.2f}%)")
    # if len(fg_reserved_promotion) != 0:
    #     print(f"\tLocal Rsv. Promo. : {len(fg_reserved_promotion[fg_reserved_promotion['promotion_type'] == 2]) / len(fg_reserved_promotion) * 100:.2f}%")
    #     print(f"\tRemote Rsv. Promo.: {len(fg_reserved_promotion[fg_reserved_promotion['promotion_type'] == 3]) / len(fg_reserved_promotion) * 100:.2f}%")
    # print("")

    fg_migration = fg[fg['type'] == 'migration']
    print(f"Migration         : \t{len(fg_migration)}\t"
          f"({len(fg_migration) / len(fg) * 100:.2f}%)")

    print(f"Mig.   (DRAM->DRAM): \t"
          f"{len(fg_migration[(fg_migration['dst'] == 0) | (fg_migration['dst'] == 1)])}")
    print(f"Mig. (DCPMM->DCPMM): \t"
          f"{len(fg_migration[(fg_migration['dst'] == 2) | (fg_migration['dst'] == 3)])}")

    # fg_regular_migration = fg_migration[fg_migration["reserved"] == 0]
    # print(f"Regular Migration  : \t{len(fg_regular_migration)}\t"
    #       f"({len(fg_regular_migration) / len(fg) * 100:.2f}%)")

    # fg_reserved_migration = fg_migration[fg_migration["reserved"] == 1]
    # print(f"Reserved Page Migration  : \t{len(fg_reserved_migration)}\t"
    #       f"({len(fg_reserved_migration) / len(fg) * 100:.2f}%)")

    print("")

    print(f"Reserved Page Promo/Mig.     : \t{len(fg[fg['reserved'] == 1])}\t"
          f"({len(fg[fg['reserved'] == 1]) / len(fg) * 100:.2f}%)")

    print(f"On-demand Exchange: \t{len(fg[fg['type'] == 'ondemand_exchange'])}\t"
          f"({len(fg[fg['type'] == 'ondemand_exchange']) / len(fg) * 100:.2f}%)")

    print("")

    print("Average Fault Latency")
    print(f"Avg. for all         : \t{fg['time'].mean():.2f} us")
    print(f"Avg. Promotion       : \t{fg[fg['type'] == 'promotion']['time'].mean():.2f} us")
    print(f"\tAvg. Local Promo.  : {fg_promotion[fg_promotion['promotion_type'] == 2]['time'].mean():.2f} us")
    print(f"\tAvg. Remote Promo. : {fg_promotion[fg_promotion['promotion_type'] == 3]['time'].mean():.2f} us")
    # print(f"Avg. Regular Promotion       : \t{fg_regular_promotion['time'].mean():.2f} us")
    # print(f"Avg. Rserved Promotion       : \t{fg_reserved_promotion['time'].mean():.2f} us")
    print("")
    print(f"Avg. Migration       : \t{fg_migration['time'].mean():.2f} us")
    print(f"Avg. Mig. (DRAM->DRAM): \t"
          f"{fg_migration[(fg_migration['dst'] == 0) | (fg_migration['dst'] == 1)]['time'].mean():.2f} us")
    print(f"Avg. Mig. (DCPMM->DCPMM): \t"
          f"{fg_migration[(fg_migration['dst'] == 2) | (fg_migration['dst'] == 3)]['time'].mean():.2f} us")
    # print(f"Avg. Regular Migration: \t{fg_regular_migration['time'].mean():.2f} us")
    # print(f"Avg. Rserved Migration: \t{fg_reserved_migration['time'].mean():.2f} us")
    print("")
    # print(f"Avg. Reserved Page Promo/Mig. Latency: \t{fg[fg['reserved'] == 1]['time'].mean():.2f} us")
    print(f"Avg. On-Demand       : \t{fg[fg['type'] == 'ondemand_exchange']['time'].mean():.2f} us")
    print("")

    print("Misc.")
    print(f"Outliers (>= {Latency.BOUND} us): \t"
          f"{len(fg_outliers) / len(FG_DATA) * 100:.2f} %")
    print("")
    print("------------------------------------------------------------------")


def calc_cdf(data):
    data = data.sort_values()
    # data[len(data)] = data.iloc[-1]
    cum_dist = np.linspace(0, 100, len(data))
    return pd.Series(cum_dist, index=data)


def plot(latency, FG_DATA, BG_DATA):
    bg_df = BG_DATA.loc[BG_DATA["type"] != "demotion", "time"]
    # bg_df = BG_DATA.loc[BG_DATA["type"] == "promotion", "time"]
    bg_df = bg_df[bg_df < Latency.BOUND]  # outlier
    # fg_df = FG_DATA.loc[FG_DATA["type"] != "migration", "time"]
    fg_df = FG_DATA["time"]
    fg_df = fg_df[fg_df < Latency.BOUND]  # outlier

    bg_cdf = calc_cdf(bg_df)
    fg_cdf = calc_cdf(fg_df)

    bg_cdf.plot(drawstyle='steps', label="OPM (BD)",
                color="firebrick")
    fg_cdf.plot(drawstyle='steps', linestyle="dotted", label="OPMX",
                color="firebrick")

    fig = plt.gcf()
    fig.set_size_inches(5, 4)
    plt.legend()
    plt.title(f"{latency.BENCH_NAME.capitalize()} (ALL w/o demotion)")
    plt.xlabel("Fault Latency (us)")
    plt.ylabel("CDF-Number of Page faults(%)")
    plt.savefig(f"{PLOT_DIR}/{latency.BENCH_NAME}/{latency.CASE_LIST[0]}_{latency.CASE_LIST[1]}_fault_latency.pdf")


def partial_plot(latency, FG_DATA, BG_DATA, PERF_DF):
    bg_df = BG_DATA.loc[BG_DATA["reserved"] == 1, "time"]
    bg_df = bg_df[bg_df < Latency.BOUND]  # outlier
    fg_df = FG_DATA.loc[FG_DATA["type"] == "ondemand_exchange", "time"]
    fg_df = fg_df[fg_df < Latency.BOUND]  # outlier

    bg_cdf = calc_cdf(bg_df)
    fg_cdf = calc_cdf(fg_df)

    bg_cdf.plot(drawstyle='steps', label="OPM (BD)",
                color="#273746")
    fg_cdf.plot(drawstyle='steps', linestyle="dashed", label="OPMX",
                color="#273746")

    plt.legend(loc="lower right", edgecolor='k')
    plt.title(f"{latency.BENCH_NAME.capitalize()}", fontsize=13)
    plt.xlabel("Latency (us)", fontsize=13)
    plt.ylabel("CDF - promotion / exchange (%)", fontsize=13)

    # Plotting cycle graph
    APMX_USER_CYCLES_PERCENT = PERF_DF["user_cycles"][0] / (PERF_DF["user_cycles"][0] + PERF_DF["kernel_cycles"][0]) * 100
    APMX_KERN_CYCLES_PERCENT = PERF_DF["kernel_cycles"][0] / (PERF_DF["user_cycles"][0] + PERF_DF["kernel_cycles"][0]) * 100
    APMBD_USER_CYCLES_PERCENT = PERF_DF["user_cycles"][1] / (PERF_DF["user_cycles"][1] + PERF_DF["kernel_cycles"][1]) * 100
    APMBD_KERN_CYCLES_PERCENT = PERF_DF["kernel_cycles"][1] / (PERF_DF["user_cycles"][1] + PERF_DF["kernel_cycles"][1]) * 100
    fig = plt.gcf()
    cycle_ax = fig.add_axes([0.62, 0.33, 0.25, 0.3])
    cycle_ax.set_xticks([0, 0.3])
    cycle_ax.set_xticklabels(["OPMX", "OPM (BD)"])
    cycle_ax.bar([0, 0.3],
                 [APMX_USER_CYCLES_PERCENT, APMBD_USER_CYCLES_PERCENT], 0.2,
                 color="#AEB6BF", label="User", edgecolor="k")
    cycle_ax.bar([0, 0.3],
                 [APMX_KERN_CYCLES_PERCENT, APMBD_KERN_CYCLES_PERCENT], 0.2,
                 bottom=[APMX_USER_CYCLES_PERCENT, APMBD_USER_CYCLES_PERCENT],
                 color="#34495E", label="Kernel", edgecolor="k")
    cycle_ax.legend(bbox_to_anchor=(0, 1.02, 1, 0.2), loc="lower left",
                    mode="expand", borderaxespad=0, frameon=False, ncol=2,
                    handlelength=0.8, edgecolor="k", fontsize="9")

    fig.set_size_inches(5, 4)
    plt.savefig(f"{PLOT_DIR}/{latency.BENCH_NAME}_fault_latency_partial.pdf")


def read(latency, PATH):
    FILE = latency.FULL_PATH[PATH] + "/lat.tmp"
    results = {
        "type": [],
        "src": [],
        "dst": [],
        "time": [],
        "cycle": [],
        "batch": [],
        "promotion_type": [],
        "reserved": [],
    }

    with open(FILE, "r") as fp:
        data = [x.strip().split(" ") for x in fp.readlines()]

    for line in data:
        results["type"].append(line[0])
        results["src"].append(int(line[1]))
        results["dst"].append(int(line[2]))
        time = (float(line[3])) / (2.3e+09) * 1.0e+06
        results["time"].append(time)
        results["cycle"].append(int(line[3]))

        try:
            results["batch"].append(int(line[4]))
        except IndexError:
            results["batch"].append(-1)

        try:
            results["promotion_type"].append(int(line[5]))
        except IndexError:
            results["promotion_type"].append(-1)

        try:
            results["reserved"].append(int(line[6]))
        except IndexError:
            results["reserved"].append(-1)

    results = pd.DataFrame(results)

    return results


def read_perf(PATH, dic):
    FILE = PATH + "/perf.log"

    with open(FILE, "r") as fp:
        data = [x.strip().split(" ") for x in fp.readlines()]
        dic["user_cycles"].append(int(data[2][0].split(",")[0]))
        dic["kernel_cycles"].append(int(data[3][0].split(",")[0]))


def filter(latency):
    subprocess.run(f"./filter-latdata.sh {latency.BENCH_NAME} "
                   f"{latency.FULL_PATH[0]} 0",
                   shell=True, universal_newlines=True)
    subprocess.run(f"./filter-latdata.sh {latency.BENCH_NAME} {latency.FULL_PATH[1]} 1",
                   shell=True, universal_newlines=True)


def parse():
    global _LOG_DIR
    parser = argparse.ArgumentParser()
    parser.add_argument("-b", "--benchmark", type=str, nargs=1,
                        help="Select benchmark to draw graph")
    parser.add_argument("-d", "--date", type=str, nargs=2,
                        help="Choose a time for benchmarks to graph")
    parser.add_argument("-p", "--perf", type=str, nargs=2,
                        help="Choose a time for benchmarks' perf log")

    args = parser.parse_args()

    if args.benchmark:
        if len(args.benchmark) != 1:
            print("Only 1 Args available: [Benchmark Name]")
            sys.exit()
        BENCH_NAME = args.benchmark[0]
        LOG_DIR = _LOG_DIR + "/" + BENCH_NAME

        if args.date:
            if len(args.date) != 2:
                print("Only 2 Args available: [FG Date] [BG Date]")
                sys.exit()
    else:
        print("Help: {} -h".format(sys.argv[0]))
        sys.exit()

    CASE_LIST = []
    for date in args.date:
        temp = subprocess.check_output(
            "ls " + LOG_DIR + " | grep {} | grep -v log".format(date),
            shell=True, universal_newlines=True)
        temp = temp.strip().split("\n")
        CASE_LIST.append(temp[0])

    PERF_LIST = []
    #for perf in args.perf:
    #    temp = subprocess.check_output(
    #        "ls " + LOG_DIR + " | grep {} | grep -v log".format(perf),
    #        shell=True, universal_newlines=True)
    #    temp = temp.strip().split("\n")
    #    PERF_LIST.append(temp[0])

    return BENCH_NAME, LOG_DIR, CASE_LIST, PERF_LIST


def main():
    global LOG_DIR
    BENCH_NAME, LOG_DIR, CASE_LIST, PERF_LIST = parse()

    latency = Latency(BENCH_NAME, LOG_DIR, CASE_LIST, PERF_LIST)
    filter(latency)  # if lat.tmp is not created, this function is needed.
    FG_DATA = read(latency, 0)
    BG_DATA = read(latency, 1)

    if len(PERF_LIST) > 0:
        PERF_DATA = {"user_cycles": [], "kernel_cycles": []}
        read_perf(latency.PERF_PATH[0], PERF_DATA)
        read_perf(latency.PERF_PATH[1], PERF_DATA)
        perf_df = pd.DataFrame(PERF_DATA)
    analyze(latency, FG_DATA, BG_DATA)
    plot(latency, FG_DATA, BG_DATA)
    plt.clf()
    #partial_plot(latency, FG_DATA, BG_DATA, perf_df)


if __name__ == "__main__":
    main()
