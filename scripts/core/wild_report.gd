## WildReport — the autotest summary lines of the Turning Year's shared rules
## and stages (temporary Act XV; GDD §15.0 "The Turning Year foundation (phase
## 1)"), called once by Autotest.finish(). Every line prints only when the
## Wild's rules ran this run (Game.wild exists: a Wild stage, or a Wild kind
## forced onto another stage with --spawn=), so every other act's summaries
## keep their exact text:
##   turning year:     SeasonCycle (on/off, each season entered and when, the
##                     roots' grabs on you / summons / enemies, the wildfires'
##                     fronts and burns and kills, the snow refreshes, the
##                     blizzards, the waves' groups held for another season)
##   bloom and blight: BloomField (peak blighted and dead cells, cells now,
##                     HP the Wild healed on living ground)
##   overgrowth:       Thickets (seeds planted / capped / blocked / died,
##                     thickets grown, peak, burnt, withered, spreads, catches)
##   spring returns:   SpringReturns (only once the Reckoning ran: began, the
##                     sproutings, the burials and their damage)
##   wild kinds:       spawns / kills of every Wild kind that spawned, its first
##                     appearance, its damage to the necromancer and to
##                     summons, grouped by group
##   wild stage:       the Wild stage itself (stub status, boss, Soul Ash, the
##                     year's length, the Reckoning)
##   wild damage:      EVERY source of damage to the necromancer and to the
##                     summons this run, the largest first: enemy kinds, the
##                     boss and its attacks, and the rules (the wildfires, the
##                     burials, ...), each "source you/summons" (so a balance
##                     pass sees the rules too, not only the kinds; the roots
##                     and the thickets hold, they never hurt: their lines
##                     above count them)
## Phase 2 adds one line per stage system here (each stage in its own block).
## Read-only: it never changes the run.
class_name WildReport
extends RefCounted


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var w := game.wild  # The Wild's rules (null when they never ran).
	if w == null:
		return
	print("[autotest] turning year: %s" % year_line(game, st))
	var b := w.bloom
	print("[autotest] bloom and blight: %s | peak cells %d (dead %d) | cells now %d | the Wild healed %d on living ground" % [
		"on" if b.enabled else "off (not a Wild stage)", b.peak_cells, b.peak_full, b.cells.size(), int(b.healed)])
	var t := w.thickets
	print("[autotest] overgrowth: seeds %d (capped %d, blocked %d, died %d) | thickets grown %d (peak %d, standing %d) | burnt %d | withered %d | spreads %d | summons caught %d" % [
		int(st.get("thicket_seeds", 0.0)), int(st.get("thicket_seeds_capped", 0.0)), int(st.get("thicket_seeds_blocked", 0.0)),
		int(st.get("thicket_seeds_died", 0.0)), int(st.get("thickets_grown", 0.0)), t.peak, t.thickets.size(),
		int(st.get("thickets_burnt", 0.0)), int(st.get("thickets_withered", 0.0)), int(st.get("thicket_spreads", 0.0)),
		int(st.get("thicket_catches", 0.0))])
	if w.returns.running():
		print("[autotest] spring returns: began %s | sproutings %d | burials %d (raw dmg %d)" % [
			EmpireReport._clock(w.returns.started_at), w.returns.sproutings, w.returns.buried, int(st.get("returns_bury_dmg", 0.0))])
	var kinds_line := kinds_line_of(game, st)
	if kinds_line != "":
		print("[autotest] wild kinds (spawned/killed): %s" % kinds_line)
	var sd := game.stage_def  # The run's stage.
	if bool(sd.get("wild", false)):
		var boss: Dictionary = sd["boss"]
		print("[autotest] wild stage: %s (%s) | act %d | playable %s | boss %s (script %s) | enemy x%.2f HP / x%.2f dmg from %s | soul ash x%.2f | season %d s | reckoning kind %s, spring returns %s" % [
			String(sd["id"]), String(sd["display_name"]), StageRegistry.act_of(String(sd["id"])), str(StageRegistry.is_playable(String(sd["id"]))),
			String(boss["id"]), String(boss.get("script", boss["id"])), float(sd["enemy_hp_mult"]), float(sd["enemy_damage_mult"]),
			EmpireReport._clock(float(sd.get("enemy_mult_from", 0.0))), float(sd["ash_mult"]), int(w.seasons.cfg["length"]),
			String((sd["reckoning"] as Dictionary).get("kind", "inquisitor")), str(w.returns.on())])
	print("[autotest] wild damage (you/summons): %s" % PrimevalReport.damage_line(st))
	# Phase 2: each Wild stage's own lines go here (its stage, kinds and boss).
	# --- Act XV (temporary number): the Greenwood ---
	GreenwoodReport.stage_lines(game, st)  # The sacred groves, the Huntsman, the kinds' specials, Scorched Earth, the Stag King.
	# --- Act XV (temporary number): the Fae Court ---
	FaeCourtReport.stage_lines(game, st)  # The endless summer, the fairy rings, the Winter Prince, the Summer Queen, A Fair Bargain.


## The "turning year" line (SeasonCycle).
static func year_line(game: Game, st: Dictionary) -> String:
	var sc := game.wild.seasons
	var seen := PackedStringArray()
	for e: Array in sc.entered:
		seen.append("%s %s" % [WildRulesData.SEASON_IDS[int(e[0])], EmpireReport._clock(float(e[1]))])
	return "%s | seasons %s | roots: you %d, summons %d, enemies %d | wildfires %d: burned summons %d (raw dmg %d), you %d, enemies %d (killed %d) | snow refreshes %d | blizzards %d | wave groups held %d" % [
		"on" if sc.enabled else "off (not a Wild stage)", ", ".join(seen) if not seen.is_empty() else "-",
		int(st.get("roots_you", 0.0)), int(st.get("roots_summons", 0.0)), int(st.get("roots_enemies", 0.0)),
		sc.fires, int(st.get("wildfire_summons", 0.0)), int(st.get("wildfire_summon_dmg", 0.0)), int(st.get("wildfire_player", 0.0)),
		int(st.get("wildfire_enemies", 0.0)), int(st.get("wildfire_kills", 0.0)), int(st.get("snow_slows", 0.0)), sc.blizzards,
		int(st.get("season_groups_held", 0.0))]


## The "wild kinds" line: every Wild kind that spawned, grouped by group ("" when none did).
static func kinds_line_of(game: Game, st: Dictionary) -> String:
	var w := game.wild
	var groups := PackedStringArray()
	for grp: String in WildRulesData.GROUPS:
		var parts := PackedStringArray()
		for table: Dictionary in [WildEnemyData.ENEMIES, GreenwoodEnemyData.ENEMIES, FaeCourtEnemyData.ENEMIES, WorldTreeEnemyData.ENEMIES]:
			for k: String in table:
				if String((table[k] as Dictionary).get("group", "")) != grp:
					continue
				var spawned := int(st.get("spawned_" + k, 0.0))
				var killed := int(st.get("kill_" + k, 0.0))
				if spawned > 0 or killed > 0:
					var first := EmpireReport._clock(float(w.first_seen[k])) if w.first_seen.has(k) else "-"
					parts.append("%s %d/%d first %s (dmg to you %d, to summons %d)" % [k, spawned, killed, first,
						int(st.get("player_dmg_from_" + k, 0.0)), int(st.get("summon_dmg_from_" + k, 0.0))])
		if not parts.is_empty():
			groups.append("%s: %s" % [grp, ", ".join(parts)])
	return " | ".join(groups)
