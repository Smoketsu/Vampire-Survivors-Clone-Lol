## FortKesslerReport — the autotest summary lines of Fort Kessler (Act VIII,
## Stage 23; GDD §15.0 "Fort Kessler (Act VIII phase 2)" and the rows after
## it). Read-only: it never changes the run. Two entry points:
##   print_lines(game, st) — from CityReport.print_lines() (only when the Last
##       Line ran), each line only when its system ran:
##     fort kessler:        FortKesslerDirector (the minefields, Mammoth, the
##                          events)
##     fort kessler kinds:  the Machine Gunner's lanes and the Attack
##                          Helicopter's runs (when one spawned)
##     mammoth:             the miniboss's fight (when it spawned)
##     fort kessler threats: the top summon-damage sources of the run (the
##                          balance pass's view)
##     harrow:              General Harrow's fight (when he was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of Fort Kessler's items was taken (so other runs print as before):
##     act VIII spell:      Bone Mines / Killing Ground (level, damage, kills,
##                          mines laid and set off)
##     act VIII passives:   Tripwire, Armour-Piercing Bones (levels, effects)
class_name FortKesslerReport
extends RefCounted

## How many summon-damage sources the threats line lists.
const THREATS: int = 8


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.fort_kessler != null:
		print("[autotest] fort kessler: %s" % en.fort_kessler.summary_line())
	if float(st.get("spawned_" + CityEnemyData.MACHINE_GUNNER, 0.0)) > 0.0 or float(st.get("spawned_" + CityEnemyData.ATTACK_HELICOPTER, 0.0)) > 0.0:
		print("[autotest] fort kessler kinds: machine gunner set-ups %d (lane ticks %d, hits on summons %d, on you %d, walled %d; dmg to you %d, to summons %d) | attack helicopter runs %d, rockets %d (dmg to you %d, to summons %d), melee hits cut %d, crashes onto a street %d" % [
			int(st.get("mg_setups", 0.0)), int(st.get("mg_ticks", 0.0)), int(st.get("mg_hits_summons", 0.0)), int(st.get("mg_hits_you", 0.0)),
			int(st.get("mg_walled", 0.0)), int(st.get("player_dmg_from_" + CityEnemyData.MG_SOURCE, 0.0)), int(st.get("summon_dmg_from_" + CityEnemyData.MG_SOURCE, 0.0)),
			int(st.get("heli_runs", 0.0)), int(st.get("heli_rockets", 0.0)),
			int(st.get("player_dmg_from_" + CityEnemyData.HELI_ROCKET_SOURCE, 0.0)), int(st.get("summon_dmg_from_" + CityEnemyData.HELI_ROCKET_SOURCE, 0.0)),
			int(st.get("heli_melee_cut", 0.0)), int(st.get("heli_crash_moved", 0.0))])
	if float(st.get("mammoth_spawned", 0.0)) > 0.0:
		print("[autotest] mammoth: main shells %d, twin lines %d | killed %d (ttk %.0f s), extra wreck %d | dmg to you %d, to summons %d" % [
			int(st.get("mammoth_main_shells", 0.0)), int(st.get("mammoth_twin_lines", 0.0)),
			int(st.get("mammoth_kills", 0.0)), float(st.get("mammoth_ttk", 0.0)), int(st.get("mammoth_wrecks", 0.0)),
			int(st.get("player_dmg_from_" + FortKesslerEnemyData.MAMMOTH, 0.0) + st.get("player_dmg_from_" + FortKesslerEnemyData.MAMMOTH_SHELL_SOURCE, 0.0)),
			int(st.get("summon_dmg_from_" + FortKesslerEnemyData.MAMMOTH, 0.0) + st.get("summon_dmg_from_" + FortKesslerEnemyData.MAMMOTH_SHELL_SOURCE, 0.0))])
	if String(game.stage_def.get("id", "")) == FortKesslerStage.ID:
		print("[autotest] fort kessler threats (summon dmg by source): %s | mines: dmg to you %d, to summons %d" % [
			_threats(st), int(st.get("player_dmg_from_" + FortKesslerStage.MINE_SOURCE, 0.0)), int(st.get("summon_dmg_from_" + FortKesslerStage.MINE_SOURCE, 0.0))])
	if String(en.boss_info.get("id", "")) == HarrowData.ARRIVAL["id"] and en.boss is BossHarrow:
		print("[autotest] harrow: %s" % BossHarrow.summary_line(st))


## The top THREATS summon-damage sources of the run, "source dmg".
static func _threats(st: Dictionary) -> String:
	var rows: Array = []  # [damage, source].
	for k: String in st:
		if k.begins_with("summon_dmg_from_"):
			rows.append([float(st[k]), k.substr(16)])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]) or (float(a[0]) == float(b[0]) and String(a[1]) < String(b[1])))
	var out := PackedStringArray()
	for i in mini(THREATS, rows.size()):
		out.append("%s %d" % [String(rows[i][1]), int(rows[i][0])])
	return ", ".join(out) if not out.is_empty() else "-"


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(BoneMinesData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(BoneMinesData.ID)  # The spell node (null if never ticked).
		print("[autotest] act VIII spell: bone_mines: Lv%d%s dmg=%d (killing ground %d, shards %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(BoneMinesData.ID) else "", int(ab.spells.damage_of(BoneMinesData.ID)),
			int(st.get("dmg_" + BoneMinesData.EVOLVED_SOURCE, 0.0)), int(st.get("dmg_" + BoneMinesData.SHARD_SOURCE, 0.0)),
			int(ab.spells.kills_of(BoneMinesData.ID)), node.summary_extra() if node != null else ""])
	var trip := ab.passive_level(BoneMinesData.TRIPWIRE)  # Tripwire level.
	var pierce := ab.passive_level(CityRulesData.ARMOUR_PIERCING)  # Armour-Piercing Bones level.
	if trip > 0 or pierce > 0:
		print("[autotest] act VIII passives: tripwire Lv%d (trigger +%d px, slow %d%% for %.1f s; %d foes slowed) | armour_piercing_bones Lv%d (front cut ignored %d%%; %d hits pierced, %d dmg let through)" % [
			trip, roundi(ab.passive_value(BoneMinesData.TRIPWIRE, BoneMinesData.TRIP_REACH_KEY)),
			roundi(100.0 * ab.passive_value(BoneMinesData.TRIPWIRE, BoneMinesData.TRIP_SLOW_KEY)),
			BoneMinesData.TRIP_SLOW_TIME, int(st.get("tripwire_slowed", 0.0)),
			pierce, roundi(100.0 * ab.passive_value(CityRulesData.ARMOUR_PIERCING, CityRulesData.PIERCE_KEY)),
			int(st.get("armour_pierced_hits", 0.0)), int(st.get("armour_pierced_dmg", 0.0))])
