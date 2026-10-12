## AbilityGlyphs — code-drawn fallback icons for the necromancer's manual
## abilities (GDD §5.5) and their Ossuary upgrades, in the flat Glyphs style:
##   grave_step     — a robed shadow stepping right, two fading afterimages
##                    behind it (the dash; HUD, Settings, Ossuary).
##   dread_rally    — a green-eyed skull in a violet burst ring with three
##                    rising soul wisps (the ultimate; HUD).
##   twin_shadow    — two overlapping step silhouettes (Ossuary: second
##                    Grave Step charge).
##   restless_shade — a step silhouette inside a clock arc (Ossuary: Grave
##                    Step cooldown).
## Glyphs.draw_icon() reaches draw_icon() here last in its fall-through chain
## (after SpellGlyphs), and dedicated icon art (assets/sprites/icons/<kind>.png,
## ART_BIBLE) still wins over these shapes. Purely visual.
class_name AbilityGlyphs
extends RefCounted

## Shadow-violet of the Grave Step silhouettes.
const SHADE := Color(0.42, 0.24, 0.72)


## Draws icon `kind` centred at `c` with half-size `s`. Returns false if the
## kind is unknown.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"grave_step":
			for i in 2:
				var off := Vector2(-s * (0.55 - 0.25 * float(i)), 0.0)  # Afterimage offset.
				_shade(ci, c + off, s * 0.5, Color(SHADE, 0.3 + 0.25 * float(i)))
			_shade(ci, c + Vector2(s * 0.25, 0.0), s * 0.5, SHADE.lightened(0.15))
			ci.draw_line(c + Vector2(-s * 0.7, s * 0.55), c + Vector2(s * 0.6, s * 0.55), Color(Palette.NECRO_GREEN, 0.7), 1.5)
		"dread_rally":
			ci.draw_circle(c, s * 0.72, Color(0.30, 0.08, 0.45, 0.55))
			ci.draw_arc(c, s * 0.72, 0.0, TAU, 28, Palette.VIOLET, 2.0)
			for i in 3:
				var a := -PI / 2.0 + (float(i) - 1.0) * 0.7  # Wisp angle.
				var tip := c + Vector2.from_angle(a) * s * 0.78
				ci.draw_line(c + Vector2.from_angle(a) * s * 0.45, tip, Color(Palette.NECRO_GREEN, 0.8), 2.0)
				ci.draw_circle(tip, s * 0.09, Palette.NECRO_GREEN)
			Glyphs._skull(ci, c + Vector2(0, s * 0.08), s * 0.36, false, Palette.NECRO_GREEN)
		"twin_shadow":
			_shade(ci, c + Vector2(-s * 0.22, 0.0), s * 0.55, Color(SHADE, 0.55))
			_shade(ci, c + Vector2(s * 0.22, 0.0), s * 0.55, SHADE.lightened(0.15))
			ci.draw_circle(c + Vector2(s * 0.55, -s * 0.55), s * 0.12, Palette.NECRO_GREEN)
			ci.draw_circle(c + Vector2(s * 0.3, -s * 0.55), s * 0.12, Palette.NECRO_GREEN)
		"restless_shade":
			ci.draw_arc(c, s * 0.68, 0.0, TAU, 28, Color(Palette.VIOLET, 0.5), 1.5)
			ci.draw_arc(c, s * 0.68, -PI / 2.0, PI * 0.6, 16, Palette.NECRO_GREEN, 3.0)
			_shade(ci, c + Vector2(0.0, s * 0.05), s * 0.45, SHADE.lightened(0.15))
		_:
			return false
	return true


## A hooded, robed silhouette `r` px tall from its centre (the Grave Step
## shadow), filled with `col`.
static func _shade(ci: CanvasItem, o: Vector2, r: float, col: Color) -> void:
	var robe := PackedVector2Array([o + Vector2(r * 0.1, -r * 0.95), o + Vector2(-r * 0.75, r * 0.95), o + Vector2(r * 0.7, r * 0.95)])
	ci.draw_colored_polygon(robe, col)
	ci.draw_circle(o + Vector2(r * 0.05, -r * 0.55), r * 0.38, col.darkened(0.25))
	ci.draw_circle(o + Vector2(r * 0.18, -r * 0.55), r * 0.08, Color(Palette.NECRO_GREEN, col.a))
