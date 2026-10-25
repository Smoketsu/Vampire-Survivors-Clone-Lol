## OlympusGlyphs — code-drawn fallback shapes of Mount Olympus (Act IV, Stage
## 11; GDD §15.0 "Mount Olympus (Act IV phase 2)"), drawn when the art is
## missing: the zones' obstacle kinds (obstacles/<kind>_<size>[_v] replace them
## through EnvironmentArt) and Zeus (bosses/zeus*). The Olympian Republic's
## palette: bronze, marble, Aegean blue and the gods' gold, with the bronze ink
## outline (PantheonGlyphs.INK); never the undead's bone or soul teal. Purely
## visual.
class_name OlympusGlyphs
extends RefCounted

## Skin of the code-drawn Zeus (the skin ramp's light shade, #E0A882).
const SKIN := Color(0.878, 0.659, 0.510)


## Draws a Mount Olympus obstacle kind. Returns false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	var ink := PantheonGlyphs.INK
	match o.kind:
		"war_trophy":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, ink)
			ci.draw_circle(c, r - 1.5, Palette.PANTHEON_BRONZE_DARK)
			ci.draw_circle(c, r * 0.7, Palette.PANTHEON_BRONZE)  # A shield on the trophy post.
			ci.draw_circle(c, r * 0.25, Palette.PANTHEON_AEGEAN)
			ci.draw_line(c + Vector2(-r, r), c + Vector2(r, -r), Palette.PANTHEON_BRONZE_DARK, 2.0)  # A spear across it.
		"chariot_wreck":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, ink)
			ci.draw_rect(rect.grow(-1.5), Palette.PANTHEON_BRONZE_DARK)
			ci.draw_rect(rect.grow(-4.0), Palette.PANTHEON_BRONZE)
			var w := minf(o.half.x, o.half.y) * 0.9  # Wheel radius (px).
			ci.draw_arc(c, w, 0.0, TAU, 16, Palette.PANTHEON_BRONZE_LIGHT, 2.0)  # A broken wheel.
			ci.draw_line(c - Vector2(w, 0), c + Vector2(w, 0), Palette.PANTHEON_BRONZE_LIGHT, 1.0)
		"cypress":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.4))
			ci.draw_circle(c, r, Color(0.04, 0.08, 0.06))
			ci.draw_circle(c, r - 1.5, Color(0.10, 0.20, 0.14))
			ci.draw_circle(c + Vector2(-r * 0.2, -r * 0.25), r * 0.55, Color(0.16, 0.30, 0.20))
			ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.2, Color(Palette.PANTHEON_MARBLE_LIGHT, 0.25))  # Moonlight on the crown.
		"moon_shrine":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, ink)
			ci.draw_circle(c, r - 1.5, Palette.PANTHEON_MARBLE_DARK)
			ci.draw_circle(c, r * 0.75, Palette.PANTHEON_MARBLE)
			ci.draw_circle(c + Vector2(-1, 0), r * 0.35, Palette.PANTHEON_MARBLE_LIGHT)  # The silver crescent.
			ci.draw_circle(c + Vector2(r * 0.12, -r * 0.08), r * 0.3, Palette.PANTHEON_MARBLE)
		"fountain":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, ink)
			ci.draw_circle(c, r - 1.5, Palette.PANTHEON_MARBLE)
			ci.draw_circle(c, r * 0.72, Palette.PANTHEON_AEGEAN_DARK)
			ci.draw_circle(c, r * 0.55, Palette.PANTHEON_AEGEAN)  # The water.
			ci.draw_circle(c, r * 0.18, Palette.PANTHEON_MARBLE_LIGHT)  # The spout.
		"balustrade":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, ink)
			ci.draw_rect(rect.grow(-1.5), Palette.PANTHEON_MARBLE_DARK)
			ci.draw_rect(rect.grow(-3.0), Palette.PANTHEON_MARBLE)
			var long_x := o.half.x >= o.half.y  # Laid along x.
			var n := int((o.half.x if long_x else o.half.y) / 6.0)  # Balusters.
			for i in n:
				var t := (float(i) + 0.5) / float(n)
				var q := Vector2(lerpf(rect.position.x, rect.end.x, t), c.y) if long_x else Vector2(c.x, lerpf(rect.position.y, rect.end.y, t))
				ci.draw_circle(q, 1.5, Palette.PANTHEON_MARBLE_LIGHT)
		_:
			return false
	return true


## Zeus without his art (bosses/zeus*): a big marble-and-gold figure, white
## robe, gold crown, a raised thunderbolt; `colossus` draws him storm-veined.
static func draw_zeus(ci: CanvasItem, o: Vector2, r: float, flash: bool, colossus: bool) -> void:
	var robe := Rect2(o + Vector2(-r * 0.6, -r * 0.5), Vector2(r * 1.2, r * 1.6))
	ci.draw_rect(robe.grow(1.5), PantheonGlyphs.INK)
	ci.draw_rect(robe, Glyphs._c(Palette.PANTHEON_MARBLE_LIGHT, flash))
	ci.draw_rect(Rect2(robe.position + Vector2(0, r * 0.45), Vector2(robe.size.x, r * 0.18)), Glyphs._c(Palette.GOLD, flash))  # The belt.
	ci.draw_circle(o + Vector2(0, -r * 0.85), r * 0.45, PantheonGlyphs.INK)
	ci.draw_circle(o + Vector2(0, -r * 0.85), r * 0.38, Glyphs._c(SKIN, flash))  # The head.
	ci.draw_circle(o + Vector2(0, -r * 0.6), r * 0.32, Glyphs._c(Palette.PANTHEON_MARBLE_LIGHT, flash))  # The beard.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.35, -r * 1.3), Vector2(r * 0.7, r * 0.14)), Glyphs._c(Palette.GOLD, flash))  # The crown.
	ci.draw_line(o + Vector2(r * 0.6, -r * 0.3), o + Vector2(r * 0.9, -r * 1.6), Glyphs._c(Palette.PANTHEON_AEGEAN_LIGHT, flash), 3.0)  # The thunderbolt.
	if colossus:
		ci.draw_arc(o, r * 1.4, 0.0, TAU, 32, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.5), 2.0)
