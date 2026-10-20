## CoopNetTest — the headless two-process network test of CoopNet (GDD §15.0
## "Online co-op: relay and lobby"). Main adds it instead of the menu when the
## command line has `--coop-net-test=host|join`; tools/coop_net_test.py runs a
## host and a join process against the local relay (tools/coop_relay.py):
##   1. the host opens a lobby and prints `COOP_CODE=<code>`; the join process
##      (`--coop-code=<code>`) joins it by that code;
##   2. both send their loadouts (CoopNet.make_loadout(), names TestHost /
##      TestGuest), the host its settings, the guest presses Ready, the host
##      starts with seed TEST_SEED; each checks start_info (seed, stage, both
##      loadouts, its own seat) and prints a hash of it without the seat, so the
##      runner can show both machines got the same start info;
##   3. each sends `--coop-frames=N` numbered frames (default 10000) paced at
##      `--coop-rate=R` frames per second (default 240) while CoopNet's pings
##      run, then an end marker; each checks every received frame's sequence
##      number (order) and payload checksum (integrity);
##   4. each prints one `COOP_NET_RESULT ...` line (frames, errors, round-trip
##      min / mean / p95 / max) and quits with 0 when everything passed; the
##      guest quits first and the host must then see `partner_left`.
## `--coop-net-test=errors` instead checks the client's error paths one after
## another: a short code (bad_code, no connection), a code with no lobby
## (no_lobby, from the relay) and a relay nobody listens on (unreachable).
## A frame is [seq u32][len u16][len payload bytes][checksum u32], little
## endian; the payload is a pseudo-random function of seq, so the receiver can
## rebuild it. Network timing (Time) only: nothing here is gameplay.
class_name CoopNetTest
extends Node

## Seed the host starts the test run with.
const TEST_SEED: int = 424242
## Stage of the test settings.
const TEST_STAGE: String = "graveyard"
## Sequence number of the end marker frame.
const END_SEQ: int = 0xFFFFFFFF
## Seconds before the test gives up.
const TIMEOUT_S: float = 240.0
## Payload length range of a frame (bytes): 8 + seq % PAYLOAD_SPREAD.
const PAYLOAD_MIN: int = 8
const PAYLOAD_SPREAD: int = 57
## Seconds to linger after finishing so the partner's last frames arrive.
const LINGER_S: float = 1.0
## Seconds the host waits for `partner_left` once the guest has finished.
const LEFT_WAIT_S: float = 15.0
## Seconds one error case may take.
const ERROR_CASE_S: float = 12.0
## The error cases: [code to join, relay override ("" = the test relay), expected error].
const ERROR_CASES: Array = [
	["BC", "", "bad_code"],
	["BBBBB", "", "no_lobby"],
	["BCDFG", "ws://127.0.0.1:9", "unreachable"],
]

## "host" or "join".
var _role: String = ""
## Frames to send (and expect).
var _total: int = 10000
## Send pace (frames per second).
var _rate: float = 240.0
## Frames sent so far.
var _sent: int = 0
## Next expected sequence number.
var _expect: int = 0
## Frames received (not counting the end marker).
var _received: int = 0
## Frames out of order / with a bad payload.
var _order_errors: int = 0
var _integrity_errors: int = 0
## True once the partner's end marker arrived.
var _partner_done: bool = false
## True once our own end marker went out.
var _end_sent: bool = false
## When the frame exchange began (ms).
var _start_ms: int = 0
## When the test began (ms).
var _begin_ms: int = 0
## Round-trip samples (ms).
var _rtts: Array[float] = []
## True once the start info was checked.
var _started: bool = false
## Failures (text), printed with the result.
var _fails: PackedStringArray = PackedStringArray()
## Seconds left to linger once done (-1 = not done).
var _linger: float = -1.0
## True once the result was printed.
var _reported: bool = false
## True once CoopNet emitted partner_left.
var _partner_left: bool = false
## Seconds the host has waited for partner_left (-1 = not waiting).
var _left_wait: float = -1.0
## Errors role: the last error code raised ("" = none yet).
var _last_error: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_role = CoopNet.cli_test_role()
	_total = maxi(1, int(_arg("--coop-frames=", "10000")))
	_rate = maxf(1.0, float(_arg("--coop-rate=", "240")))
	_begin_ms = Time.get_ticks_msec()
	CoopNet.error_raised.connect(_on_error)
	CoopNet.lobby_changed.connect(_on_lobby)
	CoopNet.run_started.connect(_on_started)
	CoopNet.frame_received.connect(_on_frame)
	CoopNet.partner_left.connect(func() -> void: _partner_left = true)
	CoopNet.latency_measured.connect(func(ms: float) -> void: _rtts.append(ms))
	var cfg := RunConfig.for_stage(TEST_STAGE)
	if _role == "errors":
		_run_errors()
	elif _role == "host":
		cfg.set_character("bone_oracle")
		CoopNet.host(CoopNet.make_loadout(cfg, "TestHost"))
	elif _role == "join":
		cfg.set_character("wither_witch")
		CoopNet.join(_arg("--coop-code=", ""), CoopNet.make_loadout(cfg, "TestGuest"))
	else:
		_fail("unknown role '%s'" % _role)


## Value of command-line argument `prefix` or `fallback`.
static func _arg(prefix: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return fallback


## Records failure `why` and finishes.
func _fail(why: String) -> void:
	_fails.append(why)
	_report()


## An error from CoopNet: expected in the errors role, a failure otherwise.
func _on_error(c: String, t: String) -> void:
	if _role == "errors":
		_last_error = c
	else:
		_fail("error %s: %s" % [c, t])


## The errors role: every ERROR_CASES entry must raise its error.
func _run_errors() -> void:
	var lo := CoopNet.make_loadout(RunConfig.new(), "TestErrors")
	for c: Array in ERROR_CASES:
		_last_error = ""
		CoopNet.relay_override = String(c[1])
		CoopNet.join(String(c[0]), lo)
		var t0 := Time.get_ticks_msec()
		while _last_error == "" and float(Time.get_ticks_msec() - t0) / 1000.0 < ERROR_CASE_S:
			await get_tree().process_frame
		print("COOP_ERROR_CASE code=%s expected=%s got=%s state=%d" % [c[0], c[2], _last_error, CoopNet.state])
		if _last_error != String(c[2]):
			_fails.append("%s: expected %s, got '%s'" % [c[0], c[2], _last_error])
		CoopNet.leave()
	CoopNet.relay_override = ""
	_reported = true
	var ok := _fails.is_empty()
	print("COOP_NET_RESULT role=errors ok=%s cases=%d%s" % [str(ok), ERROR_CASES.size(), "" if ok else " fails=" + "; ".join(_fails)])
	get_tree().quit(0 if ok else 1)


## Lobby progress: the host prints the code, sends settings and starts once
## the guest is ready; the guest presses Ready once the host's settings came.
func _on_lobby() -> void:
	if _started or _reported:
		return
	if _role == "host":
		if CoopNet.code != "" and CoopNet.settings.is_empty():
			print("COOP_CODE=%s" % CoopNet.code)
			CoopNet.set_settings(CoopNet.config_dict(RunConfig.for_stage(TEST_STAGE)))
		if CoopNet.can_start():
			CoopNet.start_run(TEST_SEED)
	elif CoopNet.has_partner() and not CoopNet.settings.is_empty() and not bool(CoopNet.ready_flags[1]):
		CoopNet.set_ready(true)


## The run started: check start_info, print its hash, begin the frames.
func _on_started(info: Dictionary) -> void:
	_started = true
	var slot := 0 if _role == "host" else 1
	if int(info.get("seed", -1)) != TEST_SEED:
		_fails.append("seed %s" % str(info.get("seed")))
	if int(info.get("local_slot", -1)) != slot:
		_fails.append("local_slot %s" % str(info.get("local_slot")))
	if String((info.get("config", {}) as Dictionary).get("stage_id", "")) != TEST_STAGE:
		_fails.append("stage")
	var los: Array = info.get("loadouts", [])
	if los.size() != 2 or String((los[0] as Dictionary).get("name", "")) != "TestHost" \
			or String((los[1] as Dictionary).get("name", "")) != "TestGuest" \
			or String((los[0] as Dictionary).get("character_id", "")) != "bone_oracle" \
			or String((los[1] as Dictionary).get("character_id", "")) != "wither_witch":
		_fails.append("loadouts %s" % JSON.stringify(los))
	if String(info.get("version", "")) != CoopNet.game_version():
		_fails.append("version")
	var same := info.duplicate(true)
	same.erase("local_slot")
	print("COOP_START_HASH=%s" % JSON.stringify(same, "", true).md5_text())
	var cfg := CoopNet.run_config_for(info, slot)
	print("COOP_RUN_CONFIG stage=%s character=%s" % [cfg.stage_id, cfg.character_id])
	_start_ms = Time.get_ticks_msec()


func _process(delta: float) -> void:
	if _reported:
		return
	if float(Time.get_ticks_msec() - _begin_ms) / 1000.0 > TIMEOUT_S:
		_fail("timeout (sent %d, received %d)" % [_sent, _received])
		return
	if not _started:
		return
	var due := mini(_total, int(float(Time.get_ticks_msec() - _start_ms) / 1000.0 * _rate) + 1)  # Frames due by now.
	while _sent < due:
		if not CoopNet.send_frame(_frame(_sent)):
			_fail("send_frame failed at %d" % _sent)
			return
		_sent += 1
	if _sent >= _total and not _end_sent:
		_end_sent = CoopNet.send_frame(_frame(END_SEQ))
	if _end_sent and _partner_done and _linger < 0.0:
		_linger = LINGER_S
	if _linger >= 0.0 and _left_wait < 0.0:
		_linger -= delta
		if _linger <= 0.0:
			if _role == "host":
				_left_wait = 0.0  # The guest quits first: wait for partner_left.
			else:
				_report()
	if _left_wait >= 0.0:
		_left_wait += delta
		if _partner_left or _left_wait > LEFT_WAIT_S:
			if not _partner_left:
				_fails.append("no partner_left after the guest quit")
			_report()


## Frame `seq`: header, the pseudo-random payload and its checksum.
static func _frame(seq: int) -> PackedByteArray:
	var payload := _payload(seq)
	var b := PackedByteArray()
	b.resize(6 + payload.size() + 4)
	b.encode_u32(0, seq)
	b.encode_u16(4, payload.size())
	for i in payload.size():
		b[6 + i] = payload[i]
	b.encode_u32(6 + payload.size(), _checksum(payload))
	return b


## The payload of frame `seq` (a small LCG stream seeded by seq).
static func _payload(seq: int) -> PackedByteArray:
	var n := PAYLOAD_MIN + (seq % PAYLOAD_SPREAD if seq != END_SEQ else 0)
	var p := PackedByteArray()
	p.resize(n)
	var x := (seq * 2654435761 + 12345) & 0xFFFFFFFF
	for i in n:
		x = (x * 1103515245 + 12345) & 0x7FFFFFFF
		p[i] = (x >> 16) & 0xFF
	return p


## FNV-1a hash of `p` (32 bit).
static func _checksum(p: PackedByteArray) -> int:
	var h := 2166136261
	for v in p:
		h = ((h ^ v) * 16777619) & 0xFFFFFFFF
	return h


## A frame from the partner: order and integrity checks.
func _on_frame(bytes: PackedByteArray) -> void:
	if bytes.size() < 10:
		_integrity_errors += 1
		return
	var seq := bytes.decode_u32(0)
	var n := bytes.decode_u16(4)
	if bytes.size() != 10 + n:
		_integrity_errors += 1
		return
	var payload := bytes.slice(6, 6 + n)
	if bytes.decode_u32(6 + n) != _checksum(payload) or payload != _payload(seq):
		_integrity_errors += 1
	if seq == END_SEQ:
		_partner_done = true
		if _received != _total:
			_fails.append("end marker after %d of %d frames" % [_received, _total])
		return
	if seq != _expect:
		_order_errors += 1
	_expect = seq + 1
	_received += 1


## Prints the result line and quits (0 = passed).
func _report() -> void:
	if _reported:
		return
	_reported = true
	var sorted := _rtts.duplicate()
	sorted.sort()
	var mean := 0.0
	for v: float in sorted:
		mean += v
	mean = mean / float(maxi(1, sorted.size()))
	var p95: float = sorted[clampi(int(ceil(0.95 * float(sorted.size()))) - 1, 0, sorted.size() - 1)] if not sorted.is_empty() else -1.0  # 95th percentile round trip (ms).
	var secs := float(Time.get_ticks_msec() - _start_ms) / 1000.0 if _start_ms > 0 else 0.0
	if _received != _total:
		_fails.append("received %d of %d" % [_received, _total])
	if _order_errors > 0 or _integrity_errors > 0:
		_fails.append("order %d integrity %d" % [_order_errors, _integrity_errors])
	if sorted.is_empty():
		_fails.append("no round-trip samples")
	var ok := _fails.is_empty()
	print("COOP_NET_RESULT role=%s ok=%s sent=%d received=%d order_errors=%d integrity_errors=%d seconds=%.1f rtt_samples=%d rtt_min=%.1f rtt_mean=%.1f rtt_p95=%.1f rtt_max=%.1f%s" % [
		_role, str(ok), _sent, _received, _order_errors, _integrity_errors, secs, sorted.size(),
		sorted.front() if not sorted.is_empty() else -1.0, mean, p95, sorted.back() if not sorted.is_empty() else -1.0,
		"" if ok else " fails=" + "; ".join(_fails)])
	CoopNet.leave()
	get_tree().quit(0 if ok else 1)
