## SummonGlyphs — code-drawn shapes for the summon classes and evolutions
## added by the priest split and the summon evolutions (user request), plus
## their UI icons. Glyphs.draw_summon() and Glyphs.draw_icon() fall through
## to this file for these kinds. Every silhouette is distinct (GDD §11 / §16
## readability rule, by SHAPE first, colour second):
##   Grave Mender   = round teal robe + green halo (the old priest, Glyphs)
##   Crypt Warder   = downward-pointing heater-shaped robe + floating blue
##                    ward sigil + lantern staff
##   Profane Bishop = wide bell robe + tall bone mitre + crook staff
##   Death Knight   = blackened plate with spiked pauldrons, horned helm,
##                    tattered cape and a long rune greatsword (bigger)
##   Lich           = floating tapering wisp robe (no feet), bone crown,
##                    soul-flame staff and green eyes
##   Risen skeleton = bare ribcage and legs, violet eyes, rusty blade (the
##                    Lich's temporary raised dead; also green temp aura)
## Colour language (Palette, GDD §11.2): undead blue / violet / green / bone;
## no Covenant gold except the evolution icon frame (ProgressionGlyphs).
class_name SummonGlyphs
extends RefCounted


## Draws summon glyph `kind` at `o` with body radius `r`. Returns false if
## the kind is unknown here.
static func draw_summon(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"warder":
			draw_warder(ci, o, r, flash)
		"bishop":
			draw_bishop(ci, o, r, flash)
		"death_knight":
			draw_death_knight(ci, o, r, flash)
		"lich":
			draw_lich(ci, o, r, flash)
		"risen":
			draw_risen(ci, o, r, flash)
		_:
			return false
	return true


## Draws UI icon `kind` centred at `c` with half-size `s`. Returns false if
## the kind is unknown here. Evolved classes get the gold evolution frame.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"warder", "bishop", "risen":
			draw_summon(ci, kind, c + Vector2(-s * 0.08, s * 0.08), s * 0.5, false)
		"death_knight", "lich":
			ProgressionGlyphs._gold_frame(ci, c, s)
			draw_summon(ci, kind, c + Vector2(-s * 0.08, s * 0.1), s * 0.45, false)
		"profane_bishop":
			ProgressionGlyphs._gold_frame(ci, c, s)
			draw_bishop(ci, c + Vector2(0, s * 0.1), s * 0.45, false)
		"forbidden_knowledge":
			# Open grimoire with a violet eye on its pages.
			var left := PackedVector2Array([c + Vector2(-s * 0.62, -s * 0.3), c + Vector2(-s * 0.02, -s * 0.18),
				c + Vector2(-s * 0.02, s * 0.5), c + Vector2(-s * 0.62, s * 0.38)])
			var right := PackedVector2Array([c + Vector2(s * 0.62, -s * 0.3), c + Vector2(s * 0.02, -s * 0.18),
				c + Vector2(s * 0.02, s * 0.5), c + Vector2(s * 0.62, s * 0.38)])
			ci.draw_colored_polygon(left, Palette.BONE.darkened(0.15))
			ci.draw_colored_polygon(right, Palette.BONE)
			ci.draw_line(c + Vector2(0, -s * 0.2), c + Vector2(0, s * 0.5), Palette.ROBE, 2.0)
			ci.draw_circle(c + Vector2(0, -s * 0.48), s * 0.2, Color(Palette.VIOLET, 0.35))
			ci.draw_circle(c + Vector2(0, -s * 0.48), s * 0.12, Palette.VIOLET)
			ci.draw_circle(c + Vector2(0, -s * 0.48), s * 0.05, Palette.NECRO_GREEN)
		"dark_benediction":
			# A green halo raining blessing rays onto a bone skull.
			ci.draw_arc(c + Vector2(0, -s * 0.5), s * 0.32, 0.0, TAU, 18, Palette.NECRO_GREEN, 2.0)
			for i in 3:
				var x := -s * 0.3 + s * 0.3 * float(i)
				ci.draw_line(c + Vector2(x, -s * 0.28), c + Vector2(x * 1.3, s * 0.05), Color(Palette.NECRO_GREEN, 0.6), 1.5)
			Glyphs._skull(ci, c + Vector2(0, s * 0.3), s * 0.3, false, Palette.NECRO_GREEN)
		_:
			return false
	return true


## Crypt Warder: a downward-pointing heater-shaped cold-blue robe (a living
## shield), skull, a floating ward sigil above the head and a lantern staff.
static func draw_warder(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var robe := PackedVector2Array([o + Vector2(-r * 0.85, -r * 0.35), o + Vector2(r * 0.85, -r * 0.35),
		o + Vector2(r * 0.85, r * 0.45), o + Vector2(0, r * 1.2), o + Vector2(-r * 0.85, r * 0.45)])
	ci.draw_colored_polygon(Glyphs.regular_polygon(o + Vector2(0, r * 0.3), r * 1.0, 5, PI / 2.0), Glyphs.OUTLINE)
	ci.draw_colored_polygon(robe, Glyphs._c(Palette.WARDER_ROBE, flash))
	# Ward rune on the chest: a downward chevron and a dot (never a cross,
	# which is Covenant iconography).
	ci.draw_polyline(PackedVector2Array([o + Vector2(-r * 0.42, -r * 0.05), o + Vector2(0, r * 0.45), o + Vector2(r * 0.42, -r * 0.05)]),
		Glyphs._c(Palette.COLD_BLUE, flash), 1.5)
	ci.draw_circle(o + Vector2(0, r * 0.75), r * 0.1, Glyphs._c(Palette.COLD_BLUE, flash))
	Glyphs._skull(ci, o + Vector2(0, -r * 0.62), r * 0.42, flash, Color(0.1, 0.25, 0.55))
	# Ward sigil: a cold-blue ring with a rune triangle, floating above.
	var sig := o + Vector2(0, -r * 1.4)
	ci.draw_arc(sig, r * 0.45, 0.0, TAU, 16, Glyphs._c(Palette.COLD_BLUE, flash), 1.5)
	ci.draw_polyline(ProgressionGlyphs._closed(Glyphs.regular_polygon(sig, r * 0.28, 3, -PI / 2.0)), Glyphs._c(Palette.COLD_BLUE, flash), 1.0)
	# Lantern staff on the right.
	ci.draw_line(o + Vector2(r * 1.0, r * 1.05), o + Vector2(r * 1.0, -r * 0.85), Glyphs._c(Palette.BONE, flash), 1.5)
	ci.draw_rect(Rect2(o + Vector2(r * 0.82, -r * 1.2), Vector2(r * 0.36, r * 0.38)), Glyphs._c(Palette.COLD_BLUE, flash))
	ci.draw_circle(o + Vector2(r * 1.0, -r * 1.01), r * 0.32, Color(Palette.COLD_BLUE, 0.25))


## Profane Bishop: a wide violet bell robe with green stoles, a tall bone
## mitre, a crook staff and two soul motes (it is the biggest support unit).
static func draw_bishop(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var robe := PackedVector2Array([o + Vector2(-r * 0.5, -r * 0.3), o + Vector2(r * 0.5, -r * 0.3),
		o + Vector2(r * 1.0, r * 1.1), o + Vector2(-r * 1.0, r * 1.1)])
	ci.draw_colored_polygon(robe, Glyphs._c(Palette.BISHOP_ROBE, flash))
	ci.draw_line(o + Vector2(-r * 0.25, -r * 0.2), o + Vector2(-r * 0.4, r * 1.05), Glyphs._c(Palette.NECRO_GREEN, flash), 2.0)
	ci.draw_line(o + Vector2(r * 0.25, -r * 0.2), o + Vector2(r * 0.4, r * 1.05), Glyphs._c(Palette.NECRO_GREEN, flash), 2.0)
	Glyphs._skull(ci, o + Vector2(0, -r * 0.55), r * 0.38, flash, Color(0.1, 0.45, 0.2))
	# Mitre: tall pointed bone hat with a green slit.
	var mitre := PackedVector2Array([o + Vector2(-r * 0.36, -r * 0.8), o + Vector2(r * 0.36, -r * 0.8),
		o + Vector2(r * 0.3, -r * 1.35), o + Vector2(0, -r * 1.8), o + Vector2(-r * 0.3, -r * 1.35)])
	ci.draw_colored_polygon(mitre, Glyphs._c(Palette.BONE, flash))
	ci.draw_line(o + Vector2(0, -r * 0.85), o + Vector2(0, -r * 1.6), Glyphs._c(Palette.NECRO_GREEN, flash), 1.5)
	# Crook staff on the left.
	ci.draw_line(o + Vector2(-r * 1.15, r * 1.1), o + Vector2(-r * 1.15, -r * 1.1), Glyphs._c(Palette.BONE, flash), 1.5)
	ci.draw_arc(o + Vector2(-r * 0.92, -r * 1.1), r * 0.24, PI, TAU, 8, Glyphs._c(Palette.NECRO_GREEN, flash), 1.5)
	ci.draw_circle(o + Vector2(r * 1.05, -r * 0.6), r * 0.13, Color(Palette.NECRO_GREEN, 0.8))
	ci.draw_circle(o + Vector2(r * 0.85, -r * 1.05), r * 0.09, Color(Palette.NECRO_GREEN, 0.6))


## Death Knight: blackened plate under a tattered violet cape, spiked
## pauldrons, a horned helm with violet eyes and a long rune greatsword.
static func draw_death_knight(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var cape := PackedVector2Array([o + Vector2(-r * 0.85, -r * 0.4), o + Vector2(r * 0.85, -r * 0.4),
		o + Vector2(r * 1.1, r * 1.15), o + Vector2(r * 0.4, r * 0.95), o + Vector2(0, r * 1.2),
		o + Vector2(-r * 0.4, r * 0.95), o + Vector2(-r * 1.1, r * 1.15)])
	ci.draw_colored_polygon(cape, Glyphs._c(Palette.ROBE, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.72, -r * 0.45), Vector2(r * 1.44, r * 1.4)), Glyphs.OUTLINE)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.62, -r * 0.35), Vector2(r * 1.24, r * 1.2)), Glyphs._c(Palette.DEATH_STEEL, flash))
	# Dread rune on the breastplate: a violet diamond outline.
	ci.draw_polyline(ProgressionGlyphs._closed(PackedVector2Array([o + Vector2(0, -r * 0.2), o + Vector2(r * 0.3, r * 0.2),
		o + Vector2(0, r * 0.6), o + Vector2(-r * 0.3, r * 0.2)])), Glyphs._c(Palette.VIOLET, flash), 1.5)
	# Spiked pauldrons.
	for sx: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([o + Vector2(sx * r * 1.05, -r * 0.55), o + Vector2(sx * r * 0.35, -r * 0.6),
			o + Vector2(sx * r * 0.5, -r * 0.05)]), Glyphs._c(Palette.UNDEAD_STEEL, flash))
	# Horned helm with glowing violet eyes.
	var h := o + Vector2(0, -r * 0.8)
	for sx: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([h + Vector2(sx * r * 0.3, -r * 0.1), h + Vector2(sx * r * 0.55, -r * 0.2),
			h + Vector2(sx * r * 0.75, -r * 0.75)]), Glyphs._c(Palette.BONE, flash))
	ci.draw_circle(h, r * 0.42, Glyphs._c(Palette.DEATH_STEEL.lightened(0.15), flash))
	ci.draw_rect(Rect2(h + Vector2(-r * 0.28, -r * 0.08), Vector2(r * 0.56, r * 0.14)), Glyphs.EYE)
	ci.draw_circle(h + Vector2(-r * 0.14, -r * 0.01), r * 0.07, Palette.VIOLET)
	ci.draw_circle(h + Vector2(r * 0.14, -r * 0.01), r * 0.07, Palette.VIOLET)
	# Greatsword: long cold-blue rune blade with a bone crossguard.
	ci.draw_line(o + Vector2(r * 0.85, r * 0.75), o + Vector2(r * 1.25, -r * 1.65), Glyphs._c(Palette.COLD_BLUE.lightened(0.2), flash), 2.5)
	ci.draw_line(o + Vector2(r * 0.6, r * 0.3), o + Vector2(r * 1.2, r * 0.42), Glyphs._c(Palette.BONE, flash), 2.0)


## Lich: a floating, tapering wisp robe (no feet), crowned skull with green
## eyes, a soul-flame staff and a faint violet aura.
static func draw_lich(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o, r * 1.35, Color(Palette.VIOLET, 0.12))
	var robe := PackedVector2Array([o + Vector2(0, -r * 0.55), o + Vector2(r * 0.85, r * 0.05),
		o + Vector2(r * 0.5, r * 0.75), o + Vector2(r * 0.15, r * 1.35), o + Vector2(-r * 0.05, r * 1.0),
		o + Vector2(-r * 0.3, r * 1.2), o + Vector2(-r * 0.5, r * 0.75), o + Vector2(-r * 0.85, r * 0.05)])
	ci.draw_colored_polygon(robe, Glyphs._c(Palette.LICH_ROBE, flash))
	ci.draw_polyline(ProgressionGlyphs._closed(robe), Glyphs._c(Palette.VIOLET, flash), 1.5)
	Glyphs._skull(ci, o + Vector2(0, -r * 0.75), r * 0.42, flash, Palette.NECRO_GREEN)
	# Bone crown: three spikes over the skull.
	var cb := o + Vector2(0, -r * 1.08)
	ci.draw_colored_polygon(PackedVector2Array([cb + Vector2(-r * 0.4, r * 0.08), cb + Vector2(-r * 0.4, -r * 0.3),
		cb + Vector2(-r * 0.2, -r * 0.08), cb + Vector2(0, -r * 0.42), cb + Vector2(r * 0.2, -r * 0.08),
		cb + Vector2(r * 0.4, -r * 0.3), cb + Vector2(r * 0.4, r * 0.08)]), Glyphs._c(Palette.BONE, flash))
	# Soul-flame staff on the left.
	ci.draw_line(o + Vector2(-r * 1.0, r * 0.95), o + Vector2(-r * 1.0, -r * 1.0), Glyphs._c(Palette.BONE, flash), 1.5)
	ci.draw_circle(o + Vector2(-r * 1.0, -r * 1.2), r * 0.42, Color(Palette.NECRO_GREEN, 0.25))
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 1.0, -r * 1.65), o + Vector2(-r * 1.22, -r * 1.05),
		o + Vector2(-r * 0.78, -r * 1.05)]), Glyphs._c(Palette.NECRO_GREEN, flash))


## Risen skeleton (Lich raise-the-dead): bare ribcage, spine and legs, violet
## eyes and a rusty blade; no shield, no armour.
static func draw_risen(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var bone := Glyphs._c(Palette.BONE, flash)
	ci.draw_line(o + Vector2(0, -r * 0.4), o + Vector2(0, r * 0.55), bone, 1.5)
	for i in 3:
		var y := -r * 0.25 + r * 0.25 * float(i)
		ci.draw_line(o + Vector2(-r * 0.45, y), o + Vector2(r * 0.45, y), bone, 1.5)
	ci.draw_line(o + Vector2(0, r * 0.55), o + Vector2(-r * 0.4, r * 1.15), bone, 1.5)
	ci.draw_line(o + Vector2(0, r * 0.55), o + Vector2(r * 0.4, r * 1.15), bone, 1.5)
	Glyphs._skull(ci, o + Vector2(0, -r * 0.75), r * 0.42, flash, Palette.VIOLET)
	ci.draw_line(o + Vector2(r * 0.55, r * 0.4), o + Vector2(r * 0.95, -r * 0.9), Glyphs._c(Color(0.55, 0.42, 0.3), flash), 2.0)


## Transformation glow on a summon evolving in place: a rising light column
## and an expanding ring that fade as `frac` goes 1 -> 0.
static func draw_transform_glow(ci: CanvasItem, r: float, frac: float) -> void:
	var k := clampf(frac, 0.0, 1.0)
	ci.draw_rect(Rect2(Vector2(-r * 0.35, -r * 3.2), Vector2(r * 0.7, r * 4.0)), Color(Palette.NECRO_GREEN, 0.3 * k))
	ci.draw_circle(Vector2.ZERO, r * (1.5 + (1.0 - k) * 1.2), Color(Palette.VIOLET, 0.22 * k))
	ci.draw_arc(Vector2.ZERO, r * (1.5 + (1.0 - k) * 1.2), 0.0, TAU, 24, Color(Palette.NECRO_GREEN, 0.9 * k), 2.0)
