## HostGround — the PLACEHOLDER floor of the Celestial Host's stubs (temporary
## Act XIII; GDD §15.0 "The Celestial Host foundation (phase 1)"), drawn with
## _draw() like Ground (it extends it and reuses its redraw-on-cell-change
## logic). Its look is the stage's STAGE "floor" dictionary (`look`, set by
## Game before it enters the tree): {style, base, line, accent, trim}. Styles:
##   stair — the Silver Stair: pale ash steps (wide bands) with silver edges.
##   wheel — the Wheel of Thrones: deep cerulean sky with thin crystal rings.
##   rose  — the Empyrean: white rose petals of light.
## Phase 2 replaces it with each stage's own zone floors (tiles through
## EnvironmentArt). The cloud shadows are not drawn here (CloudShade draws
## them above the floor). Purely cosmetic: nothing here collides.
class_name HostGround
extends Ground

## The stage's floor look (StageRegistry "floor"; {} = a stair default).
var look: Dictionary = {}


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(look.get("style", "stair"))  # Floor style.
	draw_rect(rect, look.get("base", Color(0.20, 0.22, 0.30)))
	var line: Color = look.get("line", Color(0.30, 0.33, 0.43))  # Step edge / ring colour.
	if style == "stair":
		var step := GRID * 3.0  # px between two step edges.
		var y := floorf(rect.position.y / step) * step
		while y <= rect.end.y:
			draw_rect(Rect2(Vector2(rect.position.x, y), Vector2(rect.size.x, 3.0)), line)
			draw_rect(Rect2(Vector2(rect.position.x, y + 3.0), Vector2(rect.size.x, 1.0)), Color(Palette.HOST_SILVER, 0.18))
			y += step
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_host_cell(cx, cy, style, line)


## The Host floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1313)))


## Draws the (hash-chosen) decoration of one cell for the floor style (disc
## textures and rects only).
func _draw_host_cell(cx: int, cy: int, style: String, line: Color) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = look.get("accent", Palette.HOST_SILVER)  # Silver glints.
	var trim: Color = look.get("trim", Palette.HOST_CERULEAN)  # Cerulean light.
	match style:
		"wheel":
			if roll < 0.12:
				draw_rect(Rect2(p, Vector2(2.0, 2.0)), Color(Palette.HOST_STARLIGHT, 0.8))  # A star.
			elif roll < 0.18:
				SpriteBank.draw_disc(self, p, 10.0 + float(h % 8), Color(trim, 0.18))  # A far glow.
			elif roll < 0.24:
				draw_rect(Rect2(p, Vector2(30.0, 1.0)), Color(accent, 0.35))  # A crystal ring's edge.
		"rose":
			if roll < 0.16:
				SpriteBank.draw_disc(self, p, 12.0 + float(h % 10), Color(Palette.HOST_STARLIGHT, 0.45))  # A petal of light.
			elif roll < 0.22:
				SpriteBank.draw_disc(self, p, 6.0 + float(h % 5), Color(Palette.HOST_ROSE, 0.35))  # A dawn-rose glint.
			elif roll < 0.3:
				draw_rect(Rect2(p, Vector2(20.0, 1.0)), Color(line, 0.8))  # A petal's vein.
		_:
			if roll < 0.14:
				SpriteBank.draw_disc(self, p, 5.0 + float(h % 5), Color(0.08, 0.08, 0.1, 0.4))  # Hell's ash.
			elif roll < 0.22:
				draw_rect(Rect2(p, Vector2(14.0 + float(h % 10), 2.0)), Color(accent, 0.3))  # A silver vein in the step.
			elif roll < 0.27:
				SpriteBank.draw_disc(self, p, 14.0 + float(h % 8), Color(Palette.HOST_CLOUD, 0.12))  # A wisp of cloud.
