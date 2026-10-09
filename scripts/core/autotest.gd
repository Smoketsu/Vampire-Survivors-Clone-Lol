## Autotest — headless self-test of a full run, enabled with `-- --autotest`
## (see GameState for options). It:
##   * seeds the RNG and fast-forwards time (Engine.time_scale with physics
##     ticks scaled to match, so each physics step is still 1/60 s of game
##     time and collision behaviour is unchanged),
##   * drives the necromancer with a simple kiting autopilot,
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
##   * prints progress every 30 game seconds, plus "[metric]" lines (horde
##     size, damage taken by attacker, enemies alive by kind) that the
##     multi-seed tuning scripts parse, and a final summary, then quits
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
	print("[autotest] start: seed=%d speed=%sx mortal=%s timeout=%ss policy=%s" % [
		GameState.autotest_seed, str(speed), str(GameState.autotest_mortal), str(GameState.autotest_timeout), GameState.autotest_policy])


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
	if _boss_hp_at_0 < 0.0 and game.elapsed >= WaveData.RUN_DURATION and game.enemies.boss != null:
		_boss_hp_at_0 = game.enemies.boss.hp if game.enemies.boss.active else 0.0
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


## Prints the per-window "[metric]" lines parsed by the tuning scripts.
func _print_metrics() -> void:
	var cc := PackedStringArray()
	for cls: String in UnitData.CLASS_ORDER:
		cc.append("%s%d/%d" % [cls.substr(0, 1), game.horde.count_of(cls), game.horde.capacity(cls)])
	print("[metric] t=%d avg_horde=%.1f now=%d cap=%d %s deaths_win=%d lvl=%d kills=%d enemies=%d hp=%d boss_hp=%d crystals=%d" % [
		int(game.elapsed), _horde_sum / maxf(1.0, _horde_n), game.horde.units.size(), game.horde.total_capacity(), " ".join(cc),
		game.horde.total_deaths - _death_mark, game.level, game.kills, game.enemies.active.size(), int(game.player.hp),
		int(game.enemies.boss.hp) if game.enemies.boss != null else -1, game.pickups.active.size()])
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
		LevelUpData.REROLLS - ab.rerolls_left, LevelUpData.REROLLS, LevelUpData.BANISHES - ab.banishes_left, LevelUpData.BANISHES,
		", ".join(PackedStringArray(ab.banished.keys())) if not ab.banished.is_empty() else "none", ab.skips_used])
	# Shadow Bolt damage includes its Void Barrage evolution (bolts + shards).
	var bolt_total := _bolt_damage(st, "dmg_")
	var bolt_nearest := bolt_total if _bolt_dmg_at_switch < 0.0 else _bolt_dmg_at_switch
	print("[autotest] shadow bolt: %d dmg in Nearest mode, %d dmg in Strongest mode; to boss: %d of %d total boss dmg" % [
		int(bolt_nearest), int(bolt_total - bolt_nearest), int(_bolt_damage(st, "bossdmg_")), int(_sum_prefix(st, "bossdmg_"))])
	print("[autotest] stats: " + " ".join(stat_parts))
	print("[metric] boss_hp_at_0=%d min_hp_before_0=%d" % [int(_boss_hp_at_0), int(_min_hp)])
	print("[autotest] peaks: enemies=%d summons=%d projectiles=%d effects=%d crystals=%d" % [
		int(_peak["enemies"]), int(_peak["summons"]), int(_peak["projectiles"]), int(_peak["effects"]), int(_peak["crystals"])])
	print("[autotest] nodes created (pools): enemies=%d summons=%d projectiles=%d effects=%d crystals=%d" % [
		game.enemies.created_nodes, game.horde.created_nodes, game.projectiles.created, game.effects.created, game.pickups.created])
	print("[autotest] simulation step: avg %.2f ms, worst %.2f ms" % [game.avg_step_ms(), float(game.worst_step_usec) / 1000.0])
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	get_tree().quit(0 if summary["victory"] else 1)


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
