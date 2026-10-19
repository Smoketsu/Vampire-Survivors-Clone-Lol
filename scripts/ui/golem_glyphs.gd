## GolemGlyphs — code-drawn fallback shapes (no external assets) of the Bone
## Golem (content wave 2, GDD §15.0 "Bone Golem (content wave 2)"), its
## evolution, its passive's and synergy's icons and its Bulwark marker.
## SummonGlyphs.draw_summon() / draw_icon() dispatch these kinds here; units
## and unit icons always go through Glyphs.draw_summon(), so sprite art in
## assets/sprites/summons/<kind>.png (and icons/<kind>.png) wins when present.
##   Bone Golem     = a wide square fortress block of bone slabs on grave-dirt
##                    brown, skull battlements on both shoulders, a small skull
##                    head sunk between them, a teal soul-fire hearth in the
##                    ribcage and two huge low fists,
##   Ossuary Titan  = the same, taller, with grey gravestone pauldrons and a
##                    crown of three skull towers behind the head,
##   Grave Masonry  = a bone wall of stacked blocks behind a skull keystone
##                    (passive icon),
##   Charnel House  = a bone fist slamming into a flesh stomp ring (synergy
##                    icon: the Golem's setter meets the Abomination's finisher),
##   Bulwark        = a ring of short bone stakes around a planted Golem's feet.
## Colour language (ART_BIBLE): the undead army's bone, cold grey, grave-dirt
## brown and teal soul fire; never violet, gold only on the evolution frame
## (ProgressionGlyphs._gold_frame()). Polygons are convex so they triangulate.
class_name GolemGlyphs
extends RefCounted

## Grave-dirt brown (the packed earth binding the bones).
const DIRT := Color(0.31, 0.20, 0.13)
## Lighter dirt (lit earth).
const DIRT_LIGHT := Color(0.55, 0.38, 0.25)
## Bone shadow (the darker slabs).
const BONE_SHADE := Color(0.50, 0.47, 0.37)
## Grave-stone grey (the Titan's pauldrons, fists' stones).
const GRAVESTONE := Color(0.42, 0.48, 0.58)
## Soul-fire teal (the hearth in the ribcage, the eye glints).
const SOUL := Color(0.24, 0.80, 0.58)
## Stakes drawn around a planted Golem (Bulwark marker; drawing only).
const STAKES: int = 10


## Returns the flash colour when `flash` is set, else `col`.
static func _c(col: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else col


## Draws summon glyph `kind` at `o` with body radius `r`. Returns false if the
## kind is unknown here.
static func draw_summon(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"bone_golem":
			draw_golem(ci, o, r, flash, false)
		"ossuary_titan":
			draw_golem(ci, o, r, flash, true)
		_:
			return false
	return true


## Draws UI icon `kind` centred at `c` with half-size `s`. Returns false if the
## kind is unknown here.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"bone_golem":
			Glyphs.draw_summon(ci, kind, c + Vector2(0, s * 0.08), s * 0.46, false)
		"ossuary_titan":
			ProgressionGlyphs._gold_frame(ci, c, s)
			Glyphs.draw_summon(ci, kind, c + Vector2(0, s * 0.12), s * 0.4, false)
		"grave_masonry":
			_icon_masonry(ci, c, s)
		"syn_charnel_house":
			_icon_charnel_house(ci, c, s)
		_:
			return false
	return true


## Bone Golem / Ossuary Titan (`titan`): a skull fortress facing right (see
## the header). `r` is the body radius.
static func draw_golem(ci: CanvasItem, o: Vector2, r: float, flash: bool, titan: bool) -> void:
	var bone := _c(Palette.BONE, flash)  # Lit bone.
	var shade := _c(BONE_SHADE, flash)  # Bone in shadow.
	var dirt := _c(DIRT, flash)  # Packed earth.
	var h := 1.25 if titan else 1.0  # Height factor.
	# Legs: two short stumps of stacked bone.
	for sx: float in [-0.45, 0.35]:
		ci.draw_rect(Rect2(o + Vector2(r * sx, r * 0.55), Vector2(r * 0.42, r * 0.5)), dirt)
		ci.draw_rect(Rect2(o + Vector2(r * sx, r * 0.95), Vector2(r * 0.5, r * 0.14)), bone)
	# The fortress block of the body.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.8, -r * 0.65 * h), Vector2(r * 1.6, r * (1.25 + 0.65 * (h - 1.0)))), dirt)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.7, -r * 0.55 * h), Vector2(r * 1.4, r * 0.3)), bone)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.6, -r * 0.15 * h), Vector2(r * 1.2, r * 0.22)), shade)
	# Ribcage over the soul-fire hearth.
	ci.draw_circle(o + Vector2(0, r * 0.15), r * 0.26, _c(SOUL, flash))
	for i in 3:
		var y := r * (-0.02 + 0.16 * float(i))
		ci.draw_line(o + Vector2(-r * 0.42, y), o + Vector2(r * 0.42, y), bone, maxf(1.5, r * 0.09))
	# Skull battlements on both shoulders (and the Titan's gravestone pauldrons).
	for side: float in [-1.0, 1.0]:
		var sh := o + Vector2(r * 0.78 * side, -r * 0.62 * h)  # Shoulder top.
		if titan:
			ci.draw_rect(Rect2(sh + Vector2(-r * 0.32, -r * 0.08), Vector2(r * 0.64, r * 0.42)), _c(GRAVESTONE, flash))
		for k in 3:
			Glyphs._skull(ci, sh + Vector2(r * (0.26 * float(k - 1)), -r * (0.18 + 0.06 * float(k % 2))), r * 0.17, flash, SOUL)
		# Arm down to a huge low fist.
		ci.draw_rect(Rect2(sh + Vector2(-r * 0.2, 0.0), Vector2(r * 0.4, r * 0.95)), dirt)
		ci.draw_circle(sh + Vector2(r * 0.05 * side, r * 1.1), r * 0.36, bone)
		ci.draw_circle(sh + Vector2(r * 0.05 * side, r * 1.1), r * 0.16, _c(GRAVESTONE, flash))
	if titan:
		# A crown of three skull towers behind the head.
		for k in 3:
			var tx := r * 0.32 * float(k - 1)
			ci.draw_rect(Rect2(o + Vector2(tx - r * 0.1, -r * 1.3 * h), Vector2(r * 0.2, r * 0.45)), _c(GRAVESTONE, flash))
			Glyphs._skull(ci, o + Vector2(tx, -r * 1.36 * h), r * 0.13, flash, SOUL)
	# The small skull head sunk between the shoulders.
	Glyphs._skull(ci, o + Vector2(r * 0.12, -r * 0.82 * h), r * 0.3, flash, SOUL)


## A planted Golem's Bulwark: short bone stakes ringing its feet, `k` (0..1)
## fading them out at the end of the plant. Drawn in world-aligned space.
static func draw_bulwark_stakes(ci: CanvasItem, feet: Vector2, r: float, k: float) -> void:
	var col := Color(Palette.BONE, 0.85 * k)  # Stake colour.
	var ink := Color(DIRT, 0.7 * k)  # Ground ring colour.
	ci.draw_arc(feet, r, 0.0, TAU, 32, ink, 2.0)
	for i in STAKES:
		var a := TAU * float(i) / float(STAKES)  # Stake angle.
		var base := feet + Vector2(cos(a) * r, sin(a) * r * 0.55)  # Flattened ground ring.
		ci.draw_line(base, base + Vector2(0, -r * 0.35), col, 2.0)


## Grave Masonry: a wall of stacked bone blocks behind a skull keystone.
static func _icon_masonry(ci: CanvasItem, c: Vector2, s: float) -> void:
	for row in 3:
		var y := c.y + s * (0.32 - 0.3 * float(row))  # Row top.
		var off := s * 0.18 if row % 2 == 1 else 0.0  # Running bond.
		for col in 3:
			var x := c.x - s * 0.62 + off + s * 0.42 * float(col)
			if x + s * 0.38 > c.x + s * 0.66:
				continue
			ci.draw_rect(Rect2(Vector2(x, y), Vector2(s * 0.38, s * 0.26)), Palette.BONE if (row + col) % 2 == 0 else BONE_SHADE)
	Glyphs._skull(ci, c + Vector2(0, -s * 0.42), s * 0.24, false, SOUL)


## Charnel House: a bone fist slamming into a flesh stomp ring.
static func _icon_charnel_house(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_arc(c + Vector2(0, s * 0.32), s * 0.58, PI, TAU, 16, Palette.CORPSE_FLESH, 3.0)
	ci.draw_rect(Rect2(c + Vector2(-s * 0.12, -s * 0.62), Vector2(s * 0.24, s * 0.5)), DIRT_LIGHT)
	ci.draw_circle(c + Vector2(0, s * 0.02), s * 0.3, Palette.BONE)
	ci.draw_circle(c + Vector2(0, s * 0.02), s * 0.12, GRAVESTONE)
	for i in 4:
		var a := PI + PI * (0.15 + 0.23 * float(i))  # Shard angle (upper half).
		ci.draw_line(c + Vector2(0, s * 0.3) + Vector2.from_angle(a) * s * 0.4, c + Vector2(0, s * 0.3) + Vector2.from_angle(a) * s * 0.62, Palette.BONE, 2.0)
