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
## Act II, Ul-Thalos (the sinking island): when a SinkingDirector is set as
## `shore`, the sea is the edge of the world through ONE rule: resolve_all()
## ends with shore.contain_all() (nobody is ever left in deep water),
## free_point() clamps every placement inside the shore, and no obstacle is
## generated in the sea or on the shoreline being flooded to (obstacle_ok()).
## Without a shore (every other stage) nothing here changes.
## Act III, the Iron Citadel: when a CitadelDirector is set as `citadel`,
## resolve_all() ends with citadel.contain_all() (its Shield Gate walls are
## solid for the necromancer); null on every other stage.
## Act VIII, the Last Line (GDD §15.0 "City blocks"): when the stage's zone
## layout carries a "blocks" dictionary, `city_blocks` (CityBlocks) owns the
## layout and obstacle_at() / _peek() ask it instead of the per-cell scatter: a
## grid of building lots with streets and alleys, and the wrecks Convoy places.
## Everything else here already goes through obstacle_at(), so the push-out and
## slide, free_point(), is_blocked(), clear_length() and avoid_vector() see the
## buildings unchanged; resolve_all() counts the building / wreck push-outs and
## the enemies' contact with the faces, _draw() draws the buildings and wrecks
## in view (CityGlyphs, textures), and free_point_toward() pulls a Bone Ring
## post inside a building back toward the necromancer (StanceFormations, on a
## blocks layout only). Null on every other stage, so nothing changes there.
## Act X, the Black Tide (GDD §15.0 "The Deck"): when Game.deck (DeckBounds) is
## set, the ship's deck is the arena through ONE rule: resolve_all() ends with
## deck.contain_all() (the necromancer and the army stop at the rail, a deck
## enemy knocked past it drowns, swimmers and boats stay in the water, fliers
## keep within their band), and free_point() clamps every placement onto the
## deck. A layout with a "fixed" list (the deck's furniture) generates exactly
## those obstacles (_fixed_obstacle(); at most one per cell, each at least
## ArenaData.CELL_MARGIN from its cell's edges) instead of the hashed scatter.
## Without a deck and a fixed list (every other stage) nothing here changes.
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
# --- Act XII (temporary number): the Temple of the Lioness ---
## Obstacles taken out of the layout (the Temple's Awakening Statues,
## remove_obstacle()): Vector3i(cell x, cell y, layout seed) -> true, so a cell
## looked at again (a redraw, a cache drop) never rebuilds what woke. Empty on
## every other stage, so nothing changes there.
var _removed: Dictionary = {}
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
# --- Act II: Ul-Thalos, the Risen Spire ---
## The sinking island's shore (Ul-Thalos; set by SinkingDirector, null on
## every other stage): the sea is the edge of the world (see the header).
var shore: SinkingDirector = null
# --- Act III: the Iron Citadel ---
## The Iron Citadel's director (set by CitadelDirector, null on every other
## stage): its Shield Gate walls push the necromancer out (see the header).
var citadel: CitadelDirector = null
# --- Act VIII: the Last Line ---
## The city-block layout (CityBlocks; created in _ready() when the stage's zone
## layout has "blocks", null on every other stage): see the header.
var city_blocks: CityBlocks = null


func _ready() -> void:
	z_index = -6
	_apply_layout(game.stage_def["arena"])
	var march: Dictionary = game.stage_def["march"]  # Crimson March config ({} elsewhere).
	_road_half = float(march.get("road_half_width", 0.0))
	# --- Act VIII: the Last Line --- the city blocks (only when the layout has them).
	if _layout.has("blocks"):
		city_blocks = CityBlocks.new(game.stage_def.get("blocks", {}), _layout["blocks"], int(_layout["layout_seed"]),
				_clear_center, float(_layout["clear_radius"]))


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
	if city_blocks != null and layout.has("blocks"):
		city_blocks.set_zone(layout["blocks"], clear_center, clear_radius)  # Act VIII: new looks, the same streets.


## Keeps a circle of radius `r` around `pos` free of obstacle centres in every
## cell generated from now on (cells already generated keep their obstacle;
## the caller places its structure on a free point). Sanctum objectives use
## it so a zone change never rebuilds terrain on top of them.
func keep_clear(pos: Vector2, r: float) -> void:
	_keep_clear.append(Vector3(pos.x, pos.y, r))


## Stores `layout` (a copy, so set_layout() may change its clear radius).
func _apply_layout(layout: Dictionary) -> void:
	_layout = layout.duplicate()
	_kinds = _layout.get("kinds", {})  # (Act VIII: a blocks layout has none.)


func _process(_delta: float) -> void:
	if game == null:
		return
	var c := Vector2i(floori(game.player.position.x / ArenaData.REDRAW_CELL), floori(game.player.position.y / ArenaData.REDRAW_CELL))
	if c != _center_cell:
		_center_cell = c
		queue_redraw()
	if city_blocks != null and city_blocks.dirty:
		city_blocks.dirty = false  # Act VIII: a wreck was placed or burnt away.
		queue_redraw()


# =====================================================================================
# Generation and lookup
# =====================================================================================

## The obstacle of the cell containing `pos`, or null.
func obstacle_at(pos: Vector2) -> Obstacle:
	if city_blocks != null:
		return city_blocks.obstacle_at(pos)  # Act VIII: the building of the lot, or a wreck.
	var key := Vector2i(floori(pos.x * _inv_cell), floori(pos.y * _inv_cell))
	var o: Obstacle = _cells.get(key)
	if o == null:
		o = _generate(key)
		_cells[key] = o
	return null if o == _empty else o


## Builds the (hash-chosen) obstacle of cell `key`, or `_empty`.
func _generate(key: Vector2i) -> Obstacle:
	if not _removed.is_empty() and _removed.has(Vector3i(key.x, key.y, int(_layout.get("layout_seed", 0)))):
		return _empty  # Act XII (temporary): a statue row that woke and walked off.
	if _layout.has("fixed"):
		return _fixed_obstacle(key)  # Act X: the deck's authored furniture.
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
	if shore != null and not shore.obstacle_ok(center):
		return _empty  # Ul-Thalos: nothing stands in the sea or on the shore being flooded to.
	if _layout.has("free_bands") and in_free_band(_layout["free_bands"], center, ArenaData.MAX_HALF_EXTENT):
		return _empty  # Act III, the Assembly Halls: conveyor belts and furnace channels stay open.
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


# --- Act XII (temporary number): the Temple of the Lioness ---
## Takes obstacle `o` out of the layout for good (THE removal path; the
## Temple's Awakening Statues): its cell is empty from now on and stays so
## under this layout (recorded in `_removed`), and the layer is redrawn.
## False when `o` is no longer this cell's obstacle (a zone change rebuilt it).
func remove_obstacle(o: Obstacle) -> bool:
	var key := Vector2i(floori(o.center.x * _inv_cell), floori(o.center.y * _inv_cell))
	if _cells.get(key) != o:
		return false
	_cells[key] = _empty
	_removed[Vector3i(key.x, key.y, int(_layout.get("layout_seed", 0)))] = true
	queue_redraw()
	return true


# --- Act X: the Black Tide ---
## The authored obstacle of cell `key` on a FIXED layout (the layout's "fixed"
## list: each {kind, at (world px), size (index into the kind's sizes)}; a rect
## kind lies along x unless the entry has "vertical": true), or `_empty`. The
## first entry whose centre lies in the cell wins. No RNG: the furniture is
## the same in every run.
func _fixed_obstacle(key: Vector2i) -> Obstacle:
	for f: Dictionary in _layout["fixed"]:
		var at: Vector2 = f["at"]
		if Vector2i(floori(at.x * _inv_cell), floori(at.y * _inv_cell)) != key:
			continue
		var kind := String(f["kind"])
		var def: Dictionary = _kinds[kind]
		var sizes: Array = def["sizes"]  # Circle radii or rect long sides (px), smallest first.
		var o := Obstacle.new()
		o.kind = kind
		o.center = at.round()
		o.variant = absi(hash(Vector3i(key.x, key.y, 1013)))  # Cosmetic only.
		o.size_index = clampi(int(f.get("size", 0)), 0, sizes.size() - 1)
		var size := float(sizes[o.size_index])  # This variant's radius / long side (px).
		var vertical := bool(f.get("vertical", false))  # A rect laid out along y.
		if String(def["shape"]) == "circle":
			o.is_circle = true
			o.radius = minf(size, ArenaData.MAX_HALF_EXTENT)
		else:
			o.is_circle = false
			var long_half := minf(size * 0.5, ArenaData.MAX_HALF_EXTENT)
			var short_half := float(def["short"]) * 0.5
			o.half = Vector2(short_half, long_half) if vertical else Vector2(long_half, short_half)
		o.art_key = EnvironmentArt.obstacle_key(kind, o.size_index, sizes.size(), vertical)
		return o
	return _empty


## Act III, the Assembly Halls (optional layout key "free_bands", GDD §15.0
## "The Assembly Halls (Act III phase 2)"): true when `p` lies within a band's
## half width plus `margin` px of the centre line of one of `bands` (repeating
## world strips: each {"axis": "x" | "y" (the axis the strip runs ALONG),
## "period", "offset", "half"} in px, a strip centred on offset + k * period
## across that axis). The conveyor belts and furnace channels use it, so no
## obstacle is ever generated on them; absent on every other stage.
static func in_free_band(bands: Array, p: Vector2, margin: float) -> bool:
	for b: Dictionary in bands:
		var across := p.y if String(b["axis"]) == "x" else p.x  # Coordinate across the strip (px).
		var period := float(b["period"])  # Strip spacing (px).
		var off := fposmod(across - float(b["offset"]) + period * 0.5, period) - period * 0.5  # Signed distance to the nearest strip centre (px).
		if absf(off) < float(b["half"]) + margin:
			return true
	return false


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
	var p := pos if shore == null else shore.clamp_point(pos, r)  # Ul-Thalos: never in the sea.
	if game.deck != null:
		p = game.deck.clamp_point(p, r)  # Act X: never over the water.
	for _i in 3:
		var o := obstacle_at(p)
		if o == null:
			return p
		var push := separation(o, p, r)
		if push == Vector2.ZERO:
			return p
		p += push * 1.05 + push.normalized() * ArenaData.FREE_POINT_MARGIN
	if game.deck != null:
		return game.deck.clamp_point(p, r)  # Act X: still on the deck.
	return p if shore == null else shore.clamp_point(p, r)


# --- Act VIII: the Last Line ---
## THE RING-POST PATH on a city-block layout (StanceFormations, GDD §15.0
## "City blocks"): a post at `pos` for a body of radius `r` that falls inside
## a building (or a wreck) is pulled back along the line toward `toward` (the
## necromancer) to the first free point, so the Bone Ring flattens along the
## street instead of sending summons round the block. Terrain, not a summon
## rule. Without city blocks it is exactly free_point().
func free_point_toward(pos: Vector2, toward: Vector2, r: float) -> Vector2:
	if city_blocks == null:
		return free_point(pos, r)
	city_blocks.ring_posts += 1
	if not is_blocked(pos, r):
		return pos
	var to := toward - pos
	var length := to.length()
	if length > 0.01:
		var dir := to / length
		var t := ArenaData.RAY_STEP
		while t < length:
			var q := pos + dir * t
			if not is_blocked(q, r):
				city_blocks.ring_pulls += 1
				return q
			t += ArenaData.RAY_STEP
	return free_point(pos, r)


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
	for p in game.all_players:  # The necromancer (co-op: each one).
		var o := obstacle_at(p.position)
		if o != null:
			var push := separation(o, p.position, p.radius)
			if push != Vector2.ZERO:
				p.position += push
				resolved_player += 1
				if city_blocks != null:
					_count_city_push(o, false, delta)  # Act VIII: the "city blocks" line.
	for h in game.all_hordes:  # The army (co-op: each one).
		for u in h.units:
			if not u.active or u.state == SummonedUnit.State.SPAWNING or u.airborne or u.flies:
				continue  # A flying Gargoyle passes over obstacles (it lands on a free point); so does a hovering Grave Drone (Act III).
			var before := u.position
			u.position = _resolve_body(u.position, u.radius, u.velocity, u.get_instance_id(), delta, now)
			if u.position != before:
				resolved_summons += 1
				if city_blocks != null:
					_count_city_push(obstacle_at(before), false, delta)  # Act VIII: the "city blocks" line.
	for e in game.enemies.active:
		if not e.active or e.phases_obstacles:
			continue  # (A phasing body, the Ink Wraith, slips through obstacles.)
		var before := e.position
		e.position = _resolve_body(e.position, e.radius, e.velocity, e.get_instance_id(), delta, now)
		if e.position != before:
			resolved_enemies += 1
			if city_blocks != null:
				_count_city_push(obstacle_at(before), true, delta)  # Act VIII: the "city blocks" line.
	if _frame % 600 == 0:
		_purge_slide(now)
	if shore != null:
		shore.contain_all()  # Ul-Thalos: the sea is the edge of the world.
	if citadel != null:
		citadel.contain_all()  # Act III, the Iron Citadel: the Shield Gate walls.
	if game.deck != null:
		game.deck.contain_all()  # Act X, the Black Tide: the rail is the edge of the world (and drowns).


# --- Act VIII: the Last Line ---
## Counts one push-out out of `o` on the city blocks (a building or a wreck);
## an enemy's push-out out of a building adds `delta` s of face contact.
func _count_city_push(o: Obstacle, enemy: bool, delta: float) -> void:
	if CityBlocks.is_building(o):
		city_blocks.building_pushes += 1
		if enemy:
			city_blocks.enemy_contact_s += delta
	elif o != null:
		city_blocks.wreck_pushes += 1


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
	if city_blocks != null:
		_draw_city(Rect2(center - Vector2.ONE * ext, Vector2.ONE * ext * 2.0))  # Act VIII: buildings and wrecks.
		return
	var c0 := Vector2i(floori((center.x - ext) * _inv_cell), floori((center.y - ext) * _inv_cell))
	var c1 := Vector2i(floori((center.x + ext) * _inv_cell), floori((center.y + ext) * _inv_cell))
	var coop := game != null and game.coop != null  # Co-op: drawing never fills the gameplay cache (see _peek()).
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var at := Vector2((float(cx) + 0.5) * ArenaData.CELL, (float(cy) + 0.5) * ArenaData.CELL)  # Cell centre (px).
			var o := _peek(at) if coop else obstacle_at(at)
			if o != null:
				_draw_obstacle(o)


## Co-op drawing: the obstacle of the cell containing `pos` WITHOUT caching a
## newly generated one. A cell is generated (and cached) the first time
## anything asks for it, and the stage objectives / the sinking shore that clear
## cells change over time, so a cell first drawn on one machine (each draws
## around its own necromancer, at its own frame rate) would be cached earlier
## there than on the partner's machine and could differ: the gameplay cache is
## filled only by the simulation, the same way on both.
func _peek(pos: Vector2) -> Obstacle:
	if city_blocks != null:
		return city_blocks.peek(pos)  # Act VIII: the same rule for the lots.
	var key := Vector2i(floori(pos.x * _inv_cell), floori(pos.y * _inv_cell))
	var o: Obstacle = _cells.get(key)
	if o == null:
		o = _generate(key)  # Reseeds the arena's own per-cell RNG: no other state changes.
	return null if o == _empty else o


# --- Act VIII: the Last Line ---
## Draws the city blocks' buildings and wrecks overlapping `rect` (tiled
## rooftop textures and wreck sprites through CityGlyphs; the code glyph when a
## PNG is missing). Co-op drawing never fills the lot cache (as _peek()).
func _draw_city(rect: Rect2) -> void:
	var coop := game != null and game.coop != null
	var r := city_blocks.lot_range(rect)  # [first lot, last lot].
	for iy in range(r[0].y, r[1].y + 1):
		for ix in range(r[0].x, r[1].x + 1):
			var o := city_blocks.building_of(Vector2i(ix, iy), not coop)
			if o != null:
				CityGlyphs.draw_building(self, o)
	var now := game.elapsed if game != null else 0.0
	for w in city_blocks.wrecks:
		if rect.has_point(w.obstacle.center):
			CityGlyphs.draw_wreck(self, w.obstacle, w.axis, now - w.placed_at)


## Draws one obstacle; the solid outline matches its collision shape.
func _draw_obstacle(o: Obstacle) -> void:
	if game != null and game.shogunate != null:
		ShogunateGlyphs.draw_long_shadow(self, o, game.shogunate.sun)  # Act V: the long dusk shadows (drawing only).
		if ShogunateGlyphs.draw_lantern(self, o, game.shogunate.sun):
			return  # Act V: a stone lantern, lit at night by the Sun's Course.
	if EnvironmentArt.draw_obstacle(self, o):
		return  # Its sprite (art pass); otherwise the code glyph below.
	if MarchGlyphs.draw_obstacle(self, o):
		return  # A Crimson March obstacle kind.
	if HarbourGlyphs.draw_obstacle(self, o):
		return  # A Gullhaven Harbour obstacle kind (Act II).
	if ArchiveGlyphs.draw_obstacle(self, o):
		return  # A Hollow Archive obstacle kind (Act II).
	if SpireTerrainGlyphs.draw_obstacle(self, o):
		return  # An Ul-Thalos obstacle kind (Act II).
	if EmpireGlyphs.draw_obstacle(self, o):
		return  # An Act III stub's placeholder obstacle kind.
	if AssemblyGlyphs.draw_obstacle(self, o):
		return  # An Assembly Halls obstacle kind (Act III).
	if WastesGlyphs.draw_obstacle(self, o):
		return  # A Scrap Wastes obstacle kind (Act III).
	if CitadelGlyphs.draw_obstacle(self, o):
		return  # An Iron Citadel obstacle kind (Act III).
	if IlionGlyphs.draw_obstacle(self, o):
		return  # A Shores of Ilion obstacle kind (Act IV).
	if PantheonGlyphs.draw_obstacle(self, o):
		return  # An Act IV stub's placeholder obstacle kind.
	if OlympusGlyphs.draw_obstacle(self, o):
		return  # A Mount Olympus obstacle kind (Act IV).
	if UnderworldGlyphs.draw_obstacle(self, o):
		return  # An Asphodel Underworld obstacle kind (Act IV).
	if ShogunateGlyphs.draw_obstacle(self, o):
		return  # An Act V stub's placeholder obstacle kind.
	# --- Act V: the Burning Province ---
	if ProvinceGlyphs.draw_obstacle(self, o):
		return  # A Burning Province obstacle kind (Act V).
	# --- Act V: the Road to the Sun ---
	if SunRoadGlyphs.draw_obstacle(self, o):
		return  # A Road to the Sun obstacle kind (Act V).
	# --- Act V: Castle Kurogane ---
	if KuroganeGlyphs.draw_obstacle(self, o):
		return  # A Castle Kurogane obstacle kind (Act V).
	# --- Act VI: the Inferno ---
	if InfernoGlyphs.draw_obstacle(self, o):
		return  # An Act VI stub's placeholder obstacle kind.
	# --- Act VII: the Sanguine Court ---
	if CourtGlyphs.draw_obstacle(self, o):
		return  # An Act VII stub's placeholder obstacle kind.
	# --- Act VI: the Burning Gate ---
	if BurningGateGlyphs.draw_obstacle(self, o):
		return  # A Burning Gate obstacle kind (Act VI).
	# --- Act VI: the Palace of Silk and Ash ---
	if SilkPalaceGlyphs.draw_obstacle(self, o):
		return  # A Palace of Silk and Ash obstacle kind (Act VI).
	# --- Act VI: Pandemonium ---
	if PandemoniumGlyphs.draw_obstacle(self, o):
		return  # A Pandemonium obstacle kind (Act VI).
	# --- Act VII: Ravensmoor ---
	if RavensmoorGlyphs.draw_obstacle(self, o):
		return  # A Ravensmoor obstacle kind (Act VII).
	# --- Act VII: the Witchwood ---
	if WitchwoodGlyphs.draw_obstacle(self, o):
		return  # A Witchwood obstacle kind (Act VII).
	# --- Act VII: Castle Sanguis ---
	if CastleSanguisGlyphs.draw_obstacle(self, o):
		return  # A Castle Sanguis obstacle kind (Act VII).
	# --- Act IX: the Concord of Stars ---
	if ConcordGlyphs.draw_obstacle(self, o):
		return  # An Act IX stub's placeholder obstacle kind.
	# --- Act X: the Black Tide ---
	if CorsairGlyphs.draw_obstacle(self, o):
		return  # An Act X stub's placeholder deck furniture.
	# --- Act XII (temporary number): the Necropolis Dynasty ---
	if DynastyGlyphs.draw_obstacle(self, o):
		return  # A Dynasty stub's placeholder obstacle kind.
	# --- Act XIII (temporary number): the Celestial Host ---
	if HostGlyphs.draw_obstacle(self, o):
		return  # A Host stub's placeholder obstacle kind.
	# --- Act IX: the Proving Moon ---
	if ProvingMoonGlyphs.draw_obstacle(self, o):
		return  # A Proving Moon obstacle kind (Act IX).
	# --- Act IX: the Ark ---
	if ArkGlyphs.draw_obstacle(self, o):
		return  # An Ark of the Concord obstacle kind (Act IX).
	# --- Act XI (temporary): the Hall of the Slain ---
	if NorseGlyphs.draw_obstacle(self, o):
		return  # A Norse stub's placeholder obstacle kind.
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
