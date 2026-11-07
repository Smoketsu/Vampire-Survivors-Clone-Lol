## PandemoniumGround — the floors of PANDEMONIUM (Act VI, Stage 18; GDD §15.0
## "Pandemonium (Act VI phase 2)"), drawn with _draw() like Ground (it extends it
## and reuses its redraw-on-cell-change logic). Each zone has its own floor
## (PandemoniumStage.ZONES "ground"):
##   iron       — the Iron City: black obsidian paving, riveted iron plates and
##                thin lava seams.
##   bridges    — the Chain Bridges: dark planks of the bridges, chain links,
##                the lava's glow between the boards.
##   cathedral  — the Cathedral of Ash: grey ash-stone flagstones, scorch marks
##                and drifts of ash.
##   throne     — the Throne: polished obsidian with gold inlay and scattered
##                bones of the proud.
## Art pass: the zone's floor tile (tiles/pandemonium_<style>.png, made with
## tools/make_tile.py) replaces the base colour and joints when its PNG exists
## (Ground header, EnvironmentArt); the decorations stay code-drawn (hashed per
## cell, no RNG). MarchDirector calls set_zone() at each zone change. The Hell
## Pits are drawn over it by HellPits, not here. Purely cosmetic: nothing here
## collides.
class_name PandemoniumGround
extends Ground

## Current zone look (a PandemoniumStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = PandemoniumStage.ZONES
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
		_courses(rect, 48.0 if style != "bridges" else 24.0, _look["line"])
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_pandemonium_cell(cx, cy, style)


## Paving courses every `step` px (joints staggered), in `col` (the code floor only).
func _courses(rect: Rect2, step: float, col: Color) -> void:
	var y := floorf(rect.position.y / step) * step
	var row := 0
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), col, 2.0)
		var x := floorf(rect.position.x / (step * 2.0)) * step * 2.0 + (step if row % 2 == 1 else 0.0)
		while x <= rect.end.x:
			draw_line(Vector2(x, y), Vector2(x, y + step), col, 1.0)
			x += step * 2.0
		y += step
		row += 1


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1818)))


## Decal key prefix of the current zone: pandemonium_<style>_.
func _decal_prefix() -> String:
	return "pandemonium_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/pandemonium_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "pandemonium_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_pandemonium_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	match style:
		"iron":
			if roll < 0.14:
				draw_rect(Rect2(p, Vector2(30, 20)), Color(PandemoniumGlyphs.IRON, 0.45))  # A riveted iron plate.
				for k in 4:
					draw_rect(Rect2(p + Vector2(2.0 + float(k % 2) * 25.0, 2.0 + float(k >> 1) * 15.0), Vector2(2, 2)), Color(PandemoniumGlyphs.IRON.lightened(0.3), 0.7))
			elif roll < 0.24:
				draw_line(p, p + Vector2(30, 5), Color(accent, 0.5), 1.0)  # A thin lava seam.
		"bridges":
			if roll < 0.2:
				draw_line(p, p + Vector2(40, 0), Color(accent, 0.35), 2.0)  # The lava's glow between two boards.
			elif roll < 0.3:
				for k in 4:
					draw_rect(Rect2(p + Vector2(float(k) * 7.0, float(k % 2)), Vector2(5, 3)), Color(PandemoniumGlyphs.IRON, 0.85))  # A chain on the boards.
		"cathedral":
			if roll < 0.16:
				draw_texture_rect(SpriteBank.disc(), Rect2(p - Vector2(16, 8), Vector2(32, 16)), false, Color(0.0, 0.0, 0.0, 0.25))  # A scorch mark.
			elif roll < 0.26:
				draw_line(p, p + Vector2(34, 0), Color(accent, 0.25), 1.0)  # A drift of ash.
				draw_line(p + Vector2(6, 2), p + Vector2(26, 2), Color(accent, 0.18), 1.0)
		_:
			if roll < 0.12:
				draw_line(p, p + Vector2(36, 0), Color(accent, 0.45), 1.0)  # Gold inlay.
				draw_line(p + Vector2(36, 0), p + Vector2(36, 12), Color(accent, 0.35), 1.0)
			elif roll < 0.2:
				draw_rect(Rect2(p, Vector2(6, 2)), Color(Palette.BONE, 0.6))  # A bone of the proud.
				draw_rect(Rect2(p + Vector2(-1, -1), Vector2(2, 4)), Color(Palette.BONE, 0.6))
