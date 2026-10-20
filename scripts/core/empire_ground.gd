## EmpireGround — the PLACEHOLDER floor of the Act III stubs (the Electronic
## Empire; GDD §15.0 "Act III foundation (phase 1)"), drawn with _draw() like
## Ground (it extends it and reuses its redraw-on-cell-change logic). Its look
## is the stage's STAGE "floor" dictionary (`look`, set by Game before it
## enters the tree): {style, base, line, accent, trim}. Styles:
##   scrap     — the Scrap Wastes: rust-dark earth, scattered chrome plates.
##   assembly  — the Assembly Halls: riveted deck plates, amber hazard stripes.
##   citadel   — the Iron Citadel: dark iron panels, thin glowing signal lines.
## Phase 2 replaces it with each stage's own zone floors (tiles through
## EnvironmentArt, like ArchiveGround). Purely cosmetic: nothing here collides.
class_name EmpireGround
extends Ground

## The stage's floor look (StageRegistry "floor"; {} = a dark steel default).
var look: Dictionary = {}


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(look.get("style", "assembly"))  # Floor style.
	draw_rect(rect, look.get("base", Color(0.085, 0.095, 0.115)))
	var line: Color = look.get("line", Color(0.13, 0.15, 0.19))  # Joint colour.
	match style:
		"scrap":
			_grid(rect, GRID * 2.0, 1.0, Color(line, 0.6))
		"citadel":
			_grid(rect, GRID, 2.0, line)
		_:
			_grid(rect, GRID, 1.0, line)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_empire_cell(cx, cy, style)


## A square joint grid every `step` px, lines `width` px wide in `col`.
func _grid(rect: Rect2, step: float, width: float, col: Color) -> void:
	var x := floorf(rect.position.x / step) * step
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), col, width)
		x += step
	var y := floorf(rect.position.y / step) * step
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), col, width)
		y += step


## The Empire floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 707)))


## Draws the (hash-chosen) decoration of one cell for the floor style.
func _draw_empire_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = look.get("accent", Color(0.26, 0.31, 0.39))  # Plate / panel colour.
	var trim: Color = look.get("trim", Palette.EMPIRE_SIGNAL_AMBER)  # Signal light colour.
	match style:
		"scrap":
			if roll < 0.16:
				var w := 10.0 + float(h % 14)  # A scrap plate (px).
				var r := Rect2(p, Vector2(w, w * 0.6))
				draw_rect(r, Color(accent, 0.55))
				draw_line(r.position, Vector2(r.end.x, r.position.y), Color(accent.lightened(0.3), 0.5), 1.0)
			elif roll < 0.2:
				draw_circle(p, 2.0, Color(trim, 0.35))  # A dead signal light.
		"citadel":
			if roll < 0.1:
				var horizontal := (h >> 5) % 2 == 0  # Line orientation.
				var to := p + (Vector2(CELL * 0.8, 0) if horizontal else Vector2(0, CELL * 0.8))
				draw_line(p, to, Color(Palette.EMPIRE_SIGNAL_RED, 0.18), 3.0)
				draw_line(p, to, Color(Palette.EMPIRE_SIGNAL_RED, 0.45), 1.0)
		_:
			if roll < 0.08:
				# A hazard stripe band: amber and dark diagonals.
				for k in 4:
					var q := p + Vector2(float(k) * 8.0, 0)
					draw_colored_polygon(PackedVector2Array([q, q + Vector2(4, 0), q + Vector2(8, 10), q + Vector2(4, 10)]), Color(trim, 0.35))
			elif roll < 0.22:
				for k in 4:
					draw_circle(p + Vector2(float(k % 2) * 20.0, floorf(float(k) / 2.0) * 20.0), 1.5, Color(accent.lightened(0.2), 0.6))  # Rivets.
