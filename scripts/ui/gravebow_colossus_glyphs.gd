## GravebowColossusGlyphs — code-drawn fallback shapes (no external assets)
## for two summon evolutions, their gold-framed UI icons and the curse tint:
##   Gravebow      = the Archer's triangle grown into a tall tattered hood
##                   (ragged hem), violet-eyed skull, a quiver of bone shafts
##                   and a HUGE bone longbow taller than the body with a
##                   nocked arrow burning with violet curse-fire,
##   Bone Colossus = the Abomination's flesh mass grown bigger and armoured in
##                   fused bone plates (a ribbed breastplate, spiked pauldron
##                   plates, a horned bone helm over the small skull) with a
##                   bone-slab club arm,
##   curse tint    = a violet film and a hovering violet curse rune over a
##                   cursed enemy (Gravebow curse; Enemy._draw()).
## SummonGlyphs.draw_summon() / draw_icon() dispatch these kinds here; units
## and icons always go through Glyphs.draw_summon(), so sprite art
## (assets/sprites/summons/gravebow.png, bone_colossus.png) wins when present.
## Colour language (Palette, GDD §11.2): undead bone / violet / green; Covenant
## gold only on the evolution icon frame (ProgressionGlyphs._gold_frame()).
class_name GravebowColossusGlyphs
extends RefCounted

## Gravebow hood colour (a darker, violet-shot version of the Archer's green).
const HOOD := Color(0.17, 0.27, 0.24)


## Returns the flash colour when `flash` is set, else `col`.
static func _c(col: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else col


## Draws summon glyph `kind` ("gravebow" | "bone_colossus") at `o` with body
## radius `r`. Returns false if the kind is unknown here.
static func draw_summon(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"gravebow":
			draw_gravebow(ci, o, r, flash)
		"bone_colossus":
			draw_bone_colossus(ci, o, r, flash)
		_:
			return false
	return true


## Draws the gold-framed evolution icon `kind` centred at `c` with half-size
## `s` (through Glyphs.draw_summon, so sprite art is used when present).
## Returns false if the kind is unknown here.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"gravebow":
			ProgressionGlyphs._gold_frame(ci, c, s)
			Glyphs.draw_summon(ci, kind, c + Vector2(-s * 0.1, s * 0.1), s * 0.42, false)
		"bone_colossus":
			ProgressionGlyphs._gold_frame(ci, c, s)
			Glyphs.draw_summon(ci, kind, c + Vector2(-s * 0.08, s * 0.06), s * 0.36, false)
		_:
			return false
	return true


## Gravebow: tall ragged hood, violet-eyed skull, quiver, huge bone longbow
## and a nocked arrow wreathed in violet curse-fire.
static func draw_gravebow(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	# Faint curse glow behind the body.
	ci.draw_circle(o + Vector2(r * 0.3, 0), r * 1.45, Color(Palette.VIOLET, 0.1))
	# Quiver on the back (left) with three bone shafts.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.95, -r * 0.6), Vector2(r * 0.38, r * 1.0)), _c(Palette.DEATH_STEEL, flash))
	for i in 3:
		var x := -r * 0.9 + r * 0.12 * float(i)  # Shaft x offset.
		ci.draw_line(o + Vector2(x, -r * 0.6), o + Vector2(x - r * 0.1, -r * 1.05), _c(Palette.BONE, flash), 1.0)
	# Tattered hood / cloak: a tall triangle with a ragged hem.
	var hood := PackedVector2Array([o + Vector2(0, -r * 1.25), o + Vector2(r * 0.7, -r * 0.35),
		o + Vector2(r * 0.85, r * 1.1), o + Vector2(r * 0.5, r * 0.85), o + Vector2(r * 0.25, r * 1.2),
		o + Vector2(-r * 0.05, r * 0.9), o + Vector2(-r * 0.35, r * 1.2), o + Vector2(-r * 0.6, r * 0.85),
		o + Vector2(-r * 0.85, r * 1.1), o + Vector2(-r * 0.7, -r * 0.35)])
	ci.draw_colored_polygon(hood, _c(HOOD, flash))
	ci.draw_polyline(ProgressionGlyphs._closed(hood), _c(Palette.VIOLET.darkened(0.25), flash), 1.2)
	# Bone clasp and a violet sash.
	ci.draw_line(o + Vector2(-r * 0.55, r * 0.2), o + Vector2(r * 0.6, -r * 0.05), _c(Palette.VIOLET, flash), 1.5)
	ci.draw_circle(o + Vector2(0, -r * 0.2), r * 0.1, _c(Palette.BONE, flash))
	# Skull deep in the hood, violet eyes.
	Glyphs._skull(ci, o + Vector2(0, -r * 0.62), r * 0.38, flash, Palette.VIOLET)
	# Huge bone longbow on the right, taller than the body.
	var bc := o + Vector2(r * 0.35, r * 0.05)  # Bow arc centre.
	var br := r * 1.45  # Bow radius.
	ci.draw_arc(bc, br, -1.05, 1.05, 14, Glyphs.OUTLINE, 4.0)
	ci.draw_arc(bc, br, -1.05, 1.05, 14, _c(Palette.BONE, flash), 2.5)
	var top := bc + Vector2.from_angle(-1.05) * br  # Upper bow tip.
	var bottom := bc + Vector2.from_angle(1.05) * br  # Lower bow tip.
	# Bone knuckle spikes at the tips and the grip.
	ci.draw_line(top, top + Vector2(r * 0.25, -r * 0.2), _c(Palette.BONE, flash), 1.5)
	ci.draw_line(bottom, bottom + Vector2(r * 0.25, r * 0.2), _c(Palette.BONE, flash), 1.5)
	ci.draw_circle(bc + Vector2(br, 0), r * 0.14, _c(Palette.IVORY, flash))
	# String drawn back to the nock, and the cursed arrow.
	var nock := o + Vector2(r * 0.05, r * 0.05)  # Drawn-back string point.
	ci.draw_line(top, nock, _c(Palette.IVORY, flash), 1.0)
	ci.draw_line(bottom, nock, _c(Palette.IVORY, flash), 1.0)
	var tip := o + Vector2(r * 2.05, r * 0.05)  # Arrowhead point.
	ci.draw_line(nock, tip, _c(Palette.BONE, flash), 1.5)
	ci.draw_circle(tip + Vector2(-r * 0.12, 0), r * 0.3, Color(Palette.VIOLET, 0.3))
	ci.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-r * 0.3, -r * 0.16), tip + Vector2(-r * 0.3, r * 0.16)]),
		_c(Palette.VIOLET, flash))
	# Curse-fire licking back along the shaft.
	for i in 3:
		var p := tip.lerp(nock, 0.25 + 0.2 * float(i))  # Flame tongue base.
		ci.draw_line(p, p + Vector2(-r * 0.15, -r * (0.3 - 0.06 * float(i))), Color(Palette.VIOLET, 0.75 - 0.2 * float(i)), 1.5)


## Bone Colossus: a towering stitched flesh mass armoured in fused bone
## plates, spiked pauldrons, a horned bone helm and a bone-slab club.
static func draw_bone_colossus(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var flesh := _c(Palette.CORPSE_FLESH.darkened(0.1), flash)  # Body colour.
	var shade := _c(Palette.CORPSE_FLESH.darkened(0.38), flash)  # Lump shading.
	var bone := _c(Palette.BONE, flash)  # Plate colour.
	var plate_dark := _c(Palette.BONE.darkened(0.3), flash)  # Plate seams / shading.
	# Thick legs with bone greaves.
	for sx: float in [-1.0, 1.0]:
		ci.draw_rect(Rect2(o + Vector2(sx * r * 0.42 - r * 0.22, r * 0.7), Vector2(r * 0.44, r * 0.45)), Glyphs.OUTLINE)
		ci.draw_rect(Rect2(o + Vector2(sx * r * 0.42 - r * 0.18, r * 0.72), Vector2(r * 0.36, r * 0.4)), plate_dark)
	# Flesh mass (outline first) with lumps.
	ci.draw_circle(o + Vector2(0, r * 0.1), r * 1.02, Glyphs.OUTLINE)
	ci.draw_circle(o + Vector2(-r * 0.6, -r * 0.3), r * 0.6, Glyphs.OUTLINE)
	ci.draw_circle(o + Vector2(0, r * 0.1), r * 0.94, flesh)
	ci.draw_circle(o + Vector2(-r * 0.6, -r * 0.3), r * 0.52, shade)
	ci.draw_circle(o + Vector2(r * 0.55, r * 0.45), r * 0.4, shade)
	# Fused bone breastplate: a shield of ribbed plates over the belly.
	var plate := PackedVector2Array([o + Vector2(-r * 0.6, -r * 0.35), o + Vector2(r * 0.55, -r * 0.4),
		o + Vector2(r * 0.65, r * 0.35), o + Vector2(0, r * 0.85), o + Vector2(-r * 0.62, r * 0.4)])
	ci.draw_colored_polygon(plate, bone)
	ci.draw_polyline(ProgressionGlyphs._closed(plate), plate_dark, 1.5)
	for i in 3:
		var y := -r * 0.18 + r * 0.25 * float(i)  # Rib seam height.
		var w := r * (0.55 - 0.1 * float(i))  # Seam half-width (narrowing).
		ci.draw_line(o + Vector2(-w, y), o + Vector2(w, y - r * 0.04), plate_dark, 1.5)
	ci.draw_circle(o + Vector2(0, r * 0.15), r * 0.1, Palette.NECRO_GREEN)  # Binding rune.
	# Spiked pauldron plates on both shoulders.
	for sx: float in [-1.0, 1.0]:
		var sh := o + Vector2(sx * r * 0.75, -r * 0.55)  # Shoulder centre.
		ci.draw_circle(sh, r * 0.34, plate_dark)
		ci.draw_circle(sh, r * 0.27, bone)
		ci.draw_colored_polygon(PackedVector2Array([sh + Vector2(-r * 0.1, -r * 0.2), sh + Vector2(sx * r * 0.18, -r * 0.62),
			sh + Vector2(r * 0.12, -r * 0.18)]), bone)
	# Horned bone helm over the small sunk skull, green eyes.
	var h := o + Vector2(r * 0.05, -r * 0.82)  # Helm centre.
	for sx: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([h + Vector2(sx * r * 0.2, -r * 0.12), h + Vector2(sx * r * 0.42, -r * 0.18),
			h + Vector2(sx * r * 0.55, -r * 0.62)]), bone)
	ci.draw_circle(h, r * 0.32, plate_dark)
	ci.draw_circle(h + Vector2(0, r * 0.03), r * 0.26, bone)
	ci.draw_rect(Rect2(h + Vector2(-r * 0.2, -r * 0.03), Vector2(r * 0.4, r * 0.1)), Glyphs.EYE)
	ci.draw_circle(h + Vector2(-r * 0.1, r * 0.02), r * 0.06, Palette.NECRO_GREEN)
	ci.draw_circle(h + Vector2(r * 0.1, r * 0.02), r * 0.06, Palette.NECRO_GREEN)
	# Bone-slab club arm on the right.
	ci.draw_line(o + Vector2(r * 0.75, -r * 0.1), o + Vector2(r * 1.25, -r * 0.6), _c(Palette.CORPSE_FLESH, flash), 4.0)
	var club := PackedVector2Array([o + Vector2(r * 1.05, -r * 0.55), o + Vector2(r * 1.35, -r * 1.25),
		o + Vector2(r * 1.75, -r * 1.1), o + Vector2(r * 1.55, -r * 0.4)])
	ci.draw_colored_polygon(club, bone)
	ci.draw_polyline(ProgressionGlyphs._closed(club), plate_dark, 1.5)
	for i in 2:
		var p := o + Vector2(r * 1.4, -r * 1.05).lerp(Vector2(r * 1.4, -r * 0.55), 0.3 + 0.4 * float(i))  # Spike root.
		ci.draw_line(p, p + Vector2(r * 0.35, -r * 0.05), bone, 1.5)


## Gravebow curse on an enemy (drawn in its _draw(), world-aligned enough to
## ignore its facing): a violet film over the body and a small curse rune (a
## violet eye in a broken ring) hovering at its side.
static func draw_curse(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r * 1.1, Color(Palette.VIOLET, 0.28))
	ci.draw_arc(c, r * 1.1, 0.4, PI - 0.4, 10, Color(Palette.VIOLET, 0.75), 1.2)
	var rune := c + Vector2(r * 0.95, -r * 1.25)  # Rune centre.
	ci.draw_arc(rune, r * 0.35 + 1.5, -2.6, 2.0, 10, Color(Palette.VIOLET, 0.9), 1.2)
	ci.draw_circle(rune, r * 0.16 + 1.0, Palette.VIOLET)
	ci.draw_circle(rune, r * 0.07 + 0.5, Palette.NECRO_GREEN)
