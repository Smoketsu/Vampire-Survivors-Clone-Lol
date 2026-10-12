## MinionPassives — small static helpers for the four later horde passives
## (PassiveData: Bone Plating, Unholy Precision, Unholy Resilience, Bound
## Souls). Their effects live on the single paths CLAUDE.md requires:
##   * Unholy Precision crits, Unholy Resilience and Bone Plating:
##     CombatResolver.damage_enemy() / damage_unit(),
##   * Bound Souls move speed, leash and return speed:
##     HordeDirector.compute_stats() (pushed to SummonedUnit.apply_stats()).
## This file only builds text: the one concrete level-up card line
## (AbilityManager._passive_offer) and the autotest summary line.
class_name MinionPassives
extends RefCounted

## Damage of the example hit shown on the Bone Plating and Unholy Resilience
## cards (UI illustration only, not a balance number).
const EXAMPLE_HIT: float = 10.0


## One player-visible consequence of passive `id` going to the level row
## `nxt` (current values from the passive's current level).
static func card_line(game: Game, id: String, nxt: Dictionary) -> String:
	var ab := game.abilities  # Passive levels.
	match id:
		"bone_plating":
			var cur := plated_hit(EXAMPLE_HIT, ab.passive_value(id, "flat_reduction"))  # Hit after the plating now.
			var nx := plated_hit(EXAMPLE_HIT, float(nxt["flat_reduction"]))  # Hit after this card.
			return "A %s-damage hit on a minion: %s -> %s" % [AbilityManager._fmt(EXAMPLE_HIT), AbilityManager._fmt(cur), AbilityManager._fmt(nx)]
		"unholy_precision":
			var k := PassiveData.CRIT_DAMAGE_MULT - 1.0  # Extra damage of one crit (fraction).
			var cur := ab.passive_value(id, "crit_chance") * k  # Average minion damage bonus now.
			var nx := float(nxt["crit_chance"]) * k  # After this card.
			return "Average minion damage +%d%% -> +%d%%" % [int(roundf(cur * 100.0)), int(roundf(nx * 100.0))]
		"unholy_resilience":
			var cur := EXAMPLE_HIT * (1.0 - ab.passive_value(id, "area_holy_reduction"))  # Holy hit now.
			var nx := EXAMPLE_HIT * (1.0 - float(nxt["area_holy_reduction"]))  # After this card.
			return "A %s-damage holy or area hit: %s -> %s" % [AbilityManager._fmt(EXAMPLE_HIT), AbilityManager._fmt(cur), AbilityManager._fmt(nx)]
		"bound_souls":
			var base := float(UnitData.UNITS["warrior"]["move_speed"])  # Warrior base speed (px/s).
			var cur_m := 1.0 + ab.passive_value(id, "minion_move_speed")  # Speed multiplier now.
			var nx_m := 1.0 + float(nxt["minion_move_speed"])  # After this card.
			var cur_l := UnitData.SOFT_RECALL * (1.0 + ab.passive_value(id, "leash_range"))  # Recall distance now (px).
			var nx_l := UnitData.SOFT_RECALL * (1.0 + float(nxt["leash_range"]))  # After this card.
			return "Warrior speed %s -> %s px/s, recalled beyond %s -> %s px" % [
				AbilityManager._fmt(base * cur_m), AbilityManager._fmt(base * nx_m), AbilityManager._fmt(cur_l), AbilityManager._fmt(nx_l)]
	return ""


## Damage of a hit of `amount` after a Bone Plating flat reduction of `flat`
## (the same rule as CombatResolver.damage_unit()).
static func plated_hit(amount: float, flat: float) -> float:
	return amount - minf(flat, amount * (1.0 - PassiveData.PLATING_MIN_FRACTION))


## Autotest summary: each passive's final level and what it did this run.
static func summary_line(game: Game) -> String:
	var ab := game.abilities  # Passive levels.
	var st := game.stats  # Run counters.
	return "bone_plating Lv %d (dmg prevented %d) | unholy_precision Lv %d (crits %d, crit bonus dmg %d) | unholy_resilience Lv %d (dmg prevented %d: area %d, holy %d) | bound_souls Lv %d (soft recalls %d, hard recalls %d)" % [
		ab.passive_level("bone_plating"), int(st.get("plating_dmg_prevented", 0.0)),
		ab.passive_level("unholy_precision"), int(st.get("minion_crits", 0.0)), int(st.get("minion_crit_bonus_dmg", 0.0)),
		ab.passive_level("unholy_resilience"), int(st.get("resilience_dmg_prevented", 0.0)),
		int(st.get("resilience_dmg_prevented_area", 0.0)), int(st.get("resilience_dmg_prevented_holy", 0.0)),
		ab.passive_level("bound_souls"), int(st.get("summon_soft_recalls", 0.0)), game.horde.hard_recalls]
