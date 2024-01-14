# Files not comitted because they are too big:

Latest firefox archive (named `firefox.tar.bz2`), goes into the `docker/` folder.

Dnscrypt-proxy executable (named `dnscrypt-proxy`), goes into the `docker/` folder.

A file containing a list of valid domain names (with a corresponding A record, that points to a somewhat working website), named `queryfile-filtered/querifiles/domainlist`.

# Overview

The experiments are launched by running is generated using `*-generate_results.sh` scripts. The results are first parsed by `parse_results_parallel.sh` and then by `gen_queries.sh`.

Running a full set of experiment will result in a directory structure looking like the following, where each "*ms" folder corresponds to one experiment:

```
.
├── chromium-cloudflare
│   ├── 1000ms
│   ├── 100ms
│   ├── 5000ms
│   ├── 50ms
│   └── 60000ms
├── chromium-google
│   ├── 1000ms
│   ├── 100ms
│   ├── 5000ms
│   ├── 50ms
│   └── 60000ms
├── chromium-quad9
│   ├── 1000ms
│   ├── 100ms
│   ├── 5000ms
│   ├── 50ms
│   └── 60000ms
├── dig_dnscrypt-cloudflare
│   ├── 1000ms
│   ├── 100ms
│   ├── 5000ms
│   ├── 50ms
│   └── 60000ms
├── dig_dnscrypt-google
│   ├── 1000ms
│   ├── 100ms
│   ├── 5000ms
│   ├── 50ms
│   └── 60000ms
├── dig_dnscrypt-quad9
│   ├── 1000ms
│   ├── 100ms
│   ├── 5000ms
│   ├── 50ms
│   └── 60000ms
├── firefox-cloudflare
│   ├── 1000ms
│   ├── 100ms
│   ├── 5000ms
│   ├── 50ms
│   └── 60000ms
├── firefox_dnscrypt-cloudflare
│   ├── 1000ms
│   ├── 100ms
│   ├── 5000ms
│   ├── 50ms
│   └── 60000ms
├── firefox_dnscrypt-google
│   ├── 1000ms
│   ├── 100ms
│   ├── 5000ms
│   ├── 50ms
│   └── 60000ms
├── firefox_dnscrypt-quad9
│   ├── 1000ms
│   ├── 100ms
│   ├── 5000ms
│   ├── 50ms
│   └── 60000ms
├── firefox-google
│   ├── 1000ms
│   ├── 100ms
│   ├── 5000ms
│   ├── 50ms
│   └── 60000ms
└── firefox-quad9
    ├── 1000ms
    ├── 100ms
    ├── 5000ms
    ├── 50ms
    └── 60000ms
```

Once this is done, graphs can be generated using the code in `datavis_funcs.py` and `datavis-tcp-keepalive.ipynb`.

In both cases, various helper scripts exist to run multiple experiments : `launch_multiple.sh`, the `sleep_timer*` scripts, or to generate graphs for every folder of an experiment tree `parsedatafolder.sh`.

# NEEDED STEPS

Install docker, and make your user part of the docker group (or run the script as root).

Install tshark, and grant yourself capabilities to capture network traffic by making your user part of the wireshark group (or again, run the script as root)

Install `jq` and `parallel`.

Set your locale to en-GB.utf8 (there are some . / , related shenanigans when doing floating point calculations that I don't have time to fix now).

Since the scripts expects you to host some pages loaded by firefox on your localhost, make queryfile/filtered/webscript/* accessible on your localhost, the most basic setup is install nginx, php and php-fpm, add the following snippet as a vhost (sites-available and sites-enabled) (disable the default) : 

```
server {
        listen 80;
        listen [::]:80;
        access_log /var/log/nginx/reverse-access.log;
        error_log /var/log/nginx/reverse-error.log;
        root /var/www/static;

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php8.1-fpm.sock; // Check according to your php version
        }

        location / {
                add_header Access-Control-Allow-Origin *;

                try_files $uri $uri/  =404;
                autoindex on;
        }
}
```
```
wireshark -o \
    tls.keylog_file:/home/antoine/Documents/prog/these_doq/article/article-transports-dns/outfiles/data1tab/firefox-cloudflare/22.05.02-11.15.40-Mon_50_ms/keys.log  \
    /home/antoine/Documents/prog/these_doq/article/article-transports-dns/outfiles/data1tab/firefox-cloudflare/22.05.02-11.15.40-Mon_50_ms/*pcap
```

# Results analysis and graphics generation

At the end of each experiment, each folder contains a summary of the experiment's parameters (called the _runfile_), and a network capture.

The first step is to launch the `outfiles/parse_results_parallel.sh` script, passing it the result folder as 1st and only arg, that will use `tshark` to enrich the _runfile_ with data about each TCP stream, and with data about the total number of expected queries that were made (we talk about "expected queries" because some additional queries can be made, especially when considering the web browser's behaviour).

Once we have this data generated, we can run the `outfiles/gen_queries.sh` script, also passing it the result folder as 1st and only arg, that will run various python scripts to first generate data in the .hdf format (so we don't do all of the data analysis once again if we just need to change how the graphics look).

## gen_queries.sh innter workings

First, it runs `outfiles/parse_run_file.py` that read the runfile and, for each connection, puts the data into a dataframe (`runfile.hdf`).

Then, it runs tshark to dump the whole filtered capture (that is, only the traffic between client and resolver) as json.

It then feeds said json to `outfiles/parse_requests_json.py`, that logs each dns query's relative time into a dataframe (`capture_filtered.hdf`).

Finally, `outfiles/plot_gantt_style.py` generate the gantt plot from `runfile.hdf`, and the cumulative curve of queries and responses from`capture_filtered.hdf`. 
<!--  
ip.addr == 104.16.248.0/23 or ip.addr == 1.0.0.1 or ip.addr == 1.1.1.1
tls.alert_message.desc == 0 
tls.handshake.type == 1
tls.handshake.extensions.psk.identities.length -->
