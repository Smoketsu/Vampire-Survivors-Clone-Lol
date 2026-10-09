## Autotest — headless self-test of a full run, enabled with `-- --autotest`
## (see GameState for options). It:
##   * seeds the RNG and fast-forwards time (Engine.time_scale with physics
##     ticks scaled to match, so each physics step is still 1/60 s of game
##     time and collision behaviour is unchanged),
##   * drives the necromancer with a simple kiting autopilot,
##   * auto-picks level-up cards (unowned summon classes and spells first, so
##     every system gets exercised),
##   * keeps the necromancer invulnerable (unless --mortal) until the countdown
##     has ended and the Reckoning has run for RECKONING_GRACE seconds, then
##     makes him mortal so the Reckoning kills him -> "Run Complete" screen,
##   * prints progress every 30 game seconds and a final summary, then quits
##     with exit code 0 when the run completed, 1 otherwise.
class_name Autotest
extends Node

## Game seconds between progress lines.
const REPORT_INTERVAL: float = 30.0
## Radius (px) in which the autopilot flees enemies.
const FLEE_RADIUS: float = 110.0
## Radius (px) in which the autopilot walks toward XP crystals.
const XP_SEEK_RADIUS: float = 320.0
## Game seconds of Reckoning before the invulnerable autopilot turns mortal.
const RECKONING_GRACE: float = 20.0

## Owning run.
var game: Game
## Game time of the next progress line.
var _next_report: float = REPORT_INTERVAL
## Game time the boss spawned (-1 until then).
var _boss_spawn_time: float = -1.0
## Game time the boss died (-1 if alive / never spawned).
var _boss_death_time: float = -1.0
## Game time the Reckoning began (-1 until then).
var _reckoning_time: float = -1.0
## Peak simultaneous entity counts.
var _peak: Dictionary = {"enemies": 0, "summons": 0, "projectiles": 0, "effects": 0, "crystals": 0}
## Real-time start (ms) for the wall-clock duration line.
var _real_start_msec: int = 0
## Guards against printing the summary twice.
var _finished: bool = false
## Reusable query buffer.
var _tmp: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	seed(GameState.autotest_seed)
	var speed := GameState.autotest_speed
	Engine.time_scale = speed
	Engine.physics_ticks_per_second = int(roundf(60.0 * speed))
	Engine.max_physics_steps_per_frame = maxi(8, int(ceilf(8.0 * speed)))
	_real_start_msec = Time.get_ticks_msec()
	print("[autotest] start: seed=%d speed=%sx mortal=%s timeout=%ss" % [
		GameState.autotest_seed, str(speed), str(GameState.autotest_mortal), str(GameState.autotest_timeout)])


## Called by Game after each simulation step.
func step(_delta: float) -> void:
	_peak["enemies"] = maxi(int(_peak["enemies"]), game.enemies.active.size())
	_peak["summons"] = maxi(int(_peak["summons"]), game.horde.units.size())
	_peak["projectiles"] = maxi(int(_peak["projectiles"]), game.projectiles.active.size())
	_peak["effects"] = maxi(int(_peak["effects"]), game.effects.active.size())
	_peak["crystals"] = maxi(int(_peak["crystals"]), game.pickups.active.size())
	if _boss_spawn_time < 0.0 and game.enemies.boss != null:
		_boss_spawn_time = game.elapsed
		print("[autotest] boss spawned at %.1f s" % game.elapsed)
	if _boss_death_time < 0.0 and game.boss_defeated:
		_boss_death_time = game.elapsed
		print("[autotest] boss defeated at %.1f s" % game.elapsed)
	if _reckoning_time < 0.0 and game.enemies.reckoning_wave > 0:
		_reckoning_time = game.elapsed
		print("[autotest] countdown reached 0:00 at %.1f s - THE RECKONING begins" % game.elapsed)
	if _reckoning_time >= 0.0 and game.player.invulnerable and game.elapsed >= _reckoning_time + RECKONING_GRACE:
		game.player.invulnerable = false
		print("[autotest] %.1f s: Reckoning wave %d reached, player made mortal" % [game.elapsed, game.enemies.reckoning_wave])
	if game.elapsed >= _next_report:
		_next_report += REPORT_INTERVAL
		print("[autotest] t=%s lvl=%d kills=%d enemies=%d summons=%d/%d projectiles=%d hp=%d step_avg=%.2fms" % [
			_clock(game.elapsed), game.level, game.kills, game.enemies.active.size(),
			game.horde.units.size(), game.horde.total_capacity(), game.projectiles.active.size(),
			int(game.player.hp), game.avg_step_ms()])
		print("[autotest]    unit FSM: %s" % str(game.horde.state_counts()))
	if game.elapsed >= GameState.autotest_timeout:
		game.end_run(false, "timeout")


## Chooses a card index: new summon classes > new spells > new passives >
## lowest resulting level. Deterministic for a given offer list.
func choose_card(offers: Array[Dictionary]) -> int:
	var best := 0
	var best_score := -INF
	for i in offers.size():
		var o := offers[i]
		var s := -float(o["to"]) * 5.0
		var is_new := int(o["from"]) == 0
		match String(o["kind"]):
			"summon":
				s += 100.0 if is_new else 3.0
			"spell":
				s += 80.0 if is_new else 0.0
			"passive":
				s += 60.0 if is_new else 0.0
		if s > best_score:
			best_score = s
			best = i
	return best


## Autopilot: flee nearby enemies, drift toward XP, dodge boss telegraphs,
## plus a slow circular wander so the run covers ground.
func get_move_vector() -> Vector2:
	var p := game.player.position
	var away := Vector2.ZERO
	game.enemy_grid.query(p, FLEE_RADIUS, _tmp)
	for e: Enemy in _tmp:
		if not e.active:
			continue
		var diff := p - e.position
		var d := maxf(diff.length(), 1.0)
		away += diff / d * (1.0 - d / FLEE_RADIUS)
	var toward := Vector2.ZERO
	var best_d := XP_SEEK_RADIUS
	for c in game.pickups.active:
		var d := p.distance_to(c.position)
		if d < best_d:
			best_d = d
			toward = (c.position - p) / maxf(d, 1.0)
	var danger := Vector2.ZERO
	if game.enemies.boss != null and game.enemies.boss.active:
		danger = game.enemies.boss.danger_push(p)
	var wander := Vector2.from_angle(game.elapsed * 0.3) * 0.35
	return (away * 1.5 + toward * 1.2 + danger * 3.0 + wander).limit_length(1.0)


## Prints the final summary and quits the engine.
func finish(summary: Dictionary) -> void:
	if _finished:
		return
	_finished = true
	var real_s := float(Time.get_ticks_msec() - _real_start_msec) / 1000.0
	var counts: Dictionary = summary["horde_counts"]
	var caps: Dictionary = summary["horde_caps"]
	var classes := PackedStringArray()
	for cls: String in UnitData.CLASS_ORDER:
		classes.append("%s %d/%d" % [cls, int(counts[cls]), int(caps[cls])])
	var stat_parts := PackedStringArray()
	var st: Dictionary = summary["stats"]
	var keys := st.keys()
	keys.sort()
	for k: String in keys:
		stat_parts.append("%s=%d" % [k, int(st[k])])
	print("[autotest] ===== GRAVEBOUND AUTOTEST SUMMARY =====")
	print("[autotest] result: %s (%s)" % ["VICTORY / RUN COMPLETE" if summary["victory"] else "NOT COMPLETED", summary["reason"]])
	print("[autotest] time reached: %s elapsed (%.1f s game time, %.1f s real time); past 0:00: %.1f s; Reckoning waves: %d" % [
		_clock(summary["time"]), float(summary["time"]), real_s, float(summary["time_past_zero"]), int(summary["reckoning_waves"])])
	print("[autotest] kills: %d | level: %d" % [int(summary["kills"]), int(summary["level"])])
	print("[autotest] horde: %d alive / capacity %d (%s)" % [int(summary["horde_total"]), int(summary["horde_capacity"]), ", ".join(classes)])
	print("[autotest] summons spawned: %d, died: %d, hard recalls: %d" % [game.horde.total_spawned, game.horde.total_deaths, game.horde.hard_recalls])
	var boss_line := "boss spawned: %s" % ("yes at %.1f s" % _boss_spawn_time if summary["boss_spawned"] else "no")
	boss_line += " | boss defeated: %s" % ("yes at %.1f s" % _boss_death_time if summary["boss_defeated"] else "no")
	if summary["boss_spawned"]:
		boss_line += " | boss HP left: %d / %d" % [int(summary["boss_hp"]), int(summary["boss_max_hp"])]
	print("[autotest] " + boss_line)
	print("[autotest] player HP: %d / %d (invulnerable: %s)" % [int(summary["player_hp"]), int(summary["player_max_hp"]), str(game.player.invulnerable)])
	print("[autotest] picks (%d): %s" % [(summary["picks"] as PackedStringArray).size(), ", ".join(summary["picks"])])
	print("[autotest] stats: " + " ".join(stat_parts))
	print("[autotest] peaks: enemies=%d summons=%d projectiles=%d effects=%d crystals=%d" % [
		int(_peak["enemies"]), int(_peak["summons"]), int(_peak["projectiles"]), int(_peak["effects"]), int(_peak["crystals"])])
	print("[autotest] nodes created (pools): enemies=%d summons=%d projectiles=%d effects=%d crystals=%d" % [
		game.enemies.created_nodes, game.horde.created_nodes, game.projectiles.created, game.effects.created, game.pickups.created])
	print("[autotest] simulation step: avg %.2f ms, worst %.2f ms" % [game.avg_step_ms(), float(game.worst_step_usec) / 1000.0])
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	get_tree().quit(0 if summary["victory"] else 1)


## Formats seconds as mm:ss.
static func _clock(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [floori(float(s) / 60.0), s % 60]
