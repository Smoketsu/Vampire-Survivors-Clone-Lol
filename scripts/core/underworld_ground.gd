## UnderworldGround — the floors of THE ASPHODEL UNDERWORLD (Act IV, Stage 12;
## GDD §15.0 "The Asphodel Underworld (Act IV phase 2)"), drawn with _draw()
## like Ground (it extends it and reuses its redraw-on-cell-change logic). Each
## zone has its own floor (UnderworldStage.ZONES "ground"):
##   asphodel — grey ash scattered with pale asphodel flowers (bronze hearts).
##   styx     — dark wet sand of the river banks, pebbles and drift.
##   hall     — cracked marble flags, the Judges' Hall.
##   throne   — black obsidian veined with dull bronze.
## A zone whose ZONES row has "styx": true also shows THE RIVER STYX on top of
## its floor (UnderworldGlyphs.draw_styx(), the same geometry as
## UnderworldDirector.river_offset(), so the water is exactly where it slows
## and suppresses). Art pass: the zone's floor tile (tiles/underworld_<style>.png,
## made with tools/make_tile.py) replaces the base colour and joints when its
## PNG exists (Ground header, EnvironmentArt); the decorations stay code-drawn.
## MarchDirector calls set_zone() at each zone change. Purely cosmetic: nothing
## here collides.
class_name UnderworldGround
extends Ground

## Current zone look (an UnderworldStage.ZONES "ground" dictionary).
var _look: Dictionary = {}
## True while the current zone has the Styx.
var _styx: bool = false


func _ready() -> void:
	super._ready()
	var zones: Array = UnderworldStage.ZONES
	_look = zones[0]["ground"]
	_styx = bool(zones[0].get("styx", false))


## Switches to zone look `look` (and its Styx) and redraws at once.
func set_zone(look: Dictionary) -> void:
	_look = look
	_styx = false
	for z: Dictionary in UnderworldStage.ZONES:
		if z["ground"] == look:
			_styx = bool(z.get("styx", false))
	queue_redraw()


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(_look["style"])
	_art_floor = _draw_tiles(rect)
	if not _art_floor:
		draw_rect(rect, _look["base"])
		match style:
			"hall":
				_grid(rect, 64.0, 1.0, _look["line"])
			"throne":
				_grid(rect, 96.0, 1.0, _look["line"])
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_underworld_cell(cx, cy, style)
	if _styx:
		UnderworldGlyphs.draw_styx(self, rect, UnderworldStage.UNDERWORLD["styx"], 0.0)


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
	return absi(hash(Vector3i(cx, cy, 1212)))


## Decal key prefix of the current zone: underworld_<style>_.
func _decal_prefix() -> String:
	return "underworld_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/underworld_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "underworld_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_underworld_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var glow: Color = _look["glow"]
	match style:
		"asphodel":
			if roll < 0.3:
				# A clump of asphodel: pale six-petalled stars with bronze hearts.
				for i in 3 + h % 3:
					var q := p + Vector2(float((h >> (i * 3)) % 24) - 12.0, float((h >> (i * 3 + 5)) % 16) - 8.0)
					draw_line(q, q + Vector2(0, 7), Color(0.22, 0.24, 0.22), 1.0)  # Stem.
					draw_circle(q, 2.2, Color(accent, 0.85))
					draw_circle(q, 0.9, glow)
			elif roll < 0.36:
				draw_circle(p, 34.0 + float(h % 24), Color(0.6, 0.6, 0.62, 0.05))  # A low mist patch (soft: code-drawn on tiles too).
		"styx":
			if roll < 0.14:
				for i in 4:
					draw_circle(p + Vector2(float(i) * 5.0, float((h >> i) % 5)), 1.6, Color(accent, 0.6))  # Pebbles.
			elif roll < 0.2:
				draw_line(p, p + Vector2(22, 4), Color(0.18, 0.15, 0.12, 0.8), 2.0)  # A piece of driftwood (an old oar).
		"hall":
			if roll < 0.14:
				draw_polyline(PackedVector2Array([p, p + Vector2(10, 6), p + Vector2(16, 3), p + Vector2(28, 11)]), Color(0.05, 0.05, 0.06, 0.7), 1.0)  # A crack.
			elif roll < 0.18:
				draw_rect(Rect2(p, Vector2(20, 20)), Color(accent, 0.12))  # A paler flagstone.
		_:
			if roll < 0.14:
				var horizontal := (h >> 5) % 2 == 0
				var b := p + (Vector2(44, 0) if horizontal else Vector2(0, 44))
				draw_line(p, b, Color(glow, 0.3), 2.0)  # A bronze vein in the obsidian.
			elif roll < 0.18:
				draw_circle(p, 3.0, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.25))  # A cold soul ember.
