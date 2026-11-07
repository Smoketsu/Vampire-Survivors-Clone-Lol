## VampireNobleKit — the kit of the Vampire Noble (CourtEnemyData
## "vampire_noble"; Act VII, GDD §15.0 "Act VII foundation (phase 1)";
## owner-approved proposal: "A blood-drain beam at range (a ranged feed); turns
## to mist at low HP, 1.5 s untargetable, and reforms nearer the
## necromancer"): the Countess, the elite in the figure style (female). A
## vampire (row "feeds" 0.5) and a NOBLE (row "noble"):
##   * THE DRAIN BEAM: when it is ready and her target (a summon or the
##     necromancer) is within beam_range px (and not already in claw reach) she
##     stands and drains it for beam_time s: every beam_tick s a hit of
##     beam_damage (time-scaled) through CombatResolver that names her as the
##     attacker, so Bloodfeast feeds her from range (THE ranged feed; no second
##     heal path). The beam breaks if the target dies or leaves 1.3 x the range.
##   * THE MIST: the first time she falls to mist_at of her max HP she turns to
##     mist for mist_time s (x Silver Bones, CourtRules.silver_mist_mult()):
##     untargetable (Enemy.untargetable: out of the enemy grid, so nothing
##     aims at her) and immune (taken_mult() 0), then she reforms up to
##     mist_jump px nearer the necromancer (never within mist_keep px of him,
##     on free ground) and fights on.
## Her claws are the shared melee blow (they feed too). The Silver Bones damage
## hook is CourtKit's. No RNG. Stats: noble_beams, noble_beam_ticks,
## noble_beam_broken, noble_mists, noble_mist_jump_px.
class_name VampireNobleKit
extends CourtKit

## Phase: the drain beam.
const BEAM: int = 1
## Phase: mist form.
const MIST: int = 2
## Beam break distance, x beam_range.
const BEAM_SLACK: float = 1.3  # TUNING (not in GDD)

## True once she used her mist this life.
var misted: bool = false
## Seconds until the next beam may start.
var _beam_cd: float = 0.0
## Seconds until the beam's next tick.
var _tick: float = 0.0
## Pool generation of a summon beam target (stale guard; 0 for a necromancer).
var _beam_gen: int = 0
## The beam's target (null when none).
var _beam_target: Node2D = null


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	misted = false
	_beam_target = null
	_beam_cd = first_cd(e, float(def.get("beam_every", 8.0)) * 0.4)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	_beam_target = null


func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	if phase == MIST:
		phase_time += delta
		hold(e)
		e.queue_redraw()  # The mist drifts.
		if phase_time >= float(d.get("mist_time", 1.5)) * CourtRules.silver_mist_mult(e):
			_reform(e)
			set_phase(e, IDLE)
		return true
	if not misted and e.hp <= e.max_hp * float(d.get("mist_at", 0.35)):
		_mist(e)
		return true
	_beam_cd -= delta
	if phase == BEAM:
		phase_time += delta
		hold(e)
		if not _beam_ok(e):
			g.stat_add("noble_beam_broken", 1.0)
			_end_beam(e)
			return false
		_tick -= delta
		if _tick <= 0.0:
			_tick += float(d.get("beam_tick", 0.25))
			_drain(e)
		e.queue_redraw()  # The beam pulses.
		if phase_time >= float(d.get("beam_time", 1.4)):
			_end_beam(e)
		return true
	if _beam_cd > 0.0 or not e._target_valid():
		return false
	var t := e.target
	var dist := e.position.distance_to(t.position)
	var edge := dist - e.radius - body_radius(e, t)
	if dist > float(d.get("beam_range", 150.0)) or edge <= e.attack_range + 4.0:
		return false
	if t == g.player and g.ultimates.player_untargetable():
		return false
	_beam_target = t
	_beam_gen = (t as SummonedUnit).generation if t is SummonedUnit else 0
	_tick = 0.0
	g.stat_add("noble_beams", 1.0)
	set_phase(e, BEAM)
	hold(e)
	return true


## True while the beam's target lives and stays within reach.
func _beam_ok(e: Enemy) -> bool:
	var t := _beam_target
	if t == null or not is_instance_valid(t):
		return false
	if t is SummonedUnit:
		var u := t as SummonedUnit
		if not u.active or u.generation != _beam_gen or u.state == SummonedUnit.State.DEAD:
			return false
	elif (t as Necromancer).dead:
		return false
	return e.position.distance_to(t.position) <= float(d.get("beam_range", 150.0)) * BEAM_SLACK


## One beam tick: a feeding hit on the target (Bloodfeast hears it through
## CombatResolver, which names her as the attacker).
func _drain(e: Enemy) -> void:
	var g := e.game
	var dmg := float(d.get("beam_damage", 1.6)) * hit_scale(e)
	g.stat_add("noble_beam_ticks", 1.0)
	if _beam_target is SummonedUnit:
		g.combat.damage_unit(_beam_target as SummonedUnit, dmg * e.undead_damage_mult, CourtEnemyData.DRAIN_SOURCE, e)
	else:
		g.combat.damage_player(dmg, CourtEnemyData.DRAIN_SOURCE, _beam_target as Necromancer, e)


## The beam ends (its cooldown starts).
func _end_beam(e: Enemy) -> void:
	_beam_target = null
	_beam_cd = float(d.get("beam_every", 8.0))
	set_phase(e, IDLE)


## She turns to mist: untargetable for mist_time s.
func _mist(e: Enemy) -> void:
	misted = true
	_beam_target = null
	e.untargetable = true
	e.game.stat_add("noble_mists", 1.0)
	e.game.effects.ring(e.position, e.radius * 2.0, Palette.COURT_MOON_LIGHT, 0.35)
	rules(e).play_sound("mist_form", e.position, 0.3)
	set_phase(e, MIST)
	hold(e)


## She reforms up to mist_jump px nearer the necromancer (never within
## mist_keep px of him), on free ground.
func _reform(e: Enemy) -> void:
	var g := e.game
	var to := g.player.position - e.position
	var dist := to.length()
	var jump := minf(float(d.get("mist_jump", 120.0)), maxf(0.0, dist - float(d.get("mist_keep", 40.0))))
	var from := e.position
	if dist > 0.01 and jump > 0.0:
		e.position = g.arena.free_point(e.position + to / dist * jump, e.radius)
	g.stat_add("noble_mist_jump_px", from.distance_to(e.position))
	e.untargetable = false
	g.effects.ring(e.position, e.radius * 2.0, Palette.COURT_BLOOD_LIGHT, 0.35)


## In mist she takes nothing; otherwise CourtKit's rule (Silver Bones).
func taken_mult(e: Enemy, source: String) -> float:
	if phase == MIST:
		return 0.0
	return super.taken_mult(e, source)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: none (the beam is not dodged by stepping).
func danger_push(_e: Enemy, _p: Vector2) -> Vector2:
	return Vector2.ZERO


## In mist she is drawn as drifting mist, not her sprite.
func draws_body(_e: Enemy) -> bool:
	return phase == MIST


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	CourtGlyphs.draw_mist(ci, e.radius, e.game.elapsed)


## The drain beam to her target, then CourtKit's shield ring. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase == BEAM and _beam_target != null and is_instance_valid(_beam_target):
		var xf := CourtGlyphs.unmirror_xf(e)  # World axes from her centre.
		var pulse := 0.6 + 0.4 * sin(e.game.elapsed * 18.0)
		CourtGlyphs.draw_thread(ci, Vector2.ZERO, _beam_target.position - e.position, 5.0, Color(Palette.COURT_BLOOD, 0.75 * pulse), xf)
		CourtGlyphs.draw_thread(ci, Vector2.ZERO, _beam_target.position - e.position, 2.0, Color(Palette.COURT_BLOOD_LIGHT, 0.95), xf)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	super.draw_over(e, ci)
