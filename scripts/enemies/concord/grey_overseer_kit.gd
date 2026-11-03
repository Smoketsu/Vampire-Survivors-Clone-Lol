## GreyOverseerKit — the kit of the Grey Overseer (ConcordEnemyData
## "grey_overseer"; Act IX, the Harvesters; GDD §15.0 "The Ark of the Concord
## (Act IX phase 2)"; owner-approved proposal: "Grey Overseer | Harvester |
## Support | A psionic pulse that stuns summons for 1 s; shields greys near it
## | Priority target"). A tall grey (sex unmarked, as the greys are) in a
## gunmetal mantle with a plasma crown. It hangs back with the drones and:
##   * THE PSIONIC PULSE: every pulse_every s, when a summon stands within
##     pulse_radius px, it stops and a psionic ring widens over pulse_windup s
##     (the telegraph, drawn as a texture); then every summon within
##     pulse_radius px is stunned pulse_stun s through
##     CombatResolver.stun_unit() (THE summon stun path: an enemy effect on a
##     unit, never a summon rule; Oni's Resolve shortens it as every stun).
##   * THE SHIELD: every shield_every s it shields up to shield_targets greys
##     (race "harvesters", not structures, itself included) within
##     shield_radius px, nearest first: an Enemy.holy_shield of shield_share x
##     each one's max HP for shield_time s (the existing shield path; a larger
##     shield already on it is kept).
## Determinism: no RNG (the spatial hash's order, the nearest first). Stats:
## overseer_pulses, overseer_pulse_stuns, overseer_shields.
class_name GreyOverseerKit
extends ConcordKit

## Phase: the psionic ring widens.
const PULSE: int = 1

## Seconds until it may pulse again.
var pulse_cd: float = 0.0
## Seconds until it shields again.
var shield_cd: float = 0.0
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	pulse_cd = first_cd(e, float(d.get("pulse_first", 3.0)))
	shield_cd = first_cd(e, float(d.get("shield_first", 1.5)))


## Per tick: the pulse's windup owns the tick; the shield is cast on the move.
func physics(e: Enemy, delta: float) -> bool:
	if super.physics(e, delta):
		return true
	var g := e.game
	shield_cd -= delta
	if shield_cd <= 0.0:
		shield_cd = float(d.get("shield_every", 6.0))
		_shield(e)
	if phase == PULSE:
		phase_time += delta
		hold(e)
		e.queue_redraw()  # The ring widens.
		if phase_time >= float(d.get("pulse_windup", 0.8)):
			_pulse(e)
			set_phase(e, IDLE)
		return true
	pulse_cd -= delta
	if pulse_cd <= 0.0:
		var r := float(d.get("pulse_radius", 90.0))
		g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
		var any := false
		for u: SummonedUnit in _buf:
			if u.active and u.state != SummonedUnit.State.DEAD and not u.airborne and u.position.distance_to(e.position) <= r + u.radius:
				any = true
				break
		if any:
			pulse_cd = float(d.get("pulse_every", 7.0))
			set_phase(e, PULSE)
			hold(e)
			rules(e).play_sound("beam_charge", e.position, 0.4)
			return true
		pulse_cd = float(ConcordRulesData.BEAMS["retry"])
	return false


## The pulse lands: every summon in reach is stunned (THE summon stun path).
func _pulse(e: Enemy) -> void:
	var g := e.game
	var r := float(d.get("pulse_radius", 90.0))
	var n := 0
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
			continue
		if u.position.distance_to(e.position) > r + u.radius:
			continue
		if g.combat.stun_unit(u, float(d.get("pulse_stun", 1.0)), ConcordEnemyData.PULSE_SOURCE) > 0.0:
			n += 1
	g.stat_add("overseer_pulses", 1.0)
	g.stat_add("overseer_pulse_stuns", float(n))
	g.effects.ring(e.position, r, Palette.CONCORD_PLASMA, 0.3)


## The shield: the nearest greys (itself included) get a holy shield.
func _shield(e: Enemy) -> void:
	var g := e.game
	var r := float(d.get("shield_radius", 120.0))
	g.enemy_grid.query(e.position, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var picked: Array[Enemy] = []
	var dists: Array[float] = []
	for o: Enemy in _buf:
		if not o.active or o.is_structure or o.is_boss or not (o.kit is ConcordKit):
			continue
		if (o.kit as ConcordKit).race() != "harvesters":
			continue
		var dist := o.position.distance_to(e.position)
		if dist > r:
			continue
		var at := 0  # Insertion index (nearest first, stable).
		while at < dists.size() and dists[at] <= dist:
			at += 1
		picked.insert(at, o)
		dists.insert(at, dist)
	var n := mini(picked.size(), int(d.get("shield_targets", 6)))
	for i in n:
		var o := picked[i]
		var amount := o.max_hp * float(d.get("shield_share", 0.35))
		if o.holy_shield >= amount:
			continue
		o.holy_shield = amount
		o.holy_shield_time = float(d.get("shield_time", 5.0))
		o.queue_redraw()
		g.stat_add("overseer_shields", 1.0)
		if o != e:
			g.effects.beam(e.position, o.position, Palette.CONCORD_PLASMA)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: nothing (the pulse stuns summons only).
func danger_push(_e: Enemy, _p: Vector2) -> Vector2:
	return Vector2.ZERO


## The psionic ring widening during the windup (a texture: the soft disc).
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	if phase != PULSE:
		return
	var k := clampf(phase_time / maxf(float(d.get("pulse_windup", 0.8)), 0.01), 0.0, 1.0)
	var r := float(d.get("pulse_radius", 90.0)) * k
	unmirror(e)
	e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r * 0.6), Vector2(r * 2.0, r * 1.2)), false, Color(Palette.CONCORD_PLASMA, 0.12 + 0.18 * k))
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Its crown glows while the pulse gathers.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var a := 0.3 + 0.25 * sin(e.game.elapsed * 3.0 + float(e.think_slot))
	if phase == PULSE:
		a = 0.9
	SpriteBank.draw_disc(ci, Vector2(0.0, -e.radius * 2.2), e.radius * 0.35, Color(Palette.CONCORD_PLASMA, a))
