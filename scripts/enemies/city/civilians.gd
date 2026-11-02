## Civilians — the third Last Line rule, CIVILIANS (Act VIII; GDD §15.0
## "Civilians"; owner: "Civilians appearing at the beginning is awesome, but
## we're not sparing them. Let them drop XP to reward killing them"; "fleeing
## civilians fill the streets at the start of a run; the army kills them like
## any enemy, and each one drops XP; there is no sparing, and no penalty for
## killing them"), owned by Game.city as `civilians`. THE one path:
##   * at 0:00 a CROWD (`crowd`) appears in the streets `crowd_min`..`crowd_max`
##     px from the necromancer (beyond the clear radius), then a TRICKLE (one
##     every `trickle_every` s, at most `max_alive` alive) until the
##     `evacuate` tier (the army), when the city is evacuated;
##   * each civilian is an ordinary enemy of kind "civilian" with a CivilianKit:
##     it flees (away from the nearest necromancer and the nearest summon,
##     along the streets: CityBlocks.lane()), never attacks, never body-blocks
##     the ring (Enemy.civilian, read by Enemy.resolve_blocking()), is never hit
##     by the city's own blasts (CityRules.hits_enemy()), and leaves the field
##     (no XP) once `recycle` px from every necromancer (flee_off());
##   * the army kills them like any enemy: summons rank them with the row's
##     target_priority 0 and never as targeting the player, so every threat
##     comes first; no summon code changes. A kill goes the normal kill path
##     (an XP crystal of the fodder value, Rally charge, kill counts); no
##     sparing, no penalty, no Soul Ash line;
##   * their OWN alive cap: EnemyDirector.regular_alive() leaves them out
##     (alive_count()), so they never take a slot from the enemy cap.
## A stage's STAGE "civilians" dictionary overrides any key of
## CityRulesData.CIVILIANS. In co-op they flee from the nearest necromancer
## (the bound one, as every enemy steps). Off Act VIII (`enabled` false) no
## crowd or trickle comes; a forced civilian (--spawn=civilian@T) still flees.
## Determinism: the seeded gameplay RNG only (positions). Stats:
## city_civilians_spawned, city_civilians_fled, city_civilians_killed,
## city_civilians_xp.
class_name Civilians
extends RefCounted

## Owning run.
var game: Game
## True on an Act VIII stage: the crowd and the trickle come.
var enabled: bool = false
## The stage's civilian numbers (CIVILIANS with the STAGE's "civilians").
var cfg: Dictionary = {}
## Civilians alive now (CivilianKit.reset() / on_deactivate()).
var alive: int = 0
## Civilians spawned this run.
var spawned: int = 0
## Civilians that fled the field (no XP).
var fled: int = 0
## Civilians killed (by the army or anything else).
var killed: int = 0
## XP their deaths dropped.
var xp_dropped: int = 0
## True once the 0:00 crowd came.
var _crowd_done: bool = false
## Game time (s) of the next trickle civilian.
var _next: float = 0.0


## Builds the civilians for `p_game`; `p_enabled`: an Act VIII stage.
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	enabled = p_enabled
	cfg = CityRulesData.CIVILIANS.duplicate()
	var over: Dictionary = p_game.stage_def.get("civilians", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]


## Civilians alive now (EnemyDirector.regular_alive() subtracts them).
func alive_count() -> int:
	return alive


## True once the city is evacuated (the `evacuate` tier began): no more come.
func evacuated() -> bool:
	return game.city.escalation.reached(String(cfg["evacuate"]))


## Per-tick update (CityRules.step()): the 0:00 crowd, then the trickle.
func step(_delta: float) -> void:
	if not enabled:
		return
	if not _crowd_done:
		_crowd_done = true
		var n := int(cfg["crowd"])
		for k in n:
			_spawn_near(game.player.position, float(cfg["crowd_min"]), float(cfg["crowd_max"]))
		_next = game.elapsed + float(cfg["trickle_every"])
		return
	if game.elapsed < _next or evacuated() or game.countdown_finished():
		return
	_next += float(cfg["trickle_every"])
	if alive < int(cfg["max_alive"]):
		_spawn_near(game.player.position, float(cfg["trickle_min"]), float(cfg["trickle_max"]))


## One civilian in a street `rmin`..`rmax` px from `c` (on a blocks layout the
## point is moved onto the nearest street's roadway; elsewhere just free).
func _spawn_near(c: Vector2, rmin: float, rmax: float) -> void:
	var p := c + Vector2.from_angle(randf() * TAU) * randf_range(rmin, rmax)
	var cb := game.arena.city_blocks
	if cb != null:
		var ln := cb.lane(p, Vector2.RIGHT if randf() < 0.5 else Vector2.DOWN)
		var off := (randf() * 2.0 - 1.0) * float(ln["half"])  # Across the roadway (px).
		var d: Vector2 = ln["dir"]
		p = (ln["point"] as Vector2) + Vector2(-d.y, d.x) * off
	game.enemies.spawn_at(CityEnemyData.CIVILIAN, p, false)


## A civilian `e` was activated (CivilianKit.reset()).
func on_spawn(_e: Enemy) -> void:
	alive += 1
	spawned += 1
	game.stat_add("city_civilians_spawned", 1.0)


## A civilian `e` left the field, killed or not (CivilianKit.on_deactivate()).
func on_gone(_e: Enemy) -> void:
	alive = maxi(0, alive - 1)


## A civilian `e` was killed (CivilianKit.on_killed()): the normal kill path
## drops its XP; counted here.
func on_killed(e: Enemy) -> void:
	killed += 1
	xp_dropped += e.xp_value
	game.stat_add("city_civilians_killed", 1.0)
	game.stat_add("city_civilians_xp", float(e.xp_value))


## A civilian `e` got away (past `recycle` px from every necromancer): taken
## off the field with no XP (EnemyDirector.despawn()).
func flee_off(e: Enemy) -> void:
	fled += 1
	game.stat_add("city_civilians_fled", 1.0)
	game.enemies.despawn(e)


## True when `e` is farther than `recycle` px from every standing necromancer.
func far_from_all(e: Enemy) -> bool:
	var r := float(cfg["recycle"])
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_squared_to(e.position) <= r * r:
			return false
	return true
