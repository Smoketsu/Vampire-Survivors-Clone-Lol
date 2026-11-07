## ShogunateReport — the autotest summary lines of the Shogunate of the Rising
## Sun's shared rules and stages (Act V; GDD §15.0 "Act V foundation (phase
## 1)"), called once by Autotest.finish(). Every line prints only when the
## Shogunate ran this run (Game.shogunate exists: an Act V stage, or a Shogunate
## kind forced onto another stage with --spawn=), so the Act I to IV summaries
## keep their exact text:
##   sun's course:      SunCourse (when each phase began, lanterns lit,
##                      ambushes revealed in light, night groups held back,
##                      night kinds activated by day (should be 0), Reckoning
##                      enemies quickened by the Endless Night)
##   the draw:          DrawCuts (lines drawn and on the necromancer, cuts,
##                      refused / cancelled, the most at once, bodies cut by
##                      kind, damage to summons vs the necromancer, dodged by
##                      the bot)
##   from the shadows:  ShadowAmbush (squads, units, appeared, inside the ring,
##                      shadow spots, revealed in light, the average warning)
##   shogunate kinds:   spawns / kills of every Shogunate kind that spawned,
##                      its first appearance, and the kits' counters
##   shogunate stage:   the Act V stage itself (stub status, boss, Soul Ash,
##                      the Reckoning)
## Phase 2 adds one line per stage system here (each stage in its own block):
##   Act V, the Burning Province: ProvinceReport.print_lines() (province,
##   province kinds, shuten-doji, kage).
##   the Road to the Sun: SunRoadReport.stage_lines() (the director, its events,
##                      its kinds, Amaterasu and her sky).
##   Act V, Castle Kurogane: KuroganeReport.print_lines() (kurogane, kurogane
##   kinds, general of the left, shogun).
## Read-only: it never changes the run.
class_name ShogunateReport
extends RefCounted


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var sh := game.shogunate  # The Shogunate's rules (null when they never ran).
	if sh == null:
		return
	print("[autotest] sun's course: %s" % sun_line(game, st))
	print("[autotest] the draw: %s" % draw_line(game, st))
	print("[autotest] from the shadows: %s" % ambush_line(game, st))
	var parts := PackedStringArray()  # "kind spawned/killed" per Shogunate kind seen.
	var kinds: Array = []  # Every Shogunate kind id, the shared table first.
	for table: Dictionary in [ShogunateEnemyData.ENEMIES, ProvinceEnemyData.ENEMIES, KuroganeEnemyData.ENEMIES, SunRoadEnemyData.ENEMIES]:
		kinds.append_array(table.keys())
	for k: String in kinds:
		var spawned := int(st.get("spawned_" + k, 0.0))
		var killed := int(st.get("kill_" + k, 0.0))
		if spawned > 0 or killed > 0:
			var first := EmpireReport._clock(float(sh.first_seen[k])) if sh.first_seen.has(k) else "-"
			parts.append("%s %d/%d first %s (dmg to you %d, to summons %d)" % [k, spawned, killed, first,
				int(st.get("player_dmg_from_" + k, 0.0)), int(st.get("summon_dmg_from_" + k, 0.0))])
	if not parts.is_empty():
		print("[autotest] shogunate kinds (spawned/killed): %s | samurai draws %d, teppo shots %d, ninja shuriken %d, oni smashes %d (summons stunned %d)" % [
			" | ".join(parts), int(st.get("samurai_draws", 0.0)), int(st.get("teppo_shots", 0.0)), int(st.get("ninja_shuriken", 0.0)),
			int(st.get("oni_smashes", 0.0)), int(st.get("oni_stuns", 0.0))])
	var sd := game.stage_def  # The run's stage.
	if StageRegistry.act_of(String(sd["id"])) == 5:
		var boss: Dictionary = sd["boss"]
		print("[autotest] shogunate stage: %s (%s) | playable %s | boss %s (script %s) | enemy x%.2f HP / x%.2f dmg from %s | soul ash x%.2f | reckoning kind %s, endless night %s" % [
			String(sd["id"]), String(sd["display_name"]), str(StageRegistry.is_playable(String(sd["id"]))),
			String(boss["id"]), String(boss.get("script", boss["id"])), float(sd["enemy_hp_mult"]), float(sd["enemy_damage_mult"]),
			EmpireReport._clock(float(sd.get("enemy_mult_from", 0.0))), float(sd["ash_mult"]),
			String((sd["reckoning"] as Dictionary).get("kind", "inquisitor")), str(not sh.sun.endless.is_empty())])
	# --- Act V: the Burning Province ---
	ProvinceReport.print_lines(game, st)  # The paddies, the fires, the stage's kinds, Shuten-doji, Kage (each when it ran).
	# --- Act V: the Road to the Sun ---
	SunRoadReport.stage_lines(game, st)
	# --- Act V: Castle Kurogane ---
	KuroganeReport.print_lines(game, st)  # The General of the Left, the stage's kinds, the Shogun (each when it ran).


## The "sun's course" line (SunCourse).
static func sun_line(game: Game, st: Dictionary) -> String:
	var sun := game.shogunate.sun
	if not sun.enabled:
		return "off (not an Act V stage: always day)"
	var ph := PackedStringArray()  # "phase @clock" for each phase reached.
	for p: int in [ShogunateRulesData.Phase.DAY, ShogunateRulesData.Phase.DUSK, ShogunateRulesData.Phase.NIGHT, ShogunateRulesData.Phase.ENDLESS_NIGHT]:
		if sun.phase_started.has(p):
			ph.append("%s @%s" % [ShogunateRulesData.PHASE_NAMES[p], EmpireReport._clock(float(sun.phase_started[p]))])
	return "phases %s | lanterns lit %d (lit at the end %d) | ambushes revealed in light %d | night groups held by day %d | night kinds by day %d | reckoning quickened %d" % [
		", ".join(ph), int(st.get("sun_lanterns_lit", 0.0)), sun.lit.size(), int(st.get("ambush_lit", 0.0)),
		int(st.get("sun_night_groups_held", 0.0)), int(st.get("sun_night_kind_by_day", 0.0)), int(st.get("endless_quickened", 0.0))]


## The "the draw" line (DrawCuts).
static func draw_line(game: Game, st: Dictionary) -> String:
	var by := PackedStringArray()  # "class N" per summon class cut.
	for cls: String in UnitData.UNITS:
		var n := int(st.get("draw_cut_" + cls, 0.0))
		if n > 0:
			by.append("%s %d" % [cls, n])
	return "lines %d (on you %d), cuts %d, refused %d, cancelled %d, most at once %d | bodies cut: you %d, summons %s | dmg to summons %d, to you %d | dodged by the bot %d" % [
		int(st.get("draw_lines", 0.0)), int(st.get("draw_on_player", 0.0)), int(st.get("draw_cuts", 0.0)),
		int(st.get("draw_refused", 0.0)), int(st.get("draw_cancelled", 0.0)), game.shogunate.draws.peak,
		int(st.get("draw_cut_you", 0.0)), ", ".join(by) if not by.is_empty() else "none",
		int(st.get("draw_dmg_summons", 0.0)), int(st.get("draw_dmg_you", 0.0)), int(st.get("draw_dodged", 0.0))]


## The "from the shadows" line (ShadowAmbush).
static func ambush_line(_game: Game, st: Dictionary) -> String:
	var squads := int(st.get("ambush_squads", 0.0))
	return "squads %d (events waited for dusk %d), units %d, appeared %d, capped %d | inside the ring %d | shadow spots %d | revealed in light %d | average warning %.2f s" % [
		squads, int(st.get("ambush_waited", 0.0)), int(st.get("ambush_units", 0.0)), int(st.get("ambush_spawned", 0.0)),
		int(st.get("ambush_capped", 0.0)), int(st.get("ambush_in_ring", 0.0)), int(st.get("ambush_shadow_spots", 0.0)),
		int(st.get("ambush_lit", 0.0)), float(st.get("ambush_warn_total", 0.0)) / maxf(1.0, float(squads))]
