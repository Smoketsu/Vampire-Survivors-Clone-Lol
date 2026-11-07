## OniKit — the kit of the Oni (ShogunateEnemyData "oni"; Act V, GDD §15.0 "Act
## V foundation (phase 1)"): the night heavy and the Endless Night's Reckoning
## kind. NIGHT. Its KANABŌ SMASH: when a summon or the necromancer comes within
## its row's smash_trigger px (edge to edge) and the smash is ready, it raises
## the iron club for smash_windup s (a telegraph circle of smash_radius px on
## the ground, which the autotest bot steps out of), then slams: every summon in
## the circle takes smash_damage and is STUNNED for smash_stun s through
## CombatResolver.stun_unit() (the one summon stun path), the necromancer takes
## the blow (no stun). Flat armour is its row's flat_armor (the shared path in
## CombatResolver.damage_enemy()). No RNG.
class_name OniKit
extends ShogunateKit

## Phase: the club is raised (the windup).
const WINDUP: int = 1
## px of reach the autotest bot keeps from the slam beyond its radius.
const DANGER_REACH: float = 16.0  # TUNING (not in GDD) autotest hint only

## Seconds until the next smash may start.
var _cd: float = 0.0
## World px where the raised club will land.
var _at: Vector2 = Vector2.ZERO
## Bodies in the slam (scratch).
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("smash_every", 5.0)) * 0.4)


func physics(e: Enemy, delta: float) -> bool:
	_cd -= delta
	if phase == WINDUP:
		phase_time += delta
		hold(e)
		if phase_time >= float(d.get("smash_windup", 0.8)):
			_slam(e)
			set_phase(e, IDLE)
		return true
	if _cd > 0.0:
		return false
	var t: Node2D = e.target if e.target != null and is_instance_valid(e.target) else e.game.player
	var edge := e.position.distance_to(t.position) - e.radius - body_radius(e, t)
	if edge > float(d.get("smash_trigger", 30.0)):
		return false
	_cd = float(d.get("smash_every", 5.0))
	var dir := (t.position - e.position).normalized() if e.position.distance_squared_to(t.position) > 1.0 else Vector2.RIGHT
	_at = e.position + dir * e.radius * 0.8
	e.game.effects.telegraph_circle(_at, float(d.get("smash_radius", 50.0)), float(d.get("smash_windup", 0.8)), e)
	set_phase(e, WINDUP)
	hold(e)
	return true


## The slam: damage and stun every summon in the circle, hit the necromancer.
func _slam(e: Enemy) -> void:
	var g := e.game
	var r := float(d.get("smash_radius", 50.0))
	var dmg := float(d.get("smash_damage", 15.0)) * g.enemies.damage_mult * e.hit_mult()
	g.stat_add("oni_smashes", 1.0)
	g.effects.impact(_at, r, Palette.SHOGUN_LACQUER)
	g.shake(3.0)
	rules(e).play_sound("oni_smash", _at)
	for pl in g.all_players:
		if pl.position.distance_to(_at) <= r + pl.radius:
			g.combat.damage_player(dmg, e.kind, pl)
	g.ally_grid.query(_at, r + PantheonRulesData.SUMMON_SLACK, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.DEAD or u.position.distance_to(_at) > r + u.radius:
			continue
		g.combat.damage_unit(u, dmg * e.undead_damage_mult, e.kind, e)
		if u.active and u.state != SummonedUnit.State.DEAD and g.combat.stun_unit(u, float(d.get("smash_stun", 1.0)), "oni_smash") > 0.0:
			g.stat_add("oni_stuns", 1.0)


func is_busy() -> bool:
	return phase == WINDUP


## Autopilot hint: away from the raised club's circle.
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	var reach := float(d.get("smash_radius", 50.0)) + DANGER_REACH
	var off := p - _at
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.0
