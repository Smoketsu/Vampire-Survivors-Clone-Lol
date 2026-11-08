## VigridReport — the autotest summary lines of VIGRID, THE LAST FIELD and its
## rewards (the Hall of the Slain's finale, temporarily Act XI; GDD §15.0
## "Vigrid, the Last Field (phase 2)" and the rows after it). Read-only: it
## never changes the run.
##   stage_lines(): called from NorseReport.print_lines() (only when the Norse
##     rules ran):
##     vigrid            VigridDirector (the Fading Light, the vanguard, the
##                       miniboss) and its event log, the warmth the bot found
##     vigrid kinds      the Fire-Giant of the south, Fenrir, the ravens (when
##                       any of them spawned)
##     odin              BossOdin.summary_line() (when he fought)
##   item_lines(): called from Autotest.finish() on EVERY stage, each line only
##     when its item was used, so every other summary keeps its exact text:
##     gungnir           Gungnir / Spear of the Hanged, Runecraft, the
##                       Berserker's innate
##     draugr thane      the Draugr Thane / Barrow King and Cold Iron
class_name VigridReport
extends RefCounted


## The stage's lines (NorseReport; the Norse rules ran this run).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var vd := game.enemies.vigrid  # The stage director (null off Vigrid).
	if vd != null:
		print("[autotest] vigrid: %s" % vd.summary_line())
		print("[autotest] vigrid events (%d): %s" % [vd.fired.size(), ", ".join(vd.fired)])
	var any := false
	for k: String in [VigridEnemyData.MUSPEL_GIANT, VigridEnemyData.FENRIR, VigridEnemyData.RAVEN]:
		any = any or int(st.get("spawned_" + k, 0.0)) > 0
	if any:
		print("[autotest] vigrid kinds: fire-giant of the south %d/%d (footprints %d, burning stomps %d) | fenrir %d/%d (lunges %d, swallows %d, spat %d, lunges on you %d) | ravens %d/%d (marks %d, flew home %d)" % [
			int(st.get("spawned_muspel_giant", 0.0)), int(st.get("kill_muspel_giant", 0.0)), int(st.get("muspel_tracks", 0.0)), int(st.get("muspel_stomp_fires", 0.0)),
			int(st.get("spawned_fenrir", 0.0)), int(st.get("kill_fenrir", 0.0)), int(st.get("fenrir_lunges", 0.0)), int(st.get("fenrir_swallows", 0.0)),
			int(st.get("fenrir_spat", 0.0)), int(st.get("fenrir_lunge_on_you", 0.0)),
			int(st.get("spawned_odin_raven", 0.0)), int(st.get("kill_odin_raven", 0.0)), int(st.get("raven_marks", 0.0)), int(st.get("raven_home", 0.0))])
	if game.enemies.boss is BossOdin:
		print("[autotest] odin: %s" % BossOdin.summary_line(st))


## The rewards' lines (every stage; each only when its item was used).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities
	var lvl := ab.spell_level(GungnirData.ID)
	if lvl > 0 or ab.passive_level(GungnirData.RUNECRAFT) > 0:
		var node: NecroSpell = ab.spells.nodes.get(GungnirData.ID)  # The spell node (null if never ticked).
		print("[autotest] gungnir: Lv%d%s dmg=%d (spear %d, evolved %d) boss=%d kills=%d %s | runecraft Lv%d" % [
			lvl, " EVOLVED" if ab.evolved.has(GungnirData.ID) else "", int(ab.spells.damage_of(GungnirData.ID)),
			int(st.get("dmg_" + GungnirData.SOURCE, 0.0)), int(st.get("dmg_" + GungnirData.EVOLVED_SOURCE, 0.0)),
			int(st.get("bossdmg_" + GungnirData.SOURCE, 0.0)) + int(st.get("bossdmg_" + GungnirData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(GungnirData.ID)), node.summary_extra() if node != null else "",
			ab.passive_level(GungnirData.RUNECRAFT)])
	var cls := DraugrThaneBehavior.CLASS_ID
	if int(game.horde.class_levels.get(cls, 0)) > 0 or ab.passive_level(DraugrThaneBehavior.COLD_IRON) > 0:
		print("[autotest] draugr thane: Lv %d%s, alive %d | dmg %d (draugr_thane=%d cleave=%d barrow_king=%d cleave=%d) | axe chills %d | cleaves %d (hits %d), freezes %d | cold_iron Lv%d, bonus dmg %d" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_draugr_thane", 0.0)) + int(st.get("dmg_" + DraugrThaneBehavior.CLEAVE_SOURCE, 0.0)) + int(st.get("dmg_barrow_king", 0.0)) + int(st.get("dmg_" + DraugrThaneBehavior.EVOLVED_CLEAVE_SOURCE, 0.0)),
			int(st.get("dmg_draugr_thane", 0.0)), int(st.get("dmg_" + DraugrThaneBehavior.CLEAVE_SOURCE, 0.0)),
			int(st.get("dmg_barrow_king", 0.0)), int(st.get("dmg_" + DraugrThaneBehavior.EVOLVED_CLEAVE_SOURCE, 0.0)),
			int(st.get("draugr_thane_chills", 0.0)), int(st.get("draugr_thane_cleaves", 0.0)), int(st.get("draugr_thane_cleave_hits", 0.0)),
			int(st.get("barrow_king_freezes", 0.0)), ab.passive_level(DraugrThaneBehavior.COLD_IRON), int(st.get("cold_iron_bonus_dmg", 0.0))])
