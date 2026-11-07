## ProvingMoonDirector — the stage systems of the Proving Moon (Stage 26; Act IX,
## GDD §15.0 "The Proving Moon (Act IX phase 2)"; owner-approved proposal
## docs/act9/PROPOSAL.md "Stage 26: The Proving Moon"), owned and stepped by
## EnemyDirector on a stage whose STAGE has a "proving_moon" config
## (ProvingMoonStage.PROVING_MOON; null elsewhere). The zones are
## MarchDirector's (the looks: ProvingMoonGround); Beams, Abduction,
## Terraforming and the Final Harvest are the shared ConcordRules'; LOW GRAVITY
## is the STAGE key "gravity" read through ConcordRules.gravity(). Here:
##   * THE WARBEAST ("warbeast" event): the stage miniboss, the Vrask's hunting
##     animal, brought in on the spawn ring with an escort of hunters, tracked
##     (objective, kill time); its kit registers it on the HUD's miniboss bar
##     and pays its XP burst.
##   * The HUD objective: Vrask'Tal's LAST TROPHY countdown (HUD text only,
##     never a screen effect: BossVraskTal.trophy_left()), else the Warbeast
##     while it stands.
## Deterministic: only the seeded global RNG (where the Warbeast comes in).
## Stats: proving_moon_warbeast_spawned, proving_moon_warbeast_killed (and
## WarbeastKit's, BossVraskTal's).
class_name ProvingMoonDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (ProvingMoonStage.PROVING_MOON).
var config: Dictionary = {}
## Log of Proving Moon events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## "m:ss" the Warbeast fell ("" while alive / never spawned).
var warbeast_time: String = ""
## The Warbeast once spawned (null before / after; generation-checked).
var _wb: Enemy = null
## Generation of `_wb` when it spawned.
var _wb_gen: int = 0


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	if _wb != null and not (_wb.active and _wb.generation == _wb_gen):
		_wb = null
		game.stat_add("proving_moon_warbeast_killed", 1.0)
		warbeast_time = _clock()
		_log("warbeast_down")


## Runs a Proving Moon timeline event (EnemyDirector forwards the "warbeast"
## type; keys in ProvingMoonStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"warbeast":
			var a := randf() * TAU
			var at := game.enemies.ring_point(a)
			var e := game.enemies.spawn_at(String(ev.get("kind", ProvingMoonEnemyData.WARBEAST)), at, bool(ev.get("elite", false)))
			if e != null:
				_wb = e
				_wb_gen = e.generation
				game.stat_add("proving_moon_warbeast_spawned", 1.0)
				game.shake(4.0)
				game.concord_rules().play_sound("brood_chitter", e.position)
				var side := Vector2.from_angle(a).orthogonal()
				for g: Dictionary in ev.get("escort", []):
					var n := int(g["count"])
					for k in n:
						if game.enemies.regular_alive() >= game.enemies.hard_cap():
							break
						var p := at + side * (float(k) - float(n - 1) * 0.5) * 44.0 - Vector2.from_angle(a) * 60.0
						game.enemies.spawn_at(String(g["kind"]), p, bool(g.get("elite", false)))
				_log("warbeast_loosed")
	game.enemies.show_banner(String(ev["banner"]))


## HUD objective for the live Proving Moon objective ("" if none): the Last
## Trophy's countdown first (HUD text, never a screen effect), then the
## Warbeast.
func objective_override() -> String:
	var boss := game.enemies.boss
	if boss != null and boss.active and boss is BossVraskTal:
		var left := (boss as BossVraskTal).trophy_left()
		if left >= 0.0:
			return String(config["trophy_objective"]) % ceili(left)
	if _wb != null:
		return String(config["warbeast_objective"])
	return ""


## One-line autotest summary.
func summary_line() -> String:
	return "low gravity x%.1f | warbeast %s | events %s" % [
		game.concord_rules().gravity(),
		("killed at " + warbeast_time) if warbeast_time != "" else ("alive" if _wb != null else "not spawned"),
		", ".join(fired) if not fired.is_empty() else "-"]


## Records a Proving Moon event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]
