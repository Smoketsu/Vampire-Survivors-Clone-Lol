## KuroganeDirector — the stage systems of Castle Kurogane (Stage 14; Act V,
## GDD §15.0 "Castle Kurogane (Act V phase 2)"; owner-approved proposal
## docs/act5/PROPOSAL.md "Stage 14: Castle Kurogane"), owned and stepped by
## EnemyDirector on a stage whose STAGE has a "kurogane" config
## (KuroganeStage.KUROGANE; null elsewhere). The zones are MarchDirector's, the
## Sun's Course, the Draw and the ambushes the shared ShogunateRules', the
## Shogun's army his own (BossShogun / ShogunRegiments). Here:
##   * The General of the Left ("general_left" event): the stage miniboss,
##     spawned on the spawn ring and tracked (objective, kill time); his kit
##     (GeneralKit) registers him on the HUD's miniboss bar and pays his XP
##     burst.
##   * The HUD objective while the Shogun stands on his platform: the soldiers
##     he has left and the banners broken.
## Deterministic: only the seeded global RNG (where the General rides in).
## Stats: kurogane_general_spawned, kurogane_general_killed.
class_name KuroganeDirector
extends Node2D

## Owning run.
var game: Game
## The stage's Kurogane config (KuroganeStage.KUROGANE).
var config: Dictionary = {}
## "m:ss" the General fell ("" while alive / never spawned).
var general_time: String = ""
## Log of Kurogane events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## The General once spawned (null before / after; generation-checked).
var _general: Enemy = null
## Generation of `_general` when he spawned.
var _general_gen: int = 0


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	if _general == null or (_general.active and _general.generation == _general_gen):
		return
	_general = null
	game.stat_add("kurogane_general_killed", 1.0)
	general_time = _clock()
	_log("general_killed")


## Runs a Kurogane timeline event (EnemyDirector forwards the "general_left"
## type; keys in KuroganeStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"general_left":
			var e := game.enemies.spawn_at(String(ev.get("kind", KuroganeEnemyData.GENERAL_LEFT)), game.enemies.ring_point(randf() * TAU), bool(ev.get("elite", false)))
			_general = e
			_general_gen = e.generation
			game.stat_add("kurogane_general_spawned", 1.0)
			game.shake(5.0)
			if game.shogunate != null:
				game.shogunate.play_sound("taiko_hit", e.position)
			_log("general_arrived")
	game.enemies.show_banner(String(ev["banner"]))


## HUD objective for the live Kurogane objective ("" if none): the General
## first, then the Shogun's army while he commands it.
func objective_override() -> String:
	if _general != null:
		return String(config["general_objective"])
	var b := game.enemies.boss
	if b is BossShogun and b.active and (b as BossShogun).phase == BossShogun.Phase.PLATFORM:
		var s := b as BossShogun
		return String(config["army_objective"]) % [s.regiments.left(), s.regiments.banners_broken, s.regiments.regiments.size()]
	return ""


## One-line autotest summary.
func summary_line() -> String:
	return "general of the left %s | events %s" % [
		("killed at " + general_time) if general_time != "" else ("alive" if _general != null else "not spawned"),
		", ".join(fired) if not fired.is_empty() else "-"]


## Records a Kurogane event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]
