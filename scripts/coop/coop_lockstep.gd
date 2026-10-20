## CoopLockstep — the co-op lockstep driver (co-op milestone 2; GDD §15.0
## "Co-op lockstep"; numbers in CoopLockstepData). Both machines run the whole
## simulation of both players (CoopSession); only each player's INPUTS travel,
## through CoopNet (the relay). It exists only in an online co-op run
## (CoopSession.lockstep); a solo run and the one-process --coop-bot never
## create it.
##
## TICKS. The simulation advances in numbered lockstep ticks of
## CoopLockstepData.TICK_DELTA game seconds. Tick t runs only when BOTH slots'
## inputs for t are known. The local player's input sampled while tick t is
## next is scheduled for tick t + delay (the input delay, DELAY_START ticks at
## first, then adapted to the measured round trip); ticks 0 .. DELAY_START - 1
## are empty for both. Every tick of the local slot is defined exactly once: a
## longer delay fills the gap by repeating the current input, a shorter one
## waits until the schedule catches up.
##
## ONE INPUT (per tick per slot): the move vector quantized to two signed bytes,
## a button byte (Grave Step, the ultimate, the Shadow Bolt aim toggle, with an
## optional dash direction byte for the bots) and up to MAX_COMMANDS_PER_TICK
## commands (Cmd: level-up pick / reroll / banish / skip, chest confirm, pause,
## resume, leave), each a [command, argument] byte pair. Both machines apply
## the DECODED values at the same tick, slot 0 then slot 1, so the local player
## plays his own quantized input exactly like the partner's machine does.
##
## FRAMES (CoopNet.send_frame(), opaque to the relay): one frame carries the
## local slot's inputs of BUNDLE_TICKS consecutive ticks (the Cloudflare free
## plan bills each incoming message), plus any due checksum record; it goes
## out early when a command waits (a level-up pick should not wait) or when the
## simulation stalls (so the partner never waits on an unsent bundle). Records,
## little endian:
##   REC_INPUTS   u8 type, u32 first tick, u8 count, count inputs
##                (input: s8 move x, s8 move y, u8 buttons, [u8 dash dir],
##                 [u8 command count, count x (u8 command, u8 argument)])
##   REC_CHECKSUM u8 type, u32 tick, u8 field count, field count x u32
##
## FREEZES (no get_tree().paused for gameplay in co-op): a level-up round (both
## players pick their own card; CoopSession's slots draw their offers from their
## own streams), a treasure chest being revealed on its opener's screen, and the
## pause menu (either player pauses both, either resumes) are lockstep states:
## the ticks keep running and keep consuming both players' inputs (that is how
## the commands arrive), but the simulation does not step while frozen. Every
## freeze starts and ends at the same tick on both machines.
##
## DESYNC CHECK: every CHECKSUM_INTERVAL ticks both machines hash the state
## (checksum_fields(): the clock and counters, each necromancer, the enemies,
## the armies, the shots, the pickups, the offer streams) into one u32 per
## field and send it; a mismatch logs the tick and the first differing field
## and ends the run for both (each keeps its Soul Ash, as any end of a run).
##
## PARTNER DROP: the relay's `left`, our own lost connection, an explicit Leave
## command, or no partner input for DROP_S real seconds hands the partner's
## necromancer to the autotest's army bot (Autotest.init_takeover()): his
## inputs already received are played first, then the bot steers him on this
## machine alone; frames stop; a co-op notice says so. No reconnect in v1.
## The waiting lines and notices go through the HUD's CoopUi (game.hud.coop_ui:
## show_waiting() / clear_waiting() / notice()).
##
## Network timing (Time) only decides WHEN ticks run, never what they do:
## gameplay stays deterministic per seed and input stream.
class_name CoopLockstep
extends RefCounted

## Commands (one byte each, with a one-byte argument).
enum Cmd { NONE, PICK, REROLL, BANISH, SKIP, CHEST_OK, PAUSE, RESUME, LEAVE }

## Button bits of one input.
const BTN_DASH: int = 1
const BTN_ULT: int = 2
const BTN_AIM: int = 4
## The input carries a dash direction byte.
const BTN_DIR: int = 8
## The input carries commands.
const BTN_CMD: int = 16
## Record types of a frame.
const REC_INPUTS: int = 1
const REC_CHECKSUM: int = 2

## Owning run.
var game: Game
## The co-op session (the two slots).
var session: CoopSession
## This machine's slot (0 = host, 1 = guest).
var local: int = 0
## The partner's slot.
var remote: int = 1
## Next tick to execute (ticks executed so far).
var tick: int = 0
## Current input delay (ticks).
var delay: int = CoopLockstepData.DELAY_START
## Per slot: tick -> input Dictionary {"mx", "my", "b", "dir", "cmds"} (see _empty_input()).
var _inputs: Array[Dictionary] = [{}, {}]
## Next tick the local slot's input is scheduled for.
var _next_local: int = CoopLockstepData.DELAY_START
## Highest tick of the partner's inputs received so far (-1 = none).
var _remote_high: int = -1
## Local inputs scheduled but not sent yet: [[tick, input], ...] in order.
var _unsent: Array = []
## Checksum records waiting to be sent: [[tick, PackedInt64Array fields], ...].
var _unsent_sums: Array = []
## Button bits waiting for the next scheduled local input.
var _pending_buttons: int = 0
## Dash direction byte waiting with them (-1 = none).
var _pending_dir: int = -1
## Commands waiting for the next scheduled local input: [[cmd, arg], ...].
var _pending_cmds: Array = []
## True when a waiting command should be sent at once (not after the bundle).
var _urgent: bool = false

# --- Freezes ------------------------------------------------------------------------------

## True while a level-up round waits for picks.
var round_active: bool = false
## Per slot: the offers shown in the current round.
var _offers: Array = [[], []]
## Per slot: true once it picked (or skipped) in the current round.
var _picked: Array[bool] = [false, false]
## Treasure chests waiting for their opener's confirm: [{"slot", "rewards", "count"}, ...].
var _chests: Array[Dictionary] = []
## True once the local opener's reveal of the first chest is shown.
var _chest_shown: bool = false
## True while the pause menu holds the run.
var paused: bool = false
## Slot that paused the run (-1 = none).
var paused_by: int = -1
## True once the run ended (no more ticks or frames).
var ended: bool = false

# --- Partner, network timing (never gameplay) ------------------------------------------

## True once the partner is gone (his slot's bot plays on this machine alone).
var dropped: bool = false
## Tick from which the bot steered the partner's necromancer (-1 = never).
var drop_tick: int = -1
## Why the partner was lost ("" = he was not): "left", "lost", "leave", "stall".
var drop_reason: String = ""
## The bot that took the partner's necromancer over (null until a drop).
var _takeover: Autotest = null
## Real time (ms) the last partner input arrived or a tick ran (stall timer).
var _progress_ms: int = 0
## Real time (ms) the current stall began (0 = not stalled).
var _stall_since: int = 0
## True while the waiting overlay shows a network stall.
var _stall_shown: bool = false
## Text the waiting overlay shows now ("" = hidden).
var _wait_text: String = ""
## Real time (ms) of the last input-delay adjustment.
var _adjust_ms: int = 0
## Smoothed jitter of the round trip (ms).
var _jitter_ms: float = 0.0
## The co-op visuals' API (Hud.coop_ui: the waiting panel and the notices; null without a HUD).
var ui: CoopUi = null
## The partner_left / connection_lost handlers (kept to disconnect them).
var _cb_left: Callable = Callable()
var _cb_lost: Callable = Callable()

# --- Checksums -------------------------------------------------------------------------------

## Our own checksums waiting for the partner's: tick -> PackedInt64Array.
var _own_sums: Dictionary = {}
## The partner's checksums waiting for ours: tick -> PackedInt64Array.
var _their_sums: Dictionary = {}
## Checksums compared so far.
var compared: int = 0
## Rolling hash over every checksum this machine computed (the gate compares it between the machines).
var chain: int = 2166136261
## Tick of the desync (-1 = none) and the first differing field.
var desync_tick: int = -1
var desync_field: String = ""

# --- Report counters (autotest; never gameplay) ------------------------------------------

## Frames sent by the driver.
var frames_sent: int = 0
## Frames received from the partner.
var frames_received: int = 0
## Physics frames on which no tick could run (waiting for the partner).
var stall_frames: int = 0
## Longest stall (ms).
var longest_stall_ms: int = 0
## Ticks run while the simulation was frozen.
var frozen_ticks: int = 0
## Smallest / largest input delay used (ticks).
var delay_low: int = CoopLockstepData.DELAY_START
var delay_high: int = CoopLockstepData.DELAY_START
## Level-up rounds resolved.
var rounds: int = 0
## Commands sent by the local player, by kind name.
var cmds_sent: Dictionary = {}


func _init(p_game: Game, p_session: CoopSession, p_local: int) -> void:
	game = p_game
	session = p_session
	local = p_local
	remote = 1 - p_local
	for t in CoopLockstepData.DELAY_START:
		_inputs[0][t] = _empty_input()
		_inputs[1][t] = _empty_input()


## Hooks the network (CoopNet) and the overlay once the run's UI exists (Game._ready).
func start() -> void:
	ui = game.hud.coop_ui if game.hud != null else null
	_cb_left = _on_partner_gone.bind("left")
	_cb_lost = _on_partner_gone.bind("lost")
	CoopNet.frame_received.connect(_on_frame)
	CoopNet.partner_left.connect(_cb_left)
	CoopNet.connection_lost.connect(_cb_lost)
	CoopNet.latency_measured.connect(_on_rtt)
	_progress_ms = Time.get_ticks_msec()
	_adjust_ms = _progress_ms
	if CoopNet.state != CoopNet.State.STARTED:
		_on_partner_gone("lost")  # No partner connection at all (a test start): the bot plays him.


## Unhooks the network (the run is being freed).
func stop() -> void:
	if CoopNet.frame_received.is_connected(_on_frame):
		CoopNet.frame_received.disconnect(_on_frame)
	if CoopNet.latency_measured.is_connected(_on_rtt):
		CoopNet.latency_measured.disconnect(_on_rtt)
	if _cb_left.is_valid() and CoopNet.partner_left.is_connected(_cb_left):
		CoopNet.partner_left.disconnect(_cb_left)
	if _cb_lost.is_valid() and CoopNet.connection_lost.is_connected(_cb_lost):
		CoopNet.connection_lost.disconnect(_cb_lost)


# =====================================================================================
# The physics frame (Game._physics_process)
# =====================================================================================

## One physics frame: polls the network, schedules the local input, runs the
## ticks whose inputs are known (catching up after a stall), sends the frame.
func frame(_delta: float) -> void:
	CoopNet.poll()
	if ended:
		_flush()
		return
	var now := Time.get_ticks_msec()
	_adapt_delay(now)
	_schedule_local()
	var limit := 1  # Ticks this frame may run.
	if not dropped and _remote_high - tick > delay + CoopLockstepData.CATCHUP_SLACK:
		limit = CoopLockstepData.MAX_CATCHUP_TICKS  # Behind the partner: catch up.
	var ran := 0
	while ran < limit and not ended and _ready_to_run():
		_run_tick()
		ran += 1
		if ran < limit and not dropped:
			_schedule_local()  # A catch-up tick frees the schedule for the next one.
	if ran > 0:
		_progress_ms = now
		if _stall_since > 0:
			longest_stall_ms = maxi(longest_stall_ms, now - _stall_since)
		_stall_since = 0
	elif not ended:
		stall_frames += 1
		if _stall_since == 0:
			_stall_since = now
	if not dropped and not _unsent.is_empty() and (_unsent.size() >= CoopLockstepData.BUNDLE_TICKS or _urgent or ran == 0):
		_flush()  # A full bundle, a waiting command, or a stall (the partner may be waiting on these ticks).
	_check_stall(now)
	_refresh_wait()


## True when both slots' inputs for the next tick are known.
func _ready_to_run() -> bool:
	if not _inputs[local].has(tick):
		return false
	return dropped or _inputs[remote].has(tick)


## Schedules the local slot's input up to tick + delay (the current move and
## any waiting buttons and commands go to the first new tick).
func _schedule_local() -> void:
	if dropped and ended:
		return
	var until := tick + delay  # Last tick to define now.
	if _next_local > until:
		return
	var inp := _sample_local()
	while _next_local <= until:
		_inputs[local][_next_local] = inp
		if not dropped:
			_unsent.append([_next_local, inp])
		_next_local += 1
		inp = inp.duplicate()  # Repeats only the move on the gap ticks.
		inp["b"] = 0
		inp["dir"] = -1
		inp["cmds"] = []


## The local slot's input now: the move (the bot's or the player's), the
## waiting buttons and commands (consumed).
func _sample_local() -> Dictionary:
	var inp := _empty_input()
	var mv := Vector2.ZERO
	session.bind(local)
	if game.run_state == Game.RunState.PLAYING:
		if game.autotest != null:
			mv = game.autotest.get_move_vector()  # The local bot (the gate).
		else:
			mv = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	session.bind(session.view_slot)
	inp["mx"] = quantize(mv.x)
	inp["my"] = quantize(mv.y)
	inp["b"] = _pending_buttons
	if _pending_dir >= 0:
		inp["dir"] = _pending_dir
		inp["b"] = int(inp["b"]) | BTN_DIR
	var cmds: Array = []
	while not _pending_cmds.is_empty() and cmds.size() < CoopLockstepData.MAX_COMMANDS_PER_TICK:
		cmds.append(_pending_cmds.pop_front())
	if not cmds.is_empty():
		inp["cmds"] = cmds
		inp["b"] = int(inp["b"]) | BTN_CMD
	_pending_buttons = 0
	_pending_dir = -1
	_urgent = _urgent or not cmds.is_empty()
	return inp


## An empty input (no move, no button, no command).
static func _empty_input() -> Dictionary:
	return {"mx": 0, "my": 0, "b": 0, "dir": -1, "cmds": []}


## A move axis value (-1..1) as a signed step (-MOVE_STEPS..MOVE_STEPS).
static func quantize(v: float) -> int:
	return clampi(roundi(v * float(CoopLockstepData.MOVE_STEPS)), -CoopLockstepData.MOVE_STEPS, CoopLockstepData.MOVE_STEPS)


## The move vector of input `inp` (what both machines apply).
static func move_of(inp: Dictionary) -> Vector2:
	var s := float(CoopLockstepData.MOVE_STEPS)
	return Vector2(float(int(inp["mx"])) / s, float(int(inp["my"])) / s).limit_length(1.0)


## The dash direction of input `inp` (zero = his facing).
static func dir_of(inp: Dictionary) -> Vector2:
	if int(inp["b"]) & BTN_DIR == 0:
		return Vector2.ZERO
	return Vector2.from_angle(float(int(inp["dir"])) * TAU / float(CoopLockstepData.DIR_STEPS))


# =====================================================================================
# Local requests (Game input, the panels, the local bot)
# =====================================================================================

## True when slot `s`'s inputs travel through the network (this machine's own
## slot while the partner is there): its bot and its player press through
## press(); a slot played by a takeover bot acts directly.
func networked(s: int) -> bool:
	return s == local


## Presses button `bit` (BTN_DASH / BTN_ULT / BTN_AIM) for the local slot's next
## scheduled input; `dir` (any length, zero = none) is a bot's dash direction.
func press(bit: int, dir: Vector2 = Vector2.ZERO) -> void:
	_pending_buttons |= bit
	if bit == BTN_DASH and dir.length() > 0.01:
		_pending_dir = posmod(roundi(dir.angle() / TAU * float(CoopLockstepData.DIR_STEPS)), CoopLockstepData.DIR_STEPS)


## Queues command `c` with argument `arg` (0..255) for the local slot.
func command(c: Cmd, arg: int = 0) -> void:
	_pending_cmds.append([int(c), clampi(arg, 0, 255)])
	_urgent = true
	var key := String(Cmd.keys()[c]).to_lower()
	cmds_sent[key] = int(cmds_sent.get(key, 0)) + 1


## The level-up panel's choice for the local slot ("pick" / "reroll" /
## "banish" / "skip", card index).
func on_panel_action(action: String, index: int) -> void:
	match action:
		"pick":
			command(Cmd.PICK, index)
		"reroll":
			command(Cmd.REROLL)
		"banish":
			command(Cmd.BANISH, index)
		"skip":
			command(Cmd.SKIP)
	_set_wait("")


## Esc / the pause menu / a turned phone / a hidden tab: asks to pause, or to
## resume when paused. Ignored while the run is not playing or paused.
func request_toggle_pause() -> void:
	if ended:
		return
	if paused:
		command(Cmd.RESUME)
	elif game.run_state == Game.RunState.PLAYING:
		command(Cmd.PAUSE)
		_push_now()  # A tab about to be hidden must get this out before it stops running.


## The page / window lost focus or went to the background: pause both (sent at once).
func request_pause_now() -> void:
	if not paused and not ended and game.run_state == Game.RunState.PLAYING:
		command(Cmd.PAUSE)
		_push_now()


## The local opener closed the chest reveal.
func on_local_chest_closed() -> void:
	if not _chests.is_empty() and int(_chests[0]["slot"]) == local:
		command(Cmd.CHEST_OK)


## Leaving the run on purpose (the pause menu's Leave): tells the partner and
## sends everything at once (the caller then closes the connection).
func leave() -> void:
	if dropped or ended:
		return
	command(Cmd.LEAVE)
	_push_now()


## Schedules one more local tick at once, beyond the delay if need be, with
## whatever waits, and sends it (urgent: pause, leave).
func _push_now() -> void:
	if dropped:
		return
	var inp := _sample_local()
	_inputs[local][_next_local] = inp
	_unsent.append([_next_local, inp])
	_next_local += 1
	_flush()
	CoopNet.poll()


# =====================================================================================
# One tick
# =====================================================================================

## Runs tick `tick`: both slots' commands and buttons, then (unless frozen) one
## simulation step, the freezes it opened, the checksum.
func _run_tick() -> void:
	var ins: Array[Dictionary] = []  # Input of each slot this tick.
	for s in session.slots.size():
		var inp: Dictionary = _inputs[s].get(tick, {})
		_inputs[s].erase(tick)
		if inp.is_empty():
			inp = _takeover_input(s)
		ins.append(inp)
	for s in ins.size():
		for c: Array in ins[s]["cmds"]:
			_apply_command(s, int(c[0]), int(c[1]))
	var frozen := is_frozen()
	for s in ins.size():
		var sl := session.slots[s]
		if frozen or ended:
			sl.move = Vector2.ZERO
			continue
		sl.move = move_of(ins[s])
		var b := int(ins[s]["b"])
		if b & BTN_DASH and not sl.downed:
			sl.grave_step.request(dir_of(ins[s]))
		if b & BTN_ULT and not sl.downed:
			sl.dread_rally.request()
		if b & BTN_AIM:
			sl.abilities.toggle_bolt_aim()
	if not frozen and not ended:
		game.coop_sim_tick(CoopLockstepData.TICK_DELTA)
		if dropped and _takeover != null and not ended:
			session.bind(remote)
			_takeover.step_slot(CoopLockstepData.TICK_DELTA)  # Its dash, ultimate and aim.
			session.bind(session.view_slot)
		if not ended:
			_after_step()
	else:
		frozen_ticks += 1
	if tick % CoopLockstepData.CHECKSUM_INTERVAL == 0:
		_checksum()
	tick += 1
	session.bind(session.view_slot)


## The partner's input for this tick when it never came (he is gone): the
## takeover bot's move; an empty input for anything else.
func _takeover_input(s: int) -> Dictionary:
	var inp := _empty_input()
	if s == remote and dropped and _takeover != null and game.run_state == Game.RunState.PLAYING:
		session.bind(remote)
		var mv := _takeover.get_move_vector()
		session.bind(session.view_slot)
		inp["mx"] = quantize(mv.x)
		inp["my"] = quantize(mv.y)
	return inp


## True while the simulation must not step (a level-up round, a chest reveal, the pause menu).
func is_frozen() -> bool:
	return round_active or not _chests.is_empty() or paused


## After a simulation step: opens the level-up round the shared bar asks for
## (once no chest waits).
func _after_step() -> void:
	if _chests.is_empty() and not round_active and game.pending_level_ups > 0:
		_start_round()
	_sync_state()


## Applies command `c` (argument `arg`) of slot `s`.
func _apply_command(s: int, c: int, arg: int) -> void:
	match c:
		Cmd.PICK, Cmd.SKIP:
			if not round_active or _picked[s]:
				return
			var sl := session.slots[s]
			session.bind(s)
			var offers: Array = _offers[s]
			if c == Cmd.SKIP or offers.is_empty():
				sl.abilities.apply_offer(sl.abilities.skip_offer())
			else:
				sl.abilities.apply_offer(offers[clampi(arg, 0, offers.size() - 1)])
			_picked[s] = true
			session.bind(session.view_slot)
			if s == local:
				game.level_up_panel.close()
			_maybe_end_round()
		Cmd.REROLL:
			if not round_active or _picked[s]:
				return
			session.bind(s)
			var ab := session.slots[s].abilities
			if ab.use_reroll():
				_offers[s] = ab.build_offers(PlayerData.CARDS_PER_LEVEL)
			session.bind(session.view_slot)
			_show_offers(s)
		Cmd.BANISH:
			if not round_active or _picked[s]:
				return
			session.bind(s)
			var ab := session.slots[s].abilities
			var offers: Array[Dictionary] = []
			offers.assign(_offers[s])
			if arg < offers.size() and ab.can_banish(offers[arg]):
				_offers[s] = ab.banish_offer(offers, arg)
			session.bind(session.view_slot)
			_show_offers(s)
		Cmd.CHEST_OK:
			for i in _chests.size():
				if int(_chests[i]["slot"]) == s:
					_chests.remove_at(i)
					if i == 0:
						_chest_shown = false
					break
			_sync_state()
			if _chests.is_empty() and not round_active and game.pending_level_ups > 0 and not paused:
				_start_round()
		Cmd.PAUSE:
			if paused or round_active or not _chests.is_empty() or ended:
				return  # Never over a level-up or a chest (both machines ignore it alike).
			paused = true
			paused_by = s
			_sync_state()
		Cmd.RESUME:
			if not paused:
				return
			paused = false
			paused_by = -1
			_sync_state()
		Cmd.LEAVE:
			if s == remote:
				_on_partner_gone("leave")


# =====================================================================================
# Level-up rounds (both pick; the simulation waits)
# =====================================================================================

## Starts a round: every slot draws its offers from its own stream (slot 0
## first), the local player's panel opens, a takeover bot picks at once.
func _start_round() -> void:
	round_active = true
	for s in session.slots.size():
		session.bind(s)
		var sl := session.slots[s]
		_picked[s] = false  # A downed player picks too (his build still grows for the revive).
		_offers[s] = sl.abilities.build_offers(PlayerData.CARDS_PER_LEVEL)
	session.bind(session.view_slot)
	_sync_state()
	_show_offers(local)
	if dropped:
		_takeover_pick()


## Shows the local slot's current offers (when it is the local slot and it has
## not picked), or lets a takeover bot answer for the partner.
func _show_offers(s: int) -> void:
	if not round_active:
		return
	if s == remote:
		if dropped:
			_takeover_pick()
		return
	if _picked[local]:
		return
	var offers: Array[Dictionary] = []
	offers.assign(_offers[local])
	game.level_up_panel.open(offers, game.level - game.pending_level_ups + 1)


## The takeover bot picks for the partner's slot (applied at once on this
## machine alone: nobody else runs it any more).
func _takeover_pick() -> void:
	if _takeover == null or _picked[remote] or not round_active:
		return
	session.bind(remote)
	var ab := session.slots[remote].abilities
	var offers: Array[Dictionary] = []
	offers.assign(_offers[remote])
	for _guard in 64:
		var act := _takeover.choose_action(offers)
		match String(act["action"]):
			"reroll":
				if ab.use_reroll():
					offers = ab.build_offers(PlayerData.CARDS_PER_LEVEL)
					continue
				ab.apply_offer(offers[0])
			"banish":
				var i := int(act["index"])
				if i >= 0 and i < offers.size() and ab.can_banish(offers[i]):
					offers = ab.banish_offer(offers, i)
					continue
				ab.apply_offer(offers[0])
			"skip":
				ab.apply_offer(ab.skip_offer())
			_:
				ab.apply_offer(offers[clampi(int(act["index"]), 0, offers.size() - 1)])
		break
	_picked[remote] = true
	session.bind(session.view_slot)
	_maybe_end_round()


## Ends the round once every slot picked: the next pending level opens
## another round, else the simulation goes on.
func _maybe_end_round() -> void:
	for s in session.slots.size():
		if not _picked[s]:
			_sync_state()
			return
	game.pending_level_ups -= 1
	session.level_rounds += 1
	rounds += 1
	round_active = false
	if game.pending_level_ups > 0:
		_start_round()
		return
	game.level_up_panel.close()
	_sync_state()


# =====================================================================================
# Treasure chests (the opener's reveal; the simulation waits)
# =====================================================================================

## A chest was opened by slot `s` (its rewards already applied, CoopSession.open_chest()).
func on_chest_opened(s: int, rewards: Array[Dictionary], count: int) -> void:
	_chests.append({"slot": s, "rewards": rewards, "count": count})
	if s == remote and dropped:
		_chests.pop_back()  # The takeover bot needs no reveal.
	_sync_state()


# =====================================================================================
# State shown on this machine (run_state, panels, the overlay)
# =====================================================================================

## Mirrors the lockstep state into Game.run_state and the panels (UI only).
func _sync_state() -> void:
	if game.run_state == Game.RunState.ENDED:
		return
	var want := Game.RunState.PLAYING
	if paused:
		want = Game.RunState.PAUSED
	elif not _chests.is_empty():
		want = Game.RunState.CHEST
	elif round_active:
		want = Game.RunState.LEVEL_UP
	if want != game.run_state:
		if game.run_state == Game.RunState.PAUSED:
			game.pause_menu.close()
		game.run_state = want
		if want == Game.RunState.PAUSED:
			game.pause_menu.open()
			game.pause_menu.set_partner_line(CoopLockstepData.PAUSED_BY_PARTNER_TEXT if paused_by == remote else "")
	if not _chests.is_empty() and not _chest_shown and int(_chests[0]["slot"]) == local:
		_chest_shown = true
		var rw: Array[Dictionary] = []
		rw.assign(_chests[0]["rewards"])
		game.chest_panel.open(rw, int(_chests[0]["count"]))


## The line the waiting overlay should show now ("" = none), and shows it.
func _refresh_wait() -> void:
	var text := ""
	if ended:
		text = ""  # The results card says it (a desync too).
	elif _stall_shown:
		text = CoopLockstepData.WAIT_NETWORK_TEXT
	elif not paused and not _chests.is_empty() and int(_chests[0]["slot"]) != local:
		text = CoopLockstepData.WAIT_CHEST_TEXT
	elif not paused and _chests.is_empty() and round_active and _picked[local] and not _picked[remote]:
		text = CoopLockstepData.WAIT_LEVEL_TEXT
	_set_wait(text)


## Shows `text` on the waiting overlay ("" hides it).
func _set_wait(text: String) -> void:
	if text == _wait_text or ui == null:
		return
	_wait_text = text
	if text == "":
		ui.clear_waiting()
	else:
		ui.show_waiting(text)


# =====================================================================================
# Network: frames in and out, the delay, stalls and drops
# =====================================================================================

## Sends every unsent local input (one frame, up to 255 ticks) and checksum.
func _flush() -> void:
	if dropped or (_unsent.is_empty() and _unsent_sums.is_empty()):
		return
	var buf := PackedByteArray()
	while not _unsent.is_empty():
		var n := mini(_unsent.size(), 255)
		var first := int(_unsent[0][0])
		buf.append(REC_INPUTS)
		_put_u32(buf, first)
		buf.append(n)
		for i in n:
			_encode_input(buf, _unsent[i][1])
		_unsent = _unsent.slice(n)
	for rec: Array in _unsent_sums:
		buf.append(REC_CHECKSUM)
		_put_u32(buf, int(rec[0]))
		var f: PackedInt64Array = rec[1]
		buf.append(f.size())
		for v in f:
			_put_u32(buf, v)
	_unsent_sums.clear()
	if CoopNet.send_frame(buf):
		frames_sent += 1
	_urgent = false


## Appends input `inp` to `buf` (see the header).
static func _encode_input(buf: PackedByteArray, inp: Dictionary) -> void:
	buf.append(int(inp["mx"]) & 0xFF)
	buf.append(int(inp["my"]) & 0xFF)
	var b := int(inp["b"])
	buf.append(b)
	if b & BTN_DIR:
		buf.append(int(inp["dir"]) & 0xFF)
	if b & BTN_CMD:
		var cmds: Array = inp["cmds"]
		buf.append(cmds.size())
		for c: Array in cmds:
			buf.append(int(c[0]))
			buf.append(int(c[1]))


## Appends `v` as a little-endian u32.
static func _put_u32(buf: PackedByteArray, v: int) -> void:
	var at := buf.size()
	buf.resize(at + 4)
	buf.encode_u32(at, v & 0xFFFFFFFF)


## A frame from the partner: his inputs and checksums.
func _on_frame(bytes: PackedByteArray) -> void:
	if dropped:
		return
	frames_received += 1
	_progress_ms = Time.get_ticks_msec()
	var at := 0
	while at < bytes.size():
		var kind := bytes[at]
		at += 1
		if kind == REC_INPUTS:
			var first := bytes.decode_u32(at)
			var n := bytes[at + 4]
			at += 5
			for i in n:
				var inp := _empty_input()
				inp["mx"] = bytes.decode_s8(at)
				inp["my"] = bytes.decode_s8(at + 1)
				var b := bytes[at + 2]
				inp["b"] = b
				at += 3
				if b & BTN_DIR:
					inp["dir"] = bytes[at]
					at += 1
				if b & BTN_CMD:
					var nc := bytes[at]
					at += 1
					var cmds: Array = []
					for _k in nc:
						cmds.append([int(bytes[at]), int(bytes[at + 1])])
						at += 2
					inp["cmds"] = cmds
				var t := first + i
				if t >= tick:
					_inputs[remote][t] = inp
				_remote_high = maxi(_remote_high, t)
		elif kind == REC_CHECKSUM:
			var t := bytes.decode_u32(at)
			var n := bytes[at + 4]
			at += 5
			var f := PackedInt64Array()
			for i in n:
				f.append(bytes.decode_u32(at))
				at += 4
			_their_sums[t] = f
			_compare(t)
		else:
			push_error("CoopLockstep: unknown record %d in a partner frame" % kind)
			return


## A round-trip sample from CoopNet's pings (ms): feeds the jitter estimate.
func _on_rtt(sample_ms: float) -> void:
	if CoopNet.rtt_ms > 0.0:
		_jitter_ms = lerpf(_jitter_ms, absf(sample_ms - CoopNet.rtt_ms), CoopLockstepData.JITTER_SMOOTHING)


## Every DELAY_ADJUST_INTERVAL s: the input delay that covers the one-way trip
## (half the round trip plus jitter) at the current tick rate, plus the bundle
## and a margin, within DELAY_MIN..DELAY_MAX.
func _adapt_delay(now: int) -> void:
	if dropped or float(now - _adjust_ms) / 1000.0 < CoopLockstepData.DELAY_ADJUST_INTERVAL or CoopNet.rtt_ms <= 0.0:
		return
	_adjust_ms = now
	var tick_ms := 1000.0 / float(maxi(1, Engine.physics_ticks_per_second))  # Real ms per tick (the autotest runs faster).
	var one_way := CoopNet.rtt_ms * 0.5 + CoopLockstepData.JITTER_WEIGHT * _jitter_ms
	var want := ceili(one_way / tick_ms) + CoopLockstepData.BUNDLE_TICKS + CoopLockstepData.DELAY_MARGIN_TICKS
	delay = clampi(want, CoopLockstepData.DELAY_MIN, CoopLockstepData.DELAY_MAX)
	delay_low = mini(delay_low, delay)
	delay_high = maxi(delay_high, delay)


## Stall bookkeeping: the waiting overlay after STALL_OVERLAY_S, the takeover after DROP_S.
func _check_stall(now: int) -> void:
	if dropped or ended:
		_stall_shown = false
		return
	var quiet := float(now - _progress_ms) / 1000.0  # Seconds without a tick or a partner frame.
	_stall_shown = _stall_since > 0 and float(now - _stall_since) / 1000.0 >= CoopLockstepData.STALL_OVERLAY_S
	var limit := CoopLockstepData.DROP_PAUSED_S if paused else CoopLockstepData.DROP_S
	if _stall_since > 0 and quiet >= limit:
		_on_partner_gone("stall")


## The partner is gone (`why`: "left", "lost", "leave", "stall"): the army bot
## takes his necromancer over on this machine; frames stop.
func _on_partner_gone(why: String) -> void:
	if dropped or ended:
		return
	dropped = true
	drop_tick = tick
	drop_reason = why
	_unsent.clear()
	_unsent_sums.clear()
	var lo: Dictionary = session.slots[remote].loadout
	_takeover = Autotest.new()
	_takeover.game = game
	_takeover.init_takeover(remote, CoopLockstepData.TAKEOVER_POLICY, String(lo.get("character_id", CharacterData.DEFAULT_ID)))
	game.add_child(_takeover)
	session.slots[remote].bot = _takeover
	print("[coop] partner %s at tick %d (%s): a bot takes slot %d over" % ["gone", tick, why, remote])
	if ui != null:
		ui.notice(CoopLockstepData.DROP_NOTICE % session.slots[remote].display_name, true)
	if paused and paused_by == remote:
		paused = false  # His pause dies with him.
		paused_by = -1
	_chests = _chests.filter(func(c: Dictionary) -> bool: return int(c["slot"]) != remote)
	if round_active:
		_takeover_pick()
	_sync_state()
	_stall_shown = false
	_refresh_wait()


# =====================================================================================
# Desync check
# =====================================================================================

## Hashes the state now and queues it for the partner.
func _checksum() -> void:
	var f := checksum_fields()
	for v in f:
		chain = _fnv_u32(chain, v)
	if dropped:
		return
	_own_sums[tick] = f
	_unsent_sums.append([tick, f])
	_compare(tick)


## Compares both machines' checksums of tick `t` once both are known.
func _compare(t: int) -> void:
	if not _own_sums.has(t) or not _their_sums.has(t):
		return
	var a: PackedInt64Array = _own_sums[t]
	var b: PackedInt64Array = _their_sums[t]
	_own_sums.erase(t)
	_their_sums.erase(t)
	compared += 1
	for i in mini(a.size(), b.size()):
		if a[i] != b[i]:
			_desync(t, CoopLockstepData.CHECKSUM_FIELDS[i] if i < CoopLockstepData.CHECKSUM_FIELDS.size() else str(i), a[i], b[i])
			return


## The two games differ: logs the tick and field and ends the run on this
## machine (the partner finds the same mismatch and ends his).
func _desync(t: int, field: String, mine: int, theirs: int) -> void:
	if desync_tick >= 0:
		return
	desync_tick = t
	desync_field = field
	print("[coop] DESYNC at tick %d: first differing field '%s' (here %08x, partner %08x)" % [t, field, mine, theirs])
	_flush()
	if game.run_state != Game.RunState.ENDED:
		game.end_run(false, "desync")
	_refresh_wait()


## The state hashed by the desync check: one u32 per CoopLockstepData.CHECKSUM_FIELDS
## entry. Cheap: sums over the living enemies, summons, shots and pickups in
## their (identical) list order, plus each necromancer and the offer streams.
func checksum_fields() -> PackedInt64Array:
	var out := PackedInt64Array()
	var g := game
	out.append(_hash_floats([g.elapsed, float(tick), float(g.kills), float(g.level), float(g.xp), float(g.pending_level_ups),
		float(g.enemies.total_spawned), float(g.enemies.reckoning_wave)]))
	for s in session.slots:
		var p := s.player
		out.append(_hash_floats([p.position.x, p.position.y, p.hp, p.max_hp, s.dread_rally.meter, float(s.grave_step.charges),
			1.0 if s.downed else 0.0, float(s.abilities.pick_history.size()), float(s.horde.units.size()), s.revive_progress]))
	if session.slots.size() < 2:
		out.append(0)
	var ex := 0.0
	var ey := 0.0
	var eh := 0.0
	var n := 0
	for e in g.enemies.active:
		if e.active:
			ex += e.position.x
			ey += e.position.y
			eh += e.hp
			n += 1
	out.append(_hash_floats([float(n), ex, ey, eh, g.enemies.boss.hp if g.enemies.boss != null else -1.0]))
	var ax := 0.0
	var ay := 0.0
	var ah := 0.0
	var na := 0
	for s in session.slots:
		for u in s.horde.units:
			ax += u.position.x
			ay += u.position.y
			ah += u.hp
			na += 1
	out.append(_hash_floats([float(na), ax, ay, ah]))
	var px := 0.0
	var py := 0.0
	for pr in g.projectiles.active:
		px += pr.position.x
		py += pr.position.y
	out.append(_hash_floats([float(g.projectiles.active.size()), px, py]))
	var cx := 0.0
	var cy := 0.0
	for c in g.pickups.active:
		cx += c.position.x
		cy += c.position.y
	out.append(_hash_floats([float(g.pickups.active.size()), cx, cy, float(g.chests.created), float(g.chests.active.size()), float(g.chests.open_log.size())]))
	var r := PackedFloat64Array()
	for rng: RandomNumberGenerator in [session.slots[0].abilities.offer_rng, session.slots[-1].abilities.offer_rng, g.chests._rng]:
		r.append(float(rng.state & 0xFFFFFFFF))
		r.append(float((rng.state >> 32) & 0xFFFFFFFF))
	out.append(_hash_floats(Array(r)))
	return out


## FNV-1a (32 bit) of the IEEE doubles `vals` (bit-exact: the same on every machine).
static func _hash_floats(vals: Array) -> int:
	var bytes := PackedFloat64Array(vals).to_byte_array()
	var h := 2166136261
	for b in bytes:
		h = ((h ^ b) * 16777619) & 0xFFFFFFFF
	return h


## FNV-1a step of the four bytes of `v` into `h`.
static func _fnv_u32(h: int, v: int) -> int:
	for k in 4:
		h = ((h ^ ((v >> (8 * k)) & 0xFF)) * 16777619) & 0xFFFFFFFF
	return h


# =====================================================================================
# End of run
# =====================================================================================

## The run ended on this machine (Game.end_run()): last checksum, every
## unsent frame out, no more ticks.
func on_run_end() -> void:
	if ended:
		return
	ended = true
	var f := checksum_fields()
	for v in f:
		chain = _fnv_u32(chain, v)
	print("[coop] run ended at tick %d: final state %s" % [tick, final_digest(f)])
	_flush()
	CoopNet.poll()
	_set_wait("")


## The final state's checksum fields as one hex string.
static func final_digest(f: PackedInt64Array) -> String:
	var parts := PackedStringArray()
	for v in f:
		parts.append("%08x" % v)
	return "-".join(parts)


## The autotest's lockstep line (both machines must print the same ticks,
## chain and final state; frames per side confirm the bundling).
func report_line() -> String:
	return "lockstep: slot %d | ticks %d (frozen %d) | frames sent %d, received %d (%.1f ticks per frame) | checksums compared %d, chain %08x, desync %s | delay %d..%d ticks (final %d) | stalls %d frames, longest %d ms | rounds %d | partner %s | commands %s" % [
		local, tick, frozen_ticks, frames_sent, frames_received, float(tick) / maxf(1.0, float(frames_sent)), compared, chain,
		"none" if desync_tick < 0 else "tick %d field %s" % [desync_tick, desync_field],
		delay_low, delay_high, delay, stall_frames, longest_stall_ms, rounds,
		"stayed" if not dropped else "lost at tick %d (%s), bot took over" % [drop_tick, drop_reason], str(cmds_sent)]
