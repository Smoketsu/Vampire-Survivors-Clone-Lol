## CitadelGround — the floors of THE IRON CITADEL (Act III, Stage 9; GDD §15.0
## "The Iron Citadel (Act III phase 2)"), drawn with _draw() like Ground (it
## extends it and reuses its redraw-on-cell-change logic). Each zone has its own
## floor (CitadelStage.ZONES "ground"):
##   gates  — dark riveted iron plates with amber trim lines (the Shield Gates).
##   courts — polished court tiles cut by thin warning-red grid lines (the Laser
##            Courts: the grid the beams follow).
##   lifts  — steel grating over the lift shafts, hazard-striped edges (the Spire
##            Lifts).
##   core   — a black floor veined with glowing amber circuit traces (the Core).
## Art pass: the zone's floor tile (tiles/citadel_<style>.png, made with
## tools/make_tile.py) replaces the base colour and joints when its PNG exists
## (Ground header, EnvironmentArt); the decorations then become decals
## (decals/citadel_<style>_<name>.png) when those exist, or stay code-drawn (the
## soft glows). MarchDirector calls set_zone() at each zone change. Purely
## cosmetic: nothing here collides.
class_name CitadelGround
extends Ground

## Current zone look (a CitadelStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = CitadelStage.ZONES
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
			"gates":
				_grid(rect, 64.0, 2.0, _look["line"])
			"courts":
				_grid(rect, 96.0, 1.0, Color(_look["line"], 0.9))
			"lifts":
				_grid(rect, 32.0, 1.0, _look["line"])
			_:
				_grid(rect, 128.0, 1.0, _look["line"])
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_citadel_cell(cx, cy, style)


## A square joint grid every `step` px, lines `width` px wide in `col`.
func _grid(rect: Rect2, step: float, width: float, col: Color) -> void:
	var x := floorf(rect.position.x / step) * step
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), col, width)
		x += step
	var y := floorf(rect.position.y / step) * step
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), col, width)
		y += step


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 9909)))


## Decal key prefix of the current zone: citadel_<style>_.
func _decal_prefix() -> String:
	return "citadel_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/citadel_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "citadel_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_citadel_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var k := _decal_prefix()  # Decal key prefix (citadel_<style>_).
	var accent: Color = _look["accent"]
	var glow: Color = _look["glow"]
	match style:
		"gates":
			if roll < 0.12:
				if _decal(k + "plate", p, h):
					return
				var r := Rect2(p, Vector2(30, 18))  # A bolted floor plate.
				draw_rect(r, Color(accent, 0.6))
				for q: Vector2 in [r.position + Vector2(3, 3), Vector2(r.end.x - 3, r.position.y + 3), r.end - Vector2(3, 3), Vector2(r.position.x + 3, r.end.y - 3)]:
					draw_circle(q, 1.2, Color(accent.lightened(0.35), 0.8))
			elif roll < 0.18:
				draw_line(p, p + Vector2(40, 0), Color(glow, 0.25), 2.0)  # An amber trim light (soft: code-drawn on tiles too).
		"courts":
			if roll < 0.1:
				draw_circle(p, 3.0, Color(glow, 0.35))  # An emitter port in the floor.
				draw_arc(p, 6.0, 0.0, TAU, 12, Color(glow, 0.25), 1.0)
			elif roll < 0.16:
				if _decal(k + "scorch", p, h):
					return
				draw_line(p, p + Vector2(26, 2), Color(0.02, 0.02, 0.03, 0.55), 3.0)  # A laser scorch.
		"lifts":
			if roll < 0.12:
				if _decal(k + "hazard", p, h):
					return
				for i in 4:  # A hazard-stripe edge.
					var q := p + Vector2(float(i) * 8.0, 0)
					draw_colored_polygon(PackedVector2Array([q, q + Vector2(4, 0), q + Vector2(8, 10), q + Vector2(4, 10)]), Color(glow, 0.35))
			elif roll < 0.18:
				draw_rect(Rect2(p, Vector2(22, 22)), Color(0.0, 0.0, 0.0, 0.35))  # A dark shaft grille.
		_:
			if roll < 0.16:
				# A glowing circuit trace (soft: code-drawn on the tile floor too).
				var horizontal := (h >> 5) % 2 == 0
				var a := p
				var b := p + (Vector2(40, 0) if horizontal else Vector2(0, 40))
				var c := b + (Vector2(0, 18) if horizontal else Vector2(18, 0))
				draw_polyline(PackedVector2Array([a, b, c]), Color(glow, 0.35), 2.0)
				draw_circle(c, 2.5, Color(glow, 0.6))
