import os
import json
import flag
import term
import net.http

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

fn fetch_logs(api string, query string, num int, show_labels bool) {
	data := http.get_text('$api/loki/api/v1/query_range?query=$query&limit=$num')
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

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('vlogql')
	fp.version('v0.1.1')
	fp.description('LogQL Query CLI')
	fp.skip_executable()
	env_limit := set_value(os.getenv('LOGQL_LIMIT')) or { '5' }
	logql_limit := fp.int('limit', `l`, env_limit.int(), 'logql query limit [LOGQL_LIMIT]')
	env_api := set_value(os.getenv('LOGQL_API')) or { 'http://localhost:3100' }
	logql_api := fp.string('api', `a`, env_api, 'logql api [LOGQL_API]')
	env_query := set_value(os.getenv('LOGQL_QUERY')) or { '' }
	logql_query := fp.string('query', `q`, env_query, 'logql query [LOGQL_QUERY]')
	logql_labels := fp.bool('labels', `t`, false, 'get labels')
	logql_label := fp.string('label', `v`, '', 'get label values')

	fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}

	if utf8_str_len(logql_query) > 0 {
		// println('Fetching logs...')
		fetch_logs(logql_api, logql_query, logql_limit, logql_labels)
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
