## StanceGlyphs — code-drawn art of the army stances (StanceData): the four
## stance icons, the padlock of a locked stance, and the faint ground outline
## of a stance's shape (StanceOutline). Same flat style as the other glyph
## files (draw_* calls, no assets). Glyphs.draw_icon() routes the
## "stance_<id>" kinds here, so dedicated icon art
## (assets/sprites/icons/stance_<id>.png, docs/art/ART_BIBLE.md) replaces
## these icons automatically once it exists.
class_name StanceGlyphs
extends RefCounted

## Violet of the necromancer dot at the centre of every stance icon.
const CENTER := Palette.VIOLET
## Dark backing of the padlock body.
const LOCK_BACK := Color(0.08, 0.06, 0.1, 0.9)


## Draws stance icon `kind` ("stance_<id>") centred at `c` with half-size
## `s`. Returns false if the kind is not a stance icon.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"stance_escort":
			# A guard arc facing up, bands of escorts around the necromancer.
			ci.draw_arc(c, s * 0.62, PI * 1.15, PI * 1.85, 14, Palette.NECRO_GREEN, s * 0.14)
			for i in 5:
				var a := PI * 1.15 + PI * 0.7 * float(i) / 4.0
				ci.draw_circle(c + Vector2.from_angle(a) * s * 0.62, s * 0.11, Palette.BONE)
			for a: float in [PI * 0.25, PI * 0.75]:
				ci.draw_circle(c + Vector2.from_angle(a) * s * 0.42, s * 0.09, Palette.NECRO_GREEN)
			ci.draw_circle(c, s * 0.16, CENTER)
		"stance_onslaught":
			# Arrows bursting outward from the necromancer.
			for i in 3:
				var a := -PI * 0.5 + TAU * float(i) / 3.0
				var dir := Vector2.from_angle(a)
				var tip := c + dir * s * 0.78
				ci.draw_line(c + dir * s * 0.25, tip - dir * s * 0.12, Palette.FLAME, s * 0.12)
				var side := dir.orthogonal() * s * 0.2
				ci.draw_colored_polygon(PackedVector2Array([tip, tip - dir * s * 0.3 + side, tip - dir * s * 0.3 - side]), Palette.FLAME)
			ci.draw_circle(c, s * 0.16, CENTER)
		"stance_spearhead":
			# A V of blockers pointing up, the necromancer behind its tip.
			var tip := c + Vector2(0, -s * 0.7)
			for sgn: float in [-1.0, 1.0]:
				ci.draw_line(tip, c + Vector2(sgn * s * 0.62, s * 0.05), Color(Palette.VIOLET, 0.6), s * 0.08)
				for k in 3:
					var t := float(k + 1) / 3.0
					ci.draw_circle(tip.lerp(c + Vector2(sgn * s * 0.62, s * 0.05), t), s * 0.1, Palette.BONE)
			ci.draw_circle(tip, s * 0.13, Palette.NECRO_GREEN)
			ci.draw_circle(c + Vector2(0, s * 0.42), s * 0.16, CENTER)
		"stance_bone_ring":
			# A closed circle of bone around the necromancer.
			ci.draw_arc(c, s * 0.62, 0.0, TAU, 28, Color(Palette.COLD_BLUE, 0.7), s * 0.08)
			for i in 8:
				ci.draw_circle(c + Vector2.from_angle(TAU * float(i) / 8.0) * s * 0.62, s * 0.11, Palette.BONE)
			ci.draw_circle(c, s * 0.16, CENTER)
		_:
			return false
	return true


## Small padlock centred at `c` (half-size `s`) over a locked stance icon.
static func draw_lock(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_arc(c + Vector2(0, -s * 0.15), s * 0.32, PI, TAU, 10, Palette.SILVER, s * 0.12)
	var body := Rect2(c + Vector2(-s * 0.48, -s * 0.12), Vector2(s * 0.96, s * 0.72))
	ci.draw_rect(body.grow(s * 0.06), LOCK_BACK)
	ci.draw_rect(body, Palette.SILVER)
	ci.draw_circle(c + Vector2(0, s * 0.2), s * 0.12, LOCK_BACK)


## Faint ground outline of stance `id`'s shape around the necromancer at
## the local origin, in colour `col` (alpha already applied). `facing` is
## the threat direction (Escort) or the wedge direction (Spearhead).
static func draw_outline(ci: CanvasItem, id: String, facing: Vector2, col: Color) -> void:
	var a := facing.angle()
	match id:
		"escort":
			ci.draw_arc(Vector2.ZERO, 105.0, a - 1.25, a + 1.25, 28, col, 3.0)
			_dashed_circle(ci, 150.0, Color(col, col.a * 0.6), 24)
		"onslaught":
			for i in 6:
				var dir := Vector2.from_angle(a + TAU * float(i) / 6.0)
				ci.draw_line(dir * 120.0, dir * 250.0, col, 3.0)
				var side := dir.orthogonal() * 16.0
				ci.draw_polyline(PackedVector2Array([dir * 230.0 + side, dir * 262.0, dir * 230.0 - side]), col, 3.0)
		"spearhead":
			var dir := facing
			var side := dir.orthogonal()
			var tip := dir * StanceData.SPEAR_TIP
			var back := StanceData.SPEAR_STEP_BACK * 4.5  # Arm length back (px).
			var wide := StanceData.SPEAR_STEP_SIDE * 4.5  # Arm length out (px).
			ci.draw_polyline(PackedVector2Array([tip - dir * back + side * wide, tip, tip - dir * back - side * wide]), col, 3.5)
			ci.draw_line(Vector2.ZERO, tip * 0.7, Color(col, col.a * 0.5), 2.0)
		"bone_ring":
			var r := (StanceData.RING_MIN + StanceData.RING_MAX) * 0.5  # Typical ring radius (px).
			ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, col, 4.0)
			_dashed_circle(ci, r - StanceData.RING_INNER_GAP, Color(col, col.a * 0.5), 16)


## Dashed circle of radius `r` around the local origin with `dashes` dashes.
static func _dashed_circle(ci: CanvasItem, r: float, col: Color, dashes: int) -> void:
	var step := TAU / float(dashes)
	for i in dashes:
		ci.draw_arc(Vector2.ZERO, r, step * float(i), step * (float(i) + 0.55), 4, col, 2.0)
