## OlympusGround — the procedural floor of Mount Olympus, the Pantheon Trial
## (Act IV, Stage 11; GDD §15.0 "Mount Olympus (Act IV phase 2)": "the stage
## climbs the mountain under Zeus's storm"), drawn with _draw() like Ground (it
## extends it and reuses its redraw-on-cell-change logic). Each zone has its
## own floor (OlympusStage.ZONES "ground"):
##   field    — the Field of Ares: trampled mountain earth and scorched grass,
##              broken spear shafts.
##   grove    — the Groves of Artemis: dark moss and cypress needles under
##              moonlight, pale flowers.
##   terrace  — the Terraces of Poseidon: wet marble flagstones with water
##              runnels and shells.
##   summit   — the Summit: storm-dark marble with gold inlay.
## Art pass: the zone's floor tile (tiles/olympus_<style>.png and its
## variants) replaces the base colour and joints when its PNG exists (Ground
## header, EnvironmentArt); the code decorations then stay sparse (a glint, a
## flower, a puddle). MarchDirector calls set_zone() at each zone change.
## Purely cosmetic: nothing here collides.
class_name OlympusGround
extends Ground

## Current zone look (an OlympusStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = OlympusStage.ZONES
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
		if style == "terrace" or style == "summit":
			_slabs(rect, 64.0 if style == "summit" else 80.0)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_olympus_cell(cx, cy, style)


## Flagstone joints every `step` px (the marble floors' code look).
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
	return absi(hash(Vector3i(cx, cy, 1111)))


## Decal key prefix of the current zone: olympus_<style>_.
func _decal_prefix() -> String:
	return "olympus_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/olympus_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "olympus_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_olympus_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	if _art_floor and roll < 0.14:
		return  # The tile already has its own stones and cracks.
	match style:
		"field":
			if roll < 0.08:
				draw_line(p, p + Vector2(18, -5), Color(accent, 0.8), 2.0)  # A broken spear shaft.
				draw_line(p + Vector2(18, -5), p + Vector2(23, -7), Color(trim, 0.7), 2.0)
			elif roll < 0.14:
				draw_circle(p, 5.0 + float(h % 4), Color(0.05, 0.03, 0.02, 0.35))  # A scorch mark.
			elif roll < 0.2:
				for k in 3:
					draw_line(p + Vector2(float(k) * 3.0, 0), p + Vector2(float(k) * 3.0 - 1.0, -5.0), Color(0.36, 0.33, 0.16, 0.7), 1.0)  # A tuft of dry grass.
		"grove":
			if roll < 0.12:
				draw_circle(p, 1.5, Color(trim, 0.6))  # A pale flower.
				draw_circle(p + Vector2(4, 2), 1.2, Color(trim, 0.45))
			elif roll < 0.2:
				draw_line(p, p + Vector2(6, 2), Color(accent.darkened(0.3), 0.8), 1.0)  # Cypress needles.
				draw_line(p + Vector2(2, 3), p + Vector2(7, 1), Color(accent.darkened(0.3), 0.8), 1.0)
			elif roll < 0.24:
				draw_circle(p, 9.0, Color(trim, 0.05))  # A patch of moonlight.
		"terrace":
			if roll < 0.1:
				draw_line(p, p + Vector2(28, 0), Color(trim, 0.35), 2.0)  # A water runnel.
			elif roll < 0.16:
				draw_circle(p, 6.0 + float(h % 5), Color(trim, 0.12))  # A puddle.
			elif roll < 0.19:
				draw_circle(p, 1.5, Color(0.96, 0.9, 0.85, 0.7))  # A shell.
		_:
			if roll < 0.12:
				draw_line(p, p + Vector2(22, 0), Color(trim, 0.35), 1.0)  # Gold inlay.
				draw_line(p + Vector2(0, 3), p + Vector2(22, 3), Color(trim, 0.2), 1.0)
			elif roll < 0.18:
				draw_polyline(PackedVector2Array([p, p + Vector2(7, 3), p + Vector2(12, -1), p + Vector2(20, 4)]), Color(_look["line"], 0.9), 1.0)  # A crack.
