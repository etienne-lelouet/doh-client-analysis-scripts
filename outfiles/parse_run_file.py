#!/usr/bin/env python3

import argparse

import pandas


def do_parse_runfile(in_):
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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=argparse.FileType("r"), required=True, help="Run file")
    parser.add_argument("--output", required=True, help="Output df")
    parser.add_argument("--outputExpected", required=True, help="Expected queries qutput df")


    args = parser.parse_args()

    df = do_parse_runfile(args.input)

    df.to_hdf(args.output, key="w")


if __name__ == "__main__":
    main()
