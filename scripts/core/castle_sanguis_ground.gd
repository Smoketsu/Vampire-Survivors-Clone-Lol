## CastleSanguisGround — the floors of CASTLE SANGUIS (Act VII, Stage 21; GDD
## §15.0 "Castle Sanguis (Act VII phase 2)"), drawn with _draw() like Ground
## (it extends it and reuses its redraw-on-cell-change logic). Each zone has
## its own floor (CastleSanguisStage.ZONES "ground"):
##   courtyard — the Courtyard: moonlit grey flagstones, tufts of moss and
##               fallen bat feathers.
##   banquet   — the Banquet Hall: dark boards under long blood-red runners,
##               spilt wine.
##   crypt     — the Crypt Gallery: cold slabs, scattered bones and candle stubs.
##   throne    — the Throne of Blood: black marble veined red, gold inlay and
##               pooled blood.
## Art pass: the zone's floor tile (tiles/castle_sanguis_<style>.png, made with
## tools/make_tile.py) replaces the base colour and joints when its PNG exists
## (Ground header, EnvironmentArt); the decorations stay code-drawn (hashed per
## cell, no RNG). MarchDirector calls set_zone() at each zone change. The blood
## fountains are drawn over it by CastleSanguisDirector, not here. Purely
## cosmetic: nothing here collides.
class_name CastleSanguisGround
extends Ground

## Current zone look (a CastleSanguisStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = CastleSanguisStage.ZONES
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
		_courses(rect, 40.0 if style != "banquet" else 20.0, _look["line"])
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_castle_cell(cx, cy, style)


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
	return absi(hash(Vector3i(cx, cy, 2121)))


## Decal key prefix of the current zone: castle_sanguis_<style>_.
func _decal_prefix() -> String:
	return "castle_sanguis_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/castle_sanguis_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "castle_sanguis_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_castle_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	match style:
		"courtyard":
			if roll < 0.12:
				draw_rect(Rect2(p, Vector2(8, 3)), Color(0.20, 0.28, 0.20, 0.55))  # A tuft of moss between the stones.
				draw_rect(Rect2(p + Vector2(2, -2), Vector2(4, 2)), Color(0.24, 0.34, 0.24, 0.5))
			elif roll < 0.2:
				draw_line(p, p + Vector2(6, -3), Color(accent, 0.55), 1.0)  # A fallen bat feather.
		"banquet":
			if roll < 0.18:
				draw_rect(Rect2(Vector2(float(cx) * CELL, p.y), Vector2(CELL, 10)), Color(accent, 0.35))  # The long red runner.
			elif roll < 0.27:
				draw_texture_rect(SpriteBank.disc(), Rect2(p - Vector2(10, 5), Vector2(20, 10)), false, Color(Palette.COURT_BLOOD_DARK, 0.5))  # Spilt wine.
		"crypt":
			if roll < 0.12:
				draw_rect(Rect2(p, Vector2(7, 2)), Color(accent, 0.55))  # A bone.
				draw_rect(Rect2(p + Vector2(-1, -1), Vector2(2, 4)), Color(accent, 0.55))
			elif roll < 0.18:
				draw_rect(Rect2(p, Vector2(3, 5)), Color(0.80, 0.76, 0.62, 0.6))  # A candle stub.
				draw_rect(Rect2(p + Vector2(1, -2), Vector2(1, 2)), Color(Palette.GOLD, 0.8))
		_:
			if roll < 0.12:
				draw_line(p, p + Vector2(36, 0), Color(accent, 0.4), 1.0)  # Gold inlay.
				draw_line(p + Vector2(36, 0), p + Vector2(36, 12), Color(accent, 0.3), 1.0)
			elif roll < 0.2:
				draw_texture_rect(SpriteBank.disc(), Rect2(p - Vector2(12, 6), Vector2(24, 12)), false, Color(Palette.COURT_BLOOD_DARK, 0.55))  # Pooled blood.
			elif roll < 0.26:
				draw_line(p, p + Vector2(18, 7), Color(Palette.COURT_BLOOD, 0.35), 1.0)  # A red vein in the marble.
