## CrocodileWardenKit — the kit of the CROCODILE WARDEN (male; DynastyEnemyData
## "crocodile_warden"; temporary Act XII, the Necropolis Dynasty; GDD §15.0 "The
## Hall of Two Truths (Necropolis Dynasty phase 2)"; owner-approved proposal:
## "Heavy | Rises from quicksand; armour 3; drags a summon in | Wither; avoid
## the quicksand"). A crocodile-headed warden of the river of the dead, a
## guardian (Rebirth from his row):
##   * THE RISE: where he is activated a quicksand patch opens (THE call,
##     Quicksand.add_patch(): rise patch_radius px for patch_life s) and he
##     climbs out of it for rise_time s, holding still (a telegraph ring);
##   * THE DRAG: every drag "every" s (first "first"), once a summon stands
##     within drag "reach" px of his body, he seizes the nearest one: a small
##     patch of quicksand opens at his feet (add_patch(), sink_radius px for
##     sink_life s), the summon is held by the shared compel path
##     (SummonedUnit.compel(): it neither thinks nor attacks) and dragged in
##     toward him at drag "speed" px/s (never into an obstacle) for at most
##     drag "hold" s; on arrival (or when the hold ends) it is pulled under:
##     drag "damage" (x the time scaling and his hit multiplier) through
##     CombatResolver.damage_unit(). He stands while he drags. A summon that
##     dies, is charmed or let go ends the drag early.
## Flat armour 3 comes from his row ("flat_armor", the shared stat).
## Determinism: no RNG (the nearest summon, ties in the spatial hash's order).
## Stats: croc_rises, croc_drags, croc_drowned, croc_drag_dmg.
class_name CrocodileWardenKit
extends DynastyKit

## Phase: climbing out of the sand.
const RISING: int = 1
## Phase: dragging a summon in.
const DRAGGING: int = 2

## Seconds until the next drag may start.
var _cd: float = 0.0
## The summon being dragged (null = none).
var _held: SummonedUnit = null
## Its pool generation when seized.
var _held_gen: int = 0
## Ally query buffer.
var _q: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	var r: Dictionary = d["rise"]
	var dr: Dictionary = d["drag"]
	_cd = first_cd(e, float(dr["first"]))
	_held = null
	_held_gen = 0
	rules(e).quicksand.add_patch(e.position, float(r["patch_radius"]), float(r["patch_life"]))
	set_phase(e, RISING)
	e.game.effects.ring(e.position, float(r["patch_radius"]), Palette.DYN_SAND, float(r["rise_time"]))
	e.game.stat_add("croc_rises", 1.0)


func on_deactivate(e: Enemy) -> void:
	_let_go(e)
	super.on_deactivate(e)


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	if phase == RISING:
		hold(e)
		phase_time += delta
		if phase_time >= float((d["rise"] as Dictionary)["rise_time"]):
			set_phase(e, IDLE)
		return true
	var dr: Dictionary = d["drag"]
	if phase == DRAGGING:
		hold(e)
		phase_time += delta
		_step_drag(e, dr, delta)
		return true
	_cd -= delta
	if _cd <= 0.0:
		var u := _nearest(e, float(dr["reach"]))
		if u != null and _seize(e, u, dr):
			return true
	return false


## The nearest summon within `reach` px of his body edge that can be dragged.
func _nearest(e: Enemy, reach: float) -> SummonedUnit:
	var g := e.game
	g.ally_grid.query(e.position, reach + e.radius + UnitData.MAX_BLOCK_RADIUS, _q)
	var best: SummonedUnit = null
	var best_d := INF
	for u: SummonedUnit in _q:
		if not u.active or u.airborne or u.flies or u.charmed or u.is_compelled() or u.state == SummonedUnit.State.SPAWNING:
			continue
		var dd := u.position.distance_to(e.position) - u.radius - e.radius
		if dd <= reach and dd < best_d:
			best_d = dd
			best = u
	return best


## Seizes `u`: the sand opens at his feet and the compel holds it.
func _seize(e: Enemy, u: SummonedUnit, dr: Dictionary) -> bool:
	var g := e.game
	if not u.compel(u.position, g.elapsed + float(dr["hold"]) + 0.1, 0.0):
		return false
	_held = u
	_held_gen = u.generation
	_cd = float(dr["every"])
	set_phase(e, DRAGGING)
	rules(e).quicksand.add_patch(e.position, float(dr["sink_radius"]), float(dr["sink_life"]))
	g.stat_add("croc_drags", 1.0)
	g.effects.ring(e.position, float(dr["sink_radius"]), Palette.DYN_PAPYRUS, 0.4)
	rules(e).play_sound("croc_drag", e.position, 0.3)
	return true


## Drags the held summon in; pulls it under on arrival or when the hold ends.
func _step_drag(e: Enemy, dr: Dictionary, delta: float) -> void:
	var u := _held
	if u == null or not u.active or u.generation != _held_gen or u.charmed or not u.is_compelled():
		_let_go(e)
		set_phase(e, IDLE)
		return
	var side := u.position - e.position
	var dist := side.length()
	var want := e.radius + u.radius + 2.0  # Dragged against his jaws.
	if dist > want:
		var goal := e.position + side / maxf(dist, 0.01) * want
		var to := goal - u.position
		var step := minf(float(dr["speed"]) * delta, to.length())
		if step > 0.0:
			var dir := to / to.length()
			u.position += dir * e.game.arena.clear_length(u.position, dir, step, u.radius * 0.5)
	var arrived := u.position.distance_to(e.position) <= want + 2.0
	if arrived or phase_time >= float(dr["hold"]):
		var dmg := float(dr["damage"]) * hit_scale(e) * e.undead_damage_mult
		e.game.combat.damage_unit(u, dmg, e.kind + "_drag", e)
		e.game.stat_add("croc_drowned", 1.0)
		e.game.stat_add("croc_drag_dmg", dmg)
		e.game.effects.pop(u.position, Palette.DYN_SAND, 14.0)
		_let_go(e)
		set_phase(e, IDLE)


## Lets the held summon go (its compel ends now).
func _let_go(e: Enemy) -> void:
	if _held != null and _held.active and _held.generation == _held_gen:
		_held.compel_until = minf(_held.compel_until, e.game.elapsed)
	_held = null


func is_busy() -> bool:
	return phase != IDLE


## A sand ring while he rises (drawn under the body).
func draw_under(e: Enemy) -> void:
	if phase != RISING:
		return
	unmirror(e)
	var k := clampf(phase_time / maxf(float((d["rise"] as Dictionary)["rise_time"]), 0.01), 0.0, 1.0)
	var r := e.radius * (2.2 - 0.8 * k)
	e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r * 0.45), Vector2(r * 2.0, r * 0.9)), false, Color(Palette.DYN_SAND_DARK, 0.6 * (1.0 - k)))
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
