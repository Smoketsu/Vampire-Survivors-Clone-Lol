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
## Phase 2 adds one line per stage system here (each stage in its own block):
##   the Iron Citadel: CitadelReport.stage_lines() (the director, its events,
##                     its kinds, the ranged share, Deus Ex Machina).
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
	# --- Act III: the Assembly Halls ---
	_assembly_lines(game, st)
	# --- Act III: the Scrap Wastes ---
	WastesReport.print_lines(game, st)  # Pylons, storms, its kinds, the Trojan Horse, Kestrel.
	# --- Act III: the Iron Citadel ---
	CitadelReport.stage_lines(game, st)


# --- Act III: the Assembly Halls ---
## The Assembly Halls' lines (GDD §15.0 "The Assembly Halls (Act III phase 2)"):
##   assembly:        fabricators (placed / destroyed, built, the waves' cut),
##                    Cold Assembly, the Beta Build
##   assembly floor:  belts (body-seconds carried) and furnace channels (burns)
##   assembly events: the timeline log
##   assembly kinds:  Arc Engineer repairs / jams, Juggernaut flames, the Beta
##                    Build's specials and patching (when any of them spawned)
##   motherboard:     the boss's fight (when it spawned)
## Each prints only when its system ran this run.
static func _assembly_lines(game: Game, st: Dictionary) -> void:
	var ad := game.enemies.assembly  # The stage's director (null off the Assembly Halls).
	if ad != null:
		print("[autotest] assembly: %s" % ad.summary_line())
		print("[autotest] assembly floor: %s" % ad.floor_line())
		print("[autotest] assembly events (%d): %s" % [ad.fired.size(), ", ".join(ad.fired)])
	var any_kind := false  # An Assembly kind spawned this run.
	for k: String in [AssemblyEnemyData.ARC_ENGINEER, AssemblyEnemyData.JUGGERNAUT, AssemblyEnemyData.BETA_BUILD, AssemblyEnemyData.FABRICATOR]:
		any_kind = any_kind or float(st.get("spawned_" + k, 0.0)) > 0.0
	if any_kind:
		print("[autotest] assembly kinds: arc engineer repairs %d (hp %d), jams %d | juggernaut flames %d (summon hits %d, player hits %d, flat armour absorbed %d) | beta build swipes %d (hits %d), rivet sprays %d, patched %d hp (%d ticks fed by fabricators), killed %d (in %.0f s) | fabricated %d" % [
			int(st.get("arc_repairs", 0.0)), int(st.get("arc_repaired_hp", 0.0)), int(st.get("arc_jams", 0.0)),
			int(st.get("juggernaut_flames", 0.0)), int(st.get("juggernaut_flame_summon_hits", 0.0)), int(st.get("juggernaut_flame_player_hits", 0.0)),
			int(st.get("flat_armor_absorbed_" + AssemblyEnemyData.JUGGERNAUT, 0.0)),
			int(st.get("beta_swipe_used", 0.0)), int(st.get("beta_swipe_hits", 0.0)), int(st.get("beta_rivets_used", 0.0)), int(st.get("beta_patched_hp", 0.0)),
			int(st.get("beta_patch_ticks_with_fabs", 0.0)), int(st.get("beta_kills", 0.0)), float(st.get("beta_ttk", 0.0)), int(st.get("assembly_fabricated", 0.0))])
	if float(st.get("boss_atk_grab", 0.0)) + float(st.get("boss_atk_stamp", 0.0)) > 0.0 or game.enemies.boss is BossMotherboard:
		print("[autotest] motherboard: %s" % BossMotherboard.summary_line(st))


## "m:ss" of `t` game seconds.
static func _clock(t: float) -> String:
	var s := maxi(0, roundi(t))
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]
