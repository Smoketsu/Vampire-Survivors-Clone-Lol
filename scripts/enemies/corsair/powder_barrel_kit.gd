## PowderBarrelKit — the kit of the Smuggler's Cutter's Powder Barrel
## (CutterEnemyData "powder_barrel"; Act X, the Black Tide; GDD §15.0 "The
## Smuggler's Cutter (Act X phase 2)"; owner-approved proposal: "Barrels stack
## against the rails. Any hit breaks one: a blast that hurts both sides and
## knocks everyone 120 px (overboard if near the rail)"). A 1 HP STRUCTURE that
## CutterDirector sets along the rails (set to CutterEnemyData.BARREL_HP at
## activation, whatever the HP scalings, so any hit that reaches it breaks it:
## a summon's blow, a volley, a spell, an enemy powder blast). Broken, it goes
## off through THE powder blast (CorsairRules.powder_blast(), its row's "keg":
## both sides hit, everyone knocked `push` px: enemies by knockback, so at the
## rail they drown) and tells CutterDirector (the report). It never moves,
## never attacks and is never recycled (Enemy.is_objective). Works on any stage
## (forced with --spawn=: the blast there just knocks).
## Determinism: no RNG.
class_name PowderBarrelKit
extends CorsairKit

## True once it went off (it never goes off twice).
var blown: bool = false


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	blown = false
	e.max_hp = CutterEnemyData.BARREL_HP  # Any hit breaks it (owner-approved proposal).
	e.hp = CutterEnemyData.BARREL_HP
	e.is_objective = true  # It stands until broken (never recycled to the spawn ring).


## Broken: the blast.
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	if blown:
		return
	blown = true
	var keg: Dictionary = d.get("keg", {})
	if not keg.is_empty():
		rules(e).powder_blast(e.position, keg, e)
	var cd := e.game.enemies.cutter
	if cd != null:
		cd.on_barrel_blown(e)
	else:
		e.game.stat_add("cutter_barrels_blown", 1.0)
