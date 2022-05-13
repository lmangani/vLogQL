<img src='https://user-images.githubusercontent.com/1423657/147935343-598c7dfd-1412-4bad-9ac6-636994810443.png' style="margin-left:-10px" width=180>

[![vlang-build-pipeline](https://github.com/lmangani/vLogQL/actions/workflows/vlang.yml/badge.svg?branch=main)](https://github.com/lmangani/vLogQL/actions/workflows/vlang.yml)

# vLogQL
cLoki / LogQL Client in [vlang](https://vlang.io/)


### Instructions
Download a [binary release](https://github.com/lmangani/vLogQL/releases/) or build from source


#### 📦 Download Binary
```
curl -fsSL github.com/lmangani/vLogQL/releases/latest/download/vlogql -O && chmod +x vlogql
```

#### Build Source
##### 📦 Install V
```bash
git clone https://github.com/vlang/v
(cd v && make && v symlink)
```
##### 📖 Compile
```bash
git clone https://github.com/lmangani/vlogql
(cd vlogql && v -o vlogql -prod vlogql.v)
```


### 🔎 Usage
```
Usage: vlogql [options] [ARGS]

Options:
  -l, --limit <int>         logql query limit [LOGQL_LIMIT]
  -a, --api <string>        logql api [LOGQL_API]
  -q, --query <string>      logql query [LOGQL_QUERY]
  -t, --labels              get labels
  -v, --label <string>      get label values
  -s, --start <string>      start nanosec timestamp
  -e, --end <string>        end nanosec timestamp
  -x, --tail                tail mode
  -c, --canary              canary mode
  -h, --help                display this help and exit
```

#### ⭐ Examples 
##### Query w/o Labels
```bash
# LOGQL_API="https://cloki:3100" ./vlogql --query '{type="clickhouse"} |~ "MiB"' --limit 5

---------- Logs for: {type="clickhouse"} |~ "MiB"
2022.03.13 10:39:19.765860 [ 29849 ] {} <Debug> MemoryTracker: Peak memory usage (for query): 8.11 MiB.
2022.03.13 10:39:19.761259 [ 29849 ] {115c1357-81d3-4277-ab04-882306f76e9d} <Debug> MemoryTracker: Peak memory usage (for query): 4.12 MiB.
2022.03.13 10:39:19.761288 [ 29849 ] {} <Debug> MemoryTracker: Peak memory usage (for query): 4.12 MiB.
2022.03.13 10:39:19.765798 [ 29849 ] {f050f9e5-f919-4680-b826-ea84be9542e0} <Debug> MemoryTracker: Peak memory usage (for query): 8.11 MiB.
2022.03.13 10:39:19.759982 [ 29849 ] {115c1357-81d3-4277-ab04-882306f76e9d} <Debug> DiskLocal: Reserving 1.00 MiB on disk `default`, having unreserved 2.63 TiB.
```

##### Query w/ Labels
```bash
# LOGQL_API="https://cloki:3100" ./vlogql --query '{type="clickhouse"} |~ "MiB"' --limit 4 --labels

---------- Logs for: {type="clickhouse"} |~ "MiB"
Log Labels: {'pid': '19639', 'level': 'Debug', 'call': 'MemoryTracker', 'type': 'clickhouse'}
2022.03.14 09:53:31.017408 [ 19639 ] {} <Debug> MemoryTracker: Peak memory usage (for query): 4.14 MiB.
2022.03.14 09:53:31.021778 [ 19639 ] {} <Debug> MemoryTracker: Peak memory usage (for query): 8.18 MiB.
2022.03.14 09:53:31.021759 [ 19639 ] {785ba1fa-3be3-4023-8a95-de4b92c096a4} <Debug> MemoryTracker: Peak memory usage (for query): 8.18 MiB.
2022.03.14 09:53:31.017389 [ 19639 ] {a34cbcc9-d11a-4a0a-8c7a-634e00322900} <Debug> MemoryTracker: Peak memory usage (for query): 4.14 MiB.
```
##### Query Labels
```bash
# LOGQL_API="https://cloki:3100" ./vlogql --labels

---------- Labels:
['response', 'host', 'type']
```
##### Query Label Values
```bash
# LOGQL_API="https://cloki:3100" ./vlogql --label type

---------- Values for: type
['clickhouse', 'prometheus']
```

##### Tail Logs by Tag _(websocket)_
```bash
# LOGQL_API="https://cloki:3100" ./vlogql --query '{type="clickhouse"}' --tail

---------- Logs Tail
Log Labels: {'pid': '1658', 'level': 'Debug', 'type': 'clickhouse'}
2022.03.18 16:54:47.634586 [ 1658 ] {} <Debug> system.query_views_log (2bbc858b-05df-49d1-abbc-858b05df69d1): Removing part from filesystem 202203_405891_405891_0
2022.03.18 16:54:51.704528 [ 1658 ] {} <Debug> cloki.time_series (bfb2e93e-f78d-4692-bfb2-e93ef78d8692): Removing part from filesystem 20220318_22425079_22559905_26963
2022.03.18 16:54:51.704730 [ 1658 ] {} <Debug> cloki.time_series (bfb2e93e-f78d-4692-bfb2-e93ef78d8692): Removing part from filesystem 20220318_22559906_22559906_0
2022.03.18 16:54:51.704910 [ 1658 ] {} <Debug> cloki.time_series (bfb2e93e-f78d-4692-bfb2-e93ef78d8692): Removing part from filesystem 20220318_22559907_22559907_0
2022.03.18 16:54:51.705140 [ 1658 ] {} <Debug> cloki.time_series (bfb2e93e-f78d-4692-bfb2-e93ef78d8692): Removing part from filesystem 20220318_22559908_22559908_0
```

##### Canary Logs _(push + websocket)_
```bash
# LOGQL_API="https://cloki:3100" CANARY_TIMER=10 ./vlogql --canary --labels

---------- Tail Canary Logs
PUSH Successful: {"streams":[{"stream": {"canary":"canary_9cwAkBFDlrcA","type":"canary"}, "values":[ ["1649007076406000000", "ts=1649007076406000000 count=3 type=canary tag=canary_9cwAkBFDlrcA"] ]}]}
Sleeping 10 seconds...
Log Labels: {'canary': 'canary_9cwAkBFDlrcA', 'type': 'canary'}
ts=1649007076406000000 count=3 type=canary tag=canary_9cwAkBFDlrcA
PUSH Successful: {"streams":[{"stream": {"canary":"canary_9cwAkBFDlrcA","type":"canary"}, "values":[ ["1649007086482000000", "ts=1649007086482000000 count=4 type=canary tag=canary_9cwAkBFDlrcA"] ]}]}
Sleeping 10 seconds...
Log Labels: {'canary': 'canary_9cwAkBFDlrcA', 'type': 'canary'}
ts=1649007086482000000 count=4 type=canary tag=canary_9cwAkBFDlrcA
```

-----

### License
Licensed under MIT, sponsored by [qxip](https://metrico.in) as part of the [cLoki](https://cloki.org) project
