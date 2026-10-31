## HellKnightKit — the kit of the Hell Knight (InfernoEnemyData "hell_knight";
## Act VI, GDD §15.0 "Act VI foundation (phase 1)"): the soldier, obsidian
## armour with ember cracks (flat armour: its row's flat_armor, the shared path
## in CombatResolver.damage_enemy()) and a burning greatsword. A DEMON (the
## pits spare it). Its SWEEP: when a summon or the necromancer comes within
## sweep_reach px (edge to edge) and the sweep is ready, it raises the blade for
## sweep_windup s (the shared telegraph cone, which the autotest bot steps out
## of), then cuts everything in the cone in front of it: every summon and the
## necromancer take sweep_damage. No RNG.
class_name HellKnightKit
extends InfernoKit

## Phase: the blade is raised (the windup).
const WINDUP: int = 1
## px of reach the autotest bot keeps from the cone beyond its reach.
const DANGER_REACH: float = 14.0  # TUNING (not in GDD) autotest hint only

## Seconds until the next sweep may start.
var _cd: float = 0.0
## Unit direction of the raised sweep.
var _dir: Vector2 = Vector2.RIGHT
## Bodies in the sweep (scratch).
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("sweep_every", 5.5)) * 0.5)


func physics(e: Enemy, delta: float) -> bool:
	_cd -= delta
	if phase == WINDUP:
		phase_time += delta
		hold(e)
		if phase_time >= float(d.get("sweep_windup", 0.55)):
			_sweep(e)
			set_phase(e, IDLE)
		return true
	if _cd > 0.0:
		return false
	var t: Node2D = e.target if e.target != null and is_instance_valid(e.target) else e.game.player
	var edge := e.position.distance_to(t.position) - e.radius - body_radius(e, t)
	if edge > float(d.get("sweep_reach", 30.0)):
		return false
	_cd = float(d.get("sweep_every", 5.5))
	_dir = (t.position - e.position).normalized() if e.position.distance_squared_to(t.position) > 1.0 else Vector2.RIGHT
	e.game.effects.telegraph_cone(e.position, _dir, e.radius + float(d.get("sweep_reach", 30.0)),
			deg_to_rad(float(d.get("sweep_arc", 65.0))), float(d.get("sweep_windup", 0.55)), e)
	set_phase(e, WINDUP)
	hold(e)
	return true


## The sweep: every summon and the necromancer in the cone take its damage.
func _sweep(e: Enemy) -> void:
	var g := e.game
	var reach := e.radius + float(d.get("sweep_reach", 30.0))
	var half := deg_to_rad(float(d.get("sweep_arc", 65.0)))
	var dmg := float(d.get("sweep_damage", 8.0)) * hit_scale(e)
	g.stat_add("hell_knight_sweeps", 1.0)
	e.motion_lunge(_dir, MotionData.POWER_MELEE)
	for pl in g.all_players:
		if not pl.dead and in_sector(e.position, _dir, reach, half, e.radius, pl.position, pl.radius):
			g.combat.damage_player(dmg, e.kind, pl)
	g.ally_grid.query(e.position, reach + PantheonRulesData.SUMMON_SLACK, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.DEAD:
			continue
		if in_sector(e.position, _dir, reach, half, e.radius, u.position, u.radius):
			g.combat.damage_unit(u, dmg * e.undead_damage_mult, e.kind, e)
			g.stat_add("hell_knight_sweep_hits", 1.0)


func is_busy() -> bool:
	return phase == WINDUP


## Autopilot hint: out of the raised blade's cone.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	var reach := e.radius + float(d.get("sweep_reach", 30.0)) + DANGER_REACH
	var off := p - e.position
	var dist := off.length()
	if dist >= reach or absf(_dir.angle_to(off)) > deg_to_rad(float(d.get("sweep_arc", 65.0))) + 0.3:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else _dir) * (1.0 - dist / reach) * 2.0
