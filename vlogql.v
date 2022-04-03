module main

import os
import json
import flag
import term
import time
import rand
import net.http
import net.websocket
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

fn now_iso() string {
	mut timestamp := time.now().format_ss_micro().split(' ').join('T') + 'Z'
	return timestamp
}

struct Tail {
mut:
	streams []Result
}

fn tail_logs(server string, query string, show_labels bool) ? {
	socket := server.replace('http', 'ws')
	mut ws := websocket.new_client(socket + '/loki/api/v1/tail?query=' + query) ?
	// use on_open_ref if you want to send any reference object
	ws.on_open(fn (mut ws websocket.Client) ? {
		println('---------- Tail Logs')
	})
	// use on_error_ref if you want to send any reference object
	ws.on_error(fn (mut ws websocket.Client, err string) ? {
		println('---------- Tail error: $err')
	})
	// use on_close_ref if you want to send any reference object
	// ws.on_close(fn (mut ws websocket.Client, code int, reason string) ? {
	//	println('---------- Tail closed')
	// })
	// use on_message_ref if you want to send any reference object
	ws.on_message_ref(fn (mut ws websocket.Client, msg &websocket.Message, show_labels &bool) ? {
		if msg.payload.len > 0 {
			message := msg.payload.bytestr()
			res := json.decode(Tail, message) or { exit(1) }
			for row in res.streams {
				if show_labels {
					print(term.gray('Log Labels: '))
					print(term.bold('$row.stream\n'))
				}
				for log in row.values {
					println(log[1])
				}
			}
		}
	}, show_labels)

	ws.connect() or { println('error on connect: $err') }

	ws.listen() or { println('error on listen $err') }
	unsafe {
		ws.free()
	}
}

fn canary_logs(server string, canary_string string, show_labels bool) ? {
	query := '{canary="$canary_string"}'

	socket := server.replace('http', 'ws')
	mut ws := websocket.new_client(socket + '/loki/api/v1/tail?query=' + query) ?

	ws.on_open(fn (mut ws websocket.Client) ? {
		eprintln('---------- Tail Canary Logs:')
	})
	ws.on_error(fn (mut ws websocket.Client, err string) ? {
		println('---------- Tail error: $err')
	})
	ws.on_message_ref(fn (mut ws websocket.Client, msg &websocket.Message, show_labels &bool) ? {
		if msg.payload.len > 0 {
			message := msg.payload.bytestr()
			res := json.decode(Tail, message) or { exit(1) }
			for row in res.streams {
				if show_labels {
					print(term.gray('Log Labels: '))
					print(term.bold('$row.stream\n'))
				}
				for log in row.values {
					println(log[1])
				}
			}
		}
	}, show_labels)

	ws.connect() or { println('error on connect: $err') }
	ws.listen() or { println('error on listen $err') }
	unsafe {
		ws.free()
	}
}

fn canary_emitter(server string, canary_string string, timer int) ? {
	labels := '{"canary":"$canary_string","type":"canary"}'
	timestamp := now(0)
	log := 'ts=$timestamp type=canary data=1111111111111111111111111111111111111111111111'
	payload := '{"streams":[{"stream": $labels, "values":[ ["$timestamp", "$log"] ]}]}'
	data := http.post_json('$server/loki/api/v1/push', payload) or { exit(1) }
	if data.status_code != 204 {
		eprintln('PUSH error: $data.status_code.str()')
	} else {
		eprintln('PUSH Successful: $payload')
	}
	println('Sleeping $timer seconds...')
	time.sleep(timer * time.second)
	go canary_emitter(server, canary_string, timer)
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	vm := vmod.decode(@VMOD_FILE) or { panic(err.msg) }
	fp.application('$vm.name')
	fp.description('$vm.description')
	fp.version('$vm.version')
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

	logql_tail := fp.bool('tail', `x`, false, 'tail mode')

	logql_canary := fp.bool('canary', `c`, false, 'canary mode')

	fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}

	if utf8_str_len(logql_query) > 0 {
		if logql_tail {
			tail_logs(logql_api, logql_query, logql_labels) or { exit(1) }
		} else if logql_canary {
			mut tag := rand.string_from_set('abcdefghiklmnopqrestuvwzABCDEFGHIKLMNOPQRSTUVWWZX0123456789',
				12)
			tag = 'canary_' + tag
			go canary_emitter(logql_api, tag, 10)
			canary_logs(logql_api, tag, logql_labels) or { exit(1) }
		} else {
			fetch_logs(logql_api, logql_query, logql_limit, logql_labels, logql_start,
				logql_end)
		}
		return
	} else if logql_canary {
		mut tag := rand.string_from_set('abcdefghiklmnopqrestuvwzABCDEFGHIKLMNOPQRSTUVWWZX0123456789',
			12)
		tag = 'canary_' + tag
		go canary_emitter(logql_api, tag, 10)
		canary_logs(logql_api, tag, logql_labels) or { exit(1) }
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
