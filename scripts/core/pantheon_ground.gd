## PantheonGround — the PLACEHOLDER floor of the Act IV stubs (the Olympian
## Republic; GDD §15.0 "Act IV foundation (phase 1)"), drawn with _draw() like
## Ground (it extends it and reuses its redraw-on-cell-change logic). Its look
## is the stage's STAGE "floor" dictionary (`look`, set by Game before it
## enters the tree): {style, base, line, accent, trim}. Styles:
##   sand      — the Shores of Ilion: dark wet sand, foam lines, marble shards.
##   marble    — Mount Olympus: storm-dark marble flagstones, bronze inlay.
##   asphodel  — the Asphodel Underworld: grey ash, pale asphodel flowers.
## Phase 2 replaces it with each stage's own zone floors (tiles through
## EnvironmentArt). Purely cosmetic: nothing here collides.
class_name PantheonGround
extends Ground

## The stage's floor look (StageRegistry "floor"; {} = a dark sand default).
var look: Dictionary = {}


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(look.get("style", "sand"))  # Floor style.
	draw_rect(rect, look.get("base", Color(0.20, 0.17, 0.12)))
	var line: Color = look.get("line", Color(0.25, 0.21, 0.15))  # Joint colour.
	if style == "marble":
		_grid(rect, GRID * 2.0, 2.0, line)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_pantheon_cell(cx, cy, style, line)


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


## The Pantheon floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1010)))


## Draws the (hash-chosen) decoration of one cell for the floor style.
func _draw_pantheon_cell(cx: int, cy: int, style: String, line: Color) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = look.get("accent", Palette.PANTHEON_MARBLE_DARK)  # Stone colour.
	var trim: Color = look.get("trim", Palette.PANTHEON_AEGEAN_LIGHT)  # Foam / inlay / flower heart.
	match style:
		"sand":
			if roll < 0.18:
				var w := 40.0 + float(h % 60)  # A foam line (px).
				draw_line(p, p + Vector2(w, float((h >> 4) % 9) - 4.0), Color(trim, 0.22), 2.0)
			elif roll < 0.26:
				draw_rect(Rect2(p, Vector2(6.0 + float(h % 6), 4.0)), Color(accent, 0.55))  # A marble shard.
			elif roll < 0.4:
				draw_line(p, p + Vector2(10, 2), Color(line.lightened(0.15), 0.6), 1.0)  # A ripple in the sand.
		"marble":
			if roll < 0.12:
				var cell := Rect2(Vector2(floorf(p.x / (GRID * 2.0)) * GRID * 2.0, floorf(p.y / (GRID * 2.0)) * GRID * 2.0), Vector2(GRID * 2.0, GRID * 2.0))
				draw_rect(cell.grow(-3.0), Color(accent, 0.18))  # A paler slab.
			elif roll < 0.18:
				draw_line(p, p + Vector2(22, 0), Color(trim, 0.35), 1.0)  # Bronze inlay.
				draw_line(p + Vector2(0, 3), p + Vector2(22, 3), Color(trim, 0.2), 1.0)
		_:
			if roll < 0.22:
				for k in 3:
					var q := p + Vector2(float(k) * 6.0, float((h >> (k + 3)) % 5))  # An asphodel stem and flower.
					draw_line(q, q + Vector2(0, 6), Color(0.3, 0.32, 0.3, 0.7), 1.0)
					draw_circle(q, 2.0, Color(accent, 0.75))
					draw_circle(q, 0.8, Color(trim, 0.85))
			elif roll < 0.3:
				draw_circle(p, 6.0 + float(h % 6), Color(0.05, 0.05, 0.06, 0.4))  # A patch of darker ash.
