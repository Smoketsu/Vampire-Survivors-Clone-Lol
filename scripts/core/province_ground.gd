## ProvinceGround — the procedural floor of the Burning Province (Act V, Stage
## 13; GDD §15.0 "The Burning Province (Act V phase 2)": "rice terraces, bamboo
## groves, a village in flames"), drawn with _draw() like Ground (it extends it
## and reuses its redraw-on-cell-change logic). Each zone has its own floor
## (ProvinceStage.ZONES "ground"):
##   paddies — the Paddies: dark mud on the dikes between the flooded terraces.
##   bamboo  — the Bamboo Grove: leaf litter and roots on dark earth.
##   village — the Burning Village: trampled earth, ash and cinders.
##   shrine  — the Mountain Shrine: raked gravel and stepping stones.
## Art pass: the zone's floor tile (tiles/province_<style>.png) replaces the
## base colour when its PNG exists (Ground header, EnvironmentArt); the rest
## stays code-drawn and sparse (a rice shoot, a fallen leaf, an ember, a petal).
## THE PADDY WATER: on a zone whose ground has a "paddy" share, every flooded
## terrace cell (ProvinceDirector.cell_flooded(), the same geometry that slows
## the bodies in it) shows its still water inside the dike, with rows of rice
## shoots. Drawn only when the floor redraws (a cell change), never per frame.
## MarchDirector calls set_zone() at each zone change. Purely cosmetic: nothing
## here collides.
class_name ProvinceGround
extends Ground

## Paddy water colour (dark indigo-green, low alpha over the floor).
const WATER := Color(0.12, 0.20, 0.26, 0.78)
## Rim of the water along the dike.
const WATER_RIM := Color(0.24, 0.34, 0.40, 0.8)

## Current zone look (a ProvinceStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = ProvinceStage.ZONES
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
	var share := float(_look.get("paddy", 0.0))
	if share > 0.0:
		_paddies(rect, share)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_province_cell(cx, cy, style)


## The flooded terraces inside `rect` (ProvinceDirector's geometry).
func _paddies(rect: Rect2, share: float) -> void:
	var cfg: Dictionary = ProvinceStage.PROVINCE
	var cell := float(cfg["paddy_cell"])
	var dike := float(cfg["paddy_dike"])
	var shoot: Color = _look["accent"]
	var glint: Color = _look["trim"]
	var x0 := floori(rect.position.x / cell)
	var y0 := floori(rect.position.y / cell)
	var x1 := floori(rect.end.x / cell)
	var y1 := floori(rect.end.y / cell)
	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			if not ProvinceDirector.cell_flooded(cx, cy, share):
				continue
			var w := Rect2(Vector2(float(cx), float(cy)) * cell + Vector2(dike, dike), Vector2(cell - dike * 2.0, cell - dike * 2.0))
			draw_rect(w.grow(2.0), WATER_RIM)
			draw_rect(w, WATER)
			var y := w.position.y + 14.0
			var row := 0
			while y < w.end.y - 8.0:  # Rows of rice shoots standing in the water.
				var x := w.position.x + 10.0 + float(row % 2) * 9.0
				while x < w.end.x - 8.0:
					draw_rect(Rect2(Vector2(x, y), Vector2(2.0, 4.0)), Color(shoot, 0.85))
					x += 18.0
				y += 16.0
				row += 1
			draw_line(w.position + Vector2(6.0, 5.0), w.position + Vector2(w.size.x * 0.4, 5.0), Color(glint, 0.35), 1.0)  # A glint on the water.


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1313)))


## Decal key prefix of the current zone: province_<style>_.
func _decal_prefix() -> String:
	return "province_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/province_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "province_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_province_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	var line: Color = _look["line"]
	if _art_floor and roll < 0.1:
		return  # The tile already has its own stones and cracks.
	if roll < 0.07:
		var w := 5.0 + float(h % 7)  # px.
		draw_rect(Rect2(p, Vector2(w, w * 0.6).round()), Color(accent, 0.45))  # A stone / a clod.
	elif roll < 0.1:
		draw_polyline(PackedVector2Array([p, p + Vector2(8, 3), p + Vector2(13, -2), p + Vector2(22, 4)]), Color(line, 0.9), 1.5)  # A crack / a rut.
	elif roll < 0.17 and style == "bamboo":
		draw_line(p, p + Vector2(7, -2), Color(trim, 0.7), 2.0)  # A fallen bamboo leaf.
	elif roll < 0.16 and style == "village":
		draw_rect(Rect2(p, Vector2(2, 2)), Color(trim, 0.8))  # An ember.
	elif roll < 0.15 and style == "shrine":
		draw_rect(Rect2(p, Vector2(3, 2)), Color(trim, 0.7))  # A sakura petal.
	elif roll < 0.15 and style == "paddies":
		draw_rect(Rect2(p, Vector2(2, 4)), Color(accent, 0.7))  # A rice shoot on the dike.
