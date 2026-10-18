## SporePilgrimKit — the Pilgrim of the Spore (ArchiveEnemyData
## "spore_pilgrim"; Act II, GDD §15.0 "Act II: the Hollow Archive"): area
## denial. While it walks at the necromancer (the shared melee AI) it leaves a
## spore cloud behind it every cloud_interval s (cloud_radius px, cloud_life
## s), and bursts into a bigger one (death_cloud_radius, death_cloud_life)
## when it dies. The clouds live in ArchiveHazards (any stage): the
## necromancer's Dread rises while he stands in one ("spores", Act II only)
## and summons inside choke. Stats: spore_clouds_left, spore_death_clouds.
## Determinism: no RNG; the first cloud staggered by the think slot.
class_name SporePilgrimKit
extends CovenantKit

## Seconds until the next cloud.
var cloud_cd: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cloud_cd = first_cd(e, float(d["cloud_first"]))


func physics(e: Enemy, delta: float) -> bool:
	cloud_cd -= delta
	if cloud_cd <= 0.0:
		cloud_cd = float(d["cloud_interval"])
		e.game.enemies.archive_hazards().add_cloud(e.position, float(d["cloud_radius"]), float(d["cloud_life"]))
		e.game.stat_add("spore_clouds_left", 1.0)
	return false


## The death burst: a bigger cloud where it fell.
func on_killed(e: Enemy) -> void:
	e.game.enemies.archive_hazards().add_cloud(e.position, float(d["death_cloud_radius"]), float(d["death_cloud_life"]))
	e.game.stat_add("spore_death_clouds", 1.0)
