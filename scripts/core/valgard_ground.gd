## ValgardGround — the floor of Valgard, the Hall of Heroes (Stage 17 in the
## final order; the Hall of the Slain, temporarily Act XI; GDD §15.0 "Valgard,
## the Hall of Heroes (the Hall of the Slain phase 2)"), drawn with _draw() like
## Ground (it extends it and reuses its redraw-on-cell-change logic). Each zone
## has its own look (ValgardStage.ZONES "ground"): the art pass's floor tile
## (tiles/<tile>.png: norse_planks for the Shield Yard and the Mead Hall,
## norse_slabs for the Hall of Spears and the Valkyries' Gate) under code
## decorations per style:
##   shield_yard    — straw and a fallen shield's rim on weathered planks.
##   mead_hall      — rushes, spilt mead and hearth embers.
##   hall_of_spears — rune lines cut in the slabs, spear shadows.
##   valkyries_gate — white feathers and the gold of the open sky.
## The zone's base colour stands in when its tile PNG is missing. MarchDirector
## calls set_zone() at each zone change. Purely cosmetic: nothing here collides.
class_name ValgardGround
extends Ground

## Current zone look (a ValgardStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = ValgardStage.ZONES
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
			_draw_hall_cell(cx, cy)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1777)))


## Floor tile key of the current zone: tiles/<tile>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + String(_look.get("tile", "norse_planks"))


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_hall_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	var line: Color = _look["line"]
	match String(_look["style"]):
		"shield_yard":
			if roll < 0.1:
				draw_line(p, p + Vector2(14.0, float(h % 5) - 2.0), Color(accent, 0.7), 1.0)  # Straw.
				draw_line(p + Vector2(3.0, 2.0), p + Vector2(15.0, float(h % 3)), Color(accent, 0.6), 1.0)
			elif roll < 0.13:
				SpriteBank.draw_disc(self, p, 6.0, Color(line, 0.7))  # A fallen shield's rim.
				SpriteBank.draw_disc(self, p, 2.0, Color(trim, 0.6))
		"mead_hall":
			if roll < 0.12:
				draw_line(p, p + Vector2(18.0, float(h % 5) - 2.0), Color(accent, 0.8), 1.0)  # Rushes on the floor.
			elif roll < 0.16:
				draw_rect(Rect2(p, Vector2(3, 3)), Color(trim, 0.8))  # An ember.
			elif roll < 0.19:
				SpriteBank.draw_disc(self, p, 5.0 + float(h % 4), Color(Palette.NORSE_HEARTH_GLOW, 0.18))  # Spilt mead.
		"hall_of_spears":
			if roll < 0.08:
				draw_line(p, p + Vector2(20.0, 0.0), Color(trim, 0.35), 1.0)  # A cut rune line.
				draw_line(p + Vector2(10.0, -4.0), p + Vector2(10.0, 4.0), Color(trim, 0.35), 1.0)
			elif roll < 0.14:
				draw_line(p, p + Vector2(26.0, 9.0), Color(line, 0.6), 2.0)  # A spear's shadow.
		_:
			if roll < 0.07:
				draw_line(p, p + Vector2(6.0, -3.0), Color(accent, 0.8), 2.0)  # A white feather.
			elif roll < 0.1:
				draw_rect(Rect2(p, Vector2(2, 2)), Color(trim, 0.7))  # A glint of the sky's gold.
