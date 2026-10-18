## SeraphTexts — text helpers of the Fallen Seraph (Act II, GDD §15.0
## "Fallen Seraph"; the ClassPassives pattern): the one concrete level-up card
## line of her paired passive Fallen Grace (AbilityManager._passive_offer),
## the NEW lines of the Seraph of Ruin evolution card (SummonEvolutions.
## build_offer) and the autotest summary line. The effects live on their
## single paths: the dive and the rings in SeraphBehavior / SeraphFeathers,
## Fallen Grace in HordeDirector._special_stats(). Data only in UnitData /
## PassiveData / SummonEvolutionData; no state here.
class_name SeraphTexts
extends RefCounted

## Class id of the Fallen Seraph (UnitData).
const CLASS_ID: String = "fallen_seraph"
## Passive id of Fallen Grace (PassiveData).
const PASSIVE_ID: String = "fallen_grace"
## Evolution id of the Seraph of Ruin (SummonEvolutionData).
const EVOLUTION_ID: String = "ruin_seraph"
## Example special cooldown (s) shown on the Fallen Grace card when no class
## with a special is owned (UI illustration only, not a balance number): the
## Fallen Seraph's dive.
const EXAMPLE_COOLDOWN: float = 7.0


## One player-visible consequence of Fallen Grace going to level row `nxt`
## ("" for other passives): an owned special's cooldown now -> after.
static func card_line(game: Game, id: String, nxt: Dictionary) -> String:
	if id != PASSIVE_ID:
		return ""
	var ab := game.abilities  # Passive levels.
	var cur_h := 1.0 + ab.passive_value(id, "special_haste")  # Fallen Grace divisor now.
	var nxt_h := 1.0 + float(nxt["special_haste"])  # After this card.
	for cls: String in UnitData.CLASS_ORDER:
		if int(game.horde.class_levels[cls]) <= 0:
			continue
		var sp: Dictionary = game.horde.compute_stats(cls, int(game.horde.class_levels[cls]), false).get("special", {})  # Its special now.
		for key: String in sp:
			if key.ends_with("_cooldown"):
				var now := float(sp[key])  # Cooldown with the current Fallen Grace (s).
				return "%s special every %ss -> %ss" % [game.horde.evolutions.class_plural(cls), AbilityManager._fmt(now),
						AbilityManager._fmt(now * cur_h / nxt_h)]
	return "A %ss special: every %ss -> %ss" % [AbilityManager._fmt(EXAMPLE_COOLDOWN),
			AbilityManager._fmt(EXAMPLE_COOLDOWN / cur_h), AbilityManager._fmt(EXAMPLE_COOLDOWN / nxt_h)]


## Card lines for the new mechanics of evolution `evo` (`cur` / `nxt`: the
## class's effective stats without / with the overlay). Empty for the other
## evolutions.
static func evolution_lines(evo: String, _cur: Dictionary, nxt: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()  # Card lines.
	if evo != EVOLUTION_ID:
		return out
	var b: Dictionary = nxt.get("special", {})  # Special numbers after.
	if int(b.get("chain_dives", 0)) > 0:
		out.append("NEW  Each dive chains to %d more pack%s" % [int(b["chain_dives"]), "" if int(b["chain_dives"]) == 1 else "s"])
	if int(b.get("rings", 1)) > 1:
		out.append("NEW  %d feather rings per dive, the last %d%% wider" % [int(b["rings"]),
				int(roundf(float(b.get("ring_growth", 0.0)) * float(int(b["rings"]) - 1) * 100.0))])
	return out


## Autotest summary of the Fallen Seraph, Fallen Grace and the Seraph of Ruin
## (game.stats keys set by SeraphBehavior, SeraphFeathers, CombatResolver).
static func summary_line(game: Game) -> String:
	var st := game.stats  # Run counters.
	var h := game.horde
	var dmg_all := 0.0  # Every Seraph damage source.
	for src: String in [CLASS_ID, EVOLUTION_ID, SeraphBehavior.SRC_DIVE, SeraphBehavior.SRC_FEATHERS]:
		dmg_all += float(st.get("dmg_" + src, 0.0))
	return "Lv %d (%s), alive %d/%d, deaths %d | dives %d (chained %d, no pack %d), dive hits %d | rings %d (dropped %d), feather cuts %d | dmg %d (blades %d, dive %d, feathers %d) | fallen_grace Lv %d" % [
		int(h.class_levels[CLASS_ID]), h.evolutions.class_plural(CLASS_ID), h.count_of(CLASS_ID), h.capacity(CLASS_ID),
		int(_sum_prefix(st, "death_%s_by_" % CLASS_ID)),
		int(st.get("seraph_dives", 0.0)), int(st.get("seraph_chain_dives", 0.0)), int(st.get("seraph_no_pack", 0.0)),
		int(st.get("seraph_dive_hits", 0.0)), int(st.get("seraph_rings", 0.0)), int(st.get("seraph_rings_dropped", 0.0)),
		int(st.get("seraph_feather_hits", 0.0)), int(dmg_all),
		int(float(st.get("dmg_" + CLASS_ID, 0.0)) + float(st.get("dmg_" + EVOLUTION_ID, 0.0))),
		int(st.get("dmg_" + SeraphBehavior.SRC_DIVE, 0.0)), int(st.get("dmg_" + SeraphBehavior.SRC_FEATHERS, 0.0)),
		game.abilities.passive_level(PASSIVE_ID)]


## True when this run ever had the Fallen Seraph (the autotest prints her
## line only then, so runs without her print exactly as before).
static func used(game: Game) -> bool:
	return int(game.horde.class_levels[CLASS_ID]) > 0 or game.stats.has("seraph_dives") \
			or game.abilities.passive_level(PASSIVE_ID) > 0


## Sum of every stat whose key starts with `prefix`.
static func _sum_prefix(st: Dictionary, prefix: String) -> float:
	var total := 0.0  # Running sum.
	for k: String in st:
		if k.begins_with(prefix):
			total += float(st[k])
	return total
