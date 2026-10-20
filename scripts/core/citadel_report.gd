## CitadelReport — the autotest summary lines of THE IRON CITADEL and its rewards
## (Act III, Stage 9; GDD §15.0 "The Iron Citadel (Act III phase 2)" and the
## rows after it). Read-only: it never changes the run.
##   stage_lines(): called from EmpireReport (only when the Empire ran):
##     citadel          CitadelDirector (gates, lockdowns, garrisons, lasers,
##                      guns, turrets, guests, objective Soul Ash)
##     citadel events   the director's event log
##     citadel kinds    the Valkyrie Duelists' lunges, the Sentry Turrets, the
##                      generators, Valkyrie 2.0 (when any spawned)
##     ranged share     the share of Empire spawns that attack from range (the
##                      proposal's ~60% target)
##     deus ex machina  BossDeusExMachina.summary_line() (when it fought)
##   item_lines(): called from Autotest.finish() on EVERY stage, each line only
##     when its item was used, so every other summary keeps its exact text:
##     scrap swarm      Scrap Swarm / Deathless Swarm and Machine Soul
##     iron revenant    the Iron Revenant / Deus Revenant and Recoil Frame
class_name CitadelReport
extends RefCounted


## The stage's lines (EmpireReport; the Empire ran this run).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var cd := game.enemies.citadel  # The stage director (null off the Citadel).
	if cd != null:
		print("[autotest] citadel: %s" % cd.summary_line())
		print("[autotest] citadel events (%d): %s" % [cd.fired.size(), ", ".join(cd.fired)])
	if int(st.get("spawned_" + CitadelEnemyData.DUELIST, 0.0)) > 0 or int(st.get("spawned_" + CitadelEnemyData.TURRET, 0.0)) > 0 \
			or int(st.get("valkyrie_spawned", 0.0)) > 0:
		print("[autotest] citadel kinds: duelists %d (lunges %d, blocked %d, reached you %d, summons sliced %d) | turrets %d (bursts %d, bolts %d) | valkyrie 2.0 %d, killed %d (ttk %ds): dashes %d (blocked %d, you hit %d), bashes %d (you hit %d), storms %d (you hit %d), summon hits %d" % [
			int(st.get("spawned_" + CitadelEnemyData.DUELIST, 0.0)), int(st.get("duelist_lunges", 0.0)), int(st.get("duelist_lunges_blocked", 0.0)),
			int(st.get("duelist_lunges_hit", 0.0)), int(st.get("duelist_lunge_slices", 0.0)),
			int(st.get("spawned_" + CitadelEnemyData.TURRET, 0.0)), int(st.get("sentry_bursts", 0.0)), int(st.get("sentry_bolts", 0.0)),
			int(st.get("valkyrie_spawned", 0.0)), int(st.get("valkyrie_kills", 0.0)), int(st.get("valkyrie_ttk", 0.0)),
			int(st.get("valkyrie_dashes", 0.0)), int(st.get("valkyrie_dashes_blocked", 0.0)), int(st.get("valkyrie_dash_player_hits", 0.0)),
			int(st.get("valkyrie_bashes", 0.0)), int(st.get("valkyrie_bash_player_hits", 0.0)),
			int(st.get("valkyrie_storms", 0.0)), int(st.get("valkyrie_storm_player_hits", 0.0)), int(st.get("valkyrie_summon_hits", 0.0))])
	if cd != null:
		print("[autotest] ranged share: %s" % _ranged_share(st))
	if game.enemies.boss is BossDeusExMachina:
		print("[autotest] deus ex machina: %s" % BossDeusExMachina.summary_line(st))


## "R% ranged (r of n spawns; melee m)": the Empire kinds that spawned, split by
## whether they attack from range (behaviour "ranged", or a turret's kit).
static func _ranged_share(st: Dictionary) -> String:
	var ranged := 0
	var melee := 0
	for table: Dictionary in [EmpireEnemyData.ENEMIES, WastesEnemyData.ENEMIES, AssemblyEnemyData.ENEMIES, CitadelEnemyData.ENEMIES]:
		for k: String in table:
			var row: Dictionary = table[k]
			if bool(row.get("is_structure", false)) and String(row.get("kit", "")) != "sentry":
				continue  # Generators, plates, drones: not soldiers.
			var n := int(st.get("spawned_" + k, 0.0))
			if String(row["behavior"]) == "ranged" or String(row.get("kit", "")) == "sentry":
				ranged += n
			else:
				melee += n
	var total := maxi(1, ranged + melee)
	return "%.0f%% ranged (%d of %d spawns; melee %d)" % [100.0 * float(ranged) / float(total), ranged, ranged + melee, melee]


## The rewards' lines (every stage; each only when its item was used).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities
	var lvl := ab.spell_level(ScrapSwarmData.ID)
	if lvl > 0 or ab.passive_level(ScrapSwarmData.MACHINE_SOUL) > 0:
		var node: NecroSpell = ab.spells.nodes.get(ScrapSwarmData.ID)  # The spell node (null if never ticked).
		print("[autotest] scrap swarm: Lv%d%s dmg=%d (evolved %d) boss=%d kills=%d %s | machine_soul Lv%d bonus_dmg=%d" % [
			lvl, " EVOLVED" if ab.evolved.has(ScrapSwarmData.ID) else "", int(ab.spells.damage_of(ScrapSwarmData.ID)),
			int(st.get("dmg_" + ScrapSwarmData.EVOLVED_SOURCE, 0.0)), int(st.get("bossdmg_" + ScrapSwarmData.SOURCE, 0.0)) + int(st.get("bossdmg_" + ScrapSwarmData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(ScrapSwarmData.ID)), node.summary_extra() if node != null else "",
			ab.passive_level(ScrapSwarmData.MACHINE_SOUL), int(st.get("machine_soul_bonus_dmg", 0.0))])
	var cls := "iron_revenant"
	if int(game.horde.class_levels.get(cls, 0)) > 0 or ab.passive_level("recoil_frame") > 0:
		print("[autotest] iron revenant: Lv %d%s, alive %d | dmg %d (iron_revenant=%d deus_revenant=%d missiles=%d) | bursts %d, shells %d, salvos %d, missiles %d | recoil_frame Lv%d" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_iron_revenant", 0.0)) + int(st.get("dmg_deus_revenant", 0.0)) + int(st.get("dmg_" + RevenantBehavior.MISSILE_SOURCE, 0.0)),
			int(st.get("dmg_iron_revenant", 0.0)), int(st.get("dmg_deus_revenant", 0.0)), int(st.get("dmg_" + RevenantBehavior.MISSILE_SOURCE, 0.0)),
			int(st.get("revenant_bursts", 0.0)), int(st.get("revenant_shells", 0.0)), int(st.get("revenant_salvos", 0.0)), int(st.get("revenant_missiles", 0.0)),
			ab.passive_level("recoil_frame")])
