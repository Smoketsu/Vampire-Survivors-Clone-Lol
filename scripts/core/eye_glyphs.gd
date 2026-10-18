## EyeGlyphs — code-drawn fallback shapes for the ANCIENT EYE's kinds (Act II;
## GDD §15.0 "Act II: the Ancient Eye"), drawn by Glyphs.draw_enemy() when a kind
## has no sprite art (assets/sprites/eye/<kind>.png): a hooded cultist in drowned
## teal with one bioluminescent eye on the hood. The Chanter carries a raised
## sigil staff; any other Eye kind gets the plain cultist (its art lands later).
## Purely visual.
class_name EyeGlyphs
extends RefCounted


## Draws Ancient Eye kind `kind` (any kind; the plain cultist when it has no
## shape of its own). Always returns true.
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	# --- Act II: Gullhaven Harbour ---
	if HarbourGlyphs.draw_enemy(ci, kind, o, r, flash):
		return true  # A Harbour kind or structure (Deep Kin, Tide Caller, buoys...).
	if ArchiveGlyphs.draw_enemy(ci, kind, o, r, flash):
		return true  # A Hollow Archive kind (Act II, Stage 5).
	_cultist(ci, o, r, flash)
	if kind == "eye_chanter":
		# A staff topped by the Eye's sigil, held to the right.
		var top := o + Vector2(r * 1.05, -r * 1.55)  # Staff head.
		ci.draw_line(o + Vector2(r * 0.95, r * 0.75), top, Glyphs._c(Palette.BONE, flash), 2.0)
		ci.draw_circle(top, r * 0.34, Glyphs.OUTLINE)
		ci.draw_circle(top, r * 0.26, Glyphs._c(Palette.EYE_BIOLUME, flash))
		ci.draw_circle(top, r * 0.1, Glyphs._c(Palette.EYE_BIOLUME_GLOW, flash))
	return true


## A hooded cultist: a drowned-teal robe and hood, a pale face in the hood's
## shadow and one glowing eye sigil on the brow.
static func _cultist(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var robe := PackedVector2Array([o + Vector2(-r * 0.9, r * 0.95), o + Vector2(r * 0.9, r * 0.95),
		o + Vector2(r * 0.55, -r * 0.35), o + Vector2(-r * 0.55, -r * 0.35)])  # Robe trapezoid.
	ci.draw_colored_polygon(robe, Glyphs._c(Palette.EYE_DROWNED_DARK, flash))
	ci.draw_polyline(robe + PackedVector2Array([robe[0]]), Glyphs.OUTLINE, 1.0)
	ci.draw_circle(o + Vector2(0, -r * 0.55), r * 0.62, Glyphs.OUTLINE)
	ci.draw_circle(o + Vector2(0, -r * 0.55), r * 0.54, Glyphs._c(Palette.EYE_DROWNED, flash))  # Hood.
	ci.draw_circle(o + Vector2(0, -r * 0.42), r * 0.3, Glyphs._c(Palette.BONE.darkened(0.35), flash))  # Face in shadow.
	ci.draw_circle(o + Vector2(0, -r * 0.82), r * 0.14, Glyphs._c(Palette.EYE_BIOLUME_GLOW, flash))  # The Eye's sigil.
