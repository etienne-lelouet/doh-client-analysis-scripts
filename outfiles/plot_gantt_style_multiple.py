#!/usr/bin/env python3

import argparse

import matplotlib
import matplotlib.pyplot as plt
import pandas
from matplotlib.ticker import MaxNLocator, LinearLocator

def do_plot_queries(
        fig,
        ax,
        df_queries,
        df_responses,
        min_lim,
        max_lim,
        no_y_labels,
        ylim_max
):
    ax.set_xlim([min_lim, max_lim])

    if df_queries is not None:
        ax.plot(df_queries["frame.time_relative"], df_queries.index + 1)

    if df_responses is not None:
        ax.plot(df_responses["frame.time_relative"], df_responses.index + 1)

    ax.xaxis.grid(color='k', linestyle="dashed", alpha=0.4, which="both")
    ax.set_xlabel("Time (seconds)")
    ax.set_ylabel("Number of connections")
    if ylim_max != -1:
        ax.set_ylim([ax.get_ylim()[0], ylim_max])

    if no_y_labels:
        ax.axes.yaxis.set_visible(False)


def do_plot_connections(
        fig,
        ax,
        df_connections,
        try_packing,
        min_duration_sec_to_plot_a_marker,
        no_y_labels,
        linewidth
):
    print(df_connections)
    df_connections["relative_end_sec"] = \
        df_connections["relative_start_sec"] + \
        df_connections["duration_sec"]

    if not try_packing:
        df_connections.sort_values(by=["relative_start_sec"], inplace=True)

    prev_right_bound = None
    ylabels = {}
    idx = 0
    for row_idx, row in df_connections.iterrows():

        if try_packing:
            if prev_right_bound is not None:
                # we have plot something before
                if prev_right_bound < row.relative_start_sec:
                    # we can plot on the same line
                    plot_index = idx
                    prev_right_bound = row.relative_start_sec + row.duration_sec
                else:
                    # overlap between two consecutive rows
                    # we plot on another line
                    idx += 1
                    plot_index = idx
                    prev_right_bound = row.relative_start_sec + row.duration_sec
            else:
                # we are on the first line
                idx += 1
                plot_index = idx
                prev_right_bound = row.relative_start_sec + row.duration_sec

            ylabels[idx] = str(idx)
        else:
            # no packing
            ylabels[idx] = row.ip
            plot_index = idx
            idx += 1
            prev_right_bound = None

        # bar = ax.barh(
        #     plot_index,
        #     height=0.5,
        #     width=row.duration_sec,
        #     left=row.relative_start_sec,
        #     alpha=1,
        #     edgecolor="black",
        #     linewidth=linewidth
        # )

        # #  get bar color
        # color = bar.patches[0].get_facecolor()

        # for the lowest bar we plot a cross in the middle
        if row.duration_sec < min_duration_sec_to_plot_a_marker:
            ax.scatter(row.relative_start_sec + row.duration_sec /
                       2, plot_index, marker="x")
        else:
            bar = ax.barh(
                plot_index,
                height=0.5,
                width=row.duration_sec,
                left=row.relative_start_sec,
                alpha=1,
                edgecolor="black",
                linewidth=linewidth
            )

        # else:
        #     ax.text(
        #         row.relative_start_sec + row.duration_sec / 2,
        #         plot_index, str(row.num_queries),
        #         horizontalalignment="center", verticalalignment="center"
        #     )

    # set limits
    max_ = (df_connections["relative_start_sec"] +
            df_connections["duration_sec"]).max()
    min_lim, max_lim = -2, ax.get_xlim()[1]
    ax.set_xlim([min_lim, max_lim])
    ax.yaxis.set_major_locator(MaxNLocator(4, integer=True))
    # grid lines
    # ax.set_axisbelow(True)
    ax.xaxis.grid(color='k', linestyle='dashed', alpha=0.4, which='both')
    # ax.yaxis.grid(color='k', linestyle='dashed', alpha=0.4, which='both')

    # Y labels
    # ax.set_yticks(
    #     list(ylabels.keys()),
    #     labels=list(ylabels.values()),
    #     fontsize=12
    # )
    # ax.axes.yaxis.set_visible(False)

    if no_y_labels:
        ax.axes.yaxis.set_visible(False)

    return min_lim, max_lim


def do_plot(df_connections, df_queries, df_responses,
            min_duration_sec_to_plot_a_marker=1,
            try_packing=False, height_ratio=70, no_y_labels=False,
            linewidth=None, ylim_queries=-1):
    if df_queries is not None or df_responses is not None:
        fig, ax_conn = plt.subplots(1)
    else:
        fig, ax_conn = plt.subplots(1)

    min_lim, max_lim = do_plot_connections(
        fig,
        ax_conn,
        df_connections,
        try_packing,
        min_duration_sec_to_plot_a_marker,
        no_y_labels,
        linewidth
    )
    return fig


class KeyValue(argparse.Action):
    # Constructor calling
    def __call__(self, parser, namespace,
                 values, option_string=None):
        setattr(namespace, self.dest, dict())

        for value in values:
            # split it into key and value
            key, value = value.split('=')
            # assign into dictionary
            getattr(namespace, self.dest)[key] = value


def do_main():
    matplotlib.rcParams["figure.titlesize"] = "xx-large"
    matplotlib.rcParams["axes.titlesize"] = "xx-large"
    matplotlib.rcParams["axes.labelsize"] ="x-large"
    matplotlib.rcParams["xtick.labelsize"] = "large"
    matplotlib.rcParams["ytick.labelsize"] = "large"

    parser = argparse.ArgumentParser()
    parser.add_argument('input_hdfs', nargs=9, type=argparse.FileType("r"),
                        help="Input connections data")
    parser.add_argument("--output", required=True, help="Output graph")
    parser.add_argument("--min-duration-sec-to-plot-a-marker", default=3,
                        type=int, help="Minimal duration to plat a marker")
    parser.add_argument("--pack", default=False, action="store_true",
                        help="Pack non overlapped connections")
    parser.add_argument("--width", type=float, default=10.0,
                        help="fig width (inches)")
    parser.add_argument("--height", type=float, default=4.0,
                        help="fig height (inches)")
    parser.add_argument("--height-ratio", type=float, default=70,
                        choices=range(0, 100), help="Percentage of height \
                        reserved for the connections plot")
    parser.add_argument("--no-y-labels", action="store_true", default=False,
                        help="Hide y labels")
    parser.add_argument("--rc-params", nargs="+", default={}, action=KeyValue,
                        help="Tune matplotlib.rcParams")
    parser.add_argument("--barh-linewidth", type=float, help="barh linewidth")
    parser.add_argument("--suptitle", type=str)

    args = parser.parse_args()

    for name, value in args.rc_params.items():
        matplotlib.rcParams[name] = value

    fig, axs = plt.subplots(3, 3, sharex="col", )
    fig.set_size_inches(10, 7)
    plt.subplots_adjust(wspace=0.25, hspace=0.1)
    df_queries = None
    df_responses = None

    [data, software_resolv, delay,
        runfile] = args.input_hdfs[0].name.split('/')

    software, resolver = software_resolv.split('-')
    fig.suptitle(args.suptitle)

    n_iter_in_col = 0
    mpl_start_index = 0
    for i in range(0, 9):
        if (n_iter_in_col == 3):
            n_iter_in_col = 0
            mpl_start_index = mpl_start_index+1

        print("mpl_start_index : %d, n_iter_in_col : %d" %
              (mpl_start_index, n_iter_in_col))
        ax = axs[n_iter_in_col, mpl_start_index]

        df_connections = pandas.read_hdf(
            args.input_hdfs[i].name)

        [data, software_resolv, delay,
            runfile] = args.input_hdfs[i].name.split('/')

        software, resolver = software_resolv.split('-')

        if (mpl_start_index == 0):
            ax.text(-0.25, 0.5,
                    '# Connections',
                    horizontalalignment='center',
                    verticalalignment='center',
                    transform=ax.transAxes,
                    rotation=90,
                    fontsize="x-large")
            ax.text(-0.37, 0.5,
                    delay,
                    fontweight="bold",
                    horizontalalignment='center',
                    verticalalignment='center',
                    transform=ax.transAxes,
                    rotation=90,
                    fontsize="x-large")

        # if args.no_y_labels:
        #     no_y_label = args.no_y_label
        # else:
        #     if n_iter_in_col == 0:
        #         no_y_label = True
        #     else:
        #         no_y_label = False

        if n_iter_in_col == 2:
            ax.set_xlabel("Time (seconds)")

        do_plot_connections(
            fig, ax, df_connections=df_connections, try_packing=args.pack,
            min_duration_sec_to_plot_a_marker=
            args.min_duration_sec_to_plot_a_marker,
            no_y_labels=args.no_y_labels,
            linewidth=args.barh_linewidth
        )

        if (n_iter_in_col == 0):
            ax.set_title((resolver), loc='center', weight='bold')

        ylim_min, ylim_max = ax.get_ylim()

        if ylim_max < 7:
            ax.set_ylim(-1, 7)

        # ax.tick_params(axis='both', which='both', length=0)
        # ax.set_yticks([])

        print("%d / %d plotted" % (i+1, 9))
        n_iter_in_col = n_iter_in_col + 1

    if (args.suptitle is not None):
        fig.suptitle(args.suptitle)

    plt.savefig(args.output, bbox_inches="tight", dpi=150)
#    plt.show()


if __name__ == "__main__":
    do_main()
