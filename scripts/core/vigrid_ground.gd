## VigridGround — the floors of VIGRID, THE LAST FIELD (the Hall of the Slain,
## temporarily Act XI, Stage 18 in the final order; GDD §15.0 "Vigrid, the
## Last Field (phase 2)"), drawn with _draw() like Ground (it extends it and
## reuses its redraw-on-cell-change logic). Each zone has its own floor
## (VigridStage.ZONES "ground"):
##   ice — the Frozen Sea: the art pass's fjord ice (tiles/norse_ice), cracks
##         and pale snow drifts.
##   ash — the Ash Plain, the Giants' March and the Field of Vigrid: the art
##         pass's Vigrid ash (tiles/norse_ash), cracks and embers, more of
##         them as the field burns (the zone look's "embers" share).
## The zone's floor tile replaces the base colour when its PNG exists (Ground
## header, EnvironmentArt); the decorations stay code-drawn (hashed per cell, no
## RNG; small textures and rects). MarchDirector calls set_zone() at each zone
## change. Purely cosmetic: nothing here collides.
class_name VigridGround
extends Ground

## Current zone look (a VigridStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = VigridStage.ZONES
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
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_vigrid_cell(cx, cy)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1818)))


## Floor tile key of the current zone: tiles/norse_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "norse_" + String(_look["style"])


## Decal key prefix of the current zone: vigrid_<style>_ (none exist: the
## decorations are code-drawn).
func _decal_prefix() -> String:
	return "vigrid_" + String(_look["style"]) + "_"


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_vigrid_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var line: Color = _look["line"]
	var accent: Color = _look["accent"]
	if String(_look["style"]) == "ice":
		if roll < 0.12:
			draw_rect(Rect2(p, Vector2(20.0, 1.0)), Color(line, 0.6))  # A crack in the ice.
			draw_rect(Rect2(p + Vector2(8.0, 1.0), Vector2(1.0, 6.0)), Color(line, 0.5))
		elif roll < 0.2:
			SpriteBank.draw_disc(self, p, 9.0 + float(h % 8), Color(accent, 0.3))  # A snow drift on the ice.
		return
	var embers := float(_look.get("embers", 0.06))  # Share of cells with an ember (more as the field burns).
	if roll < 0.12:
		draw_rect(Rect2(p, Vector2(18.0, 1.0)), Color(line, 0.7))  # A crack in the ash.
	elif roll < 0.12 + embers:
		draw_rect(Rect2(p, Vector2(3.0, 2.0)), Color(accent, 0.75))  # An ember.
		SpriteBank.draw_disc(self, p + Vector2(1.5, 1.0), 5.0, Color(accent, 0.12))
	elif roll < 0.2 + embers:
		SpriteBank.draw_disc(self, p, 8.0 + float(h % 6), Color(line, 0.3))  # A drift of ash.
