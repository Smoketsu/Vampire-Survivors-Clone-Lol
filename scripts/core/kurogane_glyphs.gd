## KuroganeGlyphs — code-drawn shapes of Castle Kurogane (Act V, Stage 14; GDD
## §15.0 "Castle Kurogane (Act V phase 2)"): the fallbacks of the stage's six
## obstacle kinds, of Shogun Kurogane and of his command platform when their
## sprites are missing (the stage's kinds fall back on ShogunateGlyphs' shapes).
## Grey castle stone, white plaster, dark timber, red lacquer and gold; never the
## undead's bone or soul teal. Rects and texture discs only (no polygon redrawn
## every frame). Purely visual.
class_name KuroganeGlyphs
extends RefCounted

## Ink of the outlines (lacquer ink).
const INK := Color(0.102, 0.043, 0.047)
## Castle stone (grey ramp).
const STONE := Color(0.53, 0.58, 0.65)
## White plaster of the walls.
const PLASTER := Color(0.81, 0.80, 0.77)
## Dark timber (brown ramp).
const WOOD := Color(0.31, 0.2, 0.125)
## Dark tiles of the wall caps (indigo).
const TILE := Color(0.18, 0.25, 0.45)
## Pine needles.
const PINE := Color(0.18, 0.29, 0.17)


## Draws one of Castle Kurogane's obstacle kinds at its collision shape.
## Returns false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"castle_wall", "palisade_gate":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var wall := o.kind == "castle_wall"
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), STONE if wall else WOOD)
			var long := Vector2(1, 0) if o.half.x >= o.half.y else Vector2(0, 1)  # Along it.
			var band := Rect2(rect.position + Vector2(1.5, 1.5), Vector2(rect.size.x - 3.0, 4.0) if long.x > 0.0 else Vector2(4.0, rect.size.y - 3.0))
			ci.draw_rect(band, TILE if wall else Palette.SHOGUN_LACQUER)  # The tiled cap / the lacquered beam.
			if wall:
				var band2 := Rect2(band.position + (Vector2(0, 4) if long.x > 0.0 else Vector2(4, 0)), band.size)
				ci.draw_rect(band2, PLASTER)
		"black_pine", "garden_rock", "sake_barrels", "taiko_drum":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			var body: Color = PINE  # The prop's colour.
			match o.kind:
				"garden_rock":
					body = STONE
				"sake_barrels":
					body = Color(0.85, 0.66, 0.23)
				"taiko_drum":
					body = Palette.SHOGUN_LACQUER
			SpriteBank.draw_disc(ci, c, r - 1.5, body)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, body.lightened(0.2))
		_:
			return false
	return true


## The command platform without its sprite, its deck centre at `o`: a timber
## deck with a red railing and four banner poles.
static func draw_platform(ci: CanvasItem, o: Vector2) -> void:
	var deck := Rect2(o + Vector2(-40, -26), Vector2(80, 52))
	ci.draw_rect(Rect2(deck.position + Vector2(4, 26), deck.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(deck.grow(1.5), INK)
	ci.draw_rect(deck, WOOD)
	ci.draw_rect(Rect2(deck.position, Vector2(deck.size.x, 4.0)), Palette.SHOGUN_LACQUER)
	ci.draw_rect(Rect2(deck.position + Vector2(0, deck.size.y - 4.0), Vector2(deck.size.x, 4.0)), Palette.SHOGUN_LACQUER)
	for corner: Vector2 in [deck.position, deck.position + Vector2(deck.size.x, 0), deck.position + Vector2(0, deck.size.y), deck.end]:
		ci.draw_rect(Rect2(corner + Vector2(-1.5, -40), Vector2(3, 40)), INK)
		ci.draw_rect(Rect2(corner + Vector2(1.5, -40), Vector2(9, 16)), PLASTER)


## Shogun Kurogane without his art: black and gold armour, a crimson cloak, a
## gold crescent crest; `duel` shows the drawn blade instead of the raised fan.
static func draw_shogun(ci: CanvasItem, o: Vector2, r: float, flash: bool, duel: bool) -> void:
	var cloak := Rect2(o + Vector2(-r * 0.75, -r * 0.6), Vector2(r * 1.5, r * 1.8))
	ci.draw_rect(cloak, Glyphs._c(Palette.SHOGUN_LACQUER_DARK, flash))
	var body := Rect2(o + Vector2(-r * 0.5, -r * 0.7), Vector2(r * 1.0, r * 1.7))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Color(0.12, 0.10, 0.11), flash))
	for k in 3:
		ci.draw_rect(Rect2(body.position + Vector2(r * 0.08, r * (0.15 + 0.45 * float(k))), Vector2(body.size.x - r * 0.16, r * 0.14)), Glyphs._c(Palette.GOLD, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 1.05), r * 0.42, INK)
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 1.05), r * 0.34, Glyphs._c(Color(0.14, 0.11, 0.12), flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.6, -r * 1.75), Vector2(r * 1.2, r * 0.25)), Glyphs._c(Palette.GOLD, flash))  # The crescent crest.
	if duel:
		ci.draw_rect(Rect2(o + Vector2(r * 0.4, -r * 0.2), Vector2(r * 2.2, 2.0)), Glyphs._c(Color(0.86, 0.88, 0.92), flash))  # The drawn blade.
	else:
		ci.draw_rect(Rect2(o + Vector2(r * 0.55, -r * 2.1), Vector2(r * 0.7, r * 0.6)), Glyphs._c(Palette.GOLD, flash))  # The raised war fan.
