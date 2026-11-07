## IlionGlyphs — code-drawn shapes of the Shores of Ilion (Act IV, Stage 10;
## GDD §15.0 "The Shores of Ilion (Act IV phase 2)"): the cyclopes' boulders
## (always code-drawn: in flight and held up during a throw), the fallback of
## Achilles when his art is missing, and the stage's six obstacle kinds when
## their sprites are missing. The stage's kinds fall back on PantheonGlyphs'
## plain hoplite. Bronze, marble and Aegean blue (the Republic's ramps), dark
## timber; never the undead's bone or soul teal. Purely visual.
class_name IlionGlyphs
extends RefCounted

## Dark timber of the ships, tents' poles and palisades (brown ramp ink).
const WOOD_DARK := Color(0.165, 0.102, 0.063)
## Timber (brown ramp).
const WOOD := Color(0.31, 0.2, 0.125)
## Boulder stone (grey ramp).
const STONE := Color(0.42, 0.48, 0.58)
## Boulder outline (grey ramp ink).
const STONE_INK := Color(0.118, 0.133, 0.157)


## A cyclops's boulder centred at `o`, radius `r`: a grey stone with a lit
## top-left and a crack. Visual only.
static func draw_boulder(ci: CanvasItem, o: Vector2, r: float) -> void:
	ci.draw_circle(o, r + 1.0, STONE_INK)
	ci.draw_circle(o, r, STONE)
	ci.draw_circle(o + Vector2(-r * 0.3, -r * 0.3), r * 0.45, STONE.lightened(0.25))
	ci.draw_line(o + Vector2(r * 0.1, -r * 0.2), o + Vector2(r * 0.5, r * 0.4), STONE_INK, 1.0)


## Achilles without art: a gold-armoured figure with a round gold shield, a
## blue crest and a long spear; `rage` drops the shield and the helmet.
static func draw_achilles(ci: CanvasItem, o: Vector2, r: float, flash: bool, rage: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.45, -r * 0.6), Vector2(r * 0.9, r * 1.6))  # Torso and legs.
	ci.draw_rect(body.grow(1.0), PantheonGlyphs.INK)
	ci.draw_rect(body, Glyphs._c(Palette.GOLD, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.95), r * 0.42, PantheonGlyphs.INK)
	ci.draw_circle(o + Vector2(0, -r * 0.95), r * 0.34, Glyphs._c(Palette.PANTHEON_BRONZE_LIGHT if rage else Palette.GOLD, flash))
	ci.draw_line(o + Vector2(-r * 0.6, r * 1.0), o + Vector2(-r * 0.6, -r * 2.2), Glyphs._c(Palette.PANTHEON_BRONZE_DARK, flash), 2.0)  # The spear.
	if not rage:
		ci.draw_rect(Rect2(o + Vector2(-r * 0.1, -r * 1.55), Vector2(r * 0.2, r * 0.5)), Glyphs._c(Palette.PANTHEON_AEGEAN, flash))  # The crest.
		ci.draw_circle(o + Vector2(r * 0.55, -r * 0.1), r * 0.62, PantheonGlyphs.INK)
		ci.draw_circle(o + Vector2(r * 0.55, -r * 0.1), r * 0.55, Glyphs._c(Palette.GOLD, flash))  # The shield.
		ci.draw_circle(o + Vector2(r * 0.55, -r * 0.1), r * 0.18, Glyphs._c(Palette.PANTHEON_BRONZE, flash))


## Draws one of the Shores of Ilion's obstacle kinds at its collision shape.
## Returns false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"sea_rock", "fallen_column":
			var r := o.radius
			var body := Color(0.28, 0.32, 0.38) if o.kind == "sea_rock" else Palette.PANTHEON_MARBLE_DARK  # Rock / marble.
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, PantheonGlyphs.INK)
			ci.draw_circle(c, r - 1.5, body)
			ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.4, body.lightened(0.18))
			if o.kind == "sea_rock":
				ci.draw_line(c + Vector2(r * 0.2, -r * 0.6), c + Vector2(r * 0.2, r * 0.5), Palette.PANTHEON_BRONZE, 2.0)  # The anchor.
		"siege_tent":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, Color(0.31, 0.28, 0.26))
			ci.draw_circle(c, r - 1.5, Palette.PANTHEON_MARBLE)
			for k in 4:
				var a := TAU * float(k) / 4.0 + 0.4  # A blue stripe's angle.
				ci.draw_line(c, c + Vector2.from_angle(a) * (r - 2.0), Palette.PANTHEON_AEGEAN, 2.0)
			ci.draw_circle(c, 2.5, WOOD)  # The pole.
		"beached_warship", "palisade", "troy_wall":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var body := WOOD if o.kind != "troy_wall" else Palette.PANTHEON_MARBLE_DARK  # Material.
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, WOOD_DARK if o.kind != "troy_wall" else PantheonGlyphs.INK)
			ci.draw_rect(rect.grow(-1.5), body)
			ci.draw_rect(Rect2(rect.position + Vector2(1.5, 1.5), Vector2(rect.size.x - 3.0, 3.0)), body.lightened(0.2))
			var long := Vector2(1, 0) if o.half.x >= o.half.y else Vector2(0, 1)  # Along it.
			var n := 5 if o.kind == "palisade" else 3
			for k in n:
				var q := c + long * (float(k) - float(n - 1) * 0.5) * (maxf(o.half.x, o.half.y) * 1.6 / float(n))
				ci.draw_circle(q, 2.0, Palette.PANTHEON_BRONZE if o.kind != "troy_wall" else Palette.PANTHEON_AEGEAN)
		_:
			return false
	return true
