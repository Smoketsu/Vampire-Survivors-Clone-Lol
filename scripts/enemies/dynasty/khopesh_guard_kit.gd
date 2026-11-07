## KhopeshGuardKit — the kit of the KHOPESH GUARD (male; DynastyEnemyData
## "khopesh_guard"; temporary Act XII, the Necropolis Dynasty; GDD §15.0 "The
## Necropolis Dynasty foundation (phase 1)"; owner-approved proposal: "Curved
## blades, a spinning slash; Rebirth | Raise it"). Between his plain cuts (the
## shared melee), every spin "every" s, once a summon or a necromancer stands
## within its radius, he plants his feet for "windup" s (a telegraph circle)
## and SPINS: every summon and every standing necromancer within "radius" px
## takes "damage" (x the time scaling and his own hit multiplier, so a
## returned guard spins harder) through CombatResolver.damage_unit() /
## damage_player(). Rebirth comes from his row ("rebirth"). Determinism: the
## first spin is staggered by the think slot (no RNG). Stats: khopesh_spins,
## khopesh_spin_hits.
class_name KhopeshGuardKit
extends DynastyKit

## Phase: planting his feet before the spin.
const WINDUP: int = 1

## Seconds until the next spin may start.
var _cd: float = 0.0
## Ally query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float((d["spin"] as Dictionary)["every"]) * 0.5)


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var s: Dictionary = d["spin"]
	if phase == WINDUP:
		hold(e)
		phase_time += delta
		if phase_time >= float(s["windup"]):
			_spin(e, s)
			set_phase(e, IDLE)
			_cd = float(s["every"])
		return true
	_cd -= delta
	if _cd <= 0.0 and _body_near(e, float(s["radius"])):
		set_phase(e, WINDUP)
		e.game.effects.telegraph_circle(e.position, float(s["radius"]), float(s["windup"]), e)
		return true
	return false


## True when a summon or a standing necromancer is within `r` px of him.
func _body_near(e: Enemy, r: float) -> bool:
	var g := e.game
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= r + pl.radius:
			return true
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(e.position) <= r + u.radius:
			return true
	return false


## The spin: every body within the radius takes its damage.
func _spin(e: Enemy, s: Dictionary) -> void:
	var g := e.game
	var r := float(s["radius"])
	var dmg := float(s["damage"]) * hit_scale(e)  # Per body.
	var hits := 0
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(e.position) <= r + u.radius:
			g.combat.damage_unit(u, dmg * e.undead_damage_mult, e.kind + "_spin", e)
			hits += 1
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= r + pl.radius:
			g.combat.damage_player(dmg, e.kind + "_spin", pl, e)
			hits += 1
	g.stat_add("khopesh_spins", 1.0)
	g.stat_add("khopesh_spin_hits", float(hits))
	g.effects.ring(e.position, r, Palette.DYN_BRONZE_LIGHT, 0.25)
	if g.dynasty != null:
		g.dynasty.play_sound("khopesh_spin", e.position, 0.2)


func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	var r := float((d["spin"] as Dictionary)["radius"]) + 14.0
	var off := p - e.position
	if off.length() >= r or off.length() < 0.01:
		return Vector2.ZERO
	return off.normalized() * (1.0 - off.length() / r)
