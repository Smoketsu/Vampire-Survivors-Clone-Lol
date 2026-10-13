## SanctumGround — the Sanctum of Judgment's procedural floor (GDD §8.3 art:
## "cathedral halls, cloisters, sacred courtyards, stained glass, giant
## statues, golden mosaics; progressively corrupted as holy wards fall"),
## drawn with _draw() like Ground (it extends it and reuses its
## redraw-on-cell-change logic). Each battle zone has its own floor
## (SanctumStage.ZONES "ground"):
##   courtyard  — pale flagstones in staggered courses, moss, gold inlay stars.
##   halls      — a gold mosaic of small tesserae, rosettes and carpet runners.
##   cloisters  — stone walks in a square grid around turf and flower beds.
##   sanctuary  — marble slabs with veins and pools of stained-glass light.
## Corruption (SanctumDirector, 0..1 as chambers are cleansed and altars
## fall) blends every colour toward a necromantic purple (set_corruption()).
## MarchDirector calls set_zone() at each zone change. Art pass: the zone's
## floor tile (tiles/sanctum_<style>.png, no purple baked in) replaces the base
## colour and the joint pattern when its PNG exists (Ground header,
## EnvironmentArt); the decorations then become floor decals
## (decals/sanctum_<style>_<name>.png, the halls' carpet strip), are dropped,
## or stay code-drawn (the stained-glass light), per DecalData; the corruption
## then tints all of it with one translucent overlay of the corruption colour
## drawn last, at the same blend strength as _t(), which equals lerping every
## pixel toward it. Purely cosmetic.
class_name SanctumGround
extends Ground

## Stained-glass light colours of the Final Sanctuary (translucent pools).
const GLASS := [Color(0.95, 0.25, 0.25), Color(0.30, 0.45, 0.95), Color(1.0, 0.80, 0.30), Color(0.40, 0.80, 0.45)]

## Current zone look (a SanctumStage.ZONES "ground" dictionary).
var _look: Dictionary = {}
## Corruption shown (0..1).
var _corruption: float = 0.0
## Colour every floor colour is blended toward as corruption rises.
var _corrupt_color: Color = Color(0.17, 0.07, 0.21)
## Blend strength (0..1) at corruption 1.
var _corrupt_tint: float = 0.65
## Corruption value of the last redraw (redraws only on a visible change).
var _drawn_corruption: float = 0.0


func _ready() -> void:
	super._ready()
	var zones: Array = SanctumStage.ZONES
	_look = zones[0]["ground"]


## Switches to zone look `look` and redraws at once.
func set_zone(look: Dictionary) -> void:
	_look = look
	queue_redraw()


## Sets the floor's corruption (0..1) toward `color` at strength `tint`;
## redraws when it changed visibly (>= 0.02) or reached its target.
func set_corruption(value: float, color: Color, tint: float) -> void:
	_corruption = clampf(value, 0.0, 1.0)
	_corrupt_color = color
	_corrupt_tint = tint
	if absf(_corruption - _drawn_corruption) >= 0.02 or is_equal_approx(_corruption, 1.0):
		queue_redraw()


## `col` blended toward the corruption colour; unchanged on the tile floor,
## where one overlay drawn last blends everything (_draw()).
func _t(col: Color) -> Color:
	if _art_floor:
		return col
	var c := col.lerp(_corrupt_color, _corruption * _corrupt_tint)
	c.a = col.a
	return c


func _draw() -> void:
	_drawn_corruption = _corruption
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(_look["style"])
	_art_floor = _draw_tiles(rect)
	if not _art_floor:
		draw_rect(rect, _t(_look["base"]))
		match style:
			"courtyard":
				_courses(rect, 48.0, 72.0)
			"halls":
				_grid(rect, 24.0, 1.0)
			"cloisters":
				_grid(rect, GRID * 2.0, 6.0)
			_:
				_grid(rect, GRID, 1.0)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_sanctum_cell(cx, cy, style)
	if _art_floor:
		# The corruption over the tiles, the decals and the code decorations
		# alike (on the tile floor _t() leaves colours as they are, so this one
		# overlay is the whole blend; for the translucent code decorations the
		# result equals blending each colour, as alpha blending is linear).
		var k := _corruption * _corrupt_tint  # Blend toward purple (0..1), as in _t().
		if k > 0.0:
			draw_rect(rect, Color(_corrupt_color, k))  # floor * (1 - k) + purple * k.


## Flagstones in staggered courses: `row` px tall, `slab` px long.
func _courses(rect: Rect2, row: float, slab: float) -> void:
	var line := _t(_look["line"])
	var y := floorf(rect.position.y / row) * row
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line, 1.5)
		var shift := slab * 0.5 if int(floorf(y / row)) % 2 == 0 else 0.0  # Staggered joints.
		var x := floorf(rect.position.x / slab) * slab + shift
		while x <= rect.end.x:
			draw_line(Vector2(x, y), Vector2(x, y + row), line, 1.5)
			x += slab
		y += row


## A square joint grid every `step` px, lines `width` px wide.
func _grid(rect: Rect2, step: float, width: float) -> void:
	var line := _t(_look["line"])
	var x := floorf(rect.position.x / step) * step
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), line, width)
		x += step
	var y := floorf(rect.position.y / step) * step
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line, width)
		y += step


## The Sanctum's cell hash (salted, so its decorations differ from the Graveyard's).
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 313)))


## Decal key prefix of the current zone: sanctum_<style>_.
func _decal_prefix() -> String:
	return "sanctum_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/sanctum_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "sanctum_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_sanctum_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	match style:
		"courtyard":
			_decor_courtyard(p, roll, h)
		"halls":
			_decor_halls(p, roll, h, cx, cy)
		"cloisters":
			_decor_cloisters(p, roll, h)
		_:
			_decor_sanctuary(p, roll, h)


## Outer Courtyards: moss in the joints, a cracked slab, a gold inlay star,
## fallen petals.
func _decor_courtyard(p: Vector2, roll: float, h: int) -> void:
	var k := _decal_prefix()  # Decal key prefix (sanctum_courtyard_).
	if roll < 0.12:
		if not _decal(k + "moss", p, h):
			draw_circle(p, 10.0 + float(h % 10), _t(Color(0.20, 0.27, 0.17, 0.5)))  # Moss.
	elif roll < 0.20:
		if not _decal(k + "crack", p, h):
			draw_polyline(PackedVector2Array([p, p + Vector2(9, 5), p + Vector2(14, 2), p + Vector2(22, 9)]), _t(_look["line"]), 1.0)  # Crack.
	elif roll < 0.25:
		if _decal(k + "star", p, h):
			return
		var trim: Color = _t(_look["trim"])
		for i in 4:  # Gold inlay star.
			var d := Vector2.from_angle(TAU * float(i) / 4.0 + PI / 4.0) * 9.0
			draw_line(p - d, p + d, trim, 2.0)
		draw_circle(p, 3.0, trim)
	elif roll < 0.30:
		if not _decal(k + "slab", p, h):
			draw_rect(Rect2(p, Vector2(30, 22)), _t(_look["accent"]))  # A paler slab.
	elif roll < 0.33:
		if _decal(k + "petals", p, h):
			return
		for i in 3:  # Fallen petals.
			draw_circle(p + Vector2(float(i) * 6.0, float((h >> (i + 2)) % 5)), 1.5, _t(Color(0.85, 0.80, 0.70)))


## Sanctified Halls: gold mosaic tesserae, rosettes and crimson carpet runners.
func _decor_halls(p: Vector2, roll: float, h: int, cx: int, cy: int) -> void:
	var trim: Color = _t(_look["trim"])
	var accent: Color = _t(_look["accent"])
	var k := _decal_prefix()  # Decal key prefix (sanctum_halls_).
	if cy % 4 == 0:
		# A carpet runner along every fourth cell row.
		var y := float(cy) * CELL + CELL * 0.5
		if _art_floor and EnvironmentArt.draw_strip(self, DecalData.CARPET_KEY, float(cx) * CELL, y):
			return
		draw_rect(Rect2(float(cx) * CELL, y - 18.0, CELL, 36.0), _t(Palette.DARK_CRIMSON.darkened(0.45)))
		draw_line(Vector2(float(cx) * CELL, y - 15.0), Vector2(float(cx + 1) * CELL, y - 15.0), trim, 1.5)
		draw_line(Vector2(float(cx) * CELL, y + 15.0), Vector2(float(cx + 1) * CELL, y + 15.0), trim, 1.5)
		return
	if roll < 0.30:
		if _decal(k + "tesserae", p, h):
			return
		for i in 6:  # Gold tesserae.
			var q := p + Vector2(float((h >> (i * 2)) % 40), float((h >> (i * 2 + 5)) % 40))
			draw_rect(Rect2(q, Vector2(5, 5)), trim if i % 2 == 0 else accent)
	elif roll < 0.42:
		if _decal(k + "rosette", p, h):
			return
		draw_circle(p, 16.0, accent)  # Mosaic rosette.
		for i in 8:
			draw_circle(p + Vector2.from_angle(TAU * float(i) / 8.0) * 11.0, 3.0, trim)
		draw_circle(p, 5.0, trim)
	elif roll < 0.48:
		if _decal(k + "diamond", p, h):
			return
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -12), p + Vector2(12, 0), p + Vector2(0, 12), p + Vector2(-12, 0)]), accent)  # Diamond.
		draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), trim)


## Cloisters: turf and flower beds inside the stone walks, a fountain basin
## mark, fallen leaves.
func _decor_cloisters(p: Vector2, roll: float, h: int) -> void:
	var grass: Color = _t(_look["accent"])
	var k := _decal_prefix()  # Decal key prefix (sanctum_cloisters_).
	if roll < 0.30:
		if _decal(k + "turf", p, h):
			return
		draw_circle(p, 22.0 + float(h % 14), grass)  # Turf.
		draw_circle(p + Vector2(10, -6), 14.0, _t(Color(0.24, 0.34, 0.21)))
	elif roll < 0.40:
		if _decal(k + "flowers", p, h):
			return
		for i in 5:  # Flowers.
			var q := p + Vector2(float(i) * 7.0, float((h >> (i + 3)) % 9))
			draw_circle(q, 2.0, _t(Color(0.86, 0.82, 0.62) if i % 2 == 0 else Color(0.80, 0.30, 0.34)))
	elif roll < 0.46:
		if _decal(k + "sundial", p, h):
			return
		draw_arc(p, 14.0, 0.0, TAU, 20, _t(_look["trim"]), 1.5)  # Sundial ring.
		draw_line(p, p + Vector2(10, -6), _t(_look["trim"]), 1.5)
	elif roll < 0.52:
		if _decal(k + "leaves", p, h):
			return
		for i in 3:  # Leaves.
			draw_circle(p + Vector2(float(i) * 9.0, float((h >> i) % 7)), 2.0, _t(Color(0.45, 0.38, 0.18)))


## Final Sanctuary: marble veins and pools of stained-glass light.
func _decor_sanctuary(p: Vector2, roll: float, h: int) -> void:
	var k := _decal_prefix()  # Decal key prefix (sanctum_sanctuary_).
	if roll < 0.22:
		# Stained-glass light (soft and translucent: code-drawn on the tile floor too).
		var col: Color = GLASS[h % GLASS.size()]
		var w := 36.0 + float(h % 24)
		# A slanting window's light: a translucent rhombus.
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(w, 0), p + Vector2(w + 18.0, 40.0), p + Vector2(18.0, 40.0)]), _t(Color(col, 0.16)))
		draw_line(p + Vector2(w * 0.5, 0), p + Vector2(w * 0.5 + 18.0, 40.0), _t(Color(0.1, 0.1, 0.1, 0.25)), 1.5)  # Lead came.
	elif roll < 0.36:
		if not _decal(k + "vein", p, h):
			draw_polyline(PackedVector2Array([p, p + Vector2(14, 6), p + Vector2(22, 4), p + Vector2(36, 14)]), _t(_look["accent"]), 1.5)  # Vein.
	elif roll < 0.42:
		if _decal(k + "inlay", p, h):
			return
		draw_rect(Rect2(p, Vector2(18, 18)), _t(_look["accent"]))  # Inlaid square.
		draw_rect(Rect2(p + Vector2(5, 5), Vector2(8, 8)), _t(_look["trim"]))
