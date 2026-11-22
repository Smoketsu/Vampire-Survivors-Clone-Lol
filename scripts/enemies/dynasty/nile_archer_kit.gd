## NileArcherKit — the kit of the NILE ARCHER (female, figure style;
## DynastyEnemyData "nile_archer"; temporary Act XII, the Necropolis Dynasty;
## GDD §15.0 "The Necropolis of Sand (Act XII phase 2)"; owner-approved
## proposal: "Arrows; silenced by sandstorms | Kill early; wait out the
## storm"). Her arrows are the shared hostile shot (behavior "ranged",
## Enemy's own ranged attack). The Sandstorm on her bow is DynastyKit's one
## read (physics(): her reach x DynastyRules.reach_mult(), and her row's
## "storm_silenced" holds the shot while it blows); this kit only counts the
## seconds she stood silenced with a target in her normal reach (the report)
## and tags her arrows with her kind (fire_ranged(): the shared hostile
## arrow, so the reports and Lead-Lined Bones see "nile_archer").
## No Rebirth (her row has none). Determinism: game state only. Stats:
## nile_archer_silenced (s), nile_archer_shots.
class_name NileArcherKit
extends DynastyKit


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var g := e.game
	if g.dynasty != null and g.dynasty.reach_mult() < 1.0 and e._target_valid() \
			and e.position.distance_to(e.target.position) <= float(d["attack_range"]):
		g.stat_add("nile_archer_silenced", delta)
	return false


## Her arrow: the shared hostile arrow (ProjectileManager.fire_hostile()),
## tagged with her kind.
func fire_ranged(e: Enemy, _t: Node2D, dir: Vector2, dmg: float) -> bool:
	e.game.projectiles.fire_hostile(e.position, dir, dmg, e.projectile_speed, e.undead_damage_mult, Projectile.Kind.ENEMY_ARROW, e.kind)
	e.game.stat_add("nile_archer_shots", 1.0)
	return true
