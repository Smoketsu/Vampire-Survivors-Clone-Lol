## CoopNet — the co-op connection (autoload "CoopNet"; docs/coop/DESIGN.md
## "Interfaces"; GDD §15.0 "Online co-op: relay and lobby"). It owns the one
## WebSocket to the relay (server/relay, protocol in server/relay/PROTOCOL.md),
## the lobby state (code, the two seats, their loadouts and ready flags, the
## host's run settings, the round-trip time) and the start message. It never
## touches gameplay: the lockstep driver (agent "sim", scripts/coop/) reads
## `start_info` and exchanges its tick frames through send_frame() /
## `frame_received`; the lobby screens (CoopScreen, CoopLobby) drive the rest.
##
## Transport: Godot's WebSocketPeer (the browser's WebSocket on the Web build,
## native on desktop), polled from _process() (and poll(), which the lockstep
## driver may call more often); nothing ever blocks. Text messages are JSON
## control messages, binary messages are the opaque frames, all on one ordered
## stream. With no co-op session nothing of this runs: processing stays off
## until host() / join() and goes off again on leave() or a closed socket, so
## solo runs and the autotest are untouched.
##
## Lobby flow: host() opens `/lobby/new/ws` (the relay makes the code), join()
## opens `/lobby/CODE/ws`; both send a hello (protocol, game version,
## platform, name). The relay refuses another game version (and CoopNet
## refuses another platform while CoopNetData.ALLOW_MIXED_PLATFORMS is off).
## Each side sends its loadout (make_loadout(): character, skin, ultimate,
## title, Ossuary levels, unlocks, name) whenever it changes; the host sends
## its run settings (config_dict(): stage, difficulty, modifiers, Hyper, Oath),
## which un-readies the guest. The guest's Ready, then the host's start_run(),
## send `start` with the start info; both machines set the same `start_info`
## (built once on the host and passed through the same JSON round trip on both
## sides, so even its number types match) except `local_slot`, and emit
## `run_started`. Partner pings every CoopNetData.PING_INTERVAL s measure the
## round trip (`latency_measured`).
##
## Command line (desktop, after `--`): `--relay=ws://host:port` overrides the
## relay address (CoopNetData.RELAY_URL); the Web build reads `?relay=` from the
## page address the same way, and `?join=CODE` (a shared link) opens the Join pad
## filled in. `--coop-net-test=host|join` (with `--coop-code=`, see CoopNetTest)
## runs the headless two-process network test instead of the menu.
extends Node

## A frame from the partner (opaque bytes, in the order they were sent).
signal frame_received(bytes: PackedByteArray)
## The partner left the lobby or the run (closed the game, lost its connection, pressed Leave).
signal partner_left
## Our own connection to the relay closed unexpectedly (lobby or run).
signal connection_lost
## A partner ping came back: the round trip through the relay (ms).
signal latency_measured(rtt_ms: float)
## The connection state changed (State value).
signal state_changed(state: int)
## Anything shown in the lobby changed (seats, loadouts, ready flags, settings, ping).
signal lobby_changed
## A partner took the other seat.
signal partner_joined
## Something failed: `code` (CoopNetData.ERROR_TEXT key) and the line to show.
signal error_raised(code: String, text: String)
## The host started the run: `info` is start_info (both machines).
signal run_started(info: Dictionary)

## Connection states.
##   OFFLINE   : no co-op session (the default; nothing processes).
##   CONNECTING: the socket is opening or the hello awaits the welcome.
##   LOBBY     : seated in a lobby (alone or with a partner).
##   STARTED   : the run began (start_info is set).
##   CLOSED    : the socket closed (after an error or a lost connection).
enum State { OFFLINE, CONNECTING, LOBBY, STARTED, CLOSED }

## Current connection state.
var state: State = State.OFFLINE
## Lobby code (CoopNetData.CODE_LENGTH letters; "" until the welcome).
var code: String = ""
## Our seat: 0 = host, 1 = guest, -1 = none.
var local_slot: int = -1
## The start message (set on both machines when the host starts; {} before):
## {"seed": int, "config": Dictionary (config_dict()), "loadouts": [slot0, slot1],
## "local_slot": int, "version": String}.
var start_info: Dictionary = {}
## The host's run settings (config_dict() form; {} until the host sends them).
var settings: Dictionary = {}
## Loadout per seat (make_loadout() form; {} = seat empty or not sent yet).
var loadouts: Array = [{}, {}]
## Ready flag per seat (the host's is always treated as ready).
var ready_flags: Array = [false, false]
## Hello fields per seat from the relay: {"slot", "game", "platform", "name"} ({} = empty seat).
var peers: Array = [{}, {}]
## Smoothed round trip to the partner through the relay (ms; -1 = not measured yet).
var rtt_ms: float = -1.0
## The partner's own smoothed round trip, from its pings (ms; -1 = unknown).
var partner_rtt_ms: float = -1.0
## Last error code raised ("" = none since the last host() / join()).
var last_error: String = ""
## Relay address in use (relay_address()).
var relay_url: String = ""
## Relay address that wins over relay_address() when set ("" = none; the network test's unreachable case).
var relay_override: String = ""
## Frames sent / received since the last host() / join() (counts, for reports).
var frames_sent: int = 0
var frames_received: int = 0

## The socket (null while OFFLINE / CLOSED).
var _ws: WebSocketPeer = null
## True once the hello went out on the open socket.
var _hello_sent: bool = false
## Loadout to send once seated (also our hello's name).
var _pending_loadout: Dictionary = {}
## When connecting began (ms, Time.get_ticks_msec(); network timing only, never gameplay).
var _connect_ms: int = 0
## True once the relay sent an error (the close that follows raises nothing more).
var _got_error: bool = false
## Next ping id.
var _ping_id: int = 0
## Ping id -> send time (usec) of the unanswered pings.
var _ping_sent: Dictionary = {}
## Seconds until the next ping.
var _ping_timer: float = 0.0
## Last time anything came from the partner (ms; 0 = never).
var _partner_heard_ms: int = 0
## True once take_link_code() was called (the shared link is used once).
var _link_taken: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Level-ups and pauses stop the tree, never the connection.
	set_process(false)  # Nothing at all runs until host() / join().


func _process(delta: float) -> void:
	poll()
	if state == State.LOBBY or state == State.STARTED:
		_ping_timer -= delta
		if _ping_timer <= 0.0 and has_partner():
			_ping_timer = CoopNetData.PING_INTERVAL
			_send_ping()


# =====================================================================================
# Public API (lobby screens, the lockstep driver, the network test)
# =====================================================================================

## Opens a new lobby as its host with `loadout` (make_loadout()). Errors come
## through `error_raised`; the welcome turns the state to LOBBY.
func host(loadout: Dictionary) -> void:
	_open("new", loadout)


## Joins lobby `p_code` (letters, any case; spaces ignored) with `loadout`.
func join(p_code: String, loadout: Dictionary) -> void:
	var c := normalize_code(p_code)
	if not is_valid_code(c):
		_raise("bad_code")
		return
	_open(c, loadout)


## Leaves the lobby or run on purpose: tells the relay, closes the socket and
## forgets the session (no signals).
func leave() -> void:
	if _ws != null:
		if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			_send_json({"t": "leave"})
			_ws.poll()
		_ws.close(1000, "leave")
	_ws = null
	_reset_session()
	_set_state(State.OFFLINE)
	set_process(false)


## Pushes the socket and handles everything that arrived (called every frame
## while a session exists; the lockstep driver may call it more often).
func poll() -> void:
	if _ws == null:
		return
	_ws.poll()
	# Everything received is read first, whatever the state: a relay that refuses at once (no lobby, full...)
	# sends its error and closes within one poll, and the error must not be lost to the close.
	while _ws != null and _ws.get_available_packet_count() > 0:
		var pkt := _ws.get_packet()  # One whole message.
		if _ws.was_string_packet():
			_on_text(pkt.get_string_from_utf8())
		else:
			frames_received += 1
			_partner_heard_ms = Time.get_ticks_msec()
			frame_received.emit(pkt)
	if _ws == null:
		return
	match _ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _hello_sent:
				_send_hello()
			if state == State.CONNECTING and Time.get_ticks_msec() - _connect_ms > int(CoopNetData.CONNECT_TIMEOUT * 1000.0):
				_fail("unreachable")
		WebSocketPeer.STATE_CONNECTING:
			if Time.get_ticks_msec() - _connect_ms > int(CoopNetData.CONNECT_TIMEOUT * 1000.0):
				_fail("unreachable")
		WebSocketPeer.STATE_CLOSED:
			_on_closed()


## Sends one opaque frame to the partner (binary, ordered, reliable). False
## when there is no open connection or the frame is over the relay's limit.
func send_frame(bytes: PackedByteArray) -> bool:
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN or local_slot < 0:
		return false
	if bytes.size() > CoopNetData.MAX_MESSAGE_BYTES:
		push_error("CoopNet.send_frame: %d bytes is over the relay limit" % bytes.size())
		return false
	if _ws.send(bytes, WebSocketPeer.WRITE_MODE_BINARY) != OK:
		return false
	frames_sent += 1
	return true


## Replaces our loadout (make_loadout() form) and sends it to the partner.
func set_loadout(loadout: Dictionary) -> void:
	if local_slot < 0:
		_pending_loadout = loadout.duplicate(true)
		return
	loadouts[local_slot] = _clean_loadout(loadout, local_slot)
	_send_loadout()
	lobby_changed.emit()


## Guest: sets our Ready flag and tells the host.
func set_ready(on: bool) -> void:
	if local_slot != 1 or state != State.LOBBY:
		return
	ready_flags[1] = on
	_send_loadout()
	lobby_changed.emit()


## Host: replaces the run settings (config_dict() form) and sends them; the
## guest has to press Ready again.
func set_settings(config: Dictionary) -> void:
	if local_slot != 0:
		return
	settings = config.duplicate(true)
	ready_flags[1] = false
	if has_partner():
		_send_json({"t": "settings", "config": settings})
	lobby_changed.emit()


## True when the host may start: seated, a partner present, the partner ready
## and both loadouts and the settings known.
func can_start() -> bool:
	return local_slot == 0 and state == State.LOBBY and has_partner() and bool(ready_flags[1]) \
			and not (loadouts[0] as Dictionary).is_empty() and not (loadouts[1] as Dictionary).is_empty() \
			and not settings.is_empty()


## Host: starts the run with seed `p_seed` (-1 = a fresh random one). Sends
## the start info and sets start_info here too. False when can_start() is not met.
func start_run(p_seed: int = -1) -> bool:
	if not can_start():
		return false
	var s := p_seed
	if s < 0:
		var r := RandomNumberGenerator.new()  # Own generator: the global RNG is never touched.
		r.randomize()
		s = r.randi() % 2147483647
	var info := {"seed": s, "config": settings, "loadouts": [loadouts[0], loadouts[1]],
		"local_slot": 0, "version": game_version()}
	var text := JSON.stringify({"t": "start", "info": info})  # The exact message the guest gets.
	_ws.send_text(text)
	var echo: Variant = JSON.parse_string(text)  # The same round trip as on the guest.
	_begin_run((echo as Dictionary)["info"] as Dictionary, 0)
	return true


## True while a partner holds the other seat.
func has_partner() -> bool:
	return local_slot >= 0 and not (peers[1 - local_slot] as Dictionary).is_empty()


## True when we are the host.
func is_host() -> bool:
	return local_slot == 0


## True while a co-op session exists (connecting, in a lobby or in a run).
func active() -> bool:
	return state == State.CONNECTING or state == State.LOBBY or state == State.STARTED


## Seconds since anything last came from the partner (pings arrive every
## CoopNetData.PING_INTERVAL s; INF before the partner was ever heard).
func partner_quiet_seconds() -> float:
	if _partner_heard_ms == 0:
		return INF
	return float(Time.get_ticks_msec() - _partner_heard_ms) / 1000.0


## The line to show for error `err` (CoopNetData.ERROR_TEXT), with `detail` where it has a %s.
static func error_text(err: String, detail: String = "") -> String:
	var t := String(CoopNetData.ERROR_TEXT.get(err, CoopNetData.ERROR_FALLBACK))
	if t.contains("%s"):
		return t % (detail if detail != "" else err)
	return t


# =====================================================================================
# Loadouts, settings, start info (static helpers; also used by the sim's hook)
# =====================================================================================

## Our loadout from `config` (character, skin, ultimate) and the Meta save
## (worn title, Ossuary levels, Act II unlocks), named `player_name`.
static func make_loadout(config: RunConfig, player_name: String = "") -> Dictionary:
	var levels := {}  # Upgrade id -> purchased tier.
	for id: String in Meta.tiers:
		levels[id] = int(Meta.tiers[id])
	var unlocks: Array = []  # Unlocked item ids, sorted (same order on every machine).
	for id: String in Meta.unlocked_items:
		unlocks.append(id)
	unlocks.sort()
	var masteries := {}  # Summon class id -> Mastery level (Ossuary Masteries).
	for cls: String in MasteryData.CLASSES:
		if Meta.mastery_level(cls) > 0:
			masteries[cls] = Meta.mastery_level(cls)
	return {"character_id": config.character_id, "skin_id": config.skin_id, "recolour_id": config.recolour_id, "ultimate_id": config.ultimate_id,
		"title_id": Meta.selected_title(), "meta_levels": levels, "mastery_levels": masteries, "unlocks": unlocks, "name": player_name}


## The host's run settings from `config`: stage, difficulty, modifiers, Hyper,
## the host's active Profane Oath tier (DESIGN.md: it sets the run's Oath) and
## the host's Volleys setting (the bullet heaven pass changes the simulation,
## so both machines play the host's; Game._ready()).
static func config_dict(config: RunConfig) -> Dictionary:
	return {"stage_id": config.stage_id, "difficulty_id": config.difficulty_id,
		"modifiers": Array(config.modifiers), "hyper": config.hyper, "oath": Meta.oath_active_tier(),
		"volleys": Settings.volleys}


## A RunConfig for seat `slot` of start info `info`: the host's stage,
## difficulty, modifiers and Hyper with that seat's character, skin and ultimate.
static func run_config_for(info: Dictionary, slot: int) -> RunConfig:
	var cfg: Dictionary = info.get("config", {})
	var c := RunConfig.for_stage(String(cfg.get("stage_id", StageRegistry.DEFAULT_ID)))
	c.set_difficulty(String(cfg.get("difficulty_id", DifficultyData.DEFAULT_ID)))
	c.set_modifiers(PackedStringArray(cfg.get("modifiers", [])))
	c.hyper = bool(cfg.get("hyper", false))
	var lo: Dictionary = (info.get("loadouts", [{}, {}]) as Array)[clampi(slot, 0, 1)]
	c.set_character(String(lo.get("character_id", CharacterData.DEFAULT_ID)))
	c.skin_id = String(lo.get("skin_id", ""))
	c.recolour_id = String(lo.get("recolour_id", ""))  # Cosmetic: the partner's palette swap (Game._resolve_recolour() checks the save's ownership for slot 0 only).
	c.set_ultimate(String(lo.get("ultimate_id", UltimateData.DEFAULT_ID)))
	return c


## `p_code` upper-cased with spaces and dashes removed.
static func normalize_code(p_code: String) -> String:
	return p_code.strip_edges().replace(" ", "").replace("-", "").to_upper()


## True when `p_code` is CODE_LENGTH letters of CODE_ALPHABET.
static func is_valid_code(p_code: String) -> bool:
	if p_code.length() != CoopNetData.CODE_LENGTH:
		return false
	for ch in p_code:
		if not CoopNetData.CODE_ALPHABET.contains(ch):
			return false
	return true


## This build's game version: project.godot application/config/version plus the
## build id ("0.7.0+3f9c2a1b7d0e"), so two builds that share a version number but
## simulate differently never pair (lockstep needs the same simulation on both
## machines). The relay refuses a partner whose string differs. The build id is
## the commit CI exported (CoopNetData.BUILD_ID_PATH, written before the export),
## or CoopNetData.DEV_BUILD_ID when running from source (local tests and the CI
## co-op gates, where both processes share one tree).
static func game_version() -> String:
	var version := str(ProjectSettings.get_setting("application/config/version", "dev"))  # Version number.
	return "%s+%s" % [version, build_id()]


## The exported build's id (the commit CI built it from), else DEV_BUILD_ID.
static func build_id() -> String:
	if not FileAccess.file_exists(CoopNetData.BUILD_ID_PATH):
		return CoopNetData.DEV_BUILD_ID
	var id := FileAccess.get_file_as_string(CoopNetData.BUILD_ID_PATH).strip_edges()  # File contents.
	return id if id != "" else CoopNetData.DEV_BUILD_ID


## This machine's platform: "web" in a browser, else the OS name in lower case.
static func platform() -> String:
	return "web" if OS.has_feature("web") else OS.get_name().to_lower()


## The relay address: `--relay=` (desktop), `?relay=` (Web page), else CoopNetData.RELAY_URL.
static func relay_address() -> String:
	var v := _cli_value("--relay=")
	if v == "":
		v = page_query(CoopNetData.RELAY_QUERY_KEY)
	return v if v != "" else CoopNetData.RELAY_URL


## The Web page's `?key=` value ("" off the Web or when absent).
static func page_query(key: String) -> String:
	if not OS.has_feature("web"):
		return ""
	var v: Variant = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get(%s) || ''" % JSON.stringify(key), true)
	return str(v) if v != null else ""


## A code from the page's `?join=` (the shared link), "" when none or invalid.
static func link_code() -> String:
	var c := normalize_code(page_query(CoopNetData.JOIN_QUERY_KEY))
	return c if is_valid_code(c) else ""


## The shared link's code the first time it is asked for (the title screen
## opens the Join pad with it once per session), "" afterwards or when none.
func take_link_code() -> String:
	if _link_taken:
		return ""
	_link_taken = true
	return link_code()


## The headless network test's role from `--coop-net-test=host|join` ("" = none).
static func cli_test_role() -> String:
	return _cli_value("--coop-net-test=")


## Value of command-line user argument `prefix` ("--name=") or "".
static func _cli_value(prefix: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.substr(prefix.length())
	return ""


# =====================================================================================
# Internals
# =====================================================================================

## Opens the socket to `/lobby/<path_code>/ws` with `loadout` waiting to be sent.
func _open(path_code: String, loadout: Dictionary) -> void:
	if _ws != null:
		leave()
	_reset_session()
	relay_url = relay_override if relay_override != "" else relay_address()
	if relay_url == "":
		_raise("no_relay")
		return
	_pending_loadout = loadout.duplicate(true)
	_ws = WebSocketPeer.new()
	_ws.inbound_buffer_size = CoopNetData.INBOUND_BUFFER_BYTES
	_ws.outbound_buffer_size = CoopNetData.OUTBOUND_BUFFER_BYTES
	_ws.max_queued_packets = CoopNetData.MAX_QUEUED_PACKETS
	var url := "%s/lobby/%s/ws" % [relay_url.rstrip("/"), path_code]
	_connect_ms = Time.get_ticks_msec()
	if _ws.connect_to_url(url) != OK:
		_ws = null
		_raise("unreachable")
		_set_state(State.CLOSED)
		return
	_set_state(State.CONNECTING)
	set_process(true)


## Clears everything of the previous session.
func _reset_session() -> void:
	code = ""
	local_slot = -1
	start_info = {}
	settings = {}
	loadouts = [{}, {}]
	ready_flags = [false, false]
	peers = [{}, {}]
	rtt_ms = -1.0
	partner_rtt_ms = -1.0
	last_error = ""
	frames_sent = 0
	frames_received = 0
	_hello_sent = false
	_got_error = false
	_ping_sent = {}
	_ping_timer = 0.0
	_partner_heard_ms = 0


## Sets the state (and tells the screens when it changed).
func _set_state(s: State) -> void:
	if s == state:
		return
	state = s
	state_changed.emit(int(s))


## Raises error `err` (with `detail` for the line).
func _raise(err: String, detail: String = "") -> void:
	last_error = err
	print("[coop] error %s%s" % [err, (" (%s)" % detail) if detail != "" else ""])
	error_raised.emit(err, error_text(err, detail))


## Fails the session with error `err`: raised, the socket closed, processing off.
func _fail(err: String, detail: String = "") -> void:
	_raise(err, detail)
	_got_error = true
	if _ws != null:
		_ws.close(1000, err)
	_ws = null
	_set_state(State.CLOSED)
	set_process(false)


## The socket closed: a lost connection (in a lobby or run) or an unreachable
## relay (while connecting), unless the relay already said why.
func _on_closed() -> void:
	var was := state
	var close_err := _close_code_error(_ws.get_close_code())  # The relay's refusal by close code ("" = none).
	_ws = null
	set_process(false)
	_set_state(State.CLOSED)
	if was == State.LOBBY or was == State.STARTED:
		if not _got_error:
			_raise(close_err if close_err != "" else "lost")
		connection_lost.emit()
	elif was == State.CONNECTING and not _got_error:
		_raise(close_err if close_err != "" else "unreachable")


## The relay error code of WebSocket close code `c` (PROTOCOL.md: 4001-4010), "" for any other.
static func _close_code_error(c: int) -> String:
	for err: String in CoopNetData.CLOSE_CODES:
		if int(CoopNetData.CLOSE_CODES[err]) == c:
			return err
	return ""


## Sends `obj` as one JSON text message.
func _send_json(obj: Dictionary) -> void:
	if _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(obj))


## Sends the hello (first message on the open socket).
func _send_hello() -> void:
	_hello_sent = true
	_send_json({"t": "hello", "p": CoopNetData.PROTOCOL, "game": game_version(), "platform": platform(),
		"name": String(_pending_loadout.get("name", "")).left(CoopNetData.MAX_NAME_CHARS)})


## Sends our loadout and ready flag to the partner.
func _send_loadout() -> void:
	if local_slot >= 0 and has_partner():
		_send_json({"t": "loadout", "loadout": loadouts[local_slot], "ready": bool(ready_flags[local_slot])})


## Sends a partner ping (with our smoothed round trip for the partner's display).
func _send_ping() -> void:
	_ping_id += 1
	_ping_sent[_ping_id] = Time.get_ticks_usec()
	if _ping_sent.size() > CoopNetData.MAX_PENDING_PINGS:
		_ping_sent.erase(_ping_sent.keys().min())
	_send_json({"t": "pping", "id": _ping_id, "rtt": rtt_ms})


## A text message from the relay or the partner.
func _on_text(text: String) -> void:
	var v: Variant = JSON.parse_string(text)
	if not (v is Dictionary):
		return
	var m := v as Dictionary
	var other := 1 - local_slot  # The partner's seat (meaningless before the welcome).
	match String(m.get("t", "")):
		"welcome":
			_on_welcome(m)
		"peer":
			_on_peer(m.get("peer", {}) as Dictionary)
		"left":
			_on_left(int(m.get("slot", -1)))
		"error":
			_got_error = true
			_raise(String(m.get("code", "")), str(m.get("detail", "")))
		"loadout":
			if local_slot >= 0:
				_partner_heard_ms = Time.get_ticks_msec()
				loadouts[other] = _clean_loadout(m.get("loadout", {}) as Dictionary, other)
				ready_flags[other] = bool(m.get("ready", false)) if other == 1 else true
				lobby_changed.emit()
		"settings":
			if local_slot == 1 and state == State.LOBBY:
				settings = (m.get("config", {}) as Dictionary).duplicate(true)
				if bool(ready_flags[1]):
					ready_flags[1] = false  # The host changed the run: look again, then Ready.
					_send_loadout()
				lobby_changed.emit()
		"start":
			if local_slot == 1 and state == State.LOBBY:
				_begin_run(m.get("info", {}) as Dictionary, 1)
		"pping":
			_partner_heard_ms = Time.get_ticks_msec()
			partner_rtt_ms = float(m.get("rtt", -1.0))
			_send_json({"t": "ppong", "id": m.get("id", 0)})
		"ppong":
			_partner_heard_ms = Time.get_ticks_msec()
			var id := int(m.get("id", 0))
			if _ping_sent.has(id):
				var sample := float(Time.get_ticks_usec() - int(_ping_sent[id])) / 1000.0  # Round trip (ms).
				_ping_sent.erase(id)
				rtt_ms = sample if rtt_ms < 0.0 else lerpf(rtt_ms, sample, CoopNetData.RTT_SMOOTHING)
				latency_measured.emit(sample)
				lobby_changed.emit()


## The relay seated us.
func _on_welcome(m: Dictionary) -> void:
	code = String(m.get("code", ""))
	local_slot = int(m.get("slot", -1))
	peers[local_slot] = {"slot": local_slot, "game": game_version(), "platform": platform(),
		"name": String(_pending_loadout.get("name", ""))}
	loadouts[local_slot] = _clean_loadout(_pending_loadout, local_slot)
	ready_flags[local_slot] = local_slot == 0
	print("[coop] lobby %s, seat %d (%s)" % [code, local_slot, platform()])
	_set_state(State.LOBBY)
	var p: Variant = m.get("peer", null)
	if p is Dictionary and not (p as Dictionary).is_empty():
		_on_peer(p as Dictionary)
	lobby_changed.emit()


## A partner is in the other seat (from the welcome or a `peer` message).
func _on_peer(p: Dictionary) -> void:
	if local_slot < 0:
		return
	var other := 1 - local_slot
	if not CoopNetData.ALLOW_MIXED_PLATFORMS and not GameState.autotest_coop_mixed and String(p.get("platform", "")) != platform():
		_fail("platform", String(p.get("platform", "")))
		return
	peers[other] = p.duplicate()
	ready_flags[other] = other == 0
	print("[coop] partner joined: seat %d (%s)" % [other, String(p.get("platform", ""))])
	_partner_heard_ms = Time.get_ticks_msec()
	_ping_timer = 0.0  # Ping at once.
	_send_loadout()
	if local_slot == 0 and not settings.is_empty():
		_send_json({"t": "settings", "config": settings})
	partner_joined.emit()
	lobby_changed.emit()


## The partner in `slot` left.
func _on_left(slot: int) -> void:
	if slot < 0 or slot == local_slot:
		return
	peers[slot] = {}
	loadouts[slot] = {}
	ready_flags[slot] = false
	_ping_sent = {}
	print("[coop] partner left: seat %d" % slot)
	partner_left.emit()
	lobby_changed.emit()


## Sets start_info from `info` (the parsed start message) with our seat, and announces the run.
func _begin_run(info: Dictionary, slot: int) -> void:
	var out := info.duplicate(true)
	out["seed"] = int(out.get("seed", 0))
	out["local_slot"] = slot
	var cfg: Dictionary = out.get("config", {})
	cfg["oath"] = int(cfg.get("oath", 0))
	for lo: Dictionary in out.get("loadouts", []):
		var lv: Dictionary = lo.get("meta_levels", {})
		for k: String in lv:
			lv[k] = int(lv[k])
	start_info = out
	print("[coop] run starts: seed %d, seat %d, stage %s" % [int(out["seed"]), slot, String(cfg.get("stage_id", ""))])
	_set_state(State.STARTED)
	run_started.emit(start_info)


## A loadout with every field present and typed (missing ones defaulted; the
## name defaulted to the seat's CoopNetData.DEFAULT_NAMES entry and shortened).
static func _clean_loadout(lo: Dictionary, slot: int) -> Dictionary:
	var player_name := String(lo.get("name", "")).strip_edges().left(CoopNetData.MAX_NAME_CHARS)
	if player_name == "":
		player_name = String(CoopNetData.DEFAULT_NAMES[clampi(slot, 0, 1)])
	var levels := {}
	var src: Variant = lo.get("meta_levels", {})
	if src is Dictionary:
		for k: Variant in src:
			levels[String(k)] = int((src as Dictionary)[k])
	var masteries := {}  # Mastery levels, clamped to MasteryData's classes and range.
	var ms: Variant = lo.get("mastery_levels", {})
	if ms is Dictionary:
		for cls: String in MasteryData.CLASSES:
			var lv := clampi(int((ms as Dictionary).get(cls, 0)), 0, MasteryData.MAX_LEVEL)
			if lv > 0:
				masteries[cls] = lv
	var unlocks: Array = []
	var u: Variant = lo.get("unlocks", [])
	if u is Array:
		for id: Variant in u:
			unlocks.append(String(id))
	return {"character_id": String(lo.get("character_id", CharacterData.DEFAULT_ID)),
		"skin_id": String(lo.get("skin_id", "")), "recolour_id": String(lo.get("recolour_id", "")),
		"ultimate_id": String(lo.get("ultimate_id", UltimateData.DEFAULT_ID)),
		"title_id": String(lo.get("title_id", "")), "meta_levels": levels, "mastery_levels": masteries, "unlocks": unlocks, "name": player_name}
