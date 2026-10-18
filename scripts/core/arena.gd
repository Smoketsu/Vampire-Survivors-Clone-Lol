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
## crosses into a new ArenaData.REDRAW_CELL. Each kind comes in 2-3 fixed size
## variants (the stage kind's `sizes`; GDD §15.0 "Art pass (true pixel art)"),
## the collision shape exactly the variant's, and an obstacle is drawn from its
## sprite (EnvironmentArt, obstacles/<kind>_<size>[_v].png) when that PNG
## exists, else from its code glyph at the same size.
## The layout (density, clear radius, seed, obstacle kinds) comes from the
## run's stage (`game.stage_def` "arena", StageRegistry). On the Crimson March
## MarchDirector swaps it at each battle-zone change with set_layout(): the
## cell cache is dropped, so the terrain around the necromancer is rebuilt
## as the next zone (a clear circle around him, the road lane kept free).
## The Sanctum of Judgment uses the same zone swap; its live objectives (ward
## crystals, sacred altars) ask keep_clear(), so no later layout puts an
## obstacle on them, and its Sanctified Halls layout is `aligned` (each
## obstacle at its cell's centre: rows of pillars).
class_name Arena
extends Node2D

## One solid obstacle (immutable after generation).
class Obstacle:
	extends RefCounted
	## Obstacle kind: a key of the layout's `kinds` ("" for the empty-cell sentinel).
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
	## Which fixed size variant of its kind it is (index into the kind's
	## `sizes`, smallest first; GDD §15.0 "Art pass (true pixel art)").
	var size_index: int = 0
	## Sprite key of that kind / size / orientation (EnvironmentArtData key
	## scheme, e.g. "obstacles/gravestone_s"); drawn when its PNG exists.
	var art_key: String = ""

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
## Current obstacle layout (a stage's "arena" dictionary, keys as
## GraveyardStage.ARENA).
var _layout: Dictionary = {}
## Obstacle kinds of `_layout` (kind -> definition).
var _kinds: Dictionary = {}
## No obstacle centre within the layout's clear_radius of this point (the
## run start; the necromancer's position at a zone change).
var _clear_center: Vector2 = Vector2.ZERO
## Half-width (px) of the obstacle-free road along y = 0 (0 = no road).
var _road_half: float = 0.0
## Circles kept free of obstacle centres in every cell generated from now on
## (x, y = centre, z = radius in px): live stage objectives (keep_clear()).
var _keep_clear: Array[Vector3] = []


func _ready() -> void:
	z_index = -6
	_apply_layout(game.stage_def["arena"])
	var march: Dictionary = game.stage_def["march"]  # Crimson March config ({} elsewhere).
	_road_half = float(march.get("road_half_width", 0.0))


## Switches to obstacle layout `layout` (a stage's "arena" dictionary) with
## its clear circle around `clear_center`: every cached cell is regenerated
## and the layer redrawn (Crimson March zone change, MarchDirector). Bodies
## caught inside a new obstacle are pushed out by the next resolve_all().
func set_layout(layout: Dictionary, clear_center: Vector2, clear_radius: float) -> void:
	_apply_layout(layout)
	_layout["clear_radius"] = clear_radius
	_clear_center = clear_center
	_cells.clear()
	_center_cell = Vector2i(1 << 30, 1 << 30)  # Forces a redraw next frame.


## Keeps a circle of radius `r` around `pos` free of obstacle centres in every
## cell generated from now on (cells already generated keep their obstacle;
## the caller places its structure on a free point). Sanctum objectives use
## it so a zone change never rebuilds terrain on top of them.
func keep_clear(pos: Vector2, r: float) -> void:
	_keep_clear.append(Vector3(pos.x, pos.y, r))


## Stores `layout` (a copy, so set_layout() may change its clear radius).
func _apply_layout(layout: Dictionary) -> void:
	_layout = layout.duplicate()
	_kinds = _layout["kinds"]


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
	_rng.seed = hash(Vector3i(key.x, key.y, int(_layout["layout_seed"])))
	if _rng.randf() >= float(_layout["density"]):
		return _empty
	var span := ArenaData.CELL - 2.0 * ArenaData.CELL_MARGIN
	var center := Vector2(float(key.x) * ArenaData.CELL + ArenaData.CELL_MARGIN + _rng.randf() * span,
			float(key.y) * ArenaData.CELL + ArenaData.CELL_MARGIN + _rng.randf() * span)
	if bool(_layout.get("aligned", false)):
		# Aligned layout (Sanctum halls): the obstacle sits at its cell's centre,
		# so neighbouring obstacles form rows. The random draws above still run,
		# keeping the RNG stream per cell the same shape.
		center = Vector2((float(key.x) + 0.5) * ArenaData.CELL, (float(key.y) + 0.5) * ArenaData.CELL)
	# Whole layout px, so a sprite drawn 1 art px = 1 layout px sits exactly on
	# the collision shape (every fixed size is whole, every rect side even).
	center = center.round()
	if (center - _clear_center).length() < float(_layout["clear_radius"]):
		return _empty
	for k in _keep_clear:
		if center.distance_to(Vector2(k.x, k.y)) < k.z:
			return _empty  # A live stage objective stands here.
	if _road_half > 0.0 and absf(center.y) < _road_half + ArenaData.MAX_HALF_EXTENT:
		return _empty  # Crimson March: the road stays open.
	var total := 0.0
	for k: String in _kinds:
		total += float(_kinds[k]["weight"])
	var roll := _rng.randf() * total
	var kind: String = _kinds.keys()[0]  # Fallback: the first kind.
	for k: String in _kinds:
		roll -= float(_kinds[k]["weight"])
		if roll <= 0.0:
			kind = k
			break
	var def: Dictionary = _kinds[kind]
	var o := Obstacle.new()
	o.kind = kind
	o.center = center
	o.variant = _rng.randi()
	# One of the kind's fixed size variants (one RNG draw, as the old random
	# size took; the collision shape is exactly that variant's).
	var sizes: Array = def["sizes"]  # Circle radii or rect long sides (px), smallest first.
	o.size_index = _rng.randi_range(0, sizes.size() - 1)
	var size := float(sizes[o.size_index])  # This variant's radius / long side (px).
	var vertical := false  # A rect laid out along y.
	if String(def["shape"]) == "circle":
		o.is_circle = true
		o.radius = minf(size, ArenaData.MAX_HALF_EXTENT)
	else:
		o.is_circle = false
		var long_half := minf(size * 0.5, ArenaData.MAX_HALF_EXTENT)
		var short_half := float(def["short"]) * 0.5
		vertical = _rng.randf() >= 0.5
		# Optional layout `orient` (the Hollow Archive's Reading Halls: rows of
		# shelves): "h" lays every rect along x, "v" along y. The draw above
		# still runs, keeping each cell's RNG stream the same shape.
		match String(_layout.get("orient", "")):
			"h":
				vertical = false
			"v":
				vertical = true
		o.half = Vector2(short_half, long_half) if vertical else Vector2(long_half, short_half)
	o.art_key = EnvironmentArt.obstacle_key(kind, o.size_index, sizes.size(), vertical)
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
		if not e.active or e.phases_obstacles:
			continue  # (A phasing body, the Ink Wraith, slips through obstacles.)
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
	if EnvironmentArt.draw_obstacle(self, o):
		return  # Its sprite (art pass); otherwise the code glyph below.
	if MarchGlyphs.draw_obstacle(self, o):
		return  # A Crimson March obstacle kind.
	if ArchiveGlyphs.draw_obstacle(self, o):
		return  # A Hollow Archive obstacle kind (Act II).
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
