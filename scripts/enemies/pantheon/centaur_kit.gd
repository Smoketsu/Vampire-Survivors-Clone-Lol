## CentaurKit — the kit of the Centaur Archer (OlympusEnemyData
## "centaur_archer"; Act IV, Mount Olympus; GDD §15.0 "Mount Olympus kinds";
## owner-approved proposal: "Fires while galloping toward you (no kiting); kill
## it on approach"). The shared ranged AI already always advances on the
## necromancer; the kit's row key "gallop_fire" clears the shared shooting
## slow-down every tick (Enemy._shoot_slow_timer), so a centaur loses at most
## the one tick it looses an arrow and keeps its gallop. BRONZE: Zeus's
## lightning chains to it. Its arrows are ProjectileManager's hostile arrows
## (Line of Fire is Act III only) tagged with its kind id (fire_ranged()), so
## the stats name it. No RNG.
class_name CentaurKit
extends PantheonKit


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	if bool(d.get("gallop_fire", false)):
		e._shoot_slow_timer = 0.0  # Fires at the gallop (no shooting slow-down).
	return false


## Its arrow: a hostile arrow tagged with its kind id (the stats name it).
func fire_ranged(e: Enemy, _t: Node2D, dir: Vector2, dmg: float) -> bool:
	e.game.projectiles.fire_hostile(e.position + dir * (e.radius + 2.0), dir, dmg, e.projectile_speed, e.undead_damage_mult,
			Projectile.Kind.ENEMY_ARROW, e.kind)
	return true
