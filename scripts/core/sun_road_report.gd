## SunRoadReport — the autotest summary lines of THE ROAD TO THE SUN and its
## rewards (Act V, Stage 15; GDD §15.0 "The Road to the Sun (Act V phase 2)" and
## the rows after it). Read-only: it never changes the run.
##   stage_lines(): called from ShogunateReport (only when the Shogunate ran):
##     sun road         SunRoadDirector (guests, objective Soul Ash) and its
##                      event log
##     sun road kinds   the Sōhei's sweeps, the Kitsune's conjurings and her
##                      fox-fire illusions (wasted blows, how they were
##                      revealed), the Kirin (attacks, hits, time to kill)
##                      (when any spawned)
##     amaterasu        BossAmaterasu.summary_line() (when she fought) and the
##                      Sun's Course's sky override
##   item_lines(): called from Autotest.finish() on EVERY stage, each line only
##     when its item was used, so every other summary keeps its exact text:
##     black sun        Black Sun / Eclipse of Heaven, Stolen Dawn, the Shrine
##                      Maiden of Night's Night Prayer
##     bound oni        the Bound Oni / the Oni Lord and Oni's Resolve
class_name SunRoadReport
extends RefCounted


## The stage's lines (ShogunateReport; the Shogunate ran this run).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var sd := game.enemies.sun_road  # The stage director (null off the Road to the Sun).
	if sd != null:
		print("[autotest] sun road: %s" % sd.summary_line())
		print("[autotest] sun road events (%d): %s" % [sd.fired.size(), ", ".join(sd.fired)])
	var any := false
	for k: String in [SunRoadEnemyData.SOHEI, SunRoadEnemyData.KITSUNE, SunRoadEnemyData.FOX_FIRE, SunRoadEnemyData.KIRIN]:
		any = any or int(st.get("spawned_" + k, 0.0)) > 0
	if any:
		print("[autotest] sun road kinds: sohei %d/%d, sweeps %d (summon hits %d, you hit %d) | kitsune %d/%d, conjurings %d, illusions %d (wasted blows %d; revealed: light %d, area %d, faded %d, caster %d, replaced %d) | kirin %d, killed %d (ttk %ds): gallops %d, horns %d, you hit %d, summon hits %d, halo ticks %d" % [
			int(st.get("spawned_" + SunRoadEnemyData.SOHEI, 0.0)), int(st.get("kill_" + SunRoadEnemyData.SOHEI, 0.0)),
			int(st.get("sohei_sweeps", 0.0)), int(st.get("sohei_sweep_summon_hits", 0.0)), int(st.get("sohei_sweep_player_hits", 0.0)),
			int(st.get("spawned_" + SunRoadEnemyData.KITSUNE, 0.0)), int(st.get("kill_" + SunRoadEnemyData.KITSUNE, 0.0)),
			int(st.get("kitsune_conjures", 0.0)), int(st.get("fox_fire_conjured", 0.0)), int(st.get("fox_fire_wasted_hits", 0.0)),
			int(st.get("fox_fire_revealed_light", 0.0)), int(st.get("fox_fire_revealed_area", 0.0)), int(st.get("fox_fire_revealed_faded", 0.0)),
			int(st.get("fox_fire_revealed_caster", 0.0)), int(st.get("fox_fire_revealed_replaced", 0.0)),
			int(st.get("kirin_spawned", 0.0)), int(st.get("kirin_kills", 0.0)), int(st.get("kirin_ttk", 0.0)),
			int(st.get("kirin_gallops", 0.0)), int(st.get("kirin_horns", 0.0)), int(st.get("kirin_player_hits", 0.0)),
			int(st.get("kirin_summon_hits", 0.0)), int(st.get("kirin_halo_ticks", 0.0))])
	if game.enemies.boss is BossAmaterasu:
		print("[autotest] amaterasu: %s" % BossAmaterasu.summary_line(st))
		print("[autotest] amaterasu sky: override changes %d, override at the end %s, phase at the end %s" % [
			int(st.get("sun_overrides", 0.0)), str(not game.shogunate.sun.override.is_empty()),
			ShogunateRulesData.PHASE_NAMES[game.shogunate.sun.phase()]])


## The rewards' lines (every stage; each only when its item was used).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities
	var lvl := ab.spell_level(BlackSunData.ID)
	if lvl > 0 or ab.passive_level(BlackSunData.STOLEN_DAWN) > 0:
		var node: NecroSpell = ab.spells.nodes.get(BlackSunData.ID)  # The spell node (null if never ticked).
		print("[autotest] black sun: Lv%d%s dmg=%d (evolved %d, corona %d) boss=%d kills=%d %s | stolen_dawn Lv%d" % [
			lvl, " EVOLVED" if ab.evolved.has(BlackSunData.ID) else "", int(ab.spells.damage_of(BlackSunData.ID)),
			int(st.get("dmg_" + BlackSunData.EVOLVED_SOURCE, 0.0)), int(st.get("dmg_" + BlackSunData.CORONA_SOURCE, 0.0)),
			int(st.get("bossdmg_" + BlackSunData.SOURCE, 0.0)) + int(st.get("bossdmg_" + BlackSunData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(BlackSunData.ID)), node.summary_extra() if node != null else "",
			ab.passive_level(BlackSunData.STOLEN_DAWN)])
	var cls := "bound_oni"
	if int(game.horde.class_levels.get(cls, 0)) > 0 or ab.passive_level(OniBehavior.RESOLVE) > 0:
		print("[autotest] bound oni: Lv %d%s, alive %d | dmg %d (bound_oni=%d oni_lord=%d smash=%d quake=%d) | smashes %d, hits %d, stuns %d, quakes %d (hits %d) | onis_resolve Lv%d, stun s shrugged off %d" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_bound_oni", 0.0)) + int(st.get("dmg_oni_lord", 0.0)) + int(st.get("dmg_" + OniBehavior.SMASH_SOURCE, 0.0)) + int(st.get("dmg_" + OniBehavior.QUAKE_SOURCE, 0.0)),
			int(st.get("dmg_bound_oni", 0.0)), int(st.get("dmg_oni_lord", 0.0)), int(st.get("dmg_" + OniBehavior.SMASH_SOURCE, 0.0)), int(st.get("dmg_" + OniBehavior.QUAKE_SOURCE, 0.0)),
			int(st.get("bound_oni_smashes", 0.0)), int(st.get("bound_oni_smash_hits", 0.0)), int(st.get("bound_oni_stuns", 0.0)),
			int(st.get("oni_lord_quakes", 0.0)), int(st.get("oni_lord_quake_hits", 0.0)), ab.passive_level(OniBehavior.RESOLVE), int(st.get("onis_resolve_seconds", 0.0))])
