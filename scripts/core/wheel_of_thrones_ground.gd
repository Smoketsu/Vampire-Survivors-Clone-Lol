## WheelOfThronesGround — the floor of THE WHEEL OF THRONES (temporary Act XIII,
## the Celestial Host; GDD §15.0 "The Wheel of Thrones (Act XIII phase 2)":
## "the turning spheres of heaven"), drawn with _draw() like Ground (it extends
## it and reuses its redraw-on-cell-change logic). Each zone has its own floor
## (WheelOfThronesStage.ZONES "ground"), all over the `wheel` style: a deep sky
## crossed by a faint celestial grid whose lines lie `grid` px apart:
##   moon  — the Sphere of the Moon: pale silver dust on night blue.
##   sun   — the Sphere of the Sun: a lighter sky with pale motes of light.
##   stars — the Sphere of the Stars: deep star-blue with scattered stars.
##   core  — the Wheel: dark blue with silver rim lines.
## Art pass: the zone's floor tile (tiles/wheel_<style>.png,
## docs/host/ART_MANIFEST.md) replaces the base colour and the grid when its
## PNG exists (Ground header, EnvironmentArt); the decorations stay code-drawn,
## sparse and flat. The turning crystal rings are not drawn here
## (WheelOfThronesDirector draws them above the floor). MarchDirector calls
## set_zone() at each zone change. Purely cosmetic: nothing here collides.
class_name WheelOfThronesGround
extends Ground

## Current zone look (a WheelOfThronesStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = WheelOfThronesStage.ZONES
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
		var grid := float(_look["grid"])  # px between two lines of the celestial grid.
		var x := floorf(rect.position.x / grid) * grid
		while x <= rect.end.x:
			draw_rect(Rect2(Vector2(x, rect.position.y), Vector2(1.0, rect.size.y)), _look["line"])
			x += grid
		var y := floorf(rect.position.y / grid) * grid
		while y <= rect.end.y:
			draw_rect(Rect2(Vector2(rect.position.x, y), Vector2(rect.size.x, 1.0)), _look["line"])
			y += grid
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_site_cell(cx, cy)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 3838)))


## Decal key prefix of the current zone: wheel_<style>_.
func _decal_prefix() -> String:
	return "wheel_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/wheel_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "wheel_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone (disc
## textures and rects only).
func _draw_site_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	match String(_look["style"]):
		"moon":
			if roll < 0.12:
				SpriteBank.draw_disc(self, p, 4.0 + float(h % 4), Color(accent, 0.18))  # Silver dust.
		"sun":
			if roll < 0.1:
				SpriteBank.draw_disc(self, p, 6.0 + float(h % 6), Color(Palette.HOST_STARLIGHT, 0.12))  # A mote of light.
			elif roll < 0.14:
				draw_rect(Rect2(p, Vector2(14.0, 1.0)), Color(accent, 0.3))
		"stars":
			if roll < 0.2:
				SpriteBank.draw_disc(self, p, 1.5 + float(h % 2), Color(Palette.HOST_STARLIGHT, 0.6))  # A star.
			elif roll < 0.24:
				SpriteBank.draw_disc(self, p, 3.0, Color(trim, 0.45))  # A blue star.
		_:
			if roll < 0.1:
				draw_rect(Rect2(p, Vector2(22.0, 2.0)), Color(accent, 0.3))  # A silver rim line.
			elif roll < 0.13:
				SpriteBank.draw_disc(self, p, 3.0, Color(trim, 0.4))  # An eye of light in the rim.
