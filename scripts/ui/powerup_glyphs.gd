## PowerupGlyphs — code-drawn shapes for the power-up drops and the difficulty
## modifiers (user request), in the style of Glyphs / ProgressionGlyphs /
## MetaGlyphs (flat draw_* calls, no assets). Glyphs.draw_icon() falls through
## to draw_icon() here, so IconGlyph (HUD buff row, level-up cards, Ossuary)
## shows these kinds with the usual dark backdrop and level pips.
## Readability (GDD §11.2 colour language): every drop is a dark round token
## with a pulsing ring in its accent colour, so it never reads as an XP
## crystal (a bare diamond) or an enemy; each icon has its own silhouette:
##   Soul Magnet  violet horseshoe magnet holding an XP-blue crystal
##   Grave Feast  a haunch of meat on a bone (food, healthy green ring)
##   Hyper        a violet lightning bolt with a white core (spell power)
##   Stasis       a cold-blue hourglass inside a frost ring
##   Dark Frenzy  a necrotic-green skull with two crossed bone blades
##   Soul Nova    a white-violet eight-ray starburst around a green soul
##   Chest        a gold-banded crimson Covenant reliquary (draw_chest)
##   Profane Pact a crimson-sealed pact scroll with a violet sigil
##   Profane Oath a gold-rimmed crimson oath seal (the Ossuary upgrade)
## Stasis also adds draw_frozen(): a frost shell over a frozen enemy.
class_name PowerupGlyphs
extends RefCounted

## Dark backdrop of a drop token.
const TOKEN_BG := Color(0.06, 0.04, 0.09, 0.92)
## Pale ice white for frost highlights.
const ICE := Color(0.85, 0.95, 1.0)
## Cooked-meat brown of the Grave Feast haunch.
const MEAT := Color(0.62, 0.28, 0.18)


## World token of power-up `kind` at `c` with radius `r`; `age` (s) drives
## the pulsing ring.
static func draw_token(ci: CanvasItem, kind: String, c: Vector2, r: float, age: float) -> void:
	var def: Dictionary = PowerupData.POWERUPS.get(kind, {})  # Power-up definition.
	var col: Color = def.get("color", Palette.BONE)  # Accent colour of the drop.
	var pulse := 0.5 + 0.5 * sin(age * 5.0)  # 0..1 ring pulse.
	ci.draw_circle(c + Vector2(0, r * 0.9), r * 0.9, Color(0, 0, 0, 0.35))
	ci.draw_circle(c, r * (1.45 + 0.15 * pulse), Color(col, 0.10 + 0.08 * pulse))
	# Medallion art (pickups/pu_<kind>.png) replaces the disc, ring and icon; the pulse stays.
	if SpriteBank.draw_flat(ci, "pickups/pu_" + kind, c, 0.0):
		return
	ci.draw_circle(c, r, TOKEN_BG)
	ci.draw_arc(c, r, 0.0, TAU, 24, Color(col, 0.75 + 0.25 * pulse), 1.5)
	draw_icon(ci, String(def.get("icon", "")), c, r * 0.95)


## Draws icon `kind` centred at `c` with half-size `s`. Returns false if the
## kind is unknown.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"powerup_magnet":
			# Horseshoe magnet: an open arc with two pole tips, crystal inside.
			ci.draw_arc(c + Vector2(0, -s * 0.05), s * 0.5, 0.0, PI, 16, Palette.VIOLET, s * 0.28)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.64, -s * 0.5), Vector2(s * 0.28, s * 0.45)), Palette.VIOLET)
			ci.draw_rect(Rect2(c + Vector2(s * 0.36, -s * 0.5), Vector2(s * 0.28, s * 0.45)), Palette.VIOLET)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.64, -s * 0.62), Vector2(s * 0.28, s * 0.14)), Palette.BONE)
			ci.draw_rect(Rect2(c + Vector2(s * 0.36, -s * 0.62), Vector2(s * 0.28, s * 0.14)), Palette.BONE)
			var gem := PackedVector2Array([c + Vector2(0, -s * 0.45), c + Vector2(s * 0.2, -s * 0.15),
				c + Vector2(0, s * 0.15), c + Vector2(-s * 0.2, -s * 0.15)])  # XP crystal between the poles.
			ci.draw_colored_polygon(gem, Palette.XP)
		"powerup_feast":
			# Haunch of meat on a bone: round flesh, bone shaft, knobbed end.
			ci.draw_line(c + Vector2(s * 0.05, s * 0.05), c + Vector2(s * 0.55, s * 0.55), Palette.BONE, s * 0.22)
			ci.draw_circle(c + Vector2(s * 0.6, s * 0.45), s * 0.13, Palette.BONE)
			ci.draw_circle(c + Vector2(s * 0.45, s * 0.62), s * 0.13, Palette.BONE)
			ci.draw_circle(c + Vector2(-s * 0.15, -s * 0.15), s * 0.48, MEAT)
			ci.draw_circle(c + Vector2(-s * 0.28, -s * 0.28), s * 0.18, MEAT.lightened(0.3))
			ci.draw_arc(c + Vector2(-s * 0.15, -s * 0.15), s * 0.48, 0.0, TAU, 20, Palette.HP_FRIENDLY, 1.5)
		"powerup_hyper":
			# Lightning bolt.
			var bolt := PackedVector2Array([c + Vector2(s * 0.15, -s * 0.75), c + Vector2(-s * 0.4, s * 0.1),
				c + Vector2(-s * 0.02, s * 0.1), c + Vector2(-s * 0.18, s * 0.75), c + Vector2(s * 0.42, -s * 0.12),
				c + Vector2(s * 0.04, -s * 0.12)])  # Zig-zag outline.
			ci.draw_colored_polygon(bolt, Palette.VIOLET)
			ci.draw_line(c + Vector2(s * 0.08, -s * 0.5), c + Vector2(-s * 0.15, s * 0.0), Color(0.95, 0.9, 1.0), 1.5)
			ci.draw_line(c + Vector2(s * 0.12, -s * 0.05), c + Vector2(-s * 0.08, s * 0.45), Color(0.95, 0.9, 1.0), 1.5)
		"powerup_stasis":
			# Hourglass inside a frost ring.
			ci.draw_arc(c, s * 0.72, 0.0, TAU, 24, Color(Palette.COLD_BLUE, 0.7), 1.5)
			var top := PackedVector2Array([c + Vector2(-s * 0.38, -s * 0.5), c + Vector2(s * 0.38, -s * 0.5), c])  # Upper bulb.
			var bottom := PackedVector2Array([c, c + Vector2(s * 0.38, s * 0.5), c + Vector2(-s * 0.38, s * 0.5)])  # Lower bulb.
			ci.draw_colored_polygon(top, Palette.COLD_BLUE)
			ci.draw_colored_polygon(bottom, Color(Palette.COLD_BLUE, 0.55))
			ci.draw_line(c + Vector2(-s * 0.45, -s * 0.55), c + Vector2(s * 0.45, -s * 0.55), ICE, 2.0)
			ci.draw_line(c + Vector2(-s * 0.45, s * 0.55), c + Vector2(s * 0.45, s * 0.55), ICE, 2.0)
		"powerup_frenzy":
			# Crossed bone blades behind a green-eyed skull.
			ci.draw_line(c + Vector2(-s * 0.65, -s * 0.6), c + Vector2(s * 0.65, s * 0.6), Palette.BONE, 2.0)
			ci.draw_line(c + Vector2(s * 0.65, -s * 0.6), c + Vector2(-s * 0.65, s * 0.6), Palette.BONE, 2.0)
			ci.draw_circle(c, s * 0.5, Color(Palette.NECRO_GREEN, 0.3))
			Glyphs._skull(ci, c + Vector2(0, -s * 0.02), s * 0.36, false, Palette.NECRO_GREEN)
		"powerup_nova":
			# Starburst: alternating long / short rays around a soul core.
			for i in 8:
				var a := TAU * float(i) / 8.0 - PI / 2.0  # Ray angle.
				var ray_len := s * (0.8 if i % 2 == 0 else 0.5)  # Long / short ray.
				ci.draw_line(c, c + Vector2.from_angle(a) * ray_len, Color(0.95, 0.9, 1.0), 2.0)
			ci.draw_circle(c, s * 0.34, Palette.VIOLET)
			ci.draw_circle(c, s * 0.2, Palette.NECRO_GREEN)
		"chest":
			draw_chest(ci, c + Vector2(0, s * 0.1), s * 0.62, 0.0, 0.0)
		"profane_pact":
			# Pact scroll with a crimson wax seal and a violet sigil.
			ci.draw_rect(Rect2(c + Vector2(-s * 0.45, -s * 0.55), Vector2(s * 0.9, s * 1.05)), Palette.IVORY.darkened(0.15))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.65), Vector2(s * 1.1, s * 0.16)), Palette.BONE.darkened(0.3))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.55, s * 0.45), Vector2(s * 1.1, s * 0.16)), Palette.BONE.darkened(0.3))
			ci.draw_polyline(_closed(Glyphs.regular_polygon(c + Vector2(0, -s * 0.12), s * 0.28, 5, -PI / 2.0)), Palette.VIOLET, 1.5)
			ci.draw_circle(c + Vector2(s * 0.22, s * 0.25), s * 0.2, Palette.CRIMSON)
			ci.draw_circle(c + Vector2(s * 0.22, s * 0.25), s * 0.09, Palette.DARK_CRIMSON)
		"profane_oath", "tree_oath":
			# Oath seal: crimson disc, gold rim, violet eye.
			ci.draw_circle(c, s * 0.62, Palette.DARK_CRIMSON)
			ci.draw_arc(c, s * 0.62, 0.0, TAU, 24, Palette.GOLD, 2.0)
			ci.draw_circle(c, s * 0.4, Palette.CRIMSON)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.32, 0), c + Vector2(0, -s * 0.18),
				c + Vector2(s * 0.32, 0), c + Vector2(0, s * 0.18)]), Palette.BONE)
			ci.draw_circle(c, s * 0.1, Palette.VIOLET)
		_:
			return false
	return true


## Treasure chest (Covenant reliquary) at `c` with half-width `s`. `age`
## (s) pulses the glow; `open_frac` 0..1 lifts the lid and releases light
## (the ChestPanel reveal).
static func draw_chest(ci: CanvasItem, c: Vector2, s: float, age: float, open_frac: float) -> void:
	var pulse := 0.5 + 0.5 * sin(age * 4.0)  # 0..1 glow pulse.
	ci.draw_circle(c + Vector2(0, s * 0.7), s * 1.1, Color(0, 0, 0, 0.35))
	ci.draw_circle(c, s * (1.5 + 0.15 * pulse), Color(Palette.GOLD, 0.10 + 0.08 * pulse + 0.3 * open_frac))
	var body := Rect2(c + Vector2(-s, -s * 0.2), Vector2(s * 2.0, s * 1.0))  # Lower box.
	ci.draw_rect(body, Palette.DARK_CRIMSON)
	ci.draw_rect(body, Palette.GOLD, false, 1.5)
	ci.draw_rect(Rect2(c + Vector2(-s * 0.15, -s * 0.2), Vector2(s * 0.3, s * 1.0)), Palette.GOLD)
	if open_frac > 0.0:
		# Light pouring out of the open chest.
		for i in 5:
			var a := -PI / 2.0 + (float(i) - 2.0) * 0.32  # Ray angle (fan upwards).
			ci.draw_line(c + Vector2(0, -s * 0.2), c + Vector2(0, -s * 0.2) + Vector2.from_angle(a) * s * 2.6 * open_frac,
				Color(Palette.GOLD, 0.7 * open_frac), 2.0)
	var lift := s * 0.9 * open_frac  # Lid rise (px).
	var lid := Rect2(c + Vector2(-s * 1.05, -s * 0.75 - lift), Vector2(s * 2.1, s * 0.55))  # Lid.
	ci.draw_rect(lid, Palette.CRIMSON)
	ci.draw_rect(lid, Palette.GOLD, false, 1.5)
	ci.draw_circle(c + Vector2(0, -s * 0.2 - lift * 0.5), s * 0.16, Palette.IVORY)


## Frost shell over an enemy frozen by Stasis (drawn in its _draw()): the
## pixel-art ice ring (MarkerArtData.FROZEN_SHELL) over a translucent cold
## disc, sized to the body radius `r`, or the code shell without the art.
static func draw_frozen(ci: CanvasItem, c: Vector2, r: float) -> void:
	var key := MarkerArtData.FROZEN_SHELL  # Ice shell sprite key.
	if SpriteBank.has(key):
		var base := float(SpriteData.FLAT_SIZES[key])  # The shell's 1:1 height (px).
		var k := maxf(1.0, roundf(r * MarkerArtData.FROZEN_SHELL_PER_RADIUS / base))  # Whole-number scale (even pixels), never below 1:1.
		var at := c + Vector2(0.0, -r * MarkerArtData.FROZEN_SHELL_LIFT)  # Shell centre (px).
		ci.draw_circle(at, base * k * MarkerArtData.FROZEN_DISC_FRACTION, Color(Palette.COLD_BLUE, 0.28))
		SpriteBank.draw_flat(ci, key, at, 0.0, Color(1.0, 1.0, 1.0, MarkerArtData.FROZEN_SHELL_ALPHA), k)
		return
	ci.draw_circle(c, r * 1.15, Color(Palette.COLD_BLUE, 0.28))
	ci.draw_arc(c, r * 1.15, 0.0, TAU, 20, Color(ICE, 0.8), 1.5)
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.4  # Angle of one frost spike.
		ci.draw_line(c + Vector2.from_angle(a) * r * 0.9, c + Vector2.from_angle(a) * r * 1.45, ICE, 1.0)


## Closes a polygon outline for draw_polyline.
static func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()  # Copy with the first point repeated at the end.
	out.append(pts[0])
	return out
