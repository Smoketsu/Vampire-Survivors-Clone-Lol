## ValgardReport — the autotest summary lines of Valgard, the Hall of Heroes
## (Stage 17 in the final order; the Hall of the Slain, temporarily Act XI; GDD
## §15.0 "Valgard, the Hall of Heroes (the Hall of the Slain phase 2)" and the
## rows after it). Read-only: it never changes the run. Two entry points:
##   print_lines(game, st) — from NorseReport.print_lines() (only when the
##       Norse rules ran), each line only when its system ran:
##     valgard:          ValgardDirector (the Feast, the hall's hearths, the
##                       Champion, the events)
##     einherjar champion: the miniboss's fight (when he spawned)
##     valgard threats:  the top summon-damage sources and summon deaths of
##                       the run (the balance pass's view)
##     sigrun:           her fight (when she was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of Valgard's items was taken or used (so other runs print as before):
##     norse spell:      Valkyrie Spear / Chooser of the Slain (level, damage,
##                       kills, spears, the chosen)
##     norse passives:   Einherjar's Oath, Calm Blood (levels, effects)
class_name ValgardReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.valgard != null:
		print("[autotest] valgard: %s | hall's hearths lit %d" % [en.valgard.summary_line(), int(st.get("valgard_hearths", 0.0))])
	if float(st.get("champion_spawned", 0.0)) > 0.0:
		print("[autotest] einherjar champion: sweeps %d (hits %d) | horns %d (einherjar woken %d) | killed %d (ttk %.0f s) | dmg to you %d, to summons %d" % [
			int(st.get("champion_sweeps", 0.0)), int(st.get("champion_sweep_hits", 0.0)), int(st.get("champion_horns", 0.0)),
			int(st.get("champion_horn_woken", 0.0)), int(st.get("champion_kills", 0.0)), float(st.get("champion_ttk", 0.0)),
			int(st.get("player_dmg_from_" + ValgardEnemyData.CHAMPION, 0.0) + st.get("player_dmg_from_" + ValgardEnemyData.SWEEP_SOURCE, 0.0)),
			int(st.get("summon_dmg_from_" + ValgardEnemyData.CHAMPION, 0.0) + st.get("summon_dmg_from_" + ValgardEnemyData.SWEEP_SOURCE, 0.0))])
	if String(game.stage_def.get("id", "")) == ValgardStage.ID:
		print("[autotest] valgard threats (summon dmg by source): %s | summon deaths by source: %s | calm blood prevented %d" % [
			FortKesslerReport._threats(st), FortKesslerReport._deaths(st), int(st.get("calm_blood_dmg_prevented", 0.0))])
	if String(en.boss_info.get("id", "")) == SigrunData.ARRIVAL["id"] and en.boss is BossSigrun:
		print("[autotest] sigrun: %s" % BossSigrun.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(ValkyrieSpearData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(ValkyrieSpearData.ID)  # The spell node (null if never ticked).
		print("[autotest] norse spell: valkyrie_spear: Lv%d%s dmg=%d (chooser of the slain %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(ValkyrieSpearData.ID) else "", int(ab.spells.damage_of(ValkyrieSpearData.ID)),
			int(st.get("dmg_" + ValkyrieSpearData.EVOLVED_SOURCE, 0.0)), int(ab.spells.kills_of(ValkyrieSpearData.ID)),
			node.summary_extra() if node != null else ""])
	var oath := ab.passive_level(ValkyrieSpearData.OATH)  # Einherjar's Oath level.
	var calm := ab.passive_level(NorseRulesData.CALM_BLOOD)  # Calm Blood level.
	if oath > 0 or calm > 0:
		print("[autotest] norse passives: einherjars_oath Lv%d (+%d leaps, +%d%% spear damage) | calm_blood Lv%d (berserk blows on summons -%d%%, prevented %d)" % [
			oath, roundi(ab.passive_value(ValkyrieSpearData.OATH, ValkyrieSpearData.OATH_JUMPS_KEY)),
			roundi(100.0 * ab.passive_value(ValkyrieSpearData.OATH, ValkyrieSpearData.OATH_DAMAGE_KEY)),
			calm, roundi(100.0 * ab.passive_value(NorseRulesData.CALM_BLOOD, NorseRulesData.CALM_BLOOD_KEY)),
			int(st.get("calm_blood_dmg_prevented", 0.0))])
