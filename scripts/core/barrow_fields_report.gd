## BarrowFieldsReport — the autotest summary lines of the Barrow Fields (the Hall
## of the Slain, temporarily Act XI, Stage 16 in the final order; GDD §15.0 "The
## Barrow Fields (the Hall of the Slain phase 2)" and the rows after it).
## Read-only: it never changes the run. Two entry points:
##   print_lines(game, st) — from NorseReport.print_lines() (only when the Norse
##       rules ran), each line only when its system ran:
##     barrow fields:  BarrowFieldsDirector (the braziers by zone, the open
##                     barrows, the drifts, Keep the Fires, the Wight, events)
##     barrow wight:   the miniboss's fight (when he came)
##     hrimgar:        Hrimgar's fight (when he was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the stage's items was taken (so other runs print as before):
##     norse spell:    Barrow Grasp / Barrow-Lord's Embrace (level, damage,
##                     kills, casts, hands, grabs, holds)
##     norse passives: Grave Frost, Fur-Lined Bones (levels, effects)
class_name BarrowFieldsReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.barrow_fields != null:
		print("[autotest] barrow fields: %s" % en.barrow_fields.summary_line())
	if float(st.get("spawned_" + BarrowFieldsEnemyData.WIGHT, 0.0)) > 0.0:
		print("[autotest] barrow wight: spawned %d, howls %d (summons stunned %d, on you %d), killed %d (ttk %.0f s) | dmg to you %d, to summons %d" % [
			int(st.get("spawned_" + BarrowFieldsEnemyData.WIGHT, 0.0)), int(st.get("wight_howls", 0.0)),
			int(st.get("wight_howl_stuns", 0.0)), int(st.get("wight_howl_on_you", 0.0)),
			int(st.get("wight_kills", 0.0)), float(st.get("wight_ttk", 0.0)),
			int(st.get("player_dmg_from_" + BarrowFieldsEnemyData.WIGHT, 0.0)), int(st.get("summon_dmg_from_" + BarrowFieldsEnemyData.WIGHT, 0.0))])
	if String(en.boss_info.get("id", "")) == HrimgarData.ARRIVAL["id"] and en.boss is BossHrimgar:
		print("[autotest] hrimgar: %s" % BossHrimgar.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(BarrowGraspData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(BarrowGraspData.ID)  # The spell node (null if never ticked).
		print("[autotest] norse spell: barrow_grasp: Lv%d%s dmg=%d (embrace %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(BarrowGraspData.ID) else "", int(ab.spells.damage_of(BarrowGraspData.ID)),
			int(st.get("dmg_" + BarrowGraspData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(BarrowGraspData.ID)), node.summary_extra() if node != null else ""])
	var frost := ab.passive_level(BarrowGraspData.GRAVE_FROST)  # Grave Frost level.
	var fur := ab.passive_level(NorseRulesData.FUR_LINED_BONES)  # Fur-Lined Bones level.
	if frost > 0 or fur > 0:
		print("[autotest] norse passives: grave_frost Lv%d (barrow hands +%d%%, bonus dmg %d) | fur_lined_bones Lv%d (cold's slow on summons -%d%%)" % [
			frost, roundi(100.0 * ab.passive_value(BarrowGraspData.GRAVE_FROST, BarrowGraspData.GRAVE_FROST_KEY)), int(st.get("grasp_frost_bonus_dmg", 0.0)),
			fur, roundi(100.0 * ab.passive_value(NorseRulesData.FUR_LINED_BONES, NorseRulesData.FUR_KEY))])
