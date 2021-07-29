#!/usr/bin/python3

import sys
import csv
import matplotlib.pyplot as plt
import argparse
import subprocess
import numpy as np
import monitor

PLOT_DIR= monitor._PLOT_DIR

class Migration(monitor._Monitor):
    def __init__(self, name):
        super().__init__(name)
        self.promote_local = {"Node 0": [], "Node 1": [], "Node 2": [], "Node 3": []}
        self.promote_remote = {"Node 0": [], "Node 1": [], "Node 2": [], "Node 3": []}
        self.demote = {"Node 0": [], "Node 1": [], "Node 2": [], "Node 3": []}
        self.migrate = {"Node 0": [], "Node 1": [], "Node 2": [], "Node 3": []}
        self.pgmigrate = []
        self.pgmigrate_twice = []
        self.pgexchange_success = []
        self.pgexchange_fail = []
        self.pgactivate_deferred = []
        self.pgactivate_deferred_local = []
        self.pgrepromote = []
        self.pgpromote_lowfreq_fail = []

        self.LP_total = 0
        self.RP_total = 0
        self.MIG_total = 0
        self.SP_total = 0 # Slow prefetch(Optane to Optane migration)
        self.DE_total = 0
        self.ONCE_total = 0
        self.TWICE_total = 0
        self.EXCH_SUCCESS_total = 0
        self.EXCH_FAIL_total = 0
        self.ACTIVATE_total = 0
        self.ACTIVATE_LOCAL_total = 0
        self.REPROMOTE_total = 0
        self.PROMOTE_LOWFREQ_FAIL = 0

        self.event = ""

    def add_promote_local(self, node, data):
        if self.check_node(node) == -1:
            return
        self.promote_local["Node {}".format(node)].append(data)

    def add_promote_remote(self, node, data):
        if self.check_node(node) == -1:
            return
        self.promote_remote["Node {}".format(node)].append(data)

    def add_demote(self, node, data):
        if self.check_node(node) == -1:
            return
        self.demote["Node {}".format(node)].append(data)

    def add_migrate(self, node, data):
        if self.check_node(node) == -1:
            return
        self.migrate["Node {}".format(node)].append(data)

    def add_pgmigrate(self, data):
        self.pgmigrate.append(data)

    def add_pgmigrate_twice(self, data):
        self.pgmigrate_twice.append(data)

    def add_pgexchange_success(self, data):
        self.pgexchange_success.append(data)

    def add_pgexchange_fail(self, data):
        self.pgexchange_fail.append(data)

    def add_pgactivate_deferred(self, data):
        self.pgactivate_deferred.append(data)

    def add_pgactivate_deferred_local(self, data):
        self.pgactivate_deferred_local.append(data)

    def add_pgrepromote(self, data):
        self.pgrepromote.append(data)

    def add_pgpromote_lowfreq_fail(self, data):
        self.pgpromote_lowfreq_fail.append(data)


    def set_promote_local(self, node, data):
        if self.check_node(node) == -1:
            return
        self.promote_local["Node {}".format(node)] = data

    def set_promote_remote(self, node, data):
        if self.check_node(node) == -1:
            return
        self.promote_remote["Node {}".format(node)] = data

    def set_demote(self, node, data):
        if self.check_node(node) == -1:
            return
        self.demote["Node {}".format(node)] = data

    def set_migrate(self, node, data):
        if self.check_node(node) == -1:
            return
        self.migrate["Node {}".format(node)] = data

    def get_promote_local(self, node):
        if self.check_node(node) == -1:
            return
        return self.promote_local["Node {}".format(node)]

    def get_promote_remote(self, node):
        if self.check_node(node) == -1:
            return
        return self.promote_remote["Node {}".format(node)]

    def get_demote(self, node):
        if self.check_node(node) == -1:
            return
        return self.demote["Node {}".format(node)]

    def get_migrate(self, node):
        if self.check_node(node) == -1:
            return
        return self.migrate["Node {}".format(node)]

    def get_pgmigrate(self):
        return self.pgmigrate

    def get_pgmigrate_twice(self):
        return self.pgmigrate_twice

    def get_pgexchange_success(self):
        return self.pgexchange_success

    def get_pgexchange_fail(self):
        return self.pgexchange_fail

    def get_pgactivate_deferred(self):
        return self.pgactivate_deferred

    def get_pgactivate_deferred_local(self):
        return self.pgactivate_deferred_local

    def get_pgrepromote(self):
        return self.pgrepromote

    def get_pgpromote_lowfreq_fail(self):
        return self.pgpromote_lowfreq_fail

    def get_event(self):
        return self.event


    def cal_promote_local_total(self, nodes):
        for node in nodes:
            if self.check_node(node) == -1:
                return
            if self.get_promote_local(node) == []:
                return
            self.LP_total = self.LP_total + float(self.get_promote_local(node)[-1])

    def cal_promote_remote_total(self, nodes):
        for node in nodes:
            if self.check_node(node) == -1:
                return
            if self.get_promote_remote(node) == []:
                return
            self.RP_total = self.RP_total + float(self.get_promote_remote(node)[-1])

    def cal_migrate_total(self, nodes):
        for node in nodes:
            if self.check_node(node) == -1:
                return
            if self.get_migrate(node) == []:
                return
            self.MIG_total = self.MIG_total + float(self.get_migrate(node)[-1])

    def cal_slow_prefetch_total(self, nodes):
        for node in nodes:
            if self.check_node(node) == -1:
                return
            if self.get_migrate(node) == []:
                return
            self.SP_total = self.SP_total + float(self.get_migrate(node)[-1])

    def cal_demote_total(self, nodes):
        for node in nodes:
            if self.check_node(node) == -1:
                return
            if self.get_demote(node) == []:
                return
            self.DE_total = self.DE_total + float(self.get_demote(node)[-1])

    def cal_pgmigrate_total(self):
        if self.get_pgmigrate() == []:
            return
        self.ONCE_total = float(self.get_pgmigrate()[-1])

    def cal_pgmigrate_twice_total(self):
        if self.get_pgmigrate_twice() == []:
            return
        self.TWICE_total = float(self.get_pgmigrate_twice()[-1])

    def cal_pgexchange_success_total(self):
        if self.get_pgexchange_success() == []:
            return
        self.EXCH_SUCCESS_total = float(self.get_pgexchange_success()[-1])

    def cal_pgexchange_fail_total(self):
        if self.get_pgexchange_fail() == []:
            return
        self.EXCH_FAIL_total = float(self.get_pgexchange_fail()[-1])

    def cal_pgactivate_deferred_total(self):
        total = self.get_pgactivate_deferred()
        if total == [] or "pgactivate" in total[-1]:
            return
        self.ACTIVATE_total = float(total[-1])

    def cal_pgactivate_deferred_local_total(self):
        total = self.get_pgactivate_deferred_local()
        if total == [] or "pgactivate" in total[-1]:
            return
        self.ACTIVATE_LOCAL_total = float(total[-1])

    def cal_pgrepromote_total(self):
        total = self.get_pgrepromote()
        if total == [] or "pgrepromote" in total[-1]:
            return
        self.REPROMOTE_total = float(total[-1])

    def cal_pgpromote_lowfreq_fail_total(self):
        total = self.get_pgpromote_lowfreq_fail()
        if total == [] or "pgpromote_low_freq_fail" in total[-1]:
            return
        self.PGPROMOTE_LOWFREQ_FAIL = float(total[-1])


    def get_promote_local_total(self):
        return self.LP_total

    def get_promote_remote_total(self):
        return self.RP_total

    def get_migrate_total(self):
        return self.MIG_total

    def get_slow_prefetch_total(self):
        return self.SP_total

    def get_demote_total(self):
        return self.DE_total

    def get_pgmigrate_total(self):
        return self.ONCE_total

    def get_pgmigrate_twice_total(self):
        return self.TWICE_total

    def get_pgexchange_success_total(self):
        return self.EXCH_SUCCESS_total

    def get_pgexchange_fail_total(self):
        return self.EXCH_FAIL_total

    def get_pgactivate_deferred_total(self):
        return self.ACTIVATE_total

    def get_pgactivate_deferred_local_total(self):
        return self.ACTIVATE_LOCAL_total

    def get_pgrepromote_total(self):
        return self.REPROMOTE_total

    def get_pgpromote_lowfreq_fail_total(self):
        return self.PROMOTE_LOWFREQ_FAIL

    def read(self, log_dir):
        test_name = self.get_test_name()
        event = self.get_event()

        for migration_stat in ["promote_local", "promote_remote", "demote", "migrate"]:

            # Skip demote when reading fail stat
            if migration_stat == "demote" and event != "":
                continue

            filename = "{}/{}/iter-1/migration-stat-hmem_{}{}_src".format(log_dir, test_name, migration_stat, event)
            with open(filename, newline='') as csv_file:
                line = csv.reader(csv_file, delimiter=' ')
                for entry in line:
                    self.set_num_nodes(len(entry))
                    for node in range(len(entry)):
                        value = entry[node]
                        if migration_stat == "promote_local":
                            self.add_promote_local(node, value)
                        elif migration_stat == "promote_remote":
                            self.add_promote_remote(node, value)
                        elif migration_stat == "demote":
                            self.add_demote(node, value)
                        elif migration_stat == "migrate":
                            self.add_migrate(node, value)
                        else:
                            print("ERROR: migration_stat must be one of 'promote_local', 'promote_remote' 'migrate' and 'demote'")
                            return -1

        PGMIGRATE = 0
        PGMIGRATE_TWICE = 1
        filename = "{}/{}/iter-1/migration-stat-pgmigrate".format(log_dir, test_name)
        with open(filename, newline='') as csv_file:
            line = csv.reader(csv_file, delimiter=' ')
            for entry in line:
                for stat in range(len(entry)):
                    value = entry[stat]
                    if stat == PGMIGRATE:
                        self.add_pgmigrate(value)
                    if stat == PGMIGRATE_TWICE:
                        self.add_pgmigrate_twice(value)

        PGEXCHANGE_SUCCESS= 0
        PGEXCHANGE_FAIL= 1
        filename = "{}/{}/iter-1/migration-stat-pgexchange".format(log_dir, test_name)
        with open(filename, newline='') as csv_file:
            line = csv.reader(csv_file, delimiter=' ')
            for entry in line:
                for stat in range(len(entry)):
                    value = entry[stat]
                    if stat == PGEXCHANGE_SUCCESS:
                        self.add_pgexchange_success(value)
                    if stat == PGEXCHANGE_FAIL:
                        self.add_pgexchange_fail(value)

        PGACTIVATE= 0
        PGACTIVATE_LOCAL= 1
        filename = "{}/{}/iter-1/migration-stat-pgactivate".format(log_dir, test_name)
        with open(filename, newline='') as csv_file:
            line = csv.reader(csv_file, delimiter=' ')
            for entry in line:
                for stat in range(len(entry)):
                    value = entry[stat]
                    if stat == PGACTIVATE:
                        self.add_pgactivate_deferred(value)
                    if stat == PGACTIVATE_LOCAL:
                        self.add_pgactivate_deferred_local(value)

        PGREPROMOTE= 0
        filename = "{}/{}/iter-1/migration-stat-repromote".format(log_dir, test_name)
        with open(filename, newline='') as csv_file:
            line = csv.reader(csv_file, delimiter=' ')
            for entry in line:
                for stat in range(len(entry)):
                    value = entry[stat]
                    if stat == PGREPROMOTE:
                        self.add_pgrepromote(value)

        PGPROMOTE_LOWFREQ_FAIL= 0
        filename = "{}/{}/iter-1/migration-stat-lowfreq_fail".format(log_dir, test_name)
        with open(filename, newline='') as csv_file:
            line = csv.reader(csv_file, delimiter=' ')
            for entry in line:
                for stat in range(len(entry)):
                    value = entry[stat]
                    if stat == PGPROMOTE_LOWFREQ_FAIL:
                        self.add_pgpromote_lowfreq_fail(value)

        return 0


def plot(bench_name, stats):
    global PLOT_DIR
    NODES = [0, 1, 2, 3]
    PROMOTE_LOCAL, PROMOTE_REMOTE, MIGRATE, DEMOTE = migration_stats = list(range(0, 4))
    DATE = stats[0].get_date()

    fig, ax = plt.subplots(nrows=4, ncols=len(stats),
            sharex='col', sharey='row')
    fig.suptitle("{}, migration-stat".format(bench_name))

    colors = ["maroon", "darkorange",
            "green", "darkcyan",
            "slategrey", "indigo",
            "dimgray", "silver",
            "steelblue", "cadetblue",
            "royalblue","springgreen",
            "black"
            ]

    max_order = len(stats) - 1
    for mstat in stats:
        order = mstat.get_order()
        title = mstat.get_label()

        if max_order != 0:
            ax_promote_local = ax[PROMOTE_LOCAL, order]
            ax_promote_remote = ax[PROMOTE_REMOTE, order]
            ax_migrate = ax[MIGRATE, order]
            ax_demote = ax[DEMOTE, order]
        else:
            ax_promote_local = ax[PROMOTE_LOCAL]
            ax_promote_remote = ax[PROMOTE_REMOTE]
            ax_migrate = ax[MIGRATE]
            ax_demote = ax[DEMOTE]

        ax_promote_local.set_title("Local Promote, {}".format(title))
        ax_promote_remote.set_title("Remote Promote,{}".format(title))
        ax_migrate.set_title("Migrate, {}".format(title))
        ax_demote.set_title("Demote, {}".format(title))

        for migration_stat in migration_stats:
            if max_order != 0:
                ax_migration_stat = ax[migration_stat, order]
            else:
                ax_migration_stat = ax[migration_stat]

            y = []
            for node in NODES:
                if node > mstat.get_num_nodes() - 1:
                    continue
                if migration_stat == PROMOTE_LOCAL:
                    mem = mstat.get_promote_local(node)
                    label = mem.pop(0)
                    mem = list(map(float, mem))
                    mem = [val/1000 for val in mem] # Kilo migration count
                elif migration_stat == PROMOTE_REMOTE:
                    mem = mstat.get_promote_remote(node)
                    label = mem.pop(0)
                    mem = list(map(float, mem))
                    mem = [val/1000 for val in mem] # Kilo migration count
                elif migration_stat == DEMOTE:
                    mem = mstat.get_demote(node)
                    label = mem.pop(0)
                    mem = list(map(float, mem))
                    mem = [val/1000 for val in mem] # Kilo migration count
                elif migration_stat == MIGRATE:
                    mem = mstat.get_migrate(node)
                    label = mem.pop(0)
                    mem = list(map(float, mem))
                    mem = [val/1000 for val in mem] # Kilo migration count
                else:
                    print("ERROR: This migration stat was not supported")
                    return -1

                ax_migration_stat.plot([], label=label, color=colors[node])
                ax_migration_stat.legend()
                ax_migration_stat.set_xlabel("Time(s)")
                ax_migration_stat.set_ylabel("Kilo Migration")
                y.append(mem)

            x = list(range(len(y[0])))
            y_stack = np.vstack(y)
            ax_migration_stat.stackplot(x, y_stack, colors=colors)


    plt.subplots_adjust(top=0.95, bottom=0.05, right=0.95, left=0.05)
    fig.set_size_inches(20, 15)

    plt.savefig(PLOT_DIR + "/{0}/{1}-{0}-migration-stat.png".format(bench_name, DATE), format='png')
    # plt.show()
    plt.close(fig)

    # Plot total stats
    fig, total = plt.subplots()

    x_labels = [ mstat.get_label() for mstat in stats]
    y_labels = ["Local Optane to Local DRAM", "Remote Optane to Local DRAM",
            "DRAM to DRAM", "Optane to Optane", "DEMOTE",
            "Total Migration/promotion/demotion"]

    for mstat in stats:
        num_nodes = mstat.get_num_nodes()
        NODES = list(range(num_nodes))
        mstat.cal_promote_local_total(NODES)
        mstat.cal_promote_remote_total(NODES)
        mstat.cal_demote_total(NODES)
        mstat.cal_migrate_total(NODES[0:2])
        if num_nodes > 2:
            mstat.cal_slow_prefetch_total(NODES[2:4])
        mstat.cal_pgmigrate_total()
        mstat.cal_pgmigrate_twice_total()
        mstat.cal_pgexchange_success_total()
        mstat.cal_pgexchange_fail_total()
        mstat.cal_pgactivate_deferred_total()
        mstat.cal_pgactivate_deferred_local_total()
        mstat.cal_pgrepromote_total()
        mstat.cal_pgpromote_lowfreq_fail_total()


    width = 0.1
    index = np.arange(len(stats))

    total.set_xlabel("NUMA balancing option", fontsize='x-large')
    total.set_ylabel("Kilo Migration", fontsize='x-large')
    total.set_axisbelow(True)
    total.tick_params(axis='x', labelsize='large')
    total.tick_params(axis='y', labelsize='large')
    total.grid(b=True, linestyle='solid', axis='y')

    for mstat in stats:
        idx = stats.index(mstat)
        t1 = mstat.get_promote_local_total()/1000
        t2 = mstat.get_promote_remote_total()/1000
        t3 = mstat.get_migrate_total()/1000
        t4 = mstat.get_slow_prefetch_total()/1000
        t5 = (mstat.get_pgmigrate_total() - mstat.get_pgmigrate_twice_total())/1000
        t6 = mstat.get_pgmigrate_twice_total()/1000
        t7 = mstat.get_pgexchange_success_total()/1000
        t8 = mstat.get_pgexchange_fail_total()/1000
        t9 = mstat.get_pgactivate_deferred_total()/1000
        t10 = mstat.get_pgactivate_deferred_local_total()/1000
        t11 = mstat.get_demote_total()/1000
        t12 = mstat.get_pgrepromote_total()/1000
        t13 = mstat.get_pgpromote_lowfreq_fail_total()/1000

        # promote local, remote
        a, = total.bar(index[idx]-width*3.00, t1, width=width, edgecolor='black',
                color=colors[0])
        b, = total.bar(index[idx]-width*3.00, t2, width=width, edgecolor='black',
                color=colors[1], bottom=t1)

        # migration dram-dram, dcpmm-dcpmm
        c, = total.bar(index[idx]-width*3.00, t3, width=width, edgecolor='black',
                color=colors[2], bottom=t1+t2)
        d, = total.bar(index[idx]-width*3.00, t4, width=width, edgecolor='black',
                color=colors[3], bottom=t1+t2+t3)

        # pgmigrate, twice
        f, = total.bar(index[idx]-width*2.00, t5, width=width, edgecolor='black',
                color=colors[4])

        # demote
        e, = total.bar(index[idx]-width*3.00, t11, width=width, edgecolor='black',
                color=colors[10], bottom=t1+t2+t3+t4)



    a.set_label(y_labels[0])
    b.set_label(y_labels[1])
    c.set_label(y_labels[2])
    d.set_label(y_labels[3])
    e.set_label(y_labels[4])
    f.set_label(y_labels[5])

    total.set_xticks(index)
    total.set_xticklabels(x_labels, rotation=45)
    total.set_title("{}: Migration".format(bench_name))

    leg_h, leg_l = total.get_legend_handles_labels()
    plt.legend(leg_h, leg_l,  loc="upper right",
                bbox_transform=fig.transFigure, ncol=2, edgecolor='black',
                fontsize='large', columnspacing=0.3, handletextpad=0.1)
                ##bbox_to_anchor=(0.96, 0.9)

    plt.subplots_adjust(top=0.90, bottom=0.15, right=0.95, left=0.12)
    fig.set_size_inches(15, 10)

    plt.savefig(PLOT_DIR + "/{0}/{1}-{0}-migration-stat-total.png".format(bench_name, DATE),
            format="png")
    # plt.show()
    plt.close(fig)


def main():
    global LOG_DIR
    s_name = sys.argv[0]
    BENCH_NAME, LOG_DIR, CASE_LIST = monitor.parse()

    migration = [Migration(case) for case in CASE_LIST]

    for m in migration:
        if m.read(LOG_DIR) == -1:
            print("ERROR: File read error")
            return -1

    plot(BENCH_NAME, migration)

    print("Done! : {}".format(s_name))


if __name__ == '__main__':
    main()
