#!/usr/bin/env python3
import pandas as pd
import numpy as np

base_folder = "/home/etienne/these-tools/client-tcp-keepalive/outfiles/data/"
folder_list = [
    "firefox-cloudflare/50ms",
    "firefox-cloudflare/1000ms",
    "firefox-cloudflare/60000ms",
    "firefox-google/50ms",
    "firefox-google/1000ms",
    "firefox-google/60000ms",
    "firefox-quad9/50ms",
    "firefox-quad9/1000ms",
    "firefox-quad9/60000ms",
    "chromium-cloudflare/50ms",
    "chromium-cloudflare/1000ms",
    "chromium-cloudflare/60000ms",
    "chromium-google/50ms",
    "chromium-google/1000ms",
    "chromium-google/60000ms",
    "chromium-quad9/50ms",
    "chromium-quad9/1000ms",
    "chromium-quad9/60000ms",
    "dig_dnscrypt-cloudflare/50ms",
    "dig_dnscrypt-cloudflare/1000ms",
    "dig_dnscrypt-cloudflare/60000ms",
    "dig_dnscrypt-google/50ms",
    "dig_dnscrypt-google/1000ms",
    "dig_dnscrypt-google/60000ms",
    "dig_dnscrypt-quad9/50ms",
    "dig_dnscrypt-quad9/1000ms",
    "dig_dnscrypt-quad9/60000ms",
]

glob_arr = []

for folder in folder_list:
    fullfolder = base_folder + folder
    folder_hdf = fullfolder + "/runfile.hdf"

    df_tmp = pd.read_hdf(folder_hdf)
    print(folder)
    print(df_tmp)

    quantile_num_queries = df_tmp.num_queries.quantile(
        [0.25, 0.5, 0.75],
        interpolation="linear"
    )

    quantile_duration = df_tmp.duration_sec.quantile(
        [0.25, 0.5, 0.75],
        interpolation="linear"
    )

    glob_arr.append(
        folder.replace("/", "-").split("-") +
        [
            len(df_tmp),
            "%.2f" % quantile_num_queries.iloc[0],
            "%.2f" % quantile_num_queries.iloc[1],
            "%.2f" % quantile_num_queries.iloc[2],
            "%.2f" % quantile_duration.iloc[0],
            "%.2f" % quantile_duration.iloc[1],
            "%.2f" % quantile_duration.iloc[2],
        ]
    )

columns = [
    "exp_soft",
    "exp_res",
    "exp_delay",
    "nconnections",
    "msg_25%",
    "msg_50%",
    "msg_75%",
    "dur_25%",
    "dur_50%",
    "dur_75%",
]
df = pd.DataFrame(np.array(glob_arr), columns=columns)
pd.set_option('display.max_colwidth', 1000)
print(df)
