## DynastyReport — the autotest summary lines of the Necropolis Dynasty's shared
## rules and stages (temporary Act XII; GDD §15.0 "The Necropolis Dynasty
## foundation (phase 1)"), called once by Autotest.finish(). Every line prints
## only when the Dynasty ran this run (Game.dynasty exists: a Dynasty stage, or
## a Dynasty kind forced onto another stage with --spawn=), so every other
## act's summaries keep their exact text:
##   rebirth:          Rebirth (bodies fallen, cartouches laid / sealed,
##                     returned first / second / later, stolen by a raise,
##                     smashed by spells / summons / other, crumbled with a
##                     jar, eaten by the Devourer, refused: spent / cap / no
##                     jar, peak, hastened by Embalmers, jars placed / broken)
##   black land:       Quicksand and the Sandstorm (live patches peak, slow
##                     ticks on you / summons / enemies, storms and their
##                     times, time blown, reach recomputes)
##   heka:             Heka (glyphs written, refused, jumps, stuck, ended by
##                     why, peak, summon-seconds cursed, casts lost)
##   devourer's hour:  DevourersHour (only once the Reckoning ran: began,
##                     lanes, summon hits and damage, hits on you, cartouches
##                     eaten)
##   dynasty kinds:    spawns / kills of every Dynasty kind that spawned (the
##                     cartouche left out), its first appearance, its damage to
##                     the necromancer and to summons, grouped by group
##   dynasty stage:    the Dynasty stage itself (stub status, boss, Soul Ash,
##                     the Reckoning)
## Phase 2 adds one line per stage system here (each stage in its own block).
## Read-only: it never changes the run.
class_name DynastyReport
extends RefCounted


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var dy := game.dynasty  # The Dynasty's rules (null when they never ran).
	if dy == null:
		return
	print("[autotest] rebirth: %s" % rebirth_line(game, st))
	print("[autotest] black land: %s" % black_land_line(game, st))
	print("[autotest] heka: %s" % heka_line(game, st))
	if dy.devourer.running():
		print("[autotest] devourer's hour: began %s | lanes %d (refused %d) | summon hits %d (dmg %d) | hits on you %d | cartouches eaten %d | rebirth unlimited %s" % [
			EmpireReport._clock(dy.devourer.started_at), dy.devourer.lanes_swept, int(st.get("devourer_lanes_refused", 0.0)),
			int(st.get("devourer_summon_hits", 0.0)), int(st.get("devourer_summon_dmg", 0.0)), int(st.get("devourer_player_hits", 0.0)),
			dy.rebirth.eaten, str(dy.rebirth.unlimited)])
	var kinds_line := kinds_line_of(game, st)
	if kinds_line != "":
		print("[autotest] dynasty kinds (spawned/killed): %s" % kinds_line)
	var sd := game.stage_def  # The run's stage.
	if bool(sd.get("dynasty", false)):
		var boss: Dictionary = sd["boss"]
		print("[autotest] dynasty stage: %s (%s) | act %d | playable %s | boss %s (script %s) | enemy x%.2f HP / x%.2f dmg from %s | soul ash x%.2f | reckoning kind %s, devourer's hour %s" % [
			String(sd["id"]), String(sd["display_name"]), StageRegistry.act_of(String(sd["id"])), str(StageRegistry.is_playable(String(sd["id"]))),
			String(boss["id"]), String(boss.get("script", boss["id"])), float(sd["enemy_hp_mult"]), float(sd["enemy_damage_mult"]),
			EmpireReport._clock(float(sd.get("enemy_mult_from", 0.0))), float(sd["ash_mult"]),
			String((sd["reckoning"] as Dictionary).get("kind", "inquisitor")), str(not dy.devourer.cfg.is_empty())])
	# Phase 2: each Dynasty stage's own lines go here (its stage, kinds and boss).
	# --- Act XII (temporary number): the Necropolis of Sand ---
	NecropolisReport.print_lines(game, st)  # The jars, No Jars Left, the Nile Archers and Jackal Warriors, the Sand Colossus, Anubis.
	# --- Act XII (temporary number): the Temple of the Lioness --- (the Awakening Statues, the Warden, Sekhmet; LionessTempleReport)
	LionessTempleReport.print_lines(game, st)


## The "rebirth" line (Rebirth).
static func rebirth_line(game: Game, st: Dictionary) -> String:
	var r := game.dynasty.rebirth
	return "fallen %d | cartouches %d (sealed by a jar %d), peak %d, hastened by Embalmers %d | returned %d (1st %d, 2nd %d, later %d) | stolen by a raise %d | smashed %d (spell %d, summon %d, other %d) | crumbled with a jar %d | eaten %d | refused: spent %d, cap %d, no jar %d | jars %d placed, %d broken, refused %d" % [
		r.fallen, r.laid, r.sealed, r.peak, int(st.get("rebirth_embalmed", 0.0)),
		r.returned[0] + r.returned[1] + r.returned[2], r.returned[0], r.returned[1], r.returned[2], r.stolen,
		int(r.smashed.get("spell", 0)) + int(r.smashed.get("summon", 0)) + int(r.smashed.get("other", 0)),
		int(r.smashed.get("spell", 0)), int(r.smashed.get("summon", 0)), int(r.smashed.get("other", 0)),
		r.crumbled, r.eaten, r.spent, r.capped, r.unheld, r.jars_placed, r.jars_broken, int(st.get("rebirth_jars_refused", 0.0))]


## The "black land" line (Quicksand and the Sandstorm).
static func black_land_line(game: Game, st: Dictionary) -> String:
	var dy := game.dynasty
	var q := dy.quicksand
	var s := dy.sandstorm
	return "%s | quicksand peak live %d, added %d | slow ticks: you %d, summons %d, enemies %d | sandstorms %d (forced %d) at %s, blew %ds, warned %d | reach refreshes %d | enemy fire hits %d" % [
		"on" if dy.enabled else "clocks off (not a Dynasty stage)", q.peak, int(st.get("quicksand_added", 0.0)),
		int(st.get("quicksand_player", 0.0)), int(st.get("quicksand_summons", 0.0)), int(st.get("quicksand_enemies", 0.0)),
		s.storms, s.forced, ", ".join(s.rise_times) if not s.rise_times.is_empty() else "-", int(st.get("sandstorm_time", 0.0)),
		int(st.get("sandstorm_warnings", 0.0)), int(st.get("sandstorm_reach_refreshes", 0.0)), int(st.get("dynasty_fire_hits", 0.0))]


## The "heka" line (Heka).
static func heka_line(game: Game, st: Dictionary) -> String:
	var h := game.dynasty.heka
	var why := PackedStringArray()
	var keys := h.ended.keys()
	keys.sort()
	for k: String in keys:
		why.append("%s %d" % [k, int(h.ended[k])])
	return "written %d (casts %d, lost %d, refused %d) | jumps %d (stuck %d) | ended %s | peak %d | cursed summon-seconds %d | summon curses %d" % [
		h.written, int(st.get("heka_casts", 0.0)), int(st.get("heka_casts_lost", 0.0)), h.refused, h.jumps,
		int(st.get("heka_jumps_stuck", 0.0)), ", ".join(why) if not why.is_empty() else "-", h.peak, int(h.cursed_seconds),
		int(st.get("summon_curses", 0.0))]


## The "dynasty kinds" line: every Dynasty kind that spawned (the cartouche
## left out), grouped by group ("" when none did).
static func kinds_line_of(game: Game, st: Dictionary) -> String:
	var dy := game.dynasty
	var groups := PackedStringArray()
	for grp: String in DynastyRulesData.GROUPS:
		var parts := PackedStringArray()
		for table: Dictionary in [DynastyEnemyData.ENEMIES, NecropolisEnemyData.ENEMIES, LionessTempleEnemyData.ENEMIES, TwoTruthsEnemyData.ENEMIES]:
			for k: String in table:
				if String((table[k] as Dictionary).get("group", "")) != grp:
					continue
				var spawned := int(st.get("spawned_" + k, 0.0))
				var killed := int(st.get("kill_" + k, 0.0))
				if spawned > 0 or killed > 0:
					var first := EmpireReport._clock(float(dy.first_seen[k])) if dy.first_seen.has(k) else "-"
					parts.append("%s %d/%d first %s (dmg to you %d, to summons %d)" % [k, spawned, killed, first,
						int(st.get("player_dmg_from_" + k, 0.0)), int(st.get("summon_dmg_from_" + k, 0.0))])
		if not parts.is_empty():
			groups.append("%s: %s" % [grp, ", ".join(parts)])
	if groups.is_empty():
		return ""
	return " | ".join(groups) + " | khopesh spins %d (hits %d) | scarab barrier torn %d | embalmer heals %d" % [
		int(st.get("khopesh_spins", 0.0)), int(st.get("khopesh_spin_hits", 0.0)), int(st.get("scarab_barrier_gnawed", 0.0)),
		int(st.get("embalmer_heals", 0.0))]
