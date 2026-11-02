## SwatBreacherKit — the kit of the SWAT Breacher (CityEnemyData
## "swat_breacher"; Act VIII, GDD §15.0 "Act VIII foundation (phase 1)";
## owner-approved proposal: "flashbangs that stun summons in a circle for 1 s;
## a shotgun. Kill first"): a SWAT soldier.
##   * THE SHOTGUN: each shot of the shared ranged attack (close range) is a
##     spread of `pellets` pellets within pellet_spread rad (fire_ranged()).
##   * THE FLASHBANG: every flash_every s, with a summon within flash_range px,
##     it lobs one onto that summon: a landing circle (CityShells, the one shell
##     path) that after flash_windup s stuns every summon within flash_radius px
##     for flash_stun s (CombatResolver.stun_unit(), the one summon stun path:
##     an enemy attack, not a summon rule). No damage.
## Determinism: the seeded gameplay RNG (pellet spread); first flash staggered
## by the think slot.
class_name SwatBreacherKit
extends CityKit

## Seconds until its next flashbang may be thrown.
var _flash_cd: float = 0.0
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_flash_cd = first_cd(e, float(d.get("flash_every", 9.0)) * 0.5)


func fire_ranged(e: Enemy, _t: Node2D, dir: Vector2, dmg: float) -> bool:
	var n := int(d.get("pellets", 5))
	var spread := float(d.get("pellet_spread", 0.35))
	for i in n:
		var a := dir.angle() + randf_range(-spread, spread)
		e.game.projectiles.fire_hostile(e.position, Vector2.from_angle(a), dmg, e.projectile_speed, e.undead_damage_mult,
				Projectile.Kind.ENEMY_ARROW, e.kind)
	e.game.stat_add("breacher_shotgun_blasts", 1.0)
	rules(e).play_sound("gun_burst", e.position, 0.25)
	return true


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	_flash_cd -= delta
	if _flash_cd > 0.0:
		return false
	var reach := float(d.get("flash_range", 190.0))
	var best: SummonedUnit = null
	var best_d := INF
	e.game.ally_grid.query(e.position, reach, _buf)
	for u: SummonedUnit in _buf:
		if u.active and u.state != SummonedUnit.State.DEAD and not u.airborne:
			var dist := u.position.distance_to(e.position)
			if dist < best_d:
				best_d = dist
				best = u
	if best == null:
		_flash_cd = 0.5  # Nobody in reach: look again shortly.
		return false
	_flash_cd = float(d.get("flash_every", 9.0))
	rules(e).shells.add(best.position, float(d.get("flash_windup", 0.7)), float(d.get("flash_radius", 52.0)), 0.0,
			CityEnemyData.FLASH_SOURCE, false, float(d.get("flash_stun", 1.0)))
	e.game.stat_add("breacher_flashbangs", 1.0)
	return false
