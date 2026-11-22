## LionessTempleGround — the floor of the Temple of the Lioness (temporary Act
## XII, Stage 35, final stage 20; GDD §15.0 "The Temple of the Lioness
## (Dynasty phase 2)": "a sun-baked temple of colonnades and statue-lined
## courts, sacred to the goddess of war and plague"), drawn with _draw() like
## Ground (it extends it and reuses its redraw-on-cell-change logic). Each
## zone has its own floor (LionessTempleStage.ZONES "ground"), over the
## foundation's "temple" style:
##   avenue     — the Avenue of Statues: processional slabs with bronze inlay.
##   courtyard  — the Courtyard: a sun-bleached checker court.
##   hypostyle  — the Hypostyle Hall: dark slabs with glyph dashes.
##   sanctuary  — the Sanctuary: red-tinted slabs, a faint sun ring.
## Art pass: the zone's floor tile (tiles/lioness_temple_<style>.png, the
## Dynasty art) replaces the base colour (Ground header, EnvironmentArt); the
## decorations are code shapes (cracks, inlay bands, sun rings) kept sparse.
## MarchDirector calls set_zone() at each zone change. The quicksand is drawn
## above it by Quicksand. Purely cosmetic: nothing here collides.
class_name LionessTempleGround
extends Ground

## Current zone look (a LionessTempleStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = LionessTempleStage.ZONES
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
			_draw_temple_cell(cx, cy)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 3535)))


## Decal key prefix of the current zone: lioness_temple_<style>_.
func _decal_prefix() -> String:
	return "lioness_temple_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/lioness_temple_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "lioness_temple_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone (kept
## sparse: the art tile carries the floor).
func _draw_temple_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	var line: Color = _look["line"]
	match String(_look["style"]):
		"sanctuary":
			if roll < 0.05:
				SpriteBank.draw_disc(self, p, 20.0, Color(trim, 0.16))  # A faint sun ring.
				SpriteBank.draw_disc(self, p, 16.0, Color(_look["base"], 0.5 if _art_floor else 1.0))
			elif roll < 0.12:
				draw_line(p, p + Vector2(18.0, float(h % 5) - 2.0), Color(line, 0.6), 1.0)  # A crack.
		"hypostyle":
			if roll < 0.12:
				for k in 3:
					draw_rect(Rect2(p + Vector2(float(k) * 7.0, 0.0), Vector2(4.0, 2.0)), Color(trim, 0.45))  # Glyph dashes.
			elif roll < 0.18:
				SpriteBank.draw_disc(self, p, 9.0 + float(h % 6), Color(0.0, 0.0, 0.0, 0.18))  # A worn hollow.
		"courtyard":
			if roll < 0.08:
				draw_rect(Rect2(p, Vector2(10.0 + float(h % 8), 6.0)), Color(accent, 0.45))  # A sun-bleached stone.
			elif roll < 0.16:
				draw_line(p, p + Vector2(18.0, float(h % 5) - 2.0), Color(line, 0.6), 1.0)  # A crack.
		_:
			if roll < 0.08:
				draw_rect(Rect2(p, Vector2(26.0, 3.0)), Color(trim, 0.5))  # A bronze inlay band.
			elif roll < 0.14:
				draw_line(p, p + Vector2(18.0, float(h % 5) - 2.0), Color(line, 0.6), 1.0)  # A crack.
