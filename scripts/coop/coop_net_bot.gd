## CoopNetBot — the lobby half of the headless online co-op test
## (`--autotest --coop-net=host|join`, co-op milestone 2; GameState header).
## Main adds it instead of starting a run. It plays the lobby the way two
## players do through CoopNet (tools/coop_lockstep_gate.py runs a host and a
## join process against tools/coop_relay.py):
##   * host: opens a lobby with the loadout of this process's --character= /
##     --ultimate= (CoopNet.make_loadout(), name BotHost), prints
##     `COOP_CODE=<code>`, sends the run settings of --stage= / --difficulty= /
##     --modifiers= / --hyper, and starts with seed --seed= once the guest is ready;
##   * join: joins --coop-code= (name BotGuest) and presses Ready once the
##     host's settings arrived.
## CoopNet's run_started then calls Main.start_coop_run() on both, exactly as
## the lobby screens do, and each process's army bot plays its own slot through
## the lockstep. Under the lockstep only each slot's own inputs travel, so the
## per-slot test forcing (--classes=, --spells=, --passives=) is switched off
## here: it would change one machine's offers only. Network timing only.
class_name CoopNetBot
extends Node

## Real seconds the lobby may take before the test gives up (exit code 3).
const LOBBY_TIMEOUT_S: float = 90.0
## Exit code when the lobby fails (an error from the relay, or the timeout).
const EXIT_LOBBY_FAILED: int = 3

## "host" or "join".
var _role: String = ""
## True once the code was printed (host).
var _code_printed: bool = false
## True once the run settings went out (host).
var _settings_sent: bool = false
## True once the run started.
var _started: bool = false
## Real seconds spent in the lobby.
var _waited: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_role = GameState.autotest_coop_net
	GameState.autotest_classes = PackedStringArray()  # Per-slot forcing would desync (see the header).
	GameState.autotest_spells = PackedStringArray()
	GameState.autotest_passives = PackedStringArray()
	CoopNet.lobby_changed.connect(_on_lobby)
	CoopNet.error_raised.connect(_on_error)
	CoopNet.run_started.connect(_on_started)
	var cfg := config()
	print("[coop] --coop-net=%s, relay %s, character %s" % [_role, CoopNet.relay_address(), cfg.character_id])
	if _role == "host":
		CoopNet.host(CoopNet.make_loadout(cfg, "BotHost"))
	elif _role == "join":
		CoopNet.join(GameState.autotest_coop_code, CoopNet.make_loadout(cfg, "BotGuest"))
	else:
		push_error("CoopNetBot: --coop-net must be host or join, not '%s'" % _role)
		get_tree().quit(EXIT_LOBBY_FAILED)


func _process(delta: float) -> void:
	if _started:
		return
	_waited += delta
	if _waited > LOBBY_TIMEOUT_S:
		print("[coop] lobby timed out after %d s" % int(LOBBY_TIMEOUT_S))
		get_tree().quit(EXIT_LOBBY_FAILED)


## The run config of this process's autotest flags (the host's settings and
## this machine's own character / ultimate), as Main builds it for a solo test.
static func config() -> RunConfig:
	var c := RunConfig.for_stage(GameState.autotest_stage)
	c.set_difficulty(GameState.autotest_difficulty)
	c.set_modifiers(GameState.autotest_modifiers)
	c.set_character(GameState.autotest_character)
	c.hyper = GameState.autotest_hyper
	c.set_ultimate(GameState.autotest_ultimate)
	return c


## The lobby changed: the host prints its code, sends its settings and starts
## once the guest is ready; the guest presses Ready once the settings came.
func _on_lobby() -> void:
	if _started:
		return
	if _role == "host":
		if CoopNet.code != "" and not _code_printed:
			_code_printed = true
			print("COOP_CODE=%s" % CoopNet.code)
		if CoopNet.has_partner() and not _settings_sent:
			_settings_sent = true
			CoopNet.set_settings(CoopNet.config_dict(config()))
		if CoopNet.can_start():
			CoopNet.start_run(GameState.autotest_seed)
	elif _role == "join":
		if not CoopNet.settings.is_empty() and not bool(CoopNet.ready_flags[1]):
			CoopNet.set_ready(true)


## A lobby error: the test fails.
func _on_error(err: String, text: String) -> void:
	if _started:
		return
	print("[coop] lobby error %s: %s" % [err, text])
	get_tree().quit(EXIT_LOBBY_FAILED)


## The run started (both machines): Main builds it from the start info.
func _on_started(info: Dictionary) -> void:
	if _started:
		return
	_started = true
	var main := get_parent()
	if main != null and main.has_method("start_coop_run"):
		main.call_deferred("start_coop_run", info)
	queue_free()
