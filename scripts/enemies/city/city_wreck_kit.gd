## CityWreckKit — the kit of a "spawned" Burning Wreck (CityEnemyData
## "city_wreck"; Act VIII, GDD §15.0 "Armour"). Convoy places a dead vehicle's
## wreck itself; this kit only lets --spawn=city_wreck@T drop one to test: on
## its first tick it places a wreck where it stands through the same path
## (CityBlocks.add_wreck() on a blocks stage, then Convoy's explosion
## WRECK explode_after s later; off a blocks stage only the explosion) and
## leaves the field at once (EnemyDirector.despawn(): no kill, no XP). No RNG.
class_name CityWreckKit
extends CityKit

## True once this activation placed its wreck.
var _placed: bool = false


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_placed = false


func physics(e: Enemy, _delta: float) -> bool:
	if not _placed:
		_placed = true
		var conv := rules(e).convoy
		var cb := e.game.arena.city_blocks
		var at := e.position
		if cb != null:
			var o := cb.add_wreck(e.position, float(CityRulesData.WRECK["half_along"]), e.game.elapsed)
			if o != null:
				at = o.center
				e.game.stat_add("city_wrecks", 1.0)
		conv.place_explosion(at)
		e.game.enemies.despawn(e)
	return true
