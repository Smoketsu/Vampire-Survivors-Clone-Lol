## CastleSanguisReport — the autotest summary lines of CASTLE SANGUIS and its
## rewards (Act VII, Stage 21; GDD §15.0 "Castle Sanguis (Act VII phase 2)" and
## the rows after it). Read-only: it never changes the run.
##   stage_lines(): called from CourtReport.print_lines() (only when the Court
##     ran):
##     castle sanguis        CastleSanguisDirector (the Banquet's fountains,
##                           guests, objective Soul Ash) and its event log
##     castle sanguis kinds  the Chiropterans' shrieks and stuns, the
##                           Chiropteran King's carry-offs, shrieks, colony and
##                           time to kill, the Blood Bearers (when any spawned)
##     carmilla              BossCarmilla.summary_line() (when she fought)
##   item_lines(): called from Autotest.finish() on EVERY stage, each line only
##     when its item was used, so every other summary keeps its exact text:
##     night swarm           Night Swarm / Nocturne, Old Blood, the Dhampir's
##                           Half-Blood
##     blood spawn           the Blood Spawn / Nosferatu and Thirst Eternal
class_name CastleSanguisReport
extends RefCounted


## The stage's lines (CourtReport; the Court ran this run).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var cd := game.enemies.castle_sanguis  # The stage director (null off Castle Sanguis).
	if cd != null:
		print("[autotest] castle sanguis: %s" % cd.summary_line())
		print("[autotest] castle sanguis events (%d): %s" % [cd.fired.size(), ", ".join(cd.fired)])
	var any := false
	for k: String in [CastleSanguisEnemyData.CHIROPTERAN, CastleSanguisEnemyData.KING, CastleSanguisEnemyData.BEARER]:
		any = any or int(st.get("spawned_" + k, 0.0)) > 0
	if any:
		print("[autotest] castle sanguis kinds: chiropteran %d/%d, shrieks %d, summons stunned %d, you hit %d | chiropteran king %d, killed %d (ttk %ds): carry-offs %d (summons carried %d, dropped %d, %d px on average), shrieks %d (stuns %d), you hit %d, aloft blows grazed %d, colony bats %d | blood bearers %d/%d" % [
			int(st.get("spawned_" + CastleSanguisEnemyData.CHIROPTERAN, 0.0)), int(st.get("kill_" + CastleSanguisEnemyData.CHIROPTERAN, 0.0)),
			int(st.get("chiropteran_shrieks", 0.0)), int(st.get("chiropteran_stuns", 0.0)), int(st.get("chiropteran_shriek_player_hits", 0.0)),
			int(st.get("king_spawned", 0.0)), int(st.get("king_kills", 0.0)), int(st.get("king_ttk", 0.0)),
			int(st.get("king_grabs", 0.0)), int(st.get("king_carried", 0.0)), int(st.get("king_dropped", 0.0)),
			int(float(st.get("king_drop_px", 0.0)) / maxf(1.0, float(st.get("king_dropped", 0.0)))),
			int(st.get("king_shrieks", 0.0)), int(st.get("king_stuns", 0.0)), int(st.get("king_player_hits", 0.0)),
			int(st.get("king_aloft_grazed", 0.0)), int(st.get("king_swarm", 0.0)),
			int(st.get("spawned_" + CastleSanguisEnemyData.BEARER, 0.0)), int(st.get("kill_" + CastleSanguisEnemyData.BEARER, 0.0))])
	if game.enemies.boss is BossCarmilla:
		print("[autotest] carmilla: %s" % BossCarmilla.summary_line(st))


## The rewards' lines (every stage; each only when its item was used).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities
	var lvl := ab.spell_level(NightSwarmData.ID)
	if lvl > 0 or ab.passive_level(NightSwarmData.OLD_BLOOD) > 0:
		var node: NecroSpell = ab.spells.nodes.get(NightSwarmData.ID)  # The spell node (null if never ticked).
		print("[autotest] night swarm: Lv%d%s dmg=%d (evolved %d, leaps %d) boss=%d kills=%d %s | old blood Lv%d" % [
			lvl, " EVOLVED" if ab.evolved.has(NightSwarmData.ID) else "", int(ab.spells.damage_of(NightSwarmData.ID)),
			int(st.get("dmg_" + NightSwarmData.EVOLVED_SOURCE, 0.0)), int(st.get("dmg_" + NightSwarmData.CHAIN_SOURCE, 0.0)),
			int(st.get("bossdmg_" + NightSwarmData.SOURCE, 0.0)) + int(st.get("bossdmg_" + NightSwarmData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(NightSwarmData.ID)), node.summary_extra() if node != null else "",
			ab.passive_level(NightSwarmData.OLD_BLOOD)])
	var cls := "blood_spawn"
	if int(game.horde.class_levels.get(cls, 0)) > 0 or ab.passive_level(BloodSpawnBehavior.THIRST) > 0:
		print("[autotest] blood spawn: Lv %d%s, alive %d | dmg %d (blood_spawn=%d nosferatu=%d) | drinks %d, healed %d, spills %d (%d HP) | thirst_eternal Lv%d (summon healing %d)" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_blood_spawn", 0.0)) + int(st.get("dmg_nosferatu", 0.0)),
			int(st.get("dmg_blood_spawn", 0.0)), int(st.get("dmg_nosferatu", 0.0)),
			int(st.get("blood_spawn_drinks", 0.0)), int(st.get("blood_spawn_healed", 0.0)),
			int(st.get("nosferatu_spills", 0.0)), int(st.get("nosferatu_spill_heal", 0.0)),
			ab.passive_level(BloodSpawnBehavior.THIRST), int(st.get("summon_healing", 0.0))])
