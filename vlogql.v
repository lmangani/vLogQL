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
        println('---------- Logs for: ${query}')
        for row in res.data.result {
	  // TODO: parse & display labels
          // println('Labels: ${row.stream}')
          for log in row.values {
             println(log[1])
          }
        }
        return
}

struct Labels {
        status string
        data []string
}

fn fetch_labels(api string, label string) {
     if utf8_str_len(label) > 0 {
        data := http.get_text('${api}/loki/api/v1/label/${label}/values')
        res := json.decode(Labels, data) or { exit(1) }
        println('---------- Values for: ${label}')
        println(res.data)
        return

     } else {
        data := http.get_text('${api}/loki/api/v1/labels')
        res := json.decode(Labels, data) or { exit(1) }
        println('---------- Labels:')
        println(res.data)
        return
     }
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
        logql_labels := fp.bool('labels', `t`, false, 'get labels')
        logql_label := fp.string('label', `v`, '', 'get label values')

        fp.finalize() or {
                eprintln(err)
                println(fp.usage())
                return
        }

	if logql_labels {
          fetch_labels(logql_api, '')
	}
	else if utf8_str_len(logql_label) > 0 {
          fetch_labels(logql_api, logql_label)
	}
	else if utf8_str_len(logql_query) > 0 {
          println('Fetching logs...')
          fetch_logs(logql_api, logql_query, logql_limit)
	} else {
                println(fp.usage())
		return
	}

}
