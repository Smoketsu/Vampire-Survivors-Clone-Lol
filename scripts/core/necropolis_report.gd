## NecropolisReport — the autotest summary lines of the Necropolis of Sand
## (temporary Act XII; GDD §15.0 "The Necropolis of Sand (Act XII phase 2)"
## and the rows after it). Read-only: it never changes the run. Two entry
## points:
##   print_lines(game, st) — from DynastyReport.print_lines() (only when the
##       Dynasty ran), each line only when its system ran:
##     necropolis:     NecropolisDirector (the jars beside the tombs, No Jars
##                     Left, the Pass's storm, the Sand Colossus, the events)
##     necropolis kinds: the Nile Archers (silenced seconds) and the Jackal
##                     Warriors (lunges, hits), when either spawned
##     sand colossus:  the miniboss's fight (when he came)
##     anubis:         Anubis's fight (when he was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Necropolis's items was taken (so other runs print as before):
##     act XII spell:   Linen Bind / Eternal Shroud (level, damage, kills,
##                      casts, wraps, hold, risen Mummies, shroud bursts)
##     act XII passives: Natron Salts, Embalmed Bones (levels, effects)
class_name NecropolisReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.necropolis != null:
		print("[autotest] necropolis: %s" % en.necropolis.summary_line())
	var archers := float(st.get("spawned_" + DynastyEnemyData.NILE_ARCHER, 0.0))
	var jackals := float(st.get("spawned_" + DynastyEnemyData.JACKAL_WARRIOR, 0.0))
	if archers > 0.0 or jackals > 0.0:
		print("[autotest] necropolis kinds: nile archers %d (silenced in the storm %.0f s; dmg to you %d, to summons %d) | jackal warriors %d (lunges %d, hits %d; lunge dmg to you %d, to summons %d)" % [
			int(archers), float(st.get("nile_archer_silenced", 0.0)),
			int(st.get("player_dmg_from_" + DynastyEnemyData.NILE_ARCHER, 0.0)), int(st.get("summon_dmg_from_" + DynastyEnemyData.NILE_ARCHER, 0.0)),
			int(jackals), int(st.get("jackal_lunges", 0.0)), int(st.get("jackal_lunge_hits", 0.0)),
			int(st.get("player_dmg_from_" + DynastyEnemyData.LUNGE_SOURCE, 0.0)), int(st.get("summon_dmg_from_" + DynastyEnemyData.LUNGE_SOURCE, 0.0))])
	if float(st.get("spawned_" + NecropolisEnemyData.COLOSSUS, 0.0)) > 0.0:
		print("[autotest] sand colossus: spawned %d, slams %d (summons struck %d, on you %d), killed %d (ttk %.0f s) | dmg to you %d, to summons %d" % [
			int(st.get("spawned_" + NecropolisEnemyData.COLOSSUS, 0.0)), int(st.get("colossus_slams", 0.0)),
			int(st.get("colossus_slam_hits", 0.0)), int(st.get("colossus_slam_on_you", 0.0)),
			int(st.get("colossus_kills", 0.0)), float(st.get("colossus_ttk", 0.0)),
			int(st.get("player_dmg_from_" + NecropolisEnemyData.SLAM_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + NecropolisEnemyData.COLOSSUS, 0.0)),
			int(st.get("summon_dmg_from_" + NecropolisEnemyData.SLAM_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + NecropolisEnemyData.COLOSSUS, 0.0))])
	if String(en.boss_info.get("id", "")) == String(NecropolisStage.BOSS["id"]) and en.boss is BossAnubis:
		print("[autotest] anubis: %s" % BossAnubis.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(LinenBindData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(LinenBindData.ID)  # The spell node (null if never ticked).
		print("[autotest] act XII spell: linen_bind: Lv%d%s dmg=%d (eternal shroud %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(LinenBindData.ID) else "", int(ab.spells.damage_of(LinenBindData.ID)),
			int(st.get("dmg_" + LinenBindData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(LinenBindData.ID)), node.summary_extra() if node != null else ""])
	var natron := ab.passive_level(LinenBindData.NATRON_SALTS)  # Natron Salts level.
	var embalmed := ab.passive_level(DynastyRulesData.EMBALMED_BONES)  # Embalmed Bones level.
	if natron > 0 or embalmed > 0:
		print("[autotest] act XII passives: natron_salts Lv%d (bindings +%d%%, hold +%.1f s, bonus dmg %d) | embalmed_bones Lv%d (glyphs shed %d%% sooner, cursed summons take -%d%%, dmg prevented %d)" % [
			natron, roundi(100.0 * ab.passive_value(LinenBindData.NATRON_SALTS, LinenBindData.NATRON_DMG_KEY)),
			ab.passive_value(LinenBindData.NATRON_SALTS, LinenBindData.NATRON_HOLD_KEY), int(st.get("linen_natron_bonus_dmg", 0.0)),
			embalmed, roundi(100.0 * ab.passive_value(DynastyRulesData.EMBALMED_BONES, DynastyRulesData.EMBALMED_SHED_KEY)),
			roundi(100.0 * ab.passive_value(DynastyRulesData.EMBALMED_BONES, DynastyRulesData.EMBALMED_TAKEN_KEY)),
			int(st.get("embalmed_dmg_prevented", 0.0))])
