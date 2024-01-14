#!/usr/bin/env python3

import argparse

import pandas


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input-queries", type=argparse.FileType("r"),
                        required=True, help="Input json file")
    parser.add_argument("--input-responses", type=argparse.FileType("r"),
                        required=True, help="Input json file")
    parser.add_argument("--output", required=True, help="Output df")

    args = parser.parse_args()

    df_queries = pandas.read_csv(args.input_queries)
    df_queries['dns.qry.name'] = df_queries.apply(lambda row : str(row['dns.qry.name']).split(";"),axis=1)
    df_queries = df_queries.explode(column='dns.qry.name').reset_index(drop=True)
    df_queries = df_queries.drop('dns.qry.name', axis=1)

    df_responses = pandas.read_csv(args.input_responses)
    df_responses['dns.qry.name'] = df_responses.apply(lambda row : str(row['dns.qry.name']).split(";"),axis=1)
    df_responses = df_responses.explode(column='dns.qry.name').reset_index(drop=True)
    df_responses = df_responses.drop('dns.qry.name', axis=1)

    store = pandas.HDFStore(args.output)
    store['queries'] = df_queries
    store['responses'] = df_responses
    store.close()


if __name__ == "__main__":
    main()
