## CourtGround — the PLACEHOLDER floor of the Act VII stubs (the Sanguine Court;
## GDD §15.0 "Act VII foundation (phase 1)"), drawn with _draw() like Ground (it
## extends it and reuses its redraw-on-cell-change logic). Its look is the
## stage's STAGE "floor" dictionary (`look`, set by Game before it enters the
## tree): {style, base, line, accent, trim}. Styles:
##   moor    — Ravensmoor: dark heather and peat, grey moor stones, a few red
##             leaves of the wolfwood.
##   fen     — the Witchwood: black fen water in still pools, reeds, a hanging
##             charm's red thread caught in the mud.
##   castle  — Castle Sanguis: castle stone in courses, a velvet runner, spilt
##             wine (or blood).
## Phase 2 replaces it with each stage's own zone floors (tiles through
## EnvironmentArt). Purely cosmetic: nothing here collides.
class_name CourtGround
extends Ground

## The stage's floor look (StageRegistry "floor"; {} = a moor default).
var look: Dictionary = {}


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(look.get("style", "moor"))  # Floor style.
	draw_rect(rect, look.get("base", Color(0.14, 0.13, 0.13)))
	var line: Color = look.get("line", Color(0.18, 0.16, 0.16))  # Joint / seam colour.
	if style == "castle":
		_courses(rect, GRID * 1.5, line)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_court_cell(cx, cy, style, line)


## Paving courses every `step` px (rows offset by half a stone), in `col`.
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


## The Court floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1777)))


## Draws the (hash-chosen) decoration of one cell for the floor style.
func _draw_court_cell(cx: int, cy: int, style: String, line: Color) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = look.get("accent", Palette.COURT_MOON_DARK)  # Stones / pools / runners.
	var trim: Color = look.get("trim", Palette.COURT_BLOOD)  # Leaves / threads / spills.
	match style:
		"fen":
			if roll < 0.2:
				draw_rect(Rect2(p, Vector2(30.0 + float(h % 18), 12.0)), Color(accent, 0.55))  # A still pool.
			elif roll < 0.32:
				for k in 3:
					draw_line(p + Vector2(float(k) * 4.0, 0.0), p + Vector2(float(k) * 4.0 + 1.0, -10.0), Color(line.lightened(0.25), 0.8), 1.0)  # Reeds.
			elif roll < 0.36:
				draw_line(p, p + Vector2(16, 3), Color(trim, 0.7), 1.0)  # A charm's red thread.
		"castle":
			if roll < 0.12:
				draw_rect(Rect2(p, Vector2(52.0, 10.0)), Color(accent, 0.4))  # A velvet runner.
			elif roll < 0.2:
				draw_rect(Rect2(p, Vector2(6, 4)), Color(trim, 0.6))  # Spilt wine.
				draw_rect(Rect2(p + Vector2(7, 2), Vector2(3, 2)), Color(trim, 0.45))
		_:
			if roll < 0.16:
				draw_rect(Rect2(p, Vector2(10.0 + float(h % 8), 7.0)), Color(accent, 0.75))  # A moor stone.
			elif roll < 0.3:
				draw_rect(Rect2(p, Vector2(3, 3)), Color(Color(0.30, 0.18, 0.26), 0.9))  # Heather.
				draw_rect(Rect2(p + Vector2(5, 2), Vector2(2, 2)), Color(Color(0.30, 0.18, 0.26), 0.8))
			elif roll < 0.34:
				draw_rect(Rect2(p, Vector2(3, 2)), Color(trim, 0.7))  # A red leaf.
