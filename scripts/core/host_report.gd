## HostReport — the autotest summary lines of the Celestial Host's shared
## rules and stages (temporary Act XIII; GDD §15.0 "The Celestial Host
## foundation (phase 1)"), called once by Autotest.finish(). Every line prints
## only when the Host ran this run (Game.host exists: a Host stage, or a Host
## kind forced onto another stage with --spawn=), so every other act's
## summaries keep their exact text:
##   judgment:        the scales (sins raised / replaced and refused during a
##                    Verdict, peak weight, Judges sent and slain, Verdicts and
##                    their times, pillars fallen and their hits, resets)
##   hallowed light:  the shafts (opened / refused, burns on summons and their
##                    damage, burns on you, shaded, blocked, angel heals, live
##                    cloud shadows peak)
##   grace:           the halos (halos come down, hits shrugged off, the top
##                    kinds, halos regrown by Dominions)
##   last trumpet:    LastTrumpet (only once the Reckoning ran: began,
##                    trumpets, the Host it called, the sky open)
##   host kinds:      spawns / kills of every Host kind that spawned, its first
##                    appearance, its damage to the necromancer and to
##                    summons, grouped by group
##   host stage:      the Host stage itself (stub status, boss, Soul Ash, the
##                    Reckoning)
## Phase 2 adds one line per stage system here (each stage in its own block):
## the Silver Stair's are SilverStairReport's, the Wheel of Thrones'
## WheelOfThronesReport's.
## Read-only: it never changes the run.
class_name HostReport
extends RefCounted

## Most damage kinds the "grace" line names (the top ones by hits shrugged off).
const TOP_KINDS: int = 6


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var ho := game.host  # The Host's rules (null when they never ran).
	if ho == null:
		return
	print("[autotest] judgment: %s" % judgment_line(game, st))
	print("[autotest] hallowed light: %s" % light_line(game, st))
	print("[autotest] grace: %s" % grace_line(game))
	if ho.trumpet.running():
		print("[autotest] last trumpet: began %s | trumpets %d | host called %d | sky open %s | light width x%.2f" % [
			EmpireReport._clock(ho.trumpet.started_at), ho.trumpet.sounded, int(st.get("trumpet_host_spawned", 0.0)),
			str(ho.trumpet.sky_open), ho.light.width_mult])
	var kinds_line := kinds_line_of(game, st)
	if kinds_line != "":
		print("[autotest] host kinds (spawned/killed): %s" % kinds_line)
	var sd := game.stage_def  # The run's stage.
	if bool(sd.get("host", false)):
		var boss: Dictionary = sd["boss"]
		print("[autotest] host stage: %s (%s) | act %d | playable %s | boss %s (script %s) | enemy x%.2f HP / x%.2f dmg from %s | soul ash x%.2f | reckoning kind %s, last trumpet %s" % [
			String(sd["id"]), String(sd["display_name"]), StageRegistry.act_of(String(sd["id"])), str(StageRegistry.is_playable(String(sd["id"]))),
			String(boss["id"]), String(boss.get("script", boss["id"])), float(sd["enemy_hp_mult"]), float(sd["enemy_damage_mult"]),
			EmpireReport._clock(float(sd.get("enemy_mult_from", 0.0))), float(sd["ash_mult"]),
			String((sd["reckoning"] as Dictionary).get("kind", "inquisitor")), str(not ho.trumpet.cfg.is_empty())])
	# Phase 2: each Host stage's own lines go here (its stage, kinds and boss).
	# --- Act XIII (temporary number): the Silver Stair --- (its stage, the Cherubs, Seraiel; SilverStairReport)
	SilverStairReport.stage_lines(game, st)
	# --- Act XIII (temporary number): the Wheel of Thrones --- (its stage, the Ophans and the Dominion, the Throne; WheelOfThronesReport)
	WheelOfThronesReport.stage_lines(game, st)


## The "judgment" line (Judgment).
static func judgment_line(game: Game, st: Dictionary) -> String:
	var j := game.host.judgment
	return "%s | sins: raised %d, replaced %d, refused during a verdict %d | peak %.1f / %.0f | judges sent %d, slain %d | verdicts %d at %s | pillars %d (hits on you %d, on summons %d) | resets %d" % [
		"on" if j.enabled else "off (not a Host stage)", j.raised, j.replaced, j.refused, j.peak, float(j.cfg["capacity"]),
		j.judges_sent, j.judges_slain, j.verdicts, ", ".join(j.verdict_times) if not j.verdict_times.is_empty() else "-",
		j.pillars_fallen, int(st.get("verdict_player_hits", 0.0)), int(st.get("verdict_summon_hits", 0.0)),
		int(st.get("judgment_resets", 0.0))]


## The "hallowed light" line (HallowedLight and its CloudShade).
static func light_line(game: Game, st: Dictionary) -> String:
	var l := game.host.light
	return "shafts %d (refused %d) | summon burns %d (dmg %d) | burns on you %d | shaded %d | blocked %d | angel heals %d | cloud shadows peak live %d" % [
		l.opened, l.refused, int(st.get("light_summon_burns", 0.0)), int(st.get("light_summon_dmg", 0.0)),
		int(st.get("light_player_burns", 0.0)), int(st.get("light_shaded", 0.0)), int(st.get("light_blocked", 0.0)),
		int(st.get("light_angel_heals", 0.0)), l.clouds.peak]


## The "grace" line (Grace): the top TOP_KINDS kinds by hits shrugged off
## (ties by name, so the line is stable).
static func grace_line(game: Game) -> String:
	var g := game.host.grace
	var keys := g.by_kind.keys()
	keys.sort_custom(func(a: String, b: String) -> bool:
		var na := int(g.by_kind[a])
		var nb := int(g.by_kind[b])
		return na > nb or (na == nb and a < b))
	var top := PackedStringArray()
	for k: String in keys.slice(0, TOP_KINDS):
		top.append("%s %d" % [k, int(g.by_kind[k])])
	return "halos %d | hits shrugged off %d (%d kinds: %s) | regrown by Dominions %d" % [
		g.halos, g.absorbed, g.by_kind.size(), ", ".join(top) if not top.is_empty() else "-", g.regrown]


## The "host kinds" line: every Host kind that spawned, grouped by group (""
## when none did).
static func kinds_line_of(game: Game, st: Dictionary) -> String:
	var ho := game.host
	var groups := PackedStringArray()
	for grp: String in HostRulesData.GROUPS:
		var parts := PackedStringArray()
		for table: Dictionary in [HostEnemyData.ENEMIES, SilverStairEnemyData.ENEMIES, WheelOfThronesEnemyData.ENEMIES, EmpyreanEnemyData.ENEMIES]:
			for k: String in table:
				if String((table[k] as Dictionary).get("group", "")) != grp:
					continue
				var spawned := int(st.get("spawned_" + k, 0.0))
				var killed := int(st.get("kill_" + k, 0.0))
				if spawned > 0 or killed > 0:
					var first := EmpireReport._clock(float(ho.first_seen[k])) if ho.first_seen.has(k) else "-"
					parts.append("%s %d/%d first %s (dmg to you %d, to summons %d)" % [k, spawned, killed, first,
						int(st.get("player_dmg_from_" + k, 0.0)), int(st.get("summon_dmg_from_" + k, 0.0))])
		if not parts.is_empty():
			groups.append("%s: %s" % [grp, ", ".join(parts)])
	if groups.is_empty():
		return ""
	return " | ".join(groups) + " | power lunges %d (summon hits %d, on you %d) | herald blasts %d (pushed %d, called %d) | choir heals %d" % [
		int(st.get("power_lunges", 0.0)), int(st.get("power_lunge_summon_hits", 0.0)), int(st.get("power_lunge_player_hits", 0.0)),
		int(st.get("herald_blasts", 0.0)), int(st.get("herald_pushed", 0.0)), int(st.get("herald_called", 0.0)),
		int(st.get("choir_heals", 0.0))]
