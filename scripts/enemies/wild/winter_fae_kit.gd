## WinterFaeKit — the kit of the WINTER FAE (female, figure style; WildEnemyData
## "winter_fae"; temporary Act XV, the Turning Year; GDD §15.0 "The Turning Year
## foundation (phase 1)"): the Winter Court's archer, WINTER ONLY (its row's
## "season": SeasonCycle's timeline helper keeps it out of every other
## season). It throws a frost bolt from range through the plain ranged attack,
## tagged with its own id so the damage reports name it; phase 2 adds the chill.
class_name WinterFaeKit
extends WildKit


## The frost bolt: the plain hostile shot, tagged "winter_fae". Always fires it (true).
func fire_ranged(e: Enemy, _t: Node2D, dir: Vector2, dmg: float) -> bool:
	e.game.projectiles.fire_hostile(e.position, dir, dmg, e.projectile_speed, e.undead_damage_mult, Projectile.Kind.ENEMY_ARROW, e.kind)
	return true
