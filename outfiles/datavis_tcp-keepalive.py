#!/usr/bin/env python3

from datavis_funcs import *
import sys

data_root = sys.argv[1]
print(data_root)
keep = ["50", "100", "1000", "5000", "60000"]
group = ["firefox-cloudflare", "firefox-quad9"]
parse_and_gen_df(group, keep, data_root)
