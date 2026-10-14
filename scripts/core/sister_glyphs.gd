## SisterGlyphs — the code-drawn shapes of the Sister of the Scourge
## (BattleSisterData) and of her lash and zeal, drawn with CanvasItem draw_*
## calls into the CanvasItem currently inside its _draw(), like Glyphs and
## SanctumGlyphs (GDD §11 colour language: the Covenant is crimson / ivory /
## warm steel / gold; never violet). Her body here is only the fallback for
## a missing PNG (sprite key "enemies/battle_sister"; SanctumGlyphs.draw_enemy()
## delegates to it); the lash windup and the zeal glow are always drawn
## (BattleSisterKit.draw_over(), in unmirrored world-axis offsets).
class_name SisterGlyphs
extends RefCounted

## Dark outline colour behind the body (same as Glyphs.OUTLINE).
const OUTLINE := Color(0.0, 0.0, 0.0, 0.55)
## Warm skin of her face and arms (palette "skin").
const SKIN := Color(0.88, 0.66, 0.51)


## Returns the flash colour when `flash` is set, else `col`.
static func _c(col: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else col


## Fallback body: an hourglass crimson gown under an ivory veil with a gold
## circlet, the three-tailed scourge trailing from the front (+x) hand.
static func draw_body(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var gown := PackedVector2Array([
		o + Vector2(-r * 0.45, -r * 0.55), o + Vector2(r * 0.55, -r * 0.55),  # shoulders / bust
		o + Vector2(r * 0.25, -r * 0.05), o + Vector2(-r * 0.25, -r * 0.05),  # cinched waist
	])
	var skirt := PackedVector2Array([
		o + Vector2(-r * 0.25, -r * 0.05), o + Vector2(r * 0.25, -r * 0.05),
		o + Vector2(r * 0.8, r * 1.0), o + Vector2(-r * 0.8, r * 1.0),  # wide hips, long skirt
	])
	ci.draw_circle(o + Vector2(0, -r * 0.1), r * 1.0, OUTLINE)
	ci.draw_colored_polygon(skirt, _c(Palette.CRIMSON, flash))
	ci.draw_colored_polygon(gown, _c(Palette.DARK_CRIMSON, flash))
	ci.draw_circle(o + Vector2(r * 0.3, -r * 0.48), r * 0.28, _c(SKIN, flash))  # Neckline.
	ci.draw_line(o + Vector2(r * 0.1, r * 0.1), o + Vector2(r * 0.25, r * 0.95), _c(SKIN, flash), 2.0)  # The slit.
	ci.draw_circle(o + Vector2(0, -r * 0.95), r * 0.36, _c(Palette.IVORY, flash))  # Veil.
	ci.draw_circle(o + Vector2(r * 0.12, -r * 0.92), r * 0.2, _c(SKIN, flash))  # Face.
	ci.draw_line(o + Vector2(-r * 0.3, -r * 1.12), o + Vector2(r * 0.3, -r * 1.12), _c(Palette.GOLD, flash), 1.5)  # Circlet.
	var hand := o + Vector2(r * 0.75, -r * 0.1)  # Scourge handle.
	ci.draw_line(hand, hand + Vector2(r * 0.15, r * 0.3), _c(Palette.GOLD, flash), 2.0)
	for i in 3:
		var end := hand + Vector2(r * (0.45 + 0.25 * float(i)), r * (1.0 - 0.15 * float(i)))
		ci.draw_line(hand + Vector2(r * 0.15, r * 0.3), end, _c(Palette.CRIMSON, flash), 1.5)
		ci.draw_circle(end, 1.2, _c(Palette.SILVER, flash))  # Barb.


## The lash windup (`k` 0..1 of the telegraph): a crimson line along `dir`
## from her body to the lash tip `reach` px out, brightening, with a gold
## barb at the tip and the scourge raised behind her shoulder.
static func draw_lash_windup(ci: CanvasItem, dir: Vector2, r: float, reach: float, k: float) -> void:
	k = clampf(k, 0.0, 1.0)
	var from := dir * r  # Line start at her body's edge.
	var tip := dir * reach  # Lash tip.
	ci.draw_line(from, tip, Color(Palette.CRIMSON, 0.25 + 0.5 * k), 2.0 + 2.0 * k)
	ci.draw_line(from, tip, Color(Palette.GOLD, 0.15 + 0.45 * k), 1.0)
	ci.draw_circle(tip, 2.0 + 1.5 * k, Color(Palette.GOLD, 0.5 + 0.5 * k))
	var back := -dir * r * 0.9 + Vector2(0, -r * 1.1)  # The scourge drawn back over her shoulder.
	ci.draw_line(Vector2(0, -r * 0.4), back, Color(Palette.CRIMSON, 0.6 + 0.4 * k), 2.0)


## Zeal surge: a crimson flame ring at her feet and a gold chevron overhead.
static func draw_zeal(ci: CanvasItem, r: float) -> void:
	ci.draw_arc(Vector2(0, r * 0.7), r * 0.95, 0.0, TAU, 20, Color(Palette.CRIMSON, 0.7), 2.0)
	var c := Vector2(0, -r * 2.25)  # Chevron centre.
	ci.draw_polyline(PackedVector2Array([c + Vector2(-3.5, 1.5), c + Vector2(0, -2.0), c + Vector2(3.5, 1.5)]), Palette.CRIMSON, 2.0)
