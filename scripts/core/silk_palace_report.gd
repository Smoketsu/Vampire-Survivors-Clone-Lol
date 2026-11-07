## SilkPalaceReport — the autotest summary lines of THE PALACE OF SILK AND ASH
## and its rewards (Act VI, Stage 17; GDD §15.0 "The Palace of Silk and Ash (Act
## VI phase 2)" and the rows after it). Read-only: it never changes the run.
##   stage_lines(): called from InfernoReport.print_lines() (only when the
##     Inferno ran):
##     silk palace        SilkPalaceDirector (the Hall of Mirrors' reflections,
##                        the Twin Succubi, the Lilim Witches, guests) and its
##                        event log
##     silk palace kinds  spawns / kills of the Lilim Witch and the twins (when
##                        any spawned)
##     lilith             BossLilith.summary_line() (when she fought)
##   item_lines(): called from Autotest.finish() on EVERY stage, each line only
##     when its item was used, so every other summary keeps its exact text:
##     temptation         Temptation / Unholy Desire (the Enthrall path),
##                        Velvet Chains, the Succubus Queen's Heartbreaker
##     succubus           the Succubus / the Lilim Matriarch and Sweet Surrender
##     faithless          Faithless (Act VI's counter-passive)
class_name SilkPalaceReport
extends RefCounted


## The stage's lines (InfernoReport; the Inferno ran this run).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var sd := game.enemies.silk_palace  # The stage director (null off the Palace).
	if sd != null:
		print("[autotest] silk palace: %s" % sd.summary_line())
	var any := false
	for k: String in SilkPalaceEnemyData.ENEMIES:
		any = any or int(st.get("spawned_" + k, 0.0)) > 0
	if any:
		print("[autotest] silk palace kinds: lilim witch %d/%d (curses %d, pits %d, portal rites %d, healed %d) | twins: naamah %d/%d, agrat %d/%d, rages %d, kisses %d (missed %d), kisses of pain %d (summon hits %d), dmg to you %d, to summons %d" % [
			int(st.get("spawned_" + SilkPalaceEnemyData.LILIM_WITCH, 0.0)), int(st.get("kill_" + SilkPalaceEnemyData.LILIM_WITCH, 0.0)),
			int(st.get("lilim_curses", 0.0)), int(st.get("lilim_pits", 0.0)), int(st.get("lilim_rites", 0.0)), int(st.get("lilim_healed", 0.0)),
			int(st.get("spawned_" + SilkPalaceEnemyData.TWIN_NAAMAH, 0.0)), int(st.get("kill_" + SilkPalaceEnemyData.TWIN_NAAMAH, 0.0)),
			int(st.get("spawned_" + SilkPalaceEnemyData.TWIN_AGRAT, 0.0)), int(st.get("kill_" + SilkPalaceEnemyData.TWIN_AGRAT, 0.0)),
			int(st.get("twin_rages", 0.0)), int(st.get("twin_kisses", 0.0)), int(st.get("twin_kiss_missed", 0.0)),
			int(st.get("twin_pains", 0.0)), int(st.get("twin_pain_hits", 0.0)),
			int(st.get("player_dmg_from_" + SilkPalaceEnemyData.HEARTBREAK_SOURCE, 0.0) + st.get("player_dmg_from_" + SilkPalaceEnemyData.TWIN_NAAMAH, 0.0) + st.get("player_dmg_from_" + SilkPalaceEnemyData.TWIN_AGRAT, 0.0)),
			int(st.get("summon_dmg_from_" + SilkPalaceEnemyData.HEARTBREAK_SOURCE, 0.0) + st.get("summon_dmg_from_" + SilkPalaceEnemyData.TWIN_NAAMAH, 0.0) + st.get("summon_dmg_from_" + SilkPalaceEnemyData.TWIN_AGRAT, 0.0))])
	if game.enemies.boss is BossLilith:
		print("[autotest] lilith: %s" % BossLilith.summary_line(st))


## The rewards' lines (every stage; each only when its item was used).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level("tempt")  # 0 = never learned.
	var chains := ab.passive_level(TemptData.VELVET_CHAINS)
	if lvl > 0 or chains > 0:
		var node: NecroSpell = ab.spells.nodes.get("tempt")  # The spell node (null if never ticked).
		print("[autotest] temptation: Lv%d%s dmg=%d (unholy desire %d, bursts %d, heartbreaks %d) kills=%d %s | velvet_chains Lv%d (charm x%.2f, thrall dmg x%.2f) | heartbreaker %.2f" % [
			lvl, " EVOLVED" if ab.evolved.has("tempt") else "", int(ab.spells.damage_of("tempt")),
			int(st.get("dmg_" + TemptData.EVOLVED_SOURCE, 0.0)), int(st.get("dmg_" + TemptData.BURST_SOURCE, 0.0)),
			int(st.get("dmg_" + TemptData.HEARTBREAK_SOURCE, 0.0)), int(ab.spells.kills_of("tempt")),
			node.summary_extra() if node != null else "", chains,
			1.0 + ab.passive_value(TemptData.VELVET_CHAINS, TemptData.CHAIN_TIME_KEY), 1.0 + ab.passive_value(TemptData.VELVET_CHAINS, TemptData.CHAIN_POWER_KEY),
			game.character.innate_value(TemptData.HEARTBREAK_KEY)])
	var cls := "bound_succubus"
	if int(game.horde.class_levels.get(cls, 0)) > 0 or ab.passive_level(BoundSuccubusBehavior.SURRENDER) > 0:
		print("[autotest] succubus: Lv %d%s, alive %d | dmg %d (bound_succubus=%d lilim_matriarch=%d thralls=%d) | charms %d (foes turned %d, missed %d) | thralls slain %d, returned %d | sweet_surrender Lv%d" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_bound_succubus", 0.0)) + int(st.get("dmg_lilim_matriarch", 0.0)) + int(st.get("dmg_" + TemptData.CLASS_SOURCE, 0.0)),
			int(st.get("dmg_bound_succubus", 0.0)), int(st.get("dmg_lilim_matriarch", 0.0)), int(st.get("dmg_" + TemptData.CLASS_SOURCE, 0.0)),
			int(st.get("succubus_charms", 0.0)), int(st.get("succubus_charm_foes", 0.0)), int(st.get("succubus_charm_missed", 0.0)),
			int(st.get("enthrall_slain", 0.0)), int(st.get("enthrall_returned", 0.0)), ab.passive_level(BoundSuccubusBehavior.SURRENDER)])
	var faith := ab.passive_level(InfernoRulesData.FAITHLESS)
	if faith > 0:
		print("[autotest] faithless: Lv%d (charms on summons x%.2f)" % [faith, 1.0 - ab.passive_value(InfernoRulesData.FAITHLESS, InfernoRulesData.FAITHLESS_KEY)])
