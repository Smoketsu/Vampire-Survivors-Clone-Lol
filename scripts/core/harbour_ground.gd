## HarbourGround — Gullhaven Harbour's procedural floor (Act II, GDD §15.0
## "Gullhaven Harbour (Act II phase 2)"; owner-approved proposal: "a fishing
## town at low tide, at night"), drawn with _draw() like Ground (it extends it
## and reuses its redraw-on-cell-change logic). Each battle zone has its own
## floor (HarbourStage.ZONES "ground"):
##   mudflats — wet sand in low ripples, shells, kelp and tide puddles.
##   market   — wet cobbles in a tight grid, fish scales, rope coils, gutters.
##   chapel   — slimed flagstones, coral crust, barnacles, the Eye's sigil.
##   seawall  — big dressed paving stones of the promenade, mooring rings.
## The tide's water is drawn over all of it by the TideDirector. MarchDirector
## calls set_zone() at each zone change. Art pass: the zone's floor tile
## (tiles/harbour_<style>.png) replaces the base colour and the joint pattern
## when its PNG exists (Ground header, EnvironmentArt); the decorations then
## become floor decals (decals/harbour_<style>_<name>.png), are dropped, or
## stay code-drawn (the puddles), per DecalData. Purely cosmetic.
class_name HarbourGround
extends Ground

## Current zone look (a HarbourStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = HarbourStage.ZONES
	_look = zones[0]["ground"]


## Switches to zone look `look` and redraws at once.
func set_zone(look: Dictionary) -> void:
	_look = look
	queue_redraw()


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(_look["style"])
	_art_floor = _draw_tiles(rect)
	if not _art_floor:
		draw_rect(rect, _look["base"])
		match style:
			"mudflats":
				_ripples(rect)
			"market":
				_grid(rect, 24.0, 1.0)
			"chapel":
				_grid(rect, GRID, 1.5)
			_:
				_courses(rect, 48.0, 96.0)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_harbour_cell(cx, cy, style)


## Low sand ripples: gentle wavy lines every 32 px.
func _ripples(rect: Rect2) -> void:
	var line: Color = _look["line"]
	var y := floorf(rect.position.y / 32.0) * 32.0
	while y <= rect.end.y:
		var pts := PackedVector2Array()
		var x := floorf(rect.position.x / 48.0) * 48.0
		while x <= rect.end.x + 48.0:
			pts.append(Vector2(x, y + 4.0 * sin(x * 0.03 + y * 0.11)))
			x += 24.0
		draw_polyline(pts, line, 1.0)
		y += 32.0


## A square joint grid every `step` px, lines `width` px wide.
func _grid(rect: Rect2, step: float, width: float) -> void:
	var line: Color = _look["line"]
	var x := floorf(rect.position.x / step) * step
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), line, width)
		x += step
	var y := floorf(rect.position.y / step) * step
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line, width)
		y += step


## Paving stones in staggered courses: `row` px tall, `slab` px long.
func _courses(rect: Rect2, row: float, slab: float) -> void:
	var line: Color = _look["line"]
	var y := floorf(rect.position.y / row) * row
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line, 1.5)
		var shift := slab * 0.5 if int(floorf(y / row)) % 2 == 0 else 0.0  # Staggered joints.
		var x := floorf(rect.position.x / slab) * slab + shift
		while x <= rect.end.x:
			draw_line(Vector2(x, y), Vector2(x, y + row), line, 1.5)
			x += slab
		y += row


## The Harbour's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 414)))


## Decal key prefix of the current zone: harbour_<style>_.
func _decal_prefix() -> String:
	return "harbour_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/harbour_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "harbour_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_harbour_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var k := _decal_prefix()  # Decal key prefix.
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	match style:
		"mudflats":
			if roll < 0.12:
				if not _decal(k + "shells", p, h):
					for i in 3:  # Shells.
						draw_circle(p + Vector2(float(i) * 6.0, float((h >> (i + 3)) % 6)), 2.0, trim)
			elif roll < 0.22:
				if not _decal(k + "kelp", p, h):
					draw_polyline(PackedVector2Array([p, p + Vector2(8, -4), p + Vector2(14, 2), p + Vector2(22, -3)]), Color(0.16, 0.24, 0.17), 2.0)  # Stranded kelp.
			elif roll < 0.30:
				draw_circle(p, 14.0 + float(h % 12), Color(accent.darkened(0.35), 0.6))  # A tide puddle (code on every floor).
		"market":
			if roll < 0.12:
				if not _decal(k + "scales", p, h):
					for i in 5:  # Fish scales.
						draw_circle(p + Vector2(float((h >> (i * 2)) % 24), float((h >> (i * 2 + 5)) % 16)), 1.2, trim)
			elif roll < 0.20:
				if not _decal(k + "rope", p, h):
					draw_arc(p, 8.0, 0.0, TAU, 14, Color(0.38, 0.30, 0.20), 2.0)  # A coil of rope.
					draw_arc(p, 4.0, 0.0, TAU, 10, Color(0.38, 0.30, 0.20), 2.0)
			elif roll < 0.27:
				if not _decal(k + "fish", p, h):
					draw_colored_polygon(PackedVector2Array([p, p + Vector2(10, -3), p + Vector2(14, 0), p + Vector2(10, 3)]), accent.lightened(0.15))  # A dropped fish.
		"chapel":
			if roll < 0.14:
				if not _decal(k + "coral", p, h):
					draw_circle(p, 9.0 + float(h % 8), Color(0.24, 0.18, 0.26))  # Coral crust.
					draw_circle(p + Vector2(6, -4), 5.0, Color(0.30, 0.22, 0.30))
			elif roll < 0.22:
				if not _decal(k + "barnacles", p, h):
					for i in 4:  # Barnacles.
						draw_circle(p + Vector2(float(i) * 5.0, float((h >> i) % 5)), 2.0, Color(0.42, 0.42, 0.38))
			elif roll < 0.26:
				if not _decal(k + "sigil", p, h):
					draw_arc(p, 12.0, 0.0, TAU, 18, Color(trim, 0.6), 1.5)  # The Eye's sigil carved in the floor.
					draw_circle(p, 3.0, Color(trim, 0.7))
		_:
			if roll < 0.10:
				if not _decal(k + "ring", p, h):
					draw_arc(p, 6.0, 0.0, TAU, 12, Color(0.30, 0.30, 0.30), 2.0)  # A mooring ring.
			elif roll < 0.18:
				if not _decal(k + "chain", p, h):
					for i in 4:  # A rusted chain.
						draw_arc(p + Vector2(float(i) * 7.0, 0.0), 3.0, 0.0, TAU, 8, Color(0.36, 0.26, 0.20), 1.5)
			elif roll < 0.24:
				if not _decal(k + "feather", p, h):
					draw_line(p, p + Vector2(10, -3), Color(0.55, 0.55, 0.52), 1.5)  # A gull feather.
