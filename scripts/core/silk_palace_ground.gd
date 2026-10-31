## SilkPalaceGround — the floors of THE PALACE OF SILK AND ASH (Act VI, Stage 17;
## GDD §15.0 "The Palace of Silk and Ash (Act VI phase 2)"), drawn with _draw()
## like Ground (it extends it and reuses its redraw-on-cell-change logic). Each
## zone has its own floor (SilkPalaceStage.ZONES "ground"):
##   roses    — the Rose Garden: dark soil strewn with black rose petals and thorns.
##   mirrors  — the Hall of Mirrors: black-violet marble flags with pale glints.
##   ballroom — the Ballroom: rose marble laid over a lava lake, its glow
##              showing through the cracks.
##   chamber  — the Queen's Chamber: dark marble under velvet runners.
## Art pass: the zone's floor tile (tiles/silk_palace_<style>.png, made with
## tools/make_tile.py) replaces the base colour and joints when its PNG exists
## (Ground header, EnvironmentArt); the decorations stay code-drawn (hashed per
## cell, no RNG): textures, never polygons (the Web GL rule). MarchDirector
## calls set_zone() at each zone change. The Hell Pits are drawn over it by
## HellPits, not here. Purely cosmetic: nothing here collides.
class_name SilkPalaceGround
extends Ground

## Current zone look (a SilkPalaceStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = SilkPalaceStage.ZONES
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
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_palace_cell(cx, cy, style)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1717)))


## Decal key prefix of the current zone: silk_palace_<style>_.
func _decal_prefix() -> String:
	return "silk_palace_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/silk_palace_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "silk_palace_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_palace_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	match style:
		"roses":
			if roll < 0.24:
				for i in 3 + h % 4:
					var q := p + Vector2(float((h >> (i * 3)) % 28) - 14.0, float((h >> (i * 3 + 5)) % 18) - 9.0)
					draw_rect(Rect2(q, Vector2(2, 2)), Color(accent, 0.85))  # Fallen black-rose petals.
			elif roll < 0.3:
				draw_rect(Rect2(p, Vector2(8, 1)), Color(0.04, 0.03, 0.05, 0.9))  # A thorny twig.
		"mirrors":
			if roll < 0.12:
				draw_rect(Rect2(p, Vector2(2, 2)), Color(accent, 0.7))  # A glint off the polished floor.
				draw_rect(Rect2(p + Vector2(3, 3), Vector2(1, 1)), Color(accent, 0.5))
		"ballroom":
			if roll < 0.16:
				draw_texture_rect(SpriteBank.disc(), Rect2(p - Vector2(22, 9), Vector2(44, 18)), false, Color(accent, 0.10))  # The lava lake glowing up through the marble.
			elif roll < 0.22:
				draw_rect(Rect2(p, Vector2(10, 1)), Color(accent, 0.45))  # A crack with the fire below.
		_:
			if roll < 0.18:
				draw_rect(Rect2(p, Vector2(2, 2)), Color(Palette.INFERNO_CHARM, 0.35))  # A fallen rose petal on the velvet.
