## FortKesslerGlyphs — code-drawn fallbacks of Fort Kessler's art (Act VIII,
## Stage 23; GDD §15.0 "Fort Kessler art (Act VIII phase 2)"), used only when a
## PNG is missing (the art pass's sprites are drawn through SpriteBank first):
## General Harrow's command vehicle and his power armour. The kinds' fallbacks
## are CityGlyphs.draw_enemy()'s (by tier), the mines' Minefields' own. Visual
## only; textures and rects (SpriteBank.draw_disc()), no polygons.
class_name FortKesslerGlyphs
extends RefCounted

## Ink of the outlines (the act's ink).
const INK := Palette.CITY_INK


## General Harrow's command vehicle (an olive armoured car with a radio mast)
## for a body of radius `r` px on `ci`; white while `flash`.
static func draw_command_vehicle(ci: CanvasItem, r: float, flash: bool) -> void:
	var body := Color.WHITE if flash else Palette.CITY_OLIVE
	var hl := r * 1.5  # Half length (px).
	var hw := r * 0.9  # Half width (px).
	SpriteBank.draw_disc(ci, Vector2(2.0, hw * 0.6), hl, Color(0.0, 0.0, 0.0, 0.25))
	ci.draw_rect(Rect2(Vector2(-hl, -hw), Vector2(hl, hw) * 2.0), INK)
	ci.draw_rect(Rect2(Vector2(-hl + 2.0, -hw + 2.0), Vector2(hl - 2.0, hw - 2.0) * 2.0), body)
	ci.draw_rect(Rect2(Vector2(-hl * 0.3, -hw * 0.7), Vector2(hl * 0.8, hw * 1.0)), body.darkened(0.3))  # The cab.
	ci.draw_rect(Rect2(Vector2(-hl * 0.6, -hw - r * 0.9), Vector2(2.0, r * 0.9)), INK)  # The radio mast.
	SpriteBank.draw_disc(ci, Vector2(hl * 0.55, -hw * 0.1), r * 0.22, Palette.CITY_HAZARD)  # A hazard lamp (unlit).


## General Harrow on foot in his power armour (olive plates, a steel visor, a
## great hammer) for a body of radius `r` px on `ci`; white while `flash`; the
## chest plate scorched once Broken Arrow broke it (`broken`).
static func draw_harrow(ci: CanvasItem, r: float, flash: bool, broken: bool) -> void:
	var plate := Color.WHITE if flash else Palette.CITY_OLIVE
	SpriteBank.draw_disc(ci, Vector2(1.5, 2.0), r, Color(0.0, 0.0, 0.0, 0.3))
	SpriteBank.draw_disc(ci, Vector2.ZERO, r, INK)
	SpriteBank.draw_disc(ci, Vector2.ZERO, r - 2.0, plate)
	if broken:
		SpriteBank.draw_disc(ci, Vector2(r * 0.2, r * 0.1), r * 0.45, Color(0.1, 0.08, 0.06, 0.8))  # The scorched plate.
	SpriteBank.draw_disc(ci, Vector2(0.0, -r * 0.55), r * 0.38, Palette.CITY_CONCRETE_LIGHT)  # The helmet.
	ci.draw_rect(Rect2(Vector2(-r * 0.25, -r * 0.6), Vector2(r * 0.5, r * 0.12)), Palette.CITY_NEON_CYAN)  # The visor slit.
	ci.draw_rect(Rect2(Vector2(r * 0.6, -r * 1.1), Vector2(r * 0.18, r * 1.6)), INK)  # The hammer's haft.
	ci.draw_rect(Rect2(Vector2(r * 0.35, -r * 1.35), Vector2(r * 0.7, r * 0.4)), Palette.CITY_CONCRETE)  # Its head.
