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

struct App {
mut:
	counter string = '0'
	last    string = '0'
	last_ts string = '0'
	diff_ts string = '0'
	api     string = '0'
	query   string = '0'
	limit   int
	start   string = '0'
	end     string = '0'
	labels  bool
	debug   bool
	timer   int
}

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

fn get_rand(len int) string {
	return rand.string_from_set('abcdefghiklmnopqrestuvwzABCDEFGHIKLMNOPQRSTUVWWZX0123456789',
		len)
}

struct Tail {
mut:
	streams []Result
}

fn canary_logs(mut app App, canary_string string) ? {
	query := '{canary="$canary_string"}'

	socket := app.api.replace('http', 'ws')
	mut ws := websocket.new_client(socket + '/loki/api/v1/tail?query=' + query) ?

	ws.on_open(fn (mut ws websocket.Client) ? {
		println('---------- Tail Canary Logs')
	})
	ws.on_error(fn (mut ws websocket.Client, err string) ? {
		eprintln('---------- Tail error: $err')
	})
	ws.on_message_ref(fn (mut ws websocket.Client, msg &websocket.Message, mut app App) ? {
		if msg.payload.len > 0 {
			diff_ts := now(0).i64() - app.last_ts.i64()
			app.diff_ts = diff_ts.str()
			message := msg.payload.bytestr()
			res := json.decode(Tail, message) or { exit(1) }
			for row in res.streams {
				if app.labels {
					print(term.gray('Log Labels: '))
					print(term.bold('$row.stream\n'))
				}
				for log in row.values {
					println(log[1])
					if log[1] != app.last {
						eprintln('>>>>>>>>>> Out of order log! log=$app.last')
					}
					if log[0] != app.last_ts {
						eprintln('>>>>>>>>>> Out of order timestamp! last_ts=$app.last_ts')
					}
					if app.diff_ts.len > 9 {
						eprintln('>>>>>>>>>> High latency! diff_ts=$app.diff_ts')
					}
				}
			}
		}
	}, app)

	ws.connect() or { eprintln('error on connect: $err') }
	ws.listen() or { eprintln('error on listen $err') }
	unsafe {
		ws.free()
	}
}

fn canary_emitter(mut app App, canary_string string, timer int, count int) ? {
	labels := '{"canary":"$canary_string","type":"canary"}'
	timestamp := now(0)
	mut log := 'ts=$timestamp count=$count type=canary tag=$canary_string delay=$app.diff_ts'
	payload := '{"streams":[{"stream": $labels, "values":[ ["$timestamp", "$log"] ]}]}'
	data := http.post_json('$app.api/loki/api/v1/push', payload) or { exit(1) }
	if data.status_code != 204 {
		eprintln('PUSH error: $data.status_code')
	} else {
		// println('PUSH successful: $data.status_code')
	}
	next := count + 1
	app.counter = (app.counter.int() + 1).str()
	app.last = log
	app.last_ts = timestamp
	time.sleep(timer * time.second)
	go canary_emitter(mut app, canary_string, timer, next)
}

fn main() {
	mut app := &App{}
	app.counter = (0).str()
	mut fp := flag.new_flag_parser(os.args)
	vm := vmod.decode(@VMOD_FILE) or { panic(err.msg()) }
	fp.application('$vm.name (canary)')
	fp.description('$vm.description (canary)')
	fp.version('$vm.version')
	fp.skip_executable()

	env_api := set_value(os.getenv('LOGQL_API')) or { '' }
	logql_api := fp.string('api', `a`, env_api, 'logql api [LOGQL_API]')
	app.api = logql_api
	app.labels = true

	env_canary_label := set_value(os.getenv('CANARY_LABEL')) or { '' }
	logql_canary_label := fp.string('label', `l`, env_canary_label, 'custom canary label [CANARY_LABEL]')
	env_canary_timer := set_value(os.getenv('CANARY_TIMER')) or { '10' }
	logql_canary_timer := fp.int('timer', `t`, env_canary_timer.int(), 'custom canary timer [CANARY_TIMER]')

	fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}

	if app.api.len > 1 {
		mut tag := logql_canary_label
		if logql_canary_label.len < 1 {
			tag = get_rand(12)
		}
		tag = 'canary_' + tag
		go canary_emitter(mut app, tag, logql_canary_timer, 0)
		canary_logs(mut app, tag) or { exit(1) }
	} else {
		println(fp.usage())
		return
	}
}
