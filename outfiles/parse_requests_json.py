#!/usr/bin/env python3

import argparse

import ijson
import pandas


def do_parse_doh(entry, dns):
    responses_times_relative = []
    queries_times_relative = []

    if isinstance(dns, dict):
        dns_flags_rsp = int(dns["dns.flags_tree"]["dns.flags.response"])
        is_dns_query = dns_flags_rsp == 0
        is_dns_reponse = dns_flags_rsp == 1
        if is_dns_query:
            queries_times_relative.append(
                float(entry["_source"]["layers"]["frame"]["frame.time_relative"]))
        elif is_dns_reponse:
            responses_times_relative.append(
                float(entry["_source"]["layers"]["frame"]["frame.time_relative"]))

    elif isinstance(dns, list):
        for dns_query in dns:
            is_dns_query = dns_query["dns.flags_tree"]["dns.flags.response"] == 0
            is_dns_reponse = dns_query["dns.flags_tree"]["dns.flags.response"] == 1
            if is_dns_query:
                queries_times_relative.append(
                    float(entry["_source"]["layers"]["frame"]["frame.time_relative"]))
            elif is_dns_reponse:
                responses_times_relative.append(
                    float(entry["_source"]["layers"]["frame"]["frame.time_relative"]))
    else:
        raise ValueError("invalid dns type")

    return queries_times_relative, responses_times_relative


def do_parse(input):
    responses_times_relative = []
    queries_times_relative = []

    for idx, entry in enumerate(ijson.items(input, "item")):
        if "http2" in entry["_source"]["layers"]:
            if isinstance(entry["_source"]["layers"]["http2"], dict):
                if "dns" in entry["_source"]["layers"]["http2"]:
                    tmp_queries_times_relative, tmp_responses_times_relative = \
                        do_parse_doh(
                            entry, entry["_source"]["layers"]["http2"]["dns"])

                    queries_times_relative += tmp_queries_times_relative
                    responses_times_relative += tmp_responses_times_relative

            elif isinstance(entry["_source"]["layers"]["http2"], list):
                if isinstance(entry["_source"]["layers"]["http2"], dict):
                    if "dns" in entry["_source"]["layers"]["http2"]:
                        tmp_queries_times_relative, tmp_responses_times_relative = \
                            do_parse_doh(
                                entry, entry["_source"]["layers"]["http2"]["dns"])
            else:
                raise ValueError("invalid layers type")

    df_queries = pandas.DataFrame({
        "times_relative": queries_times_relative,
    }, dtype=float)

    df_responses = pandas.DataFrame({
        "times_relative": responses_times_relative
    }, dtype=float)

    return df_queries, df_responses


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input", type=argparse.FileType("r"),
                        required=True, help="Input json file")
    parser.add_argument("--output", required=True, help="Output df")

    args = parser.parse_args()

    df_queries, df_responses = do_parse(args.input)
    print(df_queries)
    print("queries", len(df_queries.index))
    print("responses", len(df_responses.index))
    store = pandas.HDFStore(args.output)
    store['queries'] = df_queries
    store['responses'] = df_responses
    store.close()


if __name__ == "__main__":
    main()
