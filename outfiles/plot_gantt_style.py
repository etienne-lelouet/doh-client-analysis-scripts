#!/usr/bin/env python3

import argparse

import matplotlib
import matplotlib.pyplot as plt
import pandas


def do_plot_queries(fig, ax, df_queries, df_responses, min_lim, max_lim, no_y_labels, ylim_max):
    ax.set_xlim([min_lim, max_lim])

    if df_queries is not None:
        ax.plot(df_queries["frame.time_relative"], df_queries.index + 1)

    if df_responses is not None:
        ax.plot(df_responses["frame.time_relative"], df_responses.index + 1)

    ax.xaxis.grid(color='k', linestyle="dashed", alpha=0.4, which="both")
    ax.set_xlabel("Time (seconds)")
    ax.set_ylabel("cum num")
    if ylim_max != -1:
        ax.set_ylim([ax.get_ylim()[0], ylim_max])

    if no_y_labels:
        ax.axes.yaxis.set_visible(False)

    plt.subplots_adjust(hspace=.0)


def do_plot_connections(fig, ax, df_connections, try_packing, min_duration_sec_to_plot_a_marker, no_y_labels,
                        linewidth):
    df_connections["relative_end_sec"] = df_connections["relative_start_sec"] + \
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

        bar = ax.barh(plot_index, width=row.duration_sec, left=row.relative_start_sec,
                      alpha=1, edgecolor="black", linewidth=linewidth)

        #  get bar color
        color = bar.patches[0].get_facecolor()

        # for the lowest bar we plot a cross in the middle
        if row.duration_sec < min_duration_sec_to_plot_a_marker:
            ax.scatter(row.relative_start_sec + row.duration_sec /
                       2, plot_index, marker="x", color=color)
        # else:
        # ax.text(row.relative_start_sec + row.duration_sec / 2, plot_index, str(row.num_queries),
        #         horizontalalignment="center", verticalalignment="center")

    # set limits
    max_ = (df_connections["relative_start_sec"] +
            df_connections["duration_sec"]).max()
    min_lim, max_lim = -5, ax.get_xlim()[1]
    ax.set_xlim([min_lim, max_lim])

    # grid lines
    # ax.set_axisbelow(True)
    ax.xaxis.grid(color='k', linestyle='dashed', alpha=0.4, which='both')
    ax.yaxis.grid(color='k', linestyle='dashed', alpha=0.4, which='both')

    # Y labels
    # ax.set_yticks(list(ylabels.keys()), labels=list(ylabels.values()), fontsize=12)
    # ax.axes.yaxis.set_visible(False)

    # if no_y_labels:
    #     ax.axes.yaxis.set_visible(False)

    ax.set_xlabel("Time (seconds)")

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
        fig, ax_conn, df_connections, try_packing, min_duration_sec_to_plot_a_marker, no_y_labels, linewidth
    )

    # if df_queries is not None or df_responses is not None:
    #     do_plot_queries(fig, ax_queries, df_queries, df_responses, min_lim, max_lim, no_y_labels, ylim_queries)

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
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-connections", type=argparse.FileType("r"), required=True,
                        help="Input connections data")
    # parser.add_argument("--input-queries", type=argparse.FileType("r"),
    #                     default=None, help="Input queries data")
    parser.add_argument("--output", required=True, help="Output graph")
    parser.add_argument("--min-duration-sec-to-plot-a-marker", default=1, type=int,
                        help="Minimal duration to plat a marker")
    parser.add_argument("--pack", default=False, action="store_true",
                        help="Pack non overlapped connections")
    parser.add_argument("--width", type=float, default=10.0,
                        help="fig width (inches)")
    parser.add_argument("--height", type=float, default=4.0,
                        help="fig height (inches)")
    parser.add_argument("--height-ratio", type=float, default=70, choices=range(0, 100),
                        help="Percentage of height reserved for the connections plot")
    parser.add_argument("--no-y-labels", action="store_true", default=False,
                        help="Hide y labels")
    parser.add_argument("--rc-params", nargs="+", default={}, action=KeyValue,
                        help="Tune matplotlib.rcParams")
    parser.add_argument("--barh-linewidth", type=float, help="barh linewidth")
    parser.add_argument("--max-queries", type=int,
                        default=-1, help="ylmit for bottom plot")

    args = parser.parse_args()

    for name, value in args.rc_params.items():
        matplotlib.rcParams[name] = value

    df_connections = pandas.read_hdf(args.input_connections.name)

    df_queries = None
    df_responses= None
    # if args.input_queries:
    #     df_queries = pandas.read_hdf(args.input_queries.name, key="queries")
    #     df_responses = pandas.read_hdf(
    #         args.input_queries.name, key="responses")

    fig = do_plot(
        df_connections, df_queries, df_responses,
        args.min_duration_sec_to_plot_a_marker,
        args.pack, args.height_ratio,
        args.no_y_labels, args.barh_linewidth, args.max_queries
    )

    fig.set_size_inches(args.width, args.height)

    plt.show()
    plt.savefig(args.output, bbox_inches="tight")


if __name__ == "__main__":
    do_main()
