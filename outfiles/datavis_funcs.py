import os
import re
from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np
import pandas
import pandas as pd
import seaborn as sns

swarmplot_bigaggreg_size = 30
swarmplot_medaggreg_size = 5
palette = {"single": "#ff6666"}

palette_delays = {"50": "#ff6666", "100": "#7fff7f",
                  "1000": "#b2b2ff", "5000": "#000000", "60000": "#0000ff"}


def myround(x, base=5):
    return base * round(x / base)


SMALL_SIZE = 15
MEDIUM_SMALL_SIZE = 45
MEDIUM_BIG_SIZE = 60
ALMOST_BIGGER_SIZE = 67
BIG_SIZE = 75
BIGGER_SIZE = 90
plt.rc('font', size=MEDIUM_SMALL_SIZE)
plt.rc('axes', titlesize=BIG_SIZE)
plt.rc('axes', labelsize=ALMOST_BIGGER_SIZE)
plt.rc('xtick', labelsize=MEDIUM_BIG_SIZE)
plt.rc('ytick', labelsize=MEDIUM_BIG_SIZE)
plt.rc('legend', fontsize=MEDIUM_SMALL_SIZE)
plt.rc('figure', titlesize=BIGGER_SIZE)

capture_time_seconds = 350
keep = ["50", "100", "1000", "5000", "60000"]

cache = False
filename = ""

swarmplot_point_size = 25


def get_df_swarmplot_time(folder, delay, currdir, metric_filename):
    df = pd.read_csv(os.path.join(currdir, metric_filename), sep=",", names=[
        "data"])
    df["delay"] = ["%s" % delay] * len(df)
    df["type"] = ["single"] * len(df)
    df["resolver"] = [folder] * len(df)
    df.to_csv(os.path.join(currdir, "%s.cache" % metric_filename), index=True)
    return df


def plot_swarmplot_time(df, output_filename, group, keep):
    fig, ax = plt.subplots(len(group), 1, figsize=(
        len(keep) * 30, (len(group) * 60)))
    plt.subplots_adjust(wspace=0.1)
    for j, resolver in enumerate(group):
        df_temp = df.loc[df['resolver'] == resolver]
        if df_temp.empty:
            continue
        log_ax = ax[j]
        log_ax.set_yscale("symlog")
        log_ax.yaxis.set_major_formatter(ticker.ScalarFormatter())
        sns.swarmplot(x="delay", y="data", hue="type",
                      data=df_temp, ax=log_ax, size=swarmplot_point_size, palette=palette)
        log_ax.set_title("%s" % (resolver), wrap=True)
        log_ax.set(xlabel="Délai (ms)", ylabel="Durée de la connexion (s)")

    for ax in fig.axes:
        ax.get_legend().remove()

    if not (os.path.isabs(filename)):
        current_directory_path = os.getcwd()
        filename_path = os.path.join(current_directory_path, output_filename)
    else:
        filename_path = os.path.join(output_filename)

    plt.savefig(filename_path, facecolor='white', transparent=False,
                bbox_inches='tight', pad_inches=0)


def get_df_swarmplot_nrequests(folder, delay, currdir, metric_filename):
    df = pd.read_csv(os.path.join(currdir, metric_filename), sep=",", names=[
        "data"])
    df["delay"] = ["%s" % delay] * len(df)
    df["type"] = ["single"] * len(df)
    df["resolver"] = [folder] * len(df)
    df.to_csv(os.path.join(currdir, "%s.cache" % metric_filename), index=True)
    return df


def plot_swarmplot_nrequests(df, output_filename, group, keep):
    fig, ax = plt.subplots(len(group), 1, figsize=(
        len(keep) * 30, (len(group) * 60)))
    plt.subplots_adjust(wspace=0.1)
    for j, resolver in enumerate(group):
        df_temp = df.loc[df['resolver'] == resolver]
        if df_temp.empty:
            continue
        log_ax = ax[j]
        log_ax.set_yscale("symlog")
        log_ax.yaxis.set_major_formatter(ticker.ScalarFormatter())
        sns.swarmplot(x="delay", y="data", hue="type",
                      data=df_temp, ax=log_ax, size=swarmplot_point_size, palette=palette)
        log_ax.set_title("%s" % (resolver), wrap=True)
        log_ax.set(xlabel="Délai (ms)", ylabel="Nombre de requêtes")

    for ax in fig.axes:
        ax.get_legend().remove()

    if not (os.path.isabs(filename)):
        current_directory_path = os.getcwd()
        filename_path = os.path.join(current_directory_path, output_filename)
    else:
        filename_path = os.path.join(output_filename)

    plt.savefig(filename_path, facecolor='white', transparent=False,
                bbox_inches='tight', pad_inches=0)


def get_df_swarmplot_nrequests_percents(folder, delay, currdir, metric_filename):
    df = pd.read_csv(os.path.join(currdir, metric_filename), sep=",", names=[
        "data"], dtype={'data': np.float64})
    totalqueries = df["data"].sum()
    total_percentage = 0
    for index, row in df.iterrows():
        percentage = (row["data"] / totalqueries) * 100
        df.loc[index, 'data'] = percentage
        total_percentage = total_percentage + percentage

    df["delay"] = [delay] * len(df)
    df["type"] = ["single"] * len(df)
    df["resolver"] = [folder] * len(df)
    df.to_csv(os.path.join(currdir, "%s.cache" % metric_filename), index=True)
    return df


def plot_swarmplot_nrequests_percent(df, output_filename, group, keep):
    fig, ax = plt.subplots(len(group), 1, figsize=(
        len(keep) * 30, (len(group) * 60)))
    plt.subplots_adjust(wspace=0.1)
    for j, resolver in enumerate(group):
        df_temp = df.loc[df['resolver'] == resolver]
        if df_temp.empty:
            continue
        log_ax = ax[j]
        log_ax.set_yscale("symlog")
        log_ax.yaxis.set_major_formatter(ticker.ScalarFormatter())
        sns.swarmplot(x="delay", y="data", hue="type",
                      data=df_temp, ax=log_ax, size=swarmplot_point_size, palette=palette)
        log_ax.set_title("%s" % (resolver), wrap=True)
        log_ax.set(xlabel="Délai (ms)", ylabel="Pourcentage")

    if not (os.path.isabs(filename)):
        current_directory_path = os.getcwd()
        filename_path = os.path.join(current_directory_path, filename)
    else:
        filename_path = os.path.join(filename)

    if not (os.path.isabs(filename)):
        current_directory_path = os.getcwd()
        filename_path = os.path.join(current_directory_path, output_filename)
    else:
        filename_path = os.path.join(output_filename)

    plt.savefig(filename_path, facecolor='white', transparent=False,
                bbox_inches='tight', pad_inches=0)


def get_df_swarmplot_naggregs(folder, delay, currdir, metric_filename):
    df = pd.read_csv(os.path.join(currdir, metric_filename), sep=",", names=[
        "data"], dtype={'data': np.float64})
    df["type"] = ["%s" % delay] * len(df)
    df["delay"] = [delay] * len(df)
    df["type"] = ["single"] * len(df)
    df["resolver"] = [folder] * len(df)
    df.to_csv(os.path.join(currdir, "%s.cache" % metric_filename), index=True)
    return df


def plot_swarmplot_naggregs(df, output_filename, group, keep):
    fig, ax = plt.subplots(len(group), 1, figsize=(
        len(keep) * 30, (len(group) * 60)))
    plt.subplots_adjust(wspace=0.1)
    for j, resolver in enumerate(group):
        df_temp = df.loc[df['resolver'] == resolver]
        if df_temp.empty:
            continue
        log_ax = ax[j]
        log_ax.set_yscale("symlog")
        log_ax.yaxis.set_major_formatter(ticker.ScalarFormatter())
        sns.swarmplot(x="delay", y="data", hue="type",
                      data=df_temp, ax=log_ax, size=swarmplot_point_size, palette=palette)
        log_ax.set_title("%s" % (resolver), wrap=True)
        log_ax.set(xlabel="Délai (ms)", ylabel="Nombre de messages")

    if not (os.path.isabs(output_filename)):
        current_directory_path = os.getcwd()
        filename_path = os.path.join(current_directory_path, output_filename)
    else:
        filename_path = os.path.join(output_filename)
    plt.savefig(filename_path, facecolor='white', transparent=False,
                bbox_inches='tight', pad_inches=0)


def get_df_linechart(folder, delay, currdir, metric_filename):
    df = pd.DataFrame(columns=["time", "count", "delay", "resolver"])
    df_timecount = pd.read_csv(os.path.join(currdir, metric_filename), sep=",", names=[
        "time", "state"], dtype={'time': np.float64, 'count': np.int32})

    timeArr = []
    countArr = []
    count = 0
    for index, row in df_timecount.iterrows():
        timeArr.append(row["time"])
        if row["state"] == "open":
            count = count + 1
        elif row["state"] == "close":
            count = count - 1
        countArr.append(count)

    # for timefloat in np.arange(0, capture_time_seconds, 0.1):
    #     time = float("%.1f" % timefloat)
    #     res = df_timecount.loc[df_timecount['time'] == time]
    #     if len(res) == 0:
    #         timeArr.append(time)
    #         countArr.append(count)
    #     else:
    #         for index, row in res.iterrows():
    #             if row["state"] == "open":
    #                 count = count + 1
    #             elif row["state"] == "close":
    #                 count = count - 1
    #         timeArr.append(time)
    #         countArr.append(count)

    df["time"] = timeArr
    df["count"] = countArr
    df["delay"] = [delay] * len(df)
    df["resolver"] = [folder] * len(df)
    df["time"] = pd.to_numeric(df["time"])
    df["count"] = pd.to_numeric(df["count"])
    df.to_csv(os.path.join(
        currdir, "%s.cache" % metric_filename), index=True)
    return df


def plot_linechart(df, output_filename, group, keep):
    lim_max = 0

    # max = df["count"].max()
    # if max > lim_max:
    #     lim_max = max

    # fig, ax = plt.subplots(len(keep), len(
    #     group), figsize=(len(group) * 90, len(keep) * 30))
    # plt.subplots_adjust(wspace=0.1)
    for i, delay in enumerate(keep):
        for j, resolver in enumerate(group):
            fig = plt.figure(figsize=(90, 30), tight_layout=True)
            ax = fig.add_subplot()
            # log_ax.set_ylim(0, (lim_max))
            ax.yaxis.set_major_locator(ticker.MaxNLocator(integer=True))
            ax.yaxis.set_major_locator(ticker.MaxNLocator(integer=True))
            df_temp = df.loc[(df['delay'] == delay) & (
                    df['resolver'] == resolver)]
            sns.lineplot(data=df_temp, x="time", y="count",
                         hue="delay", ax=ax, linewidth=15, drawstyle='steps-post')
            ax.legend(frameon=True, framealpha=1, facecolor="white")
            ax.set_title("%s, Délai : %sms" % (resolver, delay), wrap=True)
            ax.set(xlabel="Temps (s)", ylabel="Nombre de connexions")
            ax.get_legend().remove()
            fig.savefig("%s_%s_%s.png" % (output_filename, resolver, delay), facecolor='white', transparent=False,
                        bbox_inches='tight', pad_inches=0)
            plt.close(fig)

    # for ax in fig.axes:
    #     ax.get_legend().remove()

    # if not (os.path.isabs(output_filename)):
    #     current_directory_path = os.getcwd()
    #     filename_path = os.path.join(current_directory_path, output_filename)
    # else:
    #     filename_path = os.path.join(output_filename)
    # plt.savefig(filename_path, facecolor='white', transparent=False,
    #             bbox_inches='tight', pad_inches=0)


def plot_barchart(group, file, title):
    dfs = []
    titlestrings = []
    for i, folder in enumerate(group):
        basedir = os.path.join(os.getcwd(), "data", folder)
        directories = [os.path.join(basedir, d) for d in os.listdir(
            basedir) if os.path.isdir(os.path.join(basedir, d))]
        df_all = pd.DataFrame()
        for delay in keep:
            dirs = [f for f in directories if "%sms" % delay in f]
            currdir = dirs[0]
            with open(os.path.join(currdir, "runfile")) as f:
                first_line = f.readline()
                duration, delay = re.findall(
                    r"^runtime:\s([0-9]+).*?delay:\s([0-9]+).*$", first_line)[0]

            if cache == True:
                df = pd.read_csv(os.path.join(currdir, "%s.cache" % file), sep=",", header=0, names=[
                    "data", "delay"], dtype={'data': np.float64, 'delay': str})
            else:
                df = pd.read_csv(os.path.join(currdir, file),
                                 sep=",", dtype=np.float64)
            df["delay"] = ["%s" % delay] * len(df)
            df.to_csv(os.path.join(currdir, "%s.cache"), index=True)
            df_all = df_all.append(df, ignore_index=True)

        if not df_all.empty:
            dfs.append(df_all)
            titlestrings.append("%s" % (folder))

    len_df = len(dfs)
    fig = plt.figure(tight_layout=True)
    for i, df in enumerate(dfs):
        ax = fig.add_subplot(len_df, 1, i + 1)
        ax.set_title(titlestrings[i])
        ax = df.set_index('delay').plot(kind='bar', stacked=True, ax=ax, color={
            "perc_fin_by_client": "#ff6666", "perc_reset_by_client": "#b2b2ff", "perc_fin_by_server": "#7fff7f",
            "perc_reset_by_server": "#f1c232"})
        ax.set(xlabel="Délai", ylabel="% de fermetures de connexions")
        ax.legend(bbox_to_anchor=(0, 1.02),
                  loc="lower left", ncol=2, fontsize=45)

    if not (os.path.isabs(filename)):
        current_directory_path = os.getcwd()
        filename_path = os.path.join(current_directory_path, filename)
    else:
        filename_path = os.path.join(filename)

    fig.tight_layout()
    plt.savefig(filename_path, facecolor='white', transparent=False,
                bbox_inches='tight', pad_inches=0)


def do_parse_runfile(path: Path):
    with path.open("r") as in_:
        iter_ = iter(in_)
        first = next(iter_)
        second = next(iter_)
        third = next(iter_)
        tokens = [t.strip() for t in third.split(":")]
        number_tcp_streams = int(tokens[1])

        data = {
            "ip": [],
            "relative_start_sec": [],
            "num_queries": [],  # number of queries made during the connection
            "duration_sec": [],
            "closed_by": [],
            "FIN": [],
            "RESET": []
        }

        for row_idx in range(0, number_tcp_streams):
            row = next(iter_).strip()
            tokens = row.split(",")
            ip = tokens[0]
            num_queries = int(tokens[1].replace("queries: ", ""))
            relative_start_sec = float(tokens[2].replace("relative_start: ", ""))
            duration_sec = float(tokens[3].replace("duration: ", ""))
            closed_by = tokens[4].replace("closed_by: ", "")
            fin = int(tokens[5].replace("fin: ", ""))
            reset = int(tokens[6].replace("reset: ", ""))

            data["ip"].append(ip)
            data["relative_start_sec"].append(relative_start_sec)
            data["num_queries"].append(num_queries)
            data["duration_sec"].append(duration_sec)
            data["closed_by"].append(closed_by)
            data["FIN"].append(fin)
            data["RESET"].append(reset)

        df = pandas.DataFrame.from_dict(data)

    return df


def parse_and_gen_df(group, keep, root_folder):
    df_all = pd.DataFrame()
    for i, folder in enumerate(group):
        basedir = os.path.join(os.getcwd(), root_folder, folder)
        directories = [os.path.join(basedir, d) for d in os.listdir(
            basedir) if os.path.isdir(os.path.join(basedir, d))]
        for delay in keep:
            dirs = [f for f in directories if "%sms" % delay in f]
            currdir = dirs[0]
            print("doing %s" % currdir)
            runfile = os.path.join(currdir, "runfile")
            df = do_parse_runfile(Path(runfile))
            outfile = os.path.join(currdir, "df.hdf")
            df.to_hdf(outfile, "w")


def plot_metric(parse_function, plot_function, group, keep, metric_filename, title, cache, output_filename,
                root_folder):
    df_all = pd.DataFrame()
    for i, folder in enumerate(group):
        basedir = os.path.join(os.getcwd(), root_folder, folder)
        directories = [os.path.join(basedir, d) for d in os.listdir(
            basedir) if os.path.isdir(os.path.join(basedir, d))]
        for delay in keep:
            dirs = [f for f in directories if "%s_ms" % delay in f]
            currdir = dirs[0]
            with open(os.path.join(currdir, "runfile")) as f:
                first_line = f.readline()
                duration, delay = re.findall(
                    r"^runtime:\s([0-9]+).*?delay:\s([0-9]+).*$", first_line)[0]

                if cache == True:
                    df = pd.read_csv(os.path.join(
                        currdir, "%s.cache" % metric_filename), sep=",", header=0)
                else:
                    df = parse_function(
                        folder, delay, currdir, metric_filename)

                df_all = df_all.append(df, ignore_index=True)

    if df_all.empty:
        print("no data to plot")
        return
    plot_function(df_all, output_filename, group, keep)
