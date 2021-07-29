import argparse
import sys
import subprocess

_MMTEST_DIR="."
_PLOT_DIR= _MMTEST_DIR + "/plots"
_LOG_DIR = _MMTEST_DIR + "/logs"

class _Monitor:
    _DATE = ""
    def __init__(self, name):
        self.test_name = name
        self.order = ord(name.split("-")[1]) - ord('a')
        self.numaopt = name.split("-")[2]
        self.cpmopt = name.split("-")[3]
        self.exchopt = name.split("-")[4]
        self.opmopt = name.split("-")[5]

        options = [self.numaopt, self.cpmopt, self.exchopt, self.opmopt]
        labels = []
        #options = set(options)
        for opt in options:
            if opt not in labels:
                labels.append(opt)
        if "OFF" in labels:
            labels.remove("OFF")

        self.label = "-".join(labels)
        # For debugging
        #self.print_instance()
        self._DATE = name.split("-")[0]
        self.num_nodes = 0

    def print_instance(self):
        print("TEST_NAME:", self.test_name)
        print("LABEL:", self.label)
        print("NUMAOPT:", self.numaopt)
        print("CPMOPT:", self.cpmopt)
        print("EXCHOPT:", self.exchopt)
        print("APMOPT:", self.opmopt)
        print("ORDER:", self.order)
        print()

    def get_numaopt(self):
        return self.numaopt

    def get_cpmopt(self):
        return self.cpmopt

    def get_test_name(self):
        return self.test_name

    def get_label(self):
        return self.label

    def get_order(self):
        return self.order

    def get_date(self):
        return self._DATE

    def get_num_nodes(self):
        return self.num_nodes

    def set_num_nodes(self, num_nodes):
        self.num_nodes = num_nodes

    def check_node(self, node):
        if node < 0 or node > 3:
            print("Nodes are available in 0 to 3")
            return -1

def parse():
    global _LOG_DIR
    parser = argparse.ArgumentParser()
    parser.add_argument("-b", "--benchmark", type=str, nargs=1,
                        help="Select benchmark to draw graph")
    parser.add_argument("-d", "--date", type=str, nargs=1,
                        help="Choose a time for benchmarks to graph")

    args = parser.parse_args()

    if args.benchmark:
        if len(args.benchmark) != 1:
            print("Only 1 Args available: [Benchmark Name]")
            sys.exit()
        BENCH_NAME = args.benchmark[0]
        LOG_DIR = _LOG_DIR + "/" + BENCH_NAME

        if args.date:
            if len(args.date) != 1:
                print("Only 1 Args available: [Date]")
                sys.exit()
            DATE = args.date[0]
    else:
        print("Help: {} -h".format(sys.argv[0]))
        sys.exit()

    CASE_LIST = subprocess.check_output(
            "ls " + LOG_DIR + " | grep {}- | grep -v log".format(DATE),
            shell=True, universal_newlines=True)
    CASE_LIST = CASE_LIST.strip().split("\n")

    return BENCH_NAME, LOG_DIR, CASE_LIST
