## JackalWarriorKit — the kit of the JACKAL WARRIOR (male, jackal-headed;
## DynastyEnemyData "jackal_warrior"; temporary Act XII, the Necropolis
## Dynasty; GDD §15.0 "The Necropolis of Sand (Act XII phase 2)";
## owner-approved proposal: "Fast lunge; Rebirth; pack of two | Blockers;
## raise it"). An elite (row "always_elite": its numbers are final) that
## comes in pairs (the stage timeline) and RETURNS (row "rebirth", Rebirth).
## Between its spear thrusts (the shared melee) THE LUNGE (the Werewolf's
## model, without the turning): when its target is between the row's lunge
## "min" and "trigger" px away (edge to edge) and the lunge is ready, it
## crouches "windup" s (a bronze line on the ground to where it will land;
## the autotest bot steps off it), leaps there in "time" s over the bodies in
## between (the leap is a position lerp: no body-block stops it) and strikes
## its target for "damage" (x the time scaling and its own hit multiplier, so
## a returned jackal lunges harder) through damage_unit() / damage_player()
## when it is still within reach. Every "every" s. Determinism: no RNG (the
## first lunge is staggered by the think slot). Stats: jackal_lunges,
## jackal_lunge_hits; damage as DynastyEnemyData.LUNGE_SOURCE.
class_name JackalWarriorKit
extends DynastyKit

## Phase: it crouches before the leap.
const CROUCH: int = 1
## Phase: the leap.
const LEAP: int = 2
## px of reach the autotest bot keeps from the landing point beyond the body.
const DANGER_REACH: float = 16.0  # TUNING (not in GDD) autotest hint only

## Seconds until the next lunge may start.
var _cd: float = 0.0
## Where the leap starts (world px).
var _from: Vector2 = Vector2.ZERO
## Where the leap lands (world px; locked when it crouches).
var _to: Vector2 = Vector2.ZERO


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float((d["lunge"] as Dictionary)["every"]) * 0.5)


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var l: Dictionary = d["lunge"]
	_cd -= delta
	match phase:
		CROUCH:
			phase_time += delta
			hold(e)
			if phase_time >= float(l["windup"]):
				_from = e.position
				set_phase(e, LEAP)
			return true
		LEAP:
			phase_time += delta
			var k := clampf(phase_time / maxf(0.01, float(l["time"])), 0.0, 1.0)  # 0 -> 1 to the mark.
			e.position = _from.lerp(_to, k)
			e.velocity = Vector2.ZERO
			if k >= 1.0:
				_land(e, l)
				set_phase(e, IDLE)
			return true
	if _cd > 0.0 or not e._target_valid() or e.stun_timer > 0.0:
		return false
	var t := e.target
	var to := t.position - e.position
	var dist := to.length()
	var edge := dist - e.radius - body_radius(e, t)
	if edge < float(l["min"]) or edge > float(l["trigger"]) or dist < 0.01:
		return false
	if t is Necromancer and e.game.ultimates.player_untargetable():
		return false
	_cd = float(l["every"])
	_to = e.game.arena.free_point(t.position - to / dist * (e.radius + body_radius(e, t)), e.radius)
	e.game.stat_add("jackal_lunges", 1.0)
	e.game.effects.telegraph_line(e.position, _to, e.radius * 1.6, float(l["windup"]), e)
	set_phase(e, CROUCH)
	hold(e)
	return true


## The leap lands: the strike on its target if it is still within reach.
func _land(e: Enemy, l: Dictionary) -> void:
	var g := e.game
	if not e._target_valid():
		return
	var t := e.target
	var edge := e.position.distance_to(t.position) - e.radius - body_radius(e, t)
	if edge > e.attack_range + 10.0:
		return
	var dmg := float(l["damage"]) * hit_scale(e)
	g.stat_add("jackal_lunge_hits", 1.0)
	g.effects.slash(e.position, t.position - e.position, Palette.DYN_BRONZE_LIGHT, e.radius * 1.4)
	if t is SummonedUnit:
		g.combat.damage_unit(t as SummonedUnit, dmg * e.undead_damage_mult, DynastyEnemyData.LUNGE_SOURCE, e)
	else:
		g.combat.damage_player(dmg, DynastyEnemyData.LUNGE_SOURCE, t as Necromancer, e)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: off the landing point while it crouches and leaps.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != CROUCH and phase != LEAP:
		return Vector2.ZERO
	var reach := e.radius + DANGER_REACH
	var off := p - _to
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.0
