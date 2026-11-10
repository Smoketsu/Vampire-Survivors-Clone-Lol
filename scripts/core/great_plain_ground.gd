## GreatPlainGround — the floor of THE GREAT PLAIN (temporary Act XIV, the Age
## of Titans; GDD §15.0 "The Great Plain (Act XIV phase 2)": "open grassland
## under a hot sky"), drawn with _draw() like Ground (it extends it and reuses
## its redraw-on-cell-change logic). Each zone has its own floor
## (GreatPlainStage.ZONES "ground") over the `plain` style:
##   dust_flats    — dry grass tufts and dust.
##   watering_hole — greener grass, mud and hoof prints.
##   canyon        — red rock, cracks and scree.
##   bone_gate     — bleached earth, scattered bones.
## The watering hole itself is GreatPlainDirector's (it moves). Art pass: the
## zone's floor tile (tiles/great_plain_<style>.png, docs/titans/ART_MANIFEST.md)
## replaces the base colour when its PNG exists (Ground header, EnvironmentArt);
## the decorations stay code-drawn, sparse and flat (disc textures and rects:
## the layer redraws only on a cell change). MarchDirector calls set_zone() at
## each zone change. Purely cosmetic: nothing here collides or slows.
class_name GreatPlainGround
extends Ground

## Current zone look (a GreatPlainStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = GreatPlainStage.ZONES
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
			_draw_site_cell(cx, cy)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 4141)))


## Decal key prefix of the current zone: great_plain_<style>_.
func _decal_prefix() -> String:
	return "great_plain_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/great_plain_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "great_plain_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone (disc
## textures and rects only).
func _draw_site_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	var line: Color = _look["line"]
	match String(_look["style"]):
		"dust_flats":
			if roll < 0.2:
				for i in 3:
					draw_rect(Rect2(p + Vector2(float(i) * 3.0, -float(i % 2) * 2.0), Vector2(1.0, 6.0)), Color(accent, 0.45))  # A grass tuft.
			elif roll < 0.3:
				SpriteBank.draw_disc(self, p, 14.0 + float(h % 10), Color(line, 0.5))  # Dust.
		"watering_hole":
			if roll < 0.18:
				for i in 3:
					draw_rect(Rect2(p + Vector2(float(i) * 3.0, -float(i % 2) * 2.0), Vector2(1.0, 7.0)), Color(accent, 0.5))  # Green grass.
			elif roll < 0.28:
				SpriteBank.draw_disc(self, p, 3.0, Color(trim, 0.55))  # A hoof print.
				SpriteBank.draw_disc(self, p + Vector2(6.0, 3.0), 3.0, Color(trim, 0.45))
		"canyon":
			if roll < 0.14:
				draw_rect(Rect2(p, Vector2(12.0, 1.5)), Color(trim, 0.5))  # A crack.
				draw_rect(Rect2(p + Vector2(10.0, 1.5), Vector2(1.5, 6.0)), Color(trim, 0.4))
			elif roll < 0.24:
				SpriteBank.draw_disc(self, p, 2.5 + float(h % 2), Color(accent, 0.55))  # Scree.
		_:
			if roll < 0.12:
				draw_rect(Rect2(p, Vector2(10.0, 2.0)), Color(accent, 0.35))  # A bleached bone.
				SpriteBank.draw_disc(self, p + Vector2(10.0, 1.0), 2.0, Color(accent, 0.35))
			elif roll < 0.22:
				SpriteBank.draw_disc(self, p, 14.0 + float(h % 8), Color(line, 0.5))  # Pale earth.
