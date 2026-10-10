## ChestManager — treasure chests (user request; rules and numbers in
## ChestData). It rolls a chest on enemy kills (CombatResolver._kill_enemy
## calls on_enemy_killed): elites at ELITE_CHANCE, Sir Alaric always, and a
## pity drop from any regular kill after PITY_TIME s without a chest (or
## EVOLUTION_PITY_TIME s while an evolution is ready); never
## from Reckoning enemies or after 0:00. Chests are pooled Chest nodes that
## never despawn. Walking over one asks Game.open_chest() to pause the run
## and show the reveal (ChestPanel); at most one chest opens per tick.
## Rolls use their own RandomNumberGenerator (seeded from the autotest seed)
## so the gameplay RNG stream is untouched and runs stay deterministic.
## Counters (Game.stats): chests_spawned, chests_opened, chest_items,
## chest_count_<n>, chests_lost_at_cap, chests_pity; `open_log` lists every
## opened chest for the autotest summary.
class_name ChestManager
extends Node2D

## Owning run.
var game: Game
## Chests lying in the world.
var active: Array[Chest] = []
## Idle chest nodes ready for reuse.
var _pool: Array[Chest] = []
## Total Chest nodes ever instantiated (debug: pool health).
var created: int = 0
## Game seconds since the last chest was dropped (pity timer).
var since_chest: float = 0.0
## "mm:ss xN: item, item" per opened chest (autotest summary).
var open_log: PackedStringArray = PackedStringArray()
## Chest drop / content-size RNG, separate from the gameplay RNG.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	z_index = -1
	if GameState.autotest:
		_rng.seed = hash("chests:%d" % GameState.autotest_seed)
	else:
		_rng.randomize()


## Ages the pity timer, animates chests and opens the first one the
## necromancer walks over (only while the run is playing).
func step(delta: float) -> void:
	since_chest += delta
	var p := game.player.position  # Necromancer position.
	var reach := game.player.radius + ChestData.PICKUP_RADIUS  # Collection distance (px).
	for i in active.size():
		var c := active[i]  # Chest being checked.
		c.tick(delta)
		if game.run_state == Game.RunState.PLAYING and c.position.distance_to(p) <= reach + ChestData.SIZE * 0.5:
			var pos := c.position  # Where it was opened.
			active.remove_at(i)
			c.deactivate()
			_pool.append(c)
			game.open_chest(pos)
			return


## Kill hook: drops a chest per the ChestData rules.
func on_enemy_killed(e: Enemy) -> void:
	if e.is_reckoning or game.countdown_finished():
		return
	if e.is_boss:
		spawn_chest(e.position, true)
		return
	var pity := since_chest >= ChestData.PITY_TIME  # Pity timer ran out.
	if not pity and since_chest >= ChestData.EVOLUTION_PITY_TIME and not game.abilities.ready_evolutions().is_empty():
		pity = true  # An evolution waits for its chest: shorter pity.
	var rolled := e.is_elite and _rng.randf() < ChestData.ELITE_CHANCE  # Elite roll succeeded.
	if not pity and not rolled:
		return
	if active.size() >= ChestData.MAX_LIVE:
		# Ground full: a won elite roll is lost; pity simply waits.
		if rolled:
			game.stat_add("chests_lost_at_cap", 1.0)
		return
	spawn_chest(e.position, false)
	if pity and not rolled:
		game.stat_add("chests_pity", 1.0)


## Places a chest at `pos` (out of obstacles). At MAX_LIVE the chest is lost
## unless `force`. Returns true if placed.
func spawn_chest(pos: Vector2, force: bool) -> bool:
	if active.size() >= ChestData.MAX_LIVE and not force:
		return false
	var c: Chest  # Chest node (pooled or new).
	if _pool.is_empty():
		c = Chest.new()
		add_child(c)
		created += 1
	else:
		c = _pool.pop_back()
	c.setup(game.arena.free_point(pos, ChestData.SIZE))
	active.append(c)
	since_chest = 0.0
	game.stat_add("chests_spawned", 1.0)
	return true


## Weighted number of upgrades in the next chest (ChestData.COUNT_WEIGHTS);
## always 1 before ChestData.LARGE_CHEST_TIME. The roll is made either way,
## so the chest RNG stream does not depend on the time gate.
func roll_count() -> int:
	var n_rolled := _roll_weights()  # 1, 3 or 5 from the weights.
	return n_rolled if game.elapsed >= ChestData.LARGE_CHEST_TIME else 1


## Weighted 1 / 3 / 5 draw over ChestData.COUNT_WEIGHTS.
func _roll_weights() -> int:
	var total := 0.0  # Sum of the weights.
	for n: int in ChestData.COUNT_WEIGHTS:
		total += float(ChestData.COUNT_WEIGHTS[n])
	var roll := _rng.randf() * total  # Position inside the weight line.
	for n: int in ChestData.COUNT_WEIGHTS:
		roll -= float(ChestData.COUNT_WEIGHTS[n])
		if roll <= 0.0:
			return n
	return 1


## Records an opened chest (stats + summary log).
func record_opened(count: int, rewards: Array[Dictionary]) -> void:
	game.stat_add("chests_opened", 1.0)
	game.stat_add("chest_count_%d" % count, 1.0)
	game.stat_add("chest_items", float(rewards.size()))
	var names := PackedStringArray()  # "id Lv" per granted item.
	for r in rewards:
		match String(r["kind"]):
			"evolution":
				names.append("EVOLVE " + String(r["id"]))
				game.stat_add("chest_evolutions", 1.0)
			"fallback":
				names.append(String(r["id"]))
			_:
				names.append("%s %d" % [r["id"], int(r["to"])])
	var s := int(game.elapsed)  # Whole seconds for mm:ss.
	open_log.append("%02d:%02d x%d: %s" % [floori(float(s) / 60.0), s % 60, count, ", ".join(names)])


## Nearest chest within `reach` px of `p` (null if none; autotest bot).
func nearest_chest(p: Vector2, reach: float) -> Chest:
	var best: Chest = null  # Closest chest so far.
	var best_d := reach  # Its distance (starts at the search radius).
	for c in active:
		var d := c.position.distance_to(p)  # Distance to this chest.
		if d < best_d:
			best_d = d
			best = c
	return best
