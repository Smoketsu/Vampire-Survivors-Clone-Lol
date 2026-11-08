## TwoTruthsReport — the autotest summary lines of THE HALL OF TWO TRUTHS and its
## rewards (temporary Act XII, the Necropolis Dynasty's finale; GDD §15.0 "The
## Hall of Two Truths (Necropolis Dynasty phase 2)" and the rows after it).
## Read-only: it never changes the run.
##   stage_lines(): called from DynastyReport.print_lines() (only when the
##     Dynasty ran):
##     two truths         TwoTruthsDirector (the Scales, the wardens' rise)
##                        and its event log
##     two truths kinds   the Crocodile Wardens' drags and the Devourer's
##                        Whelp's meals (when either spawned)
##     osiris             BossOsiris.summary_line() (when it fought)
##   item_lines(): called from Autotest.finish() on EVERY stage, each line only
##     when its item was used, so every other summary keeps its exact text:
##     feather's verdict  Feather's Verdict / Heart Devoured, Heavy Heart, the
##                        Pharaoh's Shade's innate
##     ushabti sentinel   the Ushabti Sentinel / Eternal Guard and Answering
##                        Words
class_name TwoTruthsReport
extends RefCounted


## The stage's lines (DynastyReport; the Dynasty ran this run).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var td := game.enemies.two_truths  # The stage director (null off the Hall).
	if td != null:
		print("[autotest] two truths: %s" % td.summary_line())
		print("[autotest] two truths events (%d): %s" % [td.fired.size(), ", ".join(td.fired)])
	if int(st.get("spawned_crocodile_warden", 0.0)) > 0 or int(st.get("spawned_devourers_whelp", 0.0)) > 0:
		print("[autotest] two truths kinds: crocodile warden %d/%d, rises %d, drags %d (drowned %d, dmg %d) | devourer's whelp %d/%d, names eaten %d (healed %d, hunger peak %d), gulps %d (hits %d), killed in %ds" % [
			int(st.get("spawned_crocodile_warden", 0.0)), int(st.get("kill_crocodile_warden", 0.0)), int(st.get("croc_rises", 0.0)),
			int(st.get("croc_drags", 0.0)), int(st.get("croc_drowned", 0.0)), int(st.get("croc_drag_dmg", 0.0)),
			int(st.get("spawned_devourers_whelp", 0.0)), int(st.get("kill_devourers_whelp", 0.0)), int(st.get("whelp_eaten", 0.0)),
			int(st.get("whelp_healed", 0.0)), int(st.get("whelp_hunger_peak", 0.0)), int(st.get("whelp_gulps", 0.0)),
			int(st.get("whelp_gulp_hits", 0.0)), int(st.get("whelp_kill_time", 0.0))])
	if game.enemies.boss is BossOsiris:
		print("[autotest] osiris: %s" % BossOsiris.summary_line(st))


## The rewards' lines (every stage; each only when its item was used).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities
	var id := FeathersVerdictData.ID
	var lvl := ab.spell_level(id)
	if lvl > 0 or ab.passive_level(FeathersVerdictData.HEAVY_HEART) > 0:
		var node: NecroSpell = ab.spells.nodes.get(id)  # The spell node (null if never ticked).
		print("[autotest] feather's verdict: Lv%d%s dmg=%d (blow %d, executions %d, evolved %d / %d) boss=%d kills=%d %s | heavy_heart Lv%d" % [
			lvl, " EVOLVED" if ab.evolved.has(id) else "", int(ab.spells.damage_of(id)),
			int(st.get("dmg_" + FeathersVerdictData.SOURCE, 0.0)), int(st.get("dmg_" + FeathersVerdictData.EXECUTE_SOURCE, 0.0)),
			int(st.get("dmg_" + FeathersVerdictData.EVOLVED_SOURCE, 0.0)), int(st.get("dmg_" + FeathersVerdictData.EVOLVED_EXECUTE_SOURCE, 0.0)),
			int(st.get("bossdmg_" + FeathersVerdictData.SOURCE, 0.0)) + int(st.get("bossdmg_" + FeathersVerdictData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(id)), node.summary_extra() if node != null else "",
			ab.passive_level(FeathersVerdictData.HEAVY_HEART)])
	var cls := UshabtiSentinelBehavior.CLASS_ID
	if int(game.horde.class_levels.get(cls, 0)) > 0 or ab.passive_level(UshabtiSentinelBehavior.ANSWERING) > 0:
		print("[autotest] ushabti sentinel: Lv %d%s, alive %d | dmg %d (ushabti_sentinel=%d reform=%d eternal_guard=%d reform=%d) | reassembled %d (rubble hits held %d, reform hits %d) | slain %d | answering_words Lv%d" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_ushabti_sentinel", 0.0)) + int(st.get("dmg_" + UshabtiSentinelBehavior.REFORM_SOURCE, 0.0)) + int(st.get("dmg_eternal_guard", 0.0)) + int(st.get("dmg_" + UshabtiSentinelBehavior.EVOLVED_REFORM_SOURCE, 0.0)),
			int(st.get("dmg_ushabti_sentinel", 0.0)), int(st.get("dmg_" + UshabtiSentinelBehavior.REFORM_SOURCE, 0.0)),
			int(st.get("dmg_eternal_guard", 0.0)), int(st.get("dmg_" + UshabtiSentinelBehavior.EVOLVED_REFORM_SOURCE, 0.0)),
			int(st.get("ushabti_reassembled", 0.0)), int(st.get("ushabti_rubble_blocked", 0.0)), int(st.get("ushabti_reform_hits", 0.0)),
			int(st.get("ushabti_slain", 0.0)), ab.passive_level(UshabtiSentinelBehavior.ANSWERING)])
