## SeraphGlyphs — code-drawn fallback shapes (no external assets) of the
## Fallen Seraph (Act II, GDD §15.0 "Fallen Seraph"), her evolution, her
## passive's icon and her effects. SummonGlyphs.draw_summon() / draw_icon()
## dispatch these kinds here; units and unit icons always go through
## Glyphs.draw_summon(), so sprite art in assets/sprites/summons/<kind>.png
## (and icons/<kind>.png) wins when present.
##   Fallen Seraph   = a hovering female figure in an ash-grey gown, two
##                     broken black wings (one swept high, one hanging
##                     snapped), a cracked pale halo tilted over the head and
##                     a soul-teal eye glint (the only winged hovering summon),
##   Seraph of Ruin  = the same figure taller, wings whole and spread wide in
##                     black, a halo of black thorns around the cracked ring,
##   Fallen Grace    = a cracked halo with one black feather falling through
##                     it (passive icon),
##   effects         = the dive marker on the pack (a shrinking ash ring with
##                     a feather cross) and the feather ring (black feather
##                     blades on the expanding front, SeraphFeathers).
## Colour language (ART_BIBLE): she is the necromancer's now: desaturated
## ivory, black and ash, with a dim soul-teal accent; never the Covenant's
## gold, never the player's violet. Gold only on the evolution icon frame
## (ProgressionGlyphs._gold_frame()). Polygons are convex so they triangulate.
class_name SeraphGlyphs
extends RefCounted

## Ash grey (gown, rings, impact dust).
const ASH := Color(0.62, 0.62, 0.66)
## Desaturated ivory (skin, halo).
const IVORY_DIM := Color(0.86, 0.84, 0.78)
## Feather black (wings, feather blades): a cold near-black, never pure black.
const FEATHER := Color(0.11, 0.11, 0.14)
## Feather edge highlight (the lit rim of a black feather).
const FEATHER_RIM := Color(0.42, 0.44, 0.50)
## Dim soul-teal accent (eyes, the cracks of the halo).
const SOUL_DIM := Color(0.36, 0.72, 0.62)
## Sprite key of one ring feather (flat art, assets/sprites/projectiles/).
const FEATHER_SPRITE: String = "projectiles/seraph_feather"
## Feather spin across a ring's life (radians; drawing only).
const RING_SPIN: float = 0.9


## Returns the flash colour when `flash` is set, else `col`.
static func _c(col: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else col


## Draws summon glyph `kind` at `o` with body radius `r`. Returns false if
## the kind is unknown here.
static func draw_summon(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"fallen_seraph":
			draw_seraph(ci, o, r, flash, false)
		"ruin_seraph":
			draw_seraph(ci, o, r, flash, true)
		_:
			return false
	return true


## Draws UI icon `kind` centred at `c` with half-size `s` (the evolution gets
## the gold frame). Returns false if the kind is unknown here.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"fallen_seraph":
			Glyphs.draw_summon(ci, kind, c + Vector2(0, s * 0.1), s * 0.46, false)
		"ruin_seraph":
			ProgressionGlyphs._gold_frame(ci, c, s)
			Glyphs.draw_summon(ci, kind, c + Vector2(0, s * 0.14), s * 0.4, false)
		"fallen_grace":
			_icon_fallen_grace(ci, c, s)
		_:
			return false
	return true


# --- Units ---------------------------------------------------------------------------

## Fallen Seraph / Seraph of Ruin (`ruin`): a hovering winged figure facing
## right (see the header).
static func draw_seraph(ci: CanvasItem, o: Vector2, r: float, flash: bool, ruin: bool) -> void:
	var wing := _c(FEATHER, flash)  # Wing colour.
	var rim := _c(FEATHER_RIM, flash)  # Wing edge.
	var gown := _c(ASH.darkened(0.35) if ruin else ASH, flash)  # Gown colour.
	var skin := _c(IVORY_DIM, flash)  # Face, arms.
	var k := 1.15 if ruin else 1.0  # Size of the evolved form.
	# Wings behind the body: the far wing swept high, the near one snapped and hanging.
	var back := o + Vector2(-r * 0.15, -r * 0.35)  # Wing root.
	ci.draw_colored_polygon(PackedVector2Array([back, back + Vector2(-r * 1.5 * k, -r * 1.3 * k),
		back + Vector2(-r * 0.9 * k, -r * 0.1)]), wing)
	ci.draw_line(back, back + Vector2(-r * 1.5 * k, -r * 1.3 * k), rim, 1.0)
	if ruin:
		ci.draw_colored_polygon(PackedVector2Array([back, back + Vector2(r * 1.4 * k, -r * 1.25 * k),
			back + Vector2(r * 0.8 * k, -r * 0.05)]), wing)
		ci.draw_line(back, back + Vector2(r * 1.4 * k, -r * 1.25 * k), rim, 1.0)
	else:
		var joint := back + Vector2(r * 0.7, -r * 0.55)  # The snapped wing's broken joint.
		ci.draw_colored_polygon(PackedVector2Array([back, joint, back + Vector2(r * 0.35, r * 0.1)]), wing)
		ci.draw_colored_polygon(PackedVector2Array([joint, joint + Vector2(r * 0.45, r * 0.9),
			joint + Vector2(r * 0.1, r * 0.75)]), wing)
		ci.draw_line(back, joint, rim, 1.0)
	# Gown: an hourglass (shoulders, cinched waist, wide hips) fraying into wisps.
	var waist := o + Vector2(0, -r * 0.05)  # Waist centre.
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.5 * k, -r * 0.6), o + Vector2(r * 0.5 * k, -r * 0.6),
		waist + Vector2(r * 0.22, 0), waist + Vector2(-r * 0.22, 0)]), gown)
	ci.draw_colored_polygon(PackedVector2Array([waist + Vector2(-r * 0.22, 0), waist + Vector2(r * 0.22, 0),
		o + Vector2(r * 0.7 * k, r * 0.65), o + Vector2(-r * 0.7 * k, r * 0.65)]), gown)
	for i in 3:
		var x := (float(i) - 1.0) * r * 0.42 * k  # Wisp x.
		ci.draw_colored_polygon(PackedVector2Array([o + Vector2(x - r * 0.22, r * 0.6), o + Vector2(x + r * 0.22, r * 0.6),
			o + Vector2(x + r * 0.08 * (float(i) - 1.0), r * (1.15 + 0.12 * float(i % 2)))]), gown)
	# Arms down at the sides, a feather blade in the near hand.
	ci.draw_line(o + Vector2(-r * 0.45, -r * 0.5), o + Vector2(-r * 0.6, r * 0.15), skin, 1.5)
	ci.draw_line(o + Vector2(r * 0.45, -r * 0.5), o + Vector2(r * 0.65, r * 0.1), skin, 1.5)
	_feather(ci, o + Vector2(r * 0.85, r * 0.0), 0.5, r * 0.5, flash)
	# Head, eye glint and the tilted, cracked halo.
	var head := o + Vector2(r * 0.05, -r * 0.92)  # Head centre.
	ci.draw_circle(head, r * 0.32, Glyphs.OUTLINE)
	ci.draw_circle(head, r * 0.26, skin)
	ci.draw_circle(head + Vector2(r * 0.1, -r * 0.02), r * 0.07, _c(SOUL_DIM, flash))
	var halo := head + Vector2(-r * 0.05, -r * 0.42)  # Halo centre.
	ci.draw_set_transform(halo, -0.25, Vector2(1.0, 0.4))
	ci.draw_arc(Vector2.ZERO, r * 0.45, 0.4, TAU - 0.3, 14, _c(IVORY_DIM, flash), 1.5)  # The gap is the crack.
	if ruin:
		for i in 6:
			var a := TAU * float(i) / 6.0  # Thorn angle.
			ci.draw_line(Vector2.from_angle(a) * r * 0.45, Vector2.from_angle(a) * r * 0.7, _c(FEATHER, flash), 1.5)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_line(halo + Vector2(r * 0.3, -r * 0.05), halo + Vector2(r * 0.38, r * 0.08), _c(SOUL_DIM, flash), 1.0)


## One black feather blade centred at `c`, pointing at `angle` (radians),
## `size_px` px long (a convex diamond with a lit spine).
static func _feather(ci: CanvasItem, c: Vector2, angle: float, size_px: float, flash: bool) -> void:
	var d := Vector2.from_angle(angle)  # Feather axis.
	var n := Vector2(-d.y, d.x) * size_px * 0.2  # Half width.
	ci.draw_colored_polygon(PackedVector2Array([c + d * size_px * 0.5, c + n, c - d * size_px * 0.5, c - n]), _c(FEATHER, flash))
	ci.draw_line(c - d * size_px * 0.45, c + d * size_px * 0.45, _c(FEATHER_RIM, flash), 1.0)


# --- Effects -----------------------------------------------------------------------

## Dive marker at `at` (world-aligned local space of the unit) while she
## rises and dives: an ash ring of `r` px closing in with a feather cross.
static func draw_dive_mark(ci: CanvasItem, at: Vector2, r: float, t: float) -> void:
	var pulse := 0.85 + 0.15 * sin(t * 18.0)  # Ring pulse (drawing only).
	ci.draw_circle(at, r, Color(ASH, 0.08))
	ci.draw_arc(at, r * pulse, 0.0, TAU, 28, Color(ASH, 0.7), 1.5)
	ci.draw_line(at + Vector2(-r * 0.35, -r * 0.35), at + Vector2(r * 0.35, r * 0.35), Color(FEATHER_RIM, 0.8), 1.5)
	ci.draw_line(at + Vector2(-r * 0.35, r * 0.35), at + Vector2(r * 0.35, -r * 0.35), Color(FEATHER_RIM, 0.8), 1.5)


## Feather ring (SeraphFeathers) at `pos`: `count` black feather blades on
## the front of radius `front`, pointing outward and turning a little with
## age `t` (s); `fade` 1..0 fades it out. The feather sprite when it exists.
static func draw_ring(ci: CanvasItem, pos: Vector2, front: float, count: int, t: float, fade: float) -> void:
	ci.draw_arc(pos, front, 0.0, TAU, 40, Color(ASH, 0.25 * fade), 1.0)
	var spin := t * RING_SPIN  # Ring turn (radians).
	var art := SpriteBank.has(FEATHER_SPRITE)  # Feather sprite available.
	for i in count:
		var a := TAU * float(i) / float(count) + spin  # Feather angle around the ring.
		var p := pos + Vector2.from_angle(a) * front  # Feather centre.
		if art:
			SpriteBank.draw_flat(ci, FEATHER_SPRITE, p, a, Color(1, 1, 1, fade))
		else:
			_feather_faded(ci, p, a, 11.0, fade)


## A ring feather (code-drawn) at `c` along `angle`, faded by `fade`.
static func _feather_faded(ci: CanvasItem, c: Vector2, angle: float, size_px: float, fade: float) -> void:
	var d := Vector2.from_angle(angle)  # Feather axis.
	var n := Vector2(-d.y, d.x) * size_px * 0.2  # Half width.
	ci.draw_colored_polygon(PackedVector2Array([c + d * size_px * 0.5, c + n, c - d * size_px * 0.5, c - n]), Color(FEATHER, 0.95 * fade))
	ci.draw_line(c - d * size_px * 0.45, c + d * size_px * 0.45, Color(FEATHER_RIM, fade), 1.0)


# --- Icons ---------------------------------------------------------------------------

## Fallen Grace: a cracked pale halo with a black feather falling through it.
static func _icon_fallen_grace(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_set_transform(c + Vector2(0, -s * 0.15), 0.0, Vector2(1.0, 0.45))
	ci.draw_arc(Vector2.ZERO, s * 0.6, 0.5, TAU - 0.35, 20, IVORY_DIM, 3.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_line(c + Vector2(s * 0.45, -s * 0.3), c + Vector2(s * 0.55, -s * 0.05), SOUL_DIM, 1.5)  # The crack.
	_feather(ci, c + Vector2(-s * 0.05, s * 0.25), 1.9, s * 0.95, false)
