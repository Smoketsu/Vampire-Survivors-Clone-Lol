## ShieldMaidenKit — the kit of the Shield-Maiden (NorseEnemyData
## "shield_maiden"; the Hall of the Slain, temporarily Act XI; GDD §15.0 "The
## Hall of the Slain foundation (phase 1)"; owner-approved proposal:
## "Shield-Maiden (female, figure style) | Soldier | Spear and shield; a shield
## bash that knocks one summon back | Flank her; Rogues"). A WARRIOR
## (Berserkergang). THE SHIELD BASH: every bash_every s, when her target
## is a summon within bash_range px of her edge, she draws her shield back for
## bash_windup s (standing), then slams it: that one summon takes bash_damage
## (x undead_damage_mult, BASH_SOURCE) and is thrown bash_push px straight back
## (clear of obstacles: Arena.clear_length()). No RNG. Stats: maiden_bashes,
## maiden_bash_hits.
class_name ShieldMaidenKit
extends NorseKit

## Phase: the shield drawn back (the windup).
const WINDUP: int = 1

## Seconds until the next bash may start.
var _cd: float = 0.0
## The summon she bashes (locked at the windup).
var _victim: SummonedUnit = null
## Generation of `_victim` when locked (stale guard).
var _victim_gen: int = 0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("bash_every", 6.0)) * 0.5)
	_victim = null


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	_cd -= delta
	if phase == WINDUP:
		phase_time += delta
		hold(e)
		if phase_time >= float(d.get("bash_windup", 0.45)):
			_bash(e)
			set_phase(e, IDLE)
		return true
	if _cd > 0.0 or not (e.target is SummonedUnit):
		return false
	var u := e.target as SummonedUnit
	if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
		return false
	if e.position.distance_to(u.position) - e.radius - u.radius > float(d.get("bash_range", 22.0)):
		return false
	_cd = float(d.get("bash_every", 6.0))
	_victim = u
	_victim_gen = u.generation
	e.game.stat_add("maiden_bashes", 1.0)
	set_phase(e, WINDUP)
	hold(e)
	return true


## The slam: the locked summon takes the blow and is thrown back.
func _bash(e: Enemy) -> void:
	var u := _victim
	_victim = null
	if u == null or not u.active or u.generation != _victim_gen or u.state == SummonedUnit.State.DEAD:
		return
	var g := e.game
	if e.position.distance_to(u.position) - e.radius - u.radius > float(d.get("bash_range", 22.0)) * 1.5:
		return  # It got away during the windup.
	var away := (u.position - e.position).normalized() if u.position.distance_squared_to(e.position) > 1.0 else Vector2.RIGHT
	g.effects.slash(u.position, away, Palette.NORSE_IRON, e.radius * 1.4)
	g.combat.damage_unit(u, float(d.get("bash_damage", 4.0)) * hit_scale(e) * e.undead_damage_mult, NorseRulesData.BASH_SOURCE, e)
	g.stat_add("maiden_bash_hits", 1.0)
	if g.norse != null:
		g.norse.play_sound("maiden_bash", u.position, 0.4)
	if u.active and u.state != SummonedUnit.State.DEAD and not u.airborne:
		u.position += away * g.arena.clear_length(u.position, away, float(d.get("bash_push", 46.0)), u.radius)
