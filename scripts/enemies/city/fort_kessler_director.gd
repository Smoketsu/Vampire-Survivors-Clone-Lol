## FortKesslerDirector — the stage systems of Fort Kessler (Stage 23; Act VIII,
## GDD §15.0 "Fort Kessler (Act VIII phase 2)"; owner-approved proposal
## docs/act8/PROPOSAL.md "Stage 23: Fort Kessler"), owned and stepped by
## EnemyDirector on a stage whose STAGE has a "fort_kessler" config
## (FortKesslerStage.FORT_KESSLER; null elsewhere). The zones are
## MarchDirector's (the looks: FortKesslerGround and the zone's "blocks"); the
## escalation, Armour, the Supers, the Civilians and Martial Law are the shared
## CityRules'. Here:
##   * THE MINEFIELDS (`mines`, Minefields, the one ground path): blinking mines
##     in the open lots and on chosen streets of the Minefield zone that blow up
##     under anyone; the Bone Ring flows around them (Minefields.avoid_point(),
##     read once by StanceFormations._place()); the bot steps off them
##     (danger_push(), read through CityRules.danger_push()).
##   * MAMMOTH ("mammoth" event): the stage miniboss, a super-heavy tank driven
##     in on the spawn ring with an escort, tracked (objective, kill time); its
##     kit registers it on the HUD's miniboss bar and pays its XP burst.
##   * The HUD objective: General Harrow's BROKEN ARROW countdown (HUD text
##     only, never a screen effect: BossHarrow.broken_arrow_left()), else
##     Mammoth while it stands.
## Deterministic: the mines' layout is a pure hash; only the seeded global RNG
## (where Mammoth comes in). Stats: fort_kessler_mammoth_spawned,
## fort_kessler_mammoth_killed (and Minefields', MammothKit's, BossHarrow's).
class_name FortKesslerDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (FortKesslerStage.FORT_KESSLER).
var config: Dictionary = {}
## The minefields (child node; their own config is config "minefields").
var mines: Minefields = null
## Log of Fort Kessler events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## "m:ss" Mammoth fell ("" while alive / never spawned).
var mammoth_time: String = ""
## Mammoth once spawned (null before / after; generation-checked).
var _mm: Enemy = null
## Generation of `_mm` when it spawned.
var _mm_gen: int = 0


func _ready() -> void:
	mines = Minefields.new(game, config.get("minefields", {}))
	add_child(mines)


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(delta: float) -> void:
	if mines != null and not (config.get("minefields", {}) as Dictionary).is_empty():
		mines.step(delta)
	if _mm != null and not (_mm.active and _mm.generation == _mm_gen):
		_mm = null
		game.stat_add("fort_kessler_mammoth_killed", 1.0)
		mammoth_time = _clock()
		_log("mammoth_killed")


## Runs a Fort Kessler timeline event (EnemyDirector forwards the "mammoth"
## type; keys in FortKesslerStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"mammoth":
			var a := randf() * TAU
			var at := game.enemies.ring_point(a)
			var e := game.enemies.spawn_at(String(ev.get("kind", FortKesslerEnemyData.MAMMOTH)), at, bool(ev.get("elite", false)))
			if e != null:
				_mm = e
				_mm_gen = e.generation
				game.stat_add("fort_kessler_mammoth_spawned", 1.0)
				game.shake(5.0)
				game.city_rules().play_sound("engine_rev", e.position)
				for g: Dictionary in ev.get("escort", []):
					var n := int(g["count"])
					var side := Vector2.from_angle(a).orthogonal()
					for k in n:
						if game.enemies.regular_alive() >= game.enemies.hard_cap():
							break
						var p := at + side * (float(k) - float(n - 1) * 0.5) * 40.0 - Vector2.from_angle(a) * 60.0
						game.enemies.spawn_at(String(g["kind"]), p, bool(g.get("elite", false)))
				_log("mammoth_arrived")
	game.enemies.show_banner(String(ev["banner"]))


## HUD objective for the live Fort Kessler objective ("" if none): Broken
## Arrow's countdown first (HUD text, never a screen effect), then Mammoth.
func objective_override() -> String:
	var boss := game.enemies.boss
	if boss != null and boss.active and boss is BossHarrow:
		var left := (boss as BossHarrow).broken_arrow_left()
		if left >= 0.0:
			return String(config["broken_arrow_objective"]) % ceili(left)
	if _mm != null:
		return String(config["mammoth_objective"])
	return ""


## Autopilot hint (through CityRules.danger_push()): off the mines.
func danger_push(p: Vector2) -> Vector2:
	return mines.danger_push(p) if mines != null else Vector2.ZERO


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	return "minefields: live peak %d, triggered %d (by enemies %d, summons %d, you %d), blown %d, enemy kills %d, ring posts moved off %d | mammoth %s | events %s" % [
		int(st.get("mines_live_peak", 0.0)), int(st.get("mines_triggered", 0.0)), int(st.get("mines_triggered_by_enemy", 0.0)),
		int(st.get("mines_triggered_by_summon", 0.0)), int(st.get("mines_triggered_by_you", 0.0)), int(st.get("mines_blown", 0.0)),
		int(st.get("mine_kills_enemies", 0.0)), int(st.get("mine_ring_posts_moved", 0.0)),
		("killed at " + mammoth_time) if mammoth_time != "" else ("alive" if _mm != null else "not spawned"),
		", ".join(fired) if not fired.is_empty() else "-"]


## Records a Fort Kessler event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]
