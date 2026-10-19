## VictoryResults — what the victory results card shows, worked out from a
## finished run's summary (Game.build_summary() plus its "soul_ash" award from
## Meta.award_run()); content wave 2, GDD §15.0 "Victory screen (content wave 2)".
## Static and read-only: it never changes the run, the save or any RNG, so the
## card (EndScreen's victory path), the last stand's title card (LastStand) and
## the autotest's "victory screen" line all read the same numbers, headless too.
##
## build() returns a Dictionary:
##   stage_id      — the run's stage (StageRegistry id),
##   title         — the stage's victory title (VictoryData.STAGES),
##   line          — the act's line under the title (VictoryData.ACT_LINES),
##   boss_line     — the stage's boss line when the boss fell ("" otherwise),
##   overtime      — seconds survived past 0:00 (s),
##   best_before   — the stage's best time past 0:00 before this run (s, from
##                   the award's "best_reckoning_before"; 0 = none yet),
##   best          — the best after this run (max of the two, s),
##   new_record    — true when this run beat a positive time past 0:00 over the
##                   stage's earlier best (a first clear is a record too),
##   hyper_clear   — true when Hyper mode was on (the seal is stamped in gold),
##   seal_accent   — the seal's UiTheme accent (VictoryData.SEAL_*),
##   highlights    — Array of [caption, value, kind] rows (kind "class" for the
##                   top-damage class, "evolution" for an evolution, "" else), in
##                   the card's order: top-damage class, evolutions (with game
##                   times, at most VictoryData.MAX_EVOLUTION_ROWS plus a "+N
##                   more" row), chests opened, largest army, the boss kill time.
class_name VictoryResults
extends RefCounted


## The card's numbers for `summary` (see the header). Works for any summary;
## the card only asks for it on a victory.
static func build(summary: Dictionary) -> Dictionary:
	var stage_id := String(summary.get("stage_id", StageRegistry.DEFAULT_ID))
	var texts: Dictionary = VictoryData.STAGES.get(stage_id, {})  # Title and boss line ({} = defaults).
	var act := StageRegistry.act_of(stage_id)
	var ash: Dictionary = summary.get("soul_ash", {})  # Meta.award_run() result ({} = none).
	var overtime := float(summary.get("time_past_zero", 0.0))  # Seconds past 0:00.
	var before := float(ash.get("best_reckoning_before", 0.0))  # The stage's best before this run.
	var hyper := bool(summary.get("hyper", false)) and bool(summary.get("victory", false))
	return {
		"stage_id": stage_id,
		"title": String(texts.get("title", VictoryData.DEFAULT_TITLE)),
		"line": String(VictoryData.ACT_LINES.get(act, VictoryData.ACT_LINES[1])),
		"boss_line": String(texts.get("boss_line", "")) if bool(summary.get("boss_defeated", false)) else "",
		"overtime": overtime,
		"best_before": before,
		"best": maxf(before, overtime),
		"new_record": bool(summary.get("victory", false)) and overtime > 0.0 and overtime > before,
		"hyper_clear": hyper,
		"seal_accent": VictoryData.SEAL_HYPER_ACCENT if hyper else VictoryData.SEAL_ACCENT,
		"highlights": highlights(summary),
	}


## The highlight rows of `summary` ([caption, value, kind]; see the header).
static func highlights(summary: Dictionary) -> Array:
	var out: Array = []
	var st: Dictionary = summary.get("stats", {})
	var top := top_damage_class(st)  # [class id, damage] ("" = no summon damage).
	if String(top[0]) != "":
		var names: Dictionary = summary.get("horde_names", {})  # Class -> plural (evolved name).
		var cls := String(top[0])
		out.append([VictoryData.HL_TOP_DAMAGE, "%s  %s" % [String(names.get(cls, UnitData.UNITS[cls]["plural"])), compact(float(top[1]))], "class"])
	var evos: PackedStringArray = summary.get("evolution_log", PackedStringArray())  # "id@m:ss" entries.
	var shown := 0  # Evolution rows added.
	for entry: String in evos:
		var id := entry.get_slice("@", 0)
		if not EvolutionRecipes.has(id):
			continue
		if shown >= VictoryData.MAX_EVOLUTION_ROWS:
			break
		var r := EvolutionRecipes.recipe(id)
		out.append([String(r["name"]), entry.get_slice("@", 1), "evolution"])
		shown += 1
	if evos.size() > shown and shown > 0:
		out.append([VictoryData.HL_MORE_EVOLUTIONS % (evos.size() - shown), "", ""])
	out.append([VictoryData.HL_CHESTS, "%d" % int(st.get("chests_opened", 0.0)), ""])
	out.append([VictoryData.HL_ARMY, "%d" % int(summary.get("peak_army", summary.get("horde_total", 0))), ""])
	if bool(summary.get("boss_defeated", false)) and float(summary.get("boss_kill_time", -1.0)) >= 0.0:
		out.append([VictoryData.HL_BOSS % String(summary.get("boss_name", "")), RunBuild.clock(float(summary["boss_kill_time"])), ""])
	return out


## The summon class that dealt the most damage in stats `st` (its "dmg_<source>"
## counters, each source mapped to its class by class_of_source()): [class id,
## damage]; ["", 0.0] when no summon dealt damage. Ties go to the earlier class
## in UnitData.CLASS_ORDER (deterministic).
static func top_damage_class(st: Dictionary) -> Array:
	var per := {}  # Class id -> damage.
	for k: String in st:
		if not k.begins_with("dmg_") or k.begins_with("dmg_from_") or k.begins_with("dmg_resisted_"):
			continue
		var cls := class_of_source(k.substr(4))
		if cls != "":
			per[cls] = float(per.get(cls, 0.0)) + float(st[k])
	var best := ""
	var best_dmg := 0.0
	for cls: String in UnitData.CLASS_ORDER:
		if float(per.get(cls, 0.0)) > best_dmg:
			best = cls
			best_dmg = float(per[cls])
	return [best, best_dmg]


## The summon class (UnitData id) behind damage source `src`, or "" for a spell
## or anything else: the synergy table's map (SynergyData.SOURCE_CLASS), a class
## id itself, a summon evolution id (its first base class), or a source named
## "<class or evolution>_<suffix>" (e.g. "death_knight_bash", "warrior_aura").
static func class_of_source(src: String) -> String:
	if SynergyData.SOURCE_CLASS.has(src):
		return String(SynergyData.SOURCE_CLASS[src])
	if UnitData.UNITS.has(src):
		return src
	if SummonEvolutionData.EVOLUTIONS.has(src):
		return _evolution_class(src)
	for cls: String in UnitData.CLASS_ORDER:
		if src.begins_with(cls + "_"):
			return cls
	for evo: String in SummonEvolutionData.ORDER:
		if src.begins_with(evo + "_"):
			return _evolution_class(evo)
	return ""


## The class an evolution's damage counts for: the evolved class itself for a
## merge that has one (its "result", e.g. the Profane Bishop's "bishop"), else
## its first base class.
static func _evolution_class(evo: String) -> String:
	var def: Dictionary = SummonEvolutionData.EVOLUTIONS[evo]
	var into := String(def.get("result", ""))  # Merged class id ("" = a transform).
	if UnitData.UNITS.has(into):
		return into
	return String((def["bases"] as Array)[0])


## A short damage figure: "950", "12.3k", "1.42M".
static func compact(v: float) -> String:
	if v >= 1000000.0:
		return "%.2fM" % (v / 1000000.0)
	if v >= 10000.0:
		return "%.1fk" % (v / 1000.0)
	if v >= 1000.0:
		return "%.2fk" % (v / 1000.0)
	return "%d" % int(v)


## The stage the victory card's Next button starts after `stage_id`: the next
## StageRegistry.ORDER entry when it is playable and unlocked (Meta, after this
## run's award, so the boss kill that opens it counts); "" when there is none
## (the last stage, a locked or unplayable one): the button is hidden then.
static func next_stage(stage_id: String) -> String:
	var i := StageRegistry.ORDER.find(stage_id)
	if i < 0 or i + 1 >= StageRegistry.ORDER.size():
		return ""
	var nid := String(StageRegistry.ORDER[i + 1])
	return nid if StageRegistry.is_playable(nid) and Meta.is_stage_unlocked(nid) else ""


## The autotest's "victory screen" line for `info` (build() result).
static func summary_line(info: Dictionary) -> String:
	return "title=%s best_overtime=%d new_record=%s highlights=%d" % [
		String(info["title"]), int(float(info["best"])), str(bool(info["new_record"])), (info["highlights"] as Array).size()]
