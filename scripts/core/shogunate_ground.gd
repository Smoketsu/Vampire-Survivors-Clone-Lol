## ShogunateGround — the PLACEHOLDER floor of the Act V stubs (the Shogunate of
## the Rising Sun; GDD §15.0 "Act V foundation (phase 1)"), drawn with _draw()
## like Ground (it extends it and reuses its redraw-on-cell-change logic). Its
## look is the stage's STAGE "floor" dictionary (`look`, set by Game before it
## enters the tree): {style, base, line, accent, trim}. Styles:
##   paddy   — the Burning Province: dark paddy mud, rows of rice shoots and
##             still water.
##   castle  — Castle Kurogane: grey castle flagstones in courses.
##   gravel  — the Road to the Sun: raked shrine gravel, a few stepping stones
##             and fallen sakura petals.
## Phase 2 replaces it with each stage's own zone floors (tiles through
## EnvironmentArt). Purely cosmetic: nothing here collides. The Sun's Course's
## darkness and dusk tint are drawn over it by SunCourse, not here.
class_name ShogunateGround
extends Ground

## The stage's floor look (StageRegistry "floor"; {} = a dark paddy default).
var look: Dictionary = {}


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(look.get("style", "paddy"))  # Floor style.
	draw_rect(rect, look.get("base", Color(0.15, 0.13, 0.09)))
	var line: Color = look.get("line", Color(0.19, 0.17, 0.12))  # Joint / row colour.
	if style == "castle":
		_courses(rect, GRID * 1.5, line)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_shogunate_cell(cx, cy, style, line)


## Flagstone courses every `step` px (rows offset by half a stone), in `col`.
func _courses(rect: Rect2, step: float, col: Color) -> void:
	var y := floorf(rect.position.y / step) * step
	var row := 0
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), col, 2.0)
		var x := floorf(rect.position.x / (step * 2.0)) * step * 2.0 + (step if row % 2 == 1 else 0.0)
		while x <= rect.end.x:
			draw_line(Vector2(x, y), Vector2(x, y + step), col, 2.0)
			x += step * 2.0
		y += step
		row += 1


## The Shogunate floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1313)))


## Draws the (hash-chosen) decoration of one cell for the floor style.
func _draw_shogunate_cell(cx: int, cy: int, style: String, line: Color) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = look.get("accent", Color(0.30, 0.42, 0.22))  # Shoots / stone / stepping stones.
	var trim: Color = look.get("trim", Palette.SHOGUN_SAKURA)  # Water glint / moss / petals.
	match style:
		"paddy":
			if roll < 0.22:
				for k in 4:
					var q := p + Vector2(float(k) * 9.0, 0.0)  # A row of rice shoots.
					draw_line(q, q + Vector2(-1, -6), Color(accent, 0.8), 1.0)
					draw_line(q, q + Vector2(2, -5), Color(accent, 0.7), 1.0)
			elif roll < 0.32:
				draw_rect(Rect2(p, Vector2(28.0 + float(h % 24), 10.0)), Color(trim, 0.12))  # Still water.
			elif roll < 0.42:
				draw_line(p, p + Vector2(40, 0), Color(line.lightened(0.1), 0.6), 1.0)  # A furrow.
		"castle":
			if roll < 0.12:
				var step := GRID * 1.5
				var cell := Rect2(Vector2(floorf(p.x / step) * step, floorf(p.y / step) * step), Vector2(step, step))
				draw_rect(cell.grow(-3.0), Color(accent, 0.16))  # A paler flagstone.
			elif roll < 0.18:
				draw_rect(Rect2(p, Vector2(6, 3)), Color(trim, 0.35))  # Moss in a joint.
		_:
			if roll < 0.2:
				for k in 3:
					draw_line(p + Vector2(0, float(k) * 4.0), p + Vector2(46, float(k) * 4.0), Color(line.lightened(0.12), 0.5), 1.0)  # Raked lines.
			elif roll < 0.27:
				draw_rect(Rect2(p, Vector2(16, 10)), Color(accent, 0.6))  # A stepping stone.
			elif roll < 0.36:
				draw_rect(Rect2(p, Vector2(3, 2)), Color(trim, 0.85))  # Fallen petals.
				draw_rect(Rect2(p + Vector2(7, 4), Vector2(2, 2)), Color(trim, 0.7))
