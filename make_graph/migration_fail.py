#!/usr/bin/python3

import sys
import csv
import matplotlib.pyplot as plt
import argparse
import subprocess
import numpy as np
import monitor
import migration_stat

PLOT_DIR= monitor._PLOT_DIR

class MigrationFail(migration_stat.Migration):
    def __init__(self, name):
        super().__init__(name)
        self.event = "_fail"


def plot(bench_name, stats):
    global PLOT_DIR
    DATE = stats[0].get_date()
    NODES = [0, 1, 2, 3]
    PROMOTE_LOCAL, PROMOTE_REMOTE, MIGRATE = migration_stats = list(range(0, 3))

    fig, ax = plt.subplots(nrows=3, ncols=len(stats),
            sharex='col', sharey='row')
    fig.suptitle("{}, migration-fail".format(bench_name))

    colors = ["maroon", "darkorange", "green", "darkcyan", "royalblue"]

    max_order = len(stats) - 1
    for m in stats:
        order = m.get_order()
        title = m.get_label()
        if max_order != 0:
            ax_promote_local = ax[PROMOTE_LOCAL, order]
            ax_promote_remote = ax[PROMOTE_REMOTE, order]
            ax_migrate = ax[MIGRATE, order]
        else:
            ax_promote_local = ax[PROMOTE_LOCAL]
            ax_promote_remote = ax[PROMOTE_REMOTE]
            ax_migrate = ax[MIGRATE]

        ax_promote_local.set_title("LP_fail, {}".format(title))
        ax_promote_remote.set_title("RP_fail, {}".format(title))
        ax_migrate.set_title("Migrate_fail, {}".format(title))

        for migration_stat in migration_stats:
            if max_order != 0:
                ax_migration_stat = ax[migration_stat, order]
            else:
                ax_migration_stat = ax[migration_stat]
            y = []
            for node in NODES:
                if node > m.get_num_nodes() - 1:
                    continue
                if migration_stat == PROMOTE_LOCAL:
                    mem = m.get_promote_local(node)
                    label = mem.pop(0)
                    mem = list(map(float, mem))
                    mem = [val/1000 for val in mem] # Kilo migration count
                elif migration_stat == PROMOTE_REMOTE:
                    mem = m.get_promote_remote(node)
                    label = mem.pop(0)
                    mem = list(map(float, mem))
                    mem = [val/1000 for val in mem] # Kilo migration count
                elif migration_stat == MIGRATE:
                    mem = m.get_migrate(node)
                    label = mem.pop(0)
                    mem = list(map(float, mem))
                    mem = [val/1000 for val in mem] # Kilo migration count
                else:
                    print("ERROR: Memory state must be either 'Active' or 'Inactive'")
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

    plt.savefig(PLOT_DIR + "/{0}/{1}-{0}-migration-fail.png".format(bench_name, DATE),
            format='png')
    # plt.show()
    plt.close()

    # Plot total stats
    fig, total = plt.subplots()

    x_labels = [ m.get_label() for m in stats]
    y_labels = ["Local Optane to Local DRAM Fail", "Remote Optane to Local DRAM Fail", "DRAM to DRAM Fail", "DEMOTE"]

    for m in stats:
        num_nodes = m.get_num_nodes()
        NODES = list(range(num_nodes))
        m.cal_promote_local_total(NODES)
        m.cal_promote_remote_total(NODES)
        m.cal_migrate_total(NODES)


    width = 0.15
    index = np.arange(len(stats))

    total.set_xlabel("NUMA balancing option", fontsize='x-large')
    total.set_ylabel("Kilo Migration", fontsize='x-large')
    total.set_axisbelow(True)
    total.tick_params(axis='x', labelsize='large')
    total.tick_params(axis='y', labelsize='large')
    total.grid(b=True, linestyle='solid', axis='y')

    #base = float(y[0])
    for m in stats:
        i = stats.index(m)
        t1 = m.get_promote_local_total()/1000
        t2 = m.get_promote_remote_total()/1000
        t3 = m.get_migrate_total()/1000


        a, = total.bar(index[i]-width*0.5, t1, width=width, edgecolor='black',
                color=colors[0])
        b, = total.bar(index[i]-width*0.5, t2, width=width, edgecolor='black',
                color=colors[1], bottom=t1)
        c, = total.bar(index[i]+width*0.5, t3, width=width, edgecolor='black',
                color=colors[2])

    a.set_label(y_labels[0])
    b.set_label(y_labels[1])
    c.set_label(y_labels[2])

    total.set_xticks(index)
    total.set_xticklabels(x_labels, rotation=45)
    total.set_title("{}: Migrate Fail".format(bench_name))

    leg_h, leg_l = total.get_legend_handles_labels()
    plt.legend(leg_h, leg_l,  loc="upper left",
                bbox_transform=fig.transFigure, ncol=1, edgecolor='black',
                fontsize='large', columnspacing=0.3, handletextpad=0.1)
                ##bbox_to_anchor=(0.96, 0.9)

    plt.subplots_adjust(top=0.95, bottom=0.15, right=0.95, left=0.12)
    fig.set_size_inches(15, 10)

    plt.savefig(PLOT_DIR + "/{0}/{1}-{0}-migration-fail-total.png".format(bench_name, DATE),
            format="png")
    #plt.show()
    plt.close(fig)

def main():
    global LOG_DIR

    s_name = sys.argv[0]
    BENCH_NAME, LOG_DIR, CASE_LIST = monitor.parse()

    migration = [MigrationFail(case) for case in CASE_LIST]

    for m in migration:
        if m.read(LOG_DIR) == -1:
            print("ERROR: File read error")
            return -1

    plot(BENCH_NAME, migration)
    print("Done! : {}".format(s_name))


if __name__ == '__main__':
    main()
