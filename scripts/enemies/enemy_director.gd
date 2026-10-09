## EnemyDirector — spawns and updates the Crimson Covenant (GDD §22
## "EnemyDirector: Enemy waves, enemy density and event escalation").
##   * Reads the data-driven 5-minute timeline in WaveData: continuous
##     trickle segments + one-shot formation events + the boss at 5:00.
##   * Pools Enemy nodes; dead enemies are compacted out of `active` at the
##     start of the next step and reused.
##   * Staggers enemy AI: think() at 5 Hz, separation at 10 Hz, movement at
##     60 Hz.
##   * Recycles enemies left far behind to the spawn ring ahead of the player.
class_name EnemyDirector
extends Node2D

## The boss entered the arena.
signal boss_spawned(boss: BossAlaric)
## The boss died (big reward; the run continues).
signal boss_defeated
## The countdown hit 0:00 and the Reckoning began.
signal reckoning_started

## Owning run.
var game: Game
## Enemies in the world (may briefly contain inactive ones until compaction).
var active: Array[Enemy] = []
## Inactive enemies ready for reuse.
var _pool: Array[Enemy] = []
## Index of the current WaveData.SEGMENTS entry.
var segment_index: int = 0
## Index of the next WaveData.EVENTS entry to fire.
var event_index: int = 0
## Fractional enemies accumulated by the trickle spawner.
var spawn_accum: float = 0.0
## Current enemy HP multiplier from time scaling.
var hp_mult: float = 1.0
## Current enemy damage multiplier from time scaling.
var damage_mult: float = 1.0
## The boss once spawned (null before 5:00).
var boss: BossAlaric = null
## Event banner text shown on the HUD.
var banner_text: String = ""
## Game time (s) until which the banner is shown.
var banner_until: float = 0.0
## Total Enemy nodes ever instantiated (debug: pool health).
var created_nodes: int = 0
## Total enemies spawned (including reuse).
var total_spawned: int = 0
## Number of times far-away enemies were recycled ahead of the player.
var total_recycled: int = 0
## Reckoning waves spawned so far (0 before the countdown ends).
var reckoning_wave: int = 0
## Game time of the next Reckoning wave.
var _next_reckoning: float = WaveData.RUN_DURATION
## Physics ticks since run start (drives staggering).
var _frame: int = 0
## Next think slot handed to a new enemy (round-robin).
var _next_slot: int = 0


# =====================================================================================
# Main update
# =====================================================================================

## Fixed-order update called by Game every physics tick.
func step(delta: float) -> void:
	_frame += 1
	_compact()
	var t := game.elapsed
	_update_segment(t)
	hp_mult = 1.0 + t / 60.0 * WaveData.HP_SCALE_PER_MINUTE
	damage_mult = 1.0 + t / 60.0 * WaveData.DAMAGE_SCALE_PER_MINUTE
	_run_events(t)
	if boss == null and t >= WaveData.BOSS_TIME:
		_spawn_boss()
	if t >= _next_reckoning:
		_spawn_reckoning_wave()
	_spawn_trickle(delta)
	var slot := _frame % UnitData.AI_TICK_DIVISOR
	var sep_slot := _frame % 6
	var player_pos := game.player.position
	# Never recycle inside the spawn ring (tall / narrow windows can make the
	# ring larger than RECYCLE_DISTANCE, which would recycle forever).
	var recycle := maxf(WaveData.RECYCLE_DISTANCE, _ring_radius() + WaveData.RECYCLE_MARGIN)
	var recycle2 := recycle * recycle
	for e in active:
		if not e.active:
			continue
		if e.think_slot == slot:
			e.think()
		if e.think_slot % 6 == sep_slot:
			e.update_separation()
		e.physics_step(delta)
		e.resolve_blocking()
		if not e.is_boss and e.position.distance_squared_to(player_pos) > recycle2:
			_recycle(e)


## Removes enemies killed since the last step from `active`.
func _compact() -> void:
	var i := 0
	while i < active.size():
		if active[i].active:
			i += 1
		else:
			active[i] = active[active.size() - 1]
			active.pop_back()


## Number of living regular (non-boss) enemies.
func regular_alive() -> int:
	var n := 0
	for e in active:
		if e.active and not e.is_boss:
			n += 1
	return n


## Current HUD objective text from the active segment.
func objective_text() -> String:
	if reckoning_wave > 0:
		return WaveData.RECKONING_OBJECTIVE
	if boss != null and not boss.active:
		return "Sir Alaric is dead. Survive until the countdown ends."
	return WaveData.SEGMENTS[segment_index]["objective"]


# =====================================================================================
# Timeline
# =====================================================================================

## Advances `segment_index` to the last segment that has started.
func _update_segment(t: float) -> void:
	while segment_index + 1 < WaveData.SEGMENTS.size() and t >= float(WaveData.SEGMENTS[segment_index + 1]["start"]):
		segment_index += 1


## Trickle spawner: `rate` enemies/s up to the segment's max_alive.
func _spawn_trickle(delta: float) -> void:
	var seg: Dictionary = WaveData.SEGMENTS[segment_index]
	spawn_accum += float(seg["rate"]) * delta
	var cap: int = mini(int(seg["max_alive"]), WaveData.HARD_CAP)
	var alive := regular_alive()
	while spawn_accum >= 1.0:
		spawn_accum -= 1.0
		if alive >= cap:
			continue
		var kind := _pick_kind(seg["weights"])
		_spawn_enemy(kind, _ring_point(randf() * TAU), false)
		alive += 1


## Weighted random choice of an enemy kind.
func _pick_kind(weights: Dictionary) -> String:
	var total := 0.0
	for k: String in weights:
		total += float(weights[k])
	var roll := randf() * total
	for k: String in weights:
		roll -= float(weights[k])
		if roll <= 0.0:
			return k
	return "recruit"


## Fires every timeline event whose time has come.
func _run_events(t: float) -> void:
	while event_index < WaveData.EVENTS.size() and t >= float(WaveData.EVENTS[event_index]["time"]):
		_run_event(WaveData.EVENTS[event_index])
		event_index += 1


## Spawns one event's groups in its formation and shows its banner.
func _run_event(ev: Dictionary) -> void:
	show_banner(ev["banner"])
	var members: Array[Dictionary] = []
	for g: Dictionary in ev["groups"]:
		for i in int(g["count"]):
			members.append({"kind": g["kind"], "elite": g["elite"]})
	var n := members.size()
	var center := randf() * TAU
	var ring := _ring_radius()
	var p := game.player.position
	var alive := regular_alive()
	for i in n:
		if alive >= WaveData.HARD_CAP:
			break
		var pos: Vector2
		match String(ev["formation"]):
			"ring":
				pos = p + Vector2.from_angle(TAU * float(i) / float(n) + randf_range(-0.05, 0.05)) * ring
			"arc":
				var a := center + (float(i) / maxf(1.0, float(n - 1)) - 0.5) * WaveData.ARC_SPREAD
				pos = p + Vector2.from_angle(a) * (ring + randf_range(0.0, 40.0))
			_:
				# "line": rows of 8 marching in from one direction.
				var dir := Vector2.from_angle(center)
				var perp := Vector2(-dir.y, dir.x)
				var row := floori(float(i) / 8.0)
				var col := i % 8
				pos = p + dir * (ring + float(row) * WaveData.LINE_SPACING) + perp * (float(col) - 3.5) * WaveData.LINE_SPACING
		var m := members[i]
		_spawn_enemy(m["kind"], pos, m["elite"])
		alive += 1
	game.stat_add("wave_events", 1.0)


## Shows `text` as the HUD event banner.
func show_banner(text: String) -> void:
	banner_text = text
	banner_until = game.elapsed + WaveData.BANNER_TIME


## Spawns Sir Alaric at the spawn ring.
func _spawn_boss() -> void:
	boss = BossAlaric.new()
	add_child(boss)
	boss.setup_boss(game, _ring_point(randf() * TAU), 1.0, _next_slot)
	_next_slot = (_next_slot + 1) % UnitData.AI_TICK_DIVISOR
	active.append(boss)
	show_banner("Sir Alaric, the Gravebreaker, has arrived!")
	boss_spawned.emit(boss)


## Spawns the next Reckoning wave around the player: count and HP/damage
## compound every wave (WaveData.RECKONING), ignoring the regular caps.
func _spawn_reckoning_wave() -> void:
	var r: Dictionary = WaveData.RECKONING
	if reckoning_wave == 0:
		show_banner(r["banner"])
		reckoning_started.emit()
	var count: int = int(r["base_count"]) + int(r["count_growth"]) * reckoning_wave
	var hp_scale := hp_mult * pow(float(r["hp_growth"]), float(reckoning_wave))
	var dmg_scale := pow(float(r["damage_growth"]), float(reckoning_wave))
	var offset := randf() * TAU
	for i in count:
		var e := _spawn_enemy_def("inquisitor", EnemyData.RECKONING_ENEMY, _ring_point(offset + TAU * float(i) / float(count)), hp_scale, false)
		e.damage *= dmg_scale
		e.is_reckoning = true
	reckoning_wave += 1
	_next_reckoning += float(r["interval"])
	game.stat_add("reckoning_spawned", float(count))


# =====================================================================================
# Spawning, recycling, death
# =====================================================================================

## Radius (px) of the off-screen spawn ring around the player.
func _ring_radius() -> float:
	return game.view_size().length() * 0.5 + WaveData.SPAWN_MARGIN


## Point on the spawn ring at `angle`.
func _ring_point(angle: float) -> Vector2:
	return game.player.position + Vector2.from_angle(angle) * _ring_radius()


## Takes an enemy from the pool (or creates one) and activates it.
func _spawn_enemy(kind: String, pos: Vector2, elite: bool) -> Enemy:
	return _spawn_enemy_def(kind, EnemyData.ENEMIES[kind], pos, hp_mult, elite)


## As _spawn_enemy() but with an explicit definition and HP multiplier.
func _spawn_enemy_def(kind: String, def: Dictionary, pos: Vector2, hp_scale: float, elite: bool) -> Enemy:
	var e: Enemy
	if _pool.is_empty():
		e = Enemy.new()
		add_child(e)
		created_nodes += 1
	else:
		e = _pool.pop_back()
	e.activate(game, kind, def, pos, hp_scale, elite, _next_slot)
	_next_slot = (_next_slot + 1) % UnitData.AI_TICK_DIVISOR
	active.append(e)
	total_spawned += 1
	return e


## Moves a far-away enemy to the spawn ring ahead of the player's movement.
func _recycle(e: Enemy) -> void:
	var v := game.player.velocity
	var angle := v.angle() + randf_range(-1.0, 1.0) if v.length() > 1.0 else randf() * TAU
	e.position = _ring_point(angle)
	e.sep = Vector2.ZERO
	total_recycled += 1


## Called by CombatResolver when an enemy dies.
func on_enemy_killed(e: Enemy) -> void:
	e.deactivate()
	if e.is_boss:
		# Big reward burst (user brief: no longer the win condition).
		game.effects.impact(e.position, 120.0, Palette.GOLD)
		var n: int = EnemyData.BOSS["reward_crystals"]
		var each: int = maxi(1, floori(float(EnemyData.BOSS["reward_xp"]) / float(n)))
		for i in n:
			game.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * randf_range(20.0, 70.0), each)
		show_banner("Sir Alaric has fallen! Hold out until the end...")
		boss_defeated.emit()
	else:
		_pool.append(e)
