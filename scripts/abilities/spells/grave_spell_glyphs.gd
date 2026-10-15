## GraveSpellGlyphs — code-drawn shapes of the five later necromancer spells
## (GDD §15.0 "Five more spells"), their evolutions and their new passives:
## the UI icons (Glyphs.draw_icon falls through to draw_icon() here; icon art
## at assets/sprites/icons/<kind>.png still wins, ART_BIBLE) and the world
## visuals the spell nodes draw each tick (brands, bone walls, soul
## lightning, the Wither aura). Raised skeletons use the existing "risen"
## summon glyph. Colour language (GDD §11.2, Palette): necromancy violet /
## green / bone; Wither uses the plague's sickly yellow-green
## (SpellGlyphs.PLAGUE); evolutions get the shared gold frame
## (ProgressionGlyphs._gold_frame). Purely visual.
##   death_mark            — a violet brand sigil (ring + inverted triangle)
##                           around a small skull.
##   doom_brand            — gold frame, three linked brand sigils.
##   bone_wall             — a row of bone spikes on a stone base.
##   charnel_bastion       — gold frame, a ring of spikes around a skull.
##   soul_chains           — a jagged violet bolt arcing between three foes.
##   chains_of_the_damned  — gold frame, a forked bolt with chain links.
##   wither                — a sickly aura ring with drooping motes.
##   necrotic_blight       — gold frame, a wide green aura feeding a heart.
##   raise_dead            — a Risen skeleton clawing out of the ground.
##   legion_of_bones       — gold frame, three Risen skulls over a grave line.
##   grim_ledger           — an open ledger with a violet crown and a skull.
##   spirit_binding        — a spectral chain looped around a soul.
##   restless_dead         — an hourglass with a skull in its lower bulb.
class_name GraveSpellGlyphs
extends RefCounted

## Pale violet-white of soul lightning cores.
const LIGHTNING_CORE := Color(0.93, 0.86, 1.0)
## Sickly bright green of a Doom Brand sigil (player necromancy palette:
## never the Covenant's gold, ART_BIBLE).
const DOOM := Color(0.55, 1.0, 0.45)


# =====================================================================================
# UI icons
# =====================================================================================

## Draws icon `kind` centred at `c` with half-size `s`. Returns false if the
## kind is not one of these spells / evolutions / passives.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"death_mark":
			_sigil(ci, c, s * 0.62, Palette.VIOLET, 0.0)
			Glyphs._skull(ci, c + Vector2(0, s * 0.05), s * 0.22, false, Palette.NECRO_GREEN)
		"doom_brand":
			_gold_frame(ci, c, s)
			for i in 3:
				var q := c + Vector2.from_angle(-PI / 2.0 + TAU * float(i) / 3.0) * s * 0.38
				ci.draw_line(c, q, Color(DOOM, 0.5), 1.5)
				_sigil(ci, q, s * 0.26, DOOM, 0.0)
			ci.draw_circle(c, s * 0.1, Palette.VIOLET)
		"bone_wall":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.66, s * 0.3), Vector2(s * 1.32, s * 0.16)), Palette.STONE)
			for i in 5:
				var x := -s * 0.52 + s * 0.26 * float(i)
				SpellGlyphs._spike(ci, c + Vector2(x, s * 0.3), s * (0.62 if i % 2 == 0 else 0.48), s * 0.12, 1.0)
		"charnel_bastion":
			_gold_frame(ci, c, s)
			for i in 8:
				var a := TAU * float(i) / 8.0
				var q := c + Vector2.from_angle(a) * s * 0.5
				ci.draw_line(q, c + Vector2.from_angle(a) * s * 0.74, Palette.BONE, s * 0.1)
				ci.draw_circle(q, s * 0.08, Palette.BONE.darkened(0.2))
			Glyphs._skull(ci, c, s * 0.2, false, Palette.NECRO_GREEN)
		"soul_chains":
			var a := c + Vector2(-s * 0.6, s * 0.45)
			var b := c + Vector2(-s * 0.05, -s * 0.4)
			var d := c + Vector2(s * 0.55, s * 0.25)
			draw_lightning(ci, a, b, 3, 1.0, false, s * 0.08)
			draw_lightning(ci, b, d, 7, 1.0, false, s * 0.08)
			for q: Vector2 in [a, b, d]:
				ci.draw_circle(q, s * 0.11, Palette.NECRO_GREEN)
		"chains_of_the_damned":
			_gold_frame(ci, c, s)
			var hub := c + Vector2(0, -s * 0.1)
			for i in 4:
				var q := hub + Vector2.from_angle(PI * 0.15 + TAU * float(i) / 4.0) * s * 0.55
				draw_lightning(ci, hub, q, 11 + i, 1.0, true, s * 0.07)
				ci.draw_arc(q, s * 0.09, 0.0, TAU, 10, Palette.BONE, 1.5)
			ci.draw_circle(hub, s * 0.14, Palette.VIOLET)
		"wither":
			ci.draw_circle(c, s * 0.66, Color(SpellGlyphs.PLAGUE, 0.14))
			ci.draw_arc(c, s * 0.66, 0.0, TAU, 28, Color(SpellGlyphs.PLAGUE, 0.8), 2.0)
			ci.draw_arc(c, s * 0.44, 0.0, TAU, 22, Color(SpellGlyphs.PLAGUE, 0.35), 1.0)
			for i in 4:
				var q := c + Vector2.from_angle(TAU * float(i) / 4.0 + 0.4) * s * 0.5
				ci.draw_line(q, q + Vector2(0, s * 0.18), Color(SpellGlyphs.PLAGUE, 0.7), 1.5)
				ci.draw_circle(q + Vector2(0, s * 0.2), s * 0.05, SpellGlyphs.PLAGUE)
			ci.draw_circle(c, s * 0.16, Palette.ROBE.lightened(0.3))
		"necrotic_blight":
			_gold_frame(ci, c, s)
			ci.draw_circle(c, s * 0.72, Color(Palette.NECRO_GREEN, 0.12))
			ci.draw_arc(c, s * 0.72, 0.0, TAU, 30, Palette.NECRO_GREEN, 2.0)
			ci.draw_arc(c, s * 0.52, 0.0, TAU, 26, Color(SpellGlyphs.PLAGUE, 0.6), 1.5)
			_heart(ci, c, s * 0.24, SpellGlyphs.LIFE)
		"raise_dead":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.66, s * 0.42), Vector2(s * 1.32, s * 0.14)), Palette.STONE)
			Glyphs.draw_summon(ci, "risen", c + Vector2(0, s * 0.02), s * 0.42, false)
			for i in 3:
				var x := -s * 0.45 + s * 0.45 * float(i)
				ci.draw_line(c + Vector2(x, s * 0.42), c + Vector2(x * 1.1, s * 0.3), Color(Palette.NECRO_GREEN, 0.6), 1.5)
		"legion_of_bones":
			_gold_frame(ci, c, s)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.66, s * 0.4), Vector2(s * 1.32, s * 0.12)), Palette.STONE)
			for i in 3:
				var x := -s * 0.42 + s * 0.42 * float(i)
				var y := -s * (0.05 if i == 1 else -0.08)
				Glyphs._skull(ci, c + Vector2(x, y), s * 0.2, false, Palette.NECRO_GREEN)
				ci.draw_line(c + Vector2(x, y + s * 0.2), c + Vector2(x, s * 0.4), Palette.BONE, 1.5)
		"grim_ledger":
			var page := Color(0.82, 0.78, 0.66)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.66, -s * 0.2), c + Vector2(-s * 0.04, -s * 0.08),
				c + Vector2(-s * 0.04, s * 0.55), c + Vector2(-s * 0.66, s * 0.42)]), page)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.66, -s * 0.2), c + Vector2(s * 0.04, -s * 0.08),
				c + Vector2(s * 0.04, s * 0.55), c + Vector2(s * 0.66, s * 0.42)]), page.darkened(0.12))
			for i in 3:
				var y := s * (0.05 + 0.13 * float(i))
				ci.draw_line(c + Vector2(-s * 0.55, y - s * 0.06), c + Vector2(-s * 0.14, y), Color(Palette.ROBE, 0.8), 1.0)
			Glyphs._skull(ci, c + Vector2(s * 0.35, s * 0.18), s * 0.15, false, Palette.NECRO_GREEN)
			var crown := PackedVector2Array([c + Vector2(-s * 0.3, -s * 0.38), c + Vector2(-s * 0.3, -s * 0.66), c + Vector2(-s * 0.15, -s * 0.5),
				c + Vector2(0, -s * 0.72), c + Vector2(s * 0.15, -s * 0.5), c + Vector2(s * 0.3, -s * 0.66), c + Vector2(s * 0.3, -s * 0.38)])
			ci.draw_colored_polygon(crown, Palette.VIOLET)
		"spirit_binding":
			ci.draw_circle(c, s * 0.24, Color(Palette.COLD_BLUE, 0.35))
			ci.draw_circle(c, s * 0.12, Color(0.85, 0.95, 1.0))
			for i in 6:
				var a := TAU * float(i) / 6.0 + 0.3
				var q := c + Vector2.from_angle(a) * s * 0.52
				ci.draw_arc(q, s * 0.13, 0.0, TAU, 10, Palette.VIOLET if i % 2 == 0 else Palette.BONE, 2.0)
		"restless_dead":
			var top := PackedVector2Array([c + Vector2(-s * 0.45, -s * 0.62), c + Vector2(s * 0.45, -s * 0.62), c + Vector2(0, 0)])
			var bottom := PackedVector2Array([c + Vector2(0, 0), c + Vector2(s * 0.45, s * 0.62), c + Vector2(-s * 0.45, s * 0.62)])
			ci.draw_colored_polygon(top, Color(Palette.NECRO_GREEN, 0.3))
			ci.draw_colored_polygon(bottom, Color(Palette.NECRO_GREEN, 0.18))
			ci.draw_polyline(_closed(top), Palette.BONE, 1.5)
			ci.draw_polyline(_closed(bottom), Palette.BONE, 1.5)
			Glyphs._skull(ci, c + Vector2(0, s * 0.36), s * 0.16, false, Palette.NECRO_GREEN)
		_:
			return false
	return true


## Gold double frame marking an evolution icon (one shared evolution frame).
static func _gold_frame(ci: CanvasItem, c: Vector2, s: float) -> void:
	ProgressionGlyphs._gold_frame(ci, c, s)


## A brand sigil of radius `r` at `c`: a ring with an inverted triangle,
## turned by `rot` radians, in colour `col`.
static func _sigil(ci: CanvasItem, c: Vector2, r: float, col: Color, rot: float) -> void:
	ci.draw_arc(c, r, 0.0, TAU, 24, col, 1.5)
	ci.draw_polyline(_closed(Glyphs.regular_polygon(c, r * 0.82, 3, PI / 2.0 + rot)), Color(col, 0.85), 1.5)


## A small heart of half-width `r` at `c` (Necrotic Blight life).
static func _heart(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-r * 0.5, -r * 0.2), r * 0.55, col)
	ci.draw_circle(c + Vector2(r * 0.5, -r * 0.2), r * 0.55, col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r, 0), c + Vector2(r, 0), c + Vector2(0, r * 1.1)]), col)


## Returns `pts` with its first point appended (closed outline).
static func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out


# =====================================================================================
# World visuals
# =====================================================================================

## A Death Mark brand on an enemy of body radius `r` at `p`: a slowly turning
## sigil around it and a small skull above it (its pixel art,
## MarkerArtData.DEATH_BRAND / _DOOM, when present); it flickers in its last
## second (`left` s of brand left). `doom` draws the green Doom Brand.
## `skull_y` is the skull's y relative to `p` (px; NAN = the old body-radius
## placement, r + DEATH_BRAND_RISE above `p`).
static func draw_brand(ci: CanvasItem, p: Vector2, r: float, phase: float, doom: bool, left: float, skull_y: float = NAN) -> void:
	var a := 0.55 + 0.45 * clampf(left, 0.0, 1.0) * (0.75 + 0.25 * sin(phase * 9.0))  # Alpha (flickers out).
	var col := DOOM if doom else Palette.VIOLET  # Sigil colour.
	_sigil(ci, p, r + 5.0, Color(col, a), phase * 1.6)
	ci.draw_arc(p, r + 7.5, phase * 2.0, phase * 2.0 + PI * 0.6, 8, Color(Palette.NECRO_GREEN, 0.6 * a), 1.5)
	var key := MarkerArtData.DEATH_BRAND_DOOM if doom else MarkerArtData.DEATH_BRAND  # Brand skull art.
	var sy := -r - MarkerArtData.DEATH_BRAND_RISE if is_nan(skull_y) else skull_y  # Skull height (px).
	if SpriteBank.draw_flat(ci, key, p + Vector2(0, sy), 0.0, Color(1.0, 1.0, 1.0, a)):
		return
	Glyphs._skull(ci, p + Vector2(0, -r - 9.0), 3.2, false, col)


## One bone-wall segment of radius `r` at `p`: a cluster of three bone
## spikes over a dark mound, scaled by `grow` (0 -> 1 rising, 1 -> 0 when
## crumbling). `k` varies the spike heights; `ring` tints the Charnel Bastion
## green; `phase` animates the glint. With its pixel art
## (MarkerArtData.BONE_WALL_SEGMENT / BONE_WALL_BASTION) the segment grows up
## out of the ground with `grow`, odd segments mirrored.
static func draw_wall_segment(ci: CanvasItem, p: Vector2, r: float, grow: float, k: int, ring: bool, phase: float) -> void:
	if grow <= 0.01:
		return
	var key := MarkerArtData.BONE_WALL_BASTION if ring else MarkerArtData.BONE_WALL_SEGMENT  # Segment art key.
	if SpriteBank.draw_rising(ci, key, p, grow, k % 2 == 1):
		return
	ci.draw_circle(p + Vector2(0, r * 0.35), r * 0.95, Color(0.07, 0.05, 0.09, 0.55 * grow))
	var rim := Palette.NECRO_GREEN if ring else Palette.VIOLET  # Mound rim.
	ci.draw_arc(p + Vector2(0, r * 0.35), r * 0.95, PI, TAU, 10, Color(rim, 0.45 * grow), 1.0)
	var h := r * (1.5 + 0.35 * float(k % 3))  # Tallest spike (px).
	SpellGlyphs._spike(ci, p + Vector2(-r * 0.5, r * 0.4), h * 0.7 * grow, r * 0.28, grow)
	SpellGlyphs._spike(ci, p + Vector2(r * 0.5, r * 0.4), h * 0.62 * grow, r * 0.26, grow)
	SpellGlyphs._spike(ci, p + Vector2(0, r * 0.45), h * grow, r * 0.34, grow)
	ci.draw_circle(p + Vector2(0, r * 0.45 - h * grow * 0.8), 1.0 + 0.5 * sin(phase * 5.0 + float(k)), Color(rim, 0.7 * grow))


## A soul-lightning arc from `a` to `b`: a jagged violet bolt with a pale
## core. `jag` seeds the (deterministic) jag offsets, `life` runs 1 -> 0 as
## it fades, `damned` adds the Chains of the Damned green glow. `w` is the
## core width (px).
static func draw_lightning(ci: CanvasItem, a: Vector2, b: Vector2, jag: int, life: float, damned: bool, w: float = 2.0) -> void:
	var pts := _jagged(a, b, jag)
	var al := clampf(life, 0.0, 1.0)  # Alpha.
	if damned:
		ci.draw_polyline(pts, Color(Palette.NECRO_GREEN, 0.35 * al), w * 3.5)
	ci.draw_polyline(pts, Color(Palette.VIOLET, 0.75 * al), w * 2.2)
	ci.draw_polyline(pts, Color(LIGHTNING_CORE, al), w)


## Points of a jagged line from `a` to `b`: interior points are pushed
## sideways by up to 22% of a segment's length, from a fixed hash of `jag`
## and the point index (no RNG).
static func _jagged(a: Vector2, b: Vector2, jag: int) -> PackedVector2Array:
	var d := b - a  # Full span.
	var n := clampi(int(d.length() / 14.0), 2, 12)  # Segments.
	var side := d.orthogonal().normalized()  # Sideways direction.
	var step := d.length() / float(n)  # Segment length (px).
	var out := PackedVector2Array([a])
	for i in range(1, n):
		var h := sin(float(jag * 13 + i * 7) * 12.9898) * 43758.5453  # Hash.
		var off := (h - floorf(h)) * 2.0 - 1.0  # -1..1.
		out.append(a + d * (float(i) / float(n)) + side * off * step * 0.44)
	out.append(b)
	return out


## The Wither aura of radius `r` around `p`: a faint sickly disc with a
## turning dashed rim and drooping motes; `flash` (1 -> 0 after a pulse)
## brightens the rim, `busy` (foes inside) thickens it. `blight` draws the
## wider green Necrotic Blight.
static func draw_wither(ci: CanvasItem, p: Vector2, r: float, phase: float, flash: float, blight: bool, busy: bool) -> void:
	if r <= 1.0:
		return
	var col := Palette.NECRO_GREEN if blight else SpellGlyphs.PLAGUE  # Aura colour.
	ci.draw_circle(p, r, Color(col, 0.05 + 0.05 * flash))
	var dashes := 16  # Rim dashes.
	for i in dashes:
		var a0 := phase * 0.5 + TAU * float(i) / float(dashes)
		ci.draw_arc(p, r, a0, a0 + TAU / float(dashes) * 0.6, 4, Color(col, 0.3 + 0.4 * flash), 1.5 + (1.0 if busy else 0.0))
	for i in 5:
		var fall := fposmod(phase * 0.5 + float(i) / 5.0, 1.0)  # 0 -> 1 as a mote droops.
		var q := p + Vector2.from_angle(TAU * float(i) / 5.0 - phase * 0.3) * r * 0.7 + Vector2(0, fall * 10.0)
		ci.draw_circle(q, 1.6, Color(col, 0.55 * (1.0 - fall)))
	if blight:
		ci.draw_arc(p, r * 0.92, -phase * 0.4, -phase * 0.4 + PI * 1.2, 20, Color(SpellGlyphs.PLAGUE, 0.25), 1.0)
