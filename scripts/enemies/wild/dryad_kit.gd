## DryadKit — the kit of the DRYAD (female, figure style; WildEnemyData "dryad";
## temporary Act XV, the Turning Year; GDD §15.0 "Overgrowth"; proposal:
## "Dryad | Support | Plants thicket seeds; heals the Wild on living ground |
## Priority target"). OVERGROWTH's planter: from `plant_first` s after it comes
## on, every `plant_every` s, while the nearest standing necromancer is within
## `plant_reach` px, it plants a seed `plant_ahead` px toward him
## (Thickets.plant(), the one planting path; the seed grows into a thorn
## thicket). Its heal is the plain healer AI's (row "healer"); the heal on
## living ground every Wild kind gets is BloomField's. Determinism: game time
## only, no RNG.
class_name DryadKit
extends WildKit

## Game time (s) of this dryad's next seed.
var _next_plant: float = INF


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_next_plant = e.game.elapsed + float(d.get("plant_first", 5.0))


func physics(e: Enemy, _delta: float) -> bool:
	if e.game.elapsed < _next_plant:
		return false
	_next_plant = e.game.elapsed + float(d.get("plant_every", 14.0))
	var pl := e.game.nearest_player(e.position)  # The necromancer it plants toward.
	if pl == null or pl.position.distance_to(e.position) > float(d.get("plant_reach", 260.0)):
		return false
	var to := pl.position - e.position
	var at := e.position + to.normalized() * minf(float(d.get("plant_ahead", 120.0)), to.length())
	rules(e).thickets.plant(at, -1.0, e.kind)
	return false
