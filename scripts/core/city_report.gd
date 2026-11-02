## CityReport — the autotest summary lines of the Last Line's shared rules and
## stages (Act VIII; GDD §15.0 "Act VIII foundation (phase 1)"), called once by
## Autotest.finish(). Every line prints only when the Last Line ran this run
## (Game.city exists: an Act VIII stage, or a City kind forced onto another
## stage with --spawn=), so the Act I to VII summaries keep their exact text:
##   city blocks: CityBlocks (lots built and open, building / wreck push-outs,
##                ring posts pulled toward the necromancer, the enemies' contact
##                with the building faces in s per minute, wrecks placed /
##                refused / burnt away); "off" without a blocks layout
##   armour:      Armour and Convoy (front hits and damage cut, flat armour
##                absorbed, vehicles driven / corners / turns / rams, run-overs
##                on summons and the necromancer, vehicles destroyed, wrecks,
##                explosions, shells fired)
##   supers:      SuperRoster (arrived, exposed by what, damage taken exposed
##                and guarded, the met list, Blitz's dashes)
##   civilians:   Civilians (spawned, fled, killed by the army, XP dropped)
##   escalation:  Escalation (the time each tier began)
##   city kinds:  spawns / kills of every City kind that spawned, its first
##                appearance, its damage to the necromancer and to summons
##   martial law: MartialLaw (only once the Reckoning ran)
##   city stage:  the Act VIII stage itself (stub status, boss, Soul Ash, the
##                Reckoning)
## Phase 2 adds one line per stage system here (each stage in its own block).
##   Act VIII, Skid Row: SkidRowReport.print_lines() (skid row, tear gas, big
##   sal, don marrow).
## Read-only: it never changes the run.
class_name CityReport
extends RefCounted


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var city := game.city  # The Last Line's rules (null when they never ran).
	if city == null:
		return
	print("[autotest] city blocks: %s" % blocks_line(game))
	print("[autotest] armour: %s" % armour_line(game, st))
	print("[autotest] supers: %s" % supers_line(game, st))
	print("[autotest] civilians: %s" % civilians_line(game, st))
	print("[autotest] escalation: %s" % escalation_line(game, st))
	var parts := PackedStringArray()  # "kind spawned/killed" per City kind seen.
	var kinds: Array = []  # Every City kind id, the shared table first.
	for table: Dictionary in [CityEnemyData.ENEMIES, SkidRowEnemyData.ENEMIES, FortKesslerEnemyData.ENEMIES, LibertyHeightsEnemyData.ENEMIES]:
		kinds.append_array(table.keys())
	for k: String in kinds:
		var spawned := int(st.get("spawned_" + k, 0.0))
		var killed := int(st.get("kill_" + k, 0.0))
		if spawned > 0 or killed > 0:
			var first := EmpireReport._clock(float(city.first_seen[k])) if city.first_seen.has(k) else "-"
			parts.append("%s %d/%d first %s (dmg to you %d, to summons %d)" % [k, spawned, killed, first,
				int(st.get("player_dmg_from_" + k, 0.0)), int(st.get("summon_dmg_from_" + k, 0.0))])
	if not parts.is_empty():
		print("[autotest] city kinds (spawned/killed): %s | gunner sprays %d | breacher blasts %d, flashbangs %d (summon stuns %d) | rifle bursts %d | tank shells %d | medic heals %d" % [
			" | ".join(parts), int(st.get("gunner_sprays", 0.0)), int(st.get("breacher_shotgun_blasts", 0.0)),
			int(st.get("breacher_flashbangs", 0.0)), int(st.get("summon_stuns_" + CityEnemyData.FLASH_SOURCE, 0.0)),
			int(st.get("rifle_bursts", 0.0)), int(st.get("tank_shells", 0.0)), int(st.get("medic_heals", 0.0))])
	if city.martial.running():
		var m := city.martial
		print("[autotest] martial law: began %s | artillery lines %d (shells %d; hits on summons %d, on you %d, on enemies %d) | supers returned %d" % [
			EmpireReport._clock(m.started_at), m.lines, int(st.get("martial_shells", 0.0)),
			int(st.get("city_blast_hits_summons", 0.0)), int(st.get("city_blast_hits_you", 0.0)), int(st.get("city_blast_hits_enemies", 0.0)),
			m.supers_back])
	var sd := game.stage_def  # The run's stage.
	if StageRegistry.act_of(String(sd["id"])) == 8:
		var boss: Dictionary = sd["boss"]
		print("[autotest] city stage: %s (%s) | playable %s | boss %s (script %s) | enemy x%.2f HP / x%.2f dmg from %s | soul ash x%.2f | reckoning kind %s, martial law %s" % [
			String(sd["id"]), String(sd["display_name"]), str(StageRegistry.is_playable(String(sd["id"]))),
			String(boss["id"]), String(boss.get("script", boss["id"])), float(sd["enemy_hp_mult"]), float(sd["enemy_damage_mult"]),
			EmpireReport._clock(float(sd.get("enemy_mult_from", 0.0))), float(sd["ash_mult"]),
			String((sd["reckoning"] as Dictionary).get("kind", "inquisitor")), str(not city.martial.cfg.is_empty())])
	# Phase 2: each Act VIII stage's own lines go here (its stage, kinds and boss).
	# --- Act VIII: Skid Row ---
	SkidRowReport.print_lines(game, st)  # Big Sal, the Bounty, No Witnesses, the tear gas, Don Marrow (each when it ran).
	# --- Act VIII: Fort Kessler --- (the minefields, Mammoth, the new army kinds, Harrow; FortKesslerReport)
	FortKesslerReport.print_lines(game, st)
	# --- Act VIII: Liberty Heights --- (its stage, Supers and boss; LibertyHeightsReport)
	LibertyHeightsReport.stage_lines(game, st)


## The "city blocks" line (CityBlocks; "off" without a blocks layout).
static func blocks_line(game: Game) -> String:
	var cb := game.arena.city_blocks
	if cb == null:
		return "off (no city-block layout)"
	var minutes := maxf(game.elapsed / 60.0, 1.0 / 60.0)
	return "lots %d (open %d) | building push-outs %d, wreck push-outs %d | ring posts pulled toward you %d of %d | enemy contact with faces %d s (%.1f s per minute) | wrecks placed %d, refused %d, burnt away %d, standing %d" % [
		cb.lots_built, cb.lots_open, cb.building_pushes, cb.wreck_pushes, cb.ring_pulls, cb.ring_posts,
		int(cb.enemy_contact_s), cb.enemy_contact_s / minutes, cb.wrecks_placed, cb.wrecks_refused, cb.wrecks_burnt, cb.wrecks.size()]


## The "armour" line (Armour, Convoy).
static func armour_line(game: Game, st: Dictionary) -> String:
	var c := game.city.convoy
	var flat := 0
	for k: String in CityEnemyData.ENEMIES:
		flat += int(st.get("flat_armor_absorbed_" + k, 0.0))
	return "front hits %d (cut %d) | flat armour absorbed %d | vehicles driven %d, corners %d, turns %d, rams %d (wrecks %d) | run-overs on summons %d, on you %d (dodged %d) | destroyed %d, wrecks %d, explosions %d | shells %d | kevlar withheld %d" % [
		int(st.get("armour_front_hits", 0.0)), int(st.get("armour_front_dmg_prevented", 0.0)), flat,
		c.driven, int(st.get("city_vehicle_corners", 0.0)), c.turns, c.rams, int(st.get("city_rams_wreck", 0.0)),
		c.runs_summons, c.runs_you, int(st.get("city_run_over_dodged", 0.0)),
		c.destroyed, int(st.get("city_wrecks", 0.0)), c.explosions, int(st.get("city_shells", 0.0)),
		int(st.get("kevlar_dmg_prevented", 0.0))]


## The "supers" line (SuperRoster, SuperKit, BlitzKit).
static func supers_line(game: Game, st: Dictionary) -> String:
	var r := game.city.supers
	var by := PackedStringArray()
	for k: String in r.exposed_by:
		by.append("%s %d" % [k, int(r.exposed_by[k])])
	return "arrived %d (escalation %d) | exposed %d (%s) | damage taken exposed %d, guarded %d | met %s | blitz dashes %d (hits %d, stopped %d)" % [
		r.arrived, game.city.escalation.supers_sent, int(st.get("city_supers_exposed", 0.0)), ", ".join(by) if not by.is_empty() else "-",
		int(r.dmg_exposed), int(r.dmg_guarded), ", ".join(r.met) if not r.met.is_empty() else "-",
		int(st.get("blitz_dashes", 0.0)), int(st.get("blitz_dash_hits", 0.0)), int(st.get("blitz_dash_stopped", 0.0))]


## The "civilians" line (Civilians).
static func civilians_line(game: Game, _st: Dictionary) -> String:
	var c := game.city.civilians
	if not c.enabled and c.spawned == 0:
		return "off (not an Act VIII stage)"
	return "spawned %d | fled %d | killed by the army %d | XP dropped %d | alive at the end %d (own cap %d)" % [
		c.spawned, c.fled, c.killed, c.xp_dropped, c.alive, int(c.cfg["max_alive"])]


## The "escalation" line (Escalation).
static func escalation_line(game: Game, _st: Dictionary) -> String:
	var e := game.city.escalation
	if not e.enabled:
		return "off (not an Act VIII stage)"
	var parts := PackedStringArray()
	for t: String in e.order:
		parts.append("%s %s" % [t, EmpireReport._clock(float(e.began[t])) if e.began.has(t) else "-"])
	return "%s | last tier %s | supers sent %d" % [" | ".join(parts), String(e.cfg["last"]), e.supers_sent]
