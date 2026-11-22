## SilverStairDirector — the stage systems of THE SILVER STAIR (temporary Act
## XIII stage 37, final stage 28; GDD §15.0 "The Silver Stair (Act XIII phase
## 2)"; owner-approved proposal docs/proposals/LAST_SIX_ACTS.md section X,
## "Stage 28: The Silver Stair"), owned and stepped by EnemyDirector on a stage
## whose STAGE has a "silver_stair" config (SilverStairStage.STAIR;
## `game.enemies.silver_stair`, null elsewhere). The zones' floors and
## obstacles are MarchDirector's; Judgment, Hallowed Light, Grace and the Last
## Trumpet the shared HostRules'. Here:
##   * THE STAIR (the stage mechanic, "each zone is a wider step; low cloud
##     banks are the shadows that hide from the light"): each zone is a step
##     (STAIR "steps", one per zone, by start time): on entering it the
##     Light's width_mult is multiplied up to the step's `width` (a relative
##     change, so the Last Trumpet's own widening still multiplies on top),
##     and every `bank_every` s `banks` LOW CLOUD BANKS settle bank_min..
##     bank_max px from a standing necromancer at seeded angles (the gameplay
##     RNG), radius bank_radius px, for bank_life s (CloudShade.add_shade(),
##     THE public call): the safe ground the necromancer leads his ring into.
##   * WITHOUT SIN (the stage's achievement): the highest third the scales
##     passed all run (Judgment.thirds_passed, read every tick: it resets with
##     a Verdict); when the stage boss (Seraiel) falls on the Silver Stair with
##     it still 0, the run stat WITHOUT_SIN_STAT is set (MetaProgress counts
##     the runs, lifetime without_sin_runs, MetaData "without_sin"; it unlocks
##     Absolution).
##   * THE CHERUB OF THE GATE ("cherub_gate" event): the stage miniboss,
##     spawned on the spawn ring with an escort and tracked (objective, kill
##     time); its kit registers it on the HUD's miniboss bar and pays its XP.
## Deterministic: only the seeded global RNG (the banks' points, where the
## Cherub comes in). Stats: silver_stair_banks, silver_stair_steps,
## silver_stair_cherub_spawned, silver_stair_cherub_killed, WITHOUT_SIN_STAT.
class_name SilverStairDirector
extends Node2D

## Run stat set when Without Sin is earned (MetaProgress reads it).
const WITHOUT_SIN_STAT: String = "silver_stair_without_sin"

## Owning run.
var game: Game
## The stage's config (SilverStairStage.STAIR).
var config: Dictionary = {}
## Log of the stage's events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Index of the step the necromancer stands on (-1 before the first).
var step_index: int = -1
## The highest third the scales passed this run (Without Sin wants 0).
var worst_third: int = 0
## True once the stage boss fell this run.
var boss_down: bool = false
## True once Without Sin was earned this run.
var without_sin: bool = false
## "m:ss" the Cherub of the Gate fell ("" while alive / never spawned).
var cherub_time: String = ""
## Low cloud banks laid so far.
var banks: int = 0
## The Light's width_mult the current step set (its share of the multiplier).
var _width: float = 1.0
## Game time (s) of the next low cloud banks.
var _next_bank: float = INF
## True once the boss signal is connected.
var _hooked: bool = false
## The Cherub of the Gate once spawned (null before / after; generation-checked).
var _cherub: Enemy = null
## Generation of `_cherub` when it spawned.
var _cherub_gen: int = 0


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	var now := game.elapsed
	if not _hooked:
		_hooked = true
		game.enemies.boss_defeated.connect(_on_boss_defeated)
	var steps: Array = config.get("steps", [])
	while step_index + 1 < steps.size() and now >= float((steps[step_index + 1] as Dictionary)["start"]):
		step_index += 1
		_enter_step(steps[step_index])
	if step_index >= 0 and now >= _next_bank:
		var st: Dictionary = steps[step_index]
		_next_bank = now + float(st["bank_every"])
		_lay_banks(st)
	if game.host != null:
		worst_third = maxi(worst_third, game.host.judgment.thirds_passed)
	if _cherub != null and not (_cherub.active and _cherub.generation == _cherub_gen):
		_cherub = null
		game.stat_add("silver_stair_cherub_killed", 1.0)
		cherub_time = _clock()
		_log("cherub_killed")


# =====================================================================================
# The Stair
# =====================================================================================

## A new step: the Light widens to the step's width (relative), the banks'
## clock restarts.
func _enter_step(st: Dictionary) -> void:
	game.stat_add("silver_stair_steps", 1.0)
	if game.host != null:
		var w := float(st.get("width", 1.0))
		game.host.light.width_mult *= w / maxf(_width, 0.01)
		_width = w
	_next_bank = game.elapsed + float(st.get("bank_first", 0.0))
	_log("step_%d" % (step_index + 1))


## Lays the step's low cloud banks round a standing necromancer.
func _lay_banks(st: Dictionary) -> void:
	if game.host == null:
		return
	var standing: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			standing.append(pl)
	if standing.is_empty():
		return
	var pl: Necromancer = standing[randi() % standing.size()]
	for i in int(st.get("banks", 0)):
		var at := pl.position + Vector2.from_angle(randf() * TAU) * randf_range(float(st["bank_min"]), float(st["bank_max"]))
		game.host.light.clouds.add_shade(at, float(st["bank_radius"]), float(st["bank_life"]))
		banks += 1
		game.stat_add("silver_stair_banks", 1.0)


# =====================================================================================
# Without Sin
# =====================================================================================

## The stage boss fell (EnemyDirector.boss_defeated): Without Sin when he is
## Seraiel, on the Silver Stair, and the scales never passed their first third.
func _on_boss_defeated() -> void:
	if boss_down:
		return
	boss_down = true
	_log("boss_down")
	if game.host != null:
		worst_third = maxi(worst_third, game.host.judgment.thirds_passed)
	if String(game.enemies.boss_info.get("id", "")) != String(SilverStairStage.BOSS["id"]):
		return
	if String(game.stage_def.get("id", "")) != SilverStairStage.ID or worst_third > 0:
		_log("thirds_passed_%d" % worst_third)
		return
	without_sin = true
	game.stats[WITHOUT_SIN_STAT] = 1.0
	game.enemies.show_banner(String(config.get("without_sin_banner", "WITHOUT SIN")))
	_log("without_sin")


# =====================================================================================
# The Cherub of the Gate
# =====================================================================================

## Runs a Silver Stair timeline event (EnemyDirector forwards the
## "cherub_gate" type; keys in SilverStairStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	if String(ev["type"]) != "cherub_gate":
		return
	var a := randf() * TAU
	var e := game.enemies.spawn_at(String(ev.get("kind", SilverStairEnemyData.CHERUB_OF_THE_GATE)), game.enemies.ring_point(a), bool(ev.get("elite", false)))
	if e == null:
		return
	_cherub = e
	_cherub_gen = e.generation
	game.stat_add("silver_stair_cherub_spawned", 1.0)
	game.shake(6.0)
	Sfx.play("boss_impact", e.position, 0.5)
	var side := Vector2.from_angle(a).orthogonal()
	var escort: Array = ev.get("escort", [])
	var k := 0
	for grp: Dictionary in escort:
		for j in int(grp.get("count", 0)):
			var at := e.position + side * (float(k % 6) - 2.5) * 26.0 - Vector2.from_angle(a) * (40.0 + 18.0 * float(k / 6))
			game.enemies.spawn_at(String(grp["kind"]), at, false)
			k += 1
	if ev.has("banner"):
		game.enemies.show_banner(String(ev["banner"]))
	_log("cherub_gate")


## The HUD objective while the Cherub of the Gate stands ("" otherwise).
func objective_override() -> String:
	if _cherub != null and _cherub.active and _cherub.generation == _cherub_gen:
		return String(config.get("cherub_objective", ""))
	return ""


# =====================================================================================
# Report
# =====================================================================================

## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	return "steps %d (light x%.2f) | low cloud banks %d | worst third passed %d | without sin %s | cherub of the gate spawned %d, killed %d%s | events: %s" % [
		step_index + 1, _width, banks, worst_third,
		"EARNED" if without_sin else ("lost" if boss_down else "open"),
		int(st.get("silver_stair_cherub_spawned", 0.0)), int(st.get("silver_stair_cherub_killed", 0.0)),
		(" at " + cherub_time) if cherub_time != "" else "", ", ".join(fired)]


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	fired.append("%s %s" % [_clock(), what])


## The current game clock as "m:ss".
func _clock() -> String:
	var t := int(game.elapsed)
	return "%d:%02d" % [t / 60, t % 60]
