## AssemblyGround — the floor of the Assembly Halls (Act III, Stage 8; GDD §15.0
## "The Assembly Halls (Act III phase 2)": the Empire's factory floors under hard
## amber light), drawn with _draw() like Ground (it extends it and reuses its
## redraw-on-cell-change logic). Each zone has its own floor (AssemblyStage.ZONES
## "ground"):
##   docks      — the Loading Docks: scuffed steel deck plates, painted bay lines.
##   conveyor   — the Conveyor Floor: grated walkways between the belt lanes.
##   fabricator — the Fabricator Hall: polished panels with warning-red trim.
##   furnace    — the Furnace: soot-black cast iron, slag stains, embers.
## The zone's floor tile (tiles/assembly_<style>.png, and its _2 / _3 variants)
## replaces the base colour and joints when its PNG exists (Ground header,
## EnvironmentArt); the decorations stay code-drawn flat marks on the grid
## (rivets, hazard paint, a dropped bolt) that never look solid. The belts and
## furnace channels are AssemblyDirector's (drawn over this floor).
## MarchDirector calls set_zone() at each zone change. Purely cosmetic.
class_name AssemblyGround
extends Ground

## Current zone look (an AssemblyStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = AssemblyStage.ZONES
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
		match style:
			"conveyor":
				_plates(rect, 32.0, 32.0, 1.0)
			"fabricator":
				_plates(rect, 64.0, 64.0, 2.0)
			"furnace":
				_plates(rect, 96.0, 48.0, 2.0)
			_:
				_plates(rect, 64.0, 128.0, 1.0)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_assembly_cell(cx, cy, style)


## Deck plates `w` x `h` px with joints `width` px wide (the code floor).
func _plates(rect: Rect2, w: float, h: float, width: float) -> void:
	var line: Color = _look["line"]
	var x := floorf(rect.position.x / w) * w
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), line, width)
		x += w
	var y := floorf(rect.position.y / h) * h
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line, width)
		y += h


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 8808)))


## Decal key prefix of the current zone: assembly_<style>_.
func _decal_prefix() -> String:
	return "assembly_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/assembly_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "assembly_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone: flat
## marks only (paint, rivets, a stain), so nothing on the floor looks solid.
func _draw_assembly_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0).floor()
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	if roll < 0.06:
		# A painted hazard band: amber (or the zone's trim) and dark diagonals.
		for k in 4:
			var q := p + Vector2(float(k) * 8.0, 0)
			draw_colored_polygon(PackedVector2Array([q, q + Vector2(4, 0), q + Vector2(8, 8), q + Vector2(4, 8)]), Color(trim, 0.3))
	elif roll < 0.16:
		for k in 4:  # A square of rivets.
			draw_rect(Rect2(p + Vector2(float(k % 2) * 20.0, floorf(float(k) / 2.0) * 20.0), Vector2(2, 2)), Color(accent.lightened(0.2), 0.7))
	elif roll < 0.22:
		match style:
			"furnace":
				# A cooled slag splash with one ember.
				draw_circle(p, 7.0 + float(h % 5), Color(0.05, 0.035, 0.03, 0.8))
				draw_rect(Rect2(p + Vector2(2, -1), Vector2(2, 2)), Color(1.0, 0.55, 0.15, 0.55))
			"fabricator":
				# A painted bay number plate.
				draw_rect(Rect2(p, Vector2(18, 10)), Color(accent, 0.5))
				draw_rect(Rect2(p + Vector2(3, 3), Vector2(4, 4)), Color(trim, 0.55))
			_:
				# An oil stain.
				draw_set_transform(p, 0.0, Vector2(1.0, 0.6))
				draw_circle(Vector2.ZERO, 9.0 + float(h % 6), Color(0.02, 0.025, 0.03, 0.55))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif roll < 0.25:
		# A dropped bolt (two flat pixels and a glint).
		draw_rect(Rect2(p, Vector2(4, 2)), Color(accent.lightened(0.35), 0.8))
		draw_rect(Rect2(p + Vector2(1, 0), Vector2(1, 1)), Color(0.886, 0.933, 1.0, 0.8))
