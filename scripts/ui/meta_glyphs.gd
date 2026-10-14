## MetaGlyphs — code-drawn icons for meta-progression (GDD §9.2): the Soul Ash
## currency, the four upgrade trees and every Ossuary upgrade. Same style as
## Glyphs / ProgressionGlyphs (flat draw_* shapes, GDD §11.2 colour language:
## necromancy violet / green / bone, Survival cold blue, Fortune gold), and
## Glyphs.draw_icon() falls through to draw_icon() here, so IconGlyph can show
## these kinds with the usual dark backdrop and level pips.
## Since the menu modernization (wave 2) every kind here has pixel art: a
## 32x32 cut-corner badge in assets/sprites/icons/<kind>.png (and the bare
## 16x16 "soul_ash_small" symbol for inline costs), which Glyphs.draw_icon()
## draws first; these code drawings are only the fallback for a missing PNG.
## Soul Ash API for every screen: IconGlyph.new("soul_ash", Vector2(32, 32))
## (the badge, 1:1; 64 for x2) and IconGlyph.new("soul_ash_small",
## Vector2(16, 16)) (the bare symbol next to a number).
class_name MetaGlyphs
extends RefCounted

## Ember orange of Soul Ash (warm, distinct from holy gold).
const EMBER := Color(1.0, 0.5, 0.25)
## Grey of the ash pile.
const ASH := Color(0.55, 0.52, 0.56)


## Draws icon `kind` centred at `c` with half-size `s`. Returns false if the
## kind is unknown.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"soul_ash", "soul_ash_small":
			draw_soul_ash(ci, c, s)
		"tree_necromancy":
			Glyphs._skull(ci, c + Vector2(0, -s * 0.05), s * 0.5, false, Palette.NECRO_GREEN)
			ci.draw_line(c + Vector2(-s * 0.6, s * 0.6), c + Vector2(s * 0.6, s * 0.3), Palette.BONE, 2.0)
			ci.draw_line(c + Vector2(s * 0.6, s * 0.6), c + Vector2(-s * 0.6, s * 0.3), Palette.BONE, 2.0)
		"tree_shadowcraft":
			ci.draw_circle(c, s * 0.62, Color(Palette.VIOLET, 0.25))
			ci.draw_circle(c, s * 0.38, Palette.VIOLET)
			ci.draw_circle(c, s * 0.16, Color(0.92, 0.82, 1.0))
			for i in 4:
				var a := TAU * float(i) / 4.0 + PI / 4.0
				ci.draw_line(c + Vector2.from_angle(a) * s * 0.48, c + Vector2.from_angle(a) * s * 0.75, Palette.VIOLET, 1.5)
		"tree_survival":
			_heart(ci, c + Vector2(0, -s * 0.05), s * 0.62, Color(Palette.COLD_BLUE, 0.85))
			ci.draw_line(c + Vector2(0, -s * 0.3), c + Vector2(0, s * 0.3), Palette.BONE, 2.0)
			ci.draw_line(c + Vector2(-s * 0.2, -s * 0.05), c + Vector2(s * 0.2, -s * 0.05), Palette.BONE, 2.0)
		"tree_fortune":
			_crystal(ci, c, s * 0.62, Palette.XP)
			ci.draw_arc(c, s * 0.78, 0.0, TAU, 24, Color(Palette.GOLD, 0.8), 1.5)
		# --- Necromancy ---
		"necrotic_marrow":
			_bone(ci, c, s * 0.62, -0.6, Palette.BONE)
			ci.draw_line(c + Vector2.from_angle(-0.6) * -s * 0.35, c + Vector2.from_angle(-0.6) * s * 0.35, Palette.NECRO_GREEN, 2.0)
		"sharpened_bones":
			for sgn: float in [-1.0, 1.0]:
				var tip := c + Vector2(sgn * s * 0.5, -s * 0.6)
				var base := c + Vector2(-sgn * s * 0.45, s * 0.55)
				ci.draw_colored_polygon(PackedVector2Array([tip, base + Vector2(s * 0.1, 0), base - Vector2(s * 0.1, 0)]), Palette.BONE)
			ci.draw_circle(c, s * 0.12, Palette.NECRO_GREEN)
		"grave_call":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.6, s * 0.35), Vector2(s * 1.2, s * 0.22)), Palette.STONE.lightened(0.1))
			ci.draw_arc(c + Vector2(0, -s * 0.05), s * 0.45, PI * 1.1, PI * 1.9 + PI, 16, Palette.NECRO_GREEN, 2.0)
			var tip := c + Vector2(0, -s * 0.05) + Vector2.from_angle(PI * 0.9) * s * 0.45
			ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-s * 0.18, -s * 0.05), tip + Vector2(s * 0.12, -s * 0.12), tip + Vector2(0, s * 0.18)]), Palette.NECRO_GREEN)
			Glyphs._skull(ci, c + Vector2(0, -s * 0.05), s * 0.2, false)
		"risen_vanguard":
			Glyphs.draw_warrior(ci, c + Vector2(-s * 0.15, s * 0.1), s * 0.45, false)
			_plus(ci, c + Vector2(s * 0.5, -s * 0.45), s * 0.22, Palette.NECRO_GREEN)
		"legion_of_bone":
			for i in 3:
				var x := -s * 0.45 + s * 0.45 * float(i)
				var y := s * 0.15 if i != 1 else -s * 0.2
				Glyphs._skull(ci, c + Vector2(x, y), s * 0.24, false, Palette.NECRO_GREEN)
			ci.draw_line(c + Vector2(-s * 0.65, s * 0.6), c + Vector2(s * 0.65, s * 0.6), Palette.NECRO_GREEN, 2.0)
		# --- Shadowcraft ---
		"umbral_potency":
			var flame := PackedVector2Array([c + Vector2(0, -s * 0.7), c + Vector2(s * 0.42, s * 0.05), c + Vector2(s * 0.25, s * 0.55),
				c + Vector2(-s * 0.25, s * 0.55), c + Vector2(-s * 0.42, s * 0.05)])
			ci.draw_colored_polygon(flame, Palette.VIOLET)
			ci.draw_circle(c + Vector2(0, s * 0.2), s * 0.2, Color(0.92, 0.82, 1.0))
		"quickened_rites":
			ci.draw_arc(c, s * 0.6, 0.0, TAU, 24, Color(Palette.VIOLET, 0.6), 2.0)
			ci.draw_arc(c, s * 0.6, -PI / 2.0, PI * 0.25, 12, Palette.NECRO_GREEN, 3.0)
			ci.draw_line(c, c + Vector2(0, -s * 0.45), Palette.BONE, 2.0)
			ci.draw_line(c, c + Vector2(s * 0.3, s * 0.1), Palette.BONE, 2.0)
			ci.draw_circle(c, s * 0.08, Palette.VIOLET)
		"widening_dark":
			ci.draw_circle(c, s * 0.2, Palette.VIOLET)
			ci.draw_arc(c, s * 0.42, 0.0, TAU, 20, Color(Palette.VIOLET, 0.8), 1.5)
			ci.draw_arc(c, s * 0.66, 0.0, TAU, 24, Color(Palette.VIOLET, 0.45), 1.5)
			for i in 4:
				var a := TAU * float(i) / 4.0
				var p := c + Vector2.from_angle(a) * s * 0.78
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2.from_angle(a) * s * 0.14,
					p + Vector2.from_angle(a + 2.3) * s * 0.12, p + Vector2.from_angle(a - 2.3) * s * 0.12]), Palette.NECRO_GREEN)
		"shadow_mastery":
			ProgressionGlyphs._gold_frame(ci, c, s)
			var star := PackedVector2Array()
			for i in 10:
				var rr := s * (0.55 if i % 2 == 0 else 0.24)
				star.append(c + Vector2.from_angle(TAU * float(i) / 10.0 - PI / 2.0) * rr)
			ci.draw_colored_polygon(star, Palette.VIOLET)
			ci.draw_circle(c, s * 0.14, Palette.NECRO_GREEN)
		# --- Survival ---
		"grave_flesh":
			_heart(ci, c, s * 0.62, Palette.CRIMSON.lightened(0.15))
			_plus(ci, c + Vector2(0, -s * 0.05), s * 0.2, Palette.BONE)
		"bone_mail":
			var shield := PackedVector2Array([c + Vector2(-s * 0.55, -s * 0.55), c + Vector2(s * 0.55, -s * 0.55),
				c + Vector2(s * 0.5, s * 0.15), c + Vector2(0, s * 0.68), c + Vector2(-s * 0.5, s * 0.15)])
			ci.draw_colored_polygon(shield, Palette.UNDEAD_STEEL)
			for i in 3:
				var y := -s * 0.32 + s * 0.24 * float(i)
				ci.draw_line(c + Vector2(-s * 0.36, y), c + Vector2(s * 0.36, y), Palette.BONE, 2.0)
			ci.draw_line(c + Vector2(0, -s * 0.45), c + Vector2(0, s * 0.45), Palette.BONE, 1.5)
		"fleet_shade":
			var hood := PackedVector2Array([c + Vector2(s * 0.3, -s * 0.6), c + Vector2(s * 0.65, s * 0.55), c + Vector2(-s * 0.05, s * 0.55)])
			ci.draw_colored_polygon(hood, Palette.ROBE.lightened(0.25))
			ci.draw_circle(c + Vector2(s * 0.32, -s * 0.15), s * 0.12, Palette.NECRO_GREEN)
			for i in 3:
				var y := -s * 0.3 + s * 0.3 * float(i)
				ci.draw_line(c + Vector2(-s * 0.7, y), c + Vector2(-s * 0.15, y), Color(Palette.COLD_BLUE, 0.85), 1.5)
		"undying_will":
			for i in 3:
				var a := -PI / 2.0 + (float(i) - 1.0) * 0.6
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, s * 0.1), c + Vector2.from_angle(a - 0.25) * s * 0.4,
					c + Vector2.from_angle(a) * s * 0.78, c + Vector2.from_angle(a + 0.25) * s * 0.4]), Color(Palette.NECRO_GREEN, 0.75))
			Glyphs._skull(ci, c + Vector2(0, s * 0.2), s * 0.34, false, Palette.NECRO_GREEN)
		# --- Fortune ---
		"soul_magnet":
			ci.draw_arc(c + Vector2(0, -s * 0.05), s * 0.42, PI, TAU, 14, Palette.CRIMSON.lightened(0.1), s * 0.22)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.53, -s * 0.05), Vector2(s * 0.22, s * 0.25)), Palette.SILVER)
			ci.draw_rect(Rect2(c + Vector2(s * 0.31, -s * 0.05), Vector2(s * 0.22, s * 0.25)), Palette.SILVER)
			_crystal(ci, c + Vector2(0, s * 0.5), s * 0.2, Palette.XP)
		"grave_tithe":
			_crystal(ci, c + Vector2(-s * 0.1, s * 0.05), s * 0.55, Palette.XP)
			_plus(ci, c + Vector2(s * 0.5, -s * 0.45), s * 0.2, Palette.GOLD)
		"ash_harvest":
			draw_soul_ash(ci, c + Vector2(0, s * 0.1), s * 0.8)
			_plus(ci, c + Vector2(s * 0.52, -s * 0.5), s * 0.2, Palette.GOLD)
		"fates_thread":
			ci.draw_arc(c, s * 0.5, -PI * 0.1, PI * 0.9, 14, Palette.GOLD, 2.5)
			ci.draw_arc(c, s * 0.5, PI * 0.9, PI * 1.9, 14, Palette.NECRO_GREEN, 2.5)
			var t1 := c + Vector2.from_angle(PI * 0.9) * s * 0.5
			var t2 := c + Vector2.from_angle(PI * 1.9) * s * 0.5
			ci.draw_colored_polygon(PackedVector2Array([t1 + Vector2(-s * 0.18, 0), t1 + Vector2(s * 0.12, -s * 0.05), t1 + Vector2(0, s * 0.2)]), Palette.GOLD)
			ci.draw_colored_polygon(PackedVector2Array([t2 + Vector2(s * 0.18, 0), t2 + Vector2(-s * 0.12, s * 0.05), t2 + Vector2(0, -s * 0.2)]), Palette.NECRO_GREEN)
		"banishing_rite":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.38, -s * 0.55), Vector2(s * 0.76, s * 1.1)), Color(0.12, 0.08, 0.18))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.38, -s * 0.55), Vector2(s * 0.76, s * 1.1)), Palette.BONE, false, 1.5)
			ci.draw_line(c + Vector2(-s * 0.3, -s * 0.3), c + Vector2(s * 0.3, s * 0.3), Palette.CRIMSON.lightened(0.2), 3.0)
			ci.draw_line(c + Vector2(s * 0.3, -s * 0.3), c + Vector2(-s * 0.3, s * 0.3), Palette.CRIMSON.lightened(0.2), 3.0)
		_:
			return false
	return true


## Soul Ash: a grey ash mound with glowing ember flecks and a rising wisp.
static func draw_soul_ash(ci: CanvasItem, c: Vector2, s: float) -> void:
	var mound := PackedVector2Array([c + Vector2(-s * 0.7, s * 0.45), c + Vector2(-s * 0.35, -s * 0.05),
		c + Vector2(0, -s * 0.2), c + Vector2(s * 0.35, -s * 0.05), c + Vector2(s * 0.7, s * 0.45)])
	ci.draw_colored_polygon(mound, ASH)
	ci.draw_circle(c + Vector2(-s * 0.25, s * 0.2), s * 0.09, EMBER)
	ci.draw_circle(c + Vector2(s * 0.2, s * 0.25), s * 0.07, EMBER)
	ci.draw_circle(c + Vector2(s * 0.02, s * 0.05), s * 0.1, Color(1.0, 0.75, 0.4))
	ci.draw_arc(c + Vector2(s * 0.12, -s * 0.45), s * 0.22, PI * 0.5, PI * 1.5, 8, Color(Palette.NECRO_GREEN, 0.8), 1.5)
	ci.draw_circle(c + Vector2(s * 0.12, -s * 0.7), s * 0.07, Palette.NECRO_GREEN)


## Heart shape of half-width `r` centred at `c`.
static func _heart(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-r * 0.45, -r * 0.2), r * 0.48, col)
	ci.draw_circle(c + Vector2(r * 0.45, -r * 0.2), r * 0.48, col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.92, -r * 0.05), c + Vector2(r * 0.92, -r * 0.05), c + Vector2(0, r * 0.95)]), col)


## XP-crystal diamond of half-height `r`.
static func _crystal(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.62, 0), c + Vector2(0, r), c + Vector2(-r * 0.62, 0)]), col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.6), c + Vector2(r * 0.25, 0), c + Vector2(0, r * 0.2), c + Vector2(-r * 0.25, 0)]), col.lightened(0.45))


## Bone (shaft + knobbed ends) of half-length `r` at angle `a`.
static func _bone(ci: CanvasItem, c: Vector2, r: float, a: float, col: Color) -> void:
	var d := Vector2.from_angle(a) * r
	var n := Vector2.from_angle(a + PI / 2.0) * r * 0.2
	ci.draw_line(c - d, c + d, col, r * 0.3)
	for e: Vector2 in [c - d, c + d]:
		ci.draw_circle(e + n, r * 0.2, col)
		ci.draw_circle(e - n, r * 0.2, col)


## Small "+" of half-size `r`.
static func _plus(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_rect(Rect2(c + Vector2(-r * 0.3, -r), Vector2(r * 0.6, r * 2.0)), col)
	ci.draw_rect(Rect2(c + Vector2(-r, -r * 0.3), Vector2(r * 2.0, r * 0.6)), col)
