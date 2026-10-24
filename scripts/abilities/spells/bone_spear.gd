## BoneSpear — the Bone Spear spell (AbilityData "bone_spear"): every
## `cooldown` s it hurls `count` piercing bone spears, fanned by
## AbilityData.SPEAR_SPREAD, the way the necromancer is walking (the last
## direction he walked; you steer it by walking, survivor "knife" style),
## with an aim assist: the volley flies at the nearest enemy inside
## AbilityData.SPEAR_AIM_CONE of that direction, or at the nearest enemy
## when none is ahead (pure movement aim missed almost everything while
## kiting away from the horde).
## A spear flies straight for `range` px and passes through `pierce` extra
## enemies. A volley is only thrown while an enemy is within
## AbilityData.SPEAR_TRIGGER_RANGE, so the cooldown is not wasted on an
## empty field.
## Evolved into Ossuary Lance (EvolutionData "ossuary_lance", detected by the
## "back_count" key): bigger lances also thrown behind him, far more pierce,
## and every hit drives the enemy back along the lance (knockback).
## Spears are pooled Spear records simulated and drawn by this one node.
class_name BoneSpear
extends NecroSpell

## One spear / lance in flight (pooled; reused through `_pool`).
class Spear:
	extends RefCounted
	## World position (px).
	var pos: Vector2 = Vector2.ZERO
	## Velocity (px/s).
	var vel: Vector2 = Vector2.ZERO
	## Distance (px) left before the spear crumbles.
	var dist_left: float = 0.0
	## Damage per enemy hit.
	var damage: float = 0.0
	## Extra enemies it may still pass through (< 0 = spent).
	var pierce_left: int = 0
	## Hit radius (px).
	var radius: float = 5.0
	## Knockback impulse (px/s, divided by enemy mass; 0 = none).
	var knockback: float = 0.0
	## True for an Ossuary Lance (drawing, stats tag).
	var lance: bool = false
	## Enemies already hit (each at most once).
	var hits: Array[Enemy] = []
	## Generation of each entry of `hits` when it was hit (a recycled enemy
	## with a new generation may be hit again).
	var hit_gens: PackedInt32Array = PackedInt32Array()

## Spears in flight.
var _live: Array[Spear] = []
## Idle Spear records ready for reuse.
var _pool: Array[Spear] = []
## Seconds until the next volley.
var _timer: float = 0.4
## Unit direction of the last movement (the throw direction).
var _facing: Vector2 = Vector2.RIGHT
## True if the last redraw showed spears (one more redraw clears them).
var _drawn: bool = false


func _ready() -> void:
	z_index = 2


## Tracks the movement direction, throws volleys and moves the spears.
func step(delta: float, stats: Dictionary) -> void:
	var v := game.player.velocity  # Current movement (px/s).
	if v.length_squared() > 1.0:
		_facing = v.normalized()
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"]) if _throw(stats) else AbilityData.SPELL_RETRY
	var i := 0  # Index into _live (swap-remove).
	while i < _live.size():
		var s := _live[i]
		if _step_spear(s, delta):
			i += 1
		else:
			_live[i] = _live[_live.size() - 1]
			_live.pop_back()
			s.hits.clear()
			_pool.append(s)
	if not _live.is_empty() or _drawn:
		queue_redraw()
	_drawn = not _live.is_empty()


## Throws one volley at the aim-assisted heading (and the Ossuary Lance back
## volley opposite it). Returns false when no enemy is near enough.
func _throw(stats: Dictionary) -> bool:
	var p := game.player.position  # Throw origin.
	game.enemy_grid.query(p, AbilityData.SPEAR_TRIGGER_RANGE, _tmp)
	var near: Enemy = null  # Nearest enemy anywhere.
	var near_d := INF  # Its distance.
	var ahead: Enemy = null  # Nearest enemy inside the aim cone.
	var ahead_d := INF  # Its distance.
	for e: Enemy in _tmp:
		if not e.active:
			continue
		var to := e.position - p  # Offset to the enemy.
		var d := to.length()
		if d < near_d:
			near_d = d
			near = e
		if d < ahead_d and d > 0.01 and absf(_facing.angle_to(to)) <= AbilityData.SPEAR_AIM_CONE:
			ahead_d = d
			ahead = e
	if near == null:
		return false
	var target := ahead if ahead != null else near  # Aim assist (AbilityData.SPEAR_AIM_CONE).
	var aim := (target.position - p).normalized() if near_d > 0.01 else _facing  # Volley heading.
	var lance := stats.has("back_count")  # Evolved into Ossuary Lance.
	_volley(p, aim, int(stats["count"]), stats, lance)
	if lance:
		_volley(p, -aim, int(stats["back_count"]), stats, lance)
	game.stat_add("spear_volleys", 1.0)
	game.player.cast_motion(p + aim)  # Engine motion: the throw (visual only).
	Sfx.play("lance_cast" if lance else "spear_cast", p)
	if lance:
		game.shake(1.0)
	return true


## Spawns `n` spears around direction `dir` from `p`.
func _volley(p: Vector2, dir: Vector2, n: int, stats: Dictionary, lance: bool) -> void:
	var base := dir.angle()  # Centre heading (radians).
	for k in n:
		if _live.size() >= AbilityData.SPEAR_MAX:
			return
		var s: Spear = _pool.pop_back() if not _pool.is_empty() else Spear.new()
		var a := base + (float(k) - float(n - 1) * 0.5) * AbilityData.SPEAR_SPREAD  # This spear's heading.
		var d := Vector2.from_angle(a)  # Unit heading.
		s.pos = p + d * game.player.radius
		s.vel = d * float(stats["speed"])
		s.dist_left = float(stats["range"])
		s.damage = float(stats["damage"])
		s.pierce_left = int(stats["pierce"])
		s.radius = float(stats.get("width", AbilityData.SPEAR_RADIUS))
		s.knockback = float(stats.get("knockback", 0.0))
		s.lance = lance
		s.hits.clear()
		s.hit_gens.clear()
		_live.append(s)


## Moves one spear and resolves its hits. Returns false once it is spent.
func _step_spear(s: Spear, delta: float) -> bool:
	var step_len := s.vel.length() * delta  # px moved this tick.
	s.pos += s.vel * delta
	s.dist_left -= step_len
	if s.dist_left <= 0.0:
		return false
	game.enemy_grid.query(s.pos, s.radius + ProjectileManager.MAX_BODY_RADIUS, _tmp)
	for e: Enemy in _tmp:
		if not e.active or e.position.distance_to(s.pos) > e.radius + s.radius:
			continue
		var idx := s.hits.find(e)  # Earlier hit on this node, if any.
		if idx >= 0 and s.hit_gens[idx] == e.generation:
			continue
		if idx >= 0:
			s.hit_gens[idx] = e.generation
		else:
			s.hits.append(e)
			s.hit_gens.append(e.generation)
		if e.kit != null and e.shield_blocks(s.vel, s.damage):
			return false  # Act III, the Scrap Wastes: an Aegis Bot's frontal shield stops the spear.
		if s.knockback > 0.0:
			e.knockback += s.vel.normalized() * s.knockback / maxf(e.mass, 0.1)
		game.combat.damage_enemy(e, s.damage, "lance" if s.lance else "spear", -1, s.pos - s.vel, true)  # Act IV: a shot from where it flew in (the Phalanx's front).
		s.pierce_left -= 1
		if s.pierce_left < 0:
			return false
	return true


func _draw() -> void:
	for s in _live:
		var d := s.vel.normalized()  # Heading.
		if s.lance:
			SpellGlyphs.draw_lance(self, s.pos, d, s.radius * 2.2, s.radius * 0.45)
		else:
			SpellGlyphs.draw_spear(self, s.pos, d)
