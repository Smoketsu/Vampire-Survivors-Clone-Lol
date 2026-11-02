## GangGunnerKit — the kit of the Gang Gunner (CityEnemyData "gang_gunner";
## Act VIII, GDD §15.0 "Act VIII foundation (phase 1)"): gangs ranged fodder
## with two pistols, sprayed sideways while it walks in. Each shot of the
## shared ranged attack is a SPRAY (fire_ranged()): `spray` bullets, each
## aimed off by up to spray_spread rad (poor aim, many bullets), tagged with
## its kind (the report's damage lines; Kevlar Bones' hook). It keeps walking
## in (the shared "ranged" advance). Determinism: the seeded gameplay RNG.
class_name GangGunnerKit
extends CityKit


func fire_ranged(e: Enemy, _t: Node2D, dir: Vector2, dmg: float) -> bool:
	var n := int(d.get("spray", 3))
	var spread := float(d.get("spray_spread", 0.4))
	for i in n:
		var a := dir.angle() + randf_range(-spread, spread)
		e.game.projectiles.fire_hostile(e.position, Vector2.from_angle(a), dmg, e.projectile_speed, e.undead_damage_mult,
				Projectile.Kind.ENEMY_ARROW, e.kind)
	e.game.stat_add("gunner_sprays", 1.0)
	rules(e).play_sound("gun_burst", e.position, 0.25)
	return true
