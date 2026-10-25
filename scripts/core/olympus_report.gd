## OlympusReport — the autotest summary lines of MOUNT OLYMPUS, THE PANTHEON
## TRIAL and its rewards (Act IV, Stage 11; GDD §15.0 "Mount Olympus (Act IV
## phase 2)" and the rows after it). Read-only: it never changes the run.
##   stage_lines(): called from PantheonReport (only when the Pantheon ran):
##     olympus          OlympusDirector (each god's arrival and fall, the
##                      groves, the trial) and its event log
##     pantheon trial   the gods' specials: Ares (war-cries, enemies buffed,
##                      charges, impaled), Artemis (volleys, hounds, teleports),
##                      Poseidon (floods, tridents, serpents) (when any came)
##     olympus kinds    Centaur Archers, Amazons (leaps, caught), Gorgons
##                      (gazes, summons petrified), sea serpents (when any spawned)
##     wrath called     the gods' strikes through DivineWrath.strike() (when any)
##     zeus             BossZeus.summary_line() (when he fought)
##   item_lines(): called from Autotest.finish() on EVERY stage, each line only
##     when its item was used, so every other summary keeps its exact text:
##     stolen thunder   Stolen Thunder / Gigantomachy, Titan's Blood
##     grounded bones   the Act IV counter-passive (when owned)
class_name OlympusReport
extends RefCounted


## The stage's lines (PantheonReport; the Pantheon ran this run).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var od := game.enemies.olympus  # The stage director (null off Olympus).
	if od != null:
		print("[autotest] olympus: %s" % od.summary_line())
		print("[autotest] olympus events (%d): %s" % [od.fired.size(), ", ".join(od.fired)])
	var gods := 0  # Gods that came (also forced ones).
	for k: String in OlympusEnemyData.GODS:
		gods += int(st.get("spawned_" + k, 0.0))
	if gods > 0:
		print("[autotest] pantheon trial: ares %d/%d (ttk %ds): war-cries %d (enemies buffed %d), charges %d (summon hits %d, impaled on blockers %d) | artemis %d/%d (ttk %ds): volleys %d (arrows %d), hound calls %d (hounds %d), teleports %d | poseidon %d/%d (ttk %ds): floods %d, tridents %d (hits %d), serpents %d" % [
			int(st.get("spawned_ares", 0.0)), int(st.get("olympus_god_kills_ares", 0.0)), int(st.get("olympus_god_ttk_ares", 0.0)),
			int(st.get("ares_warcries", 0.0)), int(st.get("ares_buffed", 0.0)), int(st.get("ares_charges", 0.0)), int(st.get("ares_charge_hits", 0.0)), int(st.get("ares_impaled", 0.0)),
			int(st.get("spawned_artemis", 0.0)), int(st.get("olympus_god_kills_artemis", 0.0)), int(st.get("olympus_god_ttk_artemis", 0.0)),
			int(st.get("artemis_volleys", 0.0)), int(st.get("artemis_arrows", 0.0)), int(st.get("artemis_hound_calls", 0.0)), int(st.get("artemis_hounds", 0.0)), int(st.get("artemis_teleports", 0.0)),
			int(st.get("spawned_poseidon", 0.0)), int(st.get("olympus_god_kills_poseidon", 0.0)), int(st.get("olympus_god_ttk_poseidon", 0.0)),
			int(st.get("poseidon_floods", 0.0)), int(st.get("poseidon_tridents", 0.0)), int(st.get("poseidon_trident_hits", 0.0)), int(st.get("poseidon_serpents", 0.0))])
	var kinds := 0  # Olympus kinds that came.
	for k: String in [OlympusEnemyData.CENTAUR, OlympusEnemyData.AMAZON, OlympusEnemyData.GORGON, OlympusEnemyData.SERPENT]:
		kinds += int(st.get("spawned_" + k, 0.0))
	if kinds > 0:
		print("[autotest] olympus kinds: centaurs %d (arrow dmg to you %d, summons %d) | amazons %d: leaps %d (caught by blockers %d, summon hits %d, you hit %d) | gorgons %d: gazes %d (summons petrified %d, %.1f s of stone; you hit %d) | sea serpents %d: lunges %d (hits %d)" % [
			int(st.get("spawned_" + OlympusEnemyData.CENTAUR, 0.0)), int(st.get("player_dmg_from_" + OlympusEnemyData.CENTAUR, 0.0)), int(st.get("summon_dmg_from_" + OlympusEnemyData.CENTAUR, 0.0)),
			int(st.get("spawned_" + OlympusEnemyData.AMAZON, 0.0)), int(st.get("amazon_leaps", 0.0)), int(st.get("amazon_leaps_caught", 0.0)),
			int(st.get("amazon_land_hits", 0.0)), int(st.get("amazon_land_player_hits", 0.0)),
			int(st.get("spawned_" + OlympusEnemyData.GORGON, 0.0)), int(st.get("gorgon_gazes", 0.0)), int(st.get("gorgon_petrified", 0.0)),
			float(st.get("summon_stunned_seconds", 0.0)), int(st.get("gorgon_gaze_player_hits", 0.0)),
			int(st.get("spawned_" + OlympusEnemyData.SERPENT, 0.0)), int(st.get("serpent_lunges", 0.0)), int(st.get("serpent_lunge_hits", 0.0))])
	var called := 0  # Strikes the gods asked of the wrath.
	for k: String in PantheonRulesData.WRATH_KINDS:
		called += int(st.get("wrath_called_" + k, 0.0))
	if called > 0:
		print("[autotest] wrath called: waves %d, lightning %d, fissures %d (DivineWrath.strike())" % [
			int(st.get("wrath_called_waves", 0.0)), int(st.get("wrath_called_lightning", 0.0)), int(st.get("wrath_called_fissures", 0.0))])
	if game.enemies.boss is BossZeus:
		print("[autotest] zeus: %s" % BossZeus.summary_line(st))


## The rewards' lines (every stage; each only when its item was used).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities
	var lvl := ab.spell_level(StolenThunderData.ID)
	if lvl > 0 or ab.passive_level(StolenThunderData.TITANS_BLOOD) > 0:
		var node: NecroSpell = ab.spells.nodes.get(StolenThunderData.ID)  # The spell node (null if never ticked).
		print("[autotest] stolen thunder: Lv%d%s dmg=%d (evolved %d, thunderclaps %d) boss=%d kills=%d %s | titans_blood Lv%d" % [
			lvl, " EVOLVED" if ab.evolved.has(StolenThunderData.ID) else "", int(ab.spells.damage_of(StolenThunderData.ID)),
			int(st.get("dmg_" + StolenThunderData.EVOLVED_SOURCE, 0.0)), int(st.get("dmg_" + StolenThunderData.CLAP_SOURCE, 0.0)),
			int(st.get("bossdmg_" + StolenThunderData.SOURCE, 0.0)) + int(st.get("bossdmg_" + StolenThunderData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(StolenThunderData.ID)), node.summary_extra() if node != null else "",
			ab.passive_level(StolenThunderData.TITANS_BLOOD)])
	var gb := ab.passive_level(PantheonRulesData.GROUNDED_BONES)
	if gb > 0:
		var mult := game.pantheon.wrath.grounded_mult(game.player) if game.pantheon != null else 1.0
		print("[autotest] grounded bones: Lv%d (lightning and wave damage x%.2f) | wrath dmg to summons %d, to you %d | summon stuns %d" % [
			gb, mult, int(st.get("summon_dmg_from_" + DivineWrath.SRC_BOLT, 0.0)) + int(st.get("summon_dmg_from_" + DivineWrath.SRC_WAVE, 0.0)),
			int(st.get("player_dmg_from_" + DivineWrath.SRC_BOLT, 0.0)) + int(st.get("player_dmg_from_" + DivineWrath.SRC_WAVE, 0.0)),
			int(st.get("summon_stuns", 0.0))])
