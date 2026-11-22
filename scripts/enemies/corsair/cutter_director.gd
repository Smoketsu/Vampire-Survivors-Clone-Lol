## CutterDirector — the stage systems of the Smuggler's Cutter (Act X, the
## Black Tide; GDD §15.0 "The Smuggler's Cutter (Act X phase 2)";
## owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 1 "Stage
## A: The Smuggler's Cutter"), owned and stepped by EnemyDirector on a stage
## whose STAGE has a "cutter" config (CutterStage.CUTTER; `game.enemies.cutter`,
## null elsewhere). The zones are MarchDirector's (the camera does not move: a
## zone changes the look and the timeline, not the map); Boarding, the Deck, the
## Strikes from the Sea and the Black Tide are the shared CorsairRules'. Here:
##   * POWDER BARRELS (the stage mechanic): at the start of every zone the
##     barrels along the rails (config "barrels": [x, side] rail points, set
##     barrel_inset px inside the rail) are restocked: every spot without a
##     standing barrel gets a new one (CutterEnemyData "powder_barrel", a 1 HP
##     structure, PowderBarrelKit; its blast is THE powder blast,
##     CorsairRules.powder_blast()). Blasts are counted (on_barrel_blown());
##     the enemies they tip over the rail are the deck's overboard count.
##   * THE FOG BANK (config fog_zone, fog_reveal): while that zone lasts every
##     boat launched shows its lane only for its last fog_reveal s
##     (BoardingParty.fog_reveal, the boat's "fog" flag: the lane draw), and
##     fog drifts over the water (drawn, textures).
##   * BOSUN GORRAN AND THE RAM LONGBOAT (the "gorran" event; config "ram"):
##     the heavy longboat shows its lane at a boarding point (lane_time s, the
##     seeded gameplay RNG picks the point), then RAMS THE HULL: every
##     grounded summon on the deck is knocked `push` px away from the ram point
##     (TerrainSlow.push_summon() x Sea Legs, the act's one shove path) and
##     staggered (CombatResolver.stun_unit(u, stagger, "ram"), the one summon
##     stun path), the necromancer is shoved too (TerrainSlow.push_player());
##     then the RAM LONGBOAT (CutterEnemyData "ram_longboat", a boat structure
##     in the water) lies alongside and pours its crew, Gorran first, one every
##     pour_every s, through EnemyDirector.spawn_at() at the plank (it bypasses
##     BoardingParty's queue: the miniboss's own boat, GDD row). Sunk, the crew
##     still aboard drowns (no XP); emptied, it casts off after leave_time s.
##   * THE FIRE SHIP (fire_ship(), Captain Crow's third phase; config "fire"):
##     his burning sloop rams the hull (the same stagger, smaller), and until he
##     falls (stop_fire()) burning planks spread as short fire patches every
##     `every` s through THE Hell Pits ground path (Game.inferno_rules()
##     .pits.open_pit(), tag "fire_ship"; off Act VI only those opened pits
##     burn: HellPits.step_opened()), each `dist_min`..`dist_max` px from the
##     nearest necromancer at a fixed turning angle (no RNG), on the deck.
##   * NOT ONE ABOARD (the stage's achievement): when the run's clean sinks
##     (BoardingParty: a boat sunk before any of its crew climbed aboard,
##     stat boats_sunk_clean) reach not_one_aboard, the run stat
##     cutter_not_one_aboard is set (MetaProgress counts the runs: lifetime
##     not_one_aboard_runs; it unlocks Barnacle Bones).
##   * The HUD objective while Bosun Gorran stands.
## Barrels and the ram longboat do not count as alive enemies (regular_alive()
## subtracts structures_alive()). Deterministic: game time, fixed angles and
## the seeded gameplay RNG (the ram's boarding point). Stats:
## cutter_barrels_placed, cutter_barrels_blown,
## cutter_fog_boats, cutter_rams, cutter_ram_staggers, cutter_ram_crew,
## cutter_ram_crew_drowned, cutter_ram_sunk, cutter_fire_patches,
## cutter_not_one_aboard, gorran_spawned.
class_name CutterDirector
extends Node2D

## Ram state: no ram longboat out.
const RAM_IDLE: int = 0
## Ram state: its lane shows.
const RAM_LANE: int = 1
## Ram state: alongside, pouring its crew.
const RAM_HOOKED: int = 2

## Owning run.
var game: Game
## The stage's config (CutterStage.CUTTER).
var config: Dictionary = {}
## Log of Cutter events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Index of the current zone (STAGE "zones"; -1 before the first step).
var zone: int = -1
## Standing barrels: [Enemy, generation, spot index].
var _barrels: Array = []
## Barrels set off this run.
var blown: int = 0
## Boats BoardingParty had launched at the last step (the fog's boat count).
var _launched_seen: int = 0
## Ram state (RAM_IDLE / RAM_LANE / RAM_HOOKED).
var ram_state: int = RAM_IDLE
## Game time (s) the ram state began.
var _ram_t: float = 0.0
## The ram's rail point and outward normal.
var _ram_rail: Vector2 = Vector2.ZERO
## Outward normal at the ram's rail point.
var _ram_n: Vector2 = Vector2.UP
## The ram longboat once alongside (generation-checked; null otherwise).
var _ram_boat: Enemy = null
## Pool generation of `_ram_boat`.
var _ram_gen: int = 0
## Crew still aboard the ram longboat (kind ids, Gorran first).
var _ram_crew: Array[String] = []
## Game time (s) of the next crewman off the ram longboat.
var _ram_next: float = 0.0
## The event that sent the ram (banner, escort).
var _ram_ev: Dictionary = {}
## Bosun Gorran once aboard (generation-checked; null before).
var _gorran: Enemy = null
## Pool generation of `_gorran`.
var _gorran_gen: int = 0
## "m:ss" Gorran fell ("" while alive / never came).
var gorran_time: String = ""
## True while the Fire Ship's planks burn (Crow's third phase).
var fire_on: bool = false
## Game time (s) of the next fire patch.
var _fire_next: float = 0.0
## Fire patches opened so far (turns the next one's angle).
var _fire_n: int = 0
## The Fire Ship's ram point (drawn while it burns alongside).
var _fire_at: Vector2 = Vector2.INF
## Outward normal at the Fire Ship's ram point.
var _fire_n_out: Vector2 = Vector2.UP
## Game time (s) the Fire Ship rammed.
var _fire_t: float = -INF
## True once Not One Aboard was earned this run.
var not_one_aboard: bool = false
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false
## Reusable query buffer.
var _tmp: Array = []


func _ready() -> void:
	z_index = -5  # On the deck and the sea, under every body (as CorsairRules).
	z_as_relative = false


## Per-tick update (EnemyDirector): the zone (barrels, fog), the ram, the fire,
## Not One Aboard.
func step(_delta: float) -> void:
	if game.deck == null:
		return
	var z := _zone_at(game.elapsed)
	if z != zone:
		zone = z
		_enter_zone()
	_prune_barrels()
	_step_ram()
	_step_fire()
	_check_not_one_aboard()
	var launched := game.corsair.boarding.launched if game.corsair != null else 0
	if _fogged() and launched > _launched_seen:
		game.stat_add("cutter_fog_boats", float(launched - _launched_seen))  # Boats launched under the fog.
	_launched_seen = launched
	var busy := ram_state != RAM_IDLE or fire_on or _fire_at != Vector2.INF or _fogged()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


# =====================================================================================
# Zones: the barrels and the fog
# =====================================================================================

## Index of the zone at game time `t` (the last STAGE "zones" row started by then).
func _zone_at(t: float) -> int:
	var zs: Array = game.stage_def.get("zones", [])
	var z := 0
	for k in zs.size():
		if t >= float((zs[k] as Dictionary).get("start", 0.0)):
			z = k
	return z


## Id of the current zone ("" before the first step).
func zone_id() -> String:
	var zs: Array = game.stage_def.get("zones", [])
	if zone < 0 or zone >= zs.size():
		return ""
	return String((zs[zone] as Dictionary).get("id", ""))


## True while the Fog Bank lasts.
func _fogged() -> bool:
	return zone_id() == String(config.get("fog_zone", ""))


## A new zone: the barrels are restocked and the fog rolls in or lifts.
func _enter_zone() -> void:
	_restock_barrels()
	var fog := _fogged()
	if game.corsair != null:
		game.corsair.boarding.fog_reveal = float(config.get("fog_reveal", 2.0)) if fog else 0.0
	if fog:
		_log("fog")


## Every barrel spot without a standing barrel gets a new one.
func _restock_barrels() -> void:
	var spots: Array = config.get("barrels", [])
	var inset := float(config.get("barrel_inset", 16.0))
	var placed := 0
	for i in spots.size():
		var taken := false
		for b: Array in _barrels:
			if int(b[2]) == i:
				taken = true
				break
		if taken:
			continue
		var sp: Array = spots[i]
		var side := int(sp[1])
		var at := game.deck.rail_point(float(sp[0]), side) - Vector2(0.0, float(side)) * inset
		var e := game.enemies.spawn_routed(CutterEnemyData.BARREL, at, 1.0, false)
		if e != null:
			_barrels.append([e, e.generation, i])
			placed += 1
	if placed > 0:
		game.stat_add("cutter_barrels_placed", float(placed))
		_log("barrels %d" % placed)


## Drops the barrels that are gone.
func _prune_barrels() -> void:
	var i := 0
	while i < _barrels.size():
		var b: Array = _barrels[i]
		if not _alive(b[0], int(b[1])):
			_barrels.remove_at(i)
			continue
		i += 1


## A barrel went off (PowderBarrelKit.on_killed(), after its blast): counted,
## with the enemies the blast drowned this tick.
func on_barrel_blown(_e: Enemy) -> void:
	blown += 1
	game.stat_add("cutter_barrels_blown", 1.0)
	_prune_barrels()


## Standing barrels and the ram longboat (they do not count as alive enemies).
func structures_alive() -> int:
	var n := 0
	for b: Array in _barrels:
		if _alive(b[0], int(b[1])):
			n += 1
	if _alive(_ram_boat, _ram_gen):
		n += 1
	return n


# =====================================================================================
# Bosun Gorran and the Ram Longboat
# =====================================================================================

## Runs a Cutter timeline event (EnemyDirector forwards the "gorran" type).
func start_event(ev: Dictionary) -> void:
	if String(ev["type"]) != "gorran" or ram_state != RAM_IDLE:
		return
	var pts: Array = (game.stage_def.get("boarding", {}) as Dictionary).get("points", [])
	var pick: Array = pts[randi() % pts.size()] if not pts.is_empty() else [0.0, -1]
	var side := int(pick[1])
	_ram_rail = game.deck.rail_point(float(pick[0]), side)
	_ram_n = Vector2(0.0, float(side))
	_ram_ev = ev
	ram_state = RAM_LANE
	_ram_t = game.elapsed
	if ev.has("banner"):
		game.enemies.show_banner(String(ev["banner"]))
	if game.corsair != null:
		game.corsair.play_sound("hull_creak", _ram_rail, 0.2)
	_log("ram")


## The ram's clock: the lane, the ram, the pour, the cast-off.
func _step_ram() -> void:
	var rc: Dictionary = config.get("ram", {})
	var now := game.elapsed
	match ram_state:
		RAM_LANE:
			if now >= _ram_t + float(rc.get("lane_time", 3.0)):
				_ram_hits(rc)
		RAM_HOOKED:
			if not _alive(_ram_boat, _ram_gen):
				if not _ram_crew.is_empty():
					game.stat_add("cutter_ram_crew_drowned", float(_ram_crew.size()))
					game.stat_add("cutter_ram_sunk", 1.0)
					_log("ram sunk")
				_ram_crew.clear()
				_ram_boat = null
				ram_state = RAM_IDLE
				return
			while not _ram_crew.is_empty() and now >= _ram_next:
				_ram_pour(rc)
				_ram_next += float(rc.get("pour_every", 0.5))
			if _ram_crew.is_empty() and now >= _ram_next + float(rc.get("leave_time", 2.5)):
				game.enemies.despawn(_ram_boat)
				_ram_boat = null
				ram_state = RAM_IDLE
	if _gorran != null and gorran_time == "" and not _alive(_gorran, _gorran_gen):
		gorran_time = _clock()
		_log("gorran down")


## THE RAM: the hull is struck (every summon staggered back), the longboat lies
## alongside and its crew starts to pour.
func _ram_hits(rc: Dictionary) -> void:
	ram_stagger(_ram_rail, float(rc.get("push", 90.0)), float(rc.get("stagger", 0.6)), float(rc.get("damage", 4.0)))
	game.stat_add("cutter_rams", 1.0)
	var row := game.enemies.enemy_def(CutterEnemyData.RAM_LONGBOAT)
	var boat := game.enemies.spawn_routed(CutterEnemyData.RAM_LONGBOAT, _ram_rail, game.enemies.hp_mult, false)
	boat.position = _ram_rail + _ram_n * float(row["radius"]) * 0.6  # In the water, its hull over the rail line.
	_ram_boat = boat
	_ram_gen = boat.generation
	_ram_crew.clear()
	_ram_crew.append(CutterEnemyData.GORRAN)
	for grp: Dictionary in _ram_ev.get("escort", []):
		for j in int(grp.get("count", 0)):
			_ram_crew.append(String(grp["kind"]))
	_ram_next = game.elapsed + float(rc.get("first_pour", 0.6))
	ram_state = RAM_HOOKED
	_ram_t = game.elapsed
	if game.corsair != null:
		game.corsair.play_sound("hook_bite", _ram_rail, 0.2)


## One crewman steps off the ram longboat (Gorran first).
func _ram_pour(_rc: Dictionary) -> void:
	var kind: String = _ram_crew.pop_front()
	var along := Vector2(-_ram_n.y, _ram_n.x)
	var at := _ram_rail - _ram_n * 16.0 + along * (float((_ram_crew.size() % 3) - 1) * 14.0)
	var e := game.enemies.spawn_at(kind, at, false)
	if e == null:
		return
	game.stat_add("cutter_ram_crew", 1.0)
	if kind == CutterEnemyData.GORRAN:
		_gorran = e
		_gorran_gen = e.generation
		game.stat_add("gorran_spawned", 1.0)
		game.shake(5.0)
		if game.corsair != null:
			game.corsair.play_sound("plank_drop", at, 0.2)
		_log("gorran")


## THE HULL STAGGER (the ram longboat, the Fire Ship): every grounded summon on
## the deck is knocked `push` px straight away from the rail point `at` (x Sea
## Legs; the rail stops it) and stunned `stagger` s, taking `dmg` x the
## enemies' damage scaling; every necromancer is shoved half as far.
func ram_stagger(at: Vector2, push: float, stagger: float, dmg: float) -> void:
	var dm := game.enemies.damage_mult
	var n := 0
	for h in game.all_hordes:
		for u in h.units:
			if not u.active or u.airborne or u.flies or u.state == SummonedUnit.State.DEAD:
				continue
			var off := u.position - at
			var dir := off.normalized() if off.length() > 0.01 else Vector2.DOWN
			if dmg > 0.0:
				game.combat.damage_unit(u, dmg * dm, CutterEnemyData.RAM_SOURCE)
			if not u.active:
				continue
			TerrainSlow.push_summon(game, u, dir * push * game.corsair_rules().sea_legs_mult(u), 1.0)
			game.combat.stun_unit(u, stagger, "ram")
			n += 1
	for pl in game.all_players:
		if pl.dead or game.grave_step.is_dashing():
			continue
		var off := pl.position - at
		pl.position += (off.normalized() if off.length() > 0.01 else Vector2.DOWN) * push * 0.5
	game.stat_add("cutter_ram_staggers", float(n))
	game.shake(9.0)
	game.effects.impact(at, 70.0, Palette.CORSAIR_OAK_LIGHT)
	if game.corsair != null:
		game.corsair.play_sound("hull_creak", at, 0.1)


## The HUD objective while Bosun Gorran stands ("" otherwise).
func objective_override() -> String:
	if _alive(_gorran, _gorran_gen):
		return String(config.get("gorran_objective", ""))
	return ""


# =====================================================================================
# The Fire Ship (Captain Crow's third phase)
# =====================================================================================

## Crow's burning sloop rams the hull at rail point `at` (outward normal `n`):
## the stagger, then burning planks spread until stop_fire().
func fire_ship(at: Vector2, n: Vector2) -> void:
	var fc: Dictionary = config.get("fire", {})
	ram_stagger(at, float(fc.get("push", 70.0)), float(fc.get("stagger", 0.4)), 0.0)
	_fire_at = at
	_fire_n_out = n
	_fire_t = game.elapsed
	fire_on = true
	_fire_next = game.elapsed + float(fc.get("first", 1.0))
	game.inferno_rules()  # THE Hell Pits ground path (InfernoRules off Act VI: only the pits opened here burn).
	_log("fire ship")


## The fire stops spreading (Crow fell); the patches already burning burn out.
func stop_fire() -> void:
	if fire_on:
		fire_on = false
		_log("fire out")


## Opens a fire patch on its clock while the Fire Ship burns.
func _step_fire() -> void:
	var fc: Dictionary = config.get("fire", {})
	if _fire_at != Vector2.INF and game.elapsed > _fire_t + float(fc.get("show", 8.0)) and not fire_on:
		_fire_at = Vector2.INF
	if not fire_on:
		return
	var boss := game.enemies.boss
	if boss == null or not boss.active:
		stop_fire()
		return
	if game.elapsed < _fire_next:
		return
	_fire_next = game.elapsed + float(fc.get("every", 2.2))
	var pl := game.nearest_player(game.player.position)
	var a := float(_fire_n) * 2.39996  # The golden angle: patches spread round him (no RNG).
	var dist := lerpf(float(fc.get("dist_min", 50.0)), float(fc.get("dist_max", 170.0)), float(_fire_n % 3) / 2.0)
	var r := float(fc.get("radius", 30.0))
	var at := game.deck.clamp_point(pl.position + Vector2.from_angle(a) * dist, r * 0.5)
	_fire_n += 1
	if game.inferno_rules().pits.open_pit(at, r, float(fc.get("life", 7.0)), {"tag": "fire_ship", "telegraph": float(fc.get("telegraph", 0.9)), "silent": true}):
		game.stat_add("cutter_fire_patches", 1.0)


# =====================================================================================
# Not One Aboard
# =====================================================================================

## Earned once the run's clean sinks reach the goal.
func _check_not_one_aboard() -> void:
	if not_one_aboard:
		return
	if float(game.stats.get("boats_sunk_clean", 0.0)) >= float(config.get("not_one_aboard", 5)):
		not_one_aboard = true
		game.stats["cutter_not_one_aboard"] = 1.0
		_log("not one aboard")


# =====================================================================================
# Autotest, report, drawing
# =====================================================================================

## Autopilot hint: off the ram point while its lane shows, and out of a
## standing powder barrel's blast (any hit, the army's own, may set it off).
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var keg: Dictionary = game.enemies.enemy_def(CutterEnemyData.BARREL).get("keg", {})
	var br := float(keg.get("radius", 78.0)) + float(config.get("barrel_avoid", 20.0))
	for b: Array in _barrels:
		if not _alive(b[0], int(b[1])):
			continue
		var bo: Vector2 = p - (b[0] as Enemy).position
		var bd := bo.length()
		if bd < br:
			push += (bo / bd if bd > 0.01 else Vector2.DOWN) * (1.0 - bd / br) * 1.5
	if ram_state != RAM_LANE:
		return push
	var reach := 150.0
	var off := p - _ram_rail
	var dist := off.length()
	if dist >= reach:
		return push
	return push + (off / dist if dist > 0.01 else Vector2.DOWN) * (1.0 - dist / reach) * 2.0


## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	return "barrels placed %d, blown %d | fog boats %d | ram %d (summons staggered %d, crew %d, drowned with the boat %d, sunk %d) | gorran spawned %d, killed %d%s | fire patches %d | clean sinks %d / %d, not one aboard %s | events: %s" % [
		int(st.get("cutter_barrels_placed", 0.0)), blown,
		int(st.get("cutter_fog_boats", 0.0)), int(st.get("cutter_rams", 0.0)), int(st.get("cutter_ram_staggers", 0.0)),
		int(st.get("cutter_ram_crew", 0.0)), int(st.get("cutter_ram_crew_drowned", 0.0)), int(st.get("cutter_ram_sunk", 0.0)),
		int(st.get("gorran_spawned", 0.0)), int(st.get("gorran_kills", 0.0)), (" at " + gorran_time) if gorran_time != "" else "",
		int(st.get("cutter_fire_patches", 0.0)), int(st.get("boats_sunk_clean", 0.0)), int(config.get("not_one_aboard", 5)),
		"EARNED" if not_one_aboard else "no", ", ".join(fired)]


## True while `e` is the same living enemy it was at generation `gen`.
static func _alive(e: Enemy, gen: int) -> bool:
	return e != null and e.active and e.generation == gen


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	fired.append("%s %s" % [_clock(), what])


## The current game clock as "m:ss".
func _clock() -> String:
	var t := int(game.elapsed)
	return "%d:%02d" % [t / 60, t % 60]


## The ram's lane (its longboat closing, a sash-red wake, a big lantern), the
## burning Fire Ship alongside, and the fog over the water. Textures and rects
## only (visual).
func _draw() -> void:
	var t := game.elapsed
	if _fogged():
		_draw_fog(t)
	if ram_state == RAM_LANE:
		var rc: Dictionary = config.get("ram", {})
		var k := clampf((t - _ram_t) / maxf(float(rc.get("lane_time", 3.0)), 0.01), 0.0, 1.0)
		var d := 40.0
		while d < 420.0:
			if d > 40.0 + (1.0 - k) * 340.0:
				draw_rect(Rect2(_ram_rail + _ram_n * d - Vector2(2.5, 2.5), Vector2(5.0, 5.0)), Color(Palette.CORSAIR_SASH_LIGHT, 0.8))
			d += 14.0
		var boat_at := _ram_rail + _ram_n * (40.0 + (1.0 - k) * 340.0)
		SpriteBank.draw(self, "corsair/" + CutterEnemyData.RAM_LONGBOAT, boat_at, false)
		var glow := 0.55 + 0.45 * absf(sin(t * 8.0))
		SpriteBank.draw_disc(self, _ram_rail, 18.0, Color(Palette.CORSAIR_SASH, 0.3 * glow))
		SpriteBank.draw_disc(self, _ram_rail, 6.0, Color(Palette.CORSAIR_LANTERN_LIGHT, glow))
	if _fire_at != Vector2.INF:
		var fc: Dictionary = config.get("fire", {})
		var fade := clampf(1.0 - (t - _fire_t) / maxf(float(fc.get("show", 8.0)), 0.01), 0.0, 1.0)
		var hull := _fire_at + _fire_n_out * 34.0
		SpriteBank.draw(self, "corsair/raider_ship", hull, false, Color(1.0, 0.55 + 0.2 * fade, 0.35, 0.5 + 0.5 * fade))
		for j in 6:
			var fp := hull + Vector2(-48.0 + 19.0 * float(j), -6.0 + 5.0 * sin(t * 7.0 + float(j)))
			SpriteBank.draw_disc(self, fp, 7.0 + 3.0 * absf(sin(t * 9.0 + float(j) * 1.3)), Color(Palette.CORSAIR_LANTERN, 0.55 * fade + 0.2))
			SpriteBank.draw_disc(self, fp + Vector2(0.0, -4.0), 3.5, Color(Palette.CORSAIR_LANTERN_LIGHT, 0.7 * fade + 0.2))


## The Fog Bank: soft grey-white banks drifting over the water round the hull.
func _draw_fog(t: float) -> void:
	var n := int(config.get("fog_wisps", 10))
	var dk := game.deck
	for i in n:
		var s := fposmod(float(i) / float(n) * dk.perimeter_length + t * 9.0, dk.perimeter_length)
		var p := dk.perimeter_point(s) + dk.perimeter_normal(s) * (70.0 + 30.0 * sin(t * 0.4 + float(i)))
		SpriteBank.draw_disc(self, p, 90.0 + 20.0 * float(i % 3), Color(0.72, 0.76, 0.80, 0.16))
