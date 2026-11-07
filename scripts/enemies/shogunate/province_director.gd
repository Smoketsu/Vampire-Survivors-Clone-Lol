## ProvinceDirector — the stage systems of THE BURNING PROVINCE (Stage 13; Act
## V, GDD §15.0 "The Burning Province (Act V phase 2)"; owner-approved proposal
## docs/act5/PROPOSAL.md "Stage 13: The Burning Province"), owned and stepped
## by EnemyDirector on a stage whose STAGE has a "province" config
## (ProvinceStage.PROVINCE; null elsewhere). The zones are MarchDirector's (the
## clock is authoritative); this director reads the current zone
## (MarchDirector.zone_index):
##   * THE PADDIES (owner-approved: "water slows everyone, through
##     TerrainSlow, the one ground-slow path"): the land is cut into terrace
##     cells of paddy_cell px; the zone's ground "paddy" share of them (a fixed
##     hash of the cell, so the floor draws exactly the same water) hold water
##     inside a paddy_dike px dike (in_paddy(), the one geometry). Every
##     paddy_check s whoever wades it is slowed: the necromancer through
##     TerrainSlow.slow_player(), summons through TerrainSlow.slow_summon()
##     (Brinewalker applies to both), enemies through their own
##     Enemy.apply_slow(); the Kappa (row "swimmer") is water-strong and never
##     slowed, nor are floating bodies, structures, the boss or a miniboss.
##   * THE VILLAGE FIRES (a zone with "fires": the Burning Village): every
##     fire_every s a fire flares fire_gap px beside one of the burning houses
##     within fire_scan px of a necromancer (a seeded pick), a ProvinceHazards
##     fire patch that burns every body in it (the necromancer, summons and
##     enemies alike: lure them in), at most fire_max at once.
##   * SHUTEN-DŌJI (the "shuten_doji" event; owner-approved "night only"):
##     the Oni King staggers in from the spawn ring when the Sun's Course says
##     night (an earlier event waits for it); his kit (ShutenKit) registers him
##     on the HUD's miniboss bar; ChestManager drops his chest.
##   * NO SHADOW UNLIT (the stage's achievement; own decision on its rule): a
##     run here that slays Kage with at least no_shadow_lanterns stone
##     lanterns lit (SunCourse's sun_lanterns_lit) earns it (run stat
##     province_no_shadow_unlit; MetaProgress keeps the lifetime count).
## Deterministic: the seeded global RNG only (the house a fire flares at, the
## miniboss's spawn point); the paddies are pure geometry. Stats: paddy_checks,
## paddy_player_wading, paddy_summon_slows, paddy_enemy_slows,
## paddy_swimmers_unslowed, village_fires, shuten_waited,
## shuten_spawned, shuten_killed, province_no_shadow_unlit.
class_name ProvinceDirector
extends Node2D

## Owning run.
var game: Game
## The stage's Province config (ProvinceStage.PROVINCE).
var config: Dictionary = {}
## Log of events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Paddy share of the current zone (0 = dry; MarchDirector zone "ground").
var paddy_share: float = 0.0
## True while the current zone lets the village burn.
var fires_on: bool = false
## Zone index the systems last saw (-1 = not read yet).
var _zone: int = -1
## Seconds until the next paddy check.
var _paddy_cd: float = 0.0
## Seconds until the next village fire.
var _fire_cd: float = 0.0
## The "shuten_doji" event waiting for the night ({} = none).
var _shuten_wait: Dictionary = {}
## Shuten-dōji once spawned (null before / after; generation-checked).
var _shuten: Enemy = null
## Generation of `_shuten` when he spawned.
var _shuten_gen: int = 0
## "m:ss" Shuten-dōji fell ("" while alive / never spawned).
var shuten_time: String = ""
## True once the achievement check ran for this run.
var _ach_checked: bool = false
## Reusable query buffer.
var _tmp: Array = []


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(delta: float) -> void:
	_read_zone()
	if paddy_share > 0.0:
		_paddy_cd -= delta
		if _paddy_cd <= 0.0:
			_paddy_cd += float(config["paddy_check"])
			_paddy_check()
	if fires_on:
		_fire_cd -= delta
		if _fire_cd <= 0.0:
			_fire_cd += float(config["fire_every"])
			_flare()
	_step_shuten()
	_check_achievement()


## Reads the current zone's paddy share and fires (MarchDirector's zone).
func _read_zone() -> void:
	var m := game.enemies.march  # The zones (always present on the Province).
	var zi := m.zone_index if m != null else 0
	if zi == _zone:
		return
	_zone = zi
	var zones: Array = ProvinceStage.ZONES
	var z: Dictionary = zones[clampi(zi, 0, zones.size() - 1)]
	paddy_share = float((z["ground"] as Dictionary).get("paddy", 0.0))
	fires_on = bool(z.get("fires", false))
	_fire_cd = minf(_fire_cd, 1.0)


# =====================================================================================
# The paddies
# =====================================================================================

## True when world point `p` lies in paddy water under terrace share `share`
## (the one geometry: ProvinceGround draws the same cells). A body of radius
## `r` must stand a third of itself inside the bank.
static func in_paddy(p: Vector2, r: float, share: float, cell: float, dike: float) -> bool:
	if share <= 0.0:
		return false
	var cx := floori(p.x / cell)
	var cy := floori(p.y / cell)
	if not cell_flooded(cx, cy, share):
		return false
	var local := p - Vector2(float(cx), float(cy)) * cell  # 0..cell inside the cell.
	var inset := dike + r * 0.33
	return local.x >= inset and local.y >= inset and local.x <= cell - inset and local.y <= cell - inset


## True when terrace cell (cx, cy) holds water under share `share` (a fixed
## hash of the cell: the same in every run, on every machine).
static func cell_flooded(cx: int, cy: int, share: float) -> bool:
	var h := absi(hash(Vector3i(cx, cy, 1301)))
	return float(h % 1000) / 1000.0 < share


## True when a body of radius `r` at `p` wades the current zone's paddy water.
func wading(p: Vector2, r: float) -> bool:
	return in_paddy(p, r, paddy_share, float(config["paddy_cell"]), float(config["paddy_dike"]))


## One check of who wades the paddy water (see the header).
func _paddy_check() -> void:
	var linger := float(config["paddy_linger"]) + float(config["paddy_check"])  # A slow lasts to the next check and a little more.
	game.stat_add("paddy_checks", 1.0)
	for pl in game.all_players:  # The necromancer(s): co-op binds each slot so TerrainSlow reads its own.
		if pl.dead or not wading(pl.position, pl.radius):
			continue
		game.stat_add("paddy_player_wading", 1.0)
		if game.coop == null:
			TerrainSlow.slow_player(game, float(config["paddy_slow_player"]), linger)
		else:
			var prev := game.coop.bound
			game.coop.bind(game.coop.slot_of(pl))
			TerrainSlow.slow_player(game, float(config["paddy_slow_player"]), linger)
			game.coop.bind(prev)
	for h in game.all_hordes:
		for u in h.units:
			if not u.active or u.airborne or u.flies or u.state == SummonedUnit.State.DEAD:
				continue
			if wading(u.position, u.radius) and TerrainSlow.slow_summon(game, u, float(config["paddy_slow_summon"]), linger) > 0.0:
				game.stat_add("paddy_summon_slows", 1.0)
	for e in game.enemies.active:
		if not e.active or e.is_structure or e.is_boss or e.is_miniboss or e.floating or e.untargetable:
			continue
		if not wading(e.position, e.radius):
			continue
		if bool(game.enemies.enemy_def(e.kind).get("swimmer", false)):
			game.stat_add("paddy_swimmers_unslowed", 1.0)  # The kappa: water-strong.
			continue
		e.apply_slow(float(config["paddy_slow_enemy"]), linger)
		game.stat_add("paddy_enemy_slows", 1.0)


# =====================================================================================
# The village fires
# =====================================================================================

## A fire flares beside one burning house near a necromancer (see the header).
func _flare() -> void:
	var haz := game.enemies.province_hazards()
	if haz.fires >= int(config["fire_max"]):
		return
	var pl := game.all_players[randi() % game.all_players.size()] if game.all_players.size() > 1 else game.player
	var reach := float(config["fire_scan"])  # px.
	var cell := ArenaData.CELL
	var span := ceili(reach / cell)
	var c := Vector2i(floori(pl.position.x / cell), floori(pl.position.y / cell))
	var houses: Array = []  # Burning houses in reach (each once).
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var at := Vector2((float(c.x + dx) + 0.5) * cell, (float(c.y + dy) + 0.5) * cell)
			var o := game.arena.obstacle_at(at)
			if o == null or o.kind != ProvinceGlyphs.BURNING_HOUSE or houses.has(o) or o.center.distance_to(pl.position) > reach:
				continue
			houses.append(o)
	if houses.is_empty():
		return
	var o: Arena.Obstacle = houses[randi() % houses.size()]
	var side := Vector2.from_angle(randf() * TAU)  # Which side of the house it flares on.
	var half := Vector2(o.radius, o.radius) if o.is_circle else o.half  # The house's half-size (px).
	var r := float(config["fire_radius"])
	var at := o.center + Vector2(side.x * (half.x + r * 0.6), side.y * (half.y + r * 0.6)) + side * float(config["fire_gap"])
	var mult := game.enemies.damage_mult  # The time scaling (and difficulty).
	if haz.add_fire(at, r, float(config["fire_life"]), float(config["fire_tick"]), float(config["fire_dmg_player"]) * mult,
			float(config["fire_dmg_summon"]) * mult, float(config["fire_dmg_enemy"]) * mult, "village_fire"):
		game.stat_add("village_fires", 1.0)


# =====================================================================================
# Shuten-dōji
# =====================================================================================

## Runs a Province timeline event (EnemyDirector forwards "shuten_doji").
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"shuten_doji":
			_shuten_wait = ev
			if not _is_night():
				game.stat_add("shuten_waited", 1.0)
				_log("shuten_waits_for_night")


## True when the Sun's Course says night (or the Endless Night).
func _is_night() -> bool:
	return game.shogunate == null or not game.shogunate.sun.enabled or game.shogunate.sun.is_night()


## Sends a waiting Shuten-dōji at night, and notes when he fell.
func _step_shuten() -> void:
	if not _shuten_wait.is_empty() and _is_night():
		var ev := _shuten_wait
		_shuten_wait = {}
		var e := game.enemies.spawn_at(String(ev.get("kind", ProvinceEnemyData.SHUTEN_DOJI)), game.enemies.ring_point(randf() * TAU), bool(ev.get("elite", false)))
		if e != null:
			_shuten = e
			_shuten_gen = e.generation
			game.stat_add("shuten_spawned", 1.0)
			game.enemies.show_banner(String(ev["banner"]))
			game.shake(5.0)
			_log("shuten_doji_arrived")
	if _shuten == null or (_shuten.active and _shuten.generation == _shuten_gen):
		return
	_shuten = null
	game.stat_add("shuten_killed", 1.0)
	shuten_time = _clock()
	_log("shuten_doji_killed")


# =====================================================================================
# No Shadow Unlit
# =====================================================================================

## Once Kage is slain on this stage: the achievement's run stat when enough
## stone lanterns were lit this run.
func _check_achievement() -> void:
	if _ach_checked or float(game.stats.get("kage_killed", 0.0)) <= 0.0:
		return
	_ach_checked = true
	var lit := int(game.stats.get("sun_lanterns_lit", 0.0))
	if lit >= int(config["no_shadow_lanterns"]):
		game.stat_add("province_no_shadow_unlit", 1.0)
		_log("no_shadow_unlit")


# =====================================================================================
# Queries (enemy director, HUD, autopilot, summary)
# =====================================================================================

## HUD objective while Shuten-dōji walks ("" = none).
func objective_override() -> String:
	if _shuten != null:
		return "Bring down Shuten-dōji: step out of the sake barrels' circles and the fire"
	return ""


## Autopilot hint: out of a village or sake fire at `p` (zero when none).
func danger_push(p: Vector2) -> Vector2:
	if game.enemies.province_haz == null:
		return Vector2.ZERO
	return game.enemies.province_haz.danger_push(p)


## One-line autotest summary: the paddies, the fires, Shuten-dōji, the lanterns.
func summary_line() -> String:
	var st := game.stats
	return "paddies: checks %d, you wading %d, summon slows %d, enemy slows %d, kappa unslowed %d | village fires %d (burns: you %d, summons %d, enemies %d, enemy dmg %d) | shuten-doji %s (waited for night %d) | lanterns lit %d / %d, no shadow unlit %d | events %s" % [
		int(st.get("paddy_checks", 0.0)), int(st.get("paddy_player_wading", 0.0)), int(st.get("paddy_summon_slows", 0.0)),
		int(st.get("paddy_enemy_slows", 0.0)), int(st.get("paddy_swimmers_unslowed", 0.0)), int(st.get("village_fires", 0.0)),
		int(st.get("province_fire_burns_player", 0.0)), int(st.get("province_fire_burns_summon", 0.0)), int(st.get("province_fire_burns_enemy", 0.0)),
		int(st.get("dmg_village_fire", 0.0)),
		("killed at " + shuten_time) if shuten_time != "" else ("alive" if _shuten != null else ("waiting" if not _shuten_wait.is_empty() else "not spawned")),
		int(st.get("shuten_waited", 0.0)), int(st.get("sun_lanterns_lit", 0.0)), int(config["no_shadow_lanterns"]),
		int(st.get("province_no_shadow_unlit", 0.0)), ", ".join(fired) if not fired.is_empty() else "-"]


## Records a Province event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]
