## UltimateGlyphs — code-drawn fallback icons of the content-wave-2 ultimates
## (UltimateData), in the flat Glyphs style, used until (or unless) the badge
## art assets/sprites/icons/<id>.png exists (that art always wins, through
## Glyphs.draw_icon()):
##   sovereigns_decree — a bone crown over a skull inside a violet ring,
##   eclipse           — a black sun with a pale lilac corona and a thin crescent,
##   grave_tide        — a soul-green wave with two skeletal hands rising.
## AbilityGlyphs.draw_icon() asks here last. Purely visual.
class_name UltimateGlyphs
extends RefCounted


## Draws icon `kind` centred at `c` with half-size `s`. Returns false if the
## kind is unknown.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"sovereigns_decree":
			var vio: Color = UltimateData.ULTIMATES[kind]["color"]
			ci.draw_arc(c, s * 0.74, 0.0, TAU, 28, Color(vio, 0.8), 2.0)
			Glyphs._skull(ci, c + Vector2(0.0, s * 0.18), s * 0.32, false, Palette.NECRO_GREEN)
			var crown := PackedVector2Array([
				c + Vector2(-s * 0.42, -s * 0.12), c + Vector2(-s * 0.42, -s * 0.5), c + Vector2(-s * 0.2, -s * 0.28),
				c + Vector2(0.0, -s * 0.6), c + Vector2(s * 0.2, -s * 0.28), c + Vector2(s * 0.42, -s * 0.5), c + Vector2(s * 0.42, -s * 0.12)])
			ci.draw_colored_polygon(crown, Palette.BONE)
		"eclipse":
			var blue: Color = UltimateData.ULTIMATES[kind]["color"]
			ci.draw_circle(c, s * 0.62, Color(blue.lightened(0.45), 0.55))
			ci.draw_circle(c, s * 0.5, Color(0.02, 0.02, 0.06))
			ci.draw_arc(c, s * 0.56, -PI * 0.15, PI * 0.65, 14, blue.lightened(0.7), 2.0)
			ci.draw_arc(c, s * 0.74, 0.0, TAU, 28, Color(blue, 0.6), 1.5)
		"grave_tide":
			var green: Color = UltimateData.ULTIMATES[kind]["color"]
			for i in 2:
				var x := (float(i) - 0.5) * s * 0.6  # Hand column.
				ci.draw_line(c + Vector2(x, s * 0.1), c + Vector2(x, -s * 0.45), Palette.BONE, 2.5)
				ci.draw_circle(c + Vector2(x, -s * 0.5), s * 0.11, Palette.BONE)
			var wave := PackedVector2Array([c + Vector2(-s * 0.75, s * 0.7), c + Vector2(-s * 0.75, s * 0.15),
				c + Vector2(-s * 0.35, s * 0.0), c + Vector2(0.0, s * 0.2), c + Vector2(s * 0.35, s * 0.0),
				c + Vector2(s * 0.75, s * 0.15), c + Vector2(s * 0.75, s * 0.7)])
			ci.draw_colored_polygon(wave, Color(green, 0.85))
			ci.draw_arc(c, s * 0.74, PI, TAU, 16, Color(green, 0.6), 1.5)
		_:
			return false
	return true
