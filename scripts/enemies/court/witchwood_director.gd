## WitchwoodDirector — the stage systems of the Witchwood (Stage 20; Act VII,
## GDD §15.0 "The Witchwood (Act VII phase 2)"; owner-approved proposal
## docs/act7/PROPOSAL.md "Stage 20: The Witchwood"), owned and stepped by
## EnemyDirector on a stage whose STAGE has a "witchwood" config
## (WitchwoodStage.WITCHWOOD; null elsewhere). The four zones are
## MarchDirector's (the clock is authoritative); this director reads the current
## zone (MarchDirector.zone_index). The shared rules (Bloodfeast, Night Wings,
## the Blood Moon) are the Court's; the witches' covens, circles, stones and
## pools are WitchHexes'. Here:
##   * THE FEN (a zone's "fen": true; the Fen): still pools of black water lie
##     across the ground on a fixed hash grid (fen_pool(), the one geometry the
##     floor draws too: WitchwoodGround). Every fen.check_every s whoever wades
##     one is slowed through FenWater.wade() (TerrainSlow, the one ground-slow
##     path: the necromancer and the summons; the living foes by their own
##     Enemy.apply_slow()). Owner-approved: "the Fen (water slows everyone)".
##   * THE HEX STONES (owner-approved: "standing stones that power the covens'
##     circles; destroy one and its zone's covens cannot cast"): at stones.first
##     s and at every later zone, the stones of the last zone sink (despawned:
##     no dead ground) and the dead ground clears; stones.count new hex stones
##     rise around the necromancer stones.distance px out (WitchwoodEnemyData
##     "hex_stone"; WitchHexes counts them).
##   * THE BOG MOTHER ("bog_mother" event): the stage miniboss, spawned on the
##     spawn ring and tracked (objective, kill time); her kit registers her on
##     the HUD's miniboss bar and pays her XP burst.
##   * THE COVENS ("coven" events): tight triangles of three Crimson Witches
##     with their escorts (they band at once in WitchHexes).
##   * THE COVEN BREAKS (the stage's achievement): BossIsolde sets the run stat
##     witchwood_coven_breaks when her three sisters fall within 1 s; this
##     director logs it for the summary (MetaProgress counts the runs).
##   * The HUD objective while the Bog Mother stands.
## Deterministic: the seeded global RNG only (where the stones and the Bog
## Mother appear); the fen is pure geometry. Stats: fen_checks,
## fen_wade_player / _summons / _enemies, hex_stones_raised, hex_stones_sunk,
## witchwood_bog_mother_spawned, witchwood_bog_mother_killed, witchwood_coven_witches.
class_name WitchwoodDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (WitchwoodStage.WITCHWOOD).
var config: Dictionary = {}
## Log of Witchwood events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## "m:ss" the Bog Mother fell ("" while alive / never spawned).
var bog_time: String = ""
## Zone index the systems below last saw (MarchDirector.zone_index).
var _zone: int = -1
## True while the current zone has the Fen.
var fen_on: bool = false
## Seconds until the next fen check.
var _fen_cd: float = 0.0
## True once the first stones rose.
var _stones_started: bool = false
## The stones this director raised (sunk at the next zone).
var _stones: Array[Enemy] = []
## Their generations.
var _stone_gen: PackedInt32Array = PackedInt32Array()
## Most hex stones standing at once this run.
var stones_peak: int = 0
## The Bog Mother once spawned (null before / after; generation-checked).
var _bog: Enemy = null
## Generation of `_bog` when she spawned.
var _bog_gen: int = 0
## True once The Coven Breaks was logged.
var _coven_logged: bool = false


func _ready() -> void:
	game.enemies.boss_defeated.connect(_on_boss_defeated)


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(delta: float) -> void:
	var z := game.enemies.march.zone_index if game.enemies.march != null else 0  # Current zone.
	if z != _zone:
		_enter_zone(z)
	if not _stones_started and game.elapsed >= float(config["stones"]["first"]):
		_stones_started = true
		_raise_stones()
	if fen_on:
		_fen_cd -= delta
		if _fen_cd <= 0.0:
			_fen_cd += float(config["fen"]["check_every"])
			_fen_check()
	if _bog != null and not (_bog.active and _bog.generation == _bog_gen):
		_bog = null
		game.stat_add("witchwood_bog_mother_killed", 1.0)
		bog_time = _clock()
		_log("bog_mother_killed")
	if not _coven_logged and float(game.stats.get("witchwood_coven_breaks", 0.0)) > 0.0:
		_coven_logged = true
		_log("coven_breaks")


## Runs a Witchwood timeline event (EnemyDirector forwards "bog_mother" and
## "coven").
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"bog_mother":
			var e := game.enemies.spawn_at(String(ev.get("kind", WitchwoodEnemyData.BOG_MOTHER)), game.enemies.ring_point(randf() * TAU), bool(ev.get("elite", false)))
			if e != null:
				_bog = e
				_bog_gen = e.generation
				game.stat_add("witchwood_bog_mother_spawned", 1.0)
				game.shake(4.0)
				game.court_rules().play_sound("bog_drag", e.position)
				_log("bog_mother_arrived")
		"coven":
			_send_covens(ev)
	game.enemies.show_banner(String(ev["banner"]))


## A "coven" event: `covens` tight triangles of three Crimson Witches on the
## spawn ring (they band at once: WitchHexes), each with its `escort` groups
## around it; the hard cap is respected (seeded RNG: where on the ring).
func _send_covens(ev: Dictionary) -> void:
	var spread := float(config["coven_spread"])
	var made := 0
	for c in int(ev.get("covens", 1)):
		var centre := game.enemies.ring_point(randf() * TAU)
		for i in 3:
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				break
			var at := game.arena.free_point(centre + Vector2.from_angle(TAU * float(i) / 3.0 - PI * 0.5) * spread, 10.0)
			if game.enemies.spawn_at(WitchHexData.WITCH, at, false) != null:
				made += 1
		for g: Dictionary in ev.get("escort", []):
			for k in int(g["count"]):
				if game.enemies.regular_alive() >= game.enemies.hard_cap():
					break
				var at := game.arena.free_point(centre + Vector2.from_angle(TAU * float(k) / maxf(1.0, float(g["count"]))) * (spread + 40.0), 10.0)
				game.enemies.spawn_at(String(g["kind"]), at, false)
	game.stat_add("witchwood_coven_witches", float(made))
	_log("coven")


## HUD objective for the live Witchwood objective ("" if none).
func objective_override() -> String:
	if _bog != null:
		return String(config["bog_mother_objective"])
	return ""


## Starts zone `z`'s systems (ZONES "fen"); from the first stones on, every
## new zone raises new hex stones.
func _enter_zone(z: int) -> void:
	var first := _zone < 0
	_zone = z
	var zones: Array = config["zones"]
	var zd: Dictionary = zones[clampi(z, 0, zones.size() - 1)]
	fen_on = bool(zd.get("fen", false))
	_fen_cd = 0.0
	if not first and _stones_started:
		_raise_stones()


# =====================================================================================
# The Fen
# =====================================================================================

## Centre (x, y) and radius (z) of the fen pool of grid cell (`cx`, `cy`) for
## fen settings `f` (z = 0: no pool there). Static, so the floor
## (WitchwoodGround) draws exactly the same water. The cell holding the world
## origin is always dry (the run starts there).
static func fen_pool(cx: int, cy: int, f: Dictionary) -> Vector3:
	if cx == 0 and cy == 0:
		return Vector3.ZERO
	var h := absi(hash(Vector3i(cx, cy, int(f["seed"]))))
	if float(h % 1000) / 1000.0 >= float(f["chance"]):
		return Vector3.ZERO
	var cell := float(f["cell"])
	var rmin := float(f["radius_min"])
	var rmax := float(f["radius_max"])
	var r := rmin + (rmax - rmin) * float((h >> 10) % 100) / 100.0
	var slack := maxf(0.0, cell * 0.5 - r)  # How far the pool may sit off the cell's centre.
	var ox := (float((h >> 17) % 200) / 100.0 - 1.0) * slack
	var oy := (float((h >> 24) % 200) / 100.0 - 1.0) * slack
	return Vector3((float(cx) + 0.5) * cell + ox, (float(cy) + 0.5) * cell + oy, r)


## True when a body of radius `r` at `p` stands in a fen pool (its centre in
## the water, less a third of its body: the edge is shallow).
static func in_fen(p: Vector2, r: float, f: Dictionary) -> bool:
	var cell := float(f["cell"])
	var cx := floori(p.x / cell)
	var cy := floori(p.y / cell)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var pool := fen_pool(cx + dx, cy + dy, f)
			if pool.z > 0.0 and p.distance_to(Vector2(pool.x, pool.y)) <= pool.z - r * 0.33:
				return true
	return false


## One check of who wades the fen (FenWater.wade(), the one slow helper).
func _fen_check() -> void:
	var f: Dictionary = config["fen"]
	game.stat_add("fen_checks", 1.0)
	FenWater.wade(game, func(p: Vector2, r: float) -> bool: return WitchwoodDirector.in_fen(p, r, f),
			float(f["slow_player"]), float(f["slow_summon"]), float(f["slow_enemy"]), float(f["linger"]) + float(f["check_every"]), "fen_wade")


# =====================================================================================
# The hex stones
# =====================================================================================

## The last zone's stones sink and their dead ground clears; new stones rise
## around the necromancer (seeded RNG: the ring's turn).
func _raise_stones() -> void:
	var s: Dictionary = config["stones"]
	for i in _stones.size():
		var old := _stones[i]
		if old.active and old.generation == _stone_gen[i]:
			game.enemies.despawn(old)
			game.stat_add("hex_stones_sunk", 1.0)
	_stones.clear()
	_stone_gen = PackedInt32Array()
	game.court_rules().witch_hexes().clear_dead_ground()
	var n := int(s["count"])
	var turn := randf() * TAU
	var pp := game.player.position
	for i in n:
		var at := game.arena.free_point(pp + Vector2.from_angle(turn + TAU * float(i) / float(n)) * float(s["distance"]), 16.0)
		var e := game.enemies.spawn_at(WitchwoodEnemyData.HEX_STONE, at, false)
		if e != null:
			_stones.append(e)
			_stone_gen.append(e.generation)
			game.stat_add("hex_stones_raised", 1.0)
			game.effects.spawn_ring(at, Palette.COURT_BLOOD_LIGHT)
	stones_peak = maxi(stones_peak, _stones.size())
	game.enemies.show_banner(String(s["banner"]))
	_log("hex_stones")


## Hex stones of this director standing now.
func stones_standing() -> int:
	var n := 0
	for i in _stones.size():
		if _stones[i].active and _stones[i].generation == _stone_gen[i]:
			n += 1
	return n


# =====================================================================================
# Isolde, the summary
# =====================================================================================

## Isolde fell (the boss line and the log).
func _on_boss_defeated() -> void:
	if String(game.enemies.boss_info.get("id", "")) == IsoldeData.ARRIVAL["id"]:
		_log("isolde_slain")


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	return "fen checks %d (wading: you %d, summons %d, foes %d) | hex stones raised %d (peak %d, standing %d, broken %d, sunk %d) | bog mother %s | coven breaks %s | events %s" % [
		int(st.get("fen_checks", 0.0)), int(st.get("fen_wade_player", 0.0)), int(st.get("fen_wade_summons", 0.0)), int(st.get("fen_wade_enemies", 0.0)),
		int(st.get("hex_stones_raised", 0.0)), stones_peak, stones_standing(), int(st.get("hex_stones_broken", 0.0)), int(st.get("hex_stones_sunk", 0.0)),
		("killed at " + bog_time) if bog_time != "" else ("alive" if _bog != null else "not spawned"),
		"EARNED" if _coven_logged else "no",
		", ".join(fired) if not fired.is_empty() else "-"]


## Records a Witchwood event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]
