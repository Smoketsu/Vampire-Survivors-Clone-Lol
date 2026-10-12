## PlagueCloud — the Plague Cloud spell (AbilityData "plague_cloud"): every
## `cooldown` s a plague cloud settles on the most packed group of enemies
## within `range` px of the necromancer (spots already under a cloud are
## avoided). A cloud lingers `duration` s; every AbilityData.PLAGUE_TICK s it
## deals `damage` to each enemy inside and inflicts Rot: for
## AbilityData.ROT_LINGER s the enemy takes `rot` more damage from EVERY
## source (CombatResolver.damage_enemy; bosses get ROT_BOSS_MULT of it), so
## the cloud also weakens enemies for the horde and the other spells.
## Evolved into Pestilence (EvolutionData "pestilence", detected by the
## "creep" key): bigger, longer black clouds with stronger Rot that creep
## after the nearest enemy, and each ends in a Death Nova (GDD §5.3 "wave
## dealing bonus damage to cursed enemies"): `nova` x the tick damage
## within NOVA_RADIUS_MULT x the radius, +`nova_rot_bonus` against rotting
## enemies.
## Clouds are pooled Cloud records simulated and drawn by this one node.
class_name PlagueCloud
extends NecroSpell

## One plague cloud (pooled through `_pool`).
class Cloud:
	extends RefCounted
	## Centre (world px).
	var pos: Vector2 = Vector2.ZERO
	## Radius (px).
	var radius: float = 0.0
	## Seconds left.
	var time_left: float = 0.0
	## Total lifetime (s), for the fade drawing.
	var duration: float = 1.0
	## Seconds until the next damage tick.
	var tick: float = 0.0
	## Damage per tick to each enemy inside.
	var damage: float = 0.0
	## Rot bonus inflicted (fraction).
	var rot: float = 0.0
	## Pestilence creep speed (px/s; 0 = static).
	var creep: float = 0.0
	## Pestilence Death Nova damage (0 = no nova).
	var nova: float = 0.0
	## Pestilence extra nova fraction against rotting enemies.
	var nova_rot_bonus: float = 0.0
	## True for a Pestilence cloud (drawing).
	var black: bool = false

## Live clouds.
var _clouds: Array[Cloud] = []
## Idle Cloud records ready for reuse.
var _pool: Array[Cloud] = []
## Seconds until the next cloud.
var _timer: float = 0.6
## Own query buffer for cloud ticks and the nova (kill hooks may query too).
var _hit: Array = []


func _ready() -> void:
	z_index = -3


## Places clouds on cooldown and ticks / moves / expires the live ones.
func step(delta: float, stats: Dictionary) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var i := 0  # Index into _clouds.
	while i < _clouds.size():
		var c := _clouds[i]
		if _step_cloud(c, delta):
			i += 1
		else:
			_clouds.remove_at(i)
			_pool.append(c)
	queue_redraw()


## Drops one cloud on the densest open spot. Returns false when no enemy is
## within range.
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position  # Necromancer.
	var r := float(stats["radius"])  # Cloud radius.
	game.enemy_grid.query(p, float(stats["range"]), _hit)
	var best := Vector2.INF  # Chosen centre.
	var best_score := -1.0  # Its score (enemies inside, minus overlap penalty).
	var checked := 0  # Candidates evaluated (bounded for cost).
	for e: Enemy in _hit:
		if not is_open_target(e) or e.position.distance_to(p) > float(stats["range"]):
			continue
		var score := float(count_enemies(e.position, r))  # Enemies a cloud here covers.
		if _covered(e.position, r):
			score *= 0.25  # Already under a cloud: strongly prefer fresh ground.
		if score > best_score:
			best_score = score
			best = e.position
		checked += 1
		if checked >= 16:
			break
	if best == Vector2.INF:
		return false
	var c: Cloud = null  # Record to fill.
	if _clouds.size() >= AbilityData.CLOUD_MAX:
		c = _clouds.pop_front()
	elif not _pool.is_empty():
		c = _pool.pop_back()
	else:
		c = Cloud.new()
	c.pos = best
	c.radius = r
	c.duration = float(stats["duration"])
	c.time_left = c.duration
	c.tick = 0.0
	c.damage = float(stats["damage"])
	c.rot = float(stats["rot"])
	c.creep = float(stats.get("creep", 0.0))
	c.nova = float(stats["damage"]) * float(stats.get("nova", 0.0))
	c.nova_rot_bonus = float(stats.get("nova_rot_bonus", 0.0))
	c.black = stats.has("creep")
	_clouds.append(c)
	game.stat_add("plague_clouds", 1.0)
	Sfx.play("plague_cast", best)
	return true


## True if `pos` is closer to an existing cloud's centre than 40% of the two
## radii combined (0.8 x `r` for clouds of equal size).
func _covered(pos: Vector2, r: float) -> bool:
	for c in _clouds:
		if c.pos.distance_to(pos) < (c.radius + r) * 0.4:
			return true
	return false


## Ticks one cloud. Returns false once it has expired (after its nova).
func _step_cloud(c: Cloud, delta: float) -> bool:
	c.time_left -= delta
	if c.creep > 0.0:
		_creep(c, delta)
	c.tick -= delta
	if c.tick <= 0.0:
		c.tick += AbilityData.PLAGUE_TICK
		_tick(c)
	if c.time_left > 0.0:
		return true
	if c.nova > 0.0:
		_nova(c)
	return false


## Pestilence: drifts the cloud toward the nearest enemy within 2 radii.
func _creep(c: Cloud, delta: float) -> void:
	game.enemy_grid.query(c.pos, c.radius * 2.0, _hit)
	var best: Enemy = null  # Nearest enemy.
	var best_d := INF  # Its distance.
	for e: Enemy in _hit:
		if not e.active:
			continue
		var d := c.pos.distance_to(e.position)
		if d < best_d:
			best_d = d
			best = e
	if best != null and best_d > 4.0:
		c.pos = c.pos.move_toward(best.position, c.creep * delta)


## One damage tick: damages and rots every enemy inside the cloud.
func _tick(c: Cloud) -> void:
	game.enemy_grid.query(c.pos, c.radius + ProjectileManager.MAX_BODY_RADIUS, _hit)
	var until := game.elapsed + AbilityData.ROT_LINGER  # Rot expiry.
	var src := "pestilence" if c.black else "plague"  # Stats tag.
	var victims: Array = []  # Own copy: damage may trigger kill hooks.
	for e: Enemy in _hit:
		if e.active and e.position.distance_to(c.pos) <= c.radius + e.radius * 0.5:
			victims.append(e)
	for e: Enemy in victims:
		if not e.active:
			continue
		apply_rot(e, c.rot, until)
		game.combat.damage_enemy(e, c.damage, src)


## Inflicts Rot on `e`: it takes `amount` more damage from every source until
## game time `until` (the stronger Rot wins; bosses get ROT_BOSS_MULT), through
## the one Rot path, CombatResolver.rot_enemy().
func apply_rot(e: Enemy, amount: float, until: float) -> void:
	game.combat.rot_enemy(e, amount, until)


## Pestilence Death Nova when a cloud expires.
func _nova(c: Cloud) -> void:
	var r := c.radius * AbilityData.NOVA_RADIUS_MULT  # Nova radius.
	game.enemy_grid.query(c.pos, r + ProjectileManager.MAX_BODY_RADIUS, _hit)
	var victims: Array = []  # Own copy: damage may trigger kill hooks.
	for e: Enemy in _hit:
		if e.active and e.position.distance_to(c.pos) <= r + e.radius:
			victims.append(e)
	for e: Enemy in victims:
		if not e.active:
			continue
		var rotting := e.rot_until > game.elapsed  # Cursed by the plague.
		game.combat.damage_enemy(e, c.nova * (1.0 + (c.nova_rot_bonus if rotting else 0.0)), "death_nova")
	game.effects.ring(c.pos, r, Palette.NECRO_GREEN, 0.45)
	game.effects.ring(c.pos, r * 0.6, Palette.VIOLET, 0.55)
	game.stat_add("death_novas", 1.0)
	Sfx.play("death_nova", c.pos)


func _draw() -> void:
	var now := game.elapsed  # Animation clock.
	for c in _clouds:
		var life := c.time_left / maxf(c.duration, 0.01)  # 1 -> 0 over the cloud's life.
		if c.black:
			SpellGlyphs.draw_pestilence(self, c.pos, c.radius, life, now)
		else:
			SpellGlyphs.draw_plague(self, c.pos, c.radius, life, now)
