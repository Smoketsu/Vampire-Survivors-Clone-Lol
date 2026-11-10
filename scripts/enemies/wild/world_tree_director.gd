## WorldTreeDirector — the stage systems of THE WORLD-TREE (temporary Act XV
## stage 45, final stage 45, the campaign finale; GDD §15.0 "The World-Tree (Act
## XV phase 2)"; owner-approved proposal docs/proposals/LAST_SIX_ACTS.md section
## XV, "Stage 45: The World-Tree"), owned and stepped by EnemyDirector on a stage
## whose STAGE has a "world_tree" config (WorldTreeStage.WORLD_TREE;
## `game.enemies.world_tree`, null elsewhere). The zones' floors and obstacles
## are MarchDirector's; the year (twice as fast: STAGE "seasons" length 150),
## the blight, the thickets, Spring Returns and the First Spring the shared
## WildRules'. Here:
##   * THE GARDENER OF ROOTS ("gardener" event): the stage miniboss comes in
##     gardener_dist px ahead of the necromancer (WorldTreeEnemyData
##     "gardener_of_roots", GardenerOfRootsKit: while he lives the roots answer
##     his call in any season, SeasonCycle.call_roots()); the HUD objective
##     names him while he lives.
##   * THE FIRST SPRING (the stage's achievement: "beat the Green Mother"):
##     MetaProgress reads the boss kill (boss id "green_mother").
## Deterministic: game time and positions only. Stats: gardener_spawned,
## gardener_killed (and the kit's gardener_roots, treant_roots).
class_name WorldTreeDirector
extends Node

## Owning run.
var game: Game
## The stage's config (WorldTreeStage.WORLD_TREE).
var config: Dictionary = {}
## Log of the stage's events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## "m:ss" the Gardener fell ("" while alive / never spawned).
var gardener_time: String = ""
## The Gardener once spawned (null before / after; generation-checked).
var _gardener: Enemy = null
## Generation of `_gardener` when he spawned.
var _gardener_gen: int = 0


## Per-tick update (EnemyDirector, after the MarchDirector): the Gardener's fall.
func step(_delta: float) -> void:
	if _gardener != null and not (_gardener.active and _gardener.generation == _gardener_gen):
		_gardener = null
		game.stat_add("gardener_killed", 1.0)
		gardener_time = _clock()
		_log("gardener_down")


## Runs a World-Tree timeline event (EnemyDirector forwards the "gardener"
## type; keys in WorldTreeStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	if String(ev["type"]) != "gardener":
		return
	var pl := game.player
	var ahead := pl.velocity.normalized() if pl.velocity.length() > 5.0 else Vector2.RIGHT
	var at := game.arena.free_point(pl.position + ahead * float(ev.get("gardener_dist", 300.0)), 26.0)
	var e := game.enemies.spawn_at(String(ev.get("kind", WorldTreeEnemyData.GARDENER)), at, bool(ev.get("elite", false)))
	if e != null:
		_gardener = e
		_gardener_gen = e.generation
		game.stat_add("gardener_spawned", 1.0)
	game.shake(6.0)
	if game.wild != null:
		game.wild.play_sound("roots_grab", at, 1.0)
	if ev.has("banner"):
		game.enemies.show_banner(String(ev["banner"]))
	_log("gardener")


## The HUD objective while the Gardener lives ("" otherwise).
func objective_override() -> String:
	if _gardener != null:
		return String(config.get("gardener_objective", ""))
	return ""


## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	return "gardener of roots spawned %d, killed %d%s (his call's grabs %d, his roots %d) | events: %s" % [
		int(st.get("gardener_spawned", 0.0)), int(st.get("gardener_killed", 0.0)), (" at " + gardener_time) if gardener_time != "" else "",
		int(st.get("gardener_roots", 0.0)), int(st.get("treant_roots", 0.0)), ", ".join(fired)]


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	fired.append("%s %s" % [_clock(), what])


## The current game clock as "m:ss".
func _clock() -> String:
	var t := int(game.elapsed)
	return "%d:%02d" % [t / 60, t % 60]
