## SpatialHash — uniform-grid spatial index for "who is near this point"
## queries (GDD §22 SpatialIndex, §38 "grid-based spatial hash ... avoid full
## enemy scans per unit").
##
## Usage pattern: Game clears and re-inserts every living entity once per
## physics tick (cheap: O(n) dictionary appends), then any system can run
## radius queries in O(cells touched + items in them).
## Items must expose a `position` in world space (all entities live in
## containers at the world origin, so local == world).
##
## Bucket arrays are reused between frames (cleared, not reallocated) to avoid
## per-frame garbage; empty buckets are purged occasionally.
class_name SpatialHash
extends RefCounted

## Width/height of one grid cell in px. Should be ~2x the typical query radius.
var cell_size: float = 64.0
## 1 / cell_size, cached to turn divisions into multiplications.
var _inv_cell: float = 1.0 / 64.0
## Packed cell key (cx + cy * KEY_STRIDE, an int: cheaper to build and hash
## than a Vector2i) -> Array of items in that cell.
var _cells: Dictionary = {}
## The buckets that got an item since the last clear (so clear() empties only
## those instead of walking every bucket ever made).
var _used: Array[Array] = []
## Number of items inserted since the last clear (debug / stats).
var count: int = 0
## Clears since the last purge of empty buckets.
var _clears_since_purge: int = 0
## Lowest cell x that holds an item since the last clear (cells; BOUND_EMPTY when empty).
var _min_cx: int = BOUND_EMPTY
## Highest cell x that holds an item since the last clear (cells; -BOUND_EMPTY when empty).
var _max_cx: int = -BOUND_EMPTY
## Lowest cell y that holds an item since the last clear (cells; BOUND_EMPTY when empty).
var _min_cy: int = BOUND_EMPTY
## Highest cell y that holds an item since the last clear (cells; -BOUND_EMPTY when empty).
var _max_cy: int = -BOUND_EMPTY

## Buckets beyond this many trigger a purge of empty ones on clear.
const PURGE_THRESHOLD: int = 2048
## Clears between forced purges even below the threshold.
const PURGE_INTERVAL: int = 600
## Cell-y multiplier of the packed key (cells): keys are unique while every
## |cell x| stays below half of it (2^19 cells = 33 million px at 64 px cells).
const KEY_STRIDE: int = 1048576
## "No cell yet" value of the occupied bounds (cells; far outside any world).
const BOUND_EMPTY: int = 1 << 40


func _init(p_cell_size: float = 64.0) -> void:
	cell_size = p_cell_size
	_inv_cell = 1.0 / p_cell_size


## Empties every bucket (keeps the arrays for reuse).
func clear() -> void:
	_clears_since_purge += 1
	if _cells.size() > PURGE_THRESHOLD or _clears_since_purge >= PURGE_INTERVAL:
		_cells.clear()
		_clears_since_purge = 0
	else:
		for bucket in _used:
			bucket.clear()
	_used.clear()
	count = 0
	_min_cx = BOUND_EMPTY
	_max_cx = -BOUND_EMPTY
	_min_cy = BOUND_EMPTY
	_max_cy = -BOUND_EMPTY


## Adds `item` at world position `pos`.
func insert(item: Object, pos: Vector2) -> void:
	var cx := floori(pos.x * _inv_cell)  # Cell x of the item.
	var cy := floori(pos.y * _inv_cell)  # Cell y of the item.
	var key := cx + cy * KEY_STRIDE  # Packed cell key.
	var bucket: Variant = _cells.get(key)
	if bucket == null:
		var fresh: Array = [item]  # First item of a new cell.
		_cells[key] = fresh
		_used.append(fresh)
	else:
		var b: Array = bucket  # The cell's reused bucket.
		if b.is_empty():
			_used.append(b)
		b.append(item)
	count += 1
	if cx < _min_cx:
		_min_cx = cx
	if cx > _max_cx:
		_max_cx = cx
	if cy < _min_cy:
		_min_cy = cy
	if cy > _max_cy:
		_max_cy = cy


## Fills `out` (cleared first) with every item whose position lies within
## `radius` of `center`. The caller owns `out` so it can be reused per frame.
## Items may be inactive (died this frame); callers must check that.
## The cell range is clipped to the occupied bounds first, so a query far
## from every item (an enemy still walking in from the spawn ring asking for
## blockers) costs four comparisons; the visiting order (rows, then columns,
## then insertion order) is unchanged, so results are identical.
func query(center: Vector2, radius: float, out: Array) -> void:
	out.clear()
	var min_x := maxi(floori((center.x - radius) * _inv_cell), _min_cx)
	var max_x := mini(floori((center.x + radius) * _inv_cell), _max_cx)
	if min_x > max_x:
		return
	var min_y := maxi(floori((center.y - radius) * _inv_cell), _min_cy)
	var max_y := mini(floori((center.y + radius) * _inv_cell), _max_cy)
	var r2 := radius * radius
	for cy in range(min_y, max_y + 1):
		var row := cy * KEY_STRIDE  # Key part of this row.
		for cx in range(min_x, max_x + 1):
			var bucket: Variant = _cells.get(row + cx)
			if bucket == null:
				continue
			for item: Node2D in bucket:
				if item.position.distance_squared_to(center) <= r2:
					out.append(item)
