## LionessTempleReport — the autotest summary lines of the Temple of the
## Lioness (temporary Act XII, Stage 35, final stage 20; GDD §15.0 "The Temple
## of the Lioness (Dynasty phase 2)" and the rows after it). Read-only: it
## never changes the run. Two entry points:
##   print_lines(game, st) — from DynastyReport.print_lines() (only when the
##       Dynasty ran), each line only when its system ran:
##     temple:            LionessTempleDirector (the Awakening Statues, the
##                        Lion Warden's seal, the events)
##     temple kinds:      the Bastet Hunter's dives and ambushes, the woken
##                        statues, the colossus slams (when any spawned)
##     lion warden:       the miniboss's fight (when he spawned)
##     temple threats:    the top summon-damage sources and summon deaths of
##                        the run (the balance pass's view; this stage only)
##     sekhmet:           her fight (when she was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when
##       one of the Temple's items was taken (so other runs print as before):
##     temple spell:      Burning Eye / Eye of Retribution (level, damage,
##                        kills, sweeps, retributions)
##     temple passives:   Desert Fury, Embalmed Bones (levels, effects)
class_name LionessTempleReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.lioness_temple != null:
		print("[autotest] temple: %s" % en.lioness_temple.summary_line())
	if float(st.get("spawned_bastet_hunter", 0.0)) + float(st.get("spawned_ushabti_statue", 0.0)) + float(st.get("spawned_" + LionessTempleEnemyData.WOKEN_COLOSSUS, 0.0)) > 0.0:
		print("[autotest] temple kinds: bastet dives %d, ambushes %d (hits %d), revealed by a spell %d, hits cut in the sand %d | ushabti %d/%d | woken colossi %d/%d, slams %d (hits %d)" % [
			int(st.get("bastet_dives", 0.0)), int(st.get("bastet_ambushes", 0.0)), int(st.get("bastet_ambush_hits", 0.0)),
			int(st.get("bastet_reveals", 0.0)), int(st.get("bastet_hidden_cut", 0.0)),
			int(st.get("spawned_ushabti_statue", 0.0)), int(st.get("kill_ushabti_statue", 0.0)),
			int(st.get("spawned_" + LionessTempleEnemyData.WOKEN_COLOSSUS, 0.0)), int(st.get("kill_" + LionessTempleEnemyData.WOKEN_COLOSSUS, 0.0)),
			int(st.get("colossus_slams", 0.0)), int(st.get("colossus_slam_hits", 0.0))])
	if float(st.get("warden_spawned", 0.0)) > 0.0:
		var w := LionessTempleEnemyData.LION_WARDEN
		print("[autotest] lion warden: slams %d (hits %d) | roars %d (hits %d) | killed %d (ttk %.0f s), released %d | dmg to you %d, to summons %d" % [
			int(st.get("warden_slams", 0.0)), int(st.get("warden_slam_hits", 0.0)), int(st.get("warden_roars", 0.0)),
			int(st.get("warden_roar_hits", 0.0)), int(st.get("warden_kills", 0.0)), float(st.get("warden_ttk", 0.0)),
			int(st.get("warden_released", 0.0)),
			int(st.get("player_dmg_from_" + w, 0.0) + st.get("player_dmg_from_" + LionessTempleEnemyData.WARDEN_SLAM_SOURCE, 0.0) + st.get("player_dmg_from_" + LionessTempleEnemyData.WARDEN_ROAR_SOURCE, 0.0)),
			int(st.get("summon_dmg_from_" + w, 0.0) + st.get("summon_dmg_from_" + LionessTempleEnemyData.WARDEN_SLAM_SOURCE, 0.0) + st.get("summon_dmg_from_" + LionessTempleEnemyData.WARDEN_ROAR_SOURCE, 0.0))])
	if String(game.stage_def.get("id", "")) == LionessTempleStage.ID:
		print("[autotest] temple threats (summon dmg by source): %s | summon deaths by source: %s" % [
			FortKesslerReport._threats(st), FortKesslerReport._deaths(st)])
	if en.boss is BossSekhmet:
		print("[autotest] sekhmet: %s" % BossSekhmet.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(BurningEyeData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(BurningEyeData.ID)  # The spell node (null if never ticked).
		print("[autotest] temple spell: burning_eye: Lv%d%s dmg=%d (eye of retribution %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(BurningEyeData.ID) else "", int(ab.spells.damage_of(BurningEyeData.ID)),
			int(st.get("dmg_" + BurningEyeData.EVOLVED_SOURCE, 0.0)), int(ab.spells.kills_of(BurningEyeData.ID)),
			node.summary_extra() if node != null else ""])
	var fury := ab.passive_level(BurningEyeData.PASSIVE)  # Desert Fury level.
	var emb := ab.passive_level(DynastyRulesData.EMBALMED_BONES)  # Embalmed Bones level.
	if fury > 0 or emb > 0:
		print("[autotest] temple passives: desert_fury Lv%d (Burning Eye +%d%%, arc +%d deg) | embalmed_bones Lv%d (glyphs shed %d%% sooner, cursed summons take -%d%%; dmg cut %d)" % [
			fury, roundi(100.0 * ab.passive_value(BurningEyeData.PASSIVE, "fury_dmg")), roundi(ab.passive_value(BurningEyeData.PASSIVE, "fury_arc")),
			emb, roundi(100.0 * ab.passive_value(DynastyRulesData.EMBALMED_BONES, DynastyRulesData.EMBALMED_SHED_KEY)),
			roundi(100.0 * ab.passive_value(DynastyRulesData.EMBALMED_BONES, DynastyRulesData.EMBALMED_TAKEN_KEY)),
			int(st.get("embalmed_dmg_prevented", 0.0))])
