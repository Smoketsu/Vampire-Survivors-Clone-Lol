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
## Vector2i cell coordinate -> Array of items in that cell.
var _cells: Dictionary = {}
## Number of items inserted since the last clear (debug / stats).
var count: int = 0
## Clears since the last purge of empty buckets.
var _clears_since_purge: int = 0

## Buckets beyond this many trigger a purge of empty ones on clear.
const PURGE_THRESHOLD: int = 2048
## Clears between forced purges even below the threshold.
const PURGE_INTERVAL: int = 600


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
		for bucket: Array in _cells.values():
			bucket.clear()
	count = 0


## Adds `item` at world position `pos`.
func insert(item: Object, pos: Vector2) -> void:
	var key := Vector2i(floori(pos.x * _inv_cell), floori(pos.y * _inv_cell))
	var bucket: Variant = _cells.get(key)
	if bucket == null:
		_cells[key] = [item]
	else:
		(bucket as Array).append(item)
	count += 1


## Fills `out` (cleared first) with every item whose position lies within
## `radius` of `center`. The caller owns `out` so it can be reused per frame.
## Items may be inactive (died this frame); callers must check that.
func query(center: Vector2, radius: float, out: Array) -> void:
	out.clear()
	var min_x := floori((center.x - radius) * _inv_cell)
	var max_x := floori((center.x + radius) * _inv_cell)
	var min_y := floori((center.y - radius) * _inv_cell)
	var max_y := floori((center.y + radius) * _inv_cell)
	var r2 := radius * radius
	for cy in range(min_y, max_y + 1):
		for cx in range(min_x, max_x + 1):
			var bucket: Variant = _cells.get(Vector2i(cx, cy))
			if bucket == null:
				continue
			for item: Node2D in bucket:
				if item.position.distance_squared_to(center) <= r2:
					out.append(item)
