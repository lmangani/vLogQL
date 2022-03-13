<img src='https://user-images.githubusercontent.com/1423657/147935343-598c7dfd-1412-4bad-9ac6-636994810443.png' style="margin-left:-10px" width=180>

[![vlang-build-pipeline](https://github.com/lmangani/vlogCLI/actions/workflows/vlang.yml/badge.svg)](https://github.com/lmangani/vlogCLI/actions/workflows/vlang.yml)

# vlogCLI
LogQL Client in V


### Build
```
v -o vlogcli -prod vlogcli.v
```

### Usage
```
cloki_client v0.1.0
-----------------------------------------------
Usage: cloki_client [options] [ARGS]

Description: Query LogQL Logs

Options:
  -a, --api <string>        logql api
  -q, --query <string>      logql query
  -n, --num <int>           number of logs to show
  -h, --help                display this help and exit
  --version                 output version information and exit
```
