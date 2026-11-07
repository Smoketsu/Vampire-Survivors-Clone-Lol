## ArmouredLimoKit — the kit of BIG SAL'S ARMOURED LIMO (SkidRowEnemyData
## "armoured_limo"; Act VIII, Skid Row; GDD §15.0 "Big Sal and the Armoured
## Limo (Act VIII)"; owner-approved proposal: "an enforcer who rams the ring
## while his crew shoots from the windows"), the first form of Skid Row's
## miniboss. A CityKit VEHICLE: the shared drive owns every tick (it snaps to a
## street lane, drives past the necromancer, turns, rams wrecks; Convoy runs
## over what is in its body box), its row's armour_front cuts the hits on its
## front (Armour, the one path), and dead it leaves a burning wreck
## (Convoy.wreck_vehicle()). Its own:
##   * THE CREW: every crew_every s, for each side of the car (left and right of
##     its drive) the nearest summon or necromancer within crew_range px of
##     that side (and within its length plus crew_range along it) draws a spray
##     of crew_spray bullets out of that side's window (crew_spread rad),
##     tagged limo_spray (a ranged City source: Kevlar Bones). An enemy attack,
##     not a summon rule;
##   * THE MINIBOSS BAR: it registers on the HUD's miniboss bar while it drives
##     (EnemyDirector.set_miniboss(); not is_miniboss itself, so no chest: Big
##     Sal's body carries the chest);
##   * dead, its wreck burns and Big Sal climbs out of it (SkidRowDirector
##     .on_limo_wrecked(), when the director exists; --spawn=armoured_limo
##     elsewhere leaves only the wreck).
## Determinism: the seeded gameplay RNG (the spray's spread); first volley
## staggered by the think slot. Stats: limo_crew_sprays, limo_spawned.
class_name ArmouredLimoKit
extends CityKit

## Seconds until the crew's next volley.
var _crew_cd: float = 0.0
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_crew_cd = first_cd(e, float(d.get("crew_every", 1.6)))
	e.game.enemies.set_miniboss(e)  # The HUD's miniboss bar shows the limo while it drives.
	e.game.stat_add("limo_spawned", 1.0)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


func on_killed(e: Enemy) -> void:
	var at := e.position  # Where it died (the wreck lands on its lane cell).
	super.on_killed(e)  # The burning wreck (Convoy.wreck_vehicle()).
	var sr := e.game.enemies.skid_row  # Skid Row's director (null elsewhere).
	if sr != null:
		sr.on_limo_wrecked(e, at)


func physics(e: Enemy, delta: float) -> bool:
	var owned := super.physics(e, delta)  # The drive owns the tick.
	_crew_cd -= delta
	if _crew_cd <= 0.0 and drive_state == DRIVE:
		if _crew_volley(e):
			_crew_cd = float(d.get("crew_every", 1.6))
		else:
			_crew_cd = 0.3  # Nobody beside it: look again shortly.
	return owned


## One volley from the windows: each side with a target fires a spray. True
## when either side fired.
func _crew_volley(e: Enemy) -> bool:
	var g := e.game
	var reach := float(d.get("crew_range", 210.0))
	var perp := Vector2(-drive_dir.y, drive_dir.x)  # The car's left side (unit).
	var best: Array = [null, null]  # Nearest target on the left / right side.
	var best_d: Array = [INF, INF]
	g.ally_grid.query(e.position, reach + half_length(), _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
			continue
		_consider(e, u, perp, reach, best, best_d)
	for pl in g.all_players:
		if not pl.dead:
			_consider(e, pl, perp, reach, best, best_d)
	var fired := false
	for side in 2:
		var t: Node2D = best[side]
		if t == null:
			continue
		var sgn := 1.0 if side == 0 else -1.0
		var from := e.position + perp * sgn * half_width()  # The side's window.
		var dir := (t.position - from).normalized() if t.position.distance_to(from) > 1.0 else perp * sgn
		var dmg := float(d.get("crew_damage", 1.4)) * hit_scale(e)
		var spread := float(d.get("crew_spread", 0.45))
		for i in int(d.get("crew_spray", 4)):
			var a := dir.angle() + randf_range(-spread, spread)
			g.projectiles.fire_hostile(from, Vector2.from_angle(a), dmg, e.projectile_speed, e.undead_damage_mult,
					Projectile.Kind.ENEMY_ARROW, SkidRowEnemyData.LIMO_SPRAY_SOURCE)
		fired = true
	if fired:
		g.stat_add("limo_crew_sprays", 1.0)
		rules(e).play_sound("gun_burst", e.position, 0.25)
	return fired


## Keeps `t` as the nearest target of its side when it lies beside the car:
## within `reach` px across and the car's length plus `reach` along it.
func _consider(e: Enemy, t: Node2D, perp: Vector2, reach: float, best: Array, best_d: Array) -> void:
	var rel := t.position - e.position
	var across := rel.dot(perp)
	if absf(across) > reach + half_width() or absf(rel.dot(drive_dir)) > half_length() + reach * 0.5:
		return
	var side := 0 if across >= 0.0 else 1
	var dist := absf(across)
	if dist < float(best_d[side]):
		best_d[side] = dist
		best[side] = t
