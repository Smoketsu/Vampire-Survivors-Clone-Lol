## SummonGlyphs — code-drawn shapes (no external assets) for every summon
## class and evolution that Glyphs does not draw itself, plus their UI icons:
## the priest-split classes and the summon evolutions, and the four later
## classes. Glyphs.draw_summon() and Glyphs.draw_icon() fall through to this
## file for these kinds. Every silhouette is distinct (GDD §11 / §16
## readability rule, by SHAPE first, colour second):
##   Grave Mender       = round teal robe + green halo (the old priest, Glyphs)
##   Crypt Warder       = downward-pointing heater-shaped robe + floating blue
##                        ward sigil + lantern staff
##   Profane Bishop     = wide bell robe + tall bone mitre + crook staff
##   Death Knight       = blackened plate with spiked pauldrons, horned helm,
##                        tattered cape and a long rune greatsword (bigger)
##   Lich               = floating tapering wisp robe (no feet), bone crown,
##                        soul-flame staff and green eyes
##   Risen skeleton     = bare ribcage and legs, violet eyes, rusty blade (the
##                        Lich's temporary raised dead; also green temp aura)
##   Corpse Abomination = huge lumpy blob of stitched grey-green flesh with a
##                        bone cleaver arm and a tiny embedded skull
##   Grave Rogue        = slim forward-leaning hooded chevron with two daggers
##   Crypt Gargoyle     = hunched stone body with wide bat wings and horns
##   Frost Wraith       = legless teardrop ghost with an ice crown and a
##                        floating ice shard, in a cold glow
##   Winter Revenant    = a taller crowned frost wraith in tattered robes with
##                        a black-ice staff and a pale blue glow (the Frost
##                        Wraith evolution; bigger, five-spike crown)
##   Shadow Reaper / Cathedral Horror (the Rogue / Gargoyle evolutions) are
##                        drawn by ReaperHorrorGlyphs
## The Gravebow and Bone Colossus (and their icons) are drawn by
## GravebowColossusGlyphs, dispatched from here.
## Also draws the icons of the horde passives tied to summon evolutions
## (Forbidden Knowledge, Dark Benediction, and the four later ones: Bone
## Plating, Unholy Precision, Unholy Resilience, Bound Souls), the
## evolution transformation glow (draw_transform_glow()) and
## the Frost Wraith chill tint on enemies (draw_chill()).
## Colour language (Palette, GDD §11.2): undead blue / violet / green / bone;
## no Covenant gold except the evolution icon frame (ProgressionGlyphs).
class_name SummonGlyphs
extends RefCounted


## Returns the flash colour when `flash` is set, else `col`.
static func _c(col: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else col


## Draws summon glyph `kind` (class id, evolution id or "risen") at `o` with
## body radius `r`. Returns false if the kind is unknown here.
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
		"abomination":
			draw_abomination(ci, o, r, flash)
		"rogue":
			draw_rogue(ci, o, r, flash)
		"gargoyle":
			draw_gargoyle(ci, o, r, flash)
		"frost_wraith":
			draw_frost_wraith(ci, o, r, flash)
		"winter_revenant":
			draw_winter_revenant(ci, o, r, flash)
		"shadow_reaper":
			ReaperHorrorGlyphs.draw_shadow_reaper(ci, o, r, flash)
		"cathedral_horror":
			ReaperHorrorGlyphs.draw_cathedral_horror(ci, o, r, flash)
		"gravebow", "bone_colossus":
			return GravebowColossusGlyphs.draw_summon(ci, kind, o, r, flash)
		_:
			return false
	return true


## Draws UI icon `kind` centred at `c` with half-size `s`. Returns false if
## the kind is unknown here. Evolved classes get the gold evolution frame.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		# Unit icons go through Glyphs.draw_summon() so sprite art
		# (assets/sprites/summons/) is used when present, capped to the box.
		"warder", "bishop", "risen":
			Glyphs.draw_summon(ci, kind, c + Vector2(-s * 0.08, s * 0.08), s * 0.5, false)
		"death_knight", "lich":
			ProgressionGlyphs._gold_frame(ci, c, s)
			Glyphs.draw_summon(ci, kind, c + Vector2(-s * 0.08, s * 0.1), s * 0.45, false)
		"shadow_reaper", "cathedral_horror":
			ProgressionGlyphs._gold_frame(ci, c, s)
			Glyphs.draw_summon(ci, kind, c + Vector2(-s * 0.06, s * 0.1), s * 0.42, false)
		"profane_bishop":
			ProgressionGlyphs._gold_frame(ci, c, s)
			Glyphs.draw_summon(ci, "bishop", c + Vector2(0, s * 0.1), s * 0.45, false)
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
		"bone_plating", "unholy_precision", "unholy_resilience", "bound_souls":
			_draw_horde_passive_icon(ci, kind, c, s)
		"abomination":
			Glyphs.draw_summon(ci, kind, c + Vector2(-s * 0.05, s * 0.05), s * 0.46, false)
		"rogue", "gargoyle", "frost_wraith":
			Glyphs.draw_summon(ci, kind, c + Vector2(-s * 0.06, s * 0.08), s * 0.5, false)
		"winter_revenant":
			ProgressionGlyphs._gold_frame(ci, c, s)
			Glyphs.draw_summon(ci, kind, c + Vector2(-s * 0.04, s * 0.14), s * 0.42, false)
		"gravebow", "bone_colossus":
			return GravebowColossusGlyphs.draw_icon(ci, kind, c, s)  # Gold-framed evolution icons.
		_:
			return false
	return true


## The four later horde passives' icons (bold single symbols):
##   bone_plating      — a heater shield of overlapping bone plates, rivets
##                       and a green rune,
##   unholy_precision  — a bone arrowhead with a violet crosshair eye on it,
##   unholy_resilience — a cracked pale holy sun behind a dark undead shield,
##   bound_souls       — a green soul wisp held by a short iron chain.
static func _draw_horde_passive_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> void:
	match kind:
		"bone_plating":
			var shield := PackedVector2Array([c + Vector2(-s * 0.55, -s * 0.55), c + Vector2(s * 0.55, -s * 0.55),
				c + Vector2(s * 0.5, s * 0.1), c + Vector2(0, s * 0.65), c + Vector2(-s * 0.5, s * 0.1)])
			ci.draw_colored_polygon(shield, Palette.BONE.darkened(0.25))
			for i in 3:
				var y := -s * 0.38 + s * 0.3 * float(i)  # Plate seam height.
				var w := s * (0.5 - 0.08 * float(i))  # Seam half-width (the shield narrows).
				ci.draw_line(c + Vector2(-w, y), c + Vector2(w, y), Palette.BONE.lightened(0.2), 2.0)
				ci.draw_circle(c + Vector2(-w * 0.8, y), s * 0.05, Palette.STONE)
				ci.draw_circle(c + Vector2(w * 0.8, y), s * 0.05, Palette.STONE)
			ci.draw_polyline(PackedVector2Array([shield[0], shield[1], shield[2], shield[3], shield[4], shield[0]]), Palette.IVORY, 1.5)
			ci.draw_circle(c + Vector2(0, s * 0.05), s * 0.1, Palette.NECRO_GREEN)
		"unholy_precision":
			var d := Vector2(1, -1).normalized()  # Arrow heading (up-right).
			var n := Vector2(-d.y, d.x)  # Perpendicular.
			ci.draw_line(c - d * s * 0.7, c + d * s * 0.1, Palette.BONE.darkened(0.2), s * 0.12)
			var tip := c + d * s * 0.62  # Arrowhead point.
			ci.draw_colored_polygon(PackedVector2Array([tip, c + d * s * 0.05 + n * s * 0.32, c + d * s * 0.05 - n * s * 0.32]), Palette.BONE)
			var eye := c + d * s * 0.22  # Crosshair centre on the arrowhead.
			ci.draw_arc(eye, s * 0.3, 0.0, TAU, 20, Palette.VIOLET, 2.0)
			for i in 4:
				var a := Vector2.from_angle(TAU * float(i) / 4.0)  # Crosshair tick direction.
				ci.draw_line(eye + a * s * 0.2, eye + a * s * 0.42, Palette.VIOLET, 2.0)
			ci.draw_circle(eye, s * 0.11, Palette.VIOLET)
			ci.draw_circle(eye, s * 0.05, Palette.NECRO_GREEN)
		"unholy_resilience":
			var sun := c + Vector2(0, -s * 0.28)  # Holy sun centre, behind the shield.
			var pale := Palette.IVORY.darkened(0.15)  # Drained holy light.
			for i in 8:
				var a := Vector2.from_angle(TAU * float(i) / 8.0 + 0.2)  # Ray direction.
				ci.draw_line(sun + a * s * 0.36, sun + a * s * 0.62, Color(pale, 0.7), 2.0)
			ci.draw_circle(sun, s * 0.32, pale)
			ci.draw_polyline(PackedVector2Array([sun + Vector2(-s * 0.08, -s * 0.32), sun + Vector2(s * 0.04, -s * 0.12),
				sun + Vector2(-s * 0.06, 0), sun + Vector2(s * 0.1, s * 0.2)]), Palette.ROBE, 2.0)
			var shield := PackedVector2Array([c + Vector2(-s * 0.42, -s * 0.05), c + Vector2(s * 0.42, -s * 0.05),
				c + Vector2(s * 0.38, s * 0.38), c + Vector2(0, s * 0.68), c + Vector2(-s * 0.38, s * 0.38)])
			ci.draw_colored_polygon(shield, Palette.DEATH_STEEL)
			ci.draw_polyline(PackedVector2Array([shield[0], shield[1], shield[2], shield[3], shield[4], shield[0]]), Palette.VIOLET, 1.5)
			Glyphs._skull(ci, c + Vector2(0, s * 0.26), s * 0.17, false, Palette.NECRO_GREEN)
		"bound_souls":
			var wisp := c + Vector2(s * 0.12, -s * 0.12)  # Soul wisp centre.
			ci.draw_circle(wisp, s * 0.42, Color(Palette.NECRO_GREEN, 0.18))
			ci.draw_colored_polygon(PackedVector2Array([wisp + Vector2(-s * 0.26, s * 0.05), wisp + Vector2(0, -s * 0.5),
				wisp + Vector2(s * 0.26, s * 0.05)]), Palette.NECRO_GREEN)
			ci.draw_circle(wisp + Vector2(0, s * 0.06), s * 0.26, Palette.NECRO_GREEN)
			ci.draw_circle(wisp + Vector2(-s * 0.09, s * 0.02), s * 0.05, Palette.ROBE)
			ci.draw_circle(wisp + Vector2(s * 0.09, s * 0.02), s * 0.05, Palette.ROBE)
			for i in 3:
				var p := c + Vector2(-s * 0.18, s * 0.26) + Vector2(-s * 0.17, s * 0.13) * float(i)  # Chain link centre.
				ci.draw_arc(p, s * 0.1, 0.0, TAU, 12, Palette.SILVER.darkened(0.25), 2.0)


# =====================================================================================
# Priest split and summon evolutions
# =====================================================================================

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


# =====================================================================================
# Later classes (Abomination, Rogue, Gargoyle, Frost Wraith)
# =====================================================================================

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


## Winter Revenant pale blue glow (ART_BIBLE #9ED6FF), also its shatter /
## nova effect colour (WinterRevenant).
const REVENANT_GLOW := Color("9ED6FF")
## Winter Revenant staff colour: black ice.
const BLACK_ICE := Color(0.10, 0.14, 0.24)


## Winter Revenant (Frost Wraith evolution): a towering, legless frost wraith
## in tattered robes that trail into three ragged tails, a hooded skull face
## with bright ice eyes, a five-spike ice crown, a black-ice staff topped by
## a glowing shard, and a wide pale blue glow.
static func draw_winter_revenant(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o, r * 1.45, Color(REVENANT_GLOW, 0.13))
	ci.draw_circle(o + Vector2(0, -r * 0.3), r * 0.95, Color(REVENANT_GLOW, 0.10))
	# Tattered robe: wide shoulders tapering into three ragged tails.
	var robe := PackedVector2Array([
		o + Vector2(-r * 0.8, -r * 0.5), o + Vector2(r * 0.8, -r * 0.5), o + Vector2(r * 0.7, r * 0.3),
		o + Vector2(r * 0.55, r * 1.3), o + Vector2(r * 0.28, r * 0.8), o + Vector2(r * 0.05, r * 1.5),
		o + Vector2(-r * 0.2, r * 0.85), o + Vector2(-r * 0.5, r * 1.3), o + Vector2(-r * 0.7, r * 0.3)])
	ci.draw_colored_polygon(robe, _c(Palette.FROST.darkened(0.45), flash))
	ci.draw_polyline(ProgressionGlyphs._closed(robe), _c(REVENANT_GLOW, flash), 1.5)
	# Frost trim across the chest.
	ci.draw_line(o + Vector2(-r * 0.62, -r * 0.05), o + Vector2(r * 0.62, -r * 0.05), _c(PowerupGlyphs.ICE, flash), 1.5)
	# Hooded head with a dark face and bright ice eyes.
	var h := o + Vector2(0, -r * 0.75)  # Head centre.
	ci.draw_circle(h, r * 0.58, _c(Palette.FROST.darkened(0.25), flash))
	ci.draw_circle(h + Vector2(0, r * 0.08), r * 0.4, Glyphs.EYE)
	ci.draw_circle(h + Vector2(-r * 0.17, r * 0.04), r * 0.09, _c(REVENANT_GLOW, flash))
	ci.draw_circle(h + Vector2(r * 0.17, r * 0.04), r * 0.09, _c(REVENANT_GLOW, flash))
	# Five-spike ice crown (taller centre spike).
	for i in 5:
		var x := (float(i) - 2.0) * r * 0.2  # Spike x offset.
		var sh := r * (0.6 if i == 2 else (0.42 if i == 1 or i == 3 else 0.28))  # Spike height.
		ci.draw_colored_polygon(PackedVector2Array([h + Vector2(x - r * 0.09, -r * 0.45), h + Vector2(x, -r * 0.45 - sh),
			h + Vector2(x + r * 0.09, -r * 0.45)]), _c(PowerupGlyphs.ICE, flash))
	ci.draw_line(h + Vector2(-r * 0.5, -r * 0.45), h + Vector2(r * 0.5, -r * 0.45), _c(REVENANT_GLOW, flash), 1.5)
	# Black-ice staff on the right, topped by a glowing shard.
	ci.draw_line(o + Vector2(r * 1.05, r * 1.1), o + Vector2(r * 1.05, -r * 1.15), _c(BLACK_ICE, flash), 2.5)
	var tip := o + Vector2(r * 1.05, -r * 1.45)  # Staff shard centre.
	ci.draw_circle(tip, r * 0.42, Color(REVENANT_GLOW, 0.25))
	ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -r * 0.4), tip + Vector2(r * 0.2, 0), tip + Vector2(0, r * 0.35),
		tip + Vector2(-r * 0.2, 0)]), _c(REVENANT_GLOW, flash))


## Frost Wraith chill on an enemy (drawn in its _draw()): a pale frost film
## and two ice ticks. The full Deep Freeze uses PowerupGlyphs.draw_frozen().
static func draw_chill(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r * 1.05, Color(Palette.FROST, 0.22))
	ci.draw_arc(c, r * 1.05, -2.4, -0.7, 10, Color(PowerupGlyphs.ICE, 0.7), 1.0)
	ci.draw_line(c + Vector2(-r * 0.9, r * 0.6), c + Vector2(-r * 1.25, r * 0.85), PowerupGlyphs.ICE, 1.0)
	ci.draw_line(c + Vector2(r * 0.9, r * 0.6), c + Vector2(r * 1.25, r * 0.85), PowerupGlyphs.ICE, 1.0)
