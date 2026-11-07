## BurningGateDirector — the stage systems of the Burning Gate (Stage 16; Act VI,
## GDD §15.0 "The Burning Gate (Act VI phase 2)"; owner-approved proposal
## docs/act6/PROPOSAL.md "Stage 16: The Burning Gate"), owned and stepped by
## EnemyDirector on a stage whose STAGE has a "burning_gate" config
## (BurningGateStage.BURNING_GATE; null elsewhere). The zones are
## MarchDirector's, the Hell Pits (with this stage's River of Fire band:
## HellPits._add_band()), the portals and Temptation the shared InfernoRules'.
## Here:
##   * THE GATEKEEPER ("gatekeeper" event): the stage miniboss, spawned on the
##     spawn ring and tracked (objective, kill time); his kit (GatekeeperKit)
##     registers him on the HUD's miniboss bar and pays his XP burst.
##   * GATE CRASHED (the stage's achievement; owner-approved name, own rule):
##     when Moloch falls on this stage with at least gate_crashed_seals portals
##     sealed in the run, the run stat burning_gate_crashed is set (MetaProgress
##     counts the runs: lifetime gate_crashed_runs, MetaData "gate_crashed").
##   * The HUD objective while the Gatekeeper stands.
## Deterministic: only the seeded global RNG (where the Gatekeeper walks in).
## Stats: burning_gate_gatekeeper_spawned, burning_gate_gatekeeper_killed,
## burning_gate_crashed, burning_gate_seals_at_moloch.
class_name BurningGateDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (BurningGateStage.BURNING_GATE).
var config: Dictionary = {}
## "m:ss" the Gatekeeper fell ("" while alive / never spawned).
var gatekeeper_time: String = ""
## Log of Burning Gate events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## True once Gate Crashed was earned this run.
var crashed: bool = false
## The Gatekeeper once spawned (null before / after; generation-checked).
var _gk: Enemy = null
## Generation of `_gk` when he spawned.
var _gk_gen: int = 0


func _ready() -> void:
	game.enemies.boss_defeated.connect(_on_boss_defeated)


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	if _gk == null or (_gk.active and _gk.generation == _gk_gen):
		return
	_gk = null
	game.stat_add("burning_gate_gatekeeper_killed", 1.0)
	gatekeeper_time = _clock()
	_log("gatekeeper_killed")


## Runs a Burning Gate timeline event (EnemyDirector forwards the "gatekeeper"
## type; keys in BurningGateStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"gatekeeper":
			var e := game.enemies.spawn_at(String(ev.get("kind", BurningGateEnemyData.GATEKEEPER)), game.enemies.ring_point(randf() * TAU), bool(ev.get("elite", false)))
			_gk = e
			_gk_gen = e.generation
			game.stat_add("burning_gate_gatekeeper_spawned", 1.0)
			game.shake(5.0)
			game.inferno_rules().play_sound("brute_slam", e.position)
			_log("gatekeeper_arrived")
	game.enemies.show_banner(String(ev["banner"]))


## HUD objective for the live Burning Gate objective ("" if none).
func objective_override() -> String:
	if _gk != null:
		return String(config["gatekeeper_objective"])
	return ""


## Moloch fell: Gate Crashed when enough portals were sealed this run.
func _on_boss_defeated() -> void:
	if String(game.enemies.boss_info.get("id", "")) != MolochData.ARRIVAL["id"]:
		return
	var seals := int(game.stats.get("portals_sealed", 0.0))
	game.stats["burning_gate_seals_at_moloch"] = float(seals)
	_log("moloch_slain")
	if seals >= int(config["gate_crashed_seals"]) and not crashed:
		crashed = true
		game.stats["burning_gate_crashed"] = 1.0
		game.enemies.show_banner(String(config["gate_crashed_banner"]))
		_log("gate_crashed")


## One-line autotest summary.
func summary_line() -> String:
	return "gatekeeper %s | river of fire circles peak %d | seals when Moloch fell %s (gate crashed needs %d: %s) | events %s" % [
		("killed at " + gatekeeper_time) if gatekeeper_time != "" else ("alive" if _gk != null else "not spawned"),
		int(game.stats.get("river_circles_peak", 0.0)),
		str(int(game.stats["burning_gate_seals_at_moloch"])) if game.stats.has("burning_gate_seals_at_moloch") else "-",
		int(config["gate_crashed_seals"]), "earned" if crashed else "no",
		", ".join(fired) if not fired.is_empty() else "-"]


## Records a Burning Gate event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]
