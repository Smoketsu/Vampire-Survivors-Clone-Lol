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
##   * Act VIII, Fort Kessler: ARMOUR-PIERCING BONES (pierce_share(), applied
##     inside front_mult(): a summon-class hit's front becomes front x (1 - v));
##     a City boss with no kit offers its front through city_armour_front() /
##     city_facing() (General Harrow's power armour);
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
# --- Act VIII: Fort Kessler ---
## Share (0..1) of the last front hit's raw damage that Armour-Piercing Bones
## let through (front x v; 0 when it did nothing). CombatResolver.damage_enemy()
## reads it right after armour_mult() for the armour_pierced_dmg stat only.
var last_pierce: float = 0.0
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
func front_mult(e: Enemy, origin: Vector2, _shot: bool, source: String) -> float:
	last_pierce = 0.0
	if origin == CombatResolver.FROM_ABOVE:
		return 1.0
	var front := 0.0  # The row's front share (0..1).
	var facing := Vector2.RIGHT  # The body's facing (the front test).
	if e.kit is CityKit:
		var kit := e.kit as CityKit
		front = kit.armour_front()
		facing = kit.facing
	elif e.has_method("city_armour_front"):
		# --- Act VIII: Fort Kessler --- a City boss with no kit (General
		# Harrow's power armour, BossHarrow): its own front share and facing.
		front = float(e.call("city_armour_front"))
		facing = e.call("city_facing")
	if front <= 0.0:
		return 1.0
	if not hit_from_front(e, facing, origin):
		return 1.0
	game.stat_add("armour_front_hits", 1.0)
	game.stat_add("armour_front_hits_" + e.kind, 1.0)
	# --- Act VIII: Fort Kessler --- ARMOUR-PIERCING BONES (the one hook): a
	# summon-class hit ignores `v` of the front's cut (front x (1 - v)).
	var v := pierce_share(source)
	if v > 0.0:
		last_pierce = front * v
		front *= 1.0 - v
		game.stat_add("armour_pierced_hits", 1.0)
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
	var ranged := source in CityEnemyData.RANGED_SOURCES or source in CityEnemyData.FORT_KESSLER_RANGED_SOURCES  # Act VIII: Fort Kessler's tags too.
	if not ranged:
		var row := EnemyDirector.city_def(source)
		ranged = not row.is_empty() and String(row.get("behavior", "")) == "ranged"
	return 1.0 - v if ranged else 1.0


# --- Act VIII: Fort Kessler ---
## ARMOUR-PIERCING BONES (Act VIII's counter-passive, earned by Broken Arrow;
## offered only in Act VIII through its card row's "act"): the share (0..1) of a
## front's cut that a hit tagged `source` ignores: the bound player's PassiveData
## armour_piercing_bones / front_pierce for a SUMMON-CLASS hit (a
## SynergyData.SOURCE_CLASS source, which volleys carry, or any other minion
## attack tag of CombatResolver.is_minion_source(): the Archers' "archer" and
## the later classes are not in SOURCE_CLASS), else 0. Spells, the
## necromancer's own attacks and flat armour are untouched. Exactly 0 while the
## passive is not owned (the source is not even looked at).
func pierce_share(source: String) -> float:
	var v := game.abilities.passive_value(CityRulesData.ARMOUR_PIERCING, CityRulesData.PIERCE_KEY)  # 0 when not owned.
	if v <= 0.0:
		return 0.0
	if SynergyData.SOURCE_CLASS.has(source) or game.combat.is_minion_source(source):
		return clampf(v, 0.0, 1.0)
	return 0.0
