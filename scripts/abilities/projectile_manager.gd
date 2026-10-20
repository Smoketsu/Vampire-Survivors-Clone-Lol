## ProjectileManager — fires, moves, collides and pools every projectile
## (GDD §22 ProjectileManager, §38 "limit simultaneous projectiles").
## Also owns the overkill reservation bookkeeping (GDD §27/§32): a friendly
## projectile adds its damage to the target's `incoming_damage` when fired and
## removes it when it hits that target, explodes or expires, so other ranged
## units can see the target is already "spoken for".
## Evolution / synergy hooks: Void Barrage bolts split into shards on their
## first hit (GDD §6.1); with Volley of the Fallen active, mage explosions mark
## enemies and skeletal arrows (Gravebow arrows too) deal bonus damage to
## marked ones (GDD §6.3); Gravebow arrows curse what they hit
## (CombatResolver.curse_enemy) and its split arrows fly straight
## (fire_friendly_dir()).
class_name ProjectileManager
extends Node2D

## Hard cap on live projectiles; new ones are dropped beyond it.
const MAX_PROJECTILES: int = 400  # TUNING (not in GDD)
## Lifetime in seconds of contact projectiles (range = speed * life).
const DEFAULT_LIFE: float = 1.4  # TUNING (not in GDD)
## Homing turn rate (rad/s) for skeletal arrows / priest bolts.
const ARROW_HOMING: float = 3.0  # TUNING (not in GDD)
## Largest enemy radius considered in contact queries (boss is 22 px).
const MAX_BODY_RADIUS: float = 30.0
## Total fan angle (radians) of Void Barrage shards around the bolt heading.
const SHARD_FAN: float = 1.4  # TUNING (not in GDD)

## Owning run.
var game: Game
## Projectiles in flight.
var active: Array[Projectile] = []
## Idle projectiles ready for reuse.
var _pool: Array[Projectile] = []
## Total Projectile nodes ever instantiated (debug: pool health).
var created: int = 0
## Reusable query buffer.
var _tmp: Array = []


# =====================================================================================
# Firing
# =====================================================================================

## Fires a friendly contact projectile at `target` and reserves its damage.
## Returns the projectile (null when the projectile cap was hit) so callers
## can set extra fields such as the Void Barrage split.
func fire_friendly(kind: Projectile.Kind, pos: Vector2, target: Enemy, damage: float, speed: float, pierce: int, source: String) -> Projectile:
	var p := _acquire()
	if p == null:
		return null
	p.kind = kind
	p.hostile = false
	p.is_aoe = false
	p.position = pos
	p.speed = speed
	p.velocity = (target.position - pos).normalized() * speed
	p.damage = damage
	p.pierce_left = pierce
	p.life = DEFAULT_LIFE
	var spell := kind == Projectile.Kind.SHADOW_BOLT or kind == Projectile.Kind.VOID_BOLT
	p.radius = 5.0 if spell else 3.0
	p.homing = AbilityData.BOLT_HOMING if spell else ARROW_HOMING
	p.target = target
	p.target_gen = target.generation
	p.source = source
	_reserve(p, target, damage)
	_launch(p)
	return p


## Fires a friendly contact projectile straight along unit direction `dir`
## (no homing, no target, no damage reservation): the Gravebow's split
## arrows. Returns the projectile (null when the projectile cap was hit).
func fire_friendly_dir(kind: Projectile.Kind, pos: Vector2, dir: Vector2, damage: float, speed: float, pierce: int, source: String) -> Projectile:
	var p := _acquire()
	if p == null:
		return null
	p.kind = kind
	p.hostile = false
	p.is_aoe = false
	p.position = pos
	p.speed = speed
	p.velocity = dir * speed
	p.damage = damage
	p.pierce_left = pierce
	p.life = DEFAULT_LIFE
	p.radius = 3.0
	p.homing = 0.0
	p.target = null
	p.source = source
	_launch(p)
	return p


## Void Barrage: releases `p.split_count` shards fanned around `p`'s heading
## from the enemy `hit` (which the shards ignore). Shards do not home, pierce,
## split again or reserve damage.
func _split(p: Projectile, hit: Enemy) -> void:
	var n := p.split_count
	p.split_count = 0
	var heading := p.velocity.angle()
	for i in n:
		var s := _acquire()
		if s == null:
			return
		var t := 0.5 if n <= 1 else float(i) / float(n - 1)
		var dir := Vector2.from_angle(heading + (t - 0.5) * SHARD_FAN)
		s.kind = Projectile.Kind.VOID_SHARD
		s.hostile = false
		s.is_aoe = false
		s.position = hit.position
		s.speed = p.split_speed
		s.velocity = dir * p.split_speed
		s.damage = p.split_damage
		s.pierce_left = 0
		s.life = p.split_life
		s.radius = 3.0
		s.homing = 0.0
		s.target = null
		s.source = "void_shard"
		s.split_count = 0
		s.hit_ids.append(hit.get_instance_id())
		_launch(s)
	game.stat_add("void_shards", float(n))


## Fires a mage orb that explodes at `dest` with `splash` radius. Damage is
## reserved on `reserve_target` (the cluster's centre enemy) if given.
## `source` tags the damage ("mage", or "lich" for the evolved Lich, whose
## kills can rise as skeletons, SummonEvolutions.on_enemy_killed()).
func fire_aoe(pos: Vector2, dest: Vector2, damage: float, speed: float, splash: float, reserve_target: Enemy, source: String = "mage") -> void:
	var p := _acquire()
	if p == null:
		return
	p.kind = Projectile.Kind.MAGE_ORB
	p.hostile = false
	p.is_aoe = true
	p.position = pos
	p.dest = dest
	p.speed = speed
	p.velocity = (dest - pos).normalized() * speed
	p.damage = damage
	p.splash = splash
	p.pierce_left = 0
	p.life = pos.distance_to(dest) / maxf(speed, 1.0) + 0.5
	p.radius = 5.0
	p.homing = 0.0
	p.target = null
	p.source = source
	if reserve_target != null:
		_reserve(p, reserve_target, damage)
	_launch(p)


## Fires a Covenant arrow in direction `dir`. `kind` / `source` default to
## an archer arrow; Holy Retribution (a run modifier) fires RADIANT_BOLTs
## tagged "holy_retribution" (the player_dmg_from_* / summon_dmg_from_* stat).
func fire_hostile(pos: Vector2, dir: Vector2, damage: float, speed: float, undead_mult: float,
		kind: Projectile.Kind = Projectile.Kind.ENEMY_ARROW, source: String = "archer_arrow") -> void:
	var p := _acquire()
	if p == null:
		return
	p.kind = kind
	p.source = source
	p.hostile = true
	p.is_aoe = false
	p.position = pos
	p.speed = speed
	p.velocity = dir * speed
	p.damage = damage
	p.undead_mult = undead_mult
	p.pierce_left = 0
	p.life = 2.0
	p.radius = 3.0
	p.homing = 0.0
	p.target = null
	_launch(p)


## Takes a projectile from the pool (null if at the cap) and resets it.
func _acquire() -> Projectile:
	if active.size() >= MAX_PROJECTILES:
		return null
	var p: Projectile
	if _pool.is_empty():
		p = Projectile.new()
		add_child(p)
		created += 1
	else:
		p = _pool.pop_back()
	p.hit_ids.clear()
	p.split_count = 0
	p.chill_slow = 0.0
	p.curse_amp = 0.0
	p.curse_time = 0.0
	p.slow_frac = 0.0  # Act III: the Iron Revenant's slowing shells.
	p.reserved = 0.0
	p.reserve_target = null
	p.undead_mult = 1.0
	return p


## Activates a configured projectile.
func _launch(p: Projectile) -> void:
	p.active = true
	p.visible = true
	p.rotation = p.velocity.angle()
	p.queue_redraw()
	active.append(p)


## Adds `amount` of pending damage to enemy `e` on behalf of `p`.
func _reserve(p: Projectile, e: Enemy, amount: float) -> void:
	e.incoming_damage += amount
	p.reserved = amount
	p.reserve_target = e
	p.reserve_gen = e.generation


## Removes `p`'s reservation from its target (if that enemy is unchanged).
func _release(p: Projectile) -> void:
	var e := p.reserve_target
	if e != null and e.active and e.generation == p.reserve_gen:
		e.incoming_damage = maxf(0.0, e.incoming_damage - p.reserved)
	p.reserve_target = null
	p.reserved = 0.0


# =====================================================================================
# Update
# =====================================================================================

## Moves every projectile, resolves hits and recycles finished ones.
func step(delta: float) -> void:
	var i := 0
	while i < active.size():
		var p := active[i]
		if _step_one(p, delta):
			i += 1
		else:
			_release(p)
			p.active = false
			p.visible = false
			p.target = null
			active[i] = active[active.size() - 1]
			active.pop_back()
			_pool.append(p)


## Advances one projectile. Returns false when it should be removed.
func _step_one(p: Projectile, delta: float) -> bool:
	p.life -= delta
	if p.life <= 0.0:
		return false
	if p.homing > 0.0 and p.target != null and p.target.active and p.target.generation == p.target_gen:
		var cur := p.velocity.angle()
		var want := (p.target.position - p.position).angle()
		var diff := wrapf(want - cur, -PI, PI)
		cur += clampf(diff, -p.homing * delta, p.homing * delta)
		p.velocity = Vector2.from_angle(cur) * p.speed
		p.rotation = cur
	p.position += p.velocity * delta
	if p.is_aoe:
		if p.position.distance_to(p.dest) <= p.speed * delta + 2.0:
			_explode(p)
			return false
		return true
	if p.hostile:
		return _hostile_hits(p)
	return _friendly_hits(p)


## Friendly contact hits; supports pierce. Returns false when spent.
func _friendly_hits(p: Projectile) -> bool:
	game.enemy_grid.query(p.position, p.radius + MAX_BODY_RADIUS, _tmp)
	for e: Enemy in _tmp:
		if not e.active:
			continue
		var id := e.get_instance_id()
		if p.hit_ids.has(id):
			continue
		if e.position.distance_to(p.position) > e.radius + p.radius:
			continue
		if e == p.reserve_target:
			_release(p)
		p.hit_ids.append(id)
		var dmg := p.damage
		if (p.source == "archer" or p.source == "gravebow") and e.mark_time > 0.0:
			# Volley of the Fallen: archers punish mage-marked enemies.
			var bonus := game.horde.synergies.value("volley", "archer_bonus")
			if bonus > 0.0:
				dmg *= 1.0 + bonus
				game.stat_add("volley_marked_hits", 1.0)
		game.combat.damage_enemy(e, dmg, p.source)
		if p.kind == Projectile.Kind.SHADOW_BOLT or p.kind == Projectile.Kind.VOID_BOLT or p.kind == Projectile.Kind.VOID_SHARD:
			# The player's spell bolts splash where they hit (art-only, visual).
			game.effects.burst(p.position, AnimData.BOLT_IMPACT_RADIUS, "bolt_impact")
		if p.chill_slow > 0.0:
			game.combat.chill_enemy(e, p.chill_slow, p.chill_time)  # Frost Wraith bolt.
		if p.slow_frac > 0.0:
			game.combat.slow_enemy(e, p.slow_frac, p.slow_time)  # Act III: an Iron Revenant shell (suppressive fire).
		if p.curse_time > 0.0:
			game.combat.curse_enemy(e, p.curse_amp, p.curse_time)  # Gravebow arrow.
			if p.hit_ids.size() > 1:
				game.stat_add("gravebow_pierce_hits", 1.0)  # A hit after piercing an enemy.
		if p.split_count > 0:
			_split(p, e)
		if p.pierce_left <= 0:
			return false
		p.pierce_left -= 1
	return true


## Covenant projectile hits: Orb Shield interception first (the Umbral
## Warden's Eclipsed Guard innate before the charge-limited intercept: any
## orb destroys what it touches), then the necromancer, then any summon.
## Returns false when spent.
func _hostile_hits(p: Projectile) -> bool:
	if game.innates.eclipsed_guard(p.position, p.radius):
		game.effects.pop(p.position, Palette.VIOLET, 6.0)
		return false
	if game.abilities.try_intercept(p.position, p.radius):
		game.effects.pop(p.position, Palette.VIOLET, 6.0)
		game.stat_add("orb_intercepts", 1.0)
		return false
	var pl := game.player
	if pl.position.distance_to(p.position) <= pl.radius + p.radius:
		game.combat.damage_player(p.damage, p.source)
		return false
	game.ally_grid.query(p.position, p.radius + 14.0, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.position.distance_to(p.position) <= u.radius + p.radius:
			game.combat.damage_unit(u, p.damage * p.undead_mult, p.source)
			return false
	return true


## Mage orb explosion at its destination.
func _explode(p: Projectile) -> void:
	_release(p)
	game.effects.ring(p.dest, p.splash, Palette.VIOLET, 0.3)
	game.enemy_grid.query(p.dest, p.splash + MAX_BODY_RADIUS, _tmp)
	var mark := game.horde.synergies.value("volley", "mark_duration")
	for e: Enemy in _tmp:
		if e.active and e.position.distance_to(p.dest) <= p.splash + e.radius * 0.5:
			if mark > 0.0:
				e.apply_mark(mark)
			game.combat.damage_enemy(e, p.damage, p.source)
	game.stat_add("mage_explosions", 1.0)
	if p.source == "mage" or p.source == "lich":
		game.volleys.on_mage_burst(p.dest, p.damage, p.source)  # Bullet heaven: forking sparks / the Lich's spiral.
