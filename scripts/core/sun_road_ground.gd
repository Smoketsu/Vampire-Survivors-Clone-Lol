## SunRoadGround — the floors of THE ROAD TO THE SUN (Act V, Stage 15; GDD §15.0
## "The Road to the Sun (Act V phase 2)"), drawn with _draw() like Ground (it
## extends it and reuses its redraw-on-cell-change logic). Each zone has its own
## floor (SunRoadStage.ZONES "ground"):
##   torii   — the Torii Road: a pilgrim road of packed earth and raked gravel,
##             fallen sakura petals.
##   forest  — the Sacred Forest: dark moss and cedar needles, roots and ferns.
##   steps   — the Shrine Steps: worn grey stone steps in long courses.
##   heaven  — the High Plain of Heaven: pale gold-white ground above the
##             clouds, drifting cloud wisps.
## Art pass: the zone's floor tile (tiles/sun_road_<style>.png, made with
## tools/make_tile.py) replaces the base colour and joints when its PNG exists
## (Ground header, EnvironmentArt); the decorations stay code-drawn (hashed per
## cell, no RNG). MarchDirector calls set_zone() at each zone change. The Sun's
## Course's darkness and dusk wash are drawn over it by SunCourse, not here.
## Purely cosmetic: nothing here collides.
class_name SunRoadGround
extends Ground

## Current zone look (a SunRoadStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = SunRoadStage.ZONES
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
		if style == "steps":
			_courses(rect, 48.0, _look["line"])
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_sun_road_cell(cx, cy, style)


## Long stone step courses every `step` px (joints staggered), in `col`.
func _courses(rect: Rect2, step: float, col: Color) -> void:
	var y := floorf(rect.position.y / step) * step
	var row := 0
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), col, 2.0)
		var x := floorf(rect.position.x / (step * 3.0)) * step * 3.0 + (step * 1.5 if row % 2 == 1 else 0.0)
		while x <= rect.end.x:
			draw_line(Vector2(x, y), Vector2(x, y + step), col, 1.0)
			x += step * 3.0
		y += step
		row += 1


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1515)))


## Decal key prefix of the current zone: sun_road_<style>_.
func _decal_prefix() -> String:
	return "sun_road_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/sun_road_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "sun_road_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_sun_road_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	match style:
		"torii":
			if roll < 0.22:
				for i in 3 + h % 4:
					var q := p + Vector2(float((h >> (i * 3)) % 28) - 14.0, float((h >> (i * 3 + 5)) % 18) - 9.0)
					draw_rect(Rect2(q, Vector2(2, 2)), Color(accent, 0.8))  # Fallen sakura petals.
			elif roll < 0.3:
				for i in 4:
					draw_rect(Rect2(p + Vector2(float(i) * 5.0, float((h >> i) % 4)), Vector2(2, 2)), Color(0.55, 0.53, 0.49, 0.7))  # Gravel.
		"forest":
			if roll < 0.18:
				for i in 3:
					var a := -PI * 0.5 + (float(i) - 1.0) * 0.6
					draw_line(p, p + Vector2.from_angle(a) * 9.0, Color(accent, 0.7), 2.0)  # A fern.
			elif roll < 0.26:
				draw_line(p, p + Vector2(26, 6), Color(0.22, 0.15, 0.10, 0.8), 3.0)  # A root.
		"steps":
			if roll < 0.14:
				draw_rect(Rect2(p, Vector2(10, 3)), Color(accent, 0.5))  # Moss in a joint.
			elif roll < 0.18:
				draw_rect(Rect2(p, Vector2(2, 2)), Color(Palette.SHOGUN_SAKURA, 0.8))  # A petal blown up the steps.
		_:
			if roll < 0.2:
				draw_texture_rect(SpriteBank.disc(), Rect2(p - Vector2(30, 12), Vector2(60, 24)), false, Color(1.0, 1.0, 1.0, 0.10))  # A drifting cloud wisp.
			elif roll < 0.26:
				draw_rect(Rect2(p, Vector2(2, 2)), Color(accent, 0.8))  # A gold speck of sunlight.
