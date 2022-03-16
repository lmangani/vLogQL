module main 

import os
import json
import flag
import term
import time
import net.http
import v.vmod

struct Response {
mut:
	status string
	data   Data
}

struct Data {
mut:
	res_type string   [json: 'resultType']
	result   []Result
}

struct Result {
mut:
	stream map[string]string
	values [][]string
}

struct Values {
	ts  int
	log string
}

fn fetch_logs(api string, query string, num int, show_labels bool, start string, end string) {
	data := http.get_text('$api/loki/api/v1/query_range?query=$query&limit=$num&start=$start&end=$end')
	res := json.decode(Response, data) or { exit(1) }
	println('---------- Logs for: $query')
	for row in res.data.result {
		if show_labels {
			print(term.gray('Log Labels: '))
			print(term.bold('$row.stream\n'))
		}
		for log in row.values {
			println(log[1])
		}
	}
	return
}

struct Labels {
	status string
	data   []string
}

fn fetch_labels(api string, label string) {
	if utf8_str_len(label) > 0 {
		data := http.get_text('$api/loki/api/v1/label/$label/values')
		res := json.decode(Labels, data) or { exit(1) }
		println('---------- Values for: $label')
		println(term.bold(res.data.str()))
		return
	} else {
		data := http.get_text('$api/loki/api/v1/labels')
		res := json.decode(Labels, data) or { exit(1) }
		println('---------- Labels:')
		println(term.bold(res.data.str()))
		return
	}
}

fn set_value(s string) ?string {
	if s != '' {
		return s
	}
	return none
}

fn now(diff int) string {
	ts := time.utc()
	subts := ts.unix_time_milli() - (diff * 1000)
	return '${subts}000000'
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	mod := vmod.from_file('./v.mod') or { panic(err) }
	fp.application(mod.name)
	fp.version(mod.version)
	fp.description(mod.description)
	fp.skip_executable()
	env_limit := set_value(os.getenv('LOGQL_LIMIT')) or { '5' }
	logql_limit := fp.int('limit', `l`, env_limit.int(), 'logql query limit [LOGQL_LIMIT]')
	env_api := set_value(os.getenv('LOGQL_API')) or { 'http://localhost:3100' }
	logql_api := fp.string('api', `a`, env_api, 'logql api [LOGQL_API]')
	env_query := set_value(os.getenv('LOGQL_QUERY')) or { '' }
	logql_query := fp.string('query', `q`, env_query, 'logql query [LOGQL_QUERY]')
	logql_labels := fp.bool('labels', `t`, false, 'get labels')
	logql_label := fp.string('label', `v`, '', 'get label values')

	logql_start := fp.string('start', `s`, now(3600), 'start nanosec timestamp')
	logql_end := fp.string('end', `e`, now(0), 'end nanosec timestamp')

	fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}

	if utf8_str_len(logql_query) > 0 {
		fetch_logs(logql_api, logql_query, logql_limit, logql_labels, logql_start, logql_end)
		return
	} else if logql_labels {
		fetch_labels(logql_api, '')
		return
	} else if utf8_str_len(logql_label) > 0 {
		fetch_labels(logql_api, logql_label)
		return
	} else {
		println(fp.usage())
		return
	}
}
