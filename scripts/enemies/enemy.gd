## Enemy — one Crimson Covenant soldier, driven by EnemyDirector. A single
## data-driven script covers every regular kind (Recruit, Footman, Zealous
## Archer, Chaplain, Purifier, Templar Knight); EnemyData supplies stats and a
## `behavior` key:
##   melee     close in on the player, divert onto summons in the way.
##   purifier  hunt undead summons first (GDD §35), bonus damage vs undead.
##   ranged    walk at the player and shoot arrows (player or a nearer summon)
##             whenever a target is in range.
##   healer    walk at the player and heal the most wounded OTHER enemy in
##             range (§10).
##   templar   melee that periodically telegraphs a short rush lane and
##             charges along it, shoving summons aside; a warrior in the lane
##             stops the rush (GDD §10 "knockback/disruption", §35).
##   consecrator  set at runtime by StageDirector on a desecration-event
##             Chaplain: walks to its grave (`post_pos`) and holds there
##             while it channels (GDD §11 desecration events).
## Survivor convention (user brief): enemies ALWAYS advance on the player;
## nobody kites or holds at range. Ranged units only slow down briefly after
## each shot (EnemyData.SHOOT_SLOW_*).
## Sir Alaric (BossAlaric) extends this class so every targeting / damage
## system treats the boss like any enemy.
##
## Like summons, enemies are pooled; `generation` guards stale references and
## `incoming_damage` is the rough ranged-damage reservation the horde uses to
## avoid overkill (GDD §27/§32).
class_name Enemy
extends Node2D

# --- Identity / lifecycle -----------------------------------------------------------

## Owning run.
var game: Game
## Kind id from EnemyData.ORDER ("boss" for Sir Alaric).
var kind: String = ""
## True while alive in the world (false = pooled).
var active: bool = false
## Incremented on each activation; lets holders detect a recycled enemy.
var generation: int = 0
## Elite variant (more HP, bigger, gold ring, more XP).
var is_elite: bool = false
## True only for the boss.
var is_boss: bool = false
## Which of the AI_TICK_DIVISOR physics ticks this enemy thinks on.
var think_slot: int = 0

# --- Stats (from EnemyData, scaled by time) -------------------------------------

## UI name.
var display_name: String = ""
## Maximum HP (after time scaling / elite multiplier).
var max_hp: float = 1.0
## Current HP.
var hp: float = 1.0
## Movement speed in px/s.
var move_speed: float = 50.0
## Damage per attack before the director's time-scaling multiplier.
var damage: float = 5.0
## Seconds between attacks.
var attack_interval: float = 1.0
## Melee reach (px, edge-to-edge) or max firing distance (ranged).
var attack_range: float = 4.0
## Body radius in px.
var radius: float = 9.0
## Fraction of incoming damage ignored (0..0.9).
var armor: float = 0.0
## XP crystal value dropped on death.
var xp_value: int = 1
## AI branch: "melee" | "purifier" | "ranged" | "healer".
var behavior: String = "melee"
## Arrow speed in px/s.
var projectile_speed: float = 0.0
## Damage multiplier against undead summons.
var undead_damage_mult: float = 1.0
## HP healed per chaplain cast.
var heal_amount: float = 0.0
## Seconds between chaplain heals.
var heal_interval: float = 0.0
## Chaplain heal search radius in px.
var heal_radius: float = 0.0
## 0..1 role priority summons use when scoring this enemy.
var target_priority: float = 0.2
## Fraction of slow effects ignored (boss only).
var slow_resist: float = 0.0
## Weight vs blocking warriors (overlap correction is mass-weighted).
var mass: float = 1.0
## True for Reckoning enemies (spawned after the countdown ends).
var is_reckoning: bool = false
## True for stage-objective enemies (consecrators): never recycled.
var is_objective: bool = false
## World point a "consecrator" walks to and holds.
var post_pos: Vector2 = Vector2.ZERO

# --- Runtime --------------------------------------------------------------------------

## Pending ranged damage already "in flight" toward this enemy (overkill
## reservation, approximate by design).
var incoming_damage: float = 0.0
## Seconds until the next attack.
var attack_cd: float = 0.0
## Seconds until the next chaplain heal.
var heal_cd: float = 0.0
## Current attack/approach target: the Necromancer or a SummonedUnit.
var target: Node2D = null
## Generation of `target` if it is a SummonedUnit.
var target_gen: int = 0
## True when this enemy is attacking the player up close (warrior scoring).
var targeting_player: bool = false
## True when this enemy is attacking a nearby summon (warrior scoring).
var targeting_summon: bool = false
## Chaplain heal target.
var heal_target: Enemy = null
## Generation of `heal_target` when chosen.
var heal_target_gen: int = 0
## Cached separation push from nearby enemies (refreshed at ~10 Hz).
var sep: Vector2 = Vector2.ZERO
## Current velocity in px/s.
var velocity: Vector2 = Vector2.ZERO
## Remaining slow duration in seconds.
var slow_timer: float = 0.0
## Fraction of speed removed while slowed.
var slow_factor: float = 0.0
## Remaining hit-flash time in seconds.
var flash: float = 0.0
## Seconds before Orb Shield orbs may hit this enemy again.
var orb_hit_cd: float = 0.0
## Seconds left "engaged" by a blocking warrior (slowed, fights it).
var engaged_timer: float = 0.0
## Speed multiplier while engaged (from the blocking warrior's data).
var engaged_mult: float = 1.0
## Knockback velocity in px/s (shield bashes), decays over time.
var knockback: Vector2 = Vector2.ZERO
## Seconds left of a mage mark (Volley of the Fallen synergy, GDD §6.3):
## skeletal arrows deal bonus damage while it is > 0.
var mark_time: float = 0.0
## Seconds left of the brief slowdown after a ranged unit fires.
var _shoot_slow_timer: float = 0.0
## True while a Stasis power-up holds this enemy (EnemyDirector skips its
## think() / physics_step(); drawn with an ice overlay).
var frozen: bool = false
## Seconds left of a Frost Wraith Deep Freeze (CombatResolver.freeze_enemy):
## while > 0 EnemyDirector freezes this enemy exactly like Stasis.
var freeze_timer: float = 0.0
## Seconds left of a Frost Wraith chill (the slow itself is slow_timer; this
## only drives the frost tint).
var chill_timer: float = 0.0
## Facing sign (+1 right / -1 left).
var _facing: float = 1.0
## Reusable query buffer.
var _tmp: Array = []

# --- Templar rush (behavior "templar") ----------------------------------------------

## Rush state: 0 = walking, 1 = windup (lane telegraphed), 2 = rushing.
var rush_state: int = 0
## Seconds spent in the current rush state.
var rush_timer: float = 0.0
## Seconds until the next rush may start.
var rush_cd: float = 0.0
## Unit direction of the current rush.
var rush_dir: Vector2 = Vector2.RIGHT
## Distance (px) still to rush.
var rush_left: float = 0.0
## Rush data (the templar's EnemyData row; empty for other kinds).
var _rush_def: Dictionary = {}
## Instance ids of summons already hit by the current rush.
var _rush_hits: Dictionary = {}
## Whether the player was already hit by the current rush.
var _rush_hit_player: bool = false


## Activates a pooled enemy of `p_kind` using definition `def`.
## `hp_mult` is the director's time-scaling multiplier.
func activate(p_game: Game, p_kind: String, def: Dictionary, pos: Vector2, hp_mult: float, elite: bool, slot: int) -> void:
	game = p_game
	kind = p_kind
	generation += 1
	active = true
	is_elite = elite
	position = pos
	think_slot = slot
	display_name = def["display_name"]
	max_hp = float(def["max_hp"]) * hp_mult
	move_speed = def["move_speed"]
	damage = def["damage"]
	attack_interval = def["attack_interval"]
	attack_range = def["attack_range"]
	radius = def["radius"]
	armor = def["armor"]
	xp_value = def["xp"]
	behavior = def["behavior"]
	projectile_speed = def["projectile_speed"]
	undead_damage_mult = def["undead_damage_mult"]
	heal_amount = def["heal_amount"]
	heal_interval = def["heal_interval"]
	heal_radius = def["heal_radius"]
	target_priority = def["target_priority"]
	slow_resist = float(def.get("slow_resist", 0.0))
	mass = float(def.get("mass", 1.0))
	is_reckoning = false
	is_objective = false
	post_pos = pos
	_rush_def = def if behavior == "templar" else {}
	rush_state = 0
	rush_timer = 0.0
	rush_cd = randf_range(1.0, maxf(1.0, float(def.get("charge_cooldown", 1.0))))
	_rush_hits.clear()
	if elite:
		max_hp *= EnemyData.ELITE_HP_MULT
		radius *= EnemyData.ELITE_RADIUS_MULT
		xp_value *= EnemyData.ELITE_XP_MULT
		heal_amount *= EnemyData.ELITE_HEAL_MULT
		target_priority = minf(1.0, target_priority + 0.2)
	hp = max_hp
	incoming_damage = 0.0
	attack_cd = randf() * attack_interval
	heal_cd = randf() * maxf(heal_interval, 0.1)
	target = game.player
	target_gen = 0
	targeting_player = false
	targeting_summon = false
	heal_target = null
	sep = Vector2.ZERO
	velocity = Vector2.ZERO
	slow_timer = 0.0
	slow_factor = 0.0
	flash = 0.0
	orb_hit_cd = 0.0
	engaged_timer = 0.0
	engaged_mult = 1.0
	knockback = Vector2.ZERO
	mark_time = 0.0
	_shoot_slow_timer = 0.0
	frozen = false
	freeze_timer = 0.0
	chill_timer = 0.0
	visible = true
	queue_redraw()


## Returns the enemy to an inert state (EnemyDirector pools it).
func deactivate() -> void:
	active = false
	visible = false
	incoming_damage = 0.0
	target = null
	heal_target = null


## Sets the Stasis freeze state (redraws only when it changes).
func set_frozen(f: bool) -> void:
	if f != frozen:
		frozen = f
		queue_redraw()


## Tick while frozen by Stasis: only the cosmetic hit flash and the Orb
## Shield re-hit timer run; attacks, heals, rushes, slows and knockback wait.
func step_frozen(delta: float) -> void:
	orb_hit_cd -= delta
	if freeze_timer > 0.0:
		# Frost Wraith Deep Freeze (frozen-enemy-seconds stat for the autotest).
		game.stat_add("frost_frozen_seconds", minf(delta, freeze_timer))
		freeze_timer -= delta
	if flash > 0.0:
		flash -= delta
		if flash <= 0.0:
			queue_redraw()


## Visual hit reaction.
func on_hit() -> void:
	flash = 0.08
	queue_redraw()


## Marks this enemy for `duration` s (Volley of the Fallen mage mark).
func apply_mark(duration: float) -> void:
	if mark_time <= 0.0:
		queue_redraw()
	mark_time = maxf(mark_time, duration)


## Applies a slow of `fraction` (0..1 of speed removed) for `duration` s.
func apply_slow(fraction: float, duration: float) -> void:
	var f := fraction * (1.0 - slow_resist)
	if slow_timer <= 0.0 or f > slow_factor:
		slow_factor = f
	slow_timer = maxf(slow_timer, duration)


## Shows the Frost Wraith chill tint for `duration` s (the slow is apply_slow()).
func apply_chill(duration: float) -> void:
	if chill_timer <= 0.0:
		queue_redraw()
	chill_timer = maxf(chill_timer, duration)


# =====================================================================================
# AI
# =====================================================================================

## ~5 Hz decision step: choose what to attack / whom to heal.
func think() -> void:
	# Engaged by a blocking warrior: keep fighting it (user brief).
	if engaged_timer > 0.0 and target is SummonedUnit and _target_valid():
		targeting_player = false
		targeting_summon = true
		return
	match behavior:
		"purifier":
			_pick_target(EnemyData.PURIFIER_HUNT_RADIUS, true)
		"ranged":
			_pick_target(EnemyData.RANGED_DIVERT_RADIUS, false)
		"healer":
			_pick_heal_target()
			_pick_target(EnemyData.MELEE_DIVERT_RADIUS, false)
		_:
			_pick_target(EnemyData.MELEE_DIVERT_RADIUS, false)
	var d := position.distance_to(target.position)
	targeting_player = target == game.player and d < EnemyData.ATTACKING_PLAYER_RADIUS
	targeting_summon = target is SummonedUnit and d < radius * 2.0 + 40.0


## Targets the player unless a summon within `search` px is closer (or, for
## Purifiers, unless any summon is within `search` px at all).
func _pick_target(search: float, prefer_undead: bool) -> void:
	var player := game.player
	var best: Node2D = player
	var best_d := position.distance_to(player.position)
	game.ally_grid.query(position, search, _tmp)
	var nearest: SummonedUnit = null
	var nearest_d := INF
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD:
			continue
		var d := position.distance_to(u.position)
		if d < nearest_d:
			nearest_d = d
			nearest = u
	if nearest != null and (prefer_undead or nearest_d < best_d):
		best = nearest
	_set_target(best)


## Sets the attack target, remembering summon generation.
func _set_target(n: Node2D) -> void:
	target = n
	target_gen = (n as SummonedUnit).generation if n is SummonedUnit else 0


## True if `target` still refers to the same living summon / the player.
func _target_valid() -> bool:
	if target == null:
		return false
	if target is SummonedUnit:
		var u := target as SummonedUnit
		return u.active and u.generation == target_gen
	return true


## Chaplain: picks the most wounded other enemy in heal radius.
func _pick_heal_target() -> void:
	heal_target = null
	var best_frac := EnemyData.HEAL_MIN_MISSING_FRACTION
	game.enemy_grid.query(position, heal_radius, _tmp)
	for e: Enemy in _tmp:
		if e == self or not e.active:
			continue
		var frac := 1.0 - e.hp / e.max_hp
		if frac >= best_frac:
			best_frac = frac
			heal_target = e
			heal_target_gen = e.generation


## Recomputes the cached separation push from overlapping enemies.
## Called by EnemyDirector at ~10 Hz (staggered) to keep the crowd spread.
func update_separation() -> void:
	game.enemy_grid.query(position, radius * 2.0 + 14.0, _tmp)
	var push := Vector2.ZERO
	for o: Enemy in _tmp:
		if o == self or not o.active:
			continue
		var diff := position - o.position
		var d := diff.length()
		var min_d := radius + o.radius
		if d >= min_d:
			continue
		if d < 0.01:
			diff = _overlap_dir()
			d = 1.0
		push += diff / d * (1.0 - d / min_d)
	sep = push.limit_length(1.0)


## Per-physics-tick update: movement and attacks.
func physics_step(delta: float) -> void:
	_tick_timers(delta)
	if behavior == "templar" and _step_rush(delta):
		return
	if behavior == "consecrator":
		_step_consecrator(delta)
		return
	if not _target_valid():
		_set_target(game.player)
	var t := target
	var to_t := t.position - position
	var d := to_t.length()
	var dir := to_t / d if d > 0.001 else Vector2.ZERO
	var edge := d - radius - _radius_of(t)
	var move := Vector2.ZERO
	if behavior == "ranged" or behavior == "healer":
		# Always advance on the player (even while shooting a summon), stopping
		# only on contact so they don't overlap him.
		var to_p := game.player.position - position
		var dp := to_p.length()
		if dp - radius - game.player.radius > EnemyData.ADVANCE_STOP_GAP and dp > 0.001:
			move = to_p / dp
		if behavior == "ranged":
			if d <= attack_range and attack_cd <= 0.0:
				attack_cd = attack_interval
				_shoot_slow_timer = EnemyData.SHOOT_SLOW_TIME
				game.projectiles.fire_hostile(position, dir, damage * game.enemies.damage_mult, projectile_speed, undead_damage_mult)
		else:
			_try_heal()
	elif edge > attack_range:
		move = dir
	# Anyone in contact can strike except archers (chaplains swing weakly).
	if behavior != "ranged" and edge <= attack_range and attack_cd <= 0.0:
		_melee_hit(t, dir)
	var spd := move_speed * (1.0 - slow_factor if slow_timer > 0.0 else 1.0)
	if engaged_timer > 0.0:
		spd *= engaged_mult
	if _shoot_slow_timer > 0.0:
		spd *= EnemyData.SHOOT_SLOW_MULT
	velocity = move * spd + sep * spd * EnemyData.SEPARATION_STRENGTH
	position += (velocity + knockback) * delta
	_update_facing()


## Desecration-event Chaplain: walk to the grave and hold position there
## while StageDirector runs the channel. Never attacks.
func _step_consecrator(delta: float) -> void:
	var to := post_pos - position
	var d := to.length()
	var move := to / d if d > 2.0 else Vector2.ZERO
	var spd := move_speed * (1.0 - slow_factor if slow_timer > 0.0 else 1.0)
	velocity = move * spd + sep * spd * EnemyData.SEPARATION_STRENGTH * 0.5
	position += (velocity + knockback) * delta
	_update_facing()


## Templar Knight rush. Returns true while a windup / rush owns this tick.
## Walking templars start a rush when the player is within the charge range
## and the lane is long enough (obstacles cut it short).
func _step_rush(delta: float) -> bool:
	match rush_state:
		1:
			rush_timer += delta
			velocity = Vector2.ZERO
			if rush_timer >= float(_rush_def["charge_telegraph"]):
				rush_state = 2
				rush_timer = 0.0
			return true
		2:
			_rush_move(delta)
			return true
	rush_cd -= delta
	if rush_cd > 0.0 or engaged_timer > 0.0:
		return false
	var to_p := game.player.position - position
	var d := to_p.length()
	if d < float(_rush_def["charge_range_min"]) or d > float(_rush_def["charge_range_max"]):
		return false
	rush_dir = to_p / d
	rush_left = game.arena.clear_length(position, rush_dir, float(_rush_def["charge_length"]), radius * 0.8)
	rush_cd = float(_rush_def["charge_cooldown"])
	if rush_left < float(_rush_def["charge_range_min"]):
		return false
	rush_state = 1
	rush_timer = 0.0
	_rush_hits.clear()
	_rush_hit_player = false
	velocity = Vector2.ZERO
	game.effects.telegraph_line(position, position + rush_dir * rush_left, float(_rush_def["charge_width"]), float(_rush_def["charge_telegraph"]), self)
	game.stat_add("templar_charges", 1.0)
	return true


## Moves along the rush lane: hurts the player once, shoves summons aside,
## and stops dead on a warrior heavy enough to body-block it.
func _rush_move(delta: float) -> void:
	var spd := float(_rush_def["charge_speed"])
	var step_len := minf(spd * delta, rush_left)
	position += rush_dir * step_len
	rush_left -= step_len
	velocity = rush_dir * spd
	var hit_r := float(_rush_def["charge_width"]) * 0.5
	var dmg := float(_rush_def["charge_damage"]) * game.enemies.damage_mult
	var player := game.player
	if not _rush_hit_player and player.position.distance_to(position) <= hit_r + player.radius:
		_rush_hit_player = true
		game.combat.damage_player(dmg, "templar_charge")
	game.ally_grid.query(position, hit_r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or _rush_hits.has(u.get_instance_id()):
			continue
		var rel := u.position - position
		if rel.length() > hit_r + u.radius:
			continue
		_rush_hits[u.get_instance_id()] = true
		if u.block_mass >= float(_rush_def["charge_block_mass"]):
			# Body-blocked by a warrior: the rush ends here.
			rush_left = 0.0
			game.effects.slash(position + rush_dir * radius, rush_dir, Palette.COLD_BLUE, radius * 1.6)
			game.stat_add("templar_charges_blocked", 1.0)
			game.combat.damage_unit(u, dmg * undead_damage_mult * 0.5, "templar_charge")
			break
		var side := rel - rush_dir * rel.dot(rush_dir)
		var push := side.normalized() if side.length() > 0.1 else Vector2(-rush_dir.y, rush_dir.x)
		u.position += push * float(_rush_def["charge_knockback"])
		game.combat.damage_unit(u, dmg * undead_damage_mult, "templar_charge")
	if rush_left <= 0.0:
		rush_state = 0
		velocity = Vector2.ZERO


## Warrior blocking (user brief): pushes this enemy out of any overlapping
## blocker using the spatial hash (no physics bodies). The correction is split
## by mass so warriors hold the line while the boss can shove them. Touching
## a blocker "engages" the enemy: it is slowed, retargets that warrior and may
## eat a shield bash. Called by EnemyDirector right after physics_step().
func resolve_blocking() -> void:
	game.ally_grid.query(position, radius + game.horde.block_query_radius, _tmp)
	for u: SummonedUnit in _tmp:
		if not active:
			return
		if not u.active or u.block_radius <= 0.0 or u.state == SummonedUnit.State.SPAWNING:
			continue
		var diff := position - u.position
		var d := diff.length()
		var min_d := radius + u.block_radius
		if d >= min_d:
			continue
		var n := diff / d if d > 0.01 else _overlap_dir()
		var overlap := min_d - d
		var enemy_share := u.block_mass / (u.block_mass + mass)
		position += n * overlap * enemy_share
		u.position -= n * overlap * (1.0 - enemy_share)
		engaged_timer = EnemyData.ENGAGED_TIME
		engaged_mult = u.engaged_speed_mult
		if target != u:
			_set_target(u)
		u.try_bash(self, n)


## Shared countdowns (flash, slow, cooldowns).
func _tick_timers(delta: float) -> void:
	attack_cd -= delta
	heal_cd -= delta
	orb_hit_cd -= delta
	if slow_timer > 0.0:
		slow_timer -= delta
	if engaged_timer > 0.0:
		engaged_timer -= delta
	if _shoot_slow_timer > 0.0:
		_shoot_slow_timer -= delta
	if mark_time > 0.0:
		mark_time -= delta
		if mark_time <= 0.0:
			queue_redraw()
	if chill_timer > 0.0:
		chill_timer -= delta
		if chill_timer <= 0.0:
			queue_redraw()
	if knockback != Vector2.ZERO:
		knockback = knockback.move_toward(Vector2.ZERO, EnemyData.KNOCKBACK_DECAY * delta)
	if flash > 0.0:
		flash -= delta
		if flash <= 0.0:
			queue_redraw()


## Mirrors the sprite to face the movement direction.
func _update_facing() -> void:
	if absf(velocity.x) > 5.0:
		var f := signf(velocity.x)
		if f != _facing:
			_facing = f
			scale.x = _facing
			if hp < max_hp:
				queue_redraw()  # HP bar counter-flip depends on facing


## Stable pseudo-random push direction for an exactly overlapping body.
## Derived from the think slot and pool generation, not the instance id:
## ids depend on thread timing (audio synthesis allocates objects on worker
## threads), which made autotest runs non-deterministic.
func _overlap_dir() -> Vector2:
	return Vector2.from_angle(float((think_slot * 157 + generation * 61) % 628) * 0.01)


## Body radius of the player or a summon.
func _radius_of(n: Node2D) -> float:
	if n is SummonedUnit:
		return (n as SummonedUnit).radius
	return game.player.radius


## Melee strike on the player or a summon (undead bonus applies to summons).
func _melee_hit(t: Node2D, dir: Vector2) -> void:
	attack_cd = attack_interval
	var dmg := damage * game.enemies.damage_mult
	game.effects.slash(position + dir * radius, dir, Palette.SILVER, radius * 1.2)
	if t is SummonedUnit:
		game.combat.damage_unit(t as SummonedUnit, dmg * undead_damage_mult, kind)
	else:
		game.combat.damage_player(dmg, kind)


## Chaplain heal on the chosen wounded ally.
func _try_heal() -> void:
	if heal_cd > 0.0 or heal_target == null:
		return
	if not heal_target.active or heal_target.generation != heal_target_gen:
		heal_target = null
		return
	if heal_target.position.distance_to(position) > heal_radius:
		return
	heal_cd = heal_interval
	if game.combat.heal_enemy(heal_target, heal_amount) > 0.0:
		game.effects.beam(position, heal_target.position, Palette.GOLD)
		game.stat_add("chaplain_heals", 1.0)


func _draw() -> void:
	Glyphs.draw_enemy(self, kind, Vector2.ZERO, radius, flash > 0.0, is_elite)
	if mark_time > 0.0:
		ProgressionGlyphs.draw_mage_mark(self, Vector2(0, -radius * 2.5), 4.0)
	if hp < max_hp:
		# The node is mirrored via scale.x; counter-flip so the bar always
		# fills left-to-right.
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(_facing, 1.0))
		Glyphs.hp_bar(self, Vector2(0, -radius * 1.8), radius * 2.0, hp / max_hp, Palette.HP_ENEMY)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen:
		PowerupGlyphs.draw_frozen(self, Vector2.ZERO, radius)
	elif chill_timer > 0.0:
		SummonGlyphs.draw_chill(self, Vector2.ZERO, radius)
