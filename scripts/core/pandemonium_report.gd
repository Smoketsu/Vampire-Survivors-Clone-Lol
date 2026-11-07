## PandemoniumReport — the autotest summary lines of PANDEMONIUM and its rewards
## (Act VI, Stage 18; GDD §15.0 "Pandemonium (Act VI phase 2)" and the rows
## after it). Read-only: it never changes the run.
##   stage_lines(): called from InfernoReport.print_lines() (only when the
##     Inferno ran):
##     pandemonium        PandemoniumDirector (guests, objective Soul Ash) and
##                        its event log
##     pandemonium kinds  the Fallen Angels' dives (hits, blows that only
##                        grazed her aloft, blows taken landed, pits) and the
##                        Fallen Seraph General (cleaves, feathers, hits, pits,
##                        the Fallen Host, time to kill) (when any spawned)
##     morning star       BossMorningStar.summary_line() (when he fought)
##   item_lines(): called from Autotest.finish() on EVERY stage, each line only
##     when its item was used, so every other summary keeps its exact text:
##     fall from grace    Fall from Grace / Lightbringer, Pride, the Fallen
##                        Saint's Second Fall
##     archfiend          the Archfiend / the Prince of Hell and Crown of Horns
class_name PandemoniumReport
extends RefCounted


## The stage's lines (InfernoReport; the Inferno ran this run).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var pd := game.enemies.pandemonium  # The stage director (null off Pandemonium).
	if pd != null:
		print("[autotest] pandemonium: %s" % pd.summary_line())
		print("[autotest] pandemonium events (%d): %s" % [pd.fired.size(), ", ".join(pd.fired)])
	var any := false
	for k: String in [PandemoniumEnemyData.FALLEN_ANGEL, PandemoniumEnemyData.SERAPH_GENERAL]:
		any = any or int(st.get("spawned_" + k, 0.0)) > 0
	if any:
		print("[autotest] pandemonium kinds: fallen angel %d/%d, dives %d (summon hits %d, you hit %d), aloft blows grazed %d, landed blows %d, spear pits %d | seraph general %d, killed %d (ttk %ds): cleaves %d, feathers %d, you hit %d, summon hits %d, pits %d, fallen host %d" % [
			int(st.get("spawned_" + PandemoniumEnemyData.FALLEN_ANGEL, 0.0)), int(st.get("kill_" + PandemoniumEnemyData.FALLEN_ANGEL, 0.0)),
			int(st.get("fallen_angel_dives", 0.0)), int(st.get("fallen_angel_dive_hits", 0.0)), int(st.get("fallen_angel_dive_player_hits", 0.0)),
			int(st.get("fallen_angel_grazed", 0.0)), int(st.get("fallen_angel_landed_hits", 0.0)), int(st.get("pits_opened_fallen_angel", 0.0)),
			int(st.get("seraph_general_spawned", 0.0)), int(st.get("seraph_general_kills", 0.0)), int(st.get("seraph_general_ttk", 0.0)),
			int(st.get("seraph_general_cleaves", 0.0)), int(st.get("seraph_general_feathers", 0.0)), int(st.get("seraph_general_player_hits", 0.0)),
			int(st.get("seraph_general_summon_hits", 0.0)), int(st.get("seraph_general_pits", 0.0)), int(st.get("seraph_general_host", 0.0))])
	if game.enemies.boss is BossMorningStar:
		print("[autotest] morning star: %s" % BossMorningStar.summary_line(st))


## The rewards' lines (every stage; each only when its item was used).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities
	var lvl := ab.spell_level(FallFromGraceData.ID)
	if lvl > 0 or ab.passive_level(FallFromGraceData.PRIDE) > 0:
		var node: NecroSpell = ab.spells.nodes.get(FallFromGraceData.ID)  # The spell node (null if never ticked).
		print("[autotest] fall from grace: Lv%d%s dmg=%d (evolved %d, flare %d) boss=%d kills=%d %s | pride Lv%d" % [
			lvl, " EVOLVED" if ab.evolved.has(FallFromGraceData.ID) else "", int(ab.spells.damage_of(FallFromGraceData.ID)),
			int(st.get("dmg_" + FallFromGraceData.EVOLVED_SOURCE, 0.0)), int(st.get("dmg_" + FallFromGraceData.FLARE_SOURCE, 0.0)),
			int(st.get("bossdmg_" + FallFromGraceData.SOURCE, 0.0)) + int(st.get("bossdmg_" + FallFromGraceData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(FallFromGraceData.ID)), node.summary_extra() if node != null else "",
			ab.passive_level(FallFromGraceData.PRIDE)])
	var cls := "archfiend"
	if int(game.horde.class_levels.get(cls, 0)) > 0 or ab.passive_level(ArchfiendBehavior.CROWN) > 0:
		print("[autotest] archfiend: Lv %d%s, alive %d | dmg %d (archfiend=%d prince_of_hell=%d cleave=%d) | cleaves %d, hits %d, dreads %d | crown_of_horns Lv%d" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_archfiend", 0.0)) + int(st.get("dmg_prince_of_hell", 0.0)) + int(st.get("dmg_" + ArchfiendBehavior.CLEAVE_SOURCE, 0.0)),
			int(st.get("dmg_archfiend", 0.0)), int(st.get("dmg_prince_of_hell", 0.0)), int(st.get("dmg_" + ArchfiendBehavior.CLEAVE_SOURCE, 0.0)),
			int(st.get("archfiend_cleaves", 0.0)), int(st.get("archfiend_cleave_hits", 0.0)), int(st.get("prince_dreads", 0.0)),
			ab.passive_level(ArchfiendBehavior.CROWN)])
