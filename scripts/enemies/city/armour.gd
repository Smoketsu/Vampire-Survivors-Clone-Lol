## Armour — the first Last Line rule's FRONT (Act VIII; GDD §15.0 "Armour";
## owner-approved proposal: "the city has vehicles ... armour"), owned by
## Game.city as `armour`. THE one front path, built like Act IV's Phalanx
## (PantheonRules.hit_from_front()):
##   * front_mult(e, origin, shot, source) is called ONCE from
##     CombatResolver.damage_enemy() (through CityRules.armour_mult(), after the
##     Phalanx block), only while Game.city exists and the hit has an origin;
##     a City kind whose row has "armour_front" > 0 (the riot cop's shield, the
##     tank's front) cuts that share from a hit whose origin lies inside its
##     front arc (+-front_half_angle of the kit's facing). An arcing hit from
##     above (CombatResolver.FROM_ABOVE) ignores the front, and so does every
##     undirected hit (no origin).
##   * Flat armour is the existing Enemy.flat_armor path (the tank's
##     "flat_armor"): no second one here.
##   * the Kevlar Bones hook (kevlar_mult(), read once by
##     CombatResolver.damage_unit()): summons take less RANGED damage from City
##     kinds; exactly 1 while the passive does not exist (not built).
## The vehicles themselves (driving, run-overs, wrecks) are Convoy's.
## Determinism: no RNG. Stats: armour_front_hits, armour_front_dmg_prevented
## (in damage_enemy()), kevlar_dmg_prevented.
class_name Armour
extends RefCounted

## Owning run.
var game: Game
## cos(front_half_angle): a hit whose direction dots the facing at least this
## much lands on the front.
var _front_cos: float = 0.5


## Builds the rule for `p_game`.
func _init(p_game: Game) -> void:
	game = p_game
	_front_cos = cos(float(CityRulesData.ARMOUR["front_half_angle"]))


## Share (0..1) of a hit on `e` from world point `origin` that lands: 1 -
## the row's armour_front when the origin lies in the kit's front arc, else 1
## (also for an arcing hit from above and for a kind with no front). `shot`
## and `source` are the hit's (counted in the stats only).
func front_mult(e: Enemy, origin: Vector2, _shot: bool, _source: String) -> float:
	if origin == CombatResolver.FROM_ABOVE or not (e.kit is CityKit):
		return 1.0
	var kit := e.kit as CityKit
	var front := kit.armour_front()
	if front <= 0.0:
		return 1.0
	if not hit_from_front(e, kit.facing, origin):
		return 1.0
	game.stat_add("armour_front_hits", 1.0)
	game.stat_add("armour_front_hits_" + e.kind, 1.0)
	return 1.0 - front


## THE one facing test of the Last Line: true when a hit from `origin` strikes
## `e` (facing unit `facing`) inside its front arc. A hit from the body's own
## centre counts as the front.
func hit_from_front(e: Enemy, facing: Vector2, origin: Vector2) -> bool:
	var to := origin - e.position  # From the body toward where the hit came from.
	if to.length_squared() < 0.0001:
		return true
	return to.normalized().dot(facing) >= _front_cos


## Kevlar Bones (counter-passive hook, NOT built): x on a hit tagged `source`
## on a summon: 1 - the bound player's PassiveData kevlar_bones /
## ranged_reduction for a RANGED City hit (a "ranged" City row's kind id, or a
## CityEnemyData.RANGED_SOURCES tag), else 1. Exactly 1 while the passive does
## not exist (the source is not even looked at).
func kevlar_mult(source: String) -> float:
	var v := game.abilities.passive_value(CityRulesData.KEVLAR_BONES, CityRulesData.KEVLAR_KEY)  # 0 when not owned.
	if v <= 0.0:
		return 1.0
	var ranged := source in CityEnemyData.RANGED_SOURCES
	if not ranged:
		var row := EnemyDirector.city_def(source)
		ranged = not row.is_empty() and String(row.get("behavior", "")) == "ranged"
	return 1.0 - v if ranged else 1.0
