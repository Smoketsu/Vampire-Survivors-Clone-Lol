## PrimevalReport — the autotest summary lines of the Age of Titans' shared
## rules and stages (temporary Act XIV; GDD §15.0 "The Age of Titans
## foundation (phase 1)"), called once by Autotest.finish(). Every line prints
## only when the Titans' rules ran this run (Game.primeval exists: a Titans
## stage, or a Titans kind forced onto another stage with --spawn=), so every
## other act's summaries keep their exact text:
##   packs:            PackBrain (packs formed, circles, rushes, alphas slain
##                     and the members that charged in blind, peak live)
##   herds:            Herds (on/off, herds and the peak of beasts, stampedes,
##                     the trample on summons / you / enemies and its kills,
##                     sheltered bodies, beasts killed, Fossil Giants raised,
##                     capped and too far)
##   scavengers:       Scavengers (thieves peak, dives and empty dives, piles
##                     snatched, dropped by a kill and carried to the nests)
##   stampede of ash:  StampedeOfAsh (only once the Reckoning ran: began, the
##                     herds it brought, the bombs and their hits)
##   primeval kinds:   spawns / kills of every Titans kind that spawned, its
##                     first appearance, its damage to the necromancer and to
##                     summons, grouped by group
##   primeval stage:   the Titans stage itself (stub status, boss, Soul Ash,
##                     the Reckoning)
##   primeval damage:  EVERY source of damage to the necromancer and to the
##                     summons this run, the largest first: enemy kinds, the
##                     boss and its attacks, and the rules (the trample, the
##                     bombs, ...), each "source you/summons" (so a balance
##                     pass sees the rules too, not only the kinds)
## Phase 2 adds one line per stage system here (each stage in its own block):
## the Fern Basin's are FernBasinReport's.
## Read-only: it never changes the run.
class_name PrimevalReport
extends RefCounted


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var pr := game.primeval  # The Titans' rules (null when they never ran).
	if pr == null:
		return
	var pk := pr.packs
	print("[autotest] packs: formed %d | circles %d | rushes %d | alphas slain %d (members charged in blind %d) | peak live %d" % [
		pk.formed, pk.circles, pk.rushes, pk.alphas_slain, pk.broken_members, pk.peak])
	print("[autotest] herds: %s" % herds_line(game, st))
	print("[autotest] scavengers: %s" % scavengers_line(game, st))
	if pr.ash.running():
		print("[autotest] stampede of ash: began %s | herds %d | bombs %d (hits on summons %d, on you %d, on enemies %d)" % [
			EmpireReport._clock(pr.ash.started_at), pr.ash.stampedes, pr.ash.bombs_landed,
			int(st.get("ash_bomb_summon_hits", 0.0)), int(st.get("ash_bomb_player_hits", 0.0)), int(st.get("ash_bomb_enemy_hits", 0.0))])
	var kinds_line := kinds_line_of(game, st)
	if kinds_line != "":
		print("[autotest] primeval kinds (spawned/killed): %s" % kinds_line)
	var sd := game.stage_def  # The run's stage.
	if bool(sd.get("primeval", false)):
		var boss: Dictionary = sd["boss"]
		print("[autotest] primeval stage: %s (%s) | act %d | playable %s | boss %s (script %s) | enemy x%.2f HP / x%.2f dmg from %s | soul ash x%.2f | reckoning kind %s, stampede of ash %s" % [
			String(sd["id"]), String(sd["display_name"]), StageRegistry.act_of(String(sd["id"])), str(StageRegistry.is_playable(String(sd["id"]))),
			String(boss["id"]), String(boss.get("script", boss["id"])), float(sd["enemy_hp_mult"]), float(sd["enemy_damage_mult"]),
			EmpireReport._clock(float(sd.get("enemy_mult_from", 0.0))), float(sd["ash_mult"]),
			String((sd["reckoning"] as Dictionary).get("kind", "inquisitor")), str(not pr.ash.cfg.is_empty())])
	print("[autotest] primeval damage (you/summons): %s" % damage_line(st))
	# Phase 2: each Titans stage's own lines go here (its stage, kinds and boss).
	# --- Act XIV (temporary number): the Fern Basin --- (its stage, Scarmaw; FernBasinReport)
	FernBasinReport.stage_lines(game, st)


## The "primeval damage" line: every damage source to the necromancer
## (player_dmg_from_<source>) and to the summons (summon_dmg_from_<source>),
## sorted by their sum, largest first ("none" when nothing hurt either).
static func damage_line(st: Dictionary) -> String:
	var you := {}  # Source -> damage to the necromancer.
	var army := {}  # Source -> damage to the summons.
	for k: String in st:
		if k.begins_with("player_dmg_from_"):
			you[k.substr(16)] = float(st[k])
		elif k.begins_with("summon_dmg_from_"):
			army[k.substr(16)] = float(st[k])
	var srcs: Array = []
	for s: String in you:
		srcs.append(s)
	for s: String in army:
		if not you.has(s):
			srcs.append(s)
	srcs.sort_custom(func(a: String, b: String) -> bool:
		var ta := float(you.get(a, 0.0)) + float(army.get(a, 0.0))
		var tb := float(you.get(b, 0.0)) + float(army.get(b, 0.0))
		return ta > tb or (ta == tb and a < b))
	var parts := PackedStringArray()
	for s: String in srcs:
		parts.append("%s %d/%d" % [s, int(you.get(s, 0.0)), int(army.get(s, 0.0))])
	return ", ".join(parts) if not parts.is_empty() else "none"


## The "herds" line (Herds).
static func herds_line(game: Game, st: Dictionary) -> String:
	var h := game.primeval.herds
	return "%s | herds %d (peak beasts %d) | stampedes %d | trampled: summons %d (dmg %d), you %d, enemies %d (killed %d) | sheltered %d | beasts killed %d | fossil giants %d (capped %d, too far %d)" % [
		"on" if h.enabled else "off (not a Titans stage)", h.spawned, h.peak, h.stampedes,
		int(st.get("trample_summons", 0.0)), int(st.get("trample_summon_dmg", 0.0)), int(st.get("trample_player", 0.0)),
		int(st.get("trample_enemies", 0.0)), int(st.get("trample_kills", 0.0)), int(st.get("trample_sheltered", 0.0)),
		int(st.get("herd_kills", 0.0)), int(st.get("fossil_giants", 0.0)), int(st.get("fossil_giants_capped", 0.0)),
		int(st.get("fossil_giants_far", 0.0))]


## The "scavengers" line (Scavengers).
static func scavengers_line(game: Game, st: Dictionary) -> String:
	var s := game.primeval.scavengers
	return "thieves peak %d | dives %d (empty %d) | snatched %d piles, %d crystals, %d xp | dropped by a kill %d piles, %d crystals, %d xp | to the nests %d piles, %d xp lost" % [
		s.peak, int(st.get("scav_dives", 0.0)), int(st.get("scav_dives_empty", 0.0)),
		int(st.get("scav_snatches", 0.0)), int(st.get("scav_crystals_taken", 0.0)), int(st.get("scav_xp_taken", 0.0)),
		int(st.get("scav_drops", 0.0)), int(st.get("scav_crystals_dropped", 0.0)), int(st.get("scav_xp_dropped", 0.0)),
		int(st.get("scav_nests", 0.0)), int(st.get("scav_xp_lost", 0.0))]


## The "primeval kinds" line: every Titans kind that spawned, grouped by group
## ("" when none did).
static func kinds_line_of(game: Game, st: Dictionary) -> String:
	var pr := game.primeval
	var groups := PackedStringArray()
	for grp: String in PrimevalRulesData.GROUPS:
		var parts := PackedStringArray()
		for table: Dictionary in [PrimevalEnemyData.ENEMIES, FernBasinEnemyData.ENEMIES, GreatPlainEnemyData.ENEMIES, LastDayEnemyData.ENEMIES]:
			for k: String in table:
				if String((table[k] as Dictionary).get("group", "")) != grp:
					continue
				var spawned := int(st.get("spawned_" + k, 0.0))
				var killed := int(st.get("kill_" + k, 0.0))
				if spawned > 0 or killed > 0:
					var first := EmpireReport._clock(float(pr.first_seen[k])) if pr.first_seen.has(k) else "-"
					parts.append("%s %d/%d first %s (dmg to you %d, to summons %d)" % [k, spawned, killed, first,
						int(st.get("player_dmg_from_" + k, 0.0)), int(st.get("summon_dmg_from_" + k, 0.0))])
		if not parts.is_empty():
			groups.append("%s: %s" % [grp, ", ".join(parts)])
	return " | ".join(groups)
