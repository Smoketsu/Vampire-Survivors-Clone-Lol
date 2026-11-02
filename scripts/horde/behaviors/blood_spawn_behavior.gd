## BloodSpawnBehavior — the Blood Spawn's BLOODTHIRST ("bloodthirst", UnitData
## "blood_spawn"; Act VII, Castle Sanguis's finale reward; GDD §15.0 "The Blood
## Spawn, Nosferatu and Thirst Eternal"; owner-approved proposal: "Blood Spawn,
## fast vampire brawlers that heal themselves on every hit (a class special,
## so it works on every stage; evolution Nosferatu)"). The Blood Spawn itself
## is an ordinary fast melee "guard" summon on the Bone Ring's front posts. Its
## special has no cooldown and no cast:
##   * BLOODTHIRST (on_melee_hit()): every blade or bite that lands heals the
##     Blood Spawn for drink_share x the damage it dealt, through THE existing
##     unit-heal path (CombatResolver.heal_unit(); Thirst Eternal makes it
##     larger there, like every heal on a summon);
##   * evolved into NOSFERATU (SummonEvolutionData "nosferatu", special_set
##     drink_share / spill_share / spill_radius): the blood it cannot hold (the
##     heal past its full health) SPILLS: spill_share of it heals the most
##     wounded other summon within spill_radius px (the same heal path).
## Works the same on every stage (owner rule: summons never get act-only
## rules). Its paired passive Thirst Eternal (THIRST) is read by
## CombatResolver._thirst_eternal(). Determinism: no RNG (the most wounded
## ally, ties in the spatial hash's order). Stats: blood_spawn_drinks,
## blood_spawn_healed, nosferatu_spills, nosferatu_spill_heal.
class_name BloodSpawnBehavior
extends SummonBehavior

## Passive id of Thirst Eternal (PassiveData, UnlockData; read by
## CombatResolver._thirst_eternal()).
const THIRST: String = "thirst_eternal"
## Its level-row key: extra share (0..) of every heal a summon receives.
const THIRST_KEY: String = "unit_heal"

## Reusable ally query buffer.
var _buf: Array = []


## No cast and no cooldown: Bloodthirst works on every blow.
func cooldown(_u: SummonedUnit) -> float:
	return 1.0


## Bloodthirst: the blow heals the Blood Spawn; Nosferatu spills the overflow.
func on_melee_hit(u: SummonedUnit, _e: Enemy, dealt: float) -> void:
	if dealt <= 0.0 or not u.active:
		return
	var drink := dealt * float(u.special.get("drink_share", 0.0))  # HP the blow is worth.
	if drink <= 0.0:
		return
	var game := u.game
	var room := u.max_hp - u.hp  # HP it can hold now.
	var got := game.combat.heal_unit(u, drink)
	game.stat_add("blood_spawn_drinks", 1.0)
	game.stat_add("blood_spawn_healed", got)
	var spill := float(u.special.get("spill_share", 0.0))
	var over := drink - room
	if spill <= 0.0 or over <= 0.0:
		return
	var reach := float(u.special.get("spill_radius", 0.0))
	game.ally_grid.query(u.position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	var best: SummonedUnit = null
	var worst := 0.0  # Most HP missing so far.
	for a: SummonedUnit in _buf:
		if a == u or not a.active or a.state == SummonedUnit.State.DEAD or a.state == SummonedUnit.State.SPAWNING:
			continue
		if a.position.distance_to(u.position) > reach + a.radius:
			continue
		var miss := a.max_hp - a.hp
		if miss > worst:
			worst = miss
			best = a
	if best == null:
		return
	var shared := game.combat.heal_unit(best, over * spill)
	if shared > 0.0:
		game.stat_add("nosferatu_spills", 1.0)
		game.stat_add("nosferatu_spill_heal", shared)
