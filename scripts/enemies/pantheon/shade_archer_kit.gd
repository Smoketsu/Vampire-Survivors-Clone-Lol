## ShadeArcherKit — the kit of the Shade Archer (UnderworldEnemyData
## "shade_archer"; Act IV, the Asphodel Underworld; owner request after playtest
## pass 2, Oct 25, 2026, GDD §15.0 "Act IV playtest pass 2 decisions"): the
## archers of Troy's dead, the Underworld's ranged kind. The shared ranged AI
## already always advances on the necromancer (no kiting) and slows while it
## shoots; the kit only tags its arrows. Its arrows are ProjectileManager's
## hostile arrows (Line of Fire is Act III only) tagged with its kind id
## (fire_ranged()), so the stats name it. No RNG.
class_name ShadeArcherKit
extends PantheonKit


## Its arrow: a hostile arrow tagged with its kind id (the stats name it).
func fire_ranged(e: Enemy, _t: Node2D, dir: Vector2, dmg: float) -> bool:
	e.game.projectiles.fire_hostile(e.position + dir * (e.radius + 2.0), dir, dmg, e.projectile_speed, e.undead_damage_mult,
			Projectile.Kind.ENEMY_ARROW, e.kind)
	return true
