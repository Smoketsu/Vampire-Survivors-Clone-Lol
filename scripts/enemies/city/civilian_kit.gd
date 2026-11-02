## CivilianKit — the kit of a Civilian (CityEnemyData "civilian"; Act VIII,
## GDD §15.0 "Civilians"; owner: "fleeing civilians fill the streets at the
## start of a run ... we're not sparing them"): not a fighter. It owns every
## tick (physics() is always true): it FLEES from the nearest necromancer and
## the nearest summon within summon_fear px, along the street it is in (on a
## city-block layout the flight snaps to that street's axis, the axis with the
## farther way to go at a crossing; in an alley or a lot it runs straight and
## slides along the faces): flat out within `panic` px of the necromancer or
## with a summon near, else only walking away (`stroll` x its speed, so the
## army can catch the crowd). It never attacks, and leaves the field with no XP
## once it is `recycle` px from every necromancer (Civilians.flee_off()). It
## never body-blocks the ring (Enemy.civilian) and the city's own blasts spare
## it (CityRules.hits_enemy()); the army kills it like any enemy and its XP
## crystal drops through the normal kill path (Civilians counts it). Every
## female_every-th civilian (by its think slot) has the woman's look
## (city/civilian_woman, figure style). The one exception to "enemies always
## advance", owner-approved. No RNG.
class_name CivilianKit
extends CityKit

## True when this civilian has the woman's look.
var female: bool = false
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	var civ := rules(e).civilians
	female = e.think_slot % maxi(1, int(civ.cfg["female_every"])) == 0
	if female and e.motion != null and SpriteBank.has(CityEnemyData.CIVILIAN_WOMAN_SPRITE):
		e.motion.reset(UnitMotion.feet_of(CityEnemyData.CIVILIAN_WOMAN_SPRITE, "", e.radius), e.radius, 1.0, false)
	civ.on_spawn(e)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	rules(e).civilians.on_gone(e)


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	rules(e).civilians.on_killed(e)


## The flight (always owns the tick).
func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	var civ := rules(e).civilians
	if civ.far_from_all(e):
		civ.flee_off(e)
		return true
	var pl := g.nearest_player(e.position)
	var away := e.position - pl.position
	away = away.normalized() if away.length() > 0.5 else Vector2.RIGHT
	var fear := float(civ.cfg["summon_fear"])
	g.ally_grid.query(e.position, fear, _buf)
	var near: SummonedUnit = null
	var near_d := INF
	for u: SummonedUnit in _buf:
		if u.active and u.state != SummonedUnit.State.DEAD:
			var dist := u.position.distance_to(e.position)
			if dist < near_d:
				near_d = dist
				near = u
	if near != null and near_d > 0.5:
		away += (e.position - near.position) / near_d * (1.0 - near_d / fear)
	var dir := away.normalized() if away.length() > 0.01 else Vector2.RIGHT
	var calm := near == null and pl.position.distance_to(e.position) > float(civ.cfg["panic"])  # Only walking away.
	var cb := g.arena.city_blocks
	if cb != null:
		var inh := cb.in_h_street(e.position)
		var inv := cb.in_v_street(e.position)
		var hx := Vector2(signf(dir.x) if dir.x != 0.0 else 1.0, 0.0)  # Along x, away.
		var vy := Vector2(0.0, signf(dir.y) if dir.y != 0.0 else 1.0)  # Along y, away.
		var tries: Array[Vector2] = []  # The flight's choices, in order (the first clear one is taken).
		if inh and (not inv or absf(dir.x) >= absf(dir.y)):
			tries = [hx, vy, dir]
		elif inv:
			tries = [vy, hx, dir]
		else:
			tries = [dir, hx, vy]
		for d in tries:
			if cb.clear_dir(e.position, d, e.radius):
				dir = d
				break
	var spd := e.move_speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
	if calm:
		spd *= float(civ.cfg["stroll"])
	e.velocity = dir * spd + e.sep * spd * EnemyData.SEPARATION_STRENGTH
	e.position += (e.velocity + e.knockback) * delta
	facing = dir
	e._update_facing()
	return true


func draws_body(_e: Enemy) -> bool:
	return female


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	if not SpriteBank.draw(ci, CityEnemyData.CIVILIAN_WOMAN_SPRITE, Vector2.ZERO, e.flash > 0.0):
		CityGlyphs.draw_enemy(ci, e.kind, Vector2.ZERO, e.radius, e.flash > 0.0)
