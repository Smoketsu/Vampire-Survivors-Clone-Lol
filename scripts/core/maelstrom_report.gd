## MaelstromReport — the autotest summary lines of THE MAELSTROM and its rewards
## (Act X, the Black Tide's finale; GDD §15.0 "The Maelstrom (Act X phase 2)"
## and the rows after it). Read-only: it never changes the run.
##   stage_lines(): called from CorsairReport.print_lines() (only when the
##     Black Tide ran):
##     maelstrom          MaelstromDirector (the Heave, the raised ghost crew,
##                        the spectral longboats, the Ghost Bosun) and its log
##     maelstrom kinds    the ghost crew, the Ghost Bosun, the Sea Serpent's
##                        breaches (when any of them spawned)
##     vandermere         BossVandermere.summary_line() (when he fought)
##     black tide kraken  the kraken arms that surfaced in the Black Tide (when
##                        it ran)
##   item_lines(): called from Autotest.finish() on EVERY stage, each line only
##     when its item was used, so every other summary keeps its exact text:
##     anchor drop        Anchor Drop / Abyssal Mooring, Dead Reckoning, the
##                        Ghost Helmsman's innate
##     powder wraith      the Powder Wraith / Magazine Lord and Slow Match
class_name MaelstromReport
extends RefCounted


## The stage's lines (CorsairReport; the Black Tide ran this run).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var md := game.enemies.maelstrom  # The stage director (null off the Maelstrom).
	if md != null:
		print("[autotest] maelstrom: %s" % md.summary_line())
	var any := false
	for k: String in [MaelstromEnemyData.GHOST_DECKHAND, MaelstromEnemyData.GHOST_GUNNER, MaelstromEnemyData.GHOST_BOSUN, "corsair_serpent"]:
		any = any or int(st.get("spawned_" + k, 0.0)) > 0
	if any:
		print("[autotest] maelstrom kinds: ghost deckhands %d/%d, ghost gunners %d/%d (overboard %d) | ghost bosun %d/%d | sea serpents %d/%d, breaches %d (summon hits %d) | spectral longboats %d (sunk: see boarding)" % [
			int(st.get("spawned_ghost_deckhand", 0.0)), int(st.get("kill_ghost_deckhand", 0.0)),
			int(st.get("spawned_ghost_gunner", 0.0)), int(st.get("kill_ghost_gunner", 0.0)),
			int(st.get("overboard_ghost_deckhand", 0.0)) + int(st.get("overboard_ghost_gunner", 0.0)),
			int(st.get("spawned_ghost_bosun", 0.0)), int(st.get("kill_ghost_bosun", 0.0)),
			int(st.get("spawned_corsair_serpent", 0.0)), int(st.get("kill_corsair_serpent", 0.0)),
			int(st.get("sea_breaches", 0.0)), int(st.get("sea_breach_hits", 0.0)), int(st.get("boats_ghost_longboat", 0.0))])
	if game.enemies.boss is BossVandermere:
		print("[autotest] vandermere: %s" % BossVandermere.summary_line(st))
	if game.corsair != null and game.corsair.tide.running():
		print("[autotest] black tide kraken: arms surfaced %d" % game.corsair.tide.krakens)


## The rewards' lines (every stage; each only when its item was used).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities
	var lvl := ab.spell_level(AnchorDropData.ID)
	if lvl > 0 or ab.passive_level(AnchorDropData.DEAD_RECKONING) > 0:
		var node: NecroSpell = ab.spells.nodes.get(AnchorDropData.ID)  # The spell node (null if never ticked).
		print("[autotest] anchor drop: Lv%d%s dmg=%d (slam %d, shock %d, evolved %d, moored %d) boss=%d kills=%d %s | dead_reckoning Lv%d" % [
			lvl, " EVOLVED" if ab.evolved.has(AnchorDropData.ID) else "", int(ab.spells.damage_of(AnchorDropData.ID)),
			int(st.get("dmg_" + AnchorDropData.SOURCE, 0.0)), int(st.get("dmg_" + AnchorDropData.RING_SOURCE, 0.0)),
			int(st.get("dmg_" + AnchorDropData.EVOLVED_SOURCE, 0.0)), int(st.get("dmg_" + AnchorDropData.MOOR_SOURCE, 0.0)),
			int(st.get("bossdmg_" + AnchorDropData.SOURCE, 0.0)) + int(st.get("bossdmg_" + AnchorDropData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(AnchorDropData.ID)), node.summary_extra() if node != null else "",
			ab.passive_level(AnchorDropData.DEAD_RECKONING)])
	var cls := "powder_wraith"
	if int(game.horde.class_levels.get(cls, 0)) > 0 or ab.passive_level(PowderWraithBehavior.SLOW_MATCH) > 0:
		print("[autotest] powder wraith: Lv %d%s, alive %d | dmg %d (blade %d, keg %d, magazine_lord blade %d, keg %d) | kegs %d (foes hit %d, chained %d) | reforms %d | slow_match Lv%d" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_powder_wraith", 0.0)) + int(st.get("dmg_" + PowderWraithBehavior.SOURCE, 0.0)) + int(st.get("dmg_magazine_lord", 0.0)) + int(st.get("dmg_" + PowderWraithBehavior.EVOLVED_SOURCE, 0.0)),
			int(st.get("dmg_powder_wraith", 0.0)), int(st.get("dmg_" + PowderWraithBehavior.SOURCE, 0.0)),
			int(st.get("dmg_magazine_lord", 0.0)), int(st.get("dmg_" + PowderWraithBehavior.EVOLVED_SOURCE, 0.0)),
			int(st.get("powder_wraith_kegs", 0.0)), int(st.get("powder_wraith_keg_hits", 0.0)), int(st.get("magazine_lord_chains", 0.0)),
			int(st.get("powder_wraith_reforms", 0.0)), ab.passive_level(PowderWraithBehavior.SLOW_MATCH)])
