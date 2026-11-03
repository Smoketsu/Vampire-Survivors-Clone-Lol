## ConcordReport — the autotest summary lines of the Concord of Stars' shared
## rules and stages (Act IX; GDD §15.0 "Act IX foundation (phase 1)"), called
## once by Autotest.finish(). Every line prints only when the Concord ran this
## run (Game.concord exists: an Act IX stage, or a Concord kind forced onto
## another stage with --spawn=), so the Act I to VIII summaries keep their
## exact text:
##   beams:          ConcordBeams (fired by style, refused, peak at once, hits
##                   and damage on summons and the necromancer, reflections by
##                   an orb / a barrier and the reflected damage to enemies,
##                   prism splits, cancelled, Bone Wall stops)
##   abduction:      Abduction (lifts, rescues when the saucer fell, taken,
##                   refused at the cap / too heavy, peak held, saucers shot
##                   down, the saucers' air whiffs and hits)
##   terraforming:   Terraforming (pods landed and destroyed, cells grown, peak
##                   live cells, cells burnt, burns capped, HP healed on the
##                   turf by race)
##   final harvest:  FinalHarvest (only once the Reckoning ran: eye beams,
##                   saucers spawned, lifts past the cap)
##   concord kinds:  spawns / kills of every Concord kind that spawned, its
##                   first appearance, its damage to the necromancer and to
##                   summons, grouped by race
##   concord stage:  the Act IX stage itself (stub status, boss, Soul Ash, the
##                   Reckoning)
## Phase 2 adds one line per stage system here (each stage in its own block).
## Read-only: it never changes the run.
class_name ConcordReport
extends RefCounted


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var c := game.concord  # The Concord's rules (null when they never ran).
	if c == null:
		return
	print("[autotest] beams: %s" % beams_line(game, st))
	print("[autotest] abduction: %s" % abduction_line(game, st))
	print("[autotest] terraforming: %s" % terraforming_line(game, st))
	if c.harvest.running():
		print("[autotest] final harvest: began %s | eye beams %d (refused %d) | saucers spawned %d | lifts past the cap %d | peak held %d" % [
			EmpireReport._clock(c.harvest.started_at), c.harvest.eye_beams, int(st.get("harvest_eye_refused", 0.0)),
			c.harvest_saucers, int(st.get("abduction_lifts_uncapped", 0.0)), c.abduction.peak])
	var kinds_line := kinds_line_of(game, st)
	if kinds_line != "":
		print("[autotest] concord kinds (spawned/killed): %s" % kinds_line)
	var sd := game.stage_def  # The run's stage.
	if StageRegistry.act_of(String(sd["id"])) == 9:
		var boss: Dictionary = sd["boss"]
		print("[autotest] concord stage: %s (%s) | playable %s | boss %s (script %s) | enemy x%.2f HP / x%.2f dmg from %s | soul ash x%.2f | reckoning kind %s, final harvest %s" % [
			String(sd["id"]), String(sd["display_name"]), str(StageRegistry.is_playable(String(sd["id"]))),
			String(boss["id"]), String(boss.get("script", boss["id"])), float(sd["enemy_hp_mult"]), float(sd["enemy_damage_mult"]),
			EmpireReport._clock(float(sd.get("enemy_mult_from", 0.0))), float(sd["ash_mult"]),
			String((sd["reckoning"] as Dictionary).get("kind", "inquisitor")), str(not c.harvest.cfg.is_empty())])
	# Phase 2: each Act IX stage's own lines go here (its stage, kinds and boss).
	# --- Act IX: the Crash Site ---
	CrashSiteReport.print_lines(game, st)  # The crater, the eggs, the Burrowers, the acid, the Matriarch, the Hive Mother.


## The "beams" line (ConcordBeams).
static func beams_line(game: Game, st: Dictionary) -> String:
	var b := game.concord.beams
	var by := PackedStringArray()
	for s: String in ConcordRulesData.BEAM_STYLES:
		if b.fired_by.has(s):
			by.append("%s %d" % [s, int(b.fired_by[s])])
	return "fired %d (%s) | refused %d | cancelled %d | peak at once %d | hits on summons %d (dmg %d), on you %d (dmg %d) | reflected by orb %d, by barrier %d (enemy hits %d, dmg %d) | prism splits %d | bone wall stops %d" % [
		int(st.get("beams_fired", 0.0)), ", ".join(by) if not by.is_empty() else "-", int(st.get("beams_refused", 0.0)),
		int(st.get("beams_cancelled", 0.0)), b.peak,
		int(st.get("beam_hits_summons", 0.0)), int(st.get("beam_dmg_summons", 0.0)),
		int(st.get("beam_hits_you", 0.0)), int(st.get("beam_dmg_you", 0.0)),
		int(st.get("beam_reflect_orb", 0.0)), int(st.get("beam_reflect_barrier", 0.0)),
		int(st.get("beam_reflect_hits", 0.0)), int(st.get("beam_reflect_dmg", 0.0)), int(st.get("beam_prism_splits", 0.0)),
		int(st.get("beam_wall_stops", 0.0))]  # Act IX, the Crash Site: a Bone Wall stopped the beam.


## The "abduction" line (Abduction).
static func abduction_line(game: Game, st: Dictionary) -> String:
	var a := game.concord.abduction
	return "lifts %d (windups %d, lost %d) | rescues %d (saucer fell) | taken %d | refused: cap %d, too heavy %d | peak held %d | saucers shot down %d | air: whiffs %d, hits %d" % [
		a.lifts, int(st.get("saucer_windups", 0.0)), int(st.get("saucer_windups_lost", 0.0)), a.rescues, a.taken,
		int(st.get("abduction_refused_cap", 0.0)), int(st.get("abduction_refused_heavy", 0.0)), a.peak,
		int(st.get("abduction_saucers_down", 0.0)), int(st.get("concord_air_whiffs", 0.0)), int(st.get("concord_air_hits", 0.0))]


## The "terraforming" line (Terraforming).
static func terraforming_line(game: Game, st: Dictionary) -> String:
	var t := game.concord.terraforming
	var by := PackedStringArray()
	for r: String in ConcordRulesData.RACES:
		if t.healed_by_race.has(r):
			by.append("%s %d" % [r, int(t.healed_by_race[r])])
	return "%s | pods landed %d, destroyed %d, refused %d | cells grown %d, peak live %d, burnt %d (burns capped %d), live at the end %d | healed on turf %d (%s)" % [
		"on" if t.enabled else "pods off (not an Act IX stage)", t.pods_landed, t.pods_destroyed, int(st.get("terra_pods_refused", 0.0)),
		t.cells_grown, t.peak_live, t.cells_burnt, int(st.get("terra_burns_capped", 0.0)), t.live_count,
		int(st.get("terra_heals", 0.0)), ", ".join(by) if not by.is_empty() else "-"]


## The "concord kinds" line: every Concord kind that spawned, grouped by race
## ("" when none did).
static func kinds_line_of(game: Game, st: Dictionary) -> String:
	var c := game.concord
	var groups := PackedStringArray()
	for race: String in ConcordRulesData.RACES:
		var parts := PackedStringArray()
		for table: Dictionary in [ConcordEnemyData.ENEMIES, CrashSiteEnemyData.ENEMIES, ProvingMoonEnemyData.ENEMIES, ArkEnemyData.ENEMIES]:
			for k: String in table:
				if String((table[k] as Dictionary).get("race", "")) != race:
					continue
				var spawned := int(st.get("spawned_" + k, 0.0))
				var killed := int(st.get("kill_" + k, 0.0))
				if spawned > 0 or killed > 0:
					var first := EmpireReport._clock(float(c.first_seen[k])) if c.first_seen.has(k) else "-"
					parts.append("%s %d/%d first %s (dmg to you %d, to summons %d)" % [k, spawned, killed, first,
						int(st.get("player_dmg_from_" + k, 0.0)), int(st.get("summon_dmg_from_" + k, 0.0))])
		if not parts.is_empty():
			groups.append("%s: %s" % [race, ", ".join(parts)])
	if groups.is_empty():
		return ""
	return " | ".join(groups) + " | vrask cloak cut %d, reveals %d" % [int(st.get("vrask_cloak_cut", 0.0)), int(st.get("vrask_reveals", 0.0))]
