## ArmyStance — the army's current stance for ONE run (owner-approved Army
## Stances, StanceData; GDD §15.0). Game owns one as `game.stance`; it is
## rebuilt with the Game node, so every run (and every Restart) starts in
## StanceData.DEFAULT_ID (Escort).
##   * State: the current stance id, the switch lockout (game time) and the
##     necromancer's last non-zero move direction (the Spearhead wedge points
##     along it).
##   * Requests: request(id) from the keys / right stick (handle_input()),
##     the autotest stance bot or --stance; a locked stance (Spearhead before
##     its Ossuary unlock, MetaModifiers.unlocks()) shows a banner once per
##     run and does nothing else. `force` ignores the lock and the lockout.
##   * Numbers: the horde director reads the stance's overrides here
##     (engage_radius(), soft_recall(), formation_pull(), jitter(), shape())
##     in its effective-stat and formation code; bonus() returns a flavour
##     bonus only while StanceData.BONUSES_ENABLED.
##   * A change refreshes every unit's effective stats through the director
##     (HordeDirector.apply_stance()), plays the command sound, and starts
##     the HUD banner and the ground outline (read by StanceBar / StanceOutline
##     through changed_at).
##   * Summary stats (autotest): time, kills, army damage taken, hard recalls
##     and the largest / mean unit distance from the necromancer per stance,
##     plus the number of switches. They live here, NOT in game.stats, so the
##     long-standing "stats:" summary line of an Escort-only run is unchanged.
## No RNG anywhere: runs stay deterministic per seed.
class_name ArmyStance
extends RefCounted

## Owning run.
var game: Game
## Current stance id (StanceData.ORDER).
var current: String = StanceData.DEFAULT_ID
## Game time (Game.elapsed) of the last change (-INF = never changed).
var changed_at: float = -INF
## Game time before which a new change is refused (switch lockout).
var locked_until: float = 0.0
## Last non-zero movement direction of the necromancer (unit vector),
## turned toward a new direction at StanceData.SPEAR_TURN_RATE.
var move_dir: Vector2 = Vector2.RIGHT
## True once the "locked stance" banner was shown this run.
var locked_banner_shown: bool = false
## Game time the locked banner was shown (-INF = never).
var locked_banner_at: float = -INF
## True while the right stick may trigger a flick (re-armed when released).
var _stick_armed: bool = true
## Joypad axis index -> last value (-1..1) seen in a motion event.
var _axes: Dictionary = {}
## Stance changes this run (the initial stance is not a change).
var switches: int = 0
## Stance id -> {"time", "kills", "army_dmg", "recalls", "max_spread",
## "spread_sum", "spread_n", "entered"} (see _new_bucket()).
var per_stance: Dictionary = {}
## game.kills at the previous step (kill attribution).
var _last_kills: int = 0
## damage_to_summons stat at the previous step (army damage attribution).
var _last_army_dmg: float = 0.0
## horde.hard_recalls at the previous step.
var _last_recalls: int = 0
## Game time of the next army-spread sample.
var _next_spread: float = 0.0


func _init(p_game: Game) -> void:
	game = p_game
	for id: String in StanceData.ORDER:
		per_stance[id] = _new_bucket()


## Empty per-stance stats bucket.
static func _new_bucket() -> Dictionary:
	return {"time": 0.0, "kills": 0, "army_dmg": 0.0, "recalls": 0, "max_spread": 0.0,
		"spread_sum": 0.0, "spread_n": 0, "entered": 0}


# =====================================================================================
# Numbers read by the horde director
# =====================================================================================

## Definition of the current stance (StanceData.STANCES row).
func def() -> Dictionary:
	return StanceData.def(current)


## Formation shape of the current stance ("escort", "onslaught", "spearhead", "ring").
func shape() -> String:
	return String(def()["shape"])


## Engagement / chase leash (px) before Bound Souls.
func engage_radius() -> float:
	return float(def()["engage_radius"])


## Soft-recall distance (px) before Bound Souls.
func soft_recall() -> float:
	return float(def()["soft_recall"])


## Multiplier on every class's formation pull (w_formation).
func formation_pull() -> float:
	return float(def()["formation_pull"])


## Multiplier on the per-unit angular jitter of formation posts.
func jitter() -> float:
	return float(def()["jitter"])


## Flavour bonus `key` of the current stance (0 while the bonuses are off or
## the stance has none). Keys: attack_speed, front_push, damage_taken_reduction.
func bonus(key: String) -> float:
	if not StanceData.BONUSES_ENABLED:
		return 0.0
	return float((def()["bonus"] as Dictionary).get(key, 0.0))


# =====================================================================================
# Unlocks and requests
# =====================================================================================

## True when stance `id` may be used this run (no unlock needed, or the
## Ossuary unlock is owned; read through MetaModifiers).
func is_unlocked(id: String) -> bool:
	var stat := String(StanceData.def(id)["unlock_stat"])  # Required meta stat ("" = none).
	return stat == "" or game.meta.unlocks(stat)


## Seconds of switch lockout left (0 when a change is allowed).
func lockout_left() -> float:
	return maxf(0.0, locked_until - game.elapsed)


## Asks for stance `id`. Refused (false) while locked out, when already in
## it, or when it is locked (the locked banner is shown once per run).
## `force` (autotest --stance) ignores the lock and the lockout.
func request(id: String, force: bool = false) -> bool:
	if not StanceData.STANCES.has(id) or id == current:
		return false
	if not force:
		if not is_unlocked(id):
			if not locked_banner_shown:
				locked_banner_shown = true
				locked_banner_at = game.elapsed
			return false
		if game.elapsed < locked_until:
			return false
	_change_to(id)
	return true


## Applies a stance change: new numbers for every unit (HordeDirector), the
## lockout, the feedback (sound, banner, outline) and the switch counters.
func _change_to(id: String) -> void:
	current = id
	switches += 1
	(per_stance[id] as Dictionary)["entered"] = int(per_stance[id]["entered"]) + 1
	changed_at = game.elapsed
	locked_until = game.elapsed + StanceData.SWITCH_LOCKOUT
	game.horde.apply_stance()
	Sfx.play(StanceData.SOUND_ID)


## Routes a player input event: the stance keys (StanceData.ACTIONS) pick a
## stance; right-stick motion picks one with a flick that must be released
## (re-armed) before the next one counts. Called by Game._unhandled_input
## only while the run is playing (no menu open). Returns true if consumed.
func handle_input(event: InputEvent) -> bool:
	var motion := event as InputEventJoypadMotion
	if motion != null:
		return _handle_stick(motion)
	for i in StanceData.ACTIONS.size():
		if event.is_action_pressed(StanceData.ACTIONS[i]):
			request(StanceData.ORDER[i])
			return true
	return false


## Right-stick flick: tracks the axes, then the stance action whose bound
## axis direction is pushed past StanceData.STICK_FLICK wins while armed
## (the strongest on a diagonal); every stance direction must fall back
## under StanceData.STICK_REARM before the next flick counts.
func _handle_stick(motion: InputEventJoypadMotion) -> bool:
	_axes[motion.axis] = motion.axis_value
	var best := -1  # Index of the strongest stance direction.
	var best_v := 0.0  # Its deflection (0..1).
	var any := false  # Any stance direction above the re-arm level.
	for i in StanceData.ACTIONS.size():
		var v := _action_deflection(StanceData.ACTIONS[i])  # 0..1 toward this stance.
		if v > StanceData.STICK_REARM:
			any = true
		if v >= StanceData.STICK_FLICK and v > best_v:
			best_v = v
			best = i
	if not _stick_armed:
		if not any:
			_stick_armed = true
		return false
	if best < 0:
		return false
	_stick_armed = false
	request(StanceData.ORDER[best])
	return true


## Deflection 0..1 of the stick toward `action`'s joypad-axis binding (the
## largest over its InputEventJoypadMotion events; 0 if it has none).
func _action_deflection(action: String) -> float:
	var out := 0.0
	for ev in InputMap.action_get_events(action):
		var jm := ev as InputEventJoypadMotion
		if jm == null:
			continue
		var v := float(_axes.get(jm.axis, 0.0))  # Current value of that axis.
		if signf(v) == signf(jm.axis_value):
			out = maxf(out, absf(v))
	return out


# =====================================================================================
# Per-tick bookkeeping
# =====================================================================================

## Called by Game every physics tick (before the horde): tracks the move
## direction and the per-stance summary stats. No gameplay effect.
func step(delta: float) -> void:
	var v := game.player.velocity  # Necromancer velocity this tick.
	if v.length_squared() > 1.0:
		move_dir = move_dir.slerp(v.normalized(), clampf(delta * StanceData.SPEAR_TURN_RATE, 0.0, 1.0)).normalized()
	var b: Dictionary = per_stance[current]  # Stats bucket of the current stance.
	b["time"] = float(b["time"]) + delta
	b["kills"] = int(b["kills"]) + (game.kills - _last_kills)
	_last_kills = game.kills
	var dmg := float(game.stats.get("damage_to_summons", 0.0))  # Army damage taken so far.
	b["army_dmg"] = float(b["army_dmg"]) + (dmg - _last_army_dmg)
	_last_army_dmg = dmg
	b["recalls"] = int(b["recalls"]) + (game.horde.hard_recalls - _last_recalls)
	_last_recalls = game.horde.hard_recalls
	if game.elapsed >= _next_spread:
		_next_spread = game.elapsed + StanceData.SPREAD_SAMPLE
		_sample_spread(b)


## Records the largest and the mean unit distance from the necromancer.
func _sample_spread(b: Dictionary) -> void:
	var p := game.player.position
	var far := 0.0  # Largest distance this sample (px).
	var sum := 0.0  # Sum of distances this sample (px).
	var n := 0  # Units sampled.
	for u in game.horde.units:
		if not u.active:
			continue
		var d := u.position.distance_to(p)
		far = maxf(far, d)
		sum += d
		n += 1
	if n == 0:
		return
	b["max_spread"] = maxf(float(b["max_spread"]), far)
	b["spread_sum"] = float(b["spread_sum"]) + sum / float(n)
	b["spread_n"] = int(b["spread_n"]) + 1


## One summary line per stance plus the switch count (autotest).
func summary_line() -> String:
	var parts := PackedStringArray()
	for id: String in StanceData.ORDER:
		var b: Dictionary = per_stance[id]
		var mean := float(b["spread_sum"]) / float(b["spread_n"]) if int(b["spread_n"]) > 0 else 0.0  # Mean unit distance (px).
		parts.append("%s: %.0fs entered %d kills %d army_dmg %d recalls %d spread max %.0f mean %.0f" % [
			id, float(b["time"]), int(b["entered"]), int(b["kills"]), int(b["army_dmg"]), int(b["recalls"]),
			float(b["max_spread"]), mean])
	return "switches %d | final %s | %s" % [switches, current, " | ".join(parts)]
