## LibertyHeightsReport — the autotest summary lines of LIBERTY HEIGHTS and its
## rewards (Act VIII, Stage 24; GDD §15.0 "Liberty Heights (Act VIII phase 2)"
## and the rows after it). Read-only: it never changes the run.
##   stage_lines(): called from CityReport.print_lines() (only when the Last
##     Line ran):
##     liberty heights        LibertyHeightsDirector (the zone Supers and their
##                            fall, guests, cracks) and its event log
##     liberty heights supers Atlas's throws, Aurora's blasts and falls,
##                            Nightjar's grapples and landings, the Conscripts
##                            (when any of them spawned)
##     paragon                BossParagon.summary_line() (when he fought)
##   item_lines(): called from Autotest.finish() on EVERY stage, each line only
##     when its item was used, so every other summary keeps its exact text:
##     heros fist             Hero's Fist / Doomsday, Secret Identity, the
##                            Revenant Heroine's Back From the Dead
##     fallen hero            the Fallen Hero / Black Paragon and Origin Story
class_name LibertyHeightsReport
extends RefCounted


## The stage's lines (CityReport; the Last Line ran this run).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var lh := game.enemies.liberty_heights  # The stage director (null off Liberty Heights).
	if lh != null:
		print("[autotest] liberty heights: %s" % lh.summary_line())
		print("[autotest] liberty heights events (%d): %s" % [lh.fired.size(), ", ".join(lh.fired)])
	var any := false
	for k: String in [CityEnemyData.ATLAS, CityEnemyData.AURORA, CityEnemyData.NIGHTJAR, LibertyHeightsEnemyData.CONSCRIPT]:
		any = any or int(st.get("spawned_" + k, 0.0)) > 0
	if any:
		var to_you := 0
		var to_summons := 0
		for tag: String in CityEnemyData.SUPER_TAGS:
			to_you += int(st.get("player_dmg_from_" + tag, 0.0))
			to_summons += int(st.get("summon_dmg_from_" + tag, 0.0))
		print("[autotest] liberty heights supers: atlas %d/%d, throws %d (wrecks lifted %d, cars %d, landed as wrecks %d, dropped when stunned %d) | aurora %d/%d, volleys %d, falls %d, aloft blows grazed %d | nightjar %d/%d, grapples %d (reeled %d, %d px on average), landings %d, strikes %d, aloft blows grazed %d | specials' dmg to you %d, to summons %d | conscripts %d/%d | wrecks removed %d" % [
			int(st.get("spawned_atlas", 0.0)), int(st.get("kill_atlas", 0.0)), int(st.get("atlas_throws", 0.0)),
			int(st.get("atlas_lifts_wreck", 0.0)), int(st.get("atlas_lifts_car", 0.0)), int(st.get("atlas_wrecks_landed", 0.0)), int(st.get("atlas_dropped", 0.0)),
			int(st.get("spawned_aurora", 0.0)), int(st.get("kill_aurora", 0.0)), int(st.get("aurora_blasts", 0.0)), int(st.get("aurora_falls", 0.0)), int(st.get("aurora_aloft_grazed", 0.0)),
			int(st.get("spawned_nightjar", 0.0)), int(st.get("kill_nightjar", 0.0)), int(st.get("nightjar_grapples", 0.0)), int(st.get("nightjar_reeled", 0.0)),
			int(float(st.get("nightjar_reel_px", 0.0)) / maxf(1.0, float(st.get("nightjar_landings", 0.0)))),
			int(st.get("nightjar_landings", 0.0)), int(st.get("nightjar_strikes", 0.0)), int(st.get("nightjar_aloft_grazed", 0.0)),
			to_you, to_summons,
			int(st.get("spawned_conscript", 0.0)), int(st.get("kill_conscript", 0.0)),
			game.arena.city_blocks.wrecks_removed if game.arena.city_blocks != null else 0])
	if game.enemies.boss is BossParagon:
		print("[autotest] paragon: %s" % BossParagon.summary_line(st))


## The rewards' lines (every stage; each only when its item was used).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities
	var lvl := ab.spell_level(HerosFistData.ID)
	if lvl > 0 or ab.passive_level(HerosFistData.SECRET_IDENTITY) > 0:
		var node: NecroSpell = ab.spells.nodes.get(HerosFistData.ID)  # The spell node (null if never ticked).
		print("[autotest] heros fist: Lv%d%s dmg=%d (fling %d, evolved %d, craters %d) boss=%d kills=%d %s | secret identity Lv%d" % [
			lvl, " EVOLVED" if ab.evolved.has(HerosFistData.ID) else "", int(ab.spells.damage_of(HerosFistData.ID)),
			int(st.get("dmg_" + HerosFistData.FLING_SOURCE, 0.0)), int(st.get("dmg_" + HerosFistData.EVOLVED_SOURCE, 0.0)),
			int(st.get("dmg_" + HerosFistData.CRATER_SOURCE, 0.0)),
			int(st.get("bossdmg_" + HerosFistData.SOURCE, 0.0)) + int(st.get("bossdmg_" + HerosFistData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(HerosFistData.ID)), node.summary_extra() if node != null else "",
			ab.passive_level(HerosFistData.SECRET_IDENTITY)])
	var cls := "fallen_hero"
	if int(game.horde.class_levels.get(cls, 0)) > 0 or ab.passive_level(FallenHeroBehavior.ORIGIN) > 0:
		print("[autotest] fallen hero: Lv %d%s, alive %d | dmg %d (fallen_hero=%d slam=%d black_paragon=%d slam=%d) | slams %d (hits %d, chained %d, stuns %d) | origin_story Lv%d" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_fallen_hero", 0.0)) + int(st.get("dmg_" + FallenHeroBehavior.SOURCE, 0.0)) + int(st.get("dmg_black_paragon", 0.0)) + int(st.get("dmg_" + FallenHeroBehavior.EVOLVED_SOURCE, 0.0)),
			int(st.get("dmg_fallen_hero", 0.0)), int(st.get("dmg_" + FallenHeroBehavior.SOURCE, 0.0)),
			int(st.get("dmg_black_paragon", 0.0)), int(st.get("dmg_" + FallenHeroBehavior.EVOLVED_SOURCE, 0.0)),
			int(st.get("fallen_hero_slams", 0.0)), int(st.get("fallen_hero_slam_hits", 0.0)), int(st.get("fallen_hero_chains", 0.0)),
			int(st.get("black_paragon_stuns", 0.0)), ab.passive_level(FallenHeroBehavior.ORIGIN)])
