## IlionGround — the procedural floor of the Shores of Ilion (Act IV, Stage 10;
## GDD §15.0 "The Shores of Ilion (Act IV phase 2)": "the beach below a
## besieged city: beached warships, a siege camp, and the great walls of
## Troy"), drawn with _draw() like Ground (it extends it and reuses its
## redraw-on-cell-change logic). Each zone has its own floor (IlionStage.ZONES
## "ground"):
##   beach  — the Beachhead: dark wet sand, foam lines, shells.
##   camp   — the Siege Camp: trampled earth, straw, cart ruts.
##   gate   — the Scaean Gate: the worn flagstones of the road before the gate.
##   walls  — the Walls: cut limestone slabs at the foot of the walls of Troy.
## Art pass: the zone's floor tile (tiles/ilion_<style>.png) replaces the base
## colour and joints when its PNG exists (Ground header, EnvironmentArt); the
## stones and cracks are then left out (the tile has its own) and the rest stay
## code-drawn (sparse and flat: a foam line, a strand of straw, a bronze
## arrowhead). MarchDirector calls set_zone() at each zone change. Purely
## cosmetic: nothing here collides.
class_name IlionGround
extends Ground

## Current zone look (an IlionStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = IlionStage.ZONES
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
		if style == "gate" or style == "walls":
			_slabs(rect, 64.0 if style == "gate" else 96.0)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_ilion_cell(cx, cy, style)


## Stone slab joints every `step` px (the gate's and the walls' code floor).
func _slabs(rect: Rect2, step: float) -> void:
	var line: Color = _look["line"]
	var x := floorf(rect.position.x / step) * step
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), line, 2.0)
		x += step
	var y := floorf(rect.position.y / step) * step
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line, 2.0)
		y += step


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1010)))


## Decal key prefix of the current zone: ilion_<style>_.
func _decal_prefix() -> String:
	return "ilion_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/ilion_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "ilion_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_ilion_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	var line: Color = _look["line"]
	if _art_floor and roll < 0.12:
		return  # The tile already has its own stones and cracks.
	if roll < 0.08:
		# A stone lying flat (a pebble on the sand, a broken flag, a fallen block chip).
		var w := 6.0 + float(h % 8)  # px.
		draw_rect(Rect2(p, Vector2(w, w * 0.6).round()), Color(accent, 0.45))
	elif roll < 0.12:
		draw_polyline(PackedVector2Array([p, p + Vector2(8, 3), p + Vector2(13, -2), p + Vector2(22, 4)]), Color(line, 0.9), 1.5)  # A crack / a rut.
	elif roll < 0.20 and style == "beach":
		# A long thin foam line left by the sea.
		var w := 30.0 + float(h % 50)  # px.
		draw_line(p, p + Vector2(w, float(h % 7) - 3.0), Color(trim, 0.16), 1.5)
	elif roll < 0.18 and style == "camp":
		# A few strands of straw.
		for k in 3:
			var q := p + Vector2(float(k) * 4.0, float((h >> (k + 3)) % 5))
			draw_line(q, q + Vector2(6, -2), Color(trim, 0.7), 1.0)
	elif roll < 0.15 and (style == "gate" or style == "walls"):
		draw_circle(p, 1.5, Color(Palette.PANTHEON_BRONZE_DARK, 0.6))  # A spent bronze arrowhead.
