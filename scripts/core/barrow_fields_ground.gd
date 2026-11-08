## BarrowFieldsGround — the procedural floor of the Barrow Fields (the Hall of
## the Slain, temporarily Act XI, Stage 16 in the final order; GDD §15.0 "The
## Barrow Fields (the Hall of the Slain phase 2)": "snowfields of burial mounds
## above a frozen fjord"), drawn with _draw() like Ground (it extends it and
## reuses its redraw-on-cell-change logic). Each zone has its own floor
## (BarrowFieldsStage.ZONES "ground"):
##   snow — the Longshore, the Barrows and the Jarl's Hall: night snow
##          (tiles/norse_snow).
##   ice  — the Frozen Fjord: the fjord's ice (tiles/norse_ice).
## Art: the zone's floor tile (tiles/norse_<style>.png, the art pass's 128 px
## seamless tiles) replaces the base colour when its PNG exists (Ground header,
## EnvironmentArt); the rest stay code-drawn, sparse and flat (a tuft of dead
## grass, a frozen puddle, a crack in the ice, a rune-scratched stone).
## MarchDirector calls set_zone() at each zone change. Purely cosmetic: nothing
## here collides (the Fjord's drifts are BarrowFieldsDirector's).
class_name BarrowFieldsGround
extends Ground

## Current zone look (a BarrowFieldsStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = BarrowFieldsStage.ZONES
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
			_draw_field_cell(cx, cy)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1616)))


## Decal key prefix of the current zone: norse_<style>_.
func _decal_prefix() -> String:
	return "norse_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/norse_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "norse_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_field_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	match String(_look["style"]):
		"ice":
			if roll < 0.06:
				draw_rect(Rect2(p, Vector2(12.0 + float(h % 10), 1.0)), Color(trim, 0.45))  # A crack in the ice.
			elif roll < 0.08:
				draw_rect(Rect2(p, Vector2(3, 3)), Color(accent, 0.5))  # A trapped bubble.
		_:
			if roll < 0.05:
				draw_rect(Rect2(p, Vector2(2, 4)), Color(accent, 0.6))  # A tuft of dead grass through the snow.
			elif roll < 0.075:
				draw_rect(Rect2(p, Vector2(8.0 + float(h % 6), 3.0)), Color(trim, 0.3))  # A frozen puddle.
