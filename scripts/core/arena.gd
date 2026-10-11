## Arena — the solid obstacles of the Desecrated Graveyard (gravestones, dead
## trees, crypt walls; GDD §11 art) and their collision (GDD §26 collision
## matrix: "Units <-> solid world: YES"; steering "obstacle avoidance").
##
## No physics engine: every obstacle is a plain circle or axis-aligned rect,
## generated lazily per ArenaData.CELL from a stable hash (see ArenaData for
## why one lookup per body is enough). Game calls resolve_all() once per tick,
## after the horde and the enemies have moved, which
##   * pushes the player, every summon and every enemy out of obstacles, and
##   * redirects the blocked part of a unit's velocity along the obstacle's
##     tangent ("slide"), keeping the chosen side for ArenaData.SLIDE_MEMORY s,
##     so units walk around obstacles instead of pinning against them.
## Spawners use free_point() / is_blocked() so nothing is ever placed inside an
## obstacle; Divine Charge lanes are cut short with clear_length().
## Drawing works like Ground: the layer is redrawn only when the player
## crosses into a new ArenaData.REDRAW_CELL.
class_name Arena
extends Node2D

## One solid obstacle (immutable after generation).
class Obstacle:
	extends RefCounted
	## ArenaData.KINDS key ("" for the empty-cell sentinel).
	var kind: String = ""
	## True for a circle, false for an axis-aligned rect.
	var is_circle: bool = true
	## World-space centre.
	var center: Vector2 = Vector2.ZERO
	## Circle radius (px).
	var radius: float = 0.0
	## Rect half-size (px).
	var half: Vector2 = Vector2.ZERO
	## Stable per-obstacle random value (cosmetic variation).
	var variant: int = 0

## Owning run.
var game: Game
## Bodies pushed out of an obstacle this run, by body type (autotest stat).
var resolved_player: int = 0
## Summon/obstacle overlaps resolved this run.
var resolved_summons: int = 0
## Enemy/obstacle overlaps resolved this run.
var resolved_enemies: int = 0
## Vector2i cell -> Obstacle (or `_empty` when the cell has none).
var _cells: Dictionary = {}
## Sentinel stored for generated cells without an obstacle.
var _empty: Obstacle = Obstacle.new()
## Instance id -> Vector2(side sign, expiry game time) of the slide memory.
var _slide: Dictionary = {}
## Redraw cell the canvas is currently centred on.
var _center_cell: Vector2i = Vector2i(1 << 30, 1 << 30)
## Deterministic RNG reseeded per generated cell.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## 1 / ArenaData.CELL, cached.
var _inv_cell: float = 1.0 / ArenaData.CELL
## Physics ticks since the run started (drives slide-memory purges).
var _frame: int = 0


func _ready() -> void:
	z_index = -6


func _process(_delta: float) -> void:
	if game == null:
		return
	var c := Vector2i(floori(game.player.position.x / ArenaData.REDRAW_CELL), floori(game.player.position.y / ArenaData.REDRAW_CELL))
	if c != _center_cell:
		_center_cell = c
		queue_redraw()


# =====================================================================================
# Generation and lookup
# =====================================================================================

## The obstacle of the cell containing `pos`, or null.
func obstacle_at(pos: Vector2) -> Obstacle:
	var key := Vector2i(floori(pos.x * _inv_cell), floori(pos.y * _inv_cell))
	var o: Obstacle = _cells.get(key)
	if o == null:
		o = _generate(key)
		_cells[key] = o
	return null if o == _empty else o


## Builds the (hash-chosen) obstacle of cell `key`, or `_empty`.
func _generate(key: Vector2i) -> Obstacle:
	_rng.seed = hash(Vector3i(key.x, key.y, ArenaData.LAYOUT_SEED))
	if _rng.randf() >= ArenaData.DENSITY:
		return _empty
	var span := ArenaData.CELL - 2.0 * ArenaData.CELL_MARGIN
	var center := Vector2(float(key.x) * ArenaData.CELL + ArenaData.CELL_MARGIN + _rng.randf() * span,
			float(key.y) * ArenaData.CELL + ArenaData.CELL_MARGIN + _rng.randf() * span)
	if center.length() < ArenaData.CLEAR_RADIUS:
		return _empty
	var total := 0.0
	for k: String in ArenaData.KINDS:
		total += float(ArenaData.KINDS[k]["weight"])
	var roll := _rng.randf() * total
	var kind := "gravestone"
	for k: String in ArenaData.KINDS:
		roll -= float(ArenaData.KINDS[k]["weight"])
		if roll <= 0.0:
			kind = k
			break
	var def: Dictionary = ArenaData.KINDS[kind]
	var o := Obstacle.new()
	o.kind = kind
	o.center = center
	o.variant = _rng.randi()
	if String(def["shape"]) == "circle":
		o.is_circle = true
		o.radius = minf(_rng.randf_range(float(def["radius_min"]), float(def["radius_max"])), ArenaData.MAX_HALF_EXTENT)
	else:
		o.is_circle = false
		var long_half := minf(_rng.randf_range(float(def["long_min"]), float(def["long_max"])) * 0.5, ArenaData.MAX_HALF_EXTENT)
		var short_half := float(def["short"]) * 0.5
		o.half = Vector2(long_half, short_half) if _rng.randf() < 0.5 else Vector2(short_half, long_half)
	return o


## Push (direction * depth) that moves a body of radius `r` at `pos` out of
## `o`; Vector2.ZERO when they don't overlap.
static func separation(o: Obstacle, pos: Vector2, r: float) -> Vector2:
	if o.is_circle:
		var diff := pos - o.center
		var d := diff.length()
		var pen := r + o.radius - d
		if pen <= 0.0:
			return Vector2.ZERO
		return (diff / d if d > 0.01 else Vector2.RIGHT) * pen
	var local := pos - o.center
	var clamped := local.clamp(-o.half, o.half)
	var out := local - clamped
	var dist := out.length()
	if dist > 0.001:
		if dist >= r:
			return Vector2.ZERO
		return out / dist * (r - dist)
	# Centre inside the rect: leave through the nearest face.
	var dx := o.half.x - absf(local.x)
	var dy := o.half.y - absf(local.y)
	if dx < dy:
		return Vector2(signf(local.x) if local.x != 0.0 else 1.0, 0.0) * (dx + r)
	return Vector2(0.0, signf(local.y) if local.y != 0.0 else 1.0) * (dy + r)


## True if a body of radius `r` at `pos` would overlap an obstacle.
func is_blocked(pos: Vector2, r: float) -> bool:
	var o := obstacle_at(pos)
	return o != null and separation(o, pos, r) != Vector2.ZERO


## Nearest free position for a body of radius `r` placed at `pos` (spawns,
## recycling, recalls, objective markers, special-move landings). Each push
## gets ArenaData.FREE_POINT_MARGIN on top, so a tiny penetration far from
## the origin cannot round away in 32-bit floats.
func free_point(pos: Vector2, r: float) -> Vector2:
	var p := pos
	for _i in 3:
		var o := obstacle_at(p)
		if o == null:
			return p
		var push := separation(o, p, r)
		if push == Vector2.ZERO:
			return p
		p += push * 1.05 + push.normalized() * ArenaData.FREE_POINT_MARGIN
	return p


## Distance (<= `length`) a body of radius `r` can travel from `from` along
## unit vector `dir` before touching an obstacle (sampled every RAY_STEP px).
func clear_length(from: Vector2, dir: Vector2, length: float, r: float) -> float:
	var t := ArenaData.RAY_STEP
	while t <= length:
		if is_blocked(from + dir * t, r):
			return maxf(0.0, t - ArenaData.RAY_STEP)
		t += ArenaData.RAY_STEP
	return length


## Unit vector pointing away from an obstacle within `look` px of a body of
## radius `r` (zero if none): the autopilot uses it to avoid walls.
func avoid_vector(pos: Vector2, r: float, look: float) -> Vector2:
	var o := obstacle_at(pos)
	if o == null:
		return Vector2.ZERO
	var push := separation(o, pos, r + look)
	if push == Vector2.ZERO:
		return Vector2.ZERO
	return push.normalized() * clampf(push.length() / look, 0.0, 1.0)


# =====================================================================================
# Collision resolution
# =====================================================================================

## Pushes the player, every summon and every enemy out of obstacles. Units
## (not the player) also slide around them. Called by Game once per tick.
func resolve_all(delta: float) -> void:
	_frame += 1
	var now := game.elapsed
	var p := game.player
	var o := obstacle_at(p.position)
	if o != null:
		var push := separation(o, p.position, p.radius)
		if push != Vector2.ZERO:
			p.position += push
			resolved_player += 1
	for u in game.horde.units:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.airborne:
			continue  # A flying Gargoyle passes over obstacles (it lands on a free point).
		var before := u.position
		u.position = _resolve_body(u.position, u.radius, u.velocity, u.get_instance_id(), delta, now)
		if u.position != before:
			resolved_summons += 1
	for e in game.enemies.active:
		if not e.active:
			continue
		var before := e.position
		e.position = _resolve_body(e.position, e.radius, e.velocity, e.get_instance_id(), delta, now)
		if e.position != before:
			resolved_enemies += 1
	if _frame % 600 == 0:
		_purge_slide(now)


## Resolves one body: push-out, then turns the blocked (into-the-obstacle)
## part of `vel` into tangential motion on a remembered side.
func _resolve_body(pos: Vector2, r: float, vel: Vector2, id: int, delta: float, now: float) -> Vector2:
	var o := obstacle_at(pos)
	if o == null:
		return pos
	var push := separation(o, pos, r)
	if push == Vector2.ZERO:
		return pos
	var n := push.normalized()
	var out := pos + push
	var vn := vel.dot(n)
	if vn < 0.0:
		var t := Vector2(-n.y, n.x)
		var side := _slide_side(id, vel.dot(t), vel.length(), (pos - o.center).dot(t), now)
		out += t * side * (-vn) * delta
	return out


## Side (+1 / -1 along the tangent) a unit walks around an obstacle. The
## first contact picks the side its velocity already leans to; a unit heading
## straight in takes the side its position is offset to (`offset`: its
## distance from the obstacle centre along the tangent), i.e. the shorter way
## around. That choice is geometric, so neighbours pick the same side instead
## of sliding into each other (and it no longer depends on instance ids,
## which vary with thread timing). Later contacts keep the side.
func _slide_side(id: int, vt: float, speed: float, offset: float, now: float) -> float:
	var mem: Variant = _slide.get(id)
	var side := 0.0
	if mem != null and (mem as Vector2).y >= now:
		side = (mem as Vector2).x
	elif absf(vt) > speed * 0.1:
		side = signf(vt)
	else:
		side = -1.0 if offset < 0.0 else 1.0
	_slide[id] = Vector2(side, now + ArenaData.SLIDE_MEMORY)
	return side


## Drops expired slide memories.
func _purge_slide(now: float) -> void:
	for id: int in _slide.keys():
		if (_slide[id] as Vector2).y < now:
			_slide.erase(id)


# =====================================================================================
# Drawing
# =====================================================================================

func _draw() -> void:
	var center := Vector2(_center_cell) * ArenaData.REDRAW_CELL + Vector2.ONE * ArenaData.REDRAW_CELL * 0.5
	var ext := ArenaData.DRAW_HALF_EXTENT
	var c0 := Vector2i(floori((center.x - ext) * _inv_cell), floori((center.y - ext) * _inv_cell))
	var c1 := Vector2i(floori((center.x + ext) * _inv_cell), floori((center.y + ext) * _inv_cell))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var o := obstacle_at(Vector2((float(cx) + 0.5) * ArenaData.CELL, (float(cy) + 0.5) * ArenaData.CELL))
			if o != null:
				_draw_obstacle(o)


## Draws one obstacle; the solid outline matches its collision shape.
func _draw_obstacle(o: Obstacle) -> void:
	var c := o.center
	var dark := Color(0.06, 0.06, 0.07)
	match o.kind:
		"gravestone":
			var r := o.radius
			draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			draw_circle(c, r, dark)
			draw_circle(c, r - 1.5, Palette.STONE)
			draw_circle(c + Vector2(-r * 0.25, -r * 0.25), r * 0.45, Color(0.36, 0.38, 0.40))
			# Engraved cross (or a crack on every other stone).
			if o.variant % 2 == 0:
				draw_line(c + Vector2(0, -r * 0.55), c + Vector2(0, r * 0.55), dark, 2.0)
				draw_line(c + Vector2(-r * 0.35, -r * 0.2), c + Vector2(r * 0.35, -r * 0.2), dark, 2.0)
			else:
				draw_polyline(PackedVector2Array([c + Vector2(-r * 0.6, -r * 0.3), c + Vector2(-r * 0.1, 0), c + Vector2(r * 0.1, -r * 0.2), c + Vector2(r * 0.6, r * 0.3)]), dark, 1.5)
		"dead_tree":
			var r := o.radius
			var trunk := Color(0.20, 0.15, 0.12)
			draw_circle(c + Vector2(4, 5), r * 1.1, Color(0, 0, 0, 0.35))
			# Bare branches reaching past the trunk (cosmetic).
			for i in 5:
				var a := float(o.variant % 628) * 0.01 + TAU * float(i) / 5.0
				var tip := c + Vector2.from_angle(a) * r * 2.3
				draw_line(c, tip, trunk, 3.0)
				draw_line(tip, tip + Vector2.from_angle(a + 0.6) * r * 0.7, trunk, 2.0)
			draw_circle(c, r, dark)
			draw_circle(c, r - 2.0, trunk)
			draw_arc(c, r * 0.5, 0.0, TAU, 16, Color(0.28, 0.22, 0.17), 1.5)
		_:
			# Crypt wall: dark stone block with brick courses and a moonlit edge.
			var rect := Rect2(c - o.half, o.half * 2.0)
			draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			draw_rect(rect, dark)
			draw_rect(rect.grow(-1.5), Color(0.23, 0.24, 0.27))
			var horizontal := o.half.x > o.half.y
			var long_len := (o.half.x if horizontal else o.half.y) * 2.0
			var k := 14.0
			while k < long_len - 4.0:
				if horizontal:
					draw_line(Vector2(rect.position.x + k, rect.position.y + 2), Vector2(rect.position.x + k, rect.end.y - 2), dark, 1.0)
				else:
					draw_line(Vector2(rect.position.x + 2, rect.position.y + k), Vector2(rect.end.x - 2, rect.position.y + k), dark, 1.0)
				k += 14.0
			if horizontal:
				draw_line(rect.position + Vector2(2, 2), Vector2(rect.end.x - 2, rect.position.y + 2), Color(0.42, 0.46, 0.5), 1.5)
			else:
				draw_line(rect.position + Vector2(2, 2), Vector2(rect.position.x + 2, rect.end.y - 2), Color(0.42, 0.46, 0.5), 1.5)
			draw_circle(c, 3.0, Color(0.35, 0.75, 0.70, 0.5))
