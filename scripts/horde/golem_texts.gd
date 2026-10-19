## GolemTexts — text helpers of the Bone Golem (content wave 2, GDD §15.0
## "Bone Golem (content wave 2)"; the SeraphTexts pattern): the class's
## level-up card lines (SummonBehaviors.card_lines()), the one concrete card
## line of its paired passive Grave Masonry (AbilityManager._passive_offer),
## the NEW lines of the Ossuary Titan evolution card (SummonEvolutions.
## build_offer) and the autotest summary line. The effects live on their single
## paths: the slam and the Bulwark in GolemBehavior, Ossuary Hunger and the
## Titan in GolemKit, Grave Masonry in CombatResolver.damage_unit() (damage)
## and HordeDirector.compute_stats() (hold), Charnel House in SynergyManager.
## Data only in UnitData / PassiveData / SummonEvolutionData / SynergyData; no
## state here.
class_name GolemTexts
extends RefCounted

## Class id of the Bone Golem (UnitData).
const CLASS_ID: String = "bone_golem"
## Passive id of Grave Masonry (PassiveData).
const PASSIVE_ID: String = "grave_masonry"
## Evolution id of the Ossuary Titan (SummonEvolutionData).
const EVOLUTION_ID: String = "ossuary_titan"
## Synergy id of Charnel House (SynergyData).
const SYNERGY_ID: String = "charnel_house"
## Example hit (damage) shown on the Grave Masonry card (UI illustration only,
## not a balance number).
const EXAMPLE_HIT: float = 20.0


## Level-up card lines of the class special ("bulwark"): what it does (`a`
## empty: a new class) or how it changes (`a` -> `b`: the special numbers now
## and after the card).
static func class_lines(out: PackedStringArray, a: Dictionary, b: Dictionary, nxt: Dictionary) -> void:
	if a.is_empty():
		out.append("Slam: %s dmg, %d%% to foes within %s px" % [SummonBehaviors._f(nxt["damage"]),
				int(roundf(float(b["slam_fraction"]) * 100.0)), SummonBehaviors._f(b["slam_radius"])])
		out.append("Bulwark every %ss: plants %ss, draws foes in %s px" % [SummonBehaviors._f(b["bulwark_cooldown"]),
				SummonBehaviors._f(b["bulwark_duration"]), SummonBehaviors._f(b["bulwark_reach"])])
		out.append("Absorbs fallen summons: +%d%% max HP each (max +%d%%)" % [int(roundf(float(b["hunger_hp"]) * 100.0)),
				int(roundf(float(b["hunger_cap"]) * 100.0))])
	else:
		SummonBehaviors._delta(out, "Slam radius", a, b, "slam_radius")
		SummonBehaviors._delta(out, "Bulwark time (s)", a, b, "bulwark_duration")
		SummonBehaviors._delta(out, "Bulwark cooldown (s)", a, b, "bulwark_cooldown")


## One player-visible consequence of Grave Masonry going to level row `nxt`
## ("" for other passives).
static func card_line(game: Game, id: String, nxt: Dictionary) -> String:
	if id != PASSIVE_ID:
		return ""
	var cur := game.abilities.passive_value(id, "blocker_reduction")  # Damage cut now.
	return "A %s-dmg hit on a blocker: %s -> %s" % [AbilityManager._fmt(EXAMPLE_HIT),
			AbilityManager._fmt(EXAMPLE_HIT * (1.0 - cur)), AbilityManager._fmt(EXAMPLE_HIT * (1.0 - float(nxt["blocker_reduction"])))]


## Card lines for the new mechanics of evolution `evo` (`cur` / `nxt`: the
## class's effective stats without / with the overlay). Empty for the other
## evolutions.
static func evolution_lines(evo: String, cur: Dictionary, nxt: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()  # Card lines.
	if evo != EVOLUTION_ID:
		return out
	var b: Dictionary = nxt.get("special", {})  # Special numbers after.
	SummonEvolutions._delta(out, "Slam radius", cur.get("special", {}).get("slam_radius", 0.0), b.get("slam_radius", 0.0))
	out.append("NEW  Absorbing bones heals it %d%% of its max HP" % int(roundf(float(b.get("absorb_heal", 0.0)) * 100.0)))
	out.append("NEW  ... and shields summons within %s px (%s HP)" % [AbilityManager._fmt(b.get("barrier_reach", 0.0)),
			AbilityManager._fmt(b.get("barrier_amount", 0.0))])
	out.append("NEW  Falls into a bone wall for %ss" % AbilityManager._fmt(b.get("wall_duration", 0.0)))
	return out


## True when this run ever had the Golem or its passive (the autotest prints
## the line only then, so runs without them print exactly as before).
static func used(game: Game) -> bool:
	return int(game.horde.class_levels[CLASS_ID]) > 0 or game.horde.golems != null \
			or game.abilities.passive_level(PASSIVE_ID) > 0


## Autotest summary line ("bone golem: ..."): the owner's fields first
## (absorbed, max growth, Bulwarks, Titan, Charnel House bonus damage), then the
## class's damage, deaths, slams, taunts, Grave Masonry and the Titan's kit.
static func summary_line(game: Game) -> String:
	var st := game.stats  # Run counters.
	var h := game.horde
	var titan := h.evolutions.done.has(EVOLUTION_ID)  # The Ossuary Titan was granted.
	var dmg := 0.0  # Every Golem damage source.
	for src: String in [CLASS_ID, EVOLUTION_ID, GolemBehavior.SLAM_SOURCE, GolemKit.WALL_SOURCE]:
		dmg += float(st.get("dmg_" + src, 0.0))
	return "absorbed=%d max_growth=%d%% bulwarks=%d titan=%s charnel_house_bonus=%d | Lv %d (%s), alive %d/%d, deaths %d | dmg %d (slams %d, splash %d, wall %d) slams=%d slam_hits=%d planted_s=%d taunts=%d | grave_masonry Lv %d prevented=%d | titan heal=%d barriers=%d (%d HP) walls=%d (segments %d, hits %d, pushes %d) | charnel_house hits=%d" % [
		int(st.get("golem_absorbed", 0.0)), int(roundf(float(st.get("golem_max_growth_pct", 0.0)))), int(st.get("golem_bulwarks", 0.0)),
		str(titan), int(st.get("syn_%s_bonus_dmg" % SYNERGY_ID, 0.0)),
		int(h.class_levels[CLASS_ID]), h.evolutions.class_plural(CLASS_ID), h.count_of(CLASS_ID), h.capacity(CLASS_ID),
		int(SeraphTexts._sum_prefix(st, "death_%s_by_" % CLASS_ID)), int(dmg),
		int(float(st.get("dmg_" + CLASS_ID, 0.0)) + float(st.get("dmg_" + EVOLUTION_ID, 0.0))),
		int(st.get("dmg_" + GolemBehavior.SLAM_SOURCE, 0.0)), int(st.get("dmg_" + GolemKit.WALL_SOURCE, 0.0)),
		int(st.get("golem_slams", 0.0)), int(st.get("golem_slam_hits", 0.0)), int(st.get("golem_bulwark_seconds", 0.0)),
		int(st.get("golem_taunts", 0.0)), game.abilities.passive_level(PASSIVE_ID), int(st.get("masonry_dmg_prevented", 0.0)),
		int(st.get("titan_heal", 0.0)), int(st.get("titan_barriers", 0.0)), int(st.get("titan_barrier_hp", 0.0)),
		int(st.get("titan_walls", 0.0)), int(st.get("titan_wall_segments", 0.0)), int(st.get("titan_wall_hits", 0.0)),
		int(st.get("titan_wall_pushes", 0.0)), int(st.get("syn_%s_hits" % SYNERGY_ID, 0.0))]
