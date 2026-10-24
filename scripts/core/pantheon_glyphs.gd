## PantheonGlyphs — code-drawn fallback shapes for the OLYMPIAN REPUBLIC (Act
## IV; GDD §15.0 "Act IV foundation (phase 1)"), drawn when a kind has no
## sprite art (assets/sprites/pantheon/<kind>.png): bronze bodies with marble
## and Aegean-blue accents and bronze-ink outlines (the bronze, marble and
## aegean ramps, never the undead's bone and soul teal). Also the Act IV stubs'
## placeholder obstacles. Every Pantheon kind without a shape of its own gets
## the plain hoplite. Purely visual.
class_name PantheonGlyphs
extends RefCounted

## Outline ink of the bronze ramp ("bronze" darkest).
const INK := Color(0.118, 0.078, 0.031)


## Draws Olympian Republic kind `kind`. Returns false when `kind` is not a
## Pantheon kind (Glyphs.draw_enemy() then asks the Ancient Eye's glyphs).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	var row := EnemyDirector.pantheon_def(kind)  # Its design row ({} = not a Pantheon kind).
	if row.is_empty():
		return false
	match kind:
		"shade_of_dead":
			_shade(ci, o, r, flash)
		"hero":
			_hero(ci, o, r, flash)
		"bronze_titan":
			_titan(ci, o, r, flash)
		_:
			_hoplite(ci, o, r, flash)
	return true


## A Shade of the Dead: a pale, wispy marble-grey ghost with a hollow face and
## a trailing tail (no feet).
static func _shade(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var tail := PackedVector2Array([o + Vector2(-r * 0.75, 0.0), o + Vector2(r * 0.75, 0.0), o + Vector2(r * 0.2, r * 1.3), o + Vector2(-r * 0.3, r * 1.6)])
	ci.draw_colored_polygon(tail, Glyphs._c(Color(Palette.PANTHEON_MARBLE_DARK, 0.75), flash))
	ci.draw_circle(o, r * 0.85, Glyphs._c(Color(Palette.PANTHEON_MARBLE, 0.9), flash))
	ci.draw_circle(o + Vector2(-r * 0.2, -r * 0.25), r * 0.35, Glyphs._c(Palette.PANTHEON_MARBLE_LIGHT, flash))
	ci.draw_circle(o + Vector2(-r * 0.28, -r * 0.05), r * 0.14, INK)
	ci.draw_circle(o + Vector2(r * 0.22, -r * 0.05), r * 0.14, INK)
	ci.draw_arc(o, r * 1.05, 0.0, TAU, 18, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.35), 1.0)


## A Hoplite: a bronze-clad soldier, a crested Corinthian helmet, the big round
## bronze shield (aspis) held forward on the right (the facing side) and a
## spear.
static func _hoplite(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.55, -r * 0.4), Vector2(r * 1.1, r * 1.35))  # Tunic and legs.
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.CRIMSON.darkened(0.2), flash))
	ci.draw_rect(Rect2(body.position, Vector2(body.size.x, r * 0.45)), Glyphs._c(Palette.PANTHEON_BRONZE, flash))  # Cuirass.
	ci.draw_circle(o + Vector2(0, -r * 0.75), r * 0.48, INK)
	ci.draw_circle(o + Vector2(0, -r * 0.75), r * 0.4, Glyphs._c(Palette.PANTHEON_BRONZE, flash))  # Helmet.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.35, -r * 1.35), Vector2(r * 0.7, r * 0.25)), Glyphs._c(Palette.CRIMSON, flash))  # Crest.
	ci.draw_line(o + Vector2(-r * 0.6, r * 0.9), o + Vector2(-r * 0.6, -r * 1.6), INK, 2.0)  # Spear.
	ci.draw_line(o + Vector2(-r * 0.6, -r * 1.3), o + Vector2(-r * 0.6, -r * 1.75), Glyphs._c(Palette.PANTHEON_BRONZE_LIGHT, flash), 2.0)
	ci.draw_circle(o + Vector2(r * 0.55, r * 0.1), r * 0.62, INK)  # The aspis.
	ci.draw_circle(o + Vector2(r * 0.55, r * 0.1), r * 0.54, Glyphs._c(Palette.PANTHEON_BRONZE, flash))
	ci.draw_arc(o + Vector2(r * 0.55, r * 0.1), r * 0.42, 0.0, TAU, 16, Glyphs._c(Palette.PANTHEON_BRONZE_LIGHT, flash), 1.0)
	ci.draw_circle(o + Vector2(r * 0.55, r * 0.1), r * 0.12, Glyphs._c(Palette.GOLD, flash))


## A Hero: a grander hoplite in bronze and gold, an Aegean-blue cloak and a
## tall plume.
static func _hero(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var cloak := PackedVector2Array([o + Vector2(-r * 0.7, -r * 0.4), o + Vector2(r * 0.3, -r * 0.4), o + Vector2(r * 0.1, r * 1.1), o + Vector2(-r * 0.9, r * 1.0)])
	ci.draw_colored_polygon(cloak, Glyphs._c(Palette.PANTHEON_AEGEAN, flash))
	_hoplite(ci, o, r, flash)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.15, -r * 1.75), Vector2(r * 0.3, r * 0.6)), Glyphs._c(Palette.PANTHEON_AEGEAN_LIGHT, flash))  # Plume.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.5, -r * 0.4), Vector2(r * 1.0, r * 0.12)), Glyphs._c(Palette.GOLD, flash))  # Gold trim.


## A Bronze Titan: a huge bronze colossus, marble joints, glowing eyes.
static func _titan(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.7, -r * 0.55), Vector2(r * 1.4, r * 1.5))
	ci.draw_rect(body.grow(1.5), INK)
	ci.draw_rect(body, Glyphs._c(Palette.PANTHEON_BRONZE_DARK, flash))
	ci.draw_rect(Rect2(body.position + Vector2(r * 0.1, r * 0.1), Vector2(body.size.x - r * 0.2, r * 0.5)), Glyphs._c(Palette.PANTHEON_BRONZE, flash))
	for sx: float in [-1.0, 1.0]:
		ci.draw_circle(o + Vector2(sx * r * 0.85, -r * 0.35), r * 0.3, Glyphs._c(Palette.PANTHEON_MARBLE_DARK, flash))  # Shoulders.
	ci.draw_circle(o + Vector2(0, -r * 0.85), r * 0.42, INK)
	ci.draw_circle(o + Vector2(0, -r * 0.85), r * 0.35, Glyphs._c(Palette.PANTHEON_BRONZE, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.22, -r * 0.92), Vector2(r * 0.44, r * 0.1)), Glyphs._c(Palette.PANTHEON_AEGEAN_LIGHT, flash))  # Glowing eyes.


## Draws one of the Act IV stubs' placeholder obstacles (broken columns, marble
## blocks, bronze braziers). Returns false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"broken_column":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, INK)
			ci.draw_circle(c, r - 1.5, Palette.PANTHEON_MARBLE_DARK)
			ci.draw_circle(c, r * 0.75, Palette.PANTHEON_MARBLE)
			for k in 6:
				var a := TAU * float(k) / 6.0 + float(o.variant % 10) * 0.1  # Flute angle.
				ci.draw_line(c + Vector2.from_angle(a) * r * 0.3, c + Vector2.from_angle(a) * r * 0.72, Palette.PANTHEON_MARBLE_DARK, 1.0)
			ci.draw_circle(c + Vector2(-r * 0.25, -r * 0.3), r * 0.18, Palette.PANTHEON_MARBLE_LIGHT)
		"marble_block":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), Palette.PANTHEON_MARBLE_DARK)
			ci.draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size - Vector2(6, 8)), Palette.PANTHEON_MARBLE)
			ci.draw_line(Vector2(rect.position.x + 3, rect.position.y + 4), Vector2(rect.end.x - 3, rect.position.y + 4), Palette.PANTHEON_MARBLE_LIGHT, 1.0)
			ci.draw_line(Vector2(rect.position.x + 6, c.y), Vector2(rect.end.x - 6, c.y + 2.0), Palette.PANTHEON_MARBLE_DARK, 1.0)  # A crack.
		"bronze_brazier":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, INK)
			ci.draw_circle(c, r - 1.5, Palette.PANTHEON_BRONZE_DARK)
			ci.draw_circle(c, r * 0.65, Palette.PANTHEON_BRONZE)
			ci.draw_circle(c, r * 0.4, Palette.FLAME)
			ci.draw_circle(c, r * 0.2, Palette.PANTHEON_MARBLE_LIGHT)
		_:
			return false
	return true
