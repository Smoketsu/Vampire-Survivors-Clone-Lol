## WildGround — the PLACEHOLDER floor of the Turning Year's stubs (temporary
## Act XV; GDD §15.0 "The Turning Year foundation (phase 1)"), drawn with
## _draw() like Ground (it extends it and reuses its redraw-on-cell-change
## logic). Its look is the stage's STAGE "floor" dictionary (`look`, set by
## Game before it enters the tree): {style, base, line, accent, trim}. Styles:
##   greenwood — the Greenwood: moss, fern tufts and fallen leaves.
##   fae       — the Fae Court: grass, blossom petals and mushroom rings.
##   tree      — the World-Tree: leaf litter and great roots.
## Each season repaints it (WildRules.tint_ground(): the node's modulate, no
## redraw), and the blight is drawn over it by WildRules' under layer. Phase 2
## replaces it with each stage's own zone floors (tiles through EnvironmentArt).
## Purely cosmetic: nothing here collides.
class_name WildGround
extends Ground

## The stage's floor look (StageRegistry "floor"; {} = a greenwood default).
var look: Dictionary = {}


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(look.get("style", "greenwood"))  # Floor style.
	draw_rect(rect, look.get("base", Color(0.12, 0.18, 0.10)))
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_wild_cell(cx, cy, style)


## The Wild floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1515)))


## Draws the (hash-chosen) decoration of one cell for the floor style (disc
## textures and rects only).
func _draw_wild_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var line: Color = look.get("line", Color(0.17, 0.25, 0.13))  # Darker patches.
	var accent: Color = look.get("accent", Palette.WILD_MOSS)  # Moss, petals, leaves.
	var trim: Color = look.get("trim", Palette.WILD_BARK)  # Roots, twigs.
	match style:
		"fae":
			if roll < 0.16:
				for i in 3:
					draw_rect(Rect2(p + Vector2(float(i) * 4.0, float(i % 2) * 3.0), Vector2(2.0, 2.0)), Color(accent, 0.7))  # Fallen petals.
			elif roll < 0.22:
				for i in 6:
					var a := TAU * float(i) / 6.0
					SpriteBank.draw_disc(self, p + Vector2(cos(a), sin(a)) * 12.0, 2.5, Color(Palette.WILD_BONE, 0.5))  # A mushroom ring.
			elif roll < 0.32:
				SpriteBank.draw_disc(self, p, 14.0 + float(h % 8), Color(line, 0.5))  # Shade.
		"tree":
			if roll < 0.14:
				draw_rect(Rect2(p, Vector2(30.0 + float(h % 16), 4.0)), Color(trim, 0.75))  # A great root.
			elif roll < 0.26:
				draw_rect(Rect2(p, Vector2(3.0, 2.0)), Color(accent, 0.7))  # A leaf.
				draw_rect(Rect2(p + Vector2(7.0, 4.0), Vector2(3.0, 2.0)), Color(accent, 0.55))
			elif roll < 0.34:
				SpriteBank.draw_disc(self, p, 16.0 + float(h % 8), Color(line, 0.55))  # Shade.
		_:
			if roll < 0.18:
				for i in 4:
					draw_rect(Rect2(p + Vector2(float(i) * 2.0, -float(i) * 1.5), Vector2(1.5, 6.0)), Color(accent, 0.45))  # A fern tuft.
			elif roll < 0.25:
				draw_rect(Rect2(p, Vector2(3.0, 2.0)), Color(Palette.WILD_GOLD_LEAF, 0.55))  # A fallen leaf.
			elif roll < 0.33:
				SpriteBank.draw_disc(self, p, 16.0 + float(h % 8), Color(line, 0.5))  # Deep moss.
			elif roll < 0.36:
				draw_rect(Rect2(p, Vector2(14.0, 2.0)), Color(trim, 0.6))  # A twig.
