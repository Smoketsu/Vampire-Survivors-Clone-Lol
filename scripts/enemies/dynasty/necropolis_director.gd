## NecropolisDirector — the stage systems of the Necropolis of Sand (temporary
## Act XII stage 34, final stage 19; GDD §15.0 "The Necropolis of Sand (Act
## XII phase 2)"; owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md
## Part 3, "Stage A: The Necropolis of Sand"), owned and stepped by
## EnemyDirector on a stage whose STAGE has a "necropolis" config
## (NecropolisStage.NECROPOLIS; `game.enemies.necropolis`, null elsewhere). The
## zones are MarchDirector's; Rebirth, the Black Land, Heka and the Devourer's
## Hour the shared DynastyRules'. Here:
##   * THE CANOPIC JARS (the stage mechanic, "Jars sit beside tombs. Break one
##     and Rebirth stops in its radius. This teaches the core rule"): from
##     jars.first s, every jars.every s (until jars.until) a jar rises
##     jars.min..jars.max px from a standing necromancer (the seeded gameplay
##     RNG) BESIDE A TOMB: the nearest tomb obstacle (jars.tomb_kinds) in the
##     arena cells round that point, the jar set at its foot; none near: the
##     point itself. A telegraph circle shows for jars.warn s first; at most
##     jars.max_alive stand or rise at once. THE ONE JAR PLACER:
##     place_jar_near() (Anubis's Procession places his through it too);
##     the jar itself is Rebirth's (Rebirth.place_jar(): it seals the Names
##     within 300 px; broken, they crumble). The stub's own jar clock is off
##     (STAGE "jars": {"every": 0.0}).
##     A jar left farther than jars.abandon_reach px from every necromancer
##     for jars.abandon_after s SINKS back into the sand (not broken: its
##     Names crumble with it), so the jars follow the march.
##   * NO JARS LEFT (the stage's achievement, the brief): when the stage boss
##     (Anubis) falls on the Necropolis with every jar that rose on it broken
##     (none standing, none rising, none sunk, at least one placed), the run stat
##     necropolis_no_jars_left is set (MetaProgress counts the runs, lifetime
##     no_jars_left_runs, MetaData "no_jars_left"; it unlocks Embalmed Bones).
##   * THE SANDSTORM PASS (zone III): one more Sandstorm at pass_storm.at s
##     for pass_storm.duration s (Sandstorm.force(), THE public call; "the
##     Necropolis's Sandstorm Pass may blow longer").
##   * THE SAND COLOSSUS ("colossus" event): the stage miniboss, spawned on the
##     spawn ring with an escort and tracked (objective, kill time); his kit
##     registers him on the HUD's miniboss bar and pays his XP burst.
##   * The HUD objective while the Colossus stands, or while a jar stands near.
##   * seek_point(): the army bot walks to the nearest standing jar when calm.
## Deterministic: only the seeded global RNG (the jars' points, where the
## Colossus comes in) and the arena's own cells. Stats: necropolis_jars,
## necropolis_jars_<tag>, necropolis_jars_beside_tomb, necropolis_jars_refused,
## necropolis_jars_sunk,
## necropolis_no_jars_left, necropolis_pass_storm, necropolis_colossus_spawned,
## necropolis_colossus_killed.
class_name NecropolisDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (NecropolisStage.NECROPOLIS).
var config: Dictionary = {}
## Log of Necropolis events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Jars placed on this stage (stage clock and the Procession).
var placed: int = 0
## Of those, set beside a tomb.
var beside_tomb: int = 0
## Jars that sank back into the sand, left far behind (not broken).
var sunk: int = 0
## True once the stage boss fell this run.
var boss_down: bool = false
## True once No Jars Left was earned this run.
var no_jars_left: bool = false
## "m:ss" the Sand Colossus fell ("" while alive / never spawned).
var colossus_time: String = ""
## Jars rising: [at (Vector2), game time it stands (float), tag (String),
## beside a tomb (bool)].
var _rising: Array = []
## True when the last tomb_spot() found a tomb.
var _spot_tomb: bool = false
## Game time (s) the next stage jar starts rising (INF = none).
var _next_jar: float = INF
## True once the Sandstorm Pass's own storm blew.
var _pass_done: bool = false
## True once the boss signal is connected.
var _hooked: bool = false
## Jar -> [its generation, seconds it has stood beyond jars.abandon_reach of
## every necromancer] (the sinking clock).
var _far: Dictionary = {}
## The Sand Colossus once spawned (null before / after; generation-checked).
var _col: Enemy = null
## Generation of `_col` when he spawned.
var _col_gen: int = 0


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	var now := game.elapsed
	if not _hooked:
		_hooked = true
		game.enemies.boss_defeated.connect(_on_boss_defeated)
		var jc: Dictionary = config.get("jars", {})
		if not jc.is_empty():
			_next_jar = float(jc.get("first", 100.0))
	var i := _rising.size() - 1
	while i >= 0:
		if now >= float(_rising[i][1]):
			_stand_jar(_rising[i][0], String(_rising[i][2]), bool(_rising[i][3]))
			_rising.remove_at(i)
		i -= 1
	if now >= _next_jar:
		var jc2: Dictionary = config["jars"]
		_next_jar = now + float(jc2.get("every", 85.0))
		if now < float(jc2.get("until", WaveData.RUN_DURATION)):
			_announce_jar(jc2)
	_sink_far_jars(_delta)
	var ps: Dictionary = config.get("pass_storm", {})
	if not _pass_done and not ps.is_empty() and now >= float(ps.get("at", INF)) and game.dynasty != null:
		_pass_done = true
		game.dynasty.sandstorm.force(float(ps.get("duration", 40.0)))
		game.stat_add("necropolis_pass_storm", 1.0)
		if ps.has("banner"):
			game.enemies.show_banner(String(ps["banner"]))
		_log("pass_storm")
	if _col != null and not (_col.active and _col.generation == _col_gen):
		_col = null
		game.stat_add("necropolis_colossus_killed", 1.0)
		colossus_time = _clock()
		_log("colossus_killed")


# =====================================================================================
# The Canopic Jars: the one jar placer
# =====================================================================================

## THE ONE JAR PLACER (the stage clock, Anubis's Procession): a jar stands
## beside the tomb nearest `at` on the Necropolis (tag `tag` for the stats),
## plainly at `at` elsewhere (a --boss=anubis run on another stage). Returns
## the jar, or null when it could not spawn.
static func place_jar_near(g: Game, at: Vector2, tag: String) -> Enemy:
	var nd := g.enemies.necropolis  # The Necropolis's director (null elsewhere).
	if nd != null:
		var spot := nd.tomb_spot(at)
		return nd._stand_jar(spot, tag, nd._spot_tomb)
	var r := float(DynastyEnemyData.ENEMIES[DynastyEnemyData.CANOPIC_JAR]["radius"])
	return g.dynasty_rules().rebirth.place_jar(g.arena.free_point(at, r))


## Where a jar for point `at` stands: at the foot of the nearest tomb obstacle
## (jars.tomb_kinds) within jars.tomb_reach px of `at` (the arena's cells
## round it), else `at` itself; always a free point.
func tomb_spot(at: Vector2) -> Vector2:
	var jc: Dictionary = config.get("jars", {})
	var kinds: Array = jc.get("tomb_kinds", [])
	var reach := float(jc.get("tomb_reach", 260.0))
	var r := float(DynastyEnemyData.ENEMIES[DynastyEnemyData.CANOPIC_JAR]["radius"])
	var best: Arena.Obstacle = null
	var best_d := reach
	_spot_tomb = false
	var cell := ArenaData.CELL
	var c0 := Vector2i(floori(at.x / cell), floori(at.y / cell))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var o := game.arena.obstacle_at((Vector2(c0 + Vector2i(dx, dy)) + Vector2(0.5, 0.5)) * cell)
			if o == null or not kinds.has(o.kind):
				continue
			var dd := o.center.distance_to(at)
			if dd < best_d:
				best_d = dd
				best = o
	if best == null:
		return game.arena.free_point(at, r)
	_spot_tomb = true
	var foot := (best.radius if best.is_circle else best.half.y) + r + float(jc.get("tomb_gap", 6.0))
	return game.arena.free_point(best.center + Vector2(0.0, foot), r)


## A stage jar starts rising (see the header), unless max_alive stand or rise.
func _announce_jar(jc: Dictionary) -> void:
	var standing: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			standing.append(pl)
	if standing.is_empty():
		return
	if live_jars() + _rising.size() >= int(jc.get("max_alive", 3)):
		game.stat_add("necropolis_jars_refused", 1.0)
		return
	var pl: Necromancer = standing[randi() % standing.size()]
	var a := randf() * TAU
	var dist := randf_range(float(jc.get("min", 240.0)), float(jc.get("max", 420.0)))
	var at := tomb_spot(pl.position + Vector2.from_angle(a) * dist)
	var warn := float(jc.get("warn", 1.2))
	var r := float(DynastyEnemyData.ENEMIES[DynastyEnemyData.CANOPIC_JAR]["radius"])
	_rising.append([at, game.elapsed + warn, "tomb", _spot_tomb])
	game.effects.telegraph_circle(at, r * 2.0, warn)


## Stands a jar at `at` now (Rebirth.place_jar(), the jar's one path) and
## counts it (`by_tomb`: set at a tomb's foot). Returns it (null if it could
## not spawn).
func _stand_jar(at: Vector2, tag: String, by_tomb: bool) -> Enemy:
	var j := game.dynasty_rules().rebirth.place_jar(at)
	if j == null:
		return null
	placed += 1
	game.stat_add("necropolis_jars", 1.0)
	game.stat_add("necropolis_jars_" + tag, 1.0)
	if by_tomb:
		beside_tomb += 1
		game.stat_add("necropolis_jars_beside_tomb", 1.0)
	return j


## A jar left farther than jars.abandon_reach px from every standing
## necromancer for jars.abandon_after s SINKS back into the sand
## (EnemyDirector.despawn(): not broken, so its sealed Names crumble with it
## through Rebirth.on_jar_gone(), and No Jars Left is lost).
func _sink_far_jars(delta: float) -> void:
	if game.dynasty == null:
		return
	var jc: Dictionary = config.get("jars", {})
	var reach := float(jc.get("abandon_reach", INF))
	var after := float(jc.get("abandon_after", INF))
	for j in game.dynasty.rebirth.jars.duplicate():
		if not j.active:
			continue
		var near := INF
		for pl in game.all_players:
			if not pl.dead:
				near = minf(near, pl.position.distance_to(j.position))
		var rec: Array = _far.get(j, [j.generation, 0.0])
		if int(rec[0]) != j.generation:
			rec = [j.generation, 0.0]
		rec[1] = float(rec[1]) + delta if near > reach else 0.0
		_far[j] = rec
		if float(rec[1]) >= after:
			_far.erase(j)
			sunk += 1
			game.stat_add("necropolis_jars_sunk", 1.0)
			game.effects.pop(j.position, Palette.DYN_SAND, j.radius * 2.0)
			game.enemies.despawn(j)
			_log("jar_sunk")


## Jars standing now (any jar on the field: the stage's and the Procession's).
func live_jars() -> int:
	var n := 0
	if game.dynasty == null:
		return 0
	for j in game.dynasty.rebirth.jars:
		if j.active:
			n += 1
	return n


## The nearest standing jar within `r` px of `p` (the army bot walks to it
## when calm; Vector2.INF = none).
func seek_point(p: Vector2, r: float) -> Vector2:
	if game.dynasty == null:
		return Vector2.INF
	var best := Vector2.INF
	var best_d := r
	for j in game.dynasty.rebirth.jars:
		if not j.active:
			continue
		var dd := j.position.distance_to(p)
		if dd < best_d:
			best_d = dd
			best = j.position
	return best


## The stage boss fell (EnemyDirector.boss_defeated): No Jars Left when he is
## Anubis, on the Necropolis, and every jar that rose here was broken.
func _on_boss_defeated() -> void:
	if boss_down:
		return
	boss_down = true
	_log("boss_down")
	if String(game.enemies.boss_info.get("id", "")) != String(NecropolisStage.BOSS["id"]):
		return
	if String(game.stage_def.get("id", "")) != NecropolisStage.ID or placed <= 0 or live_jars() > 0 or not _rising.is_empty() or sunk > 0:
		_log("jars_left_%d_sunk_%d" % [live_jars() + _rising.size(), sunk])
		return
	no_jars_left = true
	game.stats["necropolis_no_jars_left"] = 1.0
	game.enemies.show_banner(String(config.get("no_jars_banner", "NO JARS LEFT")))
	_log("no_jars_left")


# =====================================================================================
# The Sand Colossus
# =====================================================================================

## Runs a Necropolis timeline event (EnemyDirector forwards the "colossus"
## type; keys in NecropolisStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"colossus":
			var a := randf() * TAU
			var e := game.enemies.spawn_at(String(ev.get("kind", NecropolisEnemyData.COLOSSUS)), game.enemies.ring_point(a), bool(ev.get("elite", false)))
			if e != null:
				_col = e
				_col_gen = e.generation
				game.stat_add("necropolis_colossus_spawned", 1.0)
				game.shake(6.0)
				Sfx.play("boss_impact", e.position, 0.5)
				var side := Vector2.from_angle(a).orthogonal()
				var escort: Array = ev.get("escort", [])
				var k := 0
				for grp: Dictionary in escort:
					for j in int(grp.get("count", 0)):
						var at := e.position + side * (float(k % 6) - 2.5) * 26.0 - Vector2.from_angle(a) * (34.0 + 18.0 * float(k / 6))
						game.enemies.spawn_at(String(grp["kind"]), at, false)
						k += 1
				if ev.has("banner"):
					game.enemies.show_banner(String(ev["banner"]))
				_log("colossus")


## The HUD objective while the Sand Colossus stands, or while a jar stands
## within jars.objective_reach px of a necromancer ("" otherwise).
func objective_override() -> String:
	if _col != null and _col.active and _col.generation == _col_gen:
		return String(config.get("colossus_objective", ""))
	var jc: Dictionary = config.get("jars", {})
	if not boss_down and game.dynasty != null and seek_point(game.player.position, float(jc.get("objective_reach", 600.0))) != Vector2.INF:
		return String(config.get("jar_objective", ""))
	return ""


# =====================================================================================
# Report
# =====================================================================================

## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	var rb := game.dynasty.rebirth if game.dynasty != null else null
	return "jars placed %d (stage %d, procession %d; beside a tomb %d), broken %d, sunk %d, standing %d, refused %d | names crumbled with a jar %d | no jars left %s | pass storm %d | colossus spawned %d, killed %d%s | events: %s" % [
		placed, int(st.get("necropolis_jars_tomb", 0.0)), int(st.get("necropolis_jars_procession", 0.0)), beside_tomb,
		rb.jars_broken if rb != null else 0, sunk, live_jars(), int(st.get("necropolis_jars_refused", 0.0)),
		rb.crumbled if rb != null else 0,
		"EARNED" if no_jars_left else ("lost" if boss_down else "open"),
		int(st.get("necropolis_pass_storm", 0.0)),
		int(st.get("necropolis_colossus_spawned", 0.0)), int(st.get("necropolis_colossus_killed", 0.0)),
		(" at " + colossus_time) if colossus_time != "" else "", ", ".join(fired)]


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	fired.append("%s %s" % [_clock(), what])


## The current game clock as "m:ss".
func _clock() -> String:
	var t := int(game.elapsed)
	return "%d:%02d" % [t / 60, t % 60]
