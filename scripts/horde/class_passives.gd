## ClassPassives — text helpers for the three newest summon classes (Bone
## Hounds, Banshee, Corpse Catapult), their passives (PassiveData: Blood
## Scent, Mournsong, Siegecraft) and their evolutions (SummonEvolutionData:
## Hellhound, Keening Lady, Ossuary Engine). The effects themselves live on
## the single paths CLAUDE.md requires:
##   * Blood Scent: HordeDirector.compute_stats() (fast classes,
##     PassiveData.FAST_SUMMON_SPEED),
##   * Mournsong: CombatResolver.debuff_time(),
##   * Siegecraft: CombatResolver.damage_enemy(),
##   * the class kits: BoneHoundBehavior, BansheeBehavior, CatapultBehavior
##     and HordeHazards.
## This file only builds text: the one concrete level-up card line of each
## passive (AbilityManager._passive_offer), the NEW lines of each evolution
## card (SummonEvolutions.build_offer) and the autotest summary line. Data
## only in UnitData / PassiveData / SummonEvolutionData; no state here.
class_name ClassPassives
extends RefCounted

## Summon damage-source tags of these classes that are not a class or
## evolution id, mapped to their base class (autotest per-class summary).
const EXTRA_TAGS := {"hellhound_burn": "bone_hound", "hellhound_trail": "bone_hound", "ossuary_shards": "corpse_catapult"}
## Example hit duration (s) shown on the Mournsong card (UI illustration
## only, not a balance number): the Banshee's Dirge.
const EXAMPLE_DEBUFF: float = 4.0


## One player-visible consequence of passive `id` going to level row `nxt`
## ("" for other passives).
static func card_line(game: Game, id: String, nxt: Dictionary) -> String:
	var ab := game.abilities  # Passive levels.
	match id:
		"blood_scent":
			var base := float(UnitData.UNITS["bone_hound"]["move_speed"])  # Hound base speed (px/s).
			var cur := 1.0 + ab.passive_value(id, "fast_move_speed")  # Speed multiplier now.
			var nx := 1.0 + float(nxt["fast_move_speed"])  # After this card.
			return "Bone Hound speed %s -> %s px/s (fast: %s)" % [AbilityManager._fmt(base * cur), AbilityManager._fmt(base * nx), ", ".join(fast_classes())]
		"mournsong":
			var cur := EXAMPLE_DEBUFF * (1.0 + ab.passive_value(id, "debuff_duration"))  # Example duration now (s).
			var nx := EXAMPLE_DEBUFF * (1.0 + float(nxt["debuff_duration"]))  # After this card.
			return "A %ss slow or Dirge: %ss -> %ss" % [AbilityManager._fmt(EXAMPLE_DEBUFF), AbilityManager._fmt(cur), AbilityManager._fmt(nx)]
		"siegecraft":
			var c := game.horde.compute_stats("corpse_catapult", maxi(1, int(game.horde.class_levels["corpse_catapult"])), false)  # Catapult stats.
			var cur := float(c["damage"]) * (1.0 + ab.passive_value(id, "siege_damage"))  # Boulder on a structure now.
			var nx := float(c["damage"]) * (1.0 + float(nxt["siege_damage"]))  # After this card.
			return "A catapult boulder on a structure: %s -> %s" % [AbilityManager._fmt(cur), AbilityManager._fmt(nx)]
	return ""


## Plurals of the summon classes Blood Scent treats as fast (base move
## speed >= PassiveData.FAST_SUMMON_SPEED; evolution-only classes left out).
static func fast_classes() -> PackedStringArray:
	var out := PackedStringArray()  # Class plurals.
	for cls: String in UnitData.CLASS_ORDER:
		var row: Dictionary = UnitData.UNITS[cls]
		if not bool(row.get("evolved_only", false)) and float(row["move_speed"]) >= PassiveData.FAST_SUMMON_SPEED:
			out.append(String(row["plural"]))
	return out


## Card lines for the new mechanics of evolution `evo` (`cur` / `nxt`: the
## class's effective stats without / with the overlay). Empty for the other
## evolutions.
static func evolution_lines(evo: String, cur: Dictionary, nxt: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()  # Card lines.
	var b: Dictionary = nxt.get("special", {})  # Special numbers after.
	match evo:
		"hellhound":
			out.append("NEW  Burning bites: +%d%% of each bite as fire over %ss" % [
				int(roundf(float(b["burn_fraction"]) * 100.0)), AbilityManager._fmt(float(b["burn_ticks"]) * float(b["burn_tick"]))])
			out.append("NEW  Running hounds leave a short fire trail")
			if int(b.get("pack_split", 1)) > 1:
				out.append("NEW  The pack splits to hunt %d prey at once" % int(b["pack_split"]))
		"keening_lady":
			out.append("NEW  Each Dirge rolls out in %d widening waves" % int(b["waves"]))
			if int(b.get("silence", 0)) > 0:
				out.append("NEW  Priests it reaches cannot heal for %ss" % AbilityManager._fmt(b["dirge_duration"]))
		"ossuary_engine":
			out.append("NEW  %d boulders per volley (volley every %ss)" % [int(b["volley"]), AbilityManager._fmt(nxt["attack_interval"])])
			out.append("NEW  Each leaves burning bone shards for %ss" % AbilityManager._fmt(b["shard_life"]))
	return out


## Autotest summary: the three passives' levels and effects, and summon
## damage to structures.
static func summary_line(game: Game) -> String:
	var ab := game.abilities  # Passive levels.
	var st := game.stats  # Run counters.
	var struct_dmg := 0.0  # Summon damage dealt to structures.
	for k: String in st:
		if not k.begins_with("structdmg_"):
			continue
		var src := k.substr(10)  # Damage-source tag.
		if game.combat.is_minion_source(src) or src in PassiveData.MINION_DOT_SOURCES:
			struct_dmg += float(st[k])
	return "blood_scent Lv %d (fast: %s) | mournsong Lv %d (extra debuff s %d) | siegecraft Lv %d (siege bonus dmg %d) | summon dmg to structures %d (catapults %d)" % [
		ab.passive_level("blood_scent"), ", ".join(fast_classes()), ab.passive_level("mournsong"), int(st.get("mournsong_extra_seconds", 0.0)),
		ab.passive_level("siegecraft"), int(st.get("siege_bonus_dmg", 0.0)), int(struct_dmg), int(st.get("catapult_structure_dmg", 0.0))]
