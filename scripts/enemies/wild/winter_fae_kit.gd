## WinterFaeKit — the kit of the WINTER FAE (female, figure style; WildEnemyData
## "winter_fae"; temporary Act XV, the Turning Year; GDD §15.0 "The Greenwood
## (Act XV phase 2)"; owner-approved proposal: "Winter Fae (female, figure
## style) | Ranged | Frost bolts that chill summons; winter only | Fire; Mages"):
## the Winter Court's archer, WINTER ONLY (its row's "season": SeasonCycle's
## timeline helper keeps it out of every other season). It throws a frost bolt
## from range through the plain ranged attack, tagged with its own id so the
## damage reports name it; a summon it strikes is CHILLED chill_slow for
## chill_time s (the bolt's chill, CombatResolver.chill_unit(), the one summon
## chill path, through ProjectileManager.fire_hostile()'s chill arguments).
class_name WinterFaeKit
extends WildKit


## The frost bolt: the plain hostile shot, tagged "winter_fae", that chills the
## summon it strikes. Always fires it (true).
func fire_ranged(e: Enemy, _t: Node2D, dir: Vector2, dmg: float) -> bool:
	e.game.projectiles.fire_hostile(e.position, dir, dmg, e.projectile_speed, e.undead_damage_mult, Projectile.Kind.ENEMY_ARROW, e.kind,
			float(d.get("chill_slow", 0.0)), float(d.get("chill_time", 0.0)))
	return true
