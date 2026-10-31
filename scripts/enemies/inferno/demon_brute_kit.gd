## DemonBruteKit — the kit of the Demon Brute (InfernoEnemyData "demon_brute";
## Act VI, GDD §15.0 "Act VI foundation (phase 1)"): the heavy, four arms, demon
## skin, horns; also the Last Judgment's heavy (the Act VI stages' RECKONING
## "kind"). A DEMON (the pits spare it). Flat armour is its row's flat_armor
## (the shared path in CombatResolver.damage_enemy()). Its SLAM: when a summon
## or the necromancer comes within slam_trigger px (edge to edge) and the slam
## is ready, it raises all four fists for slam_windup s (the shared telegraph
## circle of slam_radius px, which the autotest bot steps out of), then slams:
## every summon in the circle takes slam_damage and is thrown slam_push px back
## (never into an obstacle), the necromancer takes the blow. No RNG.
class_name DemonBruteKit
extends InfernoKit

## Phase: the fists are raised (the windup).
const WINDUP: int = 1
## px of reach the autotest bot keeps from the slam beyond its radius.
const DANGER_REACH: float = 16.0  # TUNING (not in GDD) autotest hint only

## Seconds until the next slam may start.
var _cd: float = 0.0
## World px where the slam lands.
var _at: Vector2 = Vector2.ZERO
## Bodies in the slam (scratch).
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("slam_every", 6.0)) * 0.4)


func physics(e: Enemy, delta: float) -> bool:
	_cd -= delta
	if phase == WINDUP:
		phase_time += delta
		hold(e)
		if phase_time >= float(d.get("slam_windup", 0.9)):
			_slam(e)
			set_phase(e, IDLE)
		return true
	if _cd > 0.0:
		return false
	var t: Node2D = e.target if e.target != null and is_instance_valid(e.target) else e.game.player
	var edge := e.position.distance_to(t.position) - e.radius - body_radius(e, t)
	if edge > float(d.get("slam_trigger", 34.0)):
		return false
	_cd = float(d.get("slam_every", 6.0))
	var dir := (t.position - e.position).normalized() if e.position.distance_squared_to(t.position) > 1.0 else Vector2.RIGHT
	_at = e.position + dir * e.radius * 0.8
	e.game.effects.telegraph_circle(_at, float(d.get("slam_radius", 46.0)), float(d.get("slam_windup", 0.9)), e)
	set_phase(e, WINDUP)
	hold(e)
	return true


## The slam: damage and throw back every summon in the circle, hit the necromancer.
func _slam(e: Enemy) -> void:
	var g := e.game
	var r := float(d.get("slam_radius", 46.0))
	var dmg := float(d.get("slam_damage", 10.0)) * hit_scale(e)
	var push := float(d.get("slam_push", 26.0))
	g.stat_add("brute_slams", 1.0)
	g.effects.impact(_at, r, Palette.INFERNO_LAVA)
	g.shake(3.0)
	rules(e).play_sound("brute_slam", _at)
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(_at) <= r + pl.radius:
			g.combat.damage_player(dmg, e.kind, pl)
	g.ally_grid.query(_at, r + PantheonRulesData.SUMMON_SLACK, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.DEAD or u.position.distance_to(_at) > r + u.radius:
			continue
		g.combat.damage_unit(u, dmg * e.undead_damage_mult, e.kind, e)
		g.stat_add("brute_slam_hits", 1.0)
		if u.active and u.state != SummonedUnit.State.DEAD and push > 0.0:
			var away := (u.position - _at).normalized() if u.position.distance_squared_to(_at) > 1.0 else Vector2.RIGHT
			u.position += away * g.arena.clear_length(u.position, away, push, u.radius)


func is_busy() -> bool:
	return phase == WINDUP


## Autopilot hint: away from the raised fists' circle.
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	var reach := float(d.get("slam_radius", 46.0)) + DANGER_REACH
	var off := p - _at
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.0
