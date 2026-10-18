## GibberingKit — the Gibbering Mass and its smaller masses (ArchiveEnemyData
## "gibbering_mass" -> "gibbering_lesser" -> "gibbering_least"; Act II, GDD
## §15.0 "Act II: the Hollow Archive"): a tank that walks at the necromancer
## through the shared melee AI and, when it is KILLED, splits into
## split_count masses of its row's split_into kind (at most twice: the least
## mass splits into nothing). The split is queued in ArchiveHazards and
## spawned on the next step (never inside the kill), at fixed offsets either
## side of the fallen mass's line to the necromancer: deterministic, no RNG.
## A mass that leaves the field without a kill (recycled, a run's end) does
## not split. Stats: gibbering_splits (masses spawned), gibbering_deaths.
class_name GibberingKit
extends CovenantKit


## Queues the split.
func on_killed(e: Enemy) -> void:
	var g := e.game
	g.stat_add("gibbering_deaths", 1.0)
	var into := String(d.get("split_into", ""))
	if into == "" or int(d.get("split_count", 0)) <= 0:
		return
	var to := g.player.position - e.position
	var dir := to.normalized() if to.length() > 0.5 else Vector2.RIGHT  # Fallen mass -> necromancer.
	g.enemies.archive_hazards().queue_split(into, e.position, dir, int(d["split_count"]), float(d["split_offset"]), e.is_elite)

