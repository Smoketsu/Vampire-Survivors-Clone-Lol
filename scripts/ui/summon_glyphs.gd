## SummonGlyphs — code-drawn shapes of the later summon classes (no external
## assets), used for the unit in the world AND its UI icon, like Glyphs.
## Readability rule (GDD §16/§17, Glyphs header): every class has its own
## SILHOUETTE in the undead colour language (blue / violet / green / bone):
##   Corpse Abomination = huge lumpy blob of stitched grey-green flesh with a
##                        bone cleaver arm and a tiny embedded skull
##   Grave Rogue        = slim forward-leaning hooded chevron with two daggers
##   Crypt Gargoyle     = hunched stone body with wide bat wings and horns
##   Frost Wraith       = legless teardrop ghost with an ice crown and a
##                        floating ice shard, in a cold glow
## Also draws the Frost Wraith chill tint on enemies (draw_chill()).
class_name SummonGlyphs
extends RefCounted


## Returns the flash colour when `flash` is set, else `col`.
static func _c(col: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else col


## Draws summon class `cls` at `o` with body radius `r`. Returns false for a
## class this file does not draw.
static func draw_summon(ci: CanvasItem, cls: String, o: Vector2, r: float, flash: bool) -> bool:
	match cls:
		"abomination":
			draw_abomination(ci, o, r, flash)
		"rogue":
			draw_rogue(ci, o, r, flash)
		"gargoyle":
			draw_gargoyle(ci, o, r, flash)
		"frost_wraith":
			draw_frost_wraith(ci, o, r, flash)
		_:
			return false
	return true


## UI icon (level-up cards, HUD) for the classes drawn here; false otherwise.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"abomination":
			return draw_summon(ci, kind, c + Vector2(-s * 0.05, s * 0.05), s * 0.46, false)
		"rogue", "gargoyle", "frost_wraith":
			return draw_summon(ci, kind, c + Vector2(-s * 0.06, s * 0.08), s * 0.5, false)
	return false


## Corpse Abomination: overlapping flesh lumps, belly stitches, a small skull
## sunk into the shoulders, stubby legs and a bone cleaver on the right.
static func draw_abomination(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var flesh := _c(Palette.CORPSE_FLESH, flash)  # Body colour.
	var shade := _c(Palette.CORPSE_FLESH.darkened(0.3), flash)  # Lump shading.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.55, r * 0.75), Vector2(r * 0.35, r * 0.35)), Glyphs.OUTLINE)
	ci.draw_rect(Rect2(o + Vector2(r * 0.2, r * 0.75), Vector2(r * 0.35, r * 0.35)), Glyphs.OUTLINE)
	ci.draw_circle(o + Vector2(0, r * 0.15), r * 0.98, Glyphs.OUTLINE)
	ci.draw_circle(o + Vector2(-r * 0.55, -r * 0.25), r * 0.55, Glyphs.OUTLINE)
	ci.draw_circle(o + Vector2(0, r * 0.15), r * 0.9, flesh)
	ci.draw_circle(o + Vector2(-r * 0.55, -r * 0.25), r * 0.48, shade)
	ci.draw_circle(o + Vector2(r * 0.5, r * 0.4), r * 0.42, shade)
	ci.draw_circle(o + Vector2(-r * 0.2, r * 0.3), r * 0.45, flesh)
	# Stitches across the belly.
	ci.draw_line(o + Vector2(-r * 0.45, -r * 0.05), o + Vector2(r * 0.35, r * 0.65), _c(Palette.BONE, flash), 1.5)
	for i in 3:
		var p := o + Vector2(-r * 0.45, -r * 0.05).lerp(Vector2(r * 0.35, r * 0.65), 0.2 + 0.3 * float(i))  # Stitch point.
		ci.draw_line(p + Vector2(-r * 0.12, r * 0.12), p + Vector2(r * 0.12, -r * 0.12), _c(Palette.BONE, flash), 1.0)
	# Small skull sunk between the shoulders, green eyes.
	ci.draw_circle(o + Vector2(r * 0.05, -r * 0.62), r * 0.3, _c(Palette.BONE, flash))
	ci.draw_circle(o + Vector2(-r * 0.06, -r * 0.64), r * 0.08, Palette.NECRO_GREEN)
	ci.draw_circle(o + Vector2(r * 0.16, -r * 0.64), r * 0.08, Palette.NECRO_GREEN)
	# Bone cleaver arm.
	ci.draw_line(o + Vector2(r * 0.65, r * 0.0), o + Vector2(r * 1.2, -r * 0.55), _c(Palette.BONE, flash), 3.0)
	ci.draw_colored_polygon(PackedVector2Array([
		o + Vector2(r * 1.05, -r * 0.6), o + Vector2(r * 1.45, -r * 1.0), o + Vector2(r * 1.6, -r * 0.6), o + Vector2(r * 1.25, -r * 0.3)]),
		_c(Palette.UNDEAD_STEEL, flash))


## Grave Rogue: a forward-leaning hooded cloak (chevron), green eyes in the
## hood, a dagger in front and one held back, a violet sash.
static func draw_rogue(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var cloak := PackedVector2Array([
		o + Vector2(-r * 0.75, r * 1.05), o + Vector2(-r * 0.45, -r * 0.55), o + Vector2(r * 0.3, -r * 1.15),
		o + Vector2(r * 0.65, -r * 0.35), o + Vector2(r * 0.2, r * 0.25), o + Vector2(r * 0.8, r * 1.05)])
	ci.draw_colored_polygon(cloak, _c(Palette.ROGUE_CLOAK, flash))
	var edge := cloak.duplicate()  # Closed outline.
	edge.append(cloak[0])
	ci.draw_polyline(edge, _c(Palette.VIOLET.darkened(0.2), flash), 1.2)
	ci.draw_circle(o + Vector2(r * 0.15, -r * 0.45), r * 0.3, Glyphs.EYE)
	ci.draw_circle(o + Vector2(r * 0.07, -r * 0.47), r * 0.07, Palette.NECRO_GREEN)
	ci.draw_circle(o + Vector2(r * 0.27, -r * 0.47), r * 0.07, Palette.NECRO_GREEN)
	ci.draw_line(o + Vector2(-r * 0.55, r * 0.2), o + Vector2(r * 0.35, r * 0.05), _c(Palette.VIOLET, flash), 1.5)
	ci.draw_line(o + Vector2(r * 0.5, r * 0.25), o + Vector2(r * 1.3, -r * 0.1), _c(Palette.BONE, flash), 1.5)
	ci.draw_line(o + Vector2(-r * 0.55, r * 0.45), o + Vector2(-r * 1.2, r * 0.1), _c(Palette.BONE, flash), 1.5)


## Crypt Gargoyle: wide stone bat wings behind a hunched body, horned head
## with violet eyes, bone claws.
static func draw_gargoyle(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var wing := _c(Palette.GARGOYLE_STONE.darkened(0.3), flash)  # Wing membrane colour.
	for side: float in [-1.0, 1.0]:
		var pts := PackedVector2Array([
			o + Vector2(side * r * 0.2, -r * 0.35), o + Vector2(side * r * 1.6, -r * 1.0), o + Vector2(side * r * 1.3, -r * 0.25),
			o + Vector2(side * r * 1.6, r * 0.2), o + Vector2(side * r * 0.3, r * 0.35)])
		ci.draw_colored_polygon(pts, wing)
		ci.draw_line(o + Vector2(side * r * 0.2, -r * 0.35), o + Vector2(side * r * 1.6, -r * 1.0), _c(Palette.GARGOYLE_STONE, flash), 1.5)
	ci.draw_circle(o + Vector2(0, r * 0.25), r * 0.68, Glyphs.OUTLINE)
	ci.draw_circle(o + Vector2(0, r * 0.25), r * 0.6, _c(Palette.GARGOYLE_STONE, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.45), r * 0.4, _c(Palette.GARGOYLE_STONE.lightened(0.1), flash))
	ci.draw_line(o + Vector2(-r * 0.25, -r * 0.7), o + Vector2(-r * 0.45, -r * 1.15), _c(Palette.BONE, flash), 1.5)
	ci.draw_line(o + Vector2(r * 0.25, -r * 0.7), o + Vector2(r * 0.45, -r * 1.15), _c(Palette.BONE, flash), 1.5)
	ci.draw_circle(o + Vector2(-r * 0.14, -r * 0.47), r * 0.09, Palette.VIOLET)
	ci.draw_circle(o + Vector2(r * 0.14, -r * 0.47), r * 0.09, Palette.VIOLET)
	for i in 3:
		var x := (float(i) - 1.0) * r * 0.3  # Claw x offset.
		ci.draw_line(o + Vector2(x, r * 0.8), o + Vector2(x + r * 0.08, r * 1.05), _c(Palette.BONE, flash), 1.0)


## Frost Wraith: cold glow, a legless teardrop body trailing into a wisp,
## dark eye holes, an ice crown and an ice shard floating at its side.
static func draw_frost_wraith(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o, r * 1.2, Color(Palette.FROST, 0.14))
	var body := PackedVector2Array([
		o + Vector2(-r * 0.62, -r * 0.35), o + Vector2(r * 0.62, -r * 0.35), o + Vector2(r * 0.4, r * 0.4),
		o + Vector2(r * 0.05, r * 0.7), o + Vector2(r * 0.2, r * 1.2), o + Vector2(-r * 0.25, r * 0.75), o + Vector2(-r * 0.45, r * 0.3)])
	ci.draw_colored_polygon(body, _c(Palette.FROST.darkened(0.35), flash))
	ci.draw_circle(o + Vector2(0, -r * 0.4), r * 0.62, _c(Palette.FROST.darkened(0.2), flash))
	ci.draw_circle(o + Vector2(-r * 0.2, -r * 0.42), r * 0.14, Glyphs.EYE)
	ci.draw_circle(o + Vector2(r * 0.2, -r * 0.42), r * 0.14, Glyphs.EYE)
	ci.draw_circle(o + Vector2(-r * 0.2, -r * 0.42), r * 0.06, Palette.COLD_BLUE)
	ci.draw_circle(o + Vector2(r * 0.2, -r * 0.42), r * 0.06, Palette.COLD_BLUE)
	for i in 3:
		var x := (float(i) - 1.0) * r * 0.32  # Crown spike x offset.
		var h := r * (0.45 if i == 1 else 0.3)  # Spike height.
		ci.draw_colored_polygon(PackedVector2Array([o + Vector2(x - r * 0.1, -r * 0.92), o + Vector2(x, -r * 0.92 - h), o + Vector2(x + r * 0.1, -r * 0.92)]),
			_c(PowerupGlyphs.ICE, flash))
	var shard := o + Vector2(r * 1.05, -r * 0.7)  # Floating ice shard centre.
	ci.draw_colored_polygon(PackedVector2Array([shard + Vector2(0, -r * 0.35), shard + Vector2(r * 0.18, 0), shard + Vector2(0, r * 0.35), shard + Vector2(-r * 0.18, 0)]),
		_c(Palette.COLD_BLUE, flash))


## Frost Wraith chill on an enemy (drawn in its _draw()): a pale frost film
## and two ice ticks. The full Deep Freeze uses PowerupGlyphs.draw_frozen().
static func draw_chill(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r * 1.05, Color(Palette.FROST, 0.22))
	ci.draw_arc(c, r * 1.05, -2.4, -0.7, 10, Color(PowerupGlyphs.ICE, 0.7), 1.0)
	ci.draw_line(c + Vector2(-r * 0.9, r * 0.6), c + Vector2(-r * 1.25, r * 0.85), PowerupGlyphs.ICE, 1.0)
	ci.draw_line(c + Vector2(r * 0.9, r * 0.6), c + Vector2(r * 1.25, r * 0.85), PowerupGlyphs.ICE, 1.0)
