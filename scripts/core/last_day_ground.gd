## LastDayGround — the floor of THE LAST DAY (temporary Act XIV, the Age of
## Titans' finale; GDD §15.0 "The Last Day (Act XIV phase 2)": "the impact
## basin; the sky is white, ash falls"), drawn with _draw() like Ground (it
## extends it and reuses its redraw-on-cell-change logic). Each zone has its
## own floor (LastDayStage.ZONES "ground") over the `ash` style:
##   scorched_plain — scorched earth and ash drifts.
##   ash_forest     — grey ash, burnt stumps (flat, not obstacles).
##   lava_fields    — black crust with glowing cracks.
##   impact_rim     — pale shattered rock, bleached by the white sky.
## Art pass: the zone's floor tile (tiles/last_day_<style>.png,
## docs/titans/ART_MANIFEST.md) replaces the base colour when its PNG exists
## (Ground header, EnvironmentArt); the decorations stay code-drawn, sparse
## and flat (disc textures and rects: the layer redraws only on a cell
## change). MarchDirector calls set_zone() at each zone change. Purely
## cosmetic: nothing here collides, slows or burns.
class_name LastDayGround
extends Ground

## Current zone look (a LastDayStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = LastDayStage.ZONES
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
	return absi(hash(Vector3i(cx, cy, 4242)))


## Decal key prefix of the current zone: last_day_<style>_.
func _decal_prefix() -> String:
	return "last_day_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/last_day_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "last_day_" + String(_look["style"])


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
		"scorched_plain":
			if roll < 0.2:
				SpriteBank.draw_disc(self, p, 12.0 + float(h % 10), Color(line, 0.5))  # An ash drift.
			elif roll < 0.28:
				draw_rect(Rect2(p, Vector2(10.0, 1.5)), Color(trim, 0.5))  # A scorch crack.
		"ash_forest":
			if roll < 0.14:
				SpriteBank.draw_disc(self, p, 5.0, Color(trim, 0.7))  # A burnt stump, seen from above.
				SpriteBank.draw_disc(self, p, 2.5, Color(accent, 0.25))
			elif roll < 0.3:
				SpriteBank.draw_disc(self, p, 16.0 + float(h % 8), Color(line, 0.45))  # Grey ash.
		"lava_fields":
			if roll < 0.16:
				draw_rect(Rect2(p, Vector2(12.0, 2.0)), Color(accent, 0.55))  # A glowing crack.
				draw_rect(Rect2(p + Vector2(10.0, 2.0), Vector2(2.0, 6.0)), Color(accent, 0.4))
			elif roll < 0.26:
				SpriteBank.draw_disc(self, p, 10.0 + float(h % 6), Color(trim, 0.6))  # Black crust.
		_:
			if roll < 0.14:
				draw_rect(Rect2(p, Vector2(9.0, 2.0)), Color(accent, 0.35))  # Shattered pale rock.
				draw_rect(Rect2(p + Vector2(3.0, 3.0), Vector2(6.0, 2.0)), Color(accent, 0.25))
			elif roll < 0.24:
				SpriteBank.draw_disc(self, p, 14.0 + float(h % 8), Color(line, 0.5))  # Bleached dust.
