## RiflemanKit — the kit of the Rifleman (CityEnemyData "rifleman"; Act VIII,
## GDD §15.0 "Act VIII foundation (phase 1)"): army ranged soldiers in squads
## of 4 (the timeline's events), firing short BURSTS while they advance: each
## shot of the shared ranged attack starts a burst of `burst` rounds,
## burst_gap s apart, each aimed within burst_spread rad of its target
## (fire_ranged() fires the first, physics() the rest; it keeps advancing).
## Determinism: the seeded gameplay RNG.
class_name RiflemanKit
extends CityKit

## Rounds left in the current burst.
var _left: int = 0
## Seconds until the next round of the burst.
var _gap: float = 0.0
## Damage of each round of the current burst (already scaled).
var _dmg: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_left = 0


func fire_ranged(e: Enemy, _t: Node2D, dir: Vector2, dmg: float) -> bool:
	_dmg = dmg
	_left = int(d.get("burst", 3)) - 1
	_gap = float(d.get("burst_gap", 0.12))
	_round(e, dir)
	e.game.stat_add("rifle_bursts", 1.0)
	rules(e).play_sound("gun_burst", e.position, 0.25)
	return true


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	if _left > 0:
		_gap -= delta
		if _gap <= 0.0:
			_left -= 1
			_gap = float(d.get("burst_gap", 0.12))
			var dir := facing
			if e._target_valid():
				var to := e.target.position - e.position
				if to.length() > 1.0:
					dir = to.normalized()
			_round(e, dir)
	return false


## One round of the burst along `dir`, within burst_spread rad.
func _round(e: Enemy, dir: Vector2) -> void:
	var spread := float(d.get("burst_spread", 0.08))
	var a := dir.angle() + randf_range(-spread, spread)
	e.game.projectiles.fire_hostile(e.position, Vector2.from_angle(a), _dmg, e.projectile_speed, e.undead_damage_mult,
			Projectile.Kind.ENEMY_ARROW, e.kind)
