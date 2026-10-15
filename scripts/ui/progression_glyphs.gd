## ProgressionGlyphs — code-drawn shapes for the in-run progression layer:
## icons of the evolution passives, the three spell evolutions, the army
## synergies and the fallback cards, plus the small world markers those
## systems add (Volley mage mark, Shieldwall barrier, Unholy Host aura).
## Glyphs.draw_icon() falls through to draw_icon() here for these kinds.
## Colour language (GDD §11.2): player necromancy is violet / green, undead
## effects blue / violet / green; evolutions add a gold frame so they read as
## "special" next to their base spell.
class_name ProgressionGlyphs
extends RefCounted

## Near-black "void" colour used by evolution cores.
const VOID := Color(0.04, 0.0, 0.07)


## Draws icon `kind` centred at `c` with half-size `s`. Returns false if the
## kind is unknown (the caller draws its generic placeholder).
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"soul_conduit":
			# A soul wisp flowing into a violet focus.
			ci.draw_arc(c + Vector2(-s * 0.15, s * 0.1), s * 0.45, PI * 0.6, PI * 1.9, 14, Palette.NECRO_GREEN, 2.0)
			ci.draw_circle(c + Vector2(s * 0.25, -s * 0.2), s * 0.28, Palette.VIOLET)
			ci.draw_circle(c + Vector2(s * 0.25, -s * 0.2), s * 0.12, Color(0.92, 0.82, 1.0))
			ci.draw_circle(c + Vector2(-s * 0.55, s * 0.35), s * 0.1, Palette.NECRO_GREEN)
		"warding_ritual":
			# Rune circle with a bone sigil.
			ci.draw_arc(c, s * 0.6, 0.0, TAU, 24, Palette.COLD_BLUE, 2.0)
			ci.draw_colored_polygon(Glyphs.regular_polygon(c, s * 0.42, 3, -PI / 2.0), Color(Palette.NECRO_GREEN, 0.35))
			ci.draw_polyline(_closed(Glyphs.regular_polygon(c, s * 0.42, 3, -PI / 2.0)), Palette.NECRO_GREEN, 1.5)
			ci.draw_circle(c, s * 0.12, Palette.BONE)
		"abyssal_focus":
			# Concentric violet rings narrowing to a void eye.
			ci.draw_arc(c, s * 0.62, 0.0, TAU, 24, Color(Palette.VIOLET, 0.5), 1.5)
			ci.draw_arc(c, s * 0.42, 0.0, TAU, 20, Palette.VIOLET, 2.0)
			ci.draw_circle(c, s * 0.24, VOID)
			ci.draw_circle(c, s * 0.1, Palette.NECRO_GREEN)
		"void_barrage":
			_gold_frame(ci, c, s)
			for i in 3:
				var o := c + Vector2(-s * 0.45 + s * 0.3 * float(i), s * 0.35 - s * 0.3 * float(i))
				ci.draw_line(o + Vector2(-s * 0.3, s * 0.3), o, Color(Palette.NECRO_GREEN, 0.5), s * 0.12)
				ci.draw_circle(o, s * 0.16, VOID)
				ci.draw_arc(o, s * 0.16, 0.0, TAU, 10, Palette.VIOLET, 1.5)
		"eclipse_ward":
			_gold_frame(ci, c, s)
			ci.draw_arc(c, s * 0.55, 0.0, TAU, 28, Color(Palette.NECRO_GREEN, 0.6), 2.0)
			ci.draw_circle(c, s * 0.3, Color(Palette.VIOLET, 0.5))
			ci.draw_circle(c + Vector2(s * 0.08, -s * 0.04), s * 0.26, VOID)
			for i in 6:
				ci.draw_circle(c + Vector2.from_angle(TAU * float(i) / 6.0) * s * 0.55, s * 0.09, Palette.VIOLET)
		"abyssal_detonation":
			_gold_frame(ci, c, s)
			ci.draw_circle(c, s * 0.62, Color(Palette.VIOLET, 0.25))
			ci.draw_circle(c, s * 0.4, VOID)
			ci.draw_arc(c, s * 0.62, 0.0, TAU, 24, Palette.NECRO_GREEN, 2.0)
			for i in 4:
				var a := TAU * float(i) / 4.0
				ci.draw_arc(c, s * 0.3, a, a + 1.0, 8, Palette.VIOLET, 1.5)
		"syn_shieldwall":
			Glyphs.draw_warrior(ci, c + Vector2(-s * 0.15, s * 0.1), s * 0.42, false)
			ci.draw_arc(c + Vector2(-s * 0.15, s * 0.05), s * 0.7, -PI * 0.9, PI * 0.1, 14, Palette.NECRO_GREEN, 2.0)
		"syn_volley":
			draw_mage_mark(ci, c + Vector2(s * 0.25, -s * 0.25), s * 0.28)
			ci.draw_line(c + Vector2(-s * 0.6, s * 0.6), c + Vector2(s * 0.05, -s * 0.05), Palette.BONE, 1.5)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.12, -s * 0.12), c + Vector2(-s * 0.12, -s * 0.02), c + Vector2(s * 0.02, s * 0.12)]), Palette.NECRO_GREEN)
		"syn_deathless":
			# Skull racing forward with green speed lines behind it.
			Glyphs._skull(ci, c + Vector2(s * 0.15, -s * 0.1), s * 0.32, false, Palette.NECRO_GREEN)
			for i in 3:
				var y := -s * 0.3 + s * 0.22 * float(i)
				ci.draw_line(c + Vector2(-s * 0.65, y), c + Vector2(-s * 0.25, y), Color(Palette.NECRO_GREEN, 0.8), 1.5)
		"syn_unholy_host":
			draw_host_aura(ci, c + Vector2(0, s * 0.2), s * 0.5)
			Glyphs._skull(ci, c + Vector2(-s * 0.3, 0), s * 0.18, false)
			Glyphs._skull(ci, c + Vector2(s * 0.3, 0), s * 0.18, false)
			Glyphs._skull(ci, c + Vector2(0, -s * 0.3), s * 0.2, false, Palette.NECRO_GREEN)
		"syn_flesh_rampart", "syn_killing_field", "syn_death_from_above", "syn_wild_hunt", \
				"syn_cold_blood", "syn_shatterfall", "syn_requiem", "syn_baying", "syn_charnel_menagerie":
			_draw_newer_synergy(ci, kind, c, s)
		"grave_fortitude":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.6), c + Vector2(s * 0.5, -s * 0.3), c + Vector2(s * 0.4, s * 0.3),
				c + Vector2(0, s * 0.6), c + Vector2(-s * 0.4, s * 0.3), c + Vector2(-s * 0.5, -s * 0.3)]), Palette.STONE.lightened(0.15))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.08, -s * 0.35), Vector2(s * 0.16, s * 0.6)), Palette.NECRO_GREEN)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.3, -s * 0.13), Vector2(s * 0.6, s * 0.16)), Palette.NECRO_GREEN)
		"call_of_the_grave":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.6, s * 0.3), Vector2(s * 1.2, s * 0.2)), Palette.STONE)
			for i in 3:
				var x := -s * 0.4 + s * 0.4 * float(i)
				ci.draw_line(c + Vector2(x, s * 0.3), c + Vector2(x, -s * 0.25), Palette.BONE, 1.5)
				ci.draw_circle(c + Vector2(x, -s * 0.35), s * 0.12, Palette.NECRO_GREEN)
		_:
			return false
	return true


## Fallback drawings of the newer classes' synergy icons (the pixel art in
## icons/syn_*.png is used when present): the setter's colour marks the left /
## background shape, the finisher's the right / foreground one.
static func _draw_newer_synergy(ci: CanvasItem, kind: String, c: Vector2, s: float) -> void:
	match kind:
		"syn_flesh_rampart":
			# A flesh stomp ring under a bone sword.
			ci.draw_arc(c + Vector2(0, s * 0.3), s * 0.55, PI, TAU, 14, Palette.CORPSE_FLESH, 3.0)
			ci.draw_line(c + Vector2(0, s * 0.45), c + Vector2(0, -s * 0.6), Palette.BONE, 2.5)
			ci.draw_line(c + Vector2(-s * 0.25, -s * 0.05), c + Vector2(s * 0.25, -s * 0.05), Palette.BONE, 2.0)
		"syn_killing_field":
			# A boulder falling into a flesh stomp ring.
			ci.draw_arc(c + Vector2(0, s * 0.3), s * 0.55, PI, TAU, 14, Palette.CORPSE_FLESH, 3.0)
			ci.draw_circle(c + Vector2(s * 0.1, -s * 0.2), s * 0.25, Palette.BONE)
			ci.draw_line(c + Vector2(-s * 0.45, -s * 0.65), c + Vector2(-s * 0.1, -s * 0.35), Color(Palette.BONE, 0.6), 1.5)
		"syn_death_from_above":
			# A stone wing swooping onto a violet dagger.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.65, -s * 0.5), c + Vector2(0, -s * 0.15),
				c + Vector2(-s * 0.2, -s * 0.6)]), Palette.GARGOYLE_STONE)
			ci.draw_line(c + Vector2(-s * 0.1, s * 0.6), c + Vector2(s * 0.5, -s * 0.1), Palette.VIOLET, 3.0)
		"syn_wild_hunt":
			# A stone wing over a bone hound fang.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.65, -s * 0.5), c + Vector2(0, -s * 0.15),
				c + Vector2(-s * 0.2, -s * 0.6)]), Palette.GARGOYLE_STONE)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, s * 0.0), c + Vector2(s * 0.45, s * 0.0),
				c + Vector2(s * 0.2, s * 0.6)]), Palette.BONE)
		"syn_cold_blood":
			# A frost shard crossed by a violet dagger.
			ci.draw_colored_polygon(Glyphs.regular_polygon(c, s * 0.5, 4, 0.0), Color(Palette.FROST, 0.75))
			ci.draw_line(c + Vector2(-s * 0.5, s * 0.5), c + Vector2(s * 0.5, -s * 0.5), Palette.VIOLET, 3.0)
		"syn_shatterfall":
			# A boulder shattering a frost shard.
			ci.draw_colored_polygon(Glyphs.regular_polygon(c + Vector2(0, s * 0.2), s * 0.45, 4, 0.0), Color(Palette.FROST, 0.75))
			ci.draw_circle(c + Vector2(s * 0.2, -s * 0.35), s * 0.25, Palette.BONE)
		"syn_requiem":
			# A wail ripple around a mage orb.
			ci.draw_arc(c, s * 0.6, -PI * 0.8, -PI * 0.2, 10, WarbandGlyphs.WAIL, 2.0)
			ci.draw_arc(c, s * 0.6, PI * 0.2, PI * 0.8, 10, WarbandGlyphs.WAIL, 2.0)
			ci.draw_circle(c, s * 0.28, Palette.COLD_BLUE)
			ci.draw_circle(c, s * 0.12, Palette.BONE)
		"syn_baying":
			# A wail ripple behind a bone hound fang.
			ci.draw_arc(c + Vector2(-s * 0.2, 0), s * 0.55, PI * 0.6, PI * 1.4, 10, WarbandGlyphs.WAIL, 2.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.1, -s * 0.3), c + Vector2(s * 0.5, -s * 0.3),
				c + Vector2(s * 0.2, s * 0.5)]), Palette.BONE)
		"syn_charnel_menagerie":
			# Four small marks of the newer classes around a skull.
			Glyphs._skull(ci, c, s * 0.25, false, Palette.NECRO_GREEN)
			var cols: Array[Color] = [Palette.CORPSE_FLESH, Palette.GARGOYLE_STONE, Palette.FROST, Palette.BONE]  # Corner colours.
			for i in 4:
				ci.draw_circle(c + Vector2.from_angle(PI * 0.25 + PI * 0.5 * float(i)) * s * 0.6, s * 0.14, cols[i])


## Volley of the Fallen mark: a small violet diamond with a green core (the
## code shape: the synergy icon fallback, and the mark over an enemy when its
## pixel art MarkerArtData.MAGE_MARK is missing, see Enemy._draw_over()).
static func draw_mage_mark(ci: CanvasItem, c: Vector2, r: float) -> void:
	var d := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.75, 0), c + Vector2(0, r), c + Vector2(-r * 0.75, 0)])
	ci.draw_colored_polygon(d, Palette.VIOLET)
	ci.draw_circle(c, r * 0.35, Palette.NECRO_GREEN)


## Shieldwall barrier on a warrior: a cold-blue arc in front, thicker the
## stronger the barrier (`frac` = barrier / max HP).
static func draw_barrier(ci: CanvasItem, c: Vector2, r: float, frac: float) -> void:
	var w := 1.0 + 3.0 * clampf(frac * 4.0, 0.0, 1.0)
	ci.draw_arc(c, r * 1.5, -PI * 0.85, PI * 0.85, 18, Color(Palette.COLD_BLUE, 0.85), w)
	ci.draw_arc(c, r * 1.5, -PI * 0.85, PI * 0.85, 18, Color(Palette.NECRO_GREEN, 0.35), w + 2.0)


## Unholy Host aura under a summon: violet halo with a green rim.
static func draw_host_aura(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r * 1.25, Color(Palette.VIOLET, 0.16))
	ci.draw_arc(c, r * 1.25, 0.0, TAU, 20, Color(Palette.NECRO_GREEN, 0.45), 1.0)


## Marks an evolution icon: a gold double border drawn over the icon box's
## violet one (Glyphs.draw_icon's box is the square of half-size `s` around `c`),
## so the evolution's art keeps the whole box (user decision, GDD 15.0).
static func _gold_frame(ci: CanvasItem, c: Vector2, s: float) -> void:
	var box := Rect2(c - Vector2.ONE * s, Vector2.ONE * s * 2.0)  # The icon box (px).
	ci.draw_rect(box, Palette.GOLD, false, 2.0)
	ci.draw_rect(box.grow(-3.0), Color(Palette.GOLD, 0.35), false, 1.0)


## Returns `pts` with its first point appended (closed outline).
static func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out
