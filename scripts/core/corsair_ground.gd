## CorsairGround — the PLACEHOLDER look of the Act X stubs (the Black Tide; GDD
## §15.0 "Act X foundation: the Black Tide (phase 1)"): the sea and the ship's
## deck, drawn with _draw() like Ground (it extends it and reuses its
## redraw-on-cell-change logic, so nothing here is redrawn every frame). Its
## look is the stage's STAGE "floor" dictionary (`look`, set by Game before it
## enters the tree): {style, sea, foam, plank, seam, rail}; the deck's outline
## is Game.deck's (DeckBounds), the one deck shape. Styles tint the sea:
##   night — the Smuggler's Cutter: navy-black water, pale foam.
##   dawn  — the Treasure Galleon: a lighter, bluer swell.
##   ghost — the Maelstrom: the water greened by the Hollow Queen's glow.
## Drawn: the sea (flat colour, hashed foam lines that never touch the hull),
## the deck (one polygon, its planks along its length and their seams, a rail
## round the edge and a dark hull band just outside it). Phase 2 replaces it
## with each stage's own zone art. Purely cosmetic: nothing here collides
## (DeckBounds does).
class_name CorsairGround
extends Ground

## The stage's floor look (StageRegistry "floor"; {} = the night defaults).
var look: Dictionary = {}
## Owning run (its deck outline).
var game: Game = null

## Spacing (px) of the planks across the deck.
const PLANK: float = 16.0
## Width (px) of the drawn rail.
const RAIL_W: float = 5.0
## Width (px) of the dark hull band outside the rail.
const HULL_W: float = 10.0


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(look.get("style", "night"))
	var sea: Color = look.get("sea", Palette.CORSAIR_SEA_DARK)
	if style == "dawn":
		sea = sea.lerp(Palette.CORSAIR_SEA, 0.45)
	elif style == "ghost":
		sea = sea.lerp(Palette.CORSAIR_SPECTRE_DARK, 0.35)
	draw_rect(rect, sea)
	var deck: DeckBounds = game.deck if game != null else null
	_foam(rect, deck)
	if deck == null:
		return
	var hull := PackedVector2Array()  # The hull band: the outline pushed out.
	for i in deck.outline.size():
		hull.append(deck.outline[i] + (deck.outline[i] - deck.center).normalized() * HULL_W)
	draw_colored_polygon(hull, Palette.CORSAIR_INK)
	draw_colored_polygon(deck.outline, look.get("plank", Palette.CORSAIR_OAK))
	var seam: Color = look.get("seam", Palette.CORSAIR_OAK_DARK)
	var y := deck.center.y - deck.half_beam + PLANK
	var row := 0
	while y < deck.center.y + deck.half_beam:
		var span := _span_at(deck, y)
		if span.y > span.x:
			draw_line(Vector2(span.x, y), Vector2(span.y, y), seam, 1.0)
			var x := span.x + 40.0 + float((row * 53) % 80)  # Butt joints, staggered per row.
			while x < span.y - 8.0:
				draw_line(Vector2(x, y - PLANK), Vector2(x, y), Color(seam, 0.7), 1.0)
				x += 120.0
		y += PLANK
		row += 1
	var rail_c: Color = look.get("rail", Palette.CORSAIR_OAK_LIGHT)
	var outline := deck.outline.duplicate()
	outline.append(deck.outline[0])
	draw_polyline(outline, rail_c, RAIL_W)


## The x range [min, max] of the deck's outline at height `y` (convex), as a Vector2.
static func _span_at(deck: DeckBounds, y: float) -> Vector2:
	var lo := INF
	var hi := -INF
	var n := deck.outline.size()
	for i in n:
		var a := deck.outline[i]
		var b := deck.outline[(i + 1) % n]
		if (a.y - y) * (b.y - y) > 0.0 or a.y == b.y:
			continue
		var x := lerpf(a.x, b.x, (y - a.y) / (b.y - a.y))
		lo = minf(lo, x)
		hi = maxf(hi, x)
	return Vector2(lo + 3.0, hi - 3.0)


## Hashed foam lines on the water (never over the deck).
func _foam(rect: Rect2, deck: DeckBounds) -> void:
	var foam: Color = look.get("foam", Palette.CORSAIR_FOAM)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var h := absi(hash(Vector3i(cx, cy, 3030)))
			if h % 100 >= 45:
				continue
			var p := Vector2(float(cx) * CELL + float((h >> 8) % 96) + 16.0, float(cy) * CELL + float((h >> 15) % 96) + 16.0)
			var w := 14.0 + float(h % 22)
			if deck != null and deck.violation(p, -w - 24.0) <= 0.0:
				continue  # Too close to the hull.
			draw_line(p, p + Vector2(w, 0.0), Color(foam, 0.35 + float(h % 30) / 100.0), 1.0)
			draw_line(p + Vector2(w * 0.3, 3.0), p + Vector2(w * 0.8, 3.0), Color(foam, 0.2), 1.0)
