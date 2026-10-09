## HordeDirector — owns the undead army (GDD §22 / §32 / §39 HORDE DIRECTOR):
##   * living unit registry + object pool of SummonedUnit nodes,
##   * per-class skill level, capacity and effective stats (skill bonuses x
##     passive bonuses, GDD §34 stacking rule),
##   * per-ability sequential replenishment queues (GDD §24),
##   * soft formation anchors at 4 Hz (GDD §26),
##   * player threat evaluation at 5 Hz (GDD §32),
##   * staggered 5 Hz AI ticks: each unit thinks on 1 of 12 physics ticks,
##   * temporary summons from stage events (empowered graves, Crypt Defender
##     guardians): same shared AI, but outside caps / HUD counts, and they
##     crumble after their duration (GDD §15.0 decision on open question 14).
## Ranged overkill reservations are stored on the enemies themselves
## (Enemy.incoming_damage) and managed by ProjectileManager.
class_name HordeDirector
extends Node2D

## A summon finished being created (GDD §37 summon_created).
signal summon_created(unit: SummonedUnit)
## A summon died (GDD §37 summon_died).
signal summon_died(unit: SummonedUnit)
## Live summon count of any class changed (GDD §37 summon_count_changed).
signal summon_count_changed
## Capacity of any class changed (GDD §37 summon_cap_changed).
signal summon_cap_changed

## Owning run.
var game: Game
## Living (or spawning) units. Dead units are removed immediately.
var units: Array[SummonedUnit] = []
## Pooled, inactive unit nodes ready for reuse.
var _pool: Array[SummonedUnit] = []
## Class id -> summon ability level (0 = not learned).
var class_levels: Dictionary = {}
## Class id -> effective stats Dictionary (see compute_stats()).
var class_stats: Dictionary = {}
## Class id -> number of living units of that class.
var class_counts: Dictionary = {}
## Class id -> seconds accumulated toward the next replacement.
var replenish_timer: Dictionary = {}
## Class id -> units to spawn immediately (newly learned / capacity raised).
var immediate_spawns: Dictionary = {}
## Normalised direction from the player toward the main threat.
var threat_dir: Vector2 = Vector2.RIGHT
## 0..1 how much pressure the player is under.
var threat_level: float = 0.0
## True when enemies swarm the player or the player is low on HP.
var player_in_danger: bool = false
## Physics ticks since the run started (drives staggering).
var _frame: int = 0
## Next think slot handed to a new unit (round-robin).
var _next_slot: int = 0
## Total SummonedUnit nodes ever instantiated (debug: pool health).
var created_nodes: int = 0
## Total summons spawned (including reuse).
var total_spawned: int = 0
## Total summon deaths.
var total_deaths: int = 0
## Total hard recalls (should stay rare, GDD §24).
var hard_recalls: int = 0
## Temporary summons currently alive (not in class_counts).
var temp_alive: int = 0
## Temporary summons spawned this run.
var temp_spawned: int = 0
## Reusable query buffer.
var _tmp: Array = []


func _init() -> void:
	for cls: String in UnitData.CLASS_ORDER:
		class_levels[cls] = 0
		class_counts[cls] = 0
		replenish_timer[cls] = 0.0
		immediate_spawns[cls] = 0


# =====================================================================================
# Per-tick update (GDD §39 update_horde)
# =====================================================================================

## Fixed-order update called by Game every physics tick.
func step(delta: float) -> void:
	_frame += 1
	if temp_alive > 0:
		_update_temporaries(delta)
	_update_replenishment(delta)
	if _frame % UnitData.FORMATION_TICK_DIVISOR == 0:
		_calculate_formation_anchors()
	# Offset by half a period so threat checks never share a tick with the
	# formation update.
	if _frame % UnitData.THREAT_TICK_DIVISOR == (UnitData.THREAT_TICK_DIVISOR >> 1):
		_evaluate_player_threats()
	var slot := _frame % UnitData.AI_TICK_DIVISOR
	# Safe to iterate directly: units only die from enemy / projectile / boss
	# damage, which never runs inside this loop.
	for u in units:
		if u.think_slot == slot:
			u.think()
		u.physics_step(delta)


# =====================================================================================
# Levels, capacity and effective stats
# =====================================================================================

## Sets the summon ability level of `cls` (1..5) and queues the extra units
## the new capacity allows ("Buy Warrior -> exactly two spawn", GDD §40).
func set_class_level(cls: String, level: int) -> void:
	var old_cap := capacity(cls)
	class_levels[cls] = level
	_refresh_class(cls, old_cap)


## Class id -> current capacity. Take this snapshot BEFORE changing a passive
## and pass it to recompute_all() so only real capacity growth spawns units.
func capacity_snapshot() -> Dictionary:
	var caps := {}
	for cls: String in UnitData.CLASS_ORDER:
		caps[cls] = capacity(cls)
	return caps


## Recomputes every learned class after a passive changed. `old_caps` is the
## capacity_snapshot() taken before the change: only the capacity increase
## (new cap - old cap) spawns immediately; units that were already dead keep
## waiting for their normal replacement timer (GDD §24).
func recompute_all(old_caps: Dictionary) -> void:
	for cls: String in UnitData.CLASS_ORDER:
		if int(class_levels[cls]) > 0:
			_refresh_class(cls, int(old_caps.get(cls, capacity(cls))))


## Recomputes stats for `cls`, pushes them to living units (HP % preserved)
## and queues immediate spawns for the capacity gained since `old_cap`.
func _refresh_class(cls: String, old_cap: int) -> void:
	var level: int = class_levels[cls]
	if level <= 0:
		return
	var stats := compute_stats(cls, level)
	class_stats[cls] = stats
	for u in units:
		if u.unit_class == cls and not u.is_temporary:
			u.apply_stats(stats, true)
	var new_cap := capacity(cls)
	if new_cap > old_cap:
		immediate_spawns[cls] = int(immediate_spawns[cls]) + (new_cap - old_cap)
	summon_cap_changed.emit()


## Population cap for `cls`: ability level count + Grave Dominion bonus
## (GDD §23 "Army cap = sum of equipped summon abilities' class caps + global
## bonuses"). Pass `dominion_level` to preview another passive level.
func capacity(cls: String, dominion_level: int = -1) -> int:
	var level: int = class_levels[cls]
	if level <= 0:
		return 0
	var row: Dictionary = UnitData.LEVELS[cls][level - 1]
	var cap: int = row["count"]
	var dl := dominion_level if dominion_level >= 0 else game.abilities.passive_level("grave_dominion")
	if dl > 0:
		cap += int(PassiveData.PASSIVES["grave_dominion"]["levels"][dl - 1]["capacity_per_class"])
	return cap


## Total army capacity across all classes (optionally previewing a different
## Grave Dominion level).
func total_capacity(dominion_level: int = -1) -> int:
	var total := 0
	for cls: String in UnitData.CLASS_ORDER:
		total += capacity(cls, dominion_level)
	return total


## Seconds between replacements for `cls` (GDD §24 base x Soul Recycling).
func replenish_interval(cls: String) -> float:
	var base: float = UnitData.UNITS[cls]["replenish_interval"]
	return base * (1.0 - game.abilities.passive_value("soul_recycling", "replace_reduction"))


## Effective stats of class `cls` at skill `level` with the CURRENT passives.
## Stacking (GDD §34): like-category bonuses add, categories multiply:
##   stat = base * (1 + skill_bonus) * (1 + passive_bonus).
## Attack interval divides by the attack-speed multipliers.
func compute_stats(cls: String, level: int) -> Dictionary:
	var base: Dictionary = UnitData.UNITS[cls]
	var row: Dictionary = UnitData.LEVELS[cls][clampi(level, 1, 5) - 1]
	var ab := game.abilities
	var hp_mult := (1.0 + float(row.get("hp_bonus", 0.0))) * (1.0 + ab.passive_value("necrotic_vigor", "minion_hp"))
	var dmg_mult := (1.0 + float(row.get("damage_bonus", 0.0))) * (1.0 + ab.passive_value("dark_command", "minion_damage"))
	var spd_mult := (1.0 + float(row.get("speed_bonus", 0.0))) * (1.0 + ab.passive_value("dark_command", "minion_speed"))
	var heal_mult := 1.0 + float(row.get("heal_bonus", 0.0))
	var splash_mult := 1.0 + float(row.get("splash_bonus", 0.0))
	var shield_mult := 1.0 + float(row.get("shield_bonus", 0.0))
	return {
		"count": int(row["count"]),
		"max_hp": float(base["max_hp"]) * hp_mult,
		"damage": float(base["damage"]) * dmg_mult,
		"attack_interval": float(base["attack_interval"]) / spd_mult,
		"attack_range": float(base["attack_range"]),
		"acquisition_range": float(base["acquisition_range"]),
		"move_speed": float(base["move_speed"]),
		"radius": float(base["radius"]),
		"band_min": float(base["band_min"]),
		"band_max": float(base["band_max"]),
		"w_pursuit": float(base["w_pursuit"]),
		"w_formation": float(base["w_formation"]),
		"w_separation": float(base["w_separation"]),
		"w_threat": float(base["w_threat"]),
		"windup": float(base["windup"]),
		"projectile_speed": float(base["projectile_speed"]),
		"splash_radius": float(base["splash_radius"]) * splash_mult,
		"heal_amount": float(base["heal_amount"]) * heal_mult,
		"kite_distance": float(base["kite_distance"]),
		"pierce": int(row.get("pierce", 0)),
		"block_radius": float(base.get("block_radius", 0.0)),
		"block_mass": float(base.get("block_mass", 0.0)),
		"engaged_speed_mult": float(base.get("engaged_speed_mult", 1.0)),
		"bash_damage": float(base.get("bash_damage", 0.0)) * dmg_mult,
		"bash_cooldown": float(base.get("bash_cooldown", 0.0)),
		"bash_knockback": float(base.get("bash_knockback", 0.0)),
		"shield_amount": float(base.get("shield_amount", 0.0)) * shield_mult,
		"shield_duration": float(base.get("shield_duration", 0.0)),
		"shield_cooldown": float(base.get("shield_cooldown", 0.0)),
		"heal_role_priority": float(base["heal_role_priority"]),
		"attack_profile": String(base["attack_profile"]),
		"target_profile": String(base["target_profile"]),
	}


# =====================================================================================
# Replenishment (GDD §24 / §39 REPLENISHMENT)
# =====================================================================================

## Each summon ability runs its own queue: missing units come back one at a
## time per interval; capacity increases spawn immediately. A failed spawn
## does not consume the timer (GDD §24 "Failed spawns retry").
func _update_replenishment(delta: float) -> void:
	for cls: String in UnitData.CLASS_ORDER:
		if int(class_levels[cls]) <= 0:
			continue
		var cap := capacity(cls)
		var count: int = class_counts[cls]
		if count >= cap:
			replenish_timer[cls] = 0.0
			immediate_spawns[cls] = 0
			continue
		if int(immediate_spawns[cls]) > 0:
			if _try_spawn(cls):
				immediate_spawns[cls] = int(immediate_spawns[cls]) - 1
			continue
		replenish_timer[cls] = float(replenish_timer[cls]) + delta
		if float(replenish_timer[cls]) >= replenish_interval(cls):
			if _try_spawn(cls):
				replenish_timer[cls] = 0.0
				game.stat_add("replacements", 1.0)


## Fraction 0..1 of the current replacement timer for HUD display.
func replenish_progress(cls: String) -> float:
	if int(class_counts[cls]) >= capacity(cls):
		return 1.0
	return clampf(float(replenish_timer[cls]) / replenish_interval(cls), 0.0, 1.0)


## Tries to spawn one unit of `cls` 35–80 px from the player, not inside an
## enemy body. Returns false (retry next frame) if no spot was found.
func _try_spawn(cls: String) -> bool:
	var stats: Dictionary = class_stats[cls]
	var r: float = stats["radius"]
	for _attempt in UnitData.SPAWN_RETRIES:
		var pos := game.player.position + Vector2.from_angle(randf() * TAU) * randf_range(UnitData.SPAWN_MIN, UnitData.SPAWN_MAX)
		# Never inside an enemy, an obstacle or a holy zone (holy ground
		# suppresses replacement locally, GDD §10).
		if _blocked_by_enemy(pos, r) or game.arena.is_blocked(pos, r) or game.enemies.stage.in_holy_zone(pos):
			continue
		var u: SummonedUnit
		if _pool.is_empty():
			u = SummonedUnit.new()
			add_child(u)
			created_nodes += 1
		else:
			u = _pool.pop_back()
		u.activate(self, game, cls, stats, pos, _next_slot)
		_next_slot = (_next_slot + 1) % UnitData.AI_TICK_DIVISOR
		units.append(u)
		class_counts[cls] = int(class_counts[cls]) + 1
		total_spawned += 1
		game.effects.spawn_ring(pos, Palette.NECRO_GREEN)
		summon_created.emit(u)
		summon_count_changed.emit()
		return true
	return false


## Spawns a temporary summon of `cls` near `pos` for `duration` seconds,
## using the class's current effective stats (level 1 if not learned) times
## `hp_mult` / `dmg_mult`. It runs the shared AI but is not counted in
## class_counts (caps, HUD) and is never replaced.
func spawn_temporary(cls: String, pos: Vector2, duration: float, hp_mult: float, dmg_mult: float) -> SummonedUnit:
	var stats := compute_stats(cls, maxi(1, int(class_levels[cls])))
	stats["max_hp"] = float(stats["max_hp"]) * hp_mult
	stats["damage"] = float(stats["damage"]) * dmg_mult
	stats["bash_damage"] = float(stats["bash_damage"]) * dmg_mult
	var at := game.arena.free_point(pos, float(stats["radius"]))
	var u: SummonedUnit
	if _pool.is_empty():
		u = SummonedUnit.new()
		add_child(u)
		created_nodes += 1
	else:
		u = _pool.pop_back()
	u.activate(self, game, cls, stats, at, _next_slot)
	u.is_temporary = true
	u.temp_life = duration
	_next_slot = (_next_slot + 1) % UnitData.AI_TICK_DIVISOR
	units.append(u)
	temp_alive += 1
	temp_spawned += 1
	game.effects.spawn_ring(at, Palette.NECRO_GREEN)
	return u


## Ages temporary summons and crumbles the expired ones (outside the unit
## loop, which must not see the array change).
func _update_temporaries(delta: float) -> void:
	var i := units.size() - 1
	while i >= 0:
		var u := units[i]
		if u.is_temporary:
			u.temp_life -= delta
			if u.temp_life < 5.0:
				u.queue_redraw()  # aura dims as it expires
			if u.temp_life <= 0.0:
				game.stat_add("temporary_expired", 1.0)
				on_unit_died(u)
		i -= 1


## True if `pos` overlaps a living enemy body.
func _blocked_by_enemy(pos: Vector2, r: float) -> bool:
	game.enemy_grid.query(pos, r + 30.0, _tmp)
	for e: Enemy in _tmp:
		if e.active and e.position.distance_to(pos) < e.radius + r:
			return true
	return false


## Death handling (GDD §24): stop AI, deregister, release reservations, play
## FX, pool the node; the class queue then replaces it after its interval.
func on_unit_died(u: SummonedUnit) -> void:
	if not u.active:
		return
	var idx := units.find(u)
	if idx >= 0:
		units[idx] = units[units.size() - 1]
		units.pop_back()
	if u.is_temporary:
		temp_alive -= 1
	else:
		class_counts[u.unit_class] = maxi(0, int(class_counts[u.unit_class]) - 1)
		total_deaths += 1
	game.effects.pop(u.position, Palette.COLD_BLUE, u.radius * 1.2)
	u.deactivate()
	_pool.append(u)
	summon_died.emit(u)
	summon_count_changed.emit()


## Number of living units of `cls`.
func count_of(cls: String) -> int:
	return class_counts[cls]


# =====================================================================================
# Formation (GDD §26) and threat evaluation (GDD §32)
# =====================================================================================

## Assigns each unit a player-relative anchor inside its class band.
## Warriors spread in an arc facing the threat (or a full ring when calm);
## archers + mages share the midline ring; priests sit on the side away from
## the threat. Stable per-unit jitter keeps it from looking geometric.
func _calculate_formation_anchors() -> void:
	var warriors: Array[SummonedUnit] = []
	var midline: Array[SummonedUnit] = []
	var support: Array[SummonedUnit] = []
	for u in units:
		match u.unit_class:
			"warrior":
				warriors.append(u)
			"priest":
				support.append(u)
			_:
				midline.append(u)
	var threat_angle := threat_dir.angle()
	var calm_rot := float(_frame) * 0.0005
	# Warriors: arc toward the threat, narrowing as pressure rises.
	var w_spread := lerpf(TAU, PI * 0.8, threat_level)
	_assign_arc(warriors, threat_angle if threat_level > 0.05 else calm_rot, w_spread if threat_level > 0.05 else TAU)
	# Midline: full ring, offset half a slot so it interleaves with warriors.
	_assign_arc(midline, threat_angle + PI / maxf(1.0, float(midline.size())), TAU)
	# Support: behind the army relative to the threat.
	if threat_level > 0.05:
		_assign_arc(support, threat_angle + PI, PI * 0.7)
	else:
		_assign_arc(support, calm_rot + PI * 0.5, TAU)


## Distributes `list` evenly over an arc of `spread` radians centred on
## `center_angle`, each unit at a stable radius inside its own band. Anchors
## that would fall inside an obstacle are moved out of it.
func _assign_arc(list: Array[SummonedUnit], center_angle: float, spread: float) -> void:
	var n := list.size()
	if n == 0:
		return
	var pp := game.player.position
	for i in n:
		var u := list[i]
		var t := (float(i) + 0.5) / float(n) - 0.5
		var angle := center_angle + t * spread + (u.slot_jitter - 0.5) * UnitData.FORMATION_JITTER_ANGLE
		var r := lerpf(u.band_min, u.band_max, 0.2 + 0.6 * u.band_jitter)
		u.anchor_offset = game.arena.free_point(pp + Vector2.from_angle(angle) * r, u.radius) - pp


## Summarises enemies near the player into a direction + pressure level and
## the "player in danger" flag used by warrior targeting.
func _evaluate_player_threats() -> void:
	var p := game.player.position
	game.enemy_grid.query(p, UnitData.THREAT_RADIUS, _tmp)
	var sum := Vector2.ZERO
	var weight := 0.0
	var close := 0
	for e: Enemy in _tmp:
		if not e.active:
			continue
		var diff := e.position - p
		var d := diff.length()
		var w := 1.0 - d / UnitData.THREAT_RADIUS
		if d > 0.01:
			sum += diff / d * w
		weight += w
		if d <= UnitData.DANGER_RADIUS:
			close += 1
	if sum.length() > 0.01:
		threat_dir = sum.normalized()
	threat_level = clampf(weight / 6.0, 0.0, 1.0)
	player_in_danger = close >= UnitData.DANGER_COUNT or game.player.hp < game.player.max_hp * UnitData.DANGER_HP_FRACTION


## Number of living units in each FSM state (debug overlay).
func state_counts() -> Dictionary:
	var counts := {}
	for u in units:
		var key: String = SummonedUnit.State.keys()[u.state]
		counts[key] = int(counts.get(key, 0)) + 1
	return counts
