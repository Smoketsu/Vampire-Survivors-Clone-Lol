## WolfOfTheWastesKit — the kit of the Wolf of the Wastes (NorseEnemyData
## "wolf_of_the_wastes"; the Hall of the Slain, temporarily Act XI; GDD §15.0
## "The Hall of the Slain foundation (phase 1)"; owner-approved proposal: "Wolf
## of the Wastes | Fodder pack | Packs of 5 that lunge | Blockers"). A beast, no
## warrior. THE LUNGE: every lunge_every s, when its target (a summon or the
## necromancer) is within lunge_range px of its edge, it crouches for
## lunge_windup s, then leaps along the locked line for lunge_time s (stopped
## by obstacles: Arena.clear_length()); the first body it meets takes
## lunge_damage (LUNGE_SOURCE; x undead_damage_mult on a summon). No RNG.
## Stats: wolf_lunges, wolf_lunge_hits.
class_name WolfOfTheWastesKit
extends NorseKit

## Phase: crouched (the windup).
const CROUCH: int = 1
## Phase: in the air.
const LEAP: int = 2

## Seconds until the next lunge may start.
var _cd: float = 0.0
## Unit direction of the leap (locked at the crouch).
var _dir: Vector2 = Vector2.RIGHT
## px/s of the leap.
var _speed: float = 0.0
## True once the leap struck a body (one bite a leap).
var _hit: bool = false
## Scratch for the grid query.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("lunge_every", 4.0)) * 0.5)


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	_cd -= delta
	match phase:
		CROUCH:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("lunge_windup", 0.35)):
				set_phase(e, LEAP)
			return true
		LEAP:
			phase_time += delta
			e.velocity = _dir * _speed
			e.position += e.velocity * delta
			if not _hit:
				_bite(e)
			if phase_time >= float(d.get("lunge_time", 0.22)) or _hit:
				set_phase(e, IDLE)
				e.velocity = Vector2.ZERO
			return true
	if _cd > 0.0:
		return false
	var t: Node2D = e.target if e.target != null and is_instance_valid(e.target) else e.game.player
	var to := t.position - e.position
	var gap := to.length() - e.radius - body_radius(e, t)
	if gap > float(d.get("lunge_range", 90.0)) or gap < 6.0:
		return false
	_cd = float(d.get("lunge_every", 4.0))
	_dir = to.normalized()
	var reach := e.game.arena.clear_length(e.position, _dir, gap + e.radius, e.radius * 0.8)
	_speed = reach / maxf(float(d.get("lunge_time", 0.22)), 0.01)
	_hit = false
	e.game.stat_add("wolf_lunges", 1.0)
	set_phase(e, CROUCH)
	hold(e)
	return true


## The leap meets the first body in its way.
func _bite(e: Enemy) -> void:
	var g := e.game
	var dmg := float(d.get("lunge_damage", 4.0)) * hit_scale(e)
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= e.radius + pl.radius + 2.0:
			g.combat.damage_player(dmg, NorseRulesData.LUNGE_SOURCE, pl, e)
			_hit = true
			break
	if not _hit:
		g.ally_grid.query(e.position, e.radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
		for u: SummonedUnit in _tmp:
			if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne or u.state == SummonedUnit.State.SPAWNING:
				continue
			if u.position.distance_to(e.position) <= e.radius + u.radius + 2.0:
				g.combat.damage_unit(u, dmg * e.undead_damage_mult, NorseRulesData.LUNGE_SOURCE, e)
				_hit = true
				break
	if _hit:
		g.stat_add("wolf_lunge_hits", 1.0)
		if g.norse != null:
			g.norse.play_sound("wolf_lunge", e.position, 0.6)
