## InfernoReport — the autotest summary lines of the Inferno's shared rules and
## stages (Act VI; GDD §15.0 "Act VI foundation (phase 1)"), called once by
## Autotest.finish(). Every line prints only when the Inferno ran this run
## (Game.inferno exists: an Act VI stage, or an Inferno kind forced onto another
## stage with --spawn=), so the Act I to V summaries keep their exact text:
##   hell pits:     HellPits (pits opened by kind, the most fixed pits live,
##                  burns, damage to summons / the necromancer / enemies, kills,
##                  the damned burned)
##   portals:       DemonPortals (opened, destroyed, sealed with their times
##                  and the Soul Ash bounty, squads and units poured)
##   temptation:    Temptation (charms, the most at once, broken by the
##                  charmer's death, expired, freed, refused at the cap, damage
##                  done by charmed summons to summons / the necromancer, by
##                  class)
##   inferno kinds: spawns / kills of every Inferno kind that spawned, its first
##                  appearance, and the kits' counters
##   last judgment: LastJudgment (only once the Reckoning ran)
##   inferno stage: the Act VI stage itself (stub status, boss, Soul Ash, the
##                  Reckoning)
## Phase 2 adds one line per stage system here (each stage in its own block).
## Read-only: it never changes the run.
class_name InfernoReport
extends RefCounted


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var inf := game.inferno  # The Inferno's rules (null when they never ran).
	if inf == null:
		return
	print("[autotest] hell pits: %s" % pits_line(game, st))
	print("[autotest] portals: %s" % portals_line(game, st))
	print("[autotest] temptation: %s" % temptation_line(game, st))
	var parts := PackedStringArray()  # "kind spawned/killed" per Inferno kind seen.
	var kinds: Array = []  # Every Inferno kind id, the shared table first.
	for table: Dictionary in [InfernoEnemyData.ENEMIES, BurningGateEnemyData.ENEMIES, SilkPalaceEnemyData.ENEMIES, PandemoniumEnemyData.ENEMIES]:
		kinds.append_array(table.keys())
	for k: String in kinds:
		var spawned := int(st.get("spawned_" + k, 0.0))
		var killed := int(st.get("kill_" + k, 0.0))
		if spawned > 0 or killed > 0:
			var first := EmpireReport._clock(float(inf.first_seen[k])) if inf.first_seen.has(k) else "-"
			parts.append("%s %d/%d first %s (dmg to you %d, to summons %d)" % [k, spawned, killed, first,
				int(st.get("player_dmg_from_" + k, 0.0)), int(st.get("summon_dmg_from_" + k, 0.0))])
	if not parts.is_empty():
		print("[autotest] inferno kinds (spawned/killed): %s | knight sweeps %d (hits %d), succubus kisses %d (missed %d), brute slams %d (hits %d)" % [
			" | ".join(parts), int(st.get("hell_knight_sweeps", 0.0)), int(st.get("hell_knight_sweep_hits", 0.0)),
			int(st.get("succubus_kisses", 0.0)), int(st.get("succubus_kiss_missed", 0.0)),
			int(st.get("brute_slams", 0.0)), int(st.get("brute_slam_hits", 0.0))])
	if inf.judgment.running():
		print("[autotest] last judgment: began %s | portals opened %d | pits %d | hand grabs %d (on you %d, dodged %d, summons hit %d, enemies hit %d) | dmg to you %d, to summons %d" % [
			EmpireReport._clock(inf.judgment.started_at), int(st.get("judgment_portals", 0.0)), int(st.get("pits_opened_reckoning", 0.0)),
			int(st.get("hand_grabs", 0.0)), int(st.get("hand_hits_you", 0.0)), int(st.get("hand_dodged", 0.0)),
			int(st.get("hand_hits_summons", 0.0)), int(st.get("hand_hits_enemies", 0.0)),
			int(st.get("player_dmg_from_" + InfernoRulesData.HAND_SOURCE, 0.0)), int(st.get("summon_dmg_from_" + InfernoRulesData.HAND_SOURCE, 0.0))])
	var sd := game.stage_def  # The run's stage.
	if StageRegistry.act_of(String(sd["id"])) == 6:
		var boss: Dictionary = sd["boss"]
		print("[autotest] inferno stage: %s (%s) | playable %s | boss %s (script %s) | enemy x%.2f HP / x%.2f dmg from %s | soul ash x%.2f | reckoning kind %s, last judgment %s" % [
			String(sd["id"]), String(sd["display_name"]), str(StageRegistry.is_playable(String(sd["id"]))),
			String(boss["id"]), String(boss.get("script", boss["id"])), float(sd["enemy_hp_mult"]), float(sd["enemy_damage_mult"]),
			EmpireReport._clock(float(sd.get("enemy_mult_from", 0.0))), float(sd["ash_mult"]),
			String((sd["reckoning"] as Dictionary).get("kind", "inquisitor")), str(not inf.judgment.cfg.is_empty())])


## The "hell pits" line (HellPits).
static func pits_line(game: Game, st: Dictionary) -> String:
	var p := game.inferno.pits
	if not game.inferno.enabled:
		return "off (not an Act VI stage)"
	return "opened %d (timed %d, reckoning %d, opened by kinds %d), refused %d | fixed live peak %d (zone %d at the end) | burns %d | dmg to summons %d, to you %d, to enemies %d | pit kills %d, the damned burned %d" % [
		int(st.get("pits_opened", 0.0)), int(st.get("pits_opened_timed", 0.0)), int(st.get("pits_opened_reckoning", 0.0)),
		int(st.get("pits_opened_opened", 0.0)), int(st.get("pits_refused", 0.0)), p.fixed_peak, p.zone,
		int(st.get("pit_burns", 0.0)), int(st.get("pit_dmg_summons", 0.0)), int(st.get("pit_dmg_you", 0.0)),
		int(st.get("pit_dmg_enemies", 0.0)), int(st.get("pit_kills", 0.0)), int(st.get("pit_damned_burned", 0.0))]


## The "portals" line (DemonPortals).
static func portals_line(game: Game, st: Dictionary) -> String:
	var pt := game.inferno.portals
	return "opened %d (reckoning %d), destroyed %d, sealed %d (at %s; bounty %d Soul Ash), standing at the end %d | squads %d (%d units), capped %d" % [
		pt.opened, int(st.get("portals_reckoning", 0.0)), pt.destroyed, pt.sealed,
		", ".join(pt.seal_times) if not pt.seal_times.is_empty() else "-", int(pt.seal_ash), pt.standing(),
		pt.squads, int(st.get("portal_units", 0.0)), int(st.get("portal_squads_capped", 0.0))]


## The "temptation" line (Temptation).
static func temptation_line(game: Game, st: Dictionary) -> String:
	var t := game.inferno.temptation
	var by := PackedStringArray()  # "class N" per summon class charmed.
	for cls: String in UnitData.UNITS:
		var n := int(st.get("charm_class_" + cls, 0.0))
		if n > 0:
			by.append("%s %d" % [cls, n])
	return "charms %d, most at once %d, broken by the charmer's death %d, expired %d, freed (body broken) %d, refused at the cap %d | dmg by charmed summons: to summons %d, to you %d | by class: %s" % [
		t.made, t.peak, t.broken, t.expired, t.freed, t.refused_cap,
		int(st.get("summon_dmg_from_" + InfernoEnemyData.CHARMED, 0.0)), int(st.get("player_dmg_from_" + InfernoEnemyData.CHARMED, 0.0)),
		", ".join(by) if not by.is_empty() else "none"]
