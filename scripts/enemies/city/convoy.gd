## Convoy — THE VEHICLES of the Last Line's Armour rule (Act VIII; GDD §15.0
## "Armour"; owner-approved proposal: "cars, trucks, APCs and tanks drive in
## straight lines (headlights show the lane 1 s ahead), run over every summon in
## the lane, then turn and come again. A destroyed vehicle becomes a burning
## wreck, a new obstacle for the rest of the run (and it explodes a few seconds
## later, hurting both sides). One path, Convoy, using the existing obstacle and
## push-out code"), owned by Game.city as `convoy`. What it owns:
##   * the vehicles in play (register() / the stale guard), for the autotest
##     bot's headlight push (danger_push()) and the counters;
##   * THE RUN-OVER (run_over()): every summon and necromancer inside a
##     vehicle's body box takes its run_damage (summons through
##     CombatResolver.damage_unit() and a sideways shove to a free point, the
##     necromancer through damage_player(): Grave Step's i-frames dodge it), at
##     most once every hit_every s per body: an enemy attack, not a summon rule;
##   * THE WRECK (wreck_vehicle()): a dead vehicle becomes a burning city_wreck
##     through CityBlocks.add_wreck() (solid for the rest of the run, on a
##     blocks stage only) and explodes WRECK explode_after s later, hurting both
##     sides within WRECK radius px (CityRules.blast(); never civilians); off a
##     blocks stage (or where no wreck fits) it only explodes;
##   * a burning wreck turning burnt out (the arena redraws).
## The driving itself (the lane, the turn, the ram into a wreck) is the
## vehicle's own kit (CityKit, row "vehicle"), which calls run_over() each tick.
## Determinism: game time only; no RNG.
class_name Convoy
extends RefCounted

## Owning run.
var game: Game
## The vehicles in play (the stale guard drops dead ones).
var vehicles: Array[Enemy] = []
## Pool generation of each entry of `vehicles`.
var _gens: PackedInt32Array = PackedInt32Array()
## Pending wreck explosions: world points.
var _boom_at: PackedVector2Array = PackedVector2Array()
## Game time (s) each pending explosion goes off.
var _boom_t: PackedFloat32Array = PackedFloat32Array()
## Wrecks already counted as burnt out (their obstacles).
var _burnt_seen: Array = []
## Vehicles activated this run.
var driven: int = 0
## Summons run over this run.
var runs_summons: int = 0
## Run-overs on a necromancer this run.
var runs_you: int = 0
## Vehicles that rammed a wreck (or an obstacle) this run.
var rams: int = 0
## Vehicles destroyed this run.
var destroyed: int = 0
## Wreck explosions this run.
var explosions: int = 0
## Turns at a lane's end this run.
var turns: int = 0
## Scratch buffer for grid queries.
var _buf: Array = []


## Builds the convoy for `p_game`.
func _init(p_game: Game) -> void:
	game = p_game


## A vehicle `e` was activated (its CityKit.reset()).
func register(e: Enemy) -> void:
	var i := vehicles.size() - 1
	while i >= 0:
		if not vehicles[i].active or vehicles[i].generation != _gens[i]:
			vehicles.remove_at(i)
			_gens.remove_at(i)
		i -= 1
	vehicles.append(e)
	_gens.append(e.generation)
	driven += 1
	game.stat_add("city_vehicles_driven", 1.0)


## Per-tick update (CityRules.step()): the wrecks' explosions; a wreck that
## stops burning asks the arena to redraw.
func step(_delta: float) -> void:
	var now := game.elapsed
	var i := 0
	while i < _boom_at.size():
		if now >= _boom_t[i]:
			_explode(_boom_at[i])
			_boom_at.remove_at(i)
			_boom_t.remove_at(i)
		else:
			i += 1
	var cb := game.arena.city_blocks
	if cb != null:
		for w in cb.wrecks:
			if now - w.placed_at >= float(CityRulesData.WRECK["burn_time"]) and not _burnt_seen.has(w.obstacle):
				_burnt_seen.append(w.obstacle)
				cb.dirty = true  # It shows burnt out from now on.
		if _burnt_seen.size() > CityBlockData.WRECK_MAX * 2:
			_burnt_seen = _burnt_seen.slice(_burnt_seen.size() - CityBlockData.WRECK_MAX)


## THE RUN-OVER of vehicle `e` (body box `half_length` x `half_width` px along
## unit `dir`): every summon and necromancer inside takes `dmg` (already
## scaled), at most once every hit_every s per body (`hits`: the vehicle's own
## body -> game time map). Summons are shoved sideways out of the lane.
func run_over(e: Enemy, dir: Vector2, half_length: float, half_width: float, dmg: float, hits: Dictionary) -> void:
	var now := game.elapsed
	var every := float(CityRulesData.CONVOY["hit_every"])
	var perp := Vector2(-dir.y, dir.x)
	game.ally_grid.query(e.position, half_length + UnitData.MAX_BLOCK_RADIUS + 4.0, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
			continue
		var rel := u.position - e.position
		if absf(rel.dot(dir)) > half_length + u.radius or absf(rel.dot(perp)) > half_width + u.radius:
			continue
		var last: Variant = hits.get(u)
		if last != null and now - float(last) < every:
			continue
		hits[u] = now
		game.combat.damage_unit(u, dmg, e.kind, e)
		runs_summons += 1
		game.stat_add("city_run_over_summons", 1.0)
		var side := signf(rel.dot(perp)) if absf(rel.dot(perp)) > 0.5 else 1.0
		if u.active:
			u.position = game.arena.free_point(u.position + perp * side * float(CityRulesData.CONVOY["shove"]), u.radius)
	for pl in game.all_players:
		if pl.dead:
			continue
		var rel := pl.position - e.position
		if absf(rel.dot(dir)) > half_length + pl.radius or absf(rel.dot(perp)) > half_width + pl.radius:
			continue
		var last: Variant = hits.get(pl)
		if last != null and now - float(last) < every:
			continue
		hits[pl] = now
		var hp_before := pl.hp
		game.combat.damage_player(dmg, e.kind, pl, e)
		runs_you += 1
		game.stat_add("city_run_over_you", 1.0)
		if pl.hp >= hp_before:
			game.stat_add("city_run_over_dodged", 1.0)  # Grave Step's i-frames (or a ward) took it.
	if hits.size() > 64:
		hits.clear()  # A long drive: forget old bodies (the cooldown is short).


## A vehicle `e` rammed a wreck (or another obstacle on a stage without
## blocks): counted; the kit stops and turns.
func on_ram(_e: Enemy, wreck: bool) -> void:
	rams += 1
	game.stat_add("city_rams_wreck" if wreck else "city_rams_obstacle", 1.0)


## A vehicle turned at its lane's end (the kit).
func on_turn() -> void:
	turns += 1


## THE WRECK: vehicle `e` (row half_length px long) died: a burning wreck
## where it fell (CityBlocks.add_wreck(), blocks stages only) and an
## explosion WRECK explode_after s later at the wreck (or where it fell).
func wreck_vehicle(e: Enemy, half_length: float) -> void:
	destroyed += 1
	game.stat_add("city_vehicles_destroyed", 1.0)
	var at := e.position
	var cb := game.arena.city_blocks
	if cb != null:
		var o := cb.add_wreck(e.position, minf(half_length, float(CityRulesData.WRECK["half_along"])), game.elapsed)
		if o != null:
			at = o.center
			game.stat_add("city_wrecks", 1.0)
	place_explosion(at)
	game.city.play_sound("vehicle_wreck", at, 0.2)


## Schedules a wreck's explosion at `at` (WRECK explode_after s from now).
func place_explosion(at: Vector2) -> void:
	_boom_at.append(at)
	_boom_t.append(game.elapsed + float(CityRulesData.WRECK["explode_after"]))


## A wreck explodes at `at`: both sides within WRECK radius px.
func _explode(at: Vector2) -> void:
	explosions += 1
	var dmg := float(CityRulesData.WRECK["damage"]) * game.enemies.damage_mult
	game.city.blast(at, float(CityRulesData.WRECK["radius"]), dmg, CityEnemyData.WRECK_SOURCE, true)
	game.effects.impact(at, float(CityRulesData.WRECK["radius"]), Palette.CITY_HERO_ORANGE, "")
	game.city.play_sound("vehicle_wreck", at, 0.1)


## The autotest autopilot's push out of every vehicle's headlight lane at `p`
## (the strip ahead of it, headlight_time s of its drive), sideways off the lane.
func danger_push(p: Vector2) -> Vector2:
	var out := Vector2.ZERO
	for i in vehicles.size():
		var e := vehicles[i]
		if not e.active or e.generation != _gens[i] or not (e.kit is CityKit):
			continue
		var kit := e.kit as CityKit
		var dir := kit.drive_dir
		var rel := p - e.position
		var along := rel.dot(dir)
		var reach := e.move_speed * float(CityRulesData.CONVOY["headlight_time"]) + kit.half_length()
		if along < -kit.half_length() or along > reach:
			continue
		var perp := Vector2(-dir.y, dir.x)
		var across := rel.dot(perp)
		var half := kit.half_width() + 22.0  # The lane and a body's margin (px).
		if absf(across) < half:
			out += perp * (signf(across) if absf(across) > 0.5 else 1.0) * (1.0 - absf(across) / half) * 1.5
	return out
