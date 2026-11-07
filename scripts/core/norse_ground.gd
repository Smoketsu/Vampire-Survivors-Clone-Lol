## NorseGround — the PLACEHOLDER floor of the Hall of the Slain's stubs (the
## Norse act, temporarily Act XI; GDD §15.0 "The Hall of the Slain foundation
## (phase 1)"), drawn with _draw() like Ground (it extends it and reuses its
## redraw-on-cell-change logic). Its look is the stage's STAGE "floor"
## dictionary (`look`, set by Game before it enters the tree): {style, base,
## line, accent, trim}. Styles:
##   snow  — the Barrow Fields: snowfields over a frozen fjord, drifts, dead
##           grass, frozen puddles.
##   hall  — Valgard: the feast hall's floor of broad planks, rushes, hearth
##           embers.
##   ash   — Vigrid: a plain of ash and frozen earth under a dying sky, cracks
##           and embers.
## Phase 2 replaces it with each stage's own zone floors (tiles through
## EnvironmentArt). Purely cosmetic: nothing here collides.
class_name NorseGround
extends Ground

## The stage's floor look (StageRegistry "floor"; {} = a snow default).
var look: Dictionary = {}


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(look.get("style", "snow"))  # Floor style.
	draw_rect(rect, look.get("base", Palette.NORSE_FROST_SHADE))
	var line: Color = look.get("line", Palette.NORSE_FROST)  # Plank seam / drift colour.
	if style == "hall":
		var y := floorf(rect.position.y / GRID) * GRID
		while y <= rect.end.y:
			draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line, 2.0)  # Plank seams.
			y += GRID * 0.5
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_norse_cell(cx, cy, style, line)


## The Norse floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1611)))


## Draws the (hash-chosen) decoration of one cell for the floor style.
func _draw_norse_cell(cx: int, cy: int, style: String, line: Color) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = look.get("accent", Palette.NORSE_PINE_LIGHT)  # Grass / rushes / cracks.
	var trim: Color = look.get("trim", Palette.NORSE_RUNE)  # Ice / embers.
	match style:
		"hall":
			if roll < 0.12:
				draw_line(p, p + Vector2(18.0, float(h % 5) - 2.0), Color(accent, 0.8), 1.0)  # Rushes on the floor.
			elif roll < 0.16:
				draw_rect(Rect2(p, Vector2(3, 3)), Color(trim, 0.8))  # An ember.
		"ash":
			if roll < 0.14:
				draw_line(p, p + Vector2(22.0, float(h % 9) - 4.0), Color(accent, 0.8), 1.0)  # A crack.
			elif roll < 0.2:
				draw_rect(Rect2(p, Vector2(3, 2)), Color(trim, 0.7))  # An ember.
			elif roll < 0.3:
				SpriteBank.draw_disc(self, p, 8.0 + float(h % 6), Color(line, 0.35))  # A drift of ash.
		_:
			if roll < 0.16:
				SpriteBank.draw_disc(self, p, 10.0 + float(h % 10), Color(line, 0.55))  # A snow drift.
			elif roll < 0.24:
				draw_line(p, p + Vector2(4.0, -8.0), Color(accent, 0.8), 1.0)  # Dead grass through the snow.
				draw_line(p + Vector2(3, 0), p + Vector2(6.0, -6.0), Color(accent, 0.8), 1.0)
			elif roll < 0.28:
				SpriteBank.draw_disc(self, p, 7.0 + float(h % 5), Color(trim, 0.35))  # A frozen puddle.
