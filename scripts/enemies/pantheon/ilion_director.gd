## IlionDirector — the stage systems of the Shores of Ilion (Stage 10; Act IV,
## GDD §15.0 "The Shores of Ilion (Act IV phase 2)"; owner-approved proposal
## docs/act4/PROPOSAL.md "Stage 10: The Shores of Ilion"), owned and stepped by
## EnemyDirector on a stage whose STAGE has an "ilion" config (IlionStage.ILION;
## null elsewhere). The zones are MarchDirector's, Poseidon's waves the shared
## DivineWrath's. Data: IlionStage (ILION, the "siege_towers" / "polyphemus"
## timeline events) and IlionEnemyData (the tower, the miniboss).
##   * Siege towers ("siege_towers" events): `count` towers (kind
##     IlionEnemyData.SIEGE_TOWER, a structure with the "cart" behaviour) appear
##     pass_distance px from the necromancer on the sea side and roll past him
##     toward the walls of Troy (ILION walls_dir, a fixed world direction: the
##     city is "up the beach"), each pass_offset px off his line, toward the
##     mirrored point on the wall side (Enemy.post_pos). Owner-approved: a
##     DESTROYED tower spills its garrison (the event's "garrison" groups,
##     stunned spill_stun s as they tumble out) and pays a Soul Ash bounty
##     (ash_per_tower, the run's "objective_ash") and an XP burst (reward_xp in
##     reward_crystals). Own decision (the proposal leaves it open): a tower
##     that REACHES the walls (its post_pos) drops its drawbridge and its
##     garrison marches out reach_garrison_mult times as many, no bounty; the
##     tower then leaves the field.
##   * Polyphemus ("polyphemus" event): the stage miniboss, spawned on the spawn
##     ring and tracked here (objective, kill time); his kit (PolyphemusKit)
##     registers him on the HUD's miniboss bar and pays his XP burst.
## Towers are ordinary pooled Enemy nodes (is_structure, is_objective: never
## recycled), polled with generation checks. Deterministic: only the seeded
## global RNG (the side each tower passes on). Stats: ilion_towers_rolled,
## ilion_towers_destroyed, ilion_towers_reached, ilion_garrison_spilled,
## ilion_garrison_marched, objective_ash, ilion_polyphemus_spawned,
## ilion_polyphemus_killed.
class_name IlionDirector
extends Node2D

## One rolling siege tower.
class Tower:
	extends RefCounted
	## The tower's Enemy node.
	var enemy: Enemy = null
	## Generation of `enemy` when it was placed (stale / death guard).
	var gen: int = 0
	## Last known world position (the garrison spills here).
	var pos: Vector2 = Vector2.ZERO
	## The timeline event that rolled it (garrison, rewards).
	var ev: Dictionary = {}

## Owning run.
var game: Game
## The stage's Ilion config (IlionStage.ILION).
var config: Dictionary = {}
## Towers on the field.
var towers: Array[Tower] = []
## Towers rolled this run.
var towers_rolled: int = 0
## Towers destroyed this run (the bounty paid).
var towers_destroyed: int = 0
## Towers that reached the walls this run (their garrison marched out stronger).
var towers_reached: int = 0
## "m:ss" of each destroyed tower (summary).
var destroy_times: PackedStringArray = PackedStringArray()
## "m:ss" Polyphemus fell ("" while alive / never spawned).
var polyphemus_time: String = ""
## Log of Ilion events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Polyphemus once spawned (null before / after; generation-checked).
var _poly: Enemy = null
## Generation of `_poly` when he spawned.
var _poly_gen: int = 0


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	_step_towers()
	_step_polyphemus()


# =====================================================================================
# Timeline events
# =====================================================================================

## Runs an Ilion timeline event (EnemyDirector forwards the "siege_towers" and
## "polyphemus" types; keys in IlionStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"siege_towers":
			_roll_towers(ev)
		"polyphemus":
			_spawn_polyphemus(ev)
	game.enemies.show_banner(String(ev["banner"]))


## Rolls `ev.count` towers past the necromancer toward the walls (see the
## header), side by side across his line.
func _roll_towers(ev: Dictionary) -> void:
	var n := int(ev["count"])
	var u: Vector2 = config["walls_dir"]  # Toward the walls (unit).
	var v := Vector2(-u.y, u.x)  # Across the beach.
	var reach := float(config["pass_distance"])  # px each side of the necromancer.
	var off := float(config["pass_offset"])  # px off his line.
	var p := game.player.position
	var flip := 1.0 if randf() < 0.5 else -1.0  # Which side the first tower passes on.
	var kind := String(ev.get("kind", IlionEnemyData.SIEGE_TOWER))
	for i in n:
		var lateral := off * flip * (1.0 + float(i)) * (1.0 if i % 2 == 0 else -1.0)  # Alternating sides, spreading out.
		var e := game.enemies.spawn_at(kind, p - u * reach + v * lateral, false)
		e.is_objective = true
		e.post_pos = p + u * reach + v * lateral
		var t := Tower.new()
		t.enemy = e
		t.gen = e.generation
		t.pos = e.position
		t.ev = ev
		towers.append(t)
		towers_rolled += 1
		game.effects.spawn_ring(e.position, Palette.PANTHEON_BRONZE_LIGHT)
	game.stat_add("ilion_towers_rolled", float(n))
	_log("towers_rolled_%d" % n)


## Spawns Polyphemus on the spawn ring and tracks him (his kit registers him
## on the HUD's miniboss bar; Enemy.is_miniboss: never recycled).
func _spawn_polyphemus(ev: Dictionary) -> void:
	var e := game.enemies.spawn_at(String(ev.get("kind", IlionEnemyData.POLYPHEMUS)), game.enemies.ring_point(randf() * TAU), bool(ev.get("elite", false)))
	_poly = e
	_poly_gen = e.generation
	game.stat_add("ilion_polyphemus_spawned", 1.0)
	game.shake(5.0)
	_log("polyphemus_arrived")


# =====================================================================================
# Towers, Polyphemus
# =====================================================================================

## Destroyed towers spill their garrison and pay; a tower at the walls marches
## its garrison out stronger and leaves.
func _step_towers() -> void:
	var i := 0
	while i < towers.size():
		var t := towers[i]
		var e := t.enemy
		if not e.active or e.generation != t.gen:
			_on_destroyed(t)
			towers.remove_at(i)
			continue
		t.pos = e.position
		if e.position.distance_to(e.post_pos) <= float(config["arrive_slack"]):
			_on_reached(t)
			game.enemies.despawn(e)
			towers.remove_at(i)
			continue
		i += 1


## A tower fell: its garrison tumbles out stunned, the bounty, the XP burst.
func _on_destroyed(t: Tower) -> void:
	towers_destroyed += 1
	destroy_times.append(_clock())
	game.stat_add("objective_ash", float(config["ash_per_tower"]))
	game.stat_add("ilion_towers_destroyed", 1.0)
	var xp := int(t.ev.get("reward_xp", 0))  # XP burst (in reward_crystals crystals).
	var n := maxi(1, int(t.ev.get("reward_crystals", 1)))
	if xp > 0:
		var each := maxi(1, floori(float(xp) / float(n)))
		for k in n:
			game.pickups.spawn(t.pos + Vector2.from_angle(TAU * float(k) / float(n)) * randf_range(18.0, 50.0), each)
	var spilled := _spill(t, 1.0, float(config["spill_stun"]))
	game.stat_add("ilion_garrison_spilled", float(spilled))
	game.effects.impact(t.pos, 80.0, Palette.PANTHEON_BRONZE_LIGHT)
	game.shake(5.0)
	if game.pantheon != null:
		game.pantheon.play_sound("siege_collapse", t.pos)
	game.enemies.show_banner("A siege tower crashes down: its garrison tumbles out!")
	_log("tower_destroyed")


## A tower reached the walls: its drawbridge drops and the garrison marches
## out reach_garrison_mult times as many (no bounty).
func _on_reached(t: Tower) -> void:
	towers_reached += 1
	game.stat_add("ilion_towers_reached", 1.0)
	var marched := _spill(t, float(config["reach_garrison_mult"]), 0.0)
	game.stat_add("ilion_garrison_marched", float(marched))
	game.effects.ring(t.pos, 70.0, Palette.PANTHEON_AEGEAN_LIGHT, 0.5)
	if game.pantheon != null:
		game.pantheon.play_sound("siege_creak", t.pos)
	game.enemies.show_banner("A siege tower reached the walls: its garrison marches out!")
	_log("tower_reached")


## Spawns tower `t`'s garrison (`mult` x each group's count, rounded) around
## its last position, each stunned `stun` s (0 = none); returns how many.
func _spill(t: Tower, mult: float, stun: float) -> int:
	var n := 0
	for grp: Dictionary in t.ev.get("garrison", []):
		var count := roundi(float(grp["count"]) * mult)
		for k in count:
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				return n
			var at := t.pos + Vector2.from_angle(TAU * float(n) / 7.0 + 0.3) * (t.enemy.radius + 14.0 + 4.0 * float(n % 3))
			var s := game.enemies.spawn_at(String(grp["kind"]), at, bool(grp["elite"]))
			if stun > 0.0:
				game.combat.stun_enemy(s, stun, 1.0, 1.0)
			n += 1
	return n


## Notes when Polyphemus fell (his XP burst and banner are his kit's, his
## chest ChestManager's miniboss rule).
func _step_polyphemus() -> void:
	if _poly == null or (_poly.active and _poly.generation == _poly_gen):
		return
	_poly = null
	game.stat_add("ilion_polyphemus_killed", 1.0)
	polyphemus_time = _clock()
	_log("polyphemus_killed")


# =====================================================================================
# Queries (enemy director, HUD, autopilot)
# =====================================================================================

## Towers still rolling.
func rolling_towers() -> int:
	var n := 0
	for t in towers:
		if t.enemy.active and t.enemy.generation == t.gen:
			n += 1
	return n


## HUD objective for the live Ilion objective ("" if none): Polyphemus first,
## then the rolling towers (until the boss arrives).
func objective_override() -> String:
	if _poly != null:
		return "Bring down Polyphemus: step out of the boulders' circles"
	var n := rolling_towers()
	if n > 0 and game.enemies.boss == null:
		return "Burn the siege towers before they reach the walls (%d rolling)" % n
	return ""


## Autopilot hint: the nearest rolling tower within `reach` px of `p`
## (Vector2.INF when none).
func seek_point(p: Vector2, reach: float) -> Vector2:
	var best := Vector2.INF
	var best_d := reach
	for t in towers:
		var d := p.distance_to(t.pos)
		if d < best_d:
			best_d = d
			best = t.pos
	return best


## One-line autotest summary: towers, garrisons, Polyphemus, objective ash.
func summary_line() -> String:
	return "siege towers rolled %d, destroyed %d (at %s), reached the walls %d, rolling %d | garrison spilled %d, marched out %d | polyphemus %s | objective ash %d" % [
		towers_rolled, towers_destroyed, ", ".join(destroy_times) if not destroy_times.is_empty() else "-", towers_reached, rolling_towers(),
		int(game.stats.get("ilion_garrison_spilled", 0.0)), int(game.stats.get("ilion_garrison_marched", 0.0)),
		("killed at " + polyphemus_time) if polyphemus_time != "" else ("alive" if _poly != null else "not spawned"),
		int(game.stats.get("objective_ash", 0.0))]


## Records an Ilion event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]
