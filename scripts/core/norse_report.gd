## NorseReport — the autotest summary lines of the Hall of the Slain's shared
## rules and stages (the Norse act, temporarily Act XI; GDD §15.0 "The Hall of
## the Slain foundation (phase 1)"), called once by Autotest.finish(). Every
## line prints only when the Norse rules ran this run (Game.norse exists: a
## Norse stage, or a Norse kind forced onto another stage with --spawn=), so
## every other act's summaries keep their exact text:
##   long winter:    LongWinter (the cold level reached, braziers placed / lit
##                   at the end, doused (by kind) / relit, the longest outage,
##                   the relights' Soul Ash, the time the necromancer and the
##                   army spent cold, the slows, the frostbite)
##   berserkergang:  the furies (wounded into it, by kind; berserkers born in
##                   it) and the slows / stuns / freezes the fury shrugged off
##   rune-stones:    RuneStones (raised, refused, taken and when, re-carved,
##                   held at the end, horns and their squads, ward hits, Soul
##                   Ash; the seers' walks and carving)
##   ragnarok:       Ragnarok (only once the Reckoning ran: Einherjar that
##                   marched, fire-giants, dives forced)
## (The valkyries' air whiffs and hits are on the "norse kinds" line.)
##   norse kinds:    spawns / kills of every Norse kind that spawned, its first
##                   appearance, its damage to the necromancer and to summons,
##                   grouped by group, and the kinds' specials
##   norse stage:    the Norse stage itself (stub status, boss, Soul Ash, the
##                   Reckoning)
## Phase 2 adds one line per stage system here (each stage in its own block):
##   the Barrow Fields: BarrowFieldsReport ("barrow fields", "barrow wight",
##                   "hrimgar").
## Read-only: it never changes the run.
class_name NorseReport
extends RefCounted

## Temporary act number of the Hall of the Slain (docs/last_acts/PLAN.md; the
## reorder pass renumbers it from one ordered list).
const ACT: int = 11


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var n := game.norse  # The Norse rules (null when they never ran).
	if n == null:
		return
	print("[autotest] long winter: %s" % winter_line(game, st))
	print("[autotest] berserkergang: furies %d (%s) | berserkers born in it %d | shrugged off: slows %d, stuns %d, freezes %d" % [
		n.furies, _by_prefix(st, "norse_fury_"), int(st.get("spawned_" + NorseEnemyData.BERSERKER, 0.0)),
		int(st.get("berserk_shrugged_slows", 0.0)), int(st.get("berserk_shrugged_stuns", 0.0)), int(st.get("berserk_shrugged_freezes", 0.0))])
	print("[autotest] rune-stones: %s" % stones_line(game, st))
	if n.ragnarok.running():
		print("[autotest] ragnarok: began %s | einherjar marched %d | fire-giants %d | dives forced %d" % [
			EmpireReport._clock(n.ragnarok.started_at), n.ragnarok.einherjar,
			n.ragnarok.giants, int(st.get("ragnarok_dives_forced", 0.0))])
	var kinds := kinds_line_of(game, st)
	if kinds != "":
		print("[autotest] norse kinds (spawned/killed): %s" % kinds)
	var sd := game.stage_def  # The run's stage.
	if StageRegistry.act_of(String(sd["id"])) == ACT:
		var boss: Dictionary = sd["boss"]
		print("[autotest] norse stage: %s (%s) | playable %s | boss %s (script %s) | enemy x%.2f HP / x%.2f dmg from %s | soul ash x%.2f | reckoning kind %s, ragnarok %s" % [
			String(sd["id"]), String(sd["display_name"]), str(StageRegistry.is_playable(String(sd["id"]))),
			String(boss["id"]), String(boss.get("script", boss["id"])), float(sd["enemy_hp_mult"]), float(sd["enemy_damage_mult"]),
			EmpireReport._clock(float(sd.get("enemy_mult_from", 0.0))), float(sd["ash_mult"]),
			String((sd["reckoning"] as Dictionary).get("kind", "inquisitor")), str(not n.ragnarok.cfg.is_empty())])
	# Phase 2: each Norse stage's own lines go here (its stage, kinds and boss).
	# --- Act XI (temporary): the Barrow Fields ---
	BarrowFieldsReport.print_lines(game, st)  # The braziers by the map, the barrows, the drifts, Keep the Fires, the Wight, Hrimgar.


## The "long winter" line (LongWinter).
static func winter_line(game: Game, st: Dictionary) -> String:
	var w := game.norse.winter
	return "%s | cold level reached %d | braziers %d (lit at the end %d) | doused %d (%s) | relit %d (soul ash %d) | longest out %.1f s | cold: you %.1f s, army %.1f summon-s | slows %d | frostbite %d" % [
		"on" if w.enabled else "off (not a Norse stage)", w.peak_level, w.braziers.size(), w.lit_count(), w.doused,
		_by_prefix(st, "braziers_doused_by_"), w.relit, int(w.relight_ash), w.longest_out(),
		float(st.get("winter_player_cold_s", 0.0)), float(st.get("winter_summon_cold_s", 0.0)), int(st.get("winter_slows", 0.0)),
		int(st.get("summon_dmg_from_" + NorseRulesData.FROSTBITE_SOURCE, 0.0))]


## The "rune-stones" line (RuneStones).
static func stones_line(game: Game, st: Dictionary) -> String:
	var s := game.norse.stones
	return "raised %d (refused %d) | taken %d (%s) | re-carved %d | held at the end %d of %d | horns %d (units %d, capped %d) | ward hits %d | soul ash %d | seers: walk ticks %d, carving %.1f s, curses %d (landed %d)" % [
		s.raised, int(st.get("rune_stones_refused", 0.0)), s.taken, ", ".join(s.take_times) if not s.take_times.is_empty() else "-",
		s.recarved, s.held_count(), s.stones.size(), s.horns, int(st.get("rune_horn_units", 0.0)), int(st.get("rune_horns_capped", 0.0)),
		int(st.get("rune_ward_hits", 0.0)), int(s.take_ash), int(st.get("seer_walks", 0.0)), float(st.get("seer_carve_seconds", 0.0)),
		int(st.get("seer_curses", 0.0)), int(st.get("seer_curse_hits", 0.0))]


## The "norse kinds" line: every Norse kind that spawned, grouped by group,
## then the kinds' specials ("" when none spawned).
static func kinds_line_of(game: Game, st: Dictionary) -> String:
	var n := game.norse
	var groups := PackedStringArray()
	for grp: String in NorseRulesData.GROUPS:
		var parts := PackedStringArray()
		for table: Dictionary in [NorseEnemyData.ENEMIES, BarrowFieldsEnemyData.ENEMIES, ValgardEnemyData.ENEMIES, VigridEnemyData.ENEMIES]:
			for k: String in table:
				if String((table[k] as Dictionary).get("group", "")) != grp:
					continue
				var spawned := int(st.get("spawned_" + k, 0.0))
				var killed := int(st.get("kill_" + k, 0.0))
				if spawned > 0 or killed > 0:
					var first := EmpireReport._clock(float(n.first_seen[k])) if n.first_seen.has(k) else "-"
					parts.append("%s %d/%d first %s (dmg to you %d, to summons %d)" % [k, spawned, killed, first,
						int(st.get("player_dmg_from_" + k, 0.0)), int(st.get("summon_dmg_from_" + k, 0.0))])
		if not parts.is_empty():
			groups.append("%s: %s" % [grp, ", ".join(parts)])
	if groups.is_empty():
		return ""
	return " | ".join(groups) + " | bashes %d (hit %d), verses %d (warriors sung %d), lunges %d (hit %d), boulders %d (hits %d), stomps %d (hits %d), valkyrie dives %d (summon hits %d), draugr chills %d | valkyries aloft: whiffs %d, hits %d" % [
		int(st.get("maiden_bashes", 0.0)), int(st.get("maiden_bash_hits", 0.0)), int(st.get("skald_verses", 0.0)),
		int(st.get("skald_warriors_sung", 0.0)), int(st.get("wolf_lunges", 0.0)), int(st.get("wolf_lunge_hits", 0.0)),
		int(st.get("giant_boulders", 0.0)), int(st.get("giant_boulder_hits", 0.0)), int(st.get("giant_stomps", 0.0)),
		int(st.get("giant_stomp_hits", 0.0)), int(st.get("valkyrie_dives", 0.0)), int(st.get("valkyrie_dive_hits", 0.0)),
		int(st.get("draugr_chills", 0.0)), int(st.get("norse_air_whiffs", 0.0)), int(st.get("norse_air_hits", 0.0))]


## "a 3, b 1" of every stat whose name starts with `prefix` (sorted), or "-".
static func _by_prefix(st: Dictionary, prefix: String) -> String:
	var keys: Array = []
	for k: String in st:
		if k.begins_with(prefix):
			keys.append(k)
	keys.sort()
	var parts := PackedStringArray()
	for k: String in keys:
		parts.append("%s %d" % [k.trim_prefix(prefix), int(st[k])])
	return ", ".join(parts) if not parts.is_empty() else "-"
