## HarbourDirector — Gullhaven Harbour's stage events (Act II, GDD §15.0
## "Gullhaven Harbour (Act II phase 2)"; owner-approved proposal "Stage
## events"), owned and stepped by EnemyDirector on a stage whose StageRegistry
## "harbour" config is not empty (HarbourStage.HARBOUR; null elsewhere). Data:
## HarbourStage (HARBOUR, the "buoys" / "caches" / "harbourmaster" timeline
## events) and HarbourEnemyData (the structures and the miniboss).
##   * Bell buoys (optional): three buoys out on the flats (in the water when a
##     flooded spot is found). A standing buoy tolls every toll_interval s
##     while the necromancer is within toll_radius, calling a small squad up
##     from the sea beside it. Each one sunk makes every LATER scripted wave
##     smaller (wave_mult(), applied once in EnemyDirector._run_event()) and the
##     trickle thinner (trickle_mult()), pays an XP burst and Soul Ash. Like the
##     Sanctum's altars, skipping them costs only the bonus.
##   * Smugglers' caches: locked crates at the end of a dry pier (the pier is
##     registered with the TideDirector, so it stays dry: a narrow lane out
##     into the water). Broken, a cache drops a treasure chest and an XP burst.
##   * The Harbourmaster: the stage miniboss (HarbourmasterKit registers it on
##     the HUD's miniboss bar and pays its XP burst; ChestManager's miniboss
##     rule drops its chest). Spawned and tracked here (objective, kill time).
## Structures are ordinary pooled Enemy nodes (is_structure, is_objective:
## never recycled), polled with generation checks; every placed structure asks
## Arena.keep_clear() so a later zone never rebuilds an obstacle on it.
## Deterministic: only the seeded global RNG. The piers are drawn here (world
## space, over the water and under the obstacles and bodies).
class_name HarbourDirector
extends Node2D

## One tracked structure (a bell buoy or a smugglers' cache).
class Structure:
	extends RefCounted
	## "buoy" or "cache".
	var role: String = ""
	## The structure's Enemy node.
	var enemy: Enemy = null
	## Generation of `enemy` when it was placed (stale / death guard).
	var gen: int = 0
	## The timeline event that placed it (rewards, guards).
	var ev: Dictionary = {}
	## Last known world position (rewards spawn here once it falls).
	var pos: Vector2 = Vector2.ZERO
	## Game time of its next toll (buoys).
	var next_toll: float = 0.0

## Owning run.
var game: Game
## The stage's harbour config (HarbourStage.HARBOUR).
var config: Dictionary = {}
## Live buoys and caches.
var structures: Array[Structure] = []
## Bell buoys sunk so far.
var buoys_sunk: int = 0
## Bell buoys raised so far.
var buoys_raised: int = 0
## Smugglers' caches broken so far.
var caches_broken: int = 0
## Smugglers' caches placed so far.
var caches_placed: int = 0
## Game time each buoy sank, "m:ss" (summary).
var buoy_times: PackedStringArray = PackedStringArray()
## Game time each cache broke, "m:ss" (summary).
var cache_times: PackedStringArray = PackedStringArray()
## Game time the Harbourmaster fell ("" while alive / never spawned).
var harbourmaster_time: String = ""
## Log of Harbour events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Piers drawn here: [centre, unit direction, half length, half width].
var piers: Array = []
## The Harbourmaster once spawned (null before / after; generation-checked).
var _harbourmaster: Enemy = null
## Generation of `_harbourmaster` when it spawned.
var _harbourmaster_gen: int = 0


func _ready() -> void:
	z_index = -7  # Over the water (-8), under the obstacles (-6) and bodies.


## Per-tick update, called by EnemyDirector after the MarchDirector.
func step(_delta: float) -> void:
	_step_structures()
	_step_harbourmaster()


# =====================================================================================
# Timeline events
# =====================================================================================

## Runs a Harbour timeline event (EnemyDirector forwards the "buoys", "caches"
## and "harbourmaster" types; keys in HarbourStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"buoys":
			_place(ev, "buoy")
		"caches":
			_place(ev, "cache")
		"harbourmaster":
			_spawn_harbourmaster(ev)
	game.enemies.show_banner(String(ev["banner"]))


## Places `ev.count` structures of `ev.kind` around the necromancer, spread
## evenly, spaced, out of obstacles and, when one is found, in the water.
## Caches get their dry pier and guards.
func _place(ev: Dictionary, role: String) -> void:
	var n := int(ev["count"])
	var offset := randf() * TAU  # Angle of the first structure.
	var kind := String(ev["kind"])
	var r := float(game.enemies.enemy_def(kind)["radius"])  # Body radius.
	var p := game.player.position
	var tide := game.enemies.tide  # Null off the Harbour (then nothing is flooded).
	var placed: Array[Vector2] = []
	for i in n:
		var best := p  # Chosen spot.
		var have := false  # A spaced spot was found.
		for _try in int(config["placement_tries"]):
			var a := offset + TAU * float(i) / float(maxi(1, n)) + randf_range(-0.4, 0.4)
			var pos := game.arena.free_point(p + Vector2.from_angle(a) * randf_range(float(ev["distance_min"]), float(ev["distance_max"])), r)
			var spaced := true
			for q in placed:
				spaced = spaced and q.distance_to(pos) >= float(config["structure_spacing"])
			if not spaced:
				continue
			if not have:
				best = pos
				have = true
			if tide != null and tide.flooded(pos):
				best = pos
				break  # Out in the water: the detour the owner asked for.
		placed.append(best)
		var e := game.enemies.spawn_at(kind, best, false)
		e.is_objective = true
		game.arena.keep_clear(e.position, e.radius + ArenaData.MAX_HALF_EXTENT * 1.5)
		var s := Structure.new()
		s.role = role
		s.enemy = e
		s.gen = e.generation
		s.ev = ev
		s.pos = e.position
		s.next_toll = game.elapsed + float(config["toll_interval"]) * 0.5
		structures.append(s)
		game.effects.spawn_ring(e.position, Palette.EYE_BIOLUME if role == "buoy" else Palette.BONE)
		if role == "cache":
			caches_placed += 1
			_add_pier(e.position, p)
			for grp: Dictionary in ev.get("guards", []):
				for _k in int(grp["count"]):
					if game.enemies.regular_alive() >= game.enemies.hard_cap():
						break
					game.enemies.spawn_at(String(grp["kind"]), e.position + Vector2.from_angle(randf() * TAU) * (e.radius + 28.0), bool(grp["elite"]))
		else:
			buoys_raised += 1
	game.stat_add("harbour_%ss_placed" % role, float(n))
	_log("%ss_placed_%d" % [role, n])


## A dry pier from the cache at `at` back toward `toward` (the necromancer).
func _add_pier(at: Vector2, toward: Vector2) -> void:
	var d := toward - at
	var dir := d.normalized() if d.length() > 1.0 else Vector2.UP  # Along the pier, toward land.
	var half_len := float(config["pier_length"]) * 0.5
	var half_w := float(config["pier_width"]) * 0.5
	var center := at + dir * (half_len - 6.0)  # The cache stands on its far end.
	piers.append([center, dir, half_len, half_w])
	game.arena.keep_clear(center, half_len + ArenaData.MAX_HALF_EXTENT)
	if game.enemies.tide != null:
		game.enemies.tide.add_pier(center, dir, half_len, half_w)
	queue_redraw()


## Spawns the Harbourmaster on the spawn ring and tracks it. Its kit
## registers it on the HUD's miniboss bar (Enemy.is_miniboss: never recycled).
func _spawn_harbourmaster(ev: Dictionary) -> void:
	var e := game.enemies.spawn_at(String(ev["kind"]), game.enemies.ring_point(randf() * TAU), bool(ev["elite"]))
	_harbourmaster = e
	_harbourmaster_gen = e.generation
	game.stat_add("harbour_harbourmasters_spawned", 1.0)
	_log("harbourmaster_arrived")


# =====================================================================================
# Buoys, caches, the Harbourmaster
# =====================================================================================

## Buoys toll; fallen structures pay their rewards.
func _step_structures() -> void:
	var i := 0
	while i < structures.size():
		var s := structures[i]
		var e := s.enemy
		if not e.active or e.generation != s.gen:
			_on_destroyed(s)
			structures.remove_at(i)
			continue
		s.pos = e.position
		if s.role == "buoy" and game.elapsed >= s.next_toll:
			s.next_toll += float(config["toll_interval"])
			_toll(s)
		i += 1


## A buoy tolls: a squad rises from the sea beside it (only while the
## necromancer is within toll_radius and the trickle's soft cap has room).
func _toll(s: Structure) -> void:
	if s.pos.distance_to(game.player.position) > float(config["toll_radius"]):
		return
	var cap := mini(game.enemies.soft_cap(), game.enemies.hard_cap() - 10)  # Room for the squad.
	var spawned := 0  # Cultists called this time.
	for grp: Dictionary in config["toll_groups"]:
		for _k in int(grp["count"]):
			if game.enemies.regular_alive() >= cap:
				break
			var at := s.pos + Vector2.from_angle(randf() * TAU) * (s.enemy.radius + 22.0)
			game.enemies.spawn_at(String(grp["kind"]), at, bool(grp["elite"]))
			spawned += 1
	game.effects.ring(s.pos, 60.0, Palette.EYE_BIOLUME, 0.6)
	Sfx.play("toll", s.pos, 1.15)
	game.stat_add("harbour_buoy_tolls", 1.0)
	if spawned > 0:
		game.stat_add("harbour_toll_spawns", float(spawned))


## A structure fell: rewards, banner, stats.
func _on_destroyed(s: Structure) -> void:
	_xp_burst(s.pos, s.ev)
	match s.role:
		"buoy":
			buoys_sunk += 1
			buoy_times.append(_clock())
			game.stat_add("objective_ash", float(config["ash_per_buoy"]))
			game.stat_add("harbour_buoys_sunk", 1.0)
			game.effects.impact(s.pos, 60.0, Palette.EYE_BIOLUME, "tide_splash")
			game.enemies.show_banner("A bell buoy sinks: the Eye's waves shrink (-%d%%)!" % roundi((1.0 - wave_mult()) * 100.0))
			_log("buoy_sunk")
		"cache":
			caches_broken += 1
			cache_times.append(_clock())
			game.stat_add("objective_ash", float(config["ash_per_cache"]))
			game.stat_add("harbour_caches_broken", 1.0)
			game.effects.impact(s.pos, 50.0, Palette.GOLD)
			if not game.countdown_finished() and game.chests.spawn_chest(s.pos, true):
				game.stat_add("harbour_cache_chests", 1.0)
			game.enemies.show_banner("A smugglers' cache bursts open: treasure!")
			_log("cache_broken")


## Notes when the Harbourmaster fell (its XP burst and banner are its kit's,
## its chest ChestManager's miniboss rule).
func _step_harbourmaster() -> void:
	if _harbourmaster == null or (_harbourmaster.active and _harbourmaster.generation == _harbourmaster_gen):
		return
	_harbourmaster = null
	game.stat_add("harbour_harbourmasters_killed", 1.0)
	harbourmaster_time = _clock()
	_log("harbourmaster_killed")


## XP burst of a fallen objective (`ev` reward_xp in reward_crystals crystals).
func _xp_burst(pos: Vector2, ev: Dictionary) -> void:
	var xp := int(ev.get("reward_xp", 0))
	var n := maxi(1, int(ev.get("reward_crystals", 1)))
	if xp <= 0:
		return
	var each := maxi(1, floori(float(xp) / float(n)))
	for k in n:
		game.pickups.spawn(pos + Vector2.from_angle(TAU * float(k) / float(n)) * randf_range(16.0, 46.0), each)


## Records a Harbour event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]


# =====================================================================================
# Queries (enemy director, HUD, autopilot)
# =====================================================================================

## Multiplier on the size of every scripted wave from now on: -wave_cut_per_buoy
## per sunk buoy (additive).
func wave_mult() -> float:
	return maxf(0.2, 1.0 - float(config["wave_cut_per_buoy"]) * float(buoys_sunk))


## Multiplier on the trickle rate from now on: -trickle_cut_per_buoy per sunk buoy.
func trickle_mult() -> float:
	return maxf(0.2, 1.0 - float(config["trickle_cut_per_buoy"]) * float(buoys_sunk))


## Live structures with role `role`.
func count_role(role: String) -> int:
	var n := 0
	for s in structures:
		if s.role == role and s.enemy.active and s.enemy.generation == s.gen:
			n += 1
	return n


## HUD objective for the live Harbour objective ("" if none): the
## Harbourmaster first, then the caches, then the optional buoys.
func objective_override() -> String:
	if _harbourmaster != null:
		return "Slay the Harbourmaster: he guards a treasure"
	var caches := count_role("cache")
	if caches > 0:
		return "Break the smugglers' caches on the piers for treasure (%d left)" % caches
	var buoys := count_role("buoy")
	if buoys > 0:
		return "Optional: sink the bell buoys to thin the Eye's waves (%d left)" % buoys
	return ""


## Autopilot hint: the nearest live buoy or cache within `reach` px of `p`
## (Vector2.INF when none).
func seek_point(p: Vector2, reach: float) -> Vector2:
	var best := Vector2.INF
	var best_d := reach
	for s in structures:
		var d := p.distance_to(s.pos)
		if d < best_d:
			best_d = d
			best = s.pos
	return best


## One-line autotest summary: buoys, caches, the Harbourmaster.
func summary_line() -> String:
	var st := game.stats
	return "buoys sunk %d/%d (%s) | tolls %d (cultists called %d) | wave size now x%.2f, trickle x%.2f | caches broken %d/%d (%s), cache chests %d | harbourmaster %s | objective ash %d" % [
		buoys_sunk, buoys_raised, ", ".join(buoy_times) if not buoy_times.is_empty() else "-",
		int(st.get("harbour_buoy_tolls", 0.0)), int(st.get("harbour_toll_spawns", 0.0)), wave_mult(), trickle_mult(),
		caches_broken, caches_placed, ", ".join(cache_times) if not cache_times.is_empty() else "-", int(st.get("harbour_cache_chests", 0.0)),
		("killed at " + harbourmaster_time) if harbourmaster_time != "" else ("alive" if _harbourmaster != null else "not spawned"),
		int(st.get("objective_ash", 0.0))]


# =====================================================================================
# Drawing (the piers; world space)
# =====================================================================================

func _draw() -> void:
	for pier: Array in piers:
		HarbourGlyphs.draw_pier(self, pier[0], pier[1], float(pier[2]), float(pier[3]))
