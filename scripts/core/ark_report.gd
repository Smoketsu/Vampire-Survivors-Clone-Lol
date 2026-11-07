## ArkReport — the autotest summary lines of THE ARK OF THE CONCORD and its
## rewards (Act IX, Stage 27; GDD §15.0 "The Ark of the Concord (Act IX phase
## 2)" and the rows after it). Read-only: it never changes the run.
##   stage_lines(): called from ConcordReport.print_lines() (only when the
##     Concord ran):
##     ark               ArkDirector (the tanks, the freed beasts, the vents,
##                       the Archon) and its event log
##     ark kinds         the Grey Overseers' pulses and shields, the Archon's
##                       beams, the freed beasts apart from the coalition
##                       (when any of them spawned)
##     harvester         BossHarvester.summary_line() (when it fought)
##   item_lines(): called from Autotest.finish() on EVERY stage, each line only
##     when its item was used, so every other summary keeps its exact text:
##     tractor beam      Tractor Beam / Abduction, Starseed, the Starborn's
##                       innate
##     ghost saucer      the Ghost Saucer / Black Mothership and Crop Circles
class_name ArkReport
extends RefCounted


## The stage's lines (ConcordReport; the Concord ran this run).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var ad := game.enemies.ark  # The stage director (null off the Ark).
	if ad != null:
		print("[autotest] ark: %s" % ad.summary_line())
		print("[autotest] ark events (%d): %s" % [ad.fired.size(), ", ".join(ad.fired)])
	var any := false
	for k: String in [ConcordEnemyData.GREY_OVERSEER, ArkEnemyData.ARCHON, ArkEnemyData.BEAST, ArkEnemyData.TANK, ArkEnemyData.VENT]:
		any = any or int(st.get("spawned_" + k, 0.0)) > 0
	if any:
		print("[autotest] ark kinds: grey overseer %d/%d, pulses %d (summons stunned %d), shields %d | luminous archon %d/%d, lances %d, halos %d (reflected into it: see beams) | freed beasts %d/%d (no turf heal; dmg to you %d, to summons %d, to the Concord %d) | tanks %d/%d | vents %d/%d" % [
			int(st.get("spawned_grey_overseer", 0.0)), int(st.get("kill_grey_overseer", 0.0)), int(st.get("overseer_pulses", 0.0)),
			int(st.get("overseer_pulse_stuns", 0.0)), int(st.get("overseer_shields", 0.0)),
			int(st.get("spawned_luminous_archon", 0.0)), int(st.get("kill_luminous_archon", 0.0)), int(st.get("archon_lances", 0.0)), int(st.get("archon_halos", 0.0)),
			int(st.get("spawned_vault_beast", 0.0)), int(st.get("kill_vault_beast", 0.0)),
			int(st.get("player_dmg_from_vault_beast", 0.0)), int(st.get("summon_dmg_from_vault_beast", 0.0)), int(st.get("ark_beast_bite_dmg", 0.0)),
			int(st.get("spawned_specimen_tank", 0.0)), int(st.get("kill_specimen_tank", 0.0)),
			int(st.get("spawned_reactor_vent", 0.0)), int(st.get("kill_reactor_vent", 0.0))])
	if game.enemies.boss is BossHarvester:
		print("[autotest] harvester: %s" % BossHarvester.summary_line(st))


## The rewards' lines (every stage; each only when its item was used).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities
	var lvl := ab.spell_level(TractorLiftData.ID)
	if lvl > 0 or ab.passive_level(TractorLiftData.STARSEED) > 0:
		var node: NecroSpell = ab.spells.nodes.get(TractorLiftData.ID)  # The spell node (null if never ticked).
		print("[autotest] tractor beam: Lv%d%s dmg=%d (slam %d, evolved %d, quake %d) boss=%d kills=%d %s | starseed Lv%d" % [
			lvl, " EVOLVED" if ab.evolved.has(TractorLiftData.ID) else "", int(ab.spells.damage_of(TractorLiftData.ID)),
			int(st.get("dmg_" + TractorLiftData.SOURCE, 0.0)), int(st.get("dmg_" + TractorLiftData.EVOLVED_SOURCE, 0.0)),
			int(st.get("dmg_" + TractorLiftData.QUAKE_SOURCE, 0.0)),
			int(st.get("bossdmg_" + TractorLiftData.SOURCE, 0.0)) + int(st.get("bossdmg_" + TractorLiftData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(TractorLiftData.ID)), node.summary_extra() if node != null else "",
			ab.passive_level(TractorLiftData.STARSEED)])
	var cls := GhostSaucerBehavior.CLASS_ID
	if int(game.horde.class_levels.get(cls, 0)) > 0 or ab.passive_level(GhostSaucerBehavior.CROP) > 0:
		print("[autotest] ghost saucer: Lv %d%s, alive %d | dmg %d (ghost_saucer=%d lift=%d black_mothership=%d lift=%d) | beams %d (foes hit %d) | lifts %d (slams %d) | crop_circles Lv%d" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_ghost_saucer", 0.0)) + int(st.get("dmg_" + GhostSaucerBehavior.LIFT_SOURCE, 0.0)) + int(st.get("dmg_black_mothership", 0.0)) + int(st.get("dmg_" + GhostSaucerBehavior.EVOLVED_LIFT_SOURCE, 0.0)),
			int(st.get("dmg_ghost_saucer", 0.0)), int(st.get("dmg_" + GhostSaucerBehavior.LIFT_SOURCE, 0.0)),
			int(st.get("dmg_black_mothership", 0.0)), int(st.get("dmg_" + GhostSaucerBehavior.EVOLVED_LIFT_SOURCE, 0.0)),
			int(st.get("ghost_saucer_beams", 0.0)), int(st.get("ghost_saucer_beam_hits", 0.0)),
			int(st.get("ghost_saucer_lifts", 0.0)), int(st.get("ghost_saucer_slams", 0.0)), ab.passive_level(GhostSaucerBehavior.CROP)])
