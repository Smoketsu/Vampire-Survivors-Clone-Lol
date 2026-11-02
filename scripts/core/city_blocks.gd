## CityBlocks — THE CITY-BLOCK LAYOUT of the Last Line's stages (Act VIII;
## GDD §15.0 "City blocks"; owner: "a series of blocks and rectangular streets
## with alleys rather than our normal"), owned by Arena as `city_blocks`. ONE
## path: when the stage's zone layout (its "arena" dictionary) carries a
## "blocks" dictionary, Arena.obstacle_at() asks obstacle_at() here instead of
## the per-cell scatter, so everything that already goes through Arena
## (resolve_all()'s push-out and slide, free_point(), is_blocked(),
## clear_length(), avoid_vector(), spawns, recalls, landings) sees the
## buildings and the wrecks. No physics engine; no stage without "blocks"
## changes (Arena never creates this object there).
##
## The grid, the lots, the wreck cells and the one-lookup invariant are
## documented in CityBlockData. In short: lot (ix, iy) = floor(pos / pitch)
## holds at most one building (an axis-aligned rect); its street sides alternate
## with its alley sides; streets cross at multiples of 2 x pitch, so (0, 0), the
## run's start, is a crossing of two streets.
##   * obstacle_at(pos) — the building of the lot `pos` is in, or a wreck of
##     the street strip(s) `pos` is in, whichever the body overlaps more (the
##     nearer shape; a body touches at most those). Lots are cached like
##     Arena's cells; co-op drawing uses peek() (no caching), as Arena does.
##   * open lots — a seeded share (open_share, rolled per lot from the layout
##     seed) has no building: plazas, parking lots, parks (CityGround draws
##     them). The lot `start_open` beside the start crossing is always open,
##     and no building stands within the clear circle (the run's start, or the
##     necromancer at a zone change).
##   * zones keep the grid and change only the looks and the open-lot share
##     (set_zone()); a body caught in a new building is pushed out by the next
##     Arena.resolve_all(), as on every stage.
##   * lane(pos, dir) — the street centre line through `pos` along `dir`
##     (vehicles, artillery lines, the civilians' flight, phase 2's Hearse Run).
##   * add_wreck(pos, half_along) — a burning wreck (Convoy): snapped to the
##     centre of its wreck cell in a street, at most one per cell, never at a
##     crossing, at most WRECK_MAX standing (the oldest burns away). Seeded only
##     by game events, so the layout stays deterministic.
##   * street_dir(pos, target, r) — THE street-steering hint, read by the
##     enemy advance step (Enemy.physics_step(), blocks layouts only): straight
##     while the line ahead is clear, else along the street to the crossing
##     onto the target's street, up an alley, or round a wreck. Added after measuring: advancing straight and
##     sliding (the slide memory) left ~830 enemy-seconds a minute against the
##     building faces on Skid Row (seed 7). The autotest bot steers with
##     steer() (the same faces, a slide). Never a navmesh.
## Determinism: a per-lot RNG reseeded from the layout seed (as Arena's cells);
## wrecks only from game events; no instance ids, no clock.
class_name CityBlocks
extends RefCounted

## One standing wreck (Convoy places it; the obstacle is solid until it burns away).
class Wreck:
	extends RefCounted
	## The wreck's obstacle (a rect, kind CityEnemyData.WRECK).
	var obstacle: Arena.Obstacle
	## Its wreck cell key (Vector3i(axis, street index, cell index)).
	var key: Vector3i = Vector3i.ZERO
	## Game time (s) it was placed.
	var placed_at: float = 0.0
	## 0 = along x (a horizontal street), 1 = along y.
	var axis: int = 0

## The merged layout: CityBlockData.DEFAULTS, the STAGE "blocks", the zone's "blocks".
var cfg: Dictionary = {}
## The layout seed (the stage layout's "layout_seed").
var layout_seed: int = 0
## Lot pitch (px): building size plus half a street and half an alley, per axis.
var pitch: Vector2 = Vector2.ONE
## Building size (px): width x height.
var building: Vector2 = Vector2.ONE
## px between two building faces across a street.
var street: float = 192.0
## px between two building faces across an alley.
var alley: float = 80.0
## px of one sidewalk (the street's edge strips).
var sidewalk: float = 24.0
## Share (0..1) of open lots (the current zone's).
var open_share: float = 0.2
## Rooftop style -> weight (the current zone's).
var styles: Dictionary = {}
## Open-lot look -> weight (the current zone's).
var open_styles: Dictionary = {}
## The lot forced open beside the start crossing.
var start_open: Vector2i = Vector2i.ZERO
## Centre of the clear circle (no building overlaps it).
var clear_center: Vector2 = Vector2.ZERO
## Radius (px) of the clear circle.
var clear_radius: float = 0.0
## Lot index -> its building (Arena.Obstacle) or `_empty` for an open lot.
var _lots: Dictionary = {}
## Sentinel stored for open lots.
var _empty: Arena.Obstacle = Arena.Obstacle.new()
## Deterministic RNG reseeded per generated lot.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Wreck cell key -> Wreck.
var _wrecks: Dictionary = {}
## Standing wrecks, oldest first.
var wrecks: Array[Wreck] = []
## True when the drawn layer must redraw (a wreck placed or burnt away).
var dirty: bool = false

# --- Counters (the autotest's "city blocks" line; read only by CityReport) ---
## Lots generated into the cache (built or open), each once per zone layout.
var lots_built: int = 0
## Of those, open lots.
var lots_open: int = 0
## Bodies pushed out of a building (Arena.resolve_all()).
var building_pushes: int = 0
## Bodies pushed out of a wreck (Arena.resolve_all()).
var wreck_pushes: int = 0
## Enemy-seconds spent in contact with a building face (Arena.resolve_all()).
var enemy_contact_s: float = 0.0
## Ring posts pulled back toward the necromancer (Arena.free_point_toward()).
var ring_pulls: int = 0
## Ring posts asked for (Arena.free_point_toward() on this layout).
var ring_posts: int = 0
## Wrecks placed this run.
var wrecks_placed: int = 0
## Wrecks refused (no street cell, a crossing, the cell taken).
var wrecks_refused: int = 0
## Wrecks that burnt away (the oldest past WRECK_MAX).
var wrecks_burnt: int = 0


## Builds the layout from the STAGE's `stage_blocks` and the zone layout's
## `zone_blocks` (both {} = defaults), seeded by `p_seed`, with no building
## overlapping the circle of `p_clear_radius` px around `p_clear_center`.
func _init(stage_blocks: Dictionary, zone_blocks: Dictionary, p_seed: int, p_clear_center: Vector2, p_clear_radius: float) -> void:
	cfg = CityBlockData.DEFAULTS.duplicate()
	for k: String in stage_blocks:
		cfg[k] = stage_blocks[k]
	layout_seed = p_seed
	building = Vector2(float(cfg["building_w"]), float(cfg["building_h"]))
	street = float(cfg["street"])
	alley = float(cfg["alley"])
	sidewalk = float(cfg["sidewalk"])
	pitch = building + Vector2.ONE * (street + alley) * 0.5
	start_open = cfg["start_open"]
	set_zone(zone_blocks, p_clear_center, p_clear_radius)


## Switches to a zone's looks `zone_blocks` (styles, open_share, open_styles;
## the grid keys are ignored: a zone never moves a street) with its clear circle
## (`p_clear_center`, `p_clear_radius` px). Every cached lot is regenerated.
func set_zone(zone_blocks: Dictionary, p_clear_center: Vector2, p_clear_radius: float) -> void:
	open_share = float(zone_blocks.get("open_share", cfg["open_share"]))
	styles = zone_blocks.get("styles", cfg["styles"])
	open_styles = zone_blocks.get("open_styles", cfg["open_styles"])
	clear_center = p_clear_center
	clear_radius = p_clear_radius
	_lots.clear()
	dirty = true


# =====================================================================================
# Geometry
# =====================================================================================

## The lot index of world point `pos`.
func lot_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / pitch.x), floori(pos.y / pitch.y))


## The rect a building of lot `lot` occupies (whether or not the lot is open):
## an even lot's building starts half a street in, an odd lot's half an alley.
func building_rect(lot: Vector2i) -> Rect2:
	var x0 := float(lot.x) * pitch.x + (street if (lot.x & 1) == 0 else alley) * 0.5
	var y0 := float(lot.y) * pitch.y + (street if (lot.y & 1) == 0 else alley) * 0.5
	return Rect2(Vector2(x0, y0), building)


## Index of the horizontal street (constant y) nearest to `pos`, and whether
## `pos` lies inside it (between its two building faces).
func h_street(pos: Vector2) -> int:
	return roundi(pos.y / (2.0 * pitch.y))


## Index of the vertical street (constant x) nearest to `pos`.
func v_street(pos: Vector2) -> int:
	return roundi(pos.x / (2.0 * pitch.x))


## World y of horizontal street `k`'s centre line.
func h_street_y(k: int) -> float:
	return float(k) * 2.0 * pitch.y


## World x of vertical street `k`'s centre line.
func v_street_x(k: int) -> float:
	return float(k) * 2.0 * pitch.x


## True when `pos` lies inside a horizontal street (between its faces).
func in_h_street(pos: Vector2) -> bool:
	return absf(pos.y - h_street_y(h_street(pos))) <= street * 0.5


## True when `pos` lies inside a vertical street (between its faces).
func in_v_street(pos: Vector2) -> bool:
	return absf(pos.x - v_street_x(v_street(pos))) <= street * 0.5


## THE LANE: the street centre line through `pos` along `dir` (the nearer
## axis): {"axis": 0 along x / 1 along y, "point": `pos` projected onto the
## centre line, "centre": the line's fixed coordinate (px), "dir": the unit
## axis direction with `dir`'s sign, "half": half the roadway (px)}.
func lane(pos: Vector2, dir: Vector2) -> Dictionary:
	var half := float(cfg["roadway"]) * 0.5  # Half the roadway (px).
	if absf(dir.x) >= absf(dir.y):
		var y := h_street_y(h_street(pos))
		return {"axis": 0, "point": Vector2(pos.x, y), "centre": y, "dir": Vector2(1.0 if dir.x >= 0.0 else -1.0, 0.0), "half": half}
	var x := v_street_x(v_street(pos))
	return {"axis": 1, "point": Vector2(x, pos.y), "centre": x, "dir": Vector2(0.0, 1.0 if dir.y >= 0.0 else -1.0), "half": half}


## THE STREET-STEERING HINT (read by Enemy.physics_step()'s advance, only on
## a blocks layout): the direction (unit) from `pos` toward `target` for a body
## of radius `r`:
##   * straight at it while the straight line is clear (no building or wreck
##     within `look` px);
##   * else it routes along the streets to the target's STREET POINT (the
##     target itself when it stands in a street, else the nearest point of the
##     nearest street centre line: the mouth of its alley or the edge of its open
##     lot), one turn at a crossing: in a horizontal street it runs along x to
##     the crossing onto that point's vertical street (or straight along x to
##     it when it lies in this street), and the other way round; in a crossing
##     it takes the street that already runs to that point's street. At the
##     point it goes straight in (sliding along the faces). The first clear of
##     that direction (a wreck in it: first a step round the wreck, to the
##     side the body is on), a step in toward that street's centre line (off a
##     building corner at a crossing's edge), the axes toward the target and a
##     sidestep round what blocks the straight line is taken.
##     Never a navmesh.
func street_dir(pos: Vector2, target: Vector2, r: float = 8.0, look: float = 96.0) -> Vector2:
	var to := target - pos
	var dist := to.length()
	if dist < 1.0:
		return Vector2.ZERO
	var straight := to / dist
	var o := _blocker(pos, straight, r, minf(dist, r + 16.0))
	if o == null:
		o = _blocker(pos, straight, r, minf(dist, look))
	if o == null:
		return straight
	var goal := target if (in_h_street(target) or in_v_street(target)) else exit_point(target)  # Its street point.
	var tg := goal - pos  # Toward the street point.
	var cands: Array[Vector2] = []  # Directions to try, in order.
	if tg.length() > 8.0:
		var inh := in_h_street(pos)
		var inv := in_v_street(pos)
		var same_v := v_street(pos) == v_street(goal)
		var same_h := h_street(pos) == h_street(goal)
		if inh and inv:
			if same_v and not same_h:
				cands.append(Vector2(0.0, _sgn(tg.y)))
			elif same_h and not same_v:
				cands.append(Vector2(_sgn(tg.x), 0.0))
			else:
				cands.append(Vector2(_sgn(tg.x), 0.0) if absf(tg.x) >= absf(tg.y) else Vector2(0.0, _sgn(tg.y)))
		elif inh:
			var xs := goal.x if (same_h and in_h_street(goal)) else v_street_x(v_street(goal))  # Along this street to ...
			cands.append(Vector2(_sgn(xs - pos.x), 0.0))
		elif inv:
			var ys := goal.y if (same_v and in_v_street(goal)) else h_street_y(h_street(goal))
			cands.append(Vector2(0.0, _sgn(ys - pos.y)))
		if not cands.is_empty():
			var d0: Vector2 = cands[0]  # The routed direction.
			var rb := _blocker(pos, d0, r, r + 16.0)  # What blocks it (null = clear).
			if rb != null and not is_building(rb):
				# A wreck in the lane: step round it to the side the body is on
				# (a geometric choice: it never flips while passing).
				var perp := Vector2(0.0, 1.0) if d0.y == 0.0 else Vector2(1.0, 0.0)
				var side := (pos - rb.center).dot(perp)
				cands.push_front(perp * (_sgn(side) if absf(side) > 0.5 else 1.0))
			elif rb != null:
				# Hugging the street's edge (a building corner at a crossing's
				# edge): first in toward that street's centre line.
				if d0.x == 0.0 and inv:
					var cx := v_street_x(v_street(pos)) - pos.x
					if absf(cx) > 1.0:
						cands.append(Vector2(_sgn(cx), 0.0))
				elif d0.y == 0.0 and inh:
					var cy := h_street_y(h_street(pos)) - pos.y
					if absf(cy) > 1.0:
						cands.append(Vector2(0.0, _sgn(cy)))
	var ax := Vector2(signf(to.x), 0.0)  # Along x toward the target (zero when level).
	var ay := Vector2(0.0, signf(to.y))  # Along y toward the target.
	if absf(to.x) >= absf(to.y):
		cands.append(ax)
		cands.append(ay)
	else:
		cands.append(ay)
		cands.append(ax)
	var off := pos - o.center  # Which side of the blocker the body is on.
	if absf(straight.x) >= absf(straight.y):
		cands.append(Vector2(0.0, signf(off.y) if absf(off.y) > 0.5 else 1.0))
	else:
		cands.append(Vector2(signf(off.x) if absf(off.x) > 0.5 else 1.0, 0.0))
	for d in cands:
		if d != Vector2.ZERO and _blocker(pos, d, r, r + 16.0) == null:
			return d
	return straight


## The nearest point of the nearest street centre line to `p` (a body off the
## streets: the mouth of its alley, the edge of its open lot).
func exit_point(p: Vector2) -> Vector2:
	var hp := Vector2(p.x, h_street_y(h_street(p)))  # Onto the nearest horizontal street.
	var vp := Vector2(v_street_x(v_street(p)), p.y)  # Onto the nearest vertical street.
	return hp if p.distance_squared_to(hp) <= p.distance_squared_to(vp) else vp


## The sign of `v` (+1 for 0).
static func _sgn(v: float) -> float:
	return -1.0 if v < 0.0 else 1.0


## True when a body of radius `r` at `pos` can step `r` + 16 px along unit
## `dir` without touching a building or a wreck (the civilians' flight).
func clear_dir(pos: Vector2, dir: Vector2, r: float) -> bool:
	return _blocker(pos, dir, r, r + 16.0) == null


## The building or wreck a body of radius `r` at `pos` would touch `length` px
## along unit `dir` (null when that point is clear).
func _blocker(pos: Vector2, dir: Vector2, r: float, length: float) -> Arena.Obstacle:
	var q := pos + dir * length
	var o := obstacle_at(q)
	if o != null and Arena.separation(o, q, r) != Vector2.ZERO:
		return o
	return null


## Bot steering (Autotest, only on a blocks layout): `move` with the part that
## would walk a body of radius `r` at `pos` into a building within `look` px
## turned along the face (the shorter way round), so the bot slides down the
## street instead of pinning against a wall. `move` itself when nothing is ahead.
func steer(pos: Vector2, move: Vector2, r: float, look: float = 28.0) -> Vector2:
	var m := move.length()
	if m < 0.01:
		return move
	var ahead := pos + move / m * look
	var o := obstacle_at(ahead)
	if o == null:
		return move
	var push := Arena.separation(o, ahead, r)
	if push == Vector2.ZERO:
		return move
	var n := push.normalized()  # Out of the face.
	var into := move.dot(n)
	if into >= 0.0:
		return move
	var t := Vector2(-n.y, n.x)  # Along the face.
	var side := 1.0 if move.dot(t) > 0.0 or (move.dot(t) == 0.0 and (pos - o.center).dot(t) >= 0.0) else -1.0
	var out := move - n * into  # The move with the into-the-face part removed.
	if out.length() < m * 0.3:
		out += t * side * m * 0.7
	return out.limit_length(m)


# =====================================================================================
# Lookup (Arena)
# =====================================================================================

## THE LOOKUP (Arena.obstacle_at() on a blocks layout): the building of the
## lot `pos` is in, or a wreck of the street strip(s) `pos` is in, whichever
## is nearer to `pos` (the one a body there overlaps more); null when none.
func obstacle_at(pos: Vector2) -> Arena.Obstacle:
	var lot := lot_of(pos)
	var b: Arena.Obstacle = _lots.get(lot)
	if b == null:
		b = _cache_lot(lot)
	return _with_wrecks(pos, null if b == _empty else b)


## As obstacle_at() but WITHOUT caching a newly generated lot (co-op drawing:
## each machine draws around its own necromancer at its own frame rate, so only
## the simulation fills the cache, the same way on both; Arena._peek()).
func peek(pos: Vector2) -> Arena.Obstacle:
	var lot := lot_of(pos)
	var b: Arena.Obstacle = _lots.get(lot)
	if b == null:
		b = _generate(lot)  # Reseeds the per-lot RNG only: no other state changes.
	return _with_wrecks(pos, null if b == _empty else b)


## The building of lot `lot` for drawing (null when open), uncached when
## `cache` is false (co-op drawing).
func building_of(lot: Vector2i, cache: bool) -> Arena.Obstacle:
	var b: Arena.Obstacle = _lots.get(lot)
	if b == null:
		b = _cache_lot(lot) if cache else _generate(lot)
	return null if b == _empty else b


## Generates lot `lot` and caches it (the simulation's path; counted for the
## autotest's "city blocks" line).
func _cache_lot(lot: Vector2i) -> Arena.Obstacle:
	var b := _generate(lot)
	_lots[lot] = b
	lots_built += 1
	if b == _empty:
		lots_open += 1
	return b


## `b` (the lot's building, or null) or a wreck of the street strip(s) `pos`
## lies in, whichever is nearer to `pos`.
func _with_wrecks(pos: Vector2, b: Arena.Obstacle) -> Arena.Obstacle:
	if _wrecks.is_empty():
		return b
	var best := b
	var best_d := INF
	var hs := street * 0.5  # Half a street (px).
	var hk := roundi(pos.y / (2.0 * pitch.y))  # The nearest horizontal street (inlined h_street()).
	if absf(pos.y - float(hk) * 2.0 * pitch.y) <= hs:
		var w: Wreck = _wrecks.get(Vector3i(0, hk, floori(pos.x / CityBlockData.WRECK_CELL)))
		if w != null:
			best_d = _shape_dist(b, pos) if b != null else INF
			var d := _shape_dist(w.obstacle, pos)
			if d < best_d:
				best = w.obstacle
				best_d = d
	var vk := roundi(pos.x / (2.0 * pitch.x))  # The nearest vertical street (inlined v_street()).
	if absf(pos.x - float(vk) * 2.0 * pitch.x) <= hs:
		var w: Wreck = _wrecks.get(Vector3i(1, vk, floori(pos.y / CityBlockData.WRECK_CELL)))
		if w != null:
			if best_d == INF and best != null:
				best_d = _shape_dist(best, pos)
			if _shape_dist(w.obstacle, pos) < best_d:
				best = w.obstacle
	return best


## Signed distance (px) from `pos` to rect obstacle `o` (negative inside).
static func _shape_dist(o: Arena.Obstacle, pos: Vector2) -> float:
	var local := pos - o.center
	var q := local.abs() - o.half
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0)


## Builds lot `lot`: its building (an Arena.Obstacle rect of a rooftop style),
## or `_empty` for an open lot (the seeded open-lot roll, the forced start lot,
## or a building overlapping the clear circle).
func _generate(lot: Vector2i) -> Arena.Obstacle:
	_rng.seed = hash(Vector3i(lot.x, lot.y, layout_seed))
	var roll := _rng.randf()  # The open-lot roll.
	var style_roll := _rng.randf()  # The rooftop style roll.
	var variant := _rng.randi()  # Cosmetic variation (decals).
	var rect := building_rect(lot)
	if roll < open_share or lot == start_open or _overlaps_clear(rect):
		return _empty
	var o := Arena.Obstacle.new()
	o.kind = "city_" + _pick(styles, style_roll, "tenement")
	o.is_circle = false
	o.center = rect.get_center()
	o.half = rect.size * 0.5
	o.variant = variant
	o.art_key = ""  # Drawn by CityGlyphs.draw_building() (tiled roofs), never EnvironmentArt.
	return o


## True when `rect` overlaps the clear circle.
func _overlaps_clear(rect: Rect2) -> bool:
	if clear_radius <= 0.0:
		return false
	var nearest := clear_center.clamp(rect.position, rect.end)
	return nearest.distance_to(clear_center) < clear_radius


## The look of open lot `lot` (a key of open_styles; a pure function of the
## lot and the seed, so the ground draws it without the cache).
func open_style(lot: Vector2i) -> String:
	var h := absi(hash(Vector3i(lot.x, lot.y, layout_seed + 7177)))
	return _pick(open_styles, float(h % 1000) / 1000.0, "plaza")


## The key of `weights` that roll `r` (0..1) lands on; `fallback` when empty.
static func _pick(weights: Dictionary, r: float, fallback: String) -> String:
	var total := 0.0
	for k: String in weights:
		total += float(weights[k])
	if total <= 0.0:
		return fallback
	var left := r * total
	for k: String in weights:
		left -= float(weights[k])
		if left <= 0.0:
			return k
	return String(weights.keys()[weights.size() - 1])


# =====================================================================================
# Wrecks (Convoy)
# =====================================================================================

## The wreck cell key of `pos` on street axis `axis` (0: the horizontal street
## strip it is in, cells along x; 1: the vertical one, cells along y).
func _cell_key(axis: int, pos: Vector2) -> Vector3i:
	if axis == 0:
		return Vector3i(0, h_street(pos), floori(pos.x / CityBlockData.WRECK_CELL))
	return Vector3i(1, v_street(pos), floori(pos.y / CityBlockData.WRECK_CELL))


## THE WRECK PATH: places a burning wreck where a vehicle died at `pos` (half
## length `half_along` px along its street, clamped to WRECK_HALF_MAX), snapped
## to the centre of its wreck cell on the street's centre line; at game time
## `now`. Refused (null) when `pos` is in no street, in a crossing, too near a
## crossing for the wreck to fit, or the cell already holds one. The oldest
## standing wreck burns away past WRECK_MAX. Returns the new obstacle.
func add_wreck(pos: Vector2, half_along: float, now: float) -> Arena.Obstacle:
	var inh := in_h_street(pos)
	var inv := in_v_street(pos)
	if inh == inv:
		wrecks_refused += 1
		return null  # A crossing (both) or no street (neither: an alley, a lot).
	var axis := 0 if inh else 1
	var key := _cell_key(axis, pos)
	if _wrecks.has(key):
		wrecks_refused += 1
		return null  # At most one wreck per cell.
	var ha := minf(half_along, CityBlockData.WRECK_HALF_MAX)  # Half length along the street (px).
	var hc := minf(CityBlockData.WRECK_HALF_ACROSS, CityBlockData.WRECK_HALF_MAX)  # Half width across it (px).
	var along := (float(key.z) + 0.5) * CityBlockData.WRECK_CELL  # The cell centre along the street (px).
	var cross := v_street_x(roundi(along / (2.0 * pitch.x))) if axis == 0 else h_street_y(roundi(along / (2.0 * pitch.y)))  # Nearest crossing street's centre.
	if absf(along - cross) < street * 0.5 + CityBlockData.WRECK_CROSSING_CLEAR + ha:
		wrecks_refused += 1
		return null  # Keep the crossings open (vehicles turn there).
	var o := Arena.Obstacle.new()
	o.kind = CityEnemyData.WRECK
	o.is_circle = false
	if axis == 0:
		o.center = Vector2(along, h_street_y(key.y))
		o.half = Vector2(ha, hc)
	else:
		o.center = Vector2(v_street_x(key.y), along)
		o.half = Vector2(hc, ha)
	o.variant = wrecks_placed
	o.art_key = ""
	var w := Wreck.new()
	w.obstacle = o
	w.key = key
	w.placed_at = now
	w.axis = axis
	_wrecks[key] = w
	wrecks.append(w)
	wrecks_placed += 1
	if wrecks.size() > CityBlockData.WRECK_MAX:
		var old: Wreck = wrecks.pop_front()
		_wrecks.erase(old.key)
		wrecks_burnt += 1
	dirty = true
	return o


## The standing wreck whose obstacle is `o`, or null.
func wreck_of(o: Arena.Obstacle) -> Wreck:
	for w in wrecks:
		if w.obstacle == o:
			return w
	return null


## True when `o` is a building of this layout (not a wreck).
static func is_building(o: Arena.Obstacle) -> bool:
	return o != null and o.kind.begins_with("city_") and o.kind != CityEnemyData.WRECK


# =====================================================================================
# Drawing helpers (CityGround, Arena; visual only)
# =====================================================================================

## Lot indices whose lot overlaps `rect` (inclusive range: [from, to]).
func lot_range(rect: Rect2) -> Array[Vector2i]:
	return [lot_of(rect.position), lot_of(rect.end)]
