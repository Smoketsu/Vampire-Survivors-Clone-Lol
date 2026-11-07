## SuccubusKit — the kit of the Succubus (InfernoEnemyData "succubus"; Act VI,
## GDD §15.0 "Act VI foundation (phase 1)" and "Temptation"): the elite in the
## approved Act VI figure style, bat wings, horns, a tail. A DEMON, a FLIER
## (over the pits and obstacles) and a CHARMER. Her KISS: when the kiss is
## ready, Temptation has room (fewer than max_charmed held) and a summon stands
## within kiss_range px, she blows it a kiss for kiss_windup s (a pink line of
## hearts from her to it, drawn on her overlay; she hovers in place), then, if
## the summon is still there and in reach, charms it for kiss_duration s
## through HordeDirector.charm() (the one path; Faithless shortens it there).
## Killing her breaks her charms (InfernoKit.on_killed()). The target is the
## nearest summon in reach (the ally grid's fixed order breaks ties). No RNG.
class_name SuccubusKit
extends InfernoKit

## Phase: the kiss is blown (the windup).
const KISS: int = 1
## The kiss lands if the summon is still within this x kiss_range.
const KISS_HOLD: float = 1.4  # TUNING (not in GDD)

## Seconds until the next kiss may start.
var _cd: float = 0.0
## The summon the kiss is blown at.
var _target: SummonedUnit = null
## Its generation when the kiss began (stale guard).
var _target_gen: int = 0
## Summons in reach (scratch).
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("kiss_every", 9.0)) * 0.5)
	_target = null


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	_target = null


func physics(e: Enemy, delta: float) -> bool:
	_cd -= delta
	if phase == KISS:
		phase_time += delta
		hold(e)
		if phase_time >= float(d.get("kiss_windup", 0.7)):
			_land(e)
			set_phase(e, IDLE)
		elif phase_time > 0.0 and int(phase_time * 20.0) != int((phase_time - delta) * 20.0):
			e.queue_redraw()  # The hearts travel along the kiss.
		return true
	if _cd > 0.0:
		return false
	var g := e.game
	if g.inferno != null and g.inferno.temptation.charmed_now() >= int(InfernoRulesData.TEMPTATION["max_charmed"]):
		_cd = 1.0  # Temptation is full: look again in a second.
		return false
	var u := _nearest_summon(e)
	if u == null:
		_cd = 0.5
		return false
	_cd = float(d.get("kiss_every", 9.0))
	_target = u
	_target_gen = u.generation
	g.stat_add("succubus_kisses", 1.0)
	set_phase(e, KISS)
	hold(e)
	return true


## The nearest summon within kiss_range that can be charmed, or null.
func _nearest_summon(e: Enemy) -> SummonedUnit:
	var reach := float(d.get("kiss_range", 170.0))
	e.game.ally_grid.query(e.position, reach, _tmp)
	var best: SummonedUnit = null
	var best_d := reach
	for u: SummonedUnit in _tmp:
		if not u.active or u.charmed or u.airborne or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING:
			continue
		var dist := e.position.distance_to(u.position)
		if dist < best_d:
			best = u
			best_d = dist
	return best


## The kiss lands: the summon is charmed if it is still there and in reach.
func _land(e: Enemy) -> void:
	var u := _target
	_target = null
	if u == null or not u.active or u.generation != _target_gen or u.charmed:
		e.game.stat_add("succubus_kiss_missed", 1.0)
		return
	if e.position.distance_to(u.position) > float(d.get("kiss_range", 170.0)) * KISS_HOLD:
		e.game.stat_add("succubus_kiss_missed", 1.0)
		return
	if not try_charm(e, u, float(d.get("kiss_duration", 6.0))):
		e.game.stat_add("succubus_kiss_missed", 1.0)


func is_busy() -> bool:
	return phase == KISS


## The blown kiss: a pink line to the summon with hearts travelling along it.
## Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != KISS or _target == null or not _target.active:
		return
	unmirror(e, ci)
	var to := _target.position - e.position  # The summon, from her centre (px).
	var k := clampf(phase_time / maxf(float(d.get("kiss_windup", 0.7)), 0.01), 0.0, 1.0)
	ci.draw_line(Vector2.ZERO, to, Color(Palette.INFERNO_CHARM, 0.25 + 0.35 * k), 1.0)
	for i in 3:
		var f := fmod(k + float(i) / 3.0, 1.0)  # Position of this heart along the kiss.
		InfernoGlyphs.draw_heart(ci, to * f + Vector2(0.0, -4.0), 4.0 + 2.0 * k, Color(Palette.INFERNO_CHARM, 0.9))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
