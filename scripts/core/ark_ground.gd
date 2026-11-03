## ArkGround — the floors of THE ARK OF THE CONCORD (Act IX, Stage 27; GDD
## §15.0 "The Ark of the Concord (Act IX phase 2)"), drawn with _draw() like
## Ground (it extends it and reuses its redraw-on-cell-change logic). Each
## zone has its own floor (ArkStage.ZONES "ground"), over the mothership's
## hull:
##   hangar  — the Hangar: hull-white deck plates in courses, painted landing
##             marks (plasma-green chevrons and circles).
##   vaults  — the Specimen Vaults: dark gunmetal deck between rows of sunken
##             specimen tanks (green-lit glass discs in a row).
##   reactor — the Reactor: a glowing plasma grating, the light coming up
##             through the bars.
##   bridge  — the Bridge of Stars: black starfield glass under thin gunmetal
##             ribs, stars and a slow nebula drift beneath.
## Art pass: the zone's floor tile (tiles/ark_<style>.png, drawn on the grid
## by tools/ark_tiles.py) replaces the base colour and seams when its PNG
## exists (Ground header, EnvironmentArt); the decorations stay code-drawn
## (hashed per cell, no RNG). MarchDirector calls set_zone() at each zone
## change. The alien turf is drawn above it by Terraforming. Purely cosmetic:
## nothing here collides.
class_name ArkGround
extends Ground

## Current zone look (an ArkStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = ArkStage.ZONES
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
		_seams(rect, 64.0 if style != "reactor" else 16.0, _look["line"])
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_ark_cell(cx, cy, style)


## Plate seams every `step` px (a plain grid), in `col` (the code floor only).
func _seams(rect: Rect2, step: float, col: Color) -> void:
	var y := floorf(rect.position.y / step) * step
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), col, 1.0)
		y += step
	var x := floorf(rect.position.x / step) * step
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), col, 1.0)
		x += step


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 2727)))


## Decal key prefix of the current zone: ark_<style>_.
func _decal_prefix() -> String:
	return "ark_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/ark_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "ark_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_ark_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	match style:
		"hangar":
			if roll < 0.06:
				draw_texture_rect(SpriteBank.disc(), Rect2(p - Vector2(22, 10), Vector2(44, 20)), false, Color(accent, 0.12))  # A landing pad's glow.
			elif roll < 0.12:
				draw_rect(Rect2(p, Vector2(24, 3)), Color(accent, 0.45))  # A painted guide line.
		"vaults":
			if roll < 0.08:
				draw_texture_rect(SpriteBank.disc(), Rect2(p - Vector2(10, 5), Vector2(20, 10)), false, Color(accent, 0.18))  # Spilt specimen fluid.
		"reactor":
			if roll < 0.14:
				draw_texture_rect(SpriteBank.disc(), Rect2(p - Vector2(18, 8), Vector2(36, 16)), false, Color(accent, 0.14))  # The glow through the bars.
		_:
			if roll < 0.18:
				draw_rect(Rect2(p, Vector2(1, 1)), Color(Palette.CONCORD_HULL, 0.7))  # A far star under the glass.
			elif roll < 0.21:
				draw_rect(Rect2(p, Vector2(2, 2)), Color(Palette.CONCORD_LUMEN, 0.6))  # A bright star.
