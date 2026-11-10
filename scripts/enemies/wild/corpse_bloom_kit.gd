## CorpseBloomKit — the kit of the CORPSE-BLOOM (a structure; WildEnemyData
## "corpse_bloom"; temporary Act XV, the Turning Year; GDD §15.0 "The Greenwood
## (Act XV phase 2)"; owner-approved proposal: "Corpse-Bloom | Structure | Eats
## corpses on the field and spawns thornlings | Break it"). It never moves.
## Every eat_every s it EATS: the corpses within eat_radius px in Corpse
## Explosion's store (up to eat_max, gone for the necromancer:
## CorpseExplosion.eat_near(), when the spell is owned) and, without them, any
## death within eat_radius px since its last meal (CovenantRites.death_near());
## a meal that found either counts. Every bud_meals meals it BUDS bud_count
## Thornlings (row bud_kind) round it (EnemyDirector.spawn_at()).
## Determinism: no RNG, no instance ids. Stats: bloom_meals,
## bloom_corpses_eaten, bloom_buds.
class_name CorpseBloomKit
extends WildKit

## Seconds until the next meal.
var cd: float = 0.0
## Meals since its last bud.
var meals: int = 0
## Game time (s) of its last meal (deaths after it count for the next).
var last_meal: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d.get("eat_every", 2.0)))
	meals = 0
	last_meal = e.game.elapsed


func physics(e: Enemy, delta: float) -> bool:
	cd -= delta
	if cd > 0.0:
		return false
	cd = float(d.get("eat_every", 2.0))
	var g := e.game
	var r := float(d.get("eat_radius", 160.0))
	var ate := 0
	var ce: CorpseExplosion = g.abilities.spells.nodes.get("corpse_explosion")  # Its corpse store (null while never learned).
	if ce != null:
		ate = ce.eat_near(e.position, r, int(d.get("eat_max", 3)))
		g.stat_add("bloom_corpses_eaten", float(ate))
	if ate > 0 or g.enemies.rites.death_near(e.position, r, last_meal):
		meals += 1
		g.stat_add("bloom_meals", 1.0)
	last_meal = g.elapsed
	if meals >= int(d.get("bud_meals", 3)):
		meals = 0
		var n := int(d.get("bud_count", 4))
		for i in n:
			var at := g.arena.free_point(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (e.radius + 14.0), 6.0)
			if g.enemies.spawn_at(String(d.get("bud_kind", WildEnemyData.THORNLING)), at, false) != null:
				g.stat_add("bloom_buds", 1.0)
	return false
