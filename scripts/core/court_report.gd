## CourtReport — the autotest summary lines of the Sanguine Court's shared rules
## and stages (Act VII; GDD §15.0 "Act VII foundation (phase 1)"), called once
## by Autotest.finish(). Every line prints only when the Court ran this run
## (Game.court exists: an Act VII stage, or a Court kind forced onto another
## stage with --spawn=), so the Act I to VI summaries keep their exact text:
##   bloodfeast:    Bloodfeast (feeds on summons / the necromancer, HP healed,
##                  blood shield banked / absorbed / broken, feeds halved by
##                  Rot / Wither and what that withheld, feeding under the moon)
##   night wings:   Night Wings (swoops, bites on the necromancer / summons,
##                  misses, hits taken in flight by allowed sources, grounded
##                  melee blows that found only air, hits while landed)
##   blood moon:    BloodMoon (moons with their times, forced, warnings, time
##                  up, werebeasts turned under it, feeding under it)
##   court kinds:   spawns / kills of every Court kind that spawned, its first
##                  appearance, and the kits' counters
##   endless feast: EndlessFeast (only once the Reckoning ran)
##   court stage:   the Act VII stage itself (stub status, boss, Soul Ash, the
##                  Reckoning)
## Phase 2 adds one line per stage system here (each stage in its own block).
## Read-only: it never changes the run.
class_name CourtReport
extends RefCounted


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var court := game.court  # The Court's rules (null when they never ran).
	if court == null:
		return
	print("[autotest] bloodfeast: %s" % feast_line(game, st))
	print("[autotest] night wings: %s" % wings_line(st))
	print("[autotest] blood moon: %s" % moon_line(game, st))
	var parts := PackedStringArray()  # "kind spawned/killed" per Court kind seen.
	var kinds: Array = []  # Every Court kind id, the shared table first.
	for table: Dictionary in [CourtEnemyData.ENEMIES, RavensmoorEnemyData.ENEMIES, WitchwoodEnemyData.ENEMIES, CastleSanguisEnemyData.ENEMIES]:
		kinds.append_array(table.keys())
	for k: String in kinds:
		var spawned := int(st.get("spawned_" + k, 0.0))
		var killed := int(st.get("kill_" + k, 0.0))
		if spawned > 0 or killed > 0:
			var first := EmpireReport._clock(float(court.first_seen[k])) if court.first_seen.has(k) else "-"
			parts.append("%s %d/%d first %s (dmg to you %d, to summons %d, fed %d)" % [k, spawned, killed, first,
				int(st.get("player_dmg_from_" + k, 0.0)), int(st.get("summon_dmg_from_" + k, 0.0)), int(st.get("feast_heal_" + k, 0.0))])
	if not parts.is_empty():
		print("[autotest] court kinds (spawned/killed): %s | werewolves turned %d (moon %d, wounds %d), lunges %d (hits %d) | noble beams %d (ticks %d, broken %d), mists %d (jumped %d px) | coffins opened %d, nobles released %d" % [
			" | ".join(parts), int(st.get("werewolf_turned", 0.0)), int(st.get("werewolf_turned_moon", 0.0)), int(st.get("werewolf_turned_hp", 0.0)),
			int(st.get("werewolf_lunges", 0.0)), int(st.get("werewolf_lunge_hits", 0.0)),
			int(st.get("noble_beams", 0.0)), int(st.get("noble_beam_ticks", 0.0)), int(st.get("noble_beam_broken", 0.0)),
			int(st.get("noble_mists", 0.0)), int(st.get("noble_mist_jump_px", 0.0)),
			int(st.get("coffins_opened", 0.0)), int(st.get("coffin_nobles", 0.0))])
	if court.endless.running():
		print("[autotest] endless feast: began %s | feeding x%.1f at the end | coffins opened %d (standing %d) | nobles released %d (capped %d)" % [
			EmpireReport._clock(court.endless.started_at), court.endless.feed_mult(), court.endless.coffins_opened,
			_standing(court.endless.coffins), int(st.get("coffin_nobles", 0.0)), int(st.get("coffin_capped", 0.0))])
	var sd := game.stage_def  # The run's stage.
	if StageRegistry.act_of(String(sd["id"])) == 7:
		var boss: Dictionary = sd["boss"]
		print("[autotest] court stage: %s (%s) | playable %s | boss %s (script %s) | enemy x%.2f HP / x%.2f dmg from %s | soul ash x%.2f | reckoning kind %s, endless feast %s" % [
			String(sd["id"]), String(sd["display_name"]), str(StageRegistry.is_playable(String(sd["id"]))),
			String(boss["id"]), String(boss.get("script", boss["id"])), float(sd["enemy_hp_mult"]), float(sd["enemy_damage_mult"]),
			EmpireReport._clock(float(sd.get("enemy_mult_from", 0.0))), float(sd["ash_mult"]),
			String((sd["reckoning"] as Dictionary).get("kind", "inquisitor")), str(not court.endless.cfg.is_empty())])
	# Phase 2: each Act VII stage's own lines go here (its stage, kinds and boss).


## The "bloodfeast" line (Bloodfeast).
static func feast_line(game: Game, st: Dictionary) -> String:
	var f := game.court.feast
	return "feeds %d (on summons %d, on you %d) | healed %d | blood shield banked %d, absorbed %d, broken %d | halved by Rot / Wither %d (withheld %d) | under the moon %d feeds (%d HP) | embalmed withheld %d" % [
		f.bites, int(st.get("feast_bites_summons", 0.0)), int(st.get("feast_bites_you", 0.0)), int(f.healed),
		int(f.banked), int(f.absorbed), int(st.get("feast_shields_broken", 0.0)),
		f.halved, int(st.get("feast_halved_withheld", 0.0)), int(st.get("feast_moon_bites", 0.0)), int(st.get("feast_moon_heal", 0.0)),
		int(st.get("feast_embalmed_withheld", 0.0))]


## The "night wings" line (NightWings).
static func wings_line(st: Dictionary) -> String:
	return "swoops %d | bites on you %d, on summons %d, missed %d | hits in flight by fliers / ranged / spells %d, grounded melee blows into the air %d | hits while landed %d | retargets to the necromancer %d" % [
		int(st.get("night_wings_swoops", 0.0)), int(st.get("night_wings_bites_you", 0.0)), int(st.get("night_wings_bites_summons", 0.0)),
		int(st.get("night_wings_bites_missed", 0.0)), int(st.get("night_wings_air_hits", 0.0)), int(st.get("night_wings_air_whiffs", 0.0)),
		int(st.get("night_wings_landed_hits", 0.0)), int(st.get("night_wings_retargets", 0.0))]


## The "blood moon" line (BloodMoon).
static func moon_line(game: Game, st: Dictionary) -> String:
	var m := game.court.moon
	if not m.enabled and m.moons == 0:
		return "off (not an Act VII stage)"
	return "moons %d (at %s; forced %d), warnings %d, up %d s | werebeasts turned under it %d | feeds under it %d (%d HP)" % [
		m.moons, ", ".join(m.rise_times) if not m.rise_times.is_empty() else "-", m.forced, int(st.get("blood_moon_warnings", 0.0)),
		int(st.get("blood_moon_time", 0.0)), m.transforms, int(st.get("feast_moon_bites", 0.0)), int(st.get("feast_moon_heal", 0.0))]


## Standing coffins in `list` (active ones).
static func _standing(list: Array[Enemy]) -> int:
	var n := 0
	for e in list:
		if e.active and e.kind == CourtEnemyData.COFFIN:
			n += 1
	return n
