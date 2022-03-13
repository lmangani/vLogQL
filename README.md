<img src='https://user-images.githubusercontent.com/1423657/147935343-598c7dfd-1412-4bad-9ac6-636994810443.png' style="margin-left:-10px" width=180>

[![vlang-build](https://github.com/lmangani/vlogCLI/actions/workflows/vlang.yml/badge.svg)](https://github.com/lmangani/vlogCLI/actions/workflows/vlang.yml)

# vLogQL
cLoki / LogQL Client in [vlang](https://vlang.io/)


### Instructions
Download a [linux binary release](https://github.com/lmangani/vLogQL/releases) or build from source

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
vlogql v0.1.1
-----------------------------------------------
Usage: vlogql [options] [ARGS]

Description: LogQL Query CLI

Options:
  -l, --limit <int>         logql query limit [LOGQL_LIMIT]
  -a, --api <string>        logql api [LOGQL_API]
  -q, --query <string>      logql query [LOGQL_QUERY]
  -t, --labels              get labels
  -v, --label <string>      get label values
  -h, --help                display this help and exit
```

#### Examples
#### Query w/o Labels
```bash
LOGQL_API="https://cloki:3100" ./vlogql --query '{type="clickhouse"} |~ "MiB"' --limit 5
```
```
---------- Logs for: {type="clickhouse"} |~ "MiB"
2022.03.13 10:39:19.765860 [ 29849 ] {} <Debug> MemoryTracker: Peak memory usage (for query): 8.11 MiB.
2022.03.13 10:39:19.761259 [ 29849 ] {115c1357-81d3-4277-ab04-882306f76e9d} <Debug> MemoryTracker: Peak memory usage (for query): 4.12 MiB.
2022.03.13 10:39:19.761288 [ 29849 ] {} <Debug> MemoryTracker: Peak memory usage (for query): 4.12 MiB.
2022.03.13 10:39:19.765798 [ 29849 ] {f050f9e5-f919-4680-b826-ea84be9542e0} <Debug> MemoryTracker: Peak memory usage (for query): 8.11 MiB.
2022.03.13 10:39:19.759982 [ 29849 ] {115c1357-81d3-4277-ab04-882306f76e9d} <Debug> DiskLocal: Reserving 1.00 MiB on disk `default`, having unreserved 2.63 TiB.
```

#### Query w/ Labels
```bash
LOGQL_API="https://cloki:3100" ./vlogql --query '{type="clickhouse"} |~ "MiB"' --limit 5 --labels
```
#### Query Labels
```bash
LOGQL_API="https://cloki:3100" ./vlogql --labels
```
#### Query Label Values
```bash
LOGQL_API="https://cloki:3100" ./vlogql --label type
```

-----

### License
Licensed under MIT, sponsored by [qxip](https://metrico.in) as part of the [cLoki](https://cloki.org) project
