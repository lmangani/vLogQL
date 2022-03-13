<img src='https://user-images.githubusercontent.com/1423657/147935343-598c7dfd-1412-4bad-9ac6-636994810443.png' style="margin-left:-10px" width=180>

[![vlang-build](https://github.com/lmangani/vlogCLI/actions/workflows/vlang.yml/badge.svg)](https://github.com/lmangani/vlogCLI/actions/workflows/vlang.yml)

# vLogQL
cLoki / LogQL Client in [vlang](https://vlang.io/)


### Instructions
#### Install V
```bash
git clone https://github.com/vlang/v
(cd v && make && v symlink)
```
#### Build
```bash
v -o vlogql -prod vlogql.v
```

#### Usage
```
vlogql v0.1.0
-----------------------------------------------
Usage: vlogql [options] [ARGS]
Description: Query LogQL Logs

Options:
  -l, --limit <int>         number of logs to show
  -a, --api <string>        logql api
  -q, --query <string>      logql query
  -t, --labels              get labels
  -v, --label <string>      get label values
  -h, --help                display this help and exit
  --version                 output version information and exit
```

```
./vlogql --query '{type="clickhouse"} |~ "MiB"' --limit 5
Fetching logs...
2022.03.13 10:39:19.765860 [ 29849 ] {} <Debug> MemoryTracker: Peak memory usage (for query): 8.11 MiB.
2022.03.13 10:39:19.761259 [ 29849 ] {115c1357-81d3-4277-ab04-882306f76e9d} <Debug> MemoryTracker: Peak memory usage (for query): 4.12 MiB.
2022.03.13 10:39:19.761288 [ 29849 ] {} <Debug> MemoryTracker: Peak memory usage (for query): 4.12 MiB.
2022.03.13 10:39:19.765798 [ 29849 ] {f050f9e5-f919-4680-b826-ea84be9542e0} <Debug> MemoryTracker: Peak memory usage (for query): 8.11 MiB.
2022.03.13 10:39:19.759982 [ 29849 ] {115c1357-81d3-4277-ab04-882306f76e9d} <Debug> DiskLocal: Reserving 1.00 MiB on disk `default`, having unreserved 2.63 TiB.
----------
```
