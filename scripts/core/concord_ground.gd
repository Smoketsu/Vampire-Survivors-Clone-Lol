## ConcordGround — the PLACEHOLDER floor of the Act IX stubs (the Concord of
## Stars; GDD §15.0 "Act IX foundation (phase 1)"), drawn with _draw() like
## Ground (it extends it and reuses its redraw-on-cell-change logic). Its look
## is the stage's STAGE "floor" dictionary (`look`, set by Game before it enters
## the tree): {style, base, line, accent, trim}. Styles:
##   ruins — the Crash Site: the capital's broken paving, shards of the scout
##           ship's hull, spilt plasma, scorch marks.
##   moon  — the Proving Moon: grey regolith, small craters, the Vrask's teal
##           trail markers.
##   hull  — the Ark of the Concord: the mothership's deck plates in courses,
##           hatch plates, plasma deck lights.
## Phase 2 replaces it with each stage's own zone floors (tiles through
## EnvironmentArt). The alien turf is not drawn here (Terraforming draws it
## above the floor). Purely cosmetic: nothing here collides.
class_name ConcordGround
extends Ground

## The stage's floor look (StageRegistry "floor"; {} = a ruins default).
var look: Dictionary = {}


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(look.get("style", "ruins"))  # Floor style.
	draw_rect(rect, look.get("base", Color(0.14, 0.14, 0.16)))
	var line: Color = look.get("line", Color(0.19, 0.19, 0.21))  # Joint / seam colour.
	if style == "hull":
		_plates(rect, GRID * 2.0, line)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_concord_cell(cx, cy, style, line)


## Deck plate seams every `step` px (a plain grid, every other row offset), in `col`.
func _plates(rect: Rect2, step: float, col: Color) -> void:
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


## The Concord floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 2727)))


## Draws the (hash-chosen) decoration of one cell for the floor style.
func _draw_concord_cell(cx: int, cy: int, style: String, line: Color) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = look.get("accent", Palette.CONCORD_GUNMETAL)  # Shards / craters / hatches.
	var trim: Color = look.get("trim", Palette.CONCORD_PLASMA_DARK)  # Plasma / markers / lights.
	match style:
		"moon":
			if roll < 0.14:
				SpriteBank.draw_disc(self, p, 8.0 + float(h % 10), Color(accent, 0.6))  # A small crater.
				SpriteBank.draw_disc(self, p + Vector2(-2, -2), 5.0 + float(h % 6), Color(line.lightened(0.15), 0.5))
			elif roll < 0.18:
				draw_rect(Rect2(p, Vector2(3, 3)), Color(trim, 0.8))  # A trail marker.
		"hull":
			if roll < 0.1:
				draw_rect(Rect2(p, Vector2(28.0, 18.0)), Color(accent, 0.6))  # A hatch plate.
			elif roll < 0.16:
				draw_rect(Rect2(p, Vector2(3, 3)), Color(trim, 0.75))  # A deck light.
		_:
			if roll < 0.12:
				draw_rect(Rect2(p, Vector2(12.0 + float(h % 10), 6.0)), Color(accent, 0.75))  # A hull shard.
			elif roll < 0.2:
				SpriteBank.draw_disc(self, p, 9.0 + float(h % 8), Color(0.05, 0.05, 0.06, 0.45))  # A scorch mark.
			elif roll < 0.24:
				draw_rect(Rect2(p, Vector2(5, 3)), Color(trim, 0.6))  # Spilt plasma.
			elif roll < 0.4:
				draw_line(p, p + Vector2(20.0, float(h % 7) - 3.0), Color(line.lightened(0.1), 0.7), 1.0)  # A crack in the paving.
