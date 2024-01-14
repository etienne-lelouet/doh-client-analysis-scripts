import sys

if (len(sys.argv) < 3):
    print(sys.argv[0] + " not enough args")
    exit(1)

resolver_name = sys.argv[1]
input_file= sys.argv[2]

with open('doh_resolver_queries') as file:
    num_lines = sum(1 for line in file)
    file.seek(0)
    filearr = file.readlines()

start_line = 0
last_line = 2

addr_set = set()

while last_line <= num_lines:
    query = filearr[start_line:last_line]
    querynames = query[0].split(",")
    queryrespaddr = query[1].split(",")
    for i, str in enumerate(querynames):
        if str == resolver_name:
            addr_set.add(queryrespaddr[i])

    start_line = last_line
    last_line = start_line + 2

for ip in set:
    print(ip)