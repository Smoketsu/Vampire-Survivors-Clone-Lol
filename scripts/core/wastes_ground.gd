## WastesGround — the procedural floor of the Scrap Wastes (Act III, Stage 7;
## GDD §15.0 "The Scrap Wastes (Act III phase 2)": "the Empire's old
## battlefield: slag hills, rusting war machines the size of buildings, and red
## signal masts on the ridges"), drawn with _draw() like Ground (it extends it
## and reuses its redraw-on-cell-change logic). Each zone has its own floor
## (WastesStage.ZONES "ground"):
##   slag     — the Slag Fields: cooled black slag crust with rust stains.
##   gullies  — the Wreck Gullies: packed rust-brown grit between the wrecks,
##              scattered plates and bolts.
##   ridge    — Pylon Ridge: dark ash rock, cracked, with dead cable runs.
##   wall     — the Outer Wall: cracked grey concrete slabs with old hazard
##              paint.
## Art pass: the zone's floor tile (tiles/wastes_<style>.png and its variants)
## replaces the base colour and joints when its PNG exists (Ground header,
## EnvironmentArt); the plates and cracks are then left out (the tile has its
## own) and the rest stay code-drawn (sparse and flat: a dead signal light,
## hazard paint, a cable). MarchDirector calls set_zone() at
## each zone change. Purely cosmetic: nothing here collides.
class_name WastesGround
extends Ground

## Current zone look (a WastesStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = WastesStage.ZONES
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
		if style == "wall":
			_slabs(rect, 96.0)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_wastes_cell(cx, cy, style)


## Concrete slab joints every `step` px (the Outer Wall's code floor).
func _slabs(rect: Rect2, step: float) -> void:
	var line: Color = _look["line"]
	var x := floorf(rect.position.x / step) * step
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), line, 2.0)
		x += step
	var y := floorf(rect.position.y / step) * step
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line, 2.0)
		y += step


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 7707)))


## Decal key prefix of the current zone: wastes_<style>_.
func _decal_prefix() -> String:
	return "wastes_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/wastes_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "wastes_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_wastes_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	if _art_floor and roll < 0.16:
		return  # The tile already has its own grit and plates: no flat code plates or cracks on it.
	if roll < 0.10:
		# A scrap plate lying flat (rusted chrome).
		var w := 10.0 + float(h % 12)  # Plate width (px).
		var r := Rect2(p, Vector2(w, w * 0.6).round())
		draw_rect(r, Color(accent, 0.55))
		draw_line(r.position, Vector2(r.end.x, r.position.y), Color(accent.lightened(0.25), 0.5), 1.0)
	elif roll < 0.16:
		# A crack in the crust / rock / concrete.
		draw_polyline(PackedVector2Array([p, p + Vector2(8, 3), p + Vector2(13, -2), p + Vector2(22, 4)]), Color(_look["line"], 0.9), 1.5)
	elif roll < 0.19:
		draw_circle(p, 2.0, Color(trim, 0.3))  # A dead signal light half buried.
	elif roll < 0.23 and style == "wall":
		# Old hazard paint on the concrete: amber and dark diagonals.
		for k in 3:
			var q := p + Vector2(float(k) * 8.0, 0)
			draw_colored_polygon(PackedVector2Array([q, q + Vector2(4, 0), q + Vector2(8, 8), q + Vector2(4, 8)]), Color(trim, 0.22))
	elif roll < 0.23 and style == "ridge":
		# A dead cable run across the rock.
		draw_polyline(PackedVector2Array([p, p + Vector2(10, 6), p + Vector2(24, 5), p + Vector2(34, 11)]), Color(accent.darkened(0.3), 0.8), 2.0)
