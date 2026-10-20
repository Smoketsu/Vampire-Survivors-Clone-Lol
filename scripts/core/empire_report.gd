## EmpireReport — the autotest summary lines of the Electronic Empire's shared
## rules and stages (Act III; GDD §15.0 "Act III foundation (phase 1)"), called
## once by Autotest.finish(). Every line prints only when the Empire ran this
## run (Game.empire exists: an Act III stage, or an Empire kind forced onto
## another stage with --spawn=), so the Act I and II summaries keep their
## exact text:
##   line of fire:    EmpireShots (shots fired, stopped by summons / barriers /
##                    bone walls / the Orb Shield, reaching the necromancer)
##   lock-on:         LockOn (lines painted, refused at the cap, fired,
##                    cancelled by a slain Spotter, rails stopped or landing)
##   steel:           machine vs cyborg kills, Grave Gunners raised, their damage
##   purge protocol:  the orbital strikes after 0:00 (when the stage has them)
##   empire kinds:    spawns / kills of every Empire kind that spawned
##   empire stage:    the Act III stage itself (stub status, boss, Soul Ash)
## Phase 2 adds one line per stage system here (the Scrap Wastes: WastesReport).
## Read-only: it never changes the run.
class_name EmpireReport
extends RefCounted


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var em := game.empire  # The Empire's rules (null when they never ran).
	if em == null:
		return
	print("[autotest] line of fire: %s" % em.line_of_fire_line())
	print("[autotest] lock-on: %s" % em.lock_on_line())
	print("[autotest] steel: %s" % em.steel_line())
	var purge := em.purge_line()
	if purge != "":
		print("[autotest] purge protocol: %s" % purge)
	var parts := PackedStringArray()  # "kind spawned/killed" per Empire kind seen.
	var kinds: Array = []  # Every Empire kind id, the shared table first.
	for table: Dictionary in [EmpireEnemyData.ENEMIES, WastesEnemyData.ENEMIES, AssemblyEnemyData.ENEMIES, CitadelEnemyData.ENEMIES]:
		kinds.append_array(table.keys())
	for k: String in kinds:
		var spawned := int(st.get("spawned_" + k, 0.0))
		var killed := int(st.get("kill_" + k, 0.0))
		if spawned > 0 or killed > 0:
			parts.append("%s %d/%d (dmg to you %d, to summons %d)" % [k, spawned, killed,
				int(st.get("player_dmg_from_" + k, 0.0)), int(st.get("summon_dmg_from_" + k, 0.0))])
	if not parts.is_empty():
		print("[autotest] empire kinds (spawned/killed): %s" % " | ".join(parts))
	var sd := game.stage_def  # The run's stage.
	if StageRegistry.act_of(String(sd["id"])) == 3:
		var boss: Dictionary = sd["boss"]
		print("[autotest] empire stage: %s (%s) | playable %s | boss %s (script %s) | enemy x%.2f HP / x%.2f dmg from %s | soul ash x%.2f | reckoning kind %s" % [
			String(sd["id"]), String(sd["display_name"]), str(StageRegistry.is_playable(String(sd["id"]))),
			String(boss["id"]), String(boss.get("script", boss["id"])), float(sd["enemy_hp_mult"]), float(sd["enemy_damage_mult"]),
			_clock(float(sd.get("enemy_mult_from", 0.0))), float(sd["ash_mult"]), String((sd["reckoning"] as Dictionary).get("kind", "inquisitor"))])
	# --- Act III: the Scrap Wastes ---
	WastesReport.print_lines(game, st)  # Pylons, storms, its kinds, the Trojan Horse, Kestrel.


## "m:ss" of `t` game seconds.
static func _clock(t: float) -> String:
	var s := maxi(0, roundi(t))
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]
