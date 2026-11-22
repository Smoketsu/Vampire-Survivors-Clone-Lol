## DynastyGround — the PLACEHOLDER floor of the Necropolis Dynasty's stubs
## (temporary Act XII; GDD §15.0 "The Necropolis Dynasty foundation (phase
## 1)"), drawn with _draw() like Ground (it extends it and reuses its
## redraw-on-cell-change logic). Its look is the stage's STAGE "floor"
## dictionary (`look`, set by Game before it enters the tree): {style, base,
## line, accent, trim}. Styles:
##   sand   — the Necropolis of Sand: dunes at dusk, wind ripples, stones.
##   temple — the Temple of the Lioness: sandstone flagstones, carnelian inlay.
##   hall   — the Hall of Two Truths: dark basalt flagstones, bronze and lapis
##            inlay.
## Phase 2 replaces it with each stage's own zone floors (tiles through
## EnvironmentArt). The quicksand is not drawn here (Quicksand draws it above
## the floor). Purely cosmetic: nothing here collides.
class_name DynastyGround
extends Ground

## The stage's floor look (StageRegistry "floor"; {} = a sand default).
var look: Dictionary = {}


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(look.get("style", "sand"))  # Floor style.
	draw_rect(rect, look.get("base", Color(0.42, 0.33, 0.22)))
	var line: Color = look.get("line", Color(0.36, 0.28, 0.19))  # Joint / ripple colour.
	if style != "sand":
		_flags(rect, GRID * 2.0, line)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_dynasty_cell(cx, cy, style, line)


## Flagstone joints every `step` px (every other row offset), in `col`.
func _flags(rect: Rect2, step: float, col: Color) -> void:
	var y := floorf(rect.position.y / step) * step
	var row := 0
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), col, 2.0)
		var x := floorf(rect.position.x / step) * step + (step * 0.5 if row % 2 == 1 else 0.0)
		while x <= rect.end.x:
			draw_line(Vector2(x, y), Vector2(x, y + step), col, 2.0)
			x += step
		y += step
		row += 1


## The Dynasty floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1212)))


## Draws the (hash-chosen) decoration of one cell for the floor style.
func _draw_dynasty_cell(cx: int, cy: int, style: String, line: Color) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = look.get("accent", Palette.DYN_SAND_DARK)  # Stones / inlay.
	var trim: Color = look.get("trim", Palette.DYN_NIGHT)  # Shadows / gems.
	match style:
		"temple":
			if roll < 0.1:
				draw_rect(Rect2(p, Vector2(26.0, 4.0)), Color(trim, 0.55))  # A carnelian inlay band.
			elif roll < 0.18:
				draw_rect(Rect2(p, Vector2(10.0 + float(h % 8), 6.0)), Color(accent, 0.5))  # A sun-bleached stone.
			elif roll < 0.3:
				draw_line(p, p + Vector2(18.0, float(h % 5) - 2.0), Color(line.darkened(0.15), 0.7), 1.0)  # A crack.
		"hall":
			if roll < 0.08:
				draw_rect(Rect2(p, Vector2(22.0, 3.0)), Color(accent, 0.7))  # A bronze inlay line.
			elif roll < 0.14:
				draw_rect(Rect2(p, Vector2(4.0, 4.0)), Color(trim, 0.85))  # A lapis stud.
			elif roll < 0.2:
				SpriteBank.draw_disc(self, p, 7.0 + float(h % 6), Color(0.0, 0.0, 0.0, 0.25))  # A worn hollow.
		_:
			if roll < 0.22:
				draw_line(p, p + Vector2(28.0, float(h % 5) - 2.0), Color(line.lightened(0.18), 0.6), 1.0)  # A wind ripple.
				draw_line(p + Vector2(4.0, 5.0), p + Vector2(30.0, 5.0 + float(h % 3) - 1.0), Color(line.darkened(0.1), 0.6), 1.0)
			elif roll < 0.3:
				SpriteBank.draw_disc(self, p, 4.0 + float(h % 5), Color(accent, 0.75))  # A stone half in the sand.
			elif roll < 0.34:
				SpriteBank.draw_disc(self, p, 10.0 + float(h % 8), Color(trim, 0.25))  # A dusk shadow.
