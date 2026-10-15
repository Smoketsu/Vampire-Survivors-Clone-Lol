## SanctumGlyphs — the placeholder shapes of the Sanctum of Judgment's
## Covenant kinds (SanctumEnemyData) and of their effects, drawn with
## CanvasItem draw_* calls into the CanvasItem currently inside its _draw(),
## like Glyphs and MarchGlyphs (GDD §11 colour language: the Covenant is
## crimson / ivory / silver / gold, holy magic radiant gold; constructs are
## pale stone inlaid with gold). Each kind keeps a silhouette of its own
## (GDD §10.5 "all classes must be readable"):
##   Sanctified Sentinel = squat pale-stone block, gold eye slit, stone blade arm
##   Radiant Inquisitor  = tall ivory-and-crimson robe under a gold sunburst halo
##   High Confessor      = wide ivory robe, tall gold mitre, crook with a halo
##   Sun Paladin         = gold heater shield with a sun emblem, plumed gold helm
##   Cathedral Guardian  = giant stone colossus, stained-glass chest, spire crown
## Glyphs.draw_enemy() delegates kinds MarchGlyphs does not know to here
## (the Sister of the Scourge's fallback body is SisterGlyphs').
## Sprite art (SpriteData keys "enemies/<kind>") replaces the bodies when it
## exists; the overlays below are always drawn.
class_name SanctumGlyphs
extends RefCounted

## Dark outline colour behind bodies (same as Glyphs.OUTLINE).
const OUTLINE := Color(0.0, 0.0, 0.0, 0.55)
## Pale cathedral stone of the constructs.
const PALE_STONE := Color(0.74, 0.72, 0.66)
## Shaded side of the pale stone.
const STONE_SHADE := Color(0.52, 0.50, 0.46)
## Deep stained-glass blue of the Guardian's window.
const GLASS_BLUE := Color(0.22, 0.34, 0.72)
## Pale violet-gold of an armed suppression sigil (holy, but anti-undead).
const SEAL := Color(0.96, 0.88, 0.62)


## Returns the flash colour when `flash` is set, else `col`.
static func _c(col: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else col


# --- Bodies -------------------------------------------------------------------------

## Draws Sanctum kind `kind`; returns false for kinds it does not know.
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"sanctified_sentinel":
			_draw_sentinel(ci, o, r, flash)
		"radiant_inquisitor":
			_draw_radiant_inquisitor(ci, o, r, flash)
		"high_confessor":
			_draw_confessor(ci, o, r, flash)
		"sun_paladin":
			_draw_paladin(ci, o, r, flash)
		"cathedral_guardian":
			_draw_guardian(ci, o, r, flash)
		"battle_sister":
			SisterGlyphs.draw_body(ci, o, r, flash)  # Sister of the Scourge (any stage).
		_:
			return false
	return true


## Sanctified Sentinel: a squat pale-stone block with gold inlay, a glowing
## gold eye slit and a long stone blade arm held forward (+x).
static func _draw_sentinel(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_rect(Rect2(o + Vector2(-r * 0.95, -r * 0.85), Vector2(r * 1.9, r * 1.85)), OUTLINE)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.85, -r * 0.75), Vector2(r * 1.7, r * 1.65)), _c(PALE_STONE, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.85, r * 0.45), Vector2(r * 1.7, r * 0.45)), _c(STONE_SHADE, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.12, -r * 0.6), Vector2(r * 0.24, r * 1.2)), _c(Palette.GOLD, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.5, -r * 0.1), Vector2(r * 1.0, r * 0.18)), _c(Palette.GOLD, flash))
	# Head block with the eye slit.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 1.35), Vector2(r * 0.9, r * 0.62)), _c(PALE_STONE.darkened(0.08), flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.32, -r * 1.12), Vector2(r * 0.64, r * 0.12)), _c(Palette.GOLD, flash))
	# Blade arm.
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(r * 0.7, -r * 0.3), o + Vector2(r * 1.75, -r * 0.85),
		o + Vector2(r * 1.9, -r * 0.65), o + Vector2(r * 0.85, r * 0.1)]), _c(STONE_SHADE, flash))
	ci.draw_line(o + Vector2(r * 0.8, -r * 0.2), o + Vector2(r * 1.8, -r * 0.75), _c(Palette.GOLD, flash), 1.5)


## Radiant Inquisitor: a tall ivory robe with a crimson stole under a gold
## sunburst halo (smaller and robed, unlike the Reckoning's blazing star),
## a gold-bound tome in hand.
static func _draw_radiant_inquisitor(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var head := o + Vector2(0, -r * 0.85)
	for i in 8:
		var dir := Vector2.from_angle(TAU * float(i) / 8.0 - PI / 2.0)
		ci.draw_line(head + dir * r * 0.5, head + dir * r * 1.05, _c(Palette.GOLD, flash), 2.0)
	ci.draw_circle(head, r * 0.55, Color(Palette.GOLD, 0.35))
	var robe := PackedVector2Array([o + Vector2(0, -r * 0.9), o + Vector2(r * 0.85, r * 1.05), o + Vector2(-r * 0.85, r * 1.05)])
	ci.draw_colored_polygon(robe, OUTLINE)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(0, -r * 0.75), o + Vector2(r * 0.75, r * 0.95), o + Vector2(-r * 0.75, r * 0.95)]), _c(Palette.IVORY, flash))
	ci.draw_line(o + Vector2(-r * 0.18, -r * 0.4), o + Vector2(-r * 0.3, r * 0.95), _c(Palette.CRIMSON, flash), 2.5)
	ci.draw_line(o + Vector2(r * 0.18, -r * 0.4), o + Vector2(r * 0.3, r * 0.95), _c(Palette.CRIMSON, flash), 2.5)
	ci.draw_circle(head, r * 0.34, _c(Palette.IVORY.darkened(0.1), flash))
	ci.draw_circle(head, r * 0.13, _c(Palette.CRIMSON, flash))
	ci.draw_rect(Rect2(o + Vector2(r * 0.45, -r * 0.1), Vector2(r * 0.5, r * 0.4)), _c(Palette.DARK_CRIMSON, flash))
	ci.draw_rect(Rect2(o + Vector2(r * 0.45, -r * 0.1), Vector2(r * 0.5, r * 0.4)), _c(Palette.GOLD, flash), false, 1.0)


## High Confessor: a wide ivory robe (trapezoid), crimson stole, a tall gold
## mitre and a gold crook topped by a halo.
static func _draw_confessor(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var robe := PackedVector2Array([o + Vector2(-r * 0.55, -r * 0.5), o + Vector2(r * 0.55, -r * 0.5),
		o + Vector2(r * 1.0, r * 1.0), o + Vector2(-r * 1.0, r * 1.0)])
	ci.draw_colored_polygon(robe, OUTLINE)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.46, -r * 0.4), o + Vector2(r * 0.46, -r * 0.4),
		o + Vector2(r * 0.88, r * 0.9), o + Vector2(-r * 0.88, r * 0.9)]), _c(Palette.IVORY, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.14, -r * 0.4), Vector2(r * 0.28, r * 1.3)), _c(Palette.CRIMSON, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, r * 0.05), Vector2(r * 0.8, r * 0.16)), _c(Palette.GOLD, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.65), r * 0.32, _c(Palette.IVORY.darkened(0.12), flash))
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.32, -r * 0.85), o + Vector2(r * 0.32, -r * 0.85),
		o + Vector2(r * 0.2, -r * 1.55), o + Vector2(0, -r * 1.8), o + Vector2(-r * 0.2, -r * 1.55)]), _c(Palette.GOLD, flash))
	ci.draw_line(o + Vector2(0, -r * 1.65), o + Vector2(0, -r * 0.95), _c(Palette.CRIMSON, flash), 1.5)
	# Crook with a halo.
	ci.draw_line(o + Vector2(-r * 1.05, r * 1.0), o + Vector2(-r * 1.05, -r * 1.2), _c(Palette.GOLD, flash), 2.0)
	ci.draw_arc(o + Vector2(-r * 0.85, -r * 1.2), r * 0.22, PI, TAU, 8, _c(Palette.GOLD, flash), 2.0)
	ci.draw_arc(o + Vector2(-r * 1.05, -r * 1.55), r * 0.3, 0.0, TAU, 14, Color(Palette.GOLD, 0.8), 1.5)


## Sun Paladin: a gold heater shield with a crimson sun emblem, a plumed
## gold great helm and a gilded lance (a Templar in gold).
static func _draw_paladin(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var shield := PackedVector2Array([o + Vector2(-r, -r * 0.8), o + Vector2(r, -r * 0.8), o + Vector2(r, r * 0.2),
		o + Vector2(0, r * 1.1), o + Vector2(-r, r * 0.2)])
	ci.draw_colored_polygon(shield, OUTLINE)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.88, -r * 0.7), o + Vector2(r * 0.88, -r * 0.7),
		o + Vector2(r * 0.88, r * 0.15), o + Vector2(0, r * 0.95), o + Vector2(-r * 0.88, r * 0.15)]), _c(Palette.GOLD, flash))
	var sun := o + Vector2(0, -r * 0.05)
	for i in 8:
		var dir := Vector2.from_angle(TAU * float(i) / 8.0)
		ci.draw_line(sun + dir * r * 0.28, sun + dir * r * 0.55, _c(Palette.CRIMSON, flash), 2.0)
	ci.draw_circle(sun, r * 0.24, _c(Palette.CRIMSON, flash))
	ci.draw_circle(sun, r * 0.12, _c(Palette.IVORY, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.34, -r * 1.4), Vector2(r * 0.68, r * 0.62)), _c(Palette.GOLD.darkened(0.15), flash))
	ci.draw_line(o + Vector2(-r * 0.24, -r * 1.08), o + Vector2(r * 0.24, -r * 1.08), _c(Color.BLACK, flash), 1.5)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(0, -r * 1.4), o + Vector2(-r * 0.55, -r * 1.95),
		o + Vector2(r * 0.15, -r * 1.55)]), _c(Palette.IVORY, flash))  # Plume.
	ci.draw_line(o + Vector2(r * 0.6, r * 0.5), o + Vector2(r * 1.9, -r * 0.6), _c(Palette.GOLD.darkened(0.3), flash), 2.5)
	ci.draw_circle(o + Vector2(r * 1.9, -r * 0.6), r * 0.16, _c(Palette.IVORY, flash))


## Cathedral Guardian: a giant stone colossus, broad shoulders, a gold-ringed
## stained-glass rose window in the chest, a spired crown and two great
## stone fists.
static func _draw_guardian(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o + Vector2(0, r * 0.75), r * 0.95, Color(0, 0, 0, 0.3))
	var body := PackedVector2Array([o + Vector2(-r * 1.05, -r * 0.55), o + Vector2(r * 1.05, -r * 0.55),
		o + Vector2(r * 0.75, r * 0.95), o + Vector2(-r * 0.75, r * 0.95)])
	ci.draw_colored_polygon(body, OUTLINE)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.97, -r * 0.48), o + Vector2(r * 0.97, -r * 0.48),
		o + Vector2(r * 0.68, r * 0.88), o + Vector2(-r * 0.68, r * 0.88)]), _c(PALE_STONE, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.68, r * 0.55), Vector2(r * 1.36, r * 0.33)), _c(STONE_SHADE, flash))
	# Rose window.
	var w := o + Vector2(0, -r * 0.05)
	ci.draw_circle(w, r * 0.42, _c(Palette.GOLD, flash))
	ci.draw_circle(w, r * 0.36, _c(GLASS_BLUE, flash))
	for i in 6:
		var dir := Vector2.from_angle(TAU * float(i) / 6.0)
		ci.draw_circle(w + dir * r * 0.2, r * 0.09, _c(Palette.CRIMSON if i % 2 == 0 else Palette.GOLD, flash))
	ci.draw_circle(w, r * 0.1, _c(Palette.IVORY, flash))
	# Head and spired crown.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 1.0), Vector2(r * 0.6, r * 0.48)), _c(PALE_STONE.darkened(0.06), flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.2, -r * 0.82), Vector2(r * 0.4, r * 0.08)), _c(Palette.GOLD, flash))
	for i in 3:
		var x := (float(i) - 1.0) * r * 0.22
		ci.draw_colored_polygon(PackedVector2Array([o + Vector2(x - r * 0.09, -r * 1.0), o + Vector2(x + r * 0.09, -r * 1.0),
			o + Vector2(x, -r * (1.38 if i == 1 else 1.22))]), _c(Palette.GOLD, flash))
	# Fists.
	for sx: float in [-1.0, 1.0]:
		ci.draw_circle(o + Vector2(sx * r * 1.15, r * 0.35), r * 0.36, OUTLINE)
		ci.draw_circle(o + Vector2(sx * r * 1.15, r * 0.35), r * 0.3, _c(STONE_SHADE, flash))
		ci.draw_arc(o + Vector2(sx * r * 1.15, r * 0.35), r * 0.3, 0.0, TAU, 14, _c(Palette.GOLD, flash), 1.5)


# --- Overlays on enemies --------------------------------------------------------------

## Holy shield (High Confessor): an ivory-gold bubble around the body.
static func draw_holy_shield(ci: CanvasItem, r: float) -> void:
	ci.draw_circle(Vector2.ZERO, r * 1.35, Color(Palette.IVORY, 0.12))
	ci.draw_arc(Vector2.ZERO, r * 1.35, 0.0, TAU, 24, Color(Palette.GOLD, 0.85), 1.5)
	ci.draw_arc(Vector2.ZERO, r * 1.2, -2.4, -1.4, 8, Color(Palette.IVORY, 0.9), 1.5)


## Sun Paladin ward: a small gold shield pip at `c` (`s` px half-size; its
## pixel art, MarkerArtData.SUN_WARD, at its own size when present).
static func draw_ward(ci: CanvasItem, c: Vector2, s: float) -> void:
	if SpriteBank.draw_flat(ci, MarkerArtData.SUN_WARD, c, 0.0):
		return
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s, -s), c + Vector2(s, -s), c + Vector2(s, s * 0.2),
		c + Vector2(0, s * 1.2), c + Vector2(-s, s * 0.2)]), Palette.GOLD)
	ci.draw_circle(c + Vector2(0, -s * 0.1), s * 0.35, Palette.CRIMSON)


## The Sun Paladin's aura reach: a faint gold ring with sun rays.
static func draw_sun_aura(ci: CanvasItem, radius: float) -> void:
	ci.draw_circle(Vector2.ZERO, radius, Color(Palette.GOLD, 0.03))
	ci.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(Palette.GOLD, 0.3), 1.0)
	for i in 12:
		var dir := Vector2.from_angle(TAU * float(i) / 12.0)
		ci.draw_line(dir * radius * 0.93, dir * radius, Color(Palette.GOLD, 0.35), 1.0)


## Sentinel sweep windup: the blade arm raised toward `dir` (world axes,
## CovenantKit.unmirror() active), glowing brighter as `k` (0..1) fills.
static func draw_sweep_windup(ci: CanvasItem, dir: Vector2, r: float, k: float) -> void:
	var perp := Vector2(-dir.y, dir.x)
	var base := dir * r * 0.6
	var tip := dir * r * 1.4 + perp * r * 1.2
	ci.draw_line(base, tip, Color(Palette.GOLD, 0.4 + 0.5 * clampf(k, 0.0, 1.0)), 3.0 + 2.0 * k)
	ci.draw_circle(tip, r * 0.2, Color(Palette.IVORY, 0.5 + 0.5 * k))


## A gold casting sunburst at `c` (`r` px): Inquisitor casts, a Confessor
## raising the dead, the Guardian's charging eye.
static func draw_casting(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r * 0.5, Color(Palette.GOLD, 0.35))
	for i in 8:
		var dir := Vector2.from_angle(TAU * float(i) / 8.0)
		ci.draw_line(c + dir * r * 0.35, c + dir * r * 0.8, Color(Palette.IVORY, 0.85), 1.5)
	ci.draw_circle(c, r * 0.22, Palette.IVORY)


## Cathedral Guardian slam windup: both fists raised overhead, glowing.
static func draw_guardian_fists(ci: CanvasItem, r: float) -> void:
	for sx: float in [-1.0, 1.0]:
		var f := Vector2(sx * r * 0.7, -r * 1.45)
		ci.draw_circle(f, r * 0.42, Color(Palette.GOLD, 0.3))
		ci.draw_circle(f, r * 0.32, SanctumGlyphs.STONE_SHADE)
		ci.draw_arc(f, r * 0.32, 0.0, TAU, 14, Palette.GOLD, 2.0)


## Cathedral Guardian beam from the body to `end` (world axes,
## CovenantKit.unmirror() active), `width` px wide.
static func draw_beam(ci: CanvasItem, end: Vector2, width: float) -> void:
	ci.draw_line(Vector2.ZERO, end, Color(Palette.GOLD, 0.35), width * 1.6)
	ci.draw_line(Vector2.ZERO, end, Color(Palette.GOLD, 0.85), width * 0.7)
	ci.draw_line(Vector2.ZERO, end, Palette.IVORY, width * 0.25)
	ci.draw_circle(end, width * 0.5, Color(Palette.IVORY, 0.7))


# --- World-space effects ----------------------------------------------------------------

## A High Confessor's revival pillar at `p`: a gold column of light rising
## as `k` (0..1) fills, with a growing ring on the ground (`now` = game
## time, for the shimmer).
static func draw_revive_pillar(ci: CanvasItem, p: Vector2, k: float, now: float) -> void:
	var kk := clampf(k, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(now * 10.0)
	ci.draw_circle(p, 18.0, Color(Palette.GOLD, 0.12 + 0.1 * kk))
	ci.draw_arc(p, 18.0, -PI / 2.0, -PI / 2.0 + TAU * kk, 24, Palette.GOLD, 2.5)
	var h := 30.0 + 50.0 * kk  # Pillar height (px).
	ci.draw_rect(Rect2(p + Vector2(-7.0, -h), Vector2(14.0, h)), Color(Palette.GOLD, 0.22 + 0.12 * pulse))
	ci.draw_rect(Rect2(p + Vector2(-2.5, -h), Vector2(5.0, h)), Color(Palette.IVORY, 0.55 + 0.3 * kk))
	ci.draw_circle(p + Vector2(0, -h), 5.0 + 3.0 * pulse, Color(Palette.IVORY, 0.7))


## A suppression sigil at `p` (`radius` px). Arming (`life_k` < 0): a gold
## warning ring with a disc filling up as `arm_k` (0..1) grows. Armed: a
## sealed ivory-gold circle with a slowly turning ring of crosses, fading as
## `life_k` (1..0) runs out (`now` = game time).
static func draw_suppression(ci: CanvasItem, p: Vector2, radius: float, arm_k: float, life_k: float, now: float) -> void:
	if life_k < 0.0:
		ci.draw_circle(p, radius, Color(Palette.GOLD, 0.08))
		ci.draw_circle(p, radius * clampf(arm_k, 0.0, 1.0), Color(Palette.GOLD, 0.18))
		ci.draw_arc(p, radius, 0.0, TAU, 56, Color(Palette.GOLD, 0.9), 2.0)
		return
	var fade := clampf(life_k * 4.0, 0.0, 1.0)  # Fades in the last quarter.
	ci.draw_circle(p, radius, Color(SEAL, 0.10 * fade))
	ci.draw_arc(p, radius, 0.0, TAU, 56, Color(Palette.IVORY, 0.85 * fade), 2.5)
	ci.draw_arc(p, radius * 0.92, 0.0, TAU, 56, Color(Palette.GOLD, 0.45 * fade), 1.0)
	var rot := now * 0.5
	for i in 10:
		var dir := Vector2.from_angle(rot + TAU * float(i) / 10.0)
		var c := p + dir * radius * 0.96
		ci.draw_line(c + Vector2(0, -4), c + Vector2(0, 4), Color(Palette.GOLD, 0.8 * fade), 1.5)
		ci.draw_line(c + Vector2(-3, -1), c + Vector2(3, -1), Color(Palette.GOLD, 0.8 * fade), 1.5)
	ci.draw_arc(p, 10.0, 0.0, TAU, 16, Color(Palette.IVORY, 0.6 * fade), 1.5)
