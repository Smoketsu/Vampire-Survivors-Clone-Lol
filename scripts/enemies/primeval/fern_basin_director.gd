## FernBasinDirector — the stage systems of THE FERN BASIN (temporary Act XIV
## stage 40, final stage 40; GDD §15.0 "The Fern Basin (Act XIV phase 2)";
## owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 2, "Stage
## A: The Fern Basin"), owned and stepped by EnemyDirector on a stage whose
## STAGE has a "fern_basin" config (FernBasinStage.FERN; `game.enemies.fern_basin`,
## null elsewhere). The zones' floors and obstacles are MarchDirector's; Packs,
## Herds, Scavengers and the Stampede of Ash the shared PrimevalRules'. Here:
##   * THE TAR SEEPS (the stage mechanic: "pools of tar slow everyone through
##     the existing TerrainSlow ground path. Herbivores get stuck in tar: a
##     trapped Longneck is a free kill and a free heavy corpse"): the world is
##     cut into tar cells (tar_cell px); each holds at most one pool, chosen by
##     a pure hash of the cell and the zone's salt (pool_in(), shared with
##     FernBasinGround so the drawn tar is the slowing tar; the zone's "ground"
##     "tar" dictionary is the one source). Every tar_every s whoever stands in
##     a pool is slowed for tar_linger s more: the necromancer and the summons
##     through TerrainSlow (Brinewalker helps), the enemies through
##     Enemy.apply_slow() (not the fliers, the swimmers, the structures, the
##     boss or a miniboss). A HERD BEAST in a pool is TRAPPED
##     (HerdBeastKit.stuck_until, read by Herds: it neither grazes away, runs
##     nor frightens its herd): a free kill and a free heavy corpse.
##   * THE BOG CROCS ("Bog Crocs ambush from the seeps"): from croc_first s,
##     every croc_every s, croc_count Bog Crocs come up in pools croc_min..
##     croc_max px from a standing necromancer (the nearest such pool cells to
##     a seeded point; at most croc_cap alive); their kit lies submerged and
##     lunges (BogCrocKit).
##   * IRONJAW, THE NEST MOTHER ("nest_mother" event): the stage miniboss
##     comes in nest_dist px ahead of the necromancer beside her nest (a
##     structure that hatches Scuttlers until it is destroyed; never recycled),
##     linked to her (IronjawKit.link_nest()); tracked for the objective and the
##     report.
## Deterministic: pure hashes and the seeded global RNG only. Stats:
## tar_checks, tar_slows_you, tar_slows_summons, tar_slows_enemies,
## tar_trapped (beasts caught), crocs_spawned, nest_mother_spawned,
## nest_mother_killed, nest_killed.
class_name FernBasinDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (FernBasinStage.FERN).
var config: Dictionary = {}
## Log of the stage's events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Bog Crocs brought up this run.
var crocs: int = 0
## "m:ss" Ironjaw fell ("" while alive / never spawned).
var ironjaw_time: String = ""
## "m:ss" her nest fell ("" while standing / never laid).
var nest_time: String = ""
## Game time (s) of the next tar check.
var _next_tar: float = 0.0
## Game time (s) of the next Bog Crocs (INF = none yet scheduled).
var _next_croc: float = INF
## Index of the zone whose tar the cache holds (-1 = none).
var _zone: int = -1
## The current zone's tar dictionary (a FernBasinStage.ZONES "ground" "tar").
var _tar: Dictionary = {}
## Tar cell -> its pool (Vector3: x, y, radius px; radius 0 = no pool), for the current zone.
var _cells: Dictionary = {}
## Ironjaw once spawned (null before / after; generation-checked).
var _ironjaw: Enemy = null
## Generation of `_ironjaw` when she spawned.
var _ironjaw_gen: int = 0
## Her nest once laid (null before / after; generation-checked).
var _nest: Enemy = null
## Generation of `_nest` when laid.
var _nest_gen: int = 0


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	var now := game.elapsed
	_sync_zone()
	if now >= _next_tar:
		_next_tar = now + float(config["tar_every"])
		_tar_check()
	if _next_croc == INF:
		_next_croc = float(config["croc_first"])
	if now >= _next_croc:
		_next_croc = now + float(config["croc_every"])
		_bring_crocs()
	if _ironjaw != null and not (_ironjaw.active and _ironjaw.generation == _ironjaw_gen):
		_ironjaw = null
		game.stat_add("nest_mother_killed", 1.0)
		ironjaw_time = _clock()
		_log("ironjaw_down")
	if _nest != null and not (_nest.active and _nest.generation == _nest_gen):
		_nest = null
		game.stat_add("nest_killed", 1.0)
		nest_time = _clock()
		_log("nest_down")


# =====================================================================================
# The Tar Seeps
# =====================================================================================

## The pool of tar cell `cell` under tar dictionary `tar` (Vector3: centre x,
## centre y, radius px; radius 0 = none): a pure hash of the cell and the
## zone's salt, kept tar_margin px inside the cell and out of tar_clear px of
## the arena's centre. Shared with FernBasinGround (the drawn tar is the
## slowing tar).
static func pool_in(cell: Vector2i, tar: Dictionary, fern: Dictionary) -> Vector3:
	var h := absi(hash(Vector3i(cell.x, cell.y, int(tar.get("salt", 4040)))))
	if float(h % 1000) / 1000.0 >= float(tar.get("chance", 0.0)):
		return Vector3.ZERO
	var size := float(fern["tar_cell"])
	var r := lerpf(float(tar["min"]), float(tar["max"]), float((h >> 10) % 100) / 100.0)
	var room := maxf(0.0, size - 2.0 * (r + float(fern["tar_margin"])))  # px the centre may roam inside the cell.
	var c := Vector2(float(cell.x) * size, float(cell.y) * size) + Vector2.ONE * (size * 0.5 - room * 0.5) \
			+ Vector2(float((h >> 17) % 101) / 100.0, float((h >> 24) % 101) / 100.0) * room
	if c.length() < float(fern["tar_clear"]) + r:
		return Vector3.ZERO
	return Vector3(c.x, c.y, r)


## True when world point `p` lies in a pool of the current zone (`r`: the
## body's radius, half of it counts).
func in_tar(p: Vector2, r: float = 0.0) -> bool:
	if _tar.is_empty():
		return false
	var size := float(config["tar_cell"])
	var cell := Vector2i(floori(p.x / size), floori(p.y / size))
	var pool := _pool(cell)
	if pool.z > 0.0:
		return Vector2(pool.x, pool.y).distance_squared_to(p) <= (pool.z + r * 0.5) * (pool.z + r * 0.5)
	return false


## The (cached) pool of `cell` in the current zone.
func _pool(cell: Vector2i) -> Vector3:
	if not _cells.has(cell):
		_cells[cell] = pool_in(cell, _tar, config)
	return _cells[cell]


## Follows MarchDirector's zone: its tar dictionary, a fresh cell cache.
func _sync_zone() -> void:
	var zi := game.enemies.march.zone_index if game.enemies.march != null else 0
	if zi == _zone:
		return
	_zone = zi
	var zones: Array = game.stage_def.get("zones", [])
	_tar = ((zones[zi] as Dictionary).get("ground", {}) as Dictionary).get("tar", {}) if zi < zones.size() else {}
	_cells.clear()


## One check of who stands in tar (see the header).
func _tar_check() -> void:
	var linger := float(config["tar_linger"]) + float(config["tar_every"])  # A slow lasts to the next check and a little more.
	game.stat_add("tar_checks", 1.0)
	for pl in game.all_players:
		if pl.dead or not in_tar(pl.position, pl.radius):
			continue
		var prev := -1
		if game.coop != null:
			prev = game.coop.bound
			game.coop.bind(game.coop.slot_of(pl))  # TerrainSlow reads the bound slot.
		if TerrainSlow.slow_player(game, float(config["tar_slow_player"]), linger) > 0.0:
			game.stat_add("tar_slows_you", 1.0)
		if prev >= 0:
			game.coop.bind(prev)
	for hd in game.all_hordes:
		for u in hd.units:
			if not u.active or u.airborne or u.flies or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING:
				continue
			if in_tar(u.position, u.radius):
				TerrainSlow.slow_summon(game, u, float(config["tar_slow_summon"]), linger)
				game.stat_add("tar_slows_summons", 1.0)
	var now := game.elapsed
	for e in game.enemies.active:
		if not e.active or e.is_structure or e.is_boss or e.is_miniboss or e.flies or e.floating or e.untargetable:
			continue
		if e.kit is PrimevalKit and bool((e.kit as PrimevalKit).d.get("swims", false)):
			continue
		if not in_tar(e.position, e.radius):
			continue
		e.apply_slow(float(config["tar_slow_enemy"]), linger)
		game.stat_add("tar_slows_enemies", 1.0)
		if e.kit is HerdBeastKit:
			var hk := e.kit as HerdBeastKit
			if hk.stuck_until < now:
				game.stat_add("tar_trapped", 1.0)
			hk.stuck_until = now + linger


# =====================================================================================
# The Bog Crocs
# =====================================================================================

## Brings croc_count Bog Crocs up in pools round a standing necromancer.
func _bring_crocs() -> void:
	if _tar.is_empty():
		return
	var standing: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			standing.append(pl)
	if standing.is_empty():
		return
	var kind := String(config["croc_kind"])
	var alive := 0
	for e in game.enemies.active:
		if e.active and e.kind == kind:
			alive += 1
	var pl: Necromancer = standing[randi() % standing.size()]
	for i in int(config["croc_count"]):
		if alive >= int(config["croc_cap"]):
			return
		var want := pl.position + Vector2.from_angle(randf() * TAU) * randf_range(float(config["croc_min"]), float(config["croc_max"]))
		var at := _pool_near(want, pl.position)
		if at == Vector2.INF:
			continue
		if game.enemies.spawn_at(kind, at, false) != null:
			alive += 1
			crocs += 1
			game.stat_add("crocs_spawned", 1.0)


## The centre of the pool nearest `want` (its own cell and the eight round
## it) that lies croc_min..croc_max px from `from`; Vector2.INF when none does.
func _pool_near(want: Vector2, from: Vector2) -> Vector2:
	var size := float(config["tar_cell"])
	var c0 := Vector2i(floori(want.x / size), floori(want.y / size))
	var best := Vector2.INF
	var best_d := INF
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var pool := _pool(c0 + Vector2i(dx, dy))
			if pool.z <= 0.0:
				continue
			var pc := Vector2(pool.x, pool.y)
			var df := pc.distance_to(from)
			if df < float(config["croc_min"]) or df > float(config["croc_max"]):
				continue
			if pc.distance_to(want) < best_d:
				best_d = pc.distance_to(want)
				best = pc
	return best


# =====================================================================================
# Ironjaw, the Nest Mother
# =====================================================================================

## Runs a Fern Basin timeline event (EnemyDirector forwards the "nest_mother"
## type; keys in FernBasinStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	if String(ev["type"]) != "nest_mother":
		return
	var pl := game.player
	var ahead := pl.velocity.normalized() if pl.velocity.length() > 5.0 else Vector2.from_angle(randf() * TAU)
	var at := game.arena.free_point(pl.position + ahead * float(ev.get("nest_dist", 230.0)), 20.0)
	var n := game.enemies.spawn_at(String(ev.get("nest", FernBasinEnemyData.NEST)), at, false)
	if n != null:
		n.is_objective = true  # Never recycled: it stays where it was laid.
		_nest = n
		_nest_gen = n.generation
	var side := ahead.orthogonal()
	var e := game.enemies.spawn_at(String(ev.get("kind", FernBasinEnemyData.IRONJAW)), game.arena.free_point(at + side * 46.0, 22.0), bool(ev.get("elite", false)))
	if e != null:
		_ironjaw = e
		_ironjaw_gen = e.generation
		if n != null and e.kit is IronjawKit:
			(e.kit as IronjawKit).link_nest(n)
		game.stat_add("nest_mother_spawned", 1.0)
	game.shake(6.0)
	Sfx.play("boss_impact", at, 0.5)
	var k := 0
	for grp: Dictionary in ev.get("escort", []):
		for j in int(grp.get("count", 0)):
			game.enemies.spawn_at(String(grp["kind"]), game.arena.free_point(at + Vector2.from_angle(float(k) * 0.52) * 60.0, 8.0), false)
			k += 1
	if ev.has("banner"):
		game.enemies.show_banner(String(ev["banner"]))
	_log("nest_mother")


## The HUD objective while Ironjaw or her nest stands ("" otherwise).
func objective_override() -> String:
	if _ironjaw != null or _nest != null:
		return String(config.get("nest_objective", ""))
	return ""


## The autotest autopilot's goal: the nest when it stands within `r` px of
## `p` (Vector2.INF otherwise).
func seek_point(p: Vector2, r: float) -> Vector2:
	if _nest != null and _nest.active and _nest.generation == _nest_gen and _nest.position.distance_to(p) <= r:
		return _nest.position
	return Vector2.INF


# =====================================================================================
# Report
# =====================================================================================

## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	return "tar checks %d: slowed you %d, summons %d, enemies %d | beasts trapped %d (killed in the tar %d) | bog crocs %d (ambushes %d, came up tired %d, lunges %d: bit summons %d, you %d) | ironjaw spawned %d, killed %d%s (bites %d: summons %d, you %d; warded hits %d) | nest killed %d%s (hatched %d) | events: %s" % [
		int(st.get("tar_checks", 0.0)), int(st.get("tar_slows_you", 0.0)), int(st.get("tar_slows_summons", 0.0)),
		int(st.get("tar_slows_enemies", 0.0)), int(st.get("tar_trapped", 0.0)), int(st.get("herd_kills_trapped", 0.0)),
		crocs, int(st.get("croc_ambushes", 0.0)), int(st.get("croc_tired", 0.0)), int(st.get("croc_lunges", 0.0)),
		int(st.get("croc_lunge_hits", 0.0)), int(st.get("croc_lunge_on_you", 0.0)),
		int(st.get("nest_mother_spawned", 0.0)), int(st.get("nest_mother_killed", 0.0)),
		(" at " + ironjaw_time) if ironjaw_time != "" else "", int(st.get("ironjaw_bites", 0.0)),
		int(st.get("ironjaw_bite_hits", 0.0)), int(st.get("ironjaw_bite_on_you", 0.0)), int(st.get("ironjaw_warded_hits", 0.0)),
		int(st.get("nest_killed", 0.0)), (" at " + nest_time) if nest_time != "" else "", int(st.get("nest_hatched", 0.0)),
		", ".join(fired)]


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	fired.append("%s %s" % [_clock(), what])


## The current game clock as "m:ss".
func _clock() -> String:
	var t := int(game.elapsed)
	return "%d:%02d" % [t / 60, t % 60]
