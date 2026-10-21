## Enemy pool regression: exercise real combat, spawning and solo/co-op grid
## rebuilds without advancing simulation time. Run the companion scene with
## --autotest (optionally --coop-bot). tools/.gdignore keeps it out of exports.
extends Node

## Failed assertions; any failure makes the process exit nonzero.
var _failures: int = 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	if not GameState.autotest:
		push_error("enemy_pool_check requires --autotest (no save writes).")
		get_tree().quit(2)
		return
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	var game: Game = main.get("_game")
	game.set_physics_process(false)
	var director := game.enemies
	var at := Vector2(300.0, 300.0)
	var dead := director.spawn_at("recruit", at, false)
	var old_generation := dead.generation
	_rebuild(game)
	game.combat.damage_enemy(dead, 100000.0, "shadow_bolt")
	var before_compact := director.spawn_at("recruit", at, false)
	_check(before_compact != dead, "a kill cannot be reused before compaction")
	_check(director.active.count(before_compact) == 1, "spawn has exactly one active-list entry")
	_check(not dead.active, "the dead grid reference stays inactive")
	director._compact()
	_check(not director.active.has(dead), "compaction removes the killed entry")
	var after_compact := director.spawn_at("recruit", at, false)
	_check(after_compact != dead, "compaction alone cannot release an old grid reference")
	var nearby: Array = []
	game.enemy_grid.query(at, 1000.0, nearby)
	_check(nearby.has(dead) and not dead.active, "old bucket contains only an inert retired enemy")
	_check(not nearby.has(after_compact), "a new spawn cannot alias an old bucket")
	_rebuild(game)
	var recycled := director.spawn_at("recruit", at, false)
	_check(recycled == dead, "clearing the grid makes the compacted node reusable")
	_check(recycled.generation == old_generation + 1, "reuse advances the generation exactly once")
	_check(director.active.count(recycled) == 1, "recycled node has exactly one active-list entry")
	game.enemy_grid.query(at, 1000.0, nearby)
	_check(not nearby.has(recycled), "reused node has no stale grid entry")

	# A clear before compaction is insufficient, including repeated despawns.
	director.despawn(recycled)
	director.despawn(recycled)
	_rebuild(game)
	var early := director.spawn_at("recruit", at, false)
	_check(early != recycled, "grid clear cannot release a node still in the active list")
	director._compact()
	_rebuild(game)
	var after_despawn := director.spawn_at("recruit", at, false)
	_check(after_despawn == recycled, "despawned node is reusable after both boundaries")
	_check(director.active.count(after_despawn) == 1, "repeated despawn cannot pool the node twice")

	# Repeated mixed deaths/despawns must recycle a bounded set of nodes, with
	# no duplicate list entries or duplicate living spatial-query results.
	for e in director.active:
		director.despawn(e)
	director._compact()
	_rebuild(game)
	for cycle in 100:
		for i in 8:
			director.spawn_at("recruit", at, false)
		_check(director.active.size() == 8 and director.regular_alive() == 8, "cycle %d: living count" % cycle)
		_rebuild(game)
		game.enemy_grid.query(at, 1000.0, nearby)
		_check(nearby.size() == 8, "cycle %d: spatial count" % cycle)
		for i in director.active.size():
			var e := director.active[i]
			_check(director.active.count(e) == 1 and nearby.count(e) == 1, "cycle %d: unique enemy" % cycle)
			if i % 2 == 0:
				game.combat.damage_enemy(e, 100000.0, "shadow_bolt")
			else:
				director.despawn(e)
		director._compact()
		_rebuild(game)
	_check(director.created_nodes == 8, "100 mixed cycles reuse eight nodes without pool growth")
	print("[enemy_pool_check] %s mode=%s cycles=100 created=%d failures=%d" % [
		"PASS" if _failures == 0 else "FAIL", "co-op" if game.coop != null else "solo",
		director.created_nodes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


## Use the production grid boundary in both modes (co-op has its own path).
func _rebuild(game: Game) -> void:
	if game.coop != null:
		game.coop._rebuild_grids()
	else:
		game._rebuild_grids()


## Report every failed invariant instead of letting a script assert hang CI.
func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("enemy_pool_check: " + message)
