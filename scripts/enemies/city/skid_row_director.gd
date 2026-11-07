## SkidRowDirector — the stage systems of Skid Row (Stage 22; Act VIII, GDD
## §15.0 "Skid Row (Act VIII phase 2)" and the rows after it; owner-approved
## proposal docs/act8/PROPOSAL.md "Stage 22: Skid Row" with the owner's phase 2
## answers), owned and stepped by EnemyDirector on a stage whose STAGE has a
## "skid_row" config (SkidRowStage.SKID_ROW; null elsewhere). The zones are
## MarchDirector's, Armour, Supers, Civilians and the escalation the shared
## CityRules'. Here:
##   * BIG SAL AND THE ARMOURED LIMO ("big_sal" event): the limo (kind `kind`)
##     rolls in on the spawn ring with `crew` gang gunners beside it; its kit
##     holds the HUD's miniboss bar. When it dies (ArmouredLimoKit
##     .on_killed() -> on_limo_wrecked()) its wreck burns and BIG SAL climbs
##     out at the wreck (at a free point beside it) for a short melee finish:
##     his kit registers him as the miniboss (the chest, the XP burst); kill
##     him to end the miniboss.
##   * THE BOUNTY (Don Marrow's first phase): while his bounty board stands
##     (on_board_raised(); bounty_active(), generation-checked) the gangs come
##     twice as thick: the live segment's gang share (bounty_gang_kinds, by its
##     weights x its rate) spawns a second time on the spawn ring, under
##     bounty_cap_share of the hard cap (stat skid_row_bounty_gangs).
##   * NO WITNESSES (the stage's achievement; owner, Nov 2, 2026: "kill every
##     civilian of the opening crowd before they flee the streets"): when the
##     whole 0:00 crowd was killed and none of it fled (Civilians.crowd_left /
##     crowd_fled), the run stat skid_row_no_witnesses is set (MetaProgress
##     counts the runs: lifetime no_witnesses_runs, MetaData "no_witnesses";
##     it unlocks Kevlar Bones). It fails as soon as one of the crowd leaves
##     the field.
##   * The HUD objective while the limo or Big Sal stands.
## Deterministic: only the seeded global RNG (where the limo and the extra
## gangs come in). Stats: skid_row_limo_spawned, skid_row_sal_spawned,
## skid_row_sal_killed, skid_row_bounty_gangs, skid_row_no_witnesses.
class_name SkidRowDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (SkidRowStage.SKID_ROW).
var config: Dictionary = {}
## Log of Skid Row events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## "m:ss" the limo was wrecked ("" while it drives / never came).
var limo_time: String = ""
## "m:ss" Big Sal fell ("" while alive / never came).
var sal_time: String = ""
## True once No Witnesses was earned this run.
var witnesses: bool = false
## The limo once it rolled in (null before / after; generation-checked).
var _limo: Enemy = null
## Generation of `_limo` when it spawned.
var _limo_gen: int = 0
## Big Sal on foot (null before / after; generation-checked).
var _sal: Enemy = null
## Generation of `_sal` when he climbed out.
var _sal_gen: int = 0
## Don Marrow's bounty board (null before / after; generation-checked).
var _board: Enemy = null
## Generation of `_board` when it went up.
var _board_gen: int = 0
## Fractional extra gang spawns owed by the Bounty (accumulates rate x delta).
var _bounty_acc: float = 0.0


## Per-tick update (EnemyDirector, after the MarchDirector): the Bounty's
## extra gangs, No Witnesses, the stale guards.
func step(delta: float) -> void:
	if _limo != null and not (_limo.active and _limo.generation == _limo_gen):
		_limo = null
	if _sal != null and not (_sal.active and _sal.generation == _sal_gen):
		_sal = null
	if bounty_active():
		_bounty_gangs(delta)
	else:
		_bounty_acc = 0.0
	if not witnesses and game.city != null:
		var civ := game.city.civilians
		if civ.crowd_size > 0 and civ.crowd_left == 0 and civ.crowd_fled == 0:
			witnesses = true
			game.stats["skid_row_no_witnesses"] = 1.0
			game.enemies.show_banner(String(config["witnesses_banner"]))
			_log("no_witnesses")


# =====================================================================================
# Big Sal and the Armoured Limo
# =====================================================================================

## Runs a Skid Row timeline event (EnemyDirector forwards the "big_sal" type;
## keys in SkidRowStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"big_sal":
			var a := randf() * TAU
			var e := game.enemies.spawn_at(String(ev.get("kind", SkidRowEnemyData.LIMO)), game.enemies.ring_point(a), false)
			if e != null:
				_limo = e
				_limo_gen = e.generation
				game.stat_add("skid_row_limo_spawned", 1.0)
				game.shake(4.0)
				game.city_rules().play_sound("engine_rev", e.position)
				var side := Vector2.from_angle(a).orthogonal()
				var crew := int(ev.get("crew", 0))
				var gap := float(config["sal_crew_spacing"])
				for k in crew:
					var at := e.position + side * (float(k) - float(crew - 1) * 0.5) * gap - Vector2.from_angle(a) * 40.0
					game.enemies.spawn_at(CityEnemyData.GANG_GUNNER, at, false)
				_log("limo_arrived")
	game.enemies.show_banner(String(ev["banner"]))


## The limo `e` died at `at` (ArmouredLimoKit.on_killed(), after its wreck was
## placed): Big Sal climbs out beside the wreck.
func on_limo_wrecked(e: Enemy, at: Vector2) -> void:
	limo_time = _clock()
	_limo = null
	_log("limo_wrecked")
	var row := game.enemies.enemy_def(SkidRowEnemyData.BIG_SAL)
	var spot := game.arena.free_point(at, float(row["radius"]) * EnemyData.ELITE_RADIUS_MULT)
	var sal := game.enemies.spawn_at(SkidRowEnemyData.BIG_SAL, spot, false)
	if sal == null:
		return
	_sal = sal
	_sal_gen = sal.generation
	game.stat_add("skid_row_sal_spawned", 1.0)
	game.effects.impact(spot, 36.0, Palette.CITY_HERO_ORANGE)
	game.enemies.show_banner(String(config["sal_out_banner"]))
	if e != null:
		game.stat_add("skid_row_limo_wrecked", 1.0)


## Big Sal fell (BigSalKit.on_killed()).
func on_sal_killed() -> void:
	sal_time = _clock()
	_sal = null
	game.stat_add("skid_row_sal_killed", 1.0)
	game.enemies.show_banner(String(config["sal_dead_banner"]))
	_log("big_sal_killed")


# =====================================================================================
# The Bounty
# =====================================================================================

## Don Marrow raised his bounty board `e` (BossDonMarrow): the Bounty begins.
func on_board_raised(e: Enemy) -> void:
	_board = e
	_board_gen = e.generation
	_log("bounty_board")


## True while Don Marrow's bounty board stands (the gangs come twice as thick).
func bounty_active() -> bool:
	return _board != null and _board.active and _board.generation == _board_gen


## The Bounty's second share of gangs: the live segment's gang kinds at its
## rate x their weight share, on the spawn ring, under the cap share.
func _bounty_gangs(delta: float) -> void:
	if game.countdown_finished():
		return
	var en := game.enemies
	var seg: Dictionary = en.segments[en.segment_index]
	var weights: Dictionary = seg["weights"]
	var total := 0.0
	var gang := 0.0
	for k: String in weights:
		total += float(weights[k])
		if (config["bounty_gang_kinds"] as Array).has(k):
			gang += float(weights[k])
	if total <= 0.0 or gang <= 0.0:
		return
	_bounty_acc += float(seg["rate"]) * gang / total * delta
	while _bounty_acc >= 1.0:
		_bounty_acc -= 1.0
		if en.regular_alive() >= int(float(en.hard_cap()) * float(config["bounty_cap_share"])):
			continue
		var roll := randf() * gang
		var pick := ""
		for k: String in weights:
			if not (config["bounty_gang_kinds"] as Array).has(k):
				continue
			pick = k
			roll -= float(weights[k])
			if roll <= 0.0:
				break
		if pick != "" and en.spawn_at(pick, en.ring_point(randf() * TAU), false) != null:
			game.stat_add("skid_row_bounty_gangs", 1.0)


# =====================================================================================
# Objective, summary
# =====================================================================================

## HUD objective for the live Skid Row objective ("" if none).
func objective_override() -> String:
	if _sal != null:
		return String(config["sal_out_objective"])
	if _limo != null:
		return String(config["sal_objective"])
	return ""


## One-line autotest summary.
func summary_line() -> String:
	var civ: Civilians = game.city.civilians if game.city != null else null
	return "big sal: limo %s, big sal %s | the bounty: board %s, extra gangs %d | no witnesses %s (crowd %d: killed %d, fled %d, left %d) | events %s" % [
		("wrecked at " + limo_time) if limo_time != "" else ("driving" if _limo != null else "not spawned"),
		("killed at " + sal_time) if sal_time != "" else ("alive" if _sal != null else "not out"),
		"standing" if bounty_active() else ("broken" if int(game.stats.get("bounty_board_broken", 0.0)) > 0 else ("down" if int(game.stats.get("bounty_board_raised", 0.0)) > 0 else "never raised")),
		int(game.stats.get("skid_row_bounty_gangs", 0.0)),
		"earned" if witnesses else "no",
		civ.crowd_size if civ != null else 0, civ.crowd_killed if civ != null else 0,
		civ.crowd_fled if civ != null else 0, civ.crowd_left if civ != null else 0,
		", ".join(fired) if not fired.is_empty() else "-"]


## Records a Skid Row event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]
