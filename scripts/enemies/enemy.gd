## Enemy — one Crimson Covenant soldier, driven by EnemyDirector. A single
## data-driven script covers every regular kind (Recruit, Footman, Zealous
## Archer, Chaplain, Purifier); EnemyData supplies stats and a `behavior` key:
##   melee     close in on the player, divert onto summons in the way.
##   purifier  hunt undead summons first (GDD §35), bonus damage vs undead.
##   ranged    keep preferred range and shoot arrows (player or summons).
##   healer    keep distance and heal the most wounded OTHER enemy (§10).
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
## Distance (px) ranged / healer units try to keep from their target.
var preferred_range: float = 0.0
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
## +1 / -1: which way ranged units strafe while holding range.
var _strafe_sign: float = 1.0
## Facing sign (+1 right / -1 left).
var _facing: float = 1.0
## Reusable query buffer.
var _tmp: Array = []


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
	preferred_range = def["preferred_range"]
	projectile_speed = def["projectile_speed"]
	undead_damage_mult = def["undead_damage_mult"]
	heal_amount = def["heal_amount"]
	heal_interval = def["heal_interval"]
	heal_radius = def["heal_radius"]
	target_priority = def["target_priority"]
	slow_resist = float(def.get("slow_resist", 0.0))
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
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0
	visible = true
	queue_redraw()


## Returns the enemy to an inert state (EnemyDirector pools it).
func deactivate() -> void:
	active = false
	visible = false
	incoming_damage = 0.0
	target = null
	heal_target = null


## Visual hit reaction.
func on_hit() -> void:
	flash = 0.08
	queue_redraw()


## Applies a slow of `fraction` (0..1 of speed removed) for `duration` s.
func apply_slow(fraction: float, duration: float) -> void:
	var f := fraction * (1.0 - slow_resist)
	if slow_timer <= 0.0 or f > slow_factor:
		slow_factor = f
	slow_timer = maxf(slow_timer, duration)


# =====================================================================================
# AI
# =====================================================================================

## ~5 Hz decision step: choose what to attack / whom to heal.
func think() -> void:
	match behavior:
		"purifier":
			_pick_target(EnemyData.PURIFIER_HUNT_RADIUS, true)
		"ranged":
			_pick_target(attack_range * 0.6, false)
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
			diff = Vector2.from_angle(float(get_instance_id() % 628) * 0.01)
			d = 1.0
		push += diff / d * (1.0 - d / min_d)
	sep = push.limit_length(1.0)


## Per-physics-tick update: movement and attacks.
func physics_step(delta: float) -> void:
	_tick_timers(delta)
	if not _target_valid():
		_set_target(game.player)
	var t := target
	var to_t := t.position - position
	var d := to_t.length()
	var dir := to_t / d if d > 0.001 else Vector2.ZERO
	var edge := d - radius - _radius_of(t)
	var move := Vector2.ZERO
	if behavior == "ranged" or behavior == "healer":
		if d > preferred_range + 10.0:
			move = dir
		elif d < preferred_range * 0.7:
			move = -dir
		else:
			move = Vector2(-dir.y, dir.x) * 0.35 * _strafe_sign
		if behavior == "ranged":
			if d <= attack_range and attack_cd <= 0.0:
				attack_cd = attack_interval
				game.projectiles.fire_hostile(position, dir, damage * game.enemies.damage_mult, projectile_speed, undead_damage_mult)
		else:
			_try_heal()
	elif edge > attack_range:
		move = dir
	# Anyone in contact can strike (chaplains only rarely get this close).
	if behavior != "ranged" and edge <= attack_range and attack_cd <= 0.0:
		_melee_hit(t, dir)
	var spd := move_speed * (1.0 - slow_factor if slow_timer > 0.0 else 1.0)
	velocity = move * spd + sep * spd * EnemyData.SEPARATION_STRENGTH
	position += velocity * delta
	_update_facing()


## Shared countdowns (flash, slow, cooldowns).
func _tick_timers(delta: float) -> void:
	attack_cd -= delta
	heal_cd -= delta
	orb_hit_cd -= delta
	if slow_timer > 0.0:
		slow_timer -= delta
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
		game.combat.damage_unit(t as SummonedUnit, dmg * undead_damage_mult)
	else:
		game.combat.damage_player(dmg)


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
	if hp < max_hp:
		Glyphs.hp_bar(self, Vector2(0, -radius * 1.8), radius * 2.0, hp / max_hp, Palette.HP_ENEMY)
