## PrimevalGround — the PLACEHOLDER floor of the Age of Titans' stubs
## (temporary Act XIV; GDD §15.0 "The Age of Titans foundation (phase 1)"),
## drawn with _draw() like Ground (it extends it and reuses its
## redraw-on-cell-change logic). Its look is the stage's STAGE "floor"
## dictionary (`look`, set by Game before it enters the tree): {style, base,
## line, accent, trim}. Styles:
##   fern  — the Fern Basin: jungle earth, fern fronds and tar spots.
##   plain — the Great Plain: dry grass tufts and dust.
##   ash   — the Last Day: scorched earth, embers and ash.
## Phase 2 replaces it with each stage's own zone floors (tiles through
## EnvironmentArt). Purely cosmetic: nothing here collides (the tar seeps of
## phase 2 slow through TerrainSlow, not here).
class_name PrimevalGround
extends Ground

## The stage's floor look (StageRegistry "floor"; {} = a fern default).
var look: Dictionary = {}


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(look.get("style", "fern"))  # Floor style.
	draw_rect(rect, look.get("base", Color(0.13, 0.20, 0.11)))
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_primeval_cell(cx, cy, style)


## The Titans floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1414)))


## Draws the (hash-chosen) decoration of one cell for the floor style (disc
## textures and rects only).
func _draw_primeval_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var line: Color = look.get("line", Color(0.19, 0.28, 0.14))  # Darker patches.
	var accent: Color = look.get("accent", Palette.PRIMEVAL_FERN)  # Fronds, grass, embers.
	var trim: Color = look.get("trim", Palette.PRIMEVAL_TAR)  # Tar, cracks.
	match style:
		"plain":
			if roll < 0.2:
				for i in 3:
					draw_rect(Rect2(p + Vector2(float(i) * 3.0, -float(i % 2) * 2.0), Vector2(1.0, 5.0)), Color(accent, 0.45))  # A grass tuft.
			elif roll < 0.3:
				SpriteBank.draw_disc(self, p, 14.0 + float(h % 10), Color(line, 0.6))  # A dust patch.
			elif roll < 0.33:
				draw_rect(Rect2(p, Vector2(10.0, 2.0)), Color(Palette.PRIMEVAL_BONE, 0.35))  # A bleached bone.
		"ash":
			if roll < 0.16:
				SpriteBank.draw_disc(self, p, 10.0 + float(h % 8), Color(trim, 0.7))  # Scorched earth.
			elif roll < 0.22:
				draw_rect(Rect2(p, Vector2(2.0, 2.0)), Color(accent, 0.75))  # An ember.
			elif roll < 0.32:
				draw_rect(Rect2(p, Vector2(18.0 + float(h % 10), 1.0)), Color(line, 0.9))  # A crack.
		_:
			if roll < 0.18:
				for i in 4:
					draw_rect(Rect2(p + Vector2(float(i) * 2.0, float(i) * 1.5), Vector2(7.0, 1.5)), Color(accent, 0.4))  # A fern frond.
			elif roll < 0.25:
				SpriteBank.draw_disc(self, p, 8.0 + float(h % 6), Color(trim, 0.55))  # A tar spot.
			elif roll < 0.33:
				SpriteBank.draw_disc(self, p, 16.0 + float(h % 8), Color(line, 0.5))  # Deep shade.
