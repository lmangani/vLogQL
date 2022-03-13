import os
import json
import flag
import net.http

struct Response {
mut:
        status string
        data Data
}

struct Data {
mut:
        res_type string [json:'resultType']
        result []Result
}

struct Result {
mut:
        stream string
        values [][]string
}

struct Values {
        ts int
        log string
}

fn fetch_logs(api string, query string, num int) {
        data := http.get_text('${api}/loki/api/v1/query_range?query=${query}&limit=${num}')
        res := json.decode(Response, data) or { exit(1) }
        for row in res.data.result {
          // println('Labels: ${row.stream}')
          for log in row.values {
             println(log[1])
          }
        }
        println('----------')
        return
}

fn main() {
        mut fp := flag.new_flag_parser(os.args)
        fp.application('vlogql')
        fp.version('v0.1.0')
        fp.description('Query LogQL Logs')
        fp.skip_executable()
        logql_limit := fp.int('limit', `l`, 5, 'number of logs to show')
        logql_api := fp.string('api', `a`, 'http://localhost:3100', 'logql api')
        logql_query := fp.string('query', `q`, '', 'logql query')

        fp.finalize() or {
                eprintln(err)
                println(fp.usage())
                return
        }

        println('Fetching logs...')
        fetch_logs(logql_api, logql_query, logql_limit)

}
