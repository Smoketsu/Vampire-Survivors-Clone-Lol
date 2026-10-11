## SpellGlyphs — code-drawn shapes of the four newer necromancer spells,
## their evolutions and their paired passives: the UI icons (Glyphs.draw_icon
## falls through to draw_icon() here) and the world visuals the spell nodes
## draw each tick (spears, tethers, corpses, spike fields, plague clouds).
## Colour language (GDD §11.2, Palette): necromancy is violet / green / bone;
## the plague adds a sickly yellow-green, drained life a dark magenta (never
## the Covenant's crimson); evolutions get a gold frame on their icon, like
## ProgressionGlyphs' evolutions.
class_name SpellGlyphs
extends RefCounted

## Sickly yellow-green of plague clouds.
const PLAGUE := Color(0.66, 0.80, 0.24)
## Near-black core of Pestilence clouds.
const PLAGUE_DARK := Color(0.06, 0.08, 0.03)
## Dark magenta of life drained by Soul Siphon.
const LIFE := Color(0.82, 0.22, 0.52)
## Pale green-white of Soul Rapture souls.
const SOUL := Color(0.80, 1.0, 0.86)
## Near-black "void" of evolution cores (same as ProgressionGlyphs.VOID).
const VOID := Color(0.04, 0.0, 0.07)
## Seconds a corpse burst stays visible (cosmetic only).
const BLAST_TIME: float = 0.35


# =====================================================================================
# UI icons
# =====================================================================================

## Draws icon `kind` centred at `c` with half-size `s`. Returns false if the
## kind is not one of these spells / evolutions / passives.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"bone_spear":
			draw_spear(ci, c + Vector2(s * 0.12, -s * 0.12), Vector2(1, -1).normalized(), s * 0.5, s * 0.1)
		"ossuary_lance":
			_gold_frame(ci, c, s)
			draw_lance(ci, c + Vector2(s * 0.2, -s * 0.2), Vector2(1, -1).normalized(), s * 0.34, s * 0.09)
		"soul_siphon":
			Glyphs._skull(ci, c + Vector2(s * 0.42, -s * 0.3), s * 0.2, false)
			draw_siphon_tether(ci, c + Vector2(-s * 0.5, s * 0.4), c + Vector2(s * 0.38, -s * 0.26), 0.6, 0.6, s * 0.06)
			ci.draw_circle(c + Vector2(-s * 0.5, s * 0.4), s * 0.16, Palette.VIOLET)
		"soul_rapture":
			_gold_frame(ci, c, s)
			for i in 3:
				var tgt := c + Vector2.from_angle(-PI * 0.75 + float(i) * PI * 0.5) * s * 0.5
				draw_rapture_tether(ci, c + Vector2(0, s * 0.35), tgt, 0.4 + float(i), 0.8, s * 0.05)
				ci.draw_circle(tgt, s * 0.1, SOUL)
			ci.draw_circle(c + Vector2(0, s * 0.35), s * 0.15, Palette.VIOLET)
		"corpse_explosion":
			for i in 8:
				var d := Vector2.from_angle(TAU * float(i) / 8.0 + 0.2)
				ci.draw_line(c + d * s * 0.32, c + d * s * 0.66, Palette.BONE, 1.5)
			ci.draw_circle(c, s * 0.3, Color(Palette.NECRO_GREEN, 0.3))
			Glyphs._skull(ci, c, s * 0.24, false)
		"grave_eruption":
			_gold_frame(ci, c, s)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.62, s * 0.3), Vector2(s * 1.24, s * 0.14)), Palette.STONE)
			for i in 5:
				var x := -s * 0.48 + s * 0.24 * float(i)
				var h := s * (0.45 + 0.2 * float(2 - absi(i - 2)) * 0.5)
				_spike(ci, c + Vector2(x, s * 0.3), h, s * 0.1, 1.0)
		"plague_cloud":
			draw_plague(ci, c, s * 0.62, 1.0, 0.0)
			for i in 3:
				ci.draw_circle(c + Vector2(-s * 0.25 + s * 0.25 * float(i), s * 0.1 - s * 0.12 * float(i % 2)), s * 0.06, PLAGUE)
		"pestilence":
			_gold_frame(ci, c, s)
			draw_pestilence(ci, c, s * 0.6, 1.0, 0.0)
			Glyphs._skull(ci, c, s * 0.2, false, PLAGUE)
		"shade_stride":
			# A hooded shade gliding, with violet trails behind it.
			for i in 3:
				var y := -s * 0.25 + s * 0.25 * float(i)
				ci.draw_line(c + Vector2(-s * 0.68, y), c + Vector2(-s * 0.2, y), Color(Palette.VIOLET, 0.75 - 0.2 * float(i)), 1.5)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.15, -s * 0.55), c + Vector2(s * 0.52, s * 0.45),
				c + Vector2(-s * 0.18, s * 0.45)]), Palette.ROBE.lightened(0.25))
			ci.draw_circle(c + Vector2(s * 0.2, -s * 0.12), s * 0.07, Palette.NECRO_GREEN)
		"vampiric_rite":
			# A drop of drained life inside a green rune circle.
			ci.draw_arc(c, s * 0.62, 0.0, TAU, 24, Color(Palette.NECRO_GREEN, 0.7), 1.5)
			ci.draw_circle(c + Vector2(0, s * 0.12), s * 0.3, LIFE)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.5), c + Vector2(s * 0.27, s * 0.02),
				c + Vector2(-s * 0.27, s * 0.02)]), LIFE)
			ci.draw_circle(c + Vector2(-s * 0.1, s * 0.05), s * 0.07, Color(1, 1, 1, 0.6))
		"necrotic_expanse":
			# Rings spreading outward with four arrowheads.
			ci.draw_circle(c, s * 0.14, Palette.NECRO_GREEN)
			ci.draw_arc(c, s * 0.32, 0.0, TAU, 20, Color(Palette.VIOLET, 0.9), 1.5)
			ci.draw_arc(c, s * 0.5, 0.0, TAU, 24, Color(Palette.VIOLET, 0.5), 1.5)
			for i in 4:
				var d := Vector2.from_angle(TAU * float(i) / 4.0 + PI / 4.0)
				var n := Vector2(-d.y, d.x)
				var tip := c + d * s * 0.72
				ci.draw_colored_polygon(PackedVector2Array([tip, tip - d * s * 0.16 + n * s * 0.1, tip - d * s * 0.16 - n * s * 0.1]), Palette.NECRO_GREEN)
		"lingering_malediction":
			# An hourglass of bone with green sand.
			var top := PackedVector2Array([c + Vector2(-s * 0.36, -s * 0.55), c + Vector2(s * 0.36, -s * 0.55), c + Vector2(0, 0)])
			var bot := PackedVector2Array([c + Vector2(0, 0), c + Vector2(s * 0.36, s * 0.55), c + Vector2(-s * 0.36, s * 0.55)])
			ci.draw_colored_polygon(top, Color(Palette.BONE, 0.25))
			ci.draw_colored_polygon(bot, Color(Palette.BONE, 0.25))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, s * 0.18), c + Vector2(s * 0.27, s * 0.5), c + Vector2(-s * 0.27, s * 0.5)]), PLAGUE)
			ci.draw_line(c + Vector2(-s * 0.42, -s * 0.58), c + Vector2(s * 0.42, -s * 0.58), Palette.BONE, 2.0)
			ci.draw_line(c + Vector2(-s * 0.42, s * 0.58), c + Vector2(s * 0.42, s * 0.58), Palette.BONE, 2.0)
		_:
			return false
	return true


## Gold double frame marking an evolution icon (as ProgressionGlyphs does).
static func _gold_frame(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_arc(c, s * 0.85, 0.0, TAU, 32, Color(Palette.GOLD, 0.8), 1.5)
	ci.draw_arc(c, s * 0.78, 0.0, TAU, 32, Color(Palette.GOLD, 0.3), 1.0)


# =====================================================================================
# World visuals
# =====================================================================================

## A Bone Spear at `p` heading `d` (unit): bone shaft, barbed tip, faint
## green marrow trail. `half_len` is the half length, `w` the shaft width.
static func draw_spear(ci: CanvasItem, p: Vector2, d: Vector2, half_len: float = 11.0, w: float = 2.5) -> void:
	if SpriteBank.draw_flat(ci, "projectiles/bone_spear", p, d.angle()):
		return  # Sprite art exists.
	var n := Vector2(-d.y, d.x)  # Perpendicular.
	var tail := p - d * half_len  # Butt of the shaft.
	ci.draw_line(tail - d * half_len * 0.8, tail, Color(Palette.NECRO_GREEN, 0.25), w * 1.4)
	ci.draw_line(tail, p + d * half_len * 0.35, Palette.BONE, w)
	ci.draw_circle(tail, w * 0.9, Palette.BONE)
	var tip := p + d * half_len  # Point of the head.
	ci.draw_colored_polygon(PackedVector2Array([tip, p + d * half_len * 0.25 + n * w * 1.4, p + d * half_len * 0.25 - n * w * 1.4]), Palette.BONE.lightened(0.25))


## An Ossuary Lance at `p` heading `d`: a long serrated bone lance with a
## violet afterimage trail and a green glow at its point. `half_len` is the half
## length, `w` the shaft width.
static func draw_lance(ci: CanvasItem, p: Vector2, d: Vector2, half_len: float = 20.0, w: float = 4.0) -> void:
	if SpriteBank.draw_flat(ci, "projectiles/ossuary_lance", p, d.angle()):
		return  # Sprite art exists.
	var n := Vector2(-d.y, d.x)  # Perpendicular.
	var tail := p - d * half_len  # Butt of the shaft.
	for k in 3:
		var o := tail - d * half_len * (0.35 + 0.35 * float(k))
		ci.draw_line(o, o + d * half_len * 0.6, Color(Palette.VIOLET, 0.32 - 0.09 * float(k)), w * (1.6 - 0.3 * float(k)))
	ci.draw_line(tail, p + d * half_len * 0.4, Palette.BONE, w)
	for k in 3:
		var b := tail + d * half_len * (0.35 + 0.35 * float(k))  # Barb base on the shaft.
		ci.draw_colored_polygon(PackedVector2Array([b, b - d * w * 1.2 + n * w * 1.2, b - d * w * 0.4]), Palette.BONE)
		ci.draw_colored_polygon(PackedVector2Array([b, b - d * w * 1.2 - n * w * 1.2, b - d * w * 0.4]), Palette.BONE)
	var tip := p + d * half_len * 1.15  # Point of the head.
	ci.draw_circle(tip - d * w, w * 1.8, Color(Palette.NECRO_GREEN, 0.3))
	ci.draw_colored_polygon(PackedVector2Array([tip, p + d * half_len * 0.3 + n * w * 1.6, p + d * half_len * 0.3 - n * w * 1.6]), Palette.IVORY)
	ci.draw_circle(tail, w * 0.9, Palette.BONE)


## A Soul Siphon tether from `a` (necromancer) to `b` (victim): a rippling
## violet beam with dark-magenta motes of life flowing back to `a`.
## `phase` animates it, `glow` (0..1) brightens it right after a pulse.
static func draw_siphon_tether(ci: CanvasItem, a: Vector2, b: Vector2, phase: float, glow: float, w: float = 2.5) -> void:
	var pts := _wave(a, b, phase, 5.0, 1.0)
	ci.draw_polyline(pts, Color(Palette.VIOLET, 0.3 + 0.4 * glow), w * 1.4)
	ci.draw_polyline(pts, Color(LIFE, 0.75), w * 0.5)
	for k in 3:
		var t := 1.0 - fposmod(phase * 1.3 + float(k) / 3.0, 1.0)  # 1 at the victim -> 0 at you.
		ci.draw_circle(_along(pts, t), w * 0.9, LIFE)


## A Soul Rapture tether: two braided strands (green and bone) with pale
## souls streaming back to `a`.
static func draw_rapture_tether(ci: CanvasItem, a: Vector2, b: Vector2, phase: float, glow: float, w: float = 2.5) -> void:
	var p1 := _wave(a, b, phase, 6.0, 1.0)
	var p2 := _wave(a, b, phase, 6.0, -1.0)
	ci.draw_polyline(p1, Color(Palette.NECRO_GREEN, 0.45 + 0.4 * glow), w)
	ci.draw_polyline(p2, Color(Palette.BONE, 0.35 + 0.4 * glow), w * 0.7)
	for k in 4:
		var t := 1.0 - fposmod(phase * 1.6 + float(k) / 4.0, 1.0)  # 1 at the victim -> 0 at you.
		var q := _along(p1, t)
		ci.draw_circle(q, w * 1.5, Color(SOUL, 0.35))
		ci.draw_circle(q, w * 0.8, SOUL)


## Points of a beam from `a` to `b` rippling sideways (amplitude `amp` px,
## largest mid-beam; `sgn` flips the ripple for a second strand).
static func _wave(a: Vector2, b: Vector2, phase: float, amp: float, sgn: float) -> PackedVector2Array:
	var pts := PackedVector2Array()  # Beam polyline.
	var dir := b - a  # Full beam vector.
	var n := Vector2(-dir.y, dir.x).normalized()  # Perpendicular.
	const SEGMENTS := 12  # Beam smoothness (cosmetic).
	for i in SEGMENTS + 1:
		var t := float(i) / float(SEGMENTS)
		pts.append(a + dir * t + n * sgn * sin(t * PI) * sin(phase * 9.0 + t * 9.0) * amp)
	return pts


## Point at fraction `t` (0..1) along polyline `pts` (by index, which is
## even enough for a beam).
static func _along(pts: PackedVector2Array, t: float) -> Vector2:
	var f := clampf(t, 0.0, 1.0) * float(pts.size() - 1)
	var i := mini(int(f), pts.size() - 2)
	return pts[i].lerp(pts[i + 1], f - float(i))


## A fresh corpse left for Corpse Explosion: crossed bones and a small
## skull, fading as it ages (`fresh` 1 -> 0). `k` varies the bone angle.
static func draw_corpse(ci: CanvasItem, p: Vector2, fresh: float, k: int) -> void:
	var a := 0.2 + clampf(fresh, 0.0, 1.0) * 0.5  # Alpha.
	var v := Vector2.from_angle(float(k) * 0.7) * 5.0  # First bone direction.
	var col := Color(Palette.BONE, a)
	ci.draw_line(p - v, p + v, col, 1.5)
	ci.draw_line(p - Vector2(-v.y, v.x), p + Vector2(-v.y, v.x), col, 1.5)
	ci.draw_circle(p + Vector2(0, -3.0), 2.4, col)
	ci.draw_circle(p + Vector2(0, -3.0), 0.8, Color(Palette.NECRO_GREEN, a))


## A corpse burst `t` (0..1) through its life: an expanding ring and bone
## shards flying out to radius `r`. `eruption` tints it Grave Eruption green.
static func draw_bone_burst(ci: CanvasItem, p: Vector2, r: float, t: float, eruption: bool) -> void:
	var a := 1.0 - t  # Fade.
	var rim := Palette.NECRO_GREEN if eruption else Palette.VIOLET
	ci.draw_arc(p, r * (0.35 + 0.65 * t), 0.0, TAU, 28, Color(rim, 0.6 * a), 2.0)
	for i in 8:
		var d := Vector2.from_angle(TAU * float(i) / 8.0 + 0.3)
		ci.draw_line(p + d * r * (0.15 + 0.55 * t), p + d * r * (0.3 + 0.7 * t), Color(Palette.BONE, a), 2.0)


## A Grave Eruption bone-spike field of radius `r`; `life` runs 1 -> 0 (it
## grows in quickly and sinks away at the end), `now` sways the glint.
static func draw_spike_field(ci: CanvasItem, p: Vector2, r: float, life: float, now: float) -> void:
	var grow := clampf((1.0 - life) * 8.0, 0.0, 1.0)  # Spikes rising.
	var a := clampf(life * 4.0, 0.0, 1.0)  # Fade at the end.
	ci.draw_circle(p, r, Color(0.08, 0.04, 0.1, 0.35 * a))
	ci.draw_arc(p, r, 0.0, TAU, 32, Color(Palette.NECRO_GREEN, 0.35 * a), 1.5)
	for i in 10:
		var q := p + Vector2.from_angle(TAU * float(i) / 10.0) * r * 0.75
		_spike(ci, q, 10.0 * grow, 3.0, a)
	for i in 5:
		var q := p + Vector2.from_angle(TAU * float(i) / 5.0 + 0.6) * r * 0.35
		_spike(ci, q, 13.0 * grow, 3.5, a)
	ci.draw_circle(p, 2.0 + sin(now * 6.0), Color(Palette.NECRO_GREEN, 0.6 * a))


## One upright bone spike with its base at `base` (height `h`, half-width
## `w`, alpha `a`).
static func _spike(ci: CanvasItem, base: Vector2, h: float, w: float, a: float) -> void:
	if h <= 0.5:
		return
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(w, 0), base + Vector2(0, -h)]), Color(Palette.BONE, a))
	ci.draw_line(base + Vector2(0, -h), base + Vector2(0, -h * 0.6), Color(Palette.NECRO_GREEN, a), 1.0)


## A Plague Cloud of radius `r`: slowly turning sickly puffs with a soft
## rim and rising bubbles. `life` runs 1 -> 0, `now` animates it.
static func draw_plague(ci: CanvasItem, p: Vector2, r: float, life: float, now: float) -> void:
	var a := clampf(life * 3.0, 0.0, 1.0) * clampf((1.0 - life) * 10.0 + 0.4, 0.0, 1.0)  # Fade in / out.
	ci.draw_circle(p, r, Color(PLAGUE, 0.08 * a))
	for i in 5:
		var q := p + Vector2.from_angle(now * 0.4 + TAU * float(i) / 5.0) * r * 0.45
		ci.draw_circle(q, r * 0.5, Color(PLAGUE, 0.11 * a))
	ci.draw_arc(p, r, 0.0, TAU, 32, Color(PLAGUE, 0.35 * a), 1.5)
	for i in 3:
		var rise := fposmod(now * 0.6 + float(i) / 3.0, 1.0)  # 0 -> 1 as a bubble rises.
		var q := p + Vector2(r * (0.4 * float(i) - 0.4), r * 0.3 - rise * r * 0.7)
		ci.draw_arc(q, 2.0 + rise * 1.5, 0.0, TAU, 8, Color(PLAGUE, 0.6 * a * (1.0 - rise)), 1.0)


## A Pestilence cloud: a black, violet-rimmed plague with drifting soul
## motes; its rim thickens as the Death Nova nears (`life` -> 0).
static func draw_pestilence(ci: CanvasItem, p: Vector2, r: float, life: float, now: float) -> void:
	var a := clampf(life * 6.0, 0.0, 1.0) * clampf((1.0 - life) * 10.0 + 0.4, 0.0, 1.0)  # Fade in / out.
	ci.draw_circle(p, r, Color(PLAGUE_DARK, 0.42 * a))
	for i in 6:
		var q := p + Vector2.from_angle(-now * 0.5 + TAU * float(i) / 6.0) * r * 0.5
		ci.draw_circle(q, r * 0.45, Color(PLAGUE, 0.08 * a))
	var charge := 1.0 - clampf(life * 3.0, 0.0, 1.0)  # Nova build-up in the last third.
	ci.draw_arc(p, r, 0.0, TAU, 36, Color(Palette.VIOLET, (0.45 + 0.4 * charge) * a), 1.5 + 3.0 * charge)
	ci.draw_arc(p, r * 0.92, 0.0, TAU, 36, Color(PLAGUE, 0.35 * a), 1.0)
	for i in 4:
		var q := p + Vector2.from_angle(now * 1.1 + TAU * float(i) / 4.0) * r * 0.6
		ci.draw_circle(q, 2.4, Color(SOUL, 0.55 * a))
