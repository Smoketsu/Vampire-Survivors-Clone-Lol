## Autotest — headless self-test of a full run, enabled with `-- --autotest`
## (see GameState for options). It:
##   * seeds the RNG and fast-forwards time (Engine.time_scale with physics
##     ticks scaled to match, so each physics step is still 1/60 s of game
##     time and collision behaviour is unchanged),
##   * drives the necromancer with a simple kiting autopilot (it also dodges
##     boss telegraphs and holy zones, steers off obstacles, and walks to
##     empowered graves, crypts and graves being consecrated),
##   * auto-picks level-up cards with a policy (--policy=naive: unowned summon
##     classes and spells first so every system gets exercised; --policy=army:
##     a summoner build that levels summons and army passives first;
##     --policy=evolve: a spell build that chases all three evolutions).
##     Every policy takes an evolution card as soon as one is offered; army
##     and evolve also banish unwanted items and reroll weak hands (naive
##     never does, it plays like a careless player),
##   * exercises both Shadow Bolt aim modes: Nearest until the boss spawns,
##     then Strongest, and reports bolt damage per mode and to the boss,
##   * keeps the necromancer invulnerable (unless --mortal) until the countdown
##     has ended and the Reckoning has run for RECKONING_GRACE seconds, then
##     makes him mortal so the Reckoning kills him -> "Run Complete" screen,
##   * prints progress every 60 game seconds, plus "[metric]" lines (horde
##     size, damage taken by attacker, enemies alive by kind, XP collected)
##     that the multi-seed tuning scripts parse, and a final summary
##     (including Sir Alaric's attacks per type, stage events fired, obstacle
##     collisions resolved, stuck units, the level pacing and when the build
##     was complete), then quits with exit code 0 when the run completed, 1
##     otherwise,
##   * applies the --meta profile (none / mid / max simulated Soul Ash
##     purchases, in memory only) and reports the run's Soul Ash award and
##     its breakdown in the summary,
##   * detects stuck units: a summon or enemy that wants to move toward its
##     goal (target out of reach, anchor far away, returning...) but has not
##     moved more than STUCK_DISTANCE px in STUCK_TIME s.
class_name Autotest
extends Node

## Game seconds between progress lines (a 20-minute run prints 20 of them).
const REPORT_INTERVAL: float = 60.0
## Levels whose arrival time the summary's level-pacing line lists.
const LEVEL_MARKS := [2, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
## Elapsed game times (s) at which the summary lists the level reached.
const TIME_MARKS := [60.0, 180.0, 300.0, 600.0, 900.0, 1020.0, 1200.0]
## Radius (px) in which the autopilot flees enemies.
const FLEE_RADIUS: float = 110.0
## Radius (px) in which the autopilot walks toward XP crystals.
const XP_SEEK_RADIUS: float = 320.0
## Game seconds of Reckoning before the invulnerable autopilot turns mortal.
const RECKONING_GRACE: float = 20.0
## Radius (px) in which the autopilot walks to stage objectives.
const OBJECTIVE_SEEK_RADIUS: float = 420.0
## Distance (px) at which the autopilot starts steering off obstacles.
const OBSTACLE_LOOK: float = 22.0
## Game seconds between stuck-unit samples.
const STUCK_SAMPLE: float = 1.0
## A unit that moved less than this (px) ...
const STUCK_DISTANCE: float = 10.0
## ... over this many game seconds while wanting to move counts as stuck.
const STUCK_TIME: float = 10.0
## A following summon "wants to move" only when its anchor is farther than
## this (px); closer than that it is simply standing in formation.
const STUCK_ANCHOR_SLACK: float = 40.0
## Card priorities for --policy=army (higher = picked first).
const ARMY_PRIORITY := {"warrior": 100.0, "archer": 95.0, "mage": 98.0, "priest": 90.0, "grave_dominion": 105.0,
	"dark_command": 70.0, "necrotic_vigor": 65.0, "soul_recycling": 50.0,
	"shadow_bolt": 60.0, "shadow_blast": 55.0, "orb_shield": 40.0,
	"warding_ritual": 35.0, "soul_conduit": 30.0, "abyssal_focus": 28.0}
## Card priorities for --policy=evolve (higher = picked first): the three
## base spells and their paired passives, then the army.
const EVOLVE_PRIORITY := {"shadow_bolt": 100.0, "soul_conduit": 96.0, "shadow_blast": 94.0, "abyssal_focus": 92.0,
	"orb_shield": 90.0, "warding_ritual": 88.0, "warrior": 70.0, "priest": 66.0, "grave_dominion": 64.0,
	"mage": 62.0, "archer": 60.0, "dark_command": 50.0, "necrotic_vigor": 48.0, "soul_recycling": 40.0}
## Items each policy banishes when offered (while banish charges last).
const BANISH_IDS := {"army": ["orb_shield", "abyssal_focus"], "evolve": ["soul_recycling", "necrotic_vigor"]}
## army / evolve reroll the hand when its best card scores below this.
const REROLL_BELOW: float = 25.0
## Score of an evolution card (always taken first).
const EVOLUTION_SCORE: float = 1000.0
## Score of a fallback card (taken only when nothing else is offered).
const FALLBACK_SCORE: float = -100.0

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
## Game seconds during which 2 or more priests were alive.
var _two_priest_time: float = 0.0
## Priest wards cast while 2 or more priests were alive.
var _two_priest_wards: int = 0
## priest_wards stat seen on the previous step (to attribute new wards).
var _last_wards: int = 0
## Sum of living-summon counts over the current report window.
var _horde_sum: float = 0.0
## Number of steps in the current report window.
var _horde_n: int = 0
## Total summon deaths at the start of the current report window.
var _death_mark: int = 0
## Boss HP when the countdown reached 0:00 (-1 = not reached / no boss).
var _boss_hp_at_0: float = -1.0
## summon_dmg_from_* stats at the previous report (to print per-window deltas).
var _last_src: Dictionary = {}
## Lowest necromancer HP seen before 0:00 (the "nigh-unkillable" check).
var _min_hp: float = 9999.0
## dmg_bolt stat when the aim switched to Strongest (-1 = never switched).
var _bolt_dmg_at_switch: float = -1.0
## Guards against printing the summary twice.
var _finished: bool = false
## Instance id -> [generation, position, game time] of the stuck tracker.
var _stuck_track: Dictionary = {}
## Game time of the next stuck-unit sample.
var _next_stuck_sample: float = STUCK_SAMPLE
## Stuck episodes detected (must stay ~0).
var _stuck_units: int = 0
## Stuck episodes by unit label ("summon_warrior", "enemy_footman"...).
var _stuck_by: Dictionary = {}
## Stuck episodes where the unit was touching an obstacle.
var _stuck_at_obstacle: int = 0
## Reusable query buffer.
var _tmp: Array = []
## Game time (s) at which each level was reached, indexed by level (level 1 = 0).
var _level_time: PackedFloat32Array = PackedFloat32Array([0.0, 0.0])
## Level the necromancer had at each TIME_MARKS entry (-1 until reached).
var _level_at_mark: PackedInt32Array = PackedInt32Array()
## Game time (s) of the first level-up hand made only of fallback cards, i.e.
## every slot full and maxed, every evolution taken (-1 = never).
var _build_complete_time: float = -1.0
## Level of that hand (0 = never).
var _build_complete_level: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	seed(GameState.autotest_seed)
	var speed := GameState.autotest_speed
	Engine.time_scale = speed
	Engine.physics_ticks_per_second = int(roundf(60.0 * speed))
	Engine.max_physics_steps_per_frame = maxi(8, int(ceilf(8.0 * speed)))
	_real_start_msec = Time.get_ticks_msec()
	for _i in TIME_MARKS.size():
		_level_at_mark.append(-1)
	print("[autotest] start: seed=%d speed=%sx mortal=%s timeout=%ss policy=%s meta=%s" % [
		GameState.autotest_seed, str(speed), str(GameState.autotest_mortal), str(GameState.autotest_timeout), GameState.autotest_policy, GameState.autotest_meta])


## Called by Game after each simulation step.
func step(delta: float) -> void:
	var wards := int(game.stats.get("priest_wards", 0.0))
	if game.horde.count_of("priest") >= 2:
		_two_priest_time += delta
		_two_priest_wards += wards - _last_wards
	_last_wards = wards
	_peak["enemies"] = maxi(int(_peak["enemies"]), game.enemies.active.size())
	_peak["summons"] = maxi(int(_peak["summons"]), game.horde.units.size())
	_peak["projectiles"] = maxi(int(_peak["projectiles"]), game.projectiles.active.size())
	_peak["effects"] = maxi(int(_peak["effects"]), game.effects.active.size())
	_peak["crystals"] = maxi(int(_peak["crystals"]), game.pickups.active.size())
	if _boss_spawn_time < 0.0 and game.enemies.boss != null:
		_boss_spawn_time = game.elapsed
		print("[autotest] boss spawned at %.1f s" % game.elapsed)
		if not game.abilities.bolt_aim_strongest:
			game.abilities.toggle_bolt_aim()
			_bolt_dmg_at_switch = _bolt_damage(game.stats, "dmg_")
			print("[autotest] Shadow Bolt aim switched to %s" % game.abilities.bolt_aim_name())
	if _boss_death_time < 0.0 and game.boss_defeated:
		_boss_death_time = game.elapsed
		print("[autotest] boss defeated at %.1f s" % game.elapsed)
	if _reckoning_time < 0.0 and game.enemies.reckoning_wave > 0:
		_reckoning_time = game.elapsed
		print("[autotest] countdown reached 0:00 at %.1f s - THE RECKONING begins" % game.elapsed)
	if _reckoning_time >= 0.0 and game.player.invulnerable and game.elapsed >= _reckoning_time + RECKONING_GRACE:
		game.player.invulnerable = false
		print("[autotest] %.1f s: Reckoning wave %d reached, player made mortal" % [game.elapsed, game.enemies.reckoning_wave])
	if game.elapsed < WaveData.RUN_DURATION:
		_min_hp = minf(_min_hp, game.player.hp)
	_horde_sum += game.horde.units.size()
	_horde_n += 1
	while _level_time.size() <= game.level:
		_level_time.append(game.elapsed)
	for i in TIME_MARKS.size():
		if _level_at_mark[i] < 0 and game.elapsed >= float(TIME_MARKS[i]):
			_level_at_mark[i] = game.level
	if _boss_hp_at_0 < 0.0 and game.elapsed >= WaveData.RUN_DURATION and game.enemies.boss != null:
		_boss_hp_at_0 = game.enemies.boss.hp if game.enemies.boss.active else 0.0
	if game.elapsed >= _next_stuck_sample:
		_next_stuck_sample += STUCK_SAMPLE
		_sample_stuck()
	if game.elapsed >= _next_report:
		_next_report += REPORT_INTERVAL
		_print_metrics()
		print("[autotest] t=%s lvl=%d kills=%d enemies=%d summons=%d/%d projectiles=%d hp=%d step_avg=%.2fms" % [
			_clock(game.elapsed), game.level, game.kills, game.enemies.active.size(),
			game.horde.units.size(), game.horde.total_capacity(), game.projectiles.active.size(),
			int(game.player.hp), game.avg_step_ms()])
		print("[autotest]    unit FSM: %s" % str(game.horde.state_counts()))
	if game.elapsed >= GameState.autotest_timeout:
		game.end_run(false, "timeout")


## Samples every summon and enemy for the stuck-unit check.
func _sample_stuck() -> void:
	for u in game.horde.units:
		if u.active:
			_track(u, u.generation, u.radius, _summon_wants_move(u), "summon_" + u.unit_class)
	for e in game.enemies.active:
		if e.active:
			_track(e, e.generation, e.radius, _enemy_wants_move(e), "enemy_" + e.kind)


## Stuck bookkeeping for one unit: restart its window whenever it moved
## enough, was recycled, or has no reason to move; count an episode when
## the window reaches STUCK_TIME.
func _track(n: Node2D, gen: int, r: float, wants: bool, label: String) -> void:
	var id := n.get_instance_id()
	var rec: Variant = _stuck_track.get(id)
	if rec == null or int(rec[0]) != gen or not wants or n.position.distance_to(rec[1]) > STUCK_DISTANCE:
		_stuck_track[id] = [gen, n.position, game.elapsed]
		return
	if game.elapsed - float(rec[2]) < STUCK_TIME:
		return
	_stuck_units += 1
	_stuck_by[label] = int(_stuck_by.get(label, 0)) + 1
	var at_obstacle := game.arena.is_blocked(n.position, r + 3.0)
	if at_obstacle:
		_stuck_at_obstacle += 1
	print("[autotest] stuck unit: %s at %s (%.0f px from player, touching obstacle: %s)" % [
		label, str(n.position.round()), n.position.distance_to(game.player.position), str(at_obstacle)])
	_stuck_track[id] = [gen, n.position, game.elapsed]


## True when a summon is trying to get somewhere (not idling in formation,
## casting or fighting in reach).
func _summon_wants_move(u: SummonedUnit) -> bool:
	match u.state:
		SummonedUnit.State.RETURNING, SummonedUnit.State.RETREATING, SummonedUnit.State.REPOSITIONING:
			return true
		SummonedUnit.State.FOLLOWING, SummonedUnit.State.ACQUIRING:
			return u.position.distance_to(game.player.position + u.anchor_offset) > STUCK_ANCHOR_SLACK
		SummonedUnit.State.ENGAGING:
			var t := u.target
			if u.attack_profile == "melee" and t != null and t.active and t.generation == u.target_gen:
				return u.position.distance_to(t.position) - u.radius - t.radius > u.attack_range + UnitData.MELEE_TOLERANCE
	return false


## True when an enemy is trying to close in (not fighting a blocker, not in
## reach, not winding up a special).
func _enemy_wants_move(e: Enemy) -> bool:
	if e.engaged_timer > 0.0:
		return false
	var pl := game.player
	if e.is_boss:
		var b := e as BossAlaric
		return b.phase == BossAlaric.Phase.WALK and e.position.distance_to(pl.position) - e.radius - pl.radius > e.attack_range + 4.0
	match e.behavior:
		"consecrator":
			return e.position.distance_to(e.post_pos) > 12.0
		"ranged", "healer":
			return e.position.distance_to(pl.position) - e.radius - pl.radius > EnemyData.ADVANCE_STOP_GAP + 6.0
		"templar":
			if e.rush_state != 0:
				return false
	var t := e.target
	if t == null:
		return false
	var tr := pl.radius if t == pl else (t as SummonedUnit).radius
	return e.position.distance_to(t.position) - e.radius - tr > e.attack_range + 4.0


## Prints the per-window "[metric]" lines parsed by the tuning scripts.
func _print_metrics() -> void:
	var cc := PackedStringArray()
	for cls: String in UnitData.CLASS_ORDER:
		cc.append("%s%d/%d" % [cls.substr(0, 1), game.horde.count_of(cls), game.horde.capacity(cls)])
	print("[metric] t=%d avg_horde=%.1f now=%d cap=%d %s deaths_win=%d lvl=%d kills=%d enemies=%d hp=%d boss_hp=%d crystals=%d xp=%d" % [
		int(game.elapsed), _horde_sum / maxf(1.0, _horde_n), game.horde.units.size(), game.horde.total_capacity(), " ".join(cc),
		game.horde.total_deaths - _death_mark, game.level, game.kills, game.enemies.active.size(), int(game.player.hp),
		int(game.enemies.boss.hp) if game.enemies.boss != null else -1, game.pickups.active.size(),
		int(game.stats.get("xp_collected", 0.0))])
	var parts := PackedStringArray()
	for k: String in game.stats.keys():
		if k.begins_with("summon_dmg_from_"):
			var v := float(game.stats[k]) - float(_last_src.get(k, 0.0))
			_last_src[k] = float(game.stats[k])
			if v >= 1.0:
				parts.append("%s=%d" % [k.substr(16), int(v)])
	print("[metric]    summon dmg taken this window: " + " ".join(parts))
	var kinds := {}
	var near := 0
	for e in game.enemies.active:
		if e.active:
			kinds[e.kind] = int(kinds.get(e.kind, 0)) + 1
			if e.position.distance_to(game.player.position) < 260.0:
				near += 1
	print("[metric]    alive by kind: %s within260=%d" % [str(kinds), near])
	_horde_sum = 0.0
	_horde_n = 0
	_death_mark = game.horde.total_deaths


## Decides what to do with a level-up hand: {"action": "pick" | "reroll" |
## "banish" | "skip", "index": card}. Evolutions are always picked. army /
## evolve banish BANISH_IDS items, reroll hands scoring below REROLL_BELOW,
## and skip when the only useful card would heal an unhurt necromancer.
## Deterministic for a given offer list and charge state.
func choose_action(offers: Array[Dictionary]) -> Dictionary:
	if _build_complete_time < 0.0:
		var only_fallbacks := true  # Hand holds nothing but fallback cards.
		for o in offers:
			only_fallbacks = only_fallbacks and String(o["kind"]) == "fallback"
		if only_fallbacks:
			_build_complete_time = game.elapsed
			_build_complete_level = game.level - game.pending_level_ups + 1
			print("[autotest] build complete (only fallback cards left) at %s, level %d" % [_clock(game.elapsed), _build_complete_level])
	var best := 0
	var best_score := -INF
	for i in offers.size():
		var s := _card_score(offers[i])
		if s > best_score:
			best_score = s
			best = i
	var policy := GameState.autotest_policy
	var ab := game.abilities
	if policy != "naive" and best_score < EVOLUTION_SCORE:
		var banish_ids: Array = BANISH_IDS.get(policy, [])
		for i in offers.size():
			if ab.can_banish(offers[i]) and String(offers[i]["id"]) in banish_ids:
				return {"action": "banish", "index": i}
		if best_score < REROLL_BELOW and ab.rerolls_left > 0:
			return {"action": "reroll", "index": -1}
		if String(offers[best]["id"]) == "dark_restoration" and game.player.hp >= game.player.max_hp:
			return {"action": "skip", "index": -1}
	return {"action": "pick", "index": best}


## Policy score of one card (higher = better).
##   naive : new summon classes > new spells > new passives > lowest level.
##   army  : ARMY_PRIORITY minus a level penalty.
##   evolve: EVOLVE_PRIORITY minus a small level penalty (maxes spells).
func _card_score(o: Dictionary) -> float:
	match String(o["kind"]):
		"evolution":
			return EVOLUTION_SCORE
		"fallback":
			return FALLBACK_SCORE
	var id := String(o["id"])
	match GameState.autotest_policy:
		"army":
			return float(ARMY_PRIORITY.get(id, 0.0)) - float(o["to"]) * 8.0
		"evolve":
			return float(EVOLVE_PRIORITY.get(id, 0.0)) - float(o["to"]) * 3.0
	var s := -float(o["to"]) * 5.0
	var is_new := int(o["from"]) == 0
	match String(o["kind"]):
		"summon":
			s += 100.0 if is_new else 3.0
		"spell":
			s += 80.0 if is_new else 0.0
		"passive":
			s += 60.0 if is_new else 0.0
	return s


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
	var danger := game.enemies.stage.danger_push(p)
	if game.enemies.boss != null and game.enemies.boss.active:
		danger += game.enemies.boss.danger_push(p)
	var objective := Vector2.ZERO
	# Walk to shrines any time, to graves under consecration only when calm.
	var goal := game.enemies.stage.seek_point(p, OBJECTIVE_SEEK_RADIUS, away.length() < 0.2)
	if goal != Vector2.INF:
		objective = (goal - p).normalized()
	var avoid := game.arena.avoid_vector(p, game.player.radius, OBSTACLE_LOOK)
	var wander := Vector2.from_angle(game.elapsed * 0.3) * 0.35
	return (away * 1.5 + toward * 1.2 + objective * 1.0 + danger * 3.0 + avoid * 1.5 + wander).limit_length(1.0)


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
	var at_mark := PackedStringArray()  # "mm:ss=Ln" per TIME_MARKS entry reached.
	for i in TIME_MARKS.size():
		if _level_at_mark[i] >= 0:
			at_mark.append("%s=L%d" % [_clock(float(TIME_MARKS[i])), _level_at_mark[i]])
	var reached := PackedStringArray()  # "Ln@mm:ss" per LEVEL_MARKS entry reached.
	for lvl: int in LEVEL_MARKS:
		if lvl < _level_time.size():
			reached.append("L%d@%s" % [lvl, _clock(_level_time[lvl])])
	print("[autotest] level pacing: %s | reached: %s" % [" ".join(at_mark), " ".join(reached)])
	print("[autotest] build complete: %s" % ("at %s, level %d" % [_clock(_build_complete_time), _build_complete_level] if _build_complete_time >= 0.0 else "no"))
	print("[autotest] horde: %d alive / capacity %d (%s)" % [int(summary["horde_total"]), int(summary["horde_capacity"]), ", ".join(classes)])
	print("[autotest] summons spawned: %d, died: %d, hard recalls: %d" % [game.horde.total_spawned, game.horde.total_deaths, game.horde.hard_recalls])
	var boss_line := "boss spawned: %s" % ("yes at %.1f s" % _boss_spawn_time if summary["boss_spawned"] else "no")
	boss_line += " | boss defeated: %s" % ("yes at %.1f s" % _boss_death_time if summary["boss_defeated"] else "no")
	if summary["boss_spawned"]:
		boss_line += " | boss HP left: %d / %d" % [int(summary["boss_hp"]), int(summary["boss_max_hp"])]
	print("[autotest] " + boss_line)
	print("[autotest] player HP: %d / %d (invulnerable: %s)" % [int(summary["player_hp"]), int(summary["player_max_hp"]), str(game.player.invulnerable)])
	print("[autotest] picks (%d): %s" % [(summary["picks"] as PackedStringArray).size(), ", ".join(summary["picks"])])
	var st_all: Dictionary = summary["stats"]
	var ward_rate := float(_two_priest_wards) / (_two_priest_time / 60.0) if _two_priest_time > 1.0 else 0.0
	print("[autotest] priest wards: %d total, absorbed %d dmg | %d wards in %.0f s with 2+ priests alive (%.1f / min) | priest heals: %d" % [
		int(st_all.get("priest_wards", 0.0)), int(st_all.get("ward_absorbed", 0.0)), _two_priest_wards, _two_priest_time, ward_rate, int(st_all.get("priest_heals", 0.0))])
	var ab := game.abilities
	print("[autotest] evolutions: %s" % (", ".join(ab.evolution_history) if not ab.evolution_history.is_empty() else "none"))
	var syn := game.horde.synergies
	print("[autotest] synergies active at end: %s | activations: %s" % [
		", ".join(syn.active_ids()) if not syn.active_ids().is_empty() else "none",
		", ".join(syn.activation_log) if not syn.activation_log.is_empty() else "none"])
	print("[autotest] level-up actions: rerolls used %d/%d, banishes used %d/%d (banished: %s), skips %d" % [
		ab.rerolls_max - ab.rerolls_left, ab.rerolls_max, ab.banishes_max - ab.banishes_left, ab.banishes_max,
		", ".join(PackedStringArray(ab.banished.keys())) if not ab.banished.is_empty() else "none", ab.skips_used])
	# Shadow Bolt damage includes its Void Barrage evolution (bolts + shards).
	var bolt_total := _bolt_damage(st, "dmg_")
	var bolt_nearest := bolt_total if _bolt_dmg_at_switch < 0.0 else _bolt_dmg_at_switch
	print("[autotest] shadow bolt: %d dmg in Nearest mode, %d dmg in Strongest mode; to boss: %d of %d total boss dmg" % [
		int(bolt_nearest), int(bolt_total - bolt_nearest), int(_bolt_damage(st, "bossdmg_")), int(_sum_prefix(st, "bossdmg_"))])
	print("[autotest] stats: " + " ".join(stat_parts))
	var atk := PackedStringArray()
	for id: String in EnemyData.SPECIALS:
		atk.append("%s=%d" % [id, int(st.get("boss_atk_" + id, 0.0))])
	print("[autotest] boss attacks: %s | wrath: %s | hammer soaked by undead: %d | charges stopped by undead: %d (shielding the player: %d) | judgment hits: %d | call soldiers: %d | holy zones boss/grave: %d/%d" % [
		" ".join(atk), "yes" if st.has("boss_phase2") else "no", int(st.get("boss_hammer_soaked", 0.0)), int(st.get("boss_charge_stopped", 0.0)), int(st.get("boss_charge_blocked", 0.0)),
		int(st.get("boss_judgment_hits", 0.0)), int(st.get("boss_call_soldiers", 0.0)), int(st.get("holy_zones_boss", 0.0)), int(st.get("holy_zones_grave", 0.0))])
	var fired := game.enemies.stage.fired
	print("[autotest] stage events fired (%d): %s" % [fired.size(), ", ".join(fired)])
	print("[autotest] templar charges: %d (body-blocked by warriors: %d) | temporary summons spawned: %d" % [
		int(st.get("templar_charges", 0.0)), int(st.get("templar_charges_blocked", 0.0)), game.horde.temp_spawned])
	print("[autotest] obstacle collisions resolved: player=%d summons=%d enemies=%d" % [
		game.arena.resolved_player, game.arena.resolved_summons, game.arena.resolved_enemies])
	print("[autotest] stuck_units=%d (touching an obstacle: %d) %s" % [_stuck_units, _stuck_at_obstacle, str(_stuck_by)])
	print("[metric] boss_hp_at_0=%d min_hp_before_0=%d" % [int(_boss_hp_at_0), int(_min_hp)])
	print("[autotest] peaks: enemies=%d summons=%d projectiles=%d effects=%d crystals=%d" % [
		int(_peak["enemies"]), int(_peak["summons"]), int(_peak["projectiles"]), int(_peak["effects"]), int(_peak["crystals"])])
	print("[autotest] nodes created (pools): enemies=%d summons=%d projectiles=%d effects=%d crystals=%d" % [
		game.enemies.created_nodes, game.horde.created_nodes, game.projectiles.created, game.effects.created, game.pickups.created])
	print("[autotest] simulation step: avg %.2f ms, worst %.2f ms" % [game.avg_step_ms(), float(game.worst_step_usec) / 1000.0])
	_print_soul_ash(summary)
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	get_tree().quit(0 if summary["victory"] else 1)


## Prints the meta profile and the run's Soul Ash award (Meta.award_run()).
func _print_soul_ash(summary: Dictionary) -> void:
	print("[autotest] meta upgrades (--meta=%s): %s | revivals used: %d" % [
		GameState.autotest_meta, game.meta.describe(), int(game.stats.get("revivals", 0.0))])
	var ash: Dictionary = summary.get("soul_ash", {})
	if ash.is_empty():
		return
	var parts: Dictionary = ash["parts"]
	print("[autotest] soul ash: +%d (time %d [%s] + kills %d [%d] + elites %d [%d] + boss %d + reckoning %d [%.1f s] = %d, bonus +%d%% = +%d) | bounty %d | new total %d | saved: %s" % [
		int(ash["total"]), int(parts["time"]), _clock(float(ash["time_survived"])), int(parts["kills"]), int(ash["kill_count"]),
		int(parts["elites"]), int(ash["elite_count"]), int(parts["boss"]), int(parts["reckoning"]), float(ash["reckoning_seconds"]),
		int(ash["subtotal"]), int(roundf(float(ash["bonus_pct"]) * 100.0)), int(ash["bonus"]), int(ash["bounty"]), int(ash["new_total"]),
		str(Meta.can_write())])


## Shadow Bolt damage stat with `prefix` ("dmg_" / "bossdmg_"), including the
## Void Barrage bolts and shards.
static func _bolt_damage(st: Dictionary, prefix: String) -> float:
	var total := 0.0
	for src: String in ["bolt", "void", "void_shard"]:
		total += float(st.get(prefix + src, 0.0))
	return total


## Sum of every stat whose key starts with `prefix`.
static func _sum_prefix(st: Dictionary, prefix: String) -> float:
	var total := 0.0
	for k: String in st.keys():
		if k.begins_with(prefix):
			total += float(st[k])
	return total


## Formats seconds as mm:ss.
static func _clock(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [floori(float(s) / 60.0), s % 60]
