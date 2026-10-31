## InfernoGround — the PLACEHOLDER floor of the Act VI stubs (the Inferno; GDD
## §15.0 "Act VI foundation (phase 1)"), drawn with _draw() like Ground (it
## extends it and reuses its redraw-on-cell-change logic). Its look is the
## stage's STAGE "floor" dictionary (`look`, set by Game before it enters the
## tree): {style, base, line, accent, trim}. Styles:
##   ash       — the Burning Gate: a plain of grey ash and obsidian shards, ember
##               cracks glowing in it.
##   velvet    — the Palace of Silk and Ash: marble tiles in a diamond lattice,
##               velvet runners and fallen black-rose petals.
##   obsidian  — Pandemonium: obsidian paving in courses, lava seams, chain links.
## Phase 2 replaces it with each stage's own zone floors (tiles through
## EnvironmentArt). Purely cosmetic: nothing here collides; the Hell Pits are
## drawn over it by HellPits, not here.
class_name InfernoGround
extends Ground

## The stage's floor look (StageRegistry "floor"; {} = an ash default).
var look: Dictionary = {}


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(look.get("style", "ash"))  # Floor style.
	draw_rect(rect, look.get("base", Color(0.16, 0.15, 0.16)))
	var line: Color = look.get("line", Color(0.20, 0.18, 0.20))  # Joint / seam colour.
	if style == "obsidian":
		_courses(rect, GRID * 1.5, line)
	elif style == "velvet":
		_lattice(rect, GRID * 1.5, line)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_inferno_cell(cx, cy, style, line)


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


## A square tile grid every `step` px, in `col` (the palace's marble).
func _lattice(rect: Rect2, step: float, col: Color) -> void:
	var x := floorf(rect.position.x / step) * step
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), col, 1.0)
		x += step
	var y := floorf(rect.position.y / step) * step
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), col, 1.0)
		y += step


## The Inferno floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1666)))


## Draws the (hash-chosen) decoration of one cell for the floor style.
func _draw_inferno_cell(cx: int, cy: int, style: String, line: Color) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = look.get("accent", Palette.INFERNO_OBSIDIAN)  # Shards / runners / seams.
	var trim: Color = look.get("trim", Palette.INFERNO_LAVA)  # Embers / petals / lava.
	match style:
		"velvet":
			if roll < 0.14:
				draw_rect(Rect2(p, Vector2(48.0, 10.0)), Color(accent, 0.35))  # A velvet runner.
			elif roll < 0.26:
				draw_rect(Rect2(p, Vector2(3, 2)), Color(trim, 0.9))  # Black-rose petals.
				draw_rect(Rect2(p + Vector2(6, 3), Vector2(2, 2)), Color(trim, 0.75))
		"obsidian":
			if roll < 0.12:
				draw_line(p, p + Vector2(34, 6), Color(trim, 0.55), 2.0)  # A lava seam.
			elif roll < 0.2:
				for k in 3:
					draw_rect(Rect2(p + Vector2(float(k) * 7.0, 0.0), Vector2(5, 3)), Color(accent.lightened(0.2), 0.8))  # Chain links.
		_:
			if roll < 0.18:
				draw_rect(Rect2(p, Vector2(10.0 + float(h % 8), 6.0)), Color(accent, 0.85))  # An obsidian shard.
			elif roll < 0.28:
				draw_line(p, p + Vector2(22, -5), Color(trim, 0.45), 1.0)  # An ember crack.
				draw_line(p + Vector2(22, -5), p + Vector2(30, 2), Color(trim, 0.35), 1.0)
			elif roll < 0.38:
				draw_line(p, p + Vector2(40, 0), Color(line.lightened(0.1), 0.5), 1.0)  # A drift of ash.
