## TwoTruthsGround — the floors of THE HALL OF TWO TRUTHS (temporary Act XII, the
## Necropolis Dynasty's finale; GDD §15.0 "The Hall of Two Truths (Necropolis
## Dynasty phase 2)"), drawn with _draw() like Ground (it extends it and reuses
## its redraw-on-cell-change logic). Each zone has its own floor
## (TwoTruthsStage.ZONES "ground"), the art pass's tiles/two_truths_<style>:
##   reeds  — the Gate of Reeds: reed mud;
##   fire   — the River of Fire: basalt with glowing cracks;
##   scales — the Hall of the Scales: blue-black marble;
##   throne — the Throne of Osiris: night-blue slabs with bronze inlay.
## Without the tile PNG the zone's base colour and its seams stand in. A few
## code decorations are hashed per cell (no RNG): reed tufts, embers, lapis
## inlay. MarchDirector calls set_zone() at each zone change. Purely cosmetic:
## nothing here collides.
class_name TwoTruthsGround
extends Ground

## Current zone look (a TwoTruthsStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = TwoTruthsStage.ZONES
	_look = zones[0]["ground"]


## Switches to zone look `look` and redraws at once.
func set_zone(look: Dictionary) -> void:
	_look = look
	queue_redraw()


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	_art_floor = _draw_tiles(rect)
	if not _art_floor:
		draw_rect(rect, _look["base"])
		_seams(rect, 64.0, _look["line"])
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_hall_cell(cx, cy, String(_look["style"]))


## Slab seams every `step` px (a plain grid), in `col` (the code floor only).
func _seams(rect: Rect2, step: float, col: Color) -> void:
	var y := floorf(rect.position.y / step) * step
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), col, 1.0)
		y += step
	var x := floorf(rect.position.x / step) * step
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), col, 1.0)
		x += step


## Decal key prefix of the current zone: two_truths_<style>_.
func _decal_prefix() -> String:
	return "two_truths_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/two_truths_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "two_truths_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_hall_cell(cx: int, cy: int, style: String) -> void:
	var h := absi(hash(Vector3i(cx, cy, 3621)))
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	match style:
		"reeds":
			if roll < 0.12:
				for i in 3:
					draw_rect(Rect2(p + Vector2(float(i) * 3.0, -float(6 + i * 2)), Vector2(1.0, float(6 + i * 2))), Color(accent, 0.55))  # A reed tuft.
		"fire":
			if roll < 0.10:
				draw_texture_rect(SpriteBank.disc(), Rect2(p - Vector2(14, 6), Vector2(28, 12)), false, Color(accent, 0.16))  # The glow through a crack.
		"scales":
			if roll < 0.06:
				draw_rect(Rect2(p, Vector2(12, 2)), Color(accent, 0.35))  # A lapis inlay.
		_:
			if roll < 0.07:
				draw_rect(Rect2(p, Vector2(10, 10)), Color(accent, 0.18))  # A bronze inlay square.
