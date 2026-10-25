## EmpireFx: draws the pixel art of Act III's ground effects, beams and zones
## (GDD §15.0 "Act III AoE art"; keys and numbers in EmpireFxData, the art made
## by tools/empire_aoe_art.py). It builds on the approved Act I families
## (CovenantFx: band pieces tiled at 1:1 along the exact hit edge, a seamless
## fill laid as clipped 2 px rows, scrolled beam bodies, small stills) and gives
## the Electronic Empire its own look on top: a hazard-striped red / amber band
## with cyan-white targeting ticks, a red hex-grid fill, a cyan-white scan line
## as the timing front, targeting brackets that close in on the area as the
## strike nears, white-hot cores. The drawn danger shape is the exact hit shape
## at every radius, length, side and angle the code uses, and the timing is
## shown wherever the code has a progress.
## Every function returns false and draws nothing when its art is missing, so
## each drawing site keeps its code shape as the fallback. Everything is drawn
## through the sharp-pixel shader (SpriteBank.apply_sharp()) and composed with
## CovenantFx.base (a mirrored unit sets it while it draws world-axis art).
## Textured rects only (they batch): no per-frame polygons (CLAUDE.md, GDD §15.0
## "Web GL id leak patch"). Purely visual: it reads positions and timers, never
## changes them, and uses no randomness (variety from a fixed index hash), so
## runs stay deterministic per seed.
class_name EmpireFx
extends RefCounted

## Warning red of the soft base tints (Palette.EMPIRE_SIGNAL_RED).
const RED := Color(0.878, 0.224, 0.118)
## Amber of the softer tints (Palette.EMPIRE_SIGNAL_AMBER).
const AMBER := Color(1.0, 0.682, 0.102)


## True when the art of `key` exists (CovenantFx's cache: one wrapped texture each).
static func has(key: String) -> bool:
	return CovenantFx.has(key)


## Sets `ci`'s drawing transform to CovenantFx.base x (scale `s`, turn `rot`,
## then move to `pos`).
static func _xf(ci: CanvasItem, pos: Vector2, rot: float, s: Vector2 = Vector2.ONE) -> void:
	ci.draw_set_transform_matrix(CovenantFx.base * Transform2D(rot, s, 0.0, pos))


## Sets `ci`'s drawing transform back to CovenantFx.base.
static func _reset(ci: CanvasItem) -> void:
	ci.draw_set_transform_matrix(CovenantFx.base)


## Draws frame `f` of the `frames`-frame strip `key` centred on `c`, turned by
## `angle` (rad; the art points +x), scaled by `scale`, multiplied by
## `modulate`. An unturned, unscaled frame lands on whole px. False when missing.
static func frame(ci: CanvasItem, key: String, frames: int, f: int, c: Vector2, angle: float = 0.0, scale: float = 1.0, modulate: Color = Color.WHITE) -> bool:
	var t := CovenantFx.tex(key)  # Strip art.
	if t == null:
		return false
	if modulate.a <= 0.003:
		return true
	SpriteBank.apply_sharp(ci)
	var fw := float(t.get_width()) / float(maxi(1, frames))  # Frame width (px).
	var fh := float(t.get_height())  # Frame height (px).
	var src := Rect2(fw * float(posmod(f, maxi(1, frames))), 0.0, fw, fh)  # Frame in the strip.
	if angle == 0.0 and scale == 1.0:
		_reset(ci)
		ci.draw_texture_rect_region(t, Rect2((c - Vector2(fw, fh) * 0.5).round(), Vector2(fw, fh)), src, modulate)
		return true
	_xf(ci, c, angle, Vector2(scale, scale))
	ci.draw_texture_rect_region(t, Rect2(-fw * 0.5, -fh * 0.5, fw, fh), src, modulate)
	_reset(ci)
	return true


## The four targeting-box corners round the box of half-size `h` at `c`, each
## corner pixel on (c +- h): the brackets of an orbital strike or a stamp.
static func brackets(ci: CanvasItem, c: Vector2, h: float, modulate: Color) -> void:
	var t := CovenantFx.tex(EmpireFxData.BRACKET)  # Corner art (corner pixel at its top left).
	if t == null:
		return
	SpriteBank.apply_sharp(ci)
	var size := Vector2(float(t.get_width()), float(t.get_height()))  # Art size (px).
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			# Mirror the top-left corner art so its arms point back into the box.
			_xf(ci, (c + Vector2(sx * h, sy * h)).round(), 0.0, Vector2(-sx, -sy))
			ci.draw_texture_rect(t, Rect2(Vector2.ZERO, size), false, modulate)
	_reset(ci)


## Ease-out of the timing `k` (0..1) the brackets close with.
static func _close(k: float) -> float:
	var q := 1.0 - clampf(k, 0.0, 1.0)
	return 1.0 - q * q


## The impact strip (AnimData id) that fits an Empire impact colour `col`: the
## warning-red one for signal red, the chrome one for chrome / cyan-white, else
## the amber one (EffectManager.impact(..., anim); visual only).
static func blast_for(col: Color) -> String:
	if col.is_equal_approx(Palette.EMPIRE_SIGNAL_RED):
		return EmpireFxData.BLAST_RED
	if col.is_equal_approx(Palette.EMPIRE_CHROME_LIGHT) or col.is_equal_approx(Palette.EMPIRE_CHROME):
		return EmpireFxData.BLAST_CHROME
	return EmpireFxData.BLAST


## True when the Empire's warning set has its art.
static func has_warning() -> bool:
	return has(EmpireFxData.EDGE) and has(EmpireFxData.HEX) and has(EmpireFxData.FRONT)


# =====================================================================================
# The Empire's warnings (orbital strikes, guns, mortars, Deus's rings, the
# Motherboard's stamps and hurls, the shared Effect telegraphs on Act III stages)
# =====================================================================================

## An Empire warning circle at `c`, radius `r` (the hit edge), timing `k`
## (0..1): a faint red tint, the hex grid over the whole area and denser (with
## a tint) inside r x k, the cyan-white scan line at r x k, the hazard band on
## the exact edge with targeting ticks into it, the crosshair, and (when
## `boxed` and big enough) the four targeting brackets closing from 1.45 r to the
## circle's bounding box as the strike nears. False when the art is missing.
static func telegraph_circle(ci: CanvasItem, c: Vector2, r: float, k: float, boxed: bool = true) -> bool:
	if not has_warning():
		return false
	k = clampf(k, 0.0, 1.0)
	_reset(ci)
	CovenantFx.soft_disc(ci, c, r, Color(RED, EmpireFxData.BASE_ALPHA))
	CovenantFx.hatch_disc(ci, c, r, Color(1.0, 1.0, 1.0, EmpireFxData.HEX_ALPHA), EmpireFxData.HEX)
	if k > 0.02:
		CovenantFx.soft_disc(ci, c, r * k, Color(RED, EmpireFxData.FILL_TINT))
		CovenantFx.hatch_disc(ci, c, r * k, Color(1.0, 1.0, 1.0, EmpireFxData.FILL_ALPHA), EmpireFxData.HEX)
		CovenantFx.ring(ci, c, r * k, EmpireFxData.FRONT, Color(1.0, 1.0, 1.0, EmpireFxData.FRONT_ALPHA), EmpireFxData.FRONT_ROW)
	if r >= EmpireFxData.TARGET_MIN_RADIUS:
		CovenantFx.still(ci, EmpireFxData.TARGET, c, Color(1.0, 1.0, 1.0, EmpireFxData.TARGET_ALPHA))
	CovenantFx.ring(ci, c, r, EmpireFxData.EDGE, Color(1.0, 1.0, 1.0, EmpireFxData.EDGE_ALPHA), EmpireFxData.EDGE_ROW,
		0.0, TAU, 0.0, EmpireFxData.EDGE_TICK, EmpireFxData.TICK_EVERY)
	if boxed and r >= EmpireFxData.BRACKET_MIN_RADIUS:
		var h := r * lerpf(EmpireFxData.BRACKET_FROM, 1.0, _close(k))  # Box half-size (px).
		brackets(ci, c, h, Color(1.0, 1.0, 1.0, EmpireFxData.BRACKET_ALPHA))
	_reset(ci)
	return true


## An orbital strike's warning (the Purge Protocol, the Citadel's guns): the
## warning circle, and over its last moment the uplink column striking down
## from the sky onto the centre, narrow and faint at first. False when missing.
static func orbital(ci: CanvasItem, c: Vector2, r: float, k: float) -> bool:
	if not telegraph_circle(ci, c, r, k):
		return false
	var u := clampf((k - EmpireFxData.UPLINK_FROM) / (1.0 - EmpireFxData.UPLINK_FROM), 0.0, 1.0)  # 0 -> 1 over the last moment.
	var t := CovenantFx.tex(EmpireFxData.UPLINK)  # Column art (base on its bottom row).
	if u > 0.0 and t != null:
		SpriteBank.apply_sharp(ci)
		_reset(ci)
		var hw := float(t.get_width()) * 0.5 * (0.35 + 0.65 * u)  # Half width (px).
		var hgt := EmpireFxData.UPLINK_HEIGHT  # Height above the centre (px).
		ci.draw_texture_rect(t, Rect2(c.x - hw, c.y - hgt, hw * 2.0, hgt), false, Color(1.0, 1.0, 1.0, EmpireFxData.UPLINK_ALPHA * u))
	return true


## An Empire warning lane from the node origin to `vec`, `width` px wide, timing
## `k` (0..1): the tint and hex grid over the lane, denser over its first k, the
## double chevrons (lit once the timing passes them), the hazard band round its
## four sides and the scan line across it. False when the art is missing.
static func telegraph_line(ci: CanvasItem, vec: Vector2, width: float, k: float) -> bool:
	var hex := CovenantFx.tex(EmpireFxData.HEX, true)  # Seamless hex tile.
	if hex == null or not has(EmpireFxData.EDGE) or not has(EmpireFxData.FRONT):
		return false
	k = clampf(k, 0.0, 1.0)
	var ln := vec.length()  # Lane length (px).
	if ln < 1.0:
		return true
	SpriteBank.apply_sharp(ci)
	var ang := vec.angle()  # Lane direction (rad).
	var h := width * 0.5  # Half width (px).
	var lane := Rect2(0.0, -h, ln, width)  # The lane in its own frame (x along it).
	_xf(ci, Vector2.ZERO, ang)
	ci.draw_rect(lane, Color(RED, EmpireFxData.BASE_ALPHA))
	ci.draw_texture_rect_region(hex, lane, lane, Color(1.0, 1.0, 1.0, EmpireFxData.HEX_ALPHA))
	if k > 0.02:
		var filled := Rect2(0.0, -h, ln * k, width)  # The part the timing has filled.
		ci.draw_rect(filled, Color(RED, EmpireFxData.FILL_TINT))
		ci.draw_texture_rect_region(hex, filled, filled, Color(1.0, 1.0, 1.0, EmpireFxData.FILL_ALPHA))
	_reset(ci)
	var dir := vec / ln  # Unit lane direction.
	if width >= 14.0:
		var x := EmpireFxData.CHEVRON_PITCH * 0.5  # Chevron position along the lane (px).
		while x < ln - 6.0:
			var lit := x <= ln * k  # The timing has passed it.
			CovenantFx.still(ci, EmpireFxData.CHEVRON, dir * x, Color(1.0, 1.0, 1.0,
				EmpireFxData.CHEVRON_ALPHA.y if lit else EmpireFxData.CHEVRON_ALPHA.x), ang)
			x += EmpireFxData.CHEVRON_PITCH
	var xf := Transform2D(ang, Vector2.ZERO)  # Lane frame -> node.
	if k > 0.02:
		CovenantFx.edge_run(ci, xf * Vector2(ln * k, -h), xf * Vector2(ln * k, h), EmpireFxData.FRONT,
			Color(1.0, 1.0, 1.0, EmpireFxData.FRONT_ALPHA), EmpireFxData.FRONT_ROW)
	_box_edge(ci, xf, Vector2(0.0, -h), Vector2(ln, h))
	return true


## The hazard band round the rectangle (min corner `lo`, max corner `hi`, in
## the frame `xf`), walked clockwise on screen so the band's outer row is outside.
static func _box_edge(ci: CanvasItem, xf: Transform2D, lo: Vector2, hi: Vector2) -> void:
	var em := Color(1.0, 1.0, 1.0, EmpireFxData.EDGE_ALPHA)  # Band modulate.
	var row := EmpireFxData.EDGE_ROW
	var tick := EmpireFxData.EDGE_TICK
	var every := EmpireFxData.TICK_EVERY
	CovenantFx.edge_run(ci, xf * Vector2(lo.x, lo.y), xf * Vector2(hi.x, lo.y), EmpireFxData.EDGE, em, row, tick, every)
	CovenantFx.edge_run(ci, xf * Vector2(hi.x, lo.y), xf * Vector2(hi.x, hi.y), EmpireFxData.EDGE, em, row, tick, every)
	CovenantFx.edge_run(ci, xf * Vector2(hi.x, hi.y), xf * Vector2(lo.x, hi.y), EmpireFxData.EDGE, em, row, tick, every)
	CovenantFx.edge_run(ci, xf * Vector2(lo.x, hi.y), xf * Vector2(lo.x, lo.y), EmpireFxData.EDGE, em, row, tick, every)


## An Empire warning cone at `c`, radius `r`, facing `dir`, `half` rad each
## side, timing `k`: the hex grid over the sector and denser inside r x k, the
## scan line on the arc at r x k, the hazard band along both sides and the arc.
## False when the art is missing.
static func telegraph_cone(ci: CanvasItem, c: Vector2, r: float, dir: Vector2, half: float, k: float) -> bool:
	if not has_warning():
		return false
	k = clampf(k, 0.0, 1.0)
	var face := dir.angle()  # Facing (rad).
	CovenantFx.hatch_sector(ci, c, r, face, half, Color(1.0, 1.0, 1.0, EmpireFxData.HEX_ALPHA), EmpireFxData.HEX)
	if k > 0.02:
		CovenantFx.hatch_sector(ci, c, r * k, face, half, Color(1.0, 1.0, 1.0, EmpireFxData.FILL_ALPHA), EmpireFxData.HEX)
		CovenantFx.ring(ci, c, r * k, EmpireFxData.FRONT, Color(1.0, 1.0, 1.0, EmpireFxData.FRONT_ALPHA), EmpireFxData.FRONT_ROW, face - half, face + half)
	_sector_edge(ci, c, r, face - half, face + half)
	return true


## The hazard band along a sector's two sides and its arc (angles `a0` < `a1`).
static func _sector_edge(ci: CanvasItem, c: Vector2, r: float, a0: float, a1: float) -> void:
	var em := Color(1.0, 1.0, 1.0, EmpireFxData.EDGE_ALPHA)  # Band modulate.
	var row := EmpireFxData.EDGE_ROW
	var tick := EmpireFxData.EDGE_TICK
	var every := EmpireFxData.TICK_EVERY
	CovenantFx.edge_run(ci, c, c + Vector2.from_angle(a0) * r, EmpireFxData.EDGE, em, row, tick, every)
	CovenantFx.ring(ci, c, r, EmpireFxData.EDGE, em, row, a0, a1, 0.0, tick, every)
	CovenantFx.edge_run(ci, c + Vector2.from_angle(a1) * r, c, EmpireFxData.EDGE, em, row, tick, every)


## A telegraphed sweep (Deus's chaingun and lance wind-ups): the sector of
## radius `reach` round `o` from angle `a0` to `a1` (either order), its hex
## grid growing with `k` (0..1), the band on its sides and arc. False when missing.
static func sweep(ci: CanvasItem, o: Vector2, a0: float, a1: float, reach: float, k: float) -> bool:
	if not has_warning():
		return false
	var lo := minf(a0, a1)  # Sector start (rad).
	var hi := maxf(a0, a1)  # Sector end (rad).
	var mid := (lo + hi) * 0.5  # Facing (rad).
	var half := (hi - lo) * 0.5  # Half angle (rad).
	k = clampf(k, 0.0, 1.0)
	CovenantFx.hatch_sector(ci, o, reach, mid, half, Color(1.0, 1.0, 1.0, EmpireFxData.HEX_ALPHA + (EmpireFxData.FILL_ALPHA - EmpireFxData.HEX_ALPHA) * k * 0.6), EmpireFxData.HEX)
	_sector_edge(ci, o, reach, lo, hi)
	return true


## An Empire square warning centred on `c` (side `side` px, the exact hit
## square), timing `k`: the hex grid over the square, a denser inner square of
## side x k with the scan line round it, the hazard band on its four sides and
## the targeting brackets closing on its corners (the Motherboard's stamps).
## False when the art is missing.
static func square(ci: CanvasItem, c: Vector2, side: float, k: float) -> bool:
	var hex := CovenantFx.tex(EmpireFxData.HEX, true)  # Seamless hex tile.
	if hex == null or not has(EmpireFxData.EDGE) or not has(EmpireFxData.FRONT):
		return false
	k = clampf(k, 0.0, 1.0)
	SpriteBank.apply_sharp(ci)
	_reset(ci)
	var h := side * 0.5  # Half side (px).
	var sq := Rect2(c - Vector2(h, h), Vector2(side, side))  # The hit square.
	ci.draw_rect(sq, Color(RED, EmpireFxData.BASE_ALPHA))
	ci.draw_texture_rect_region(hex, sq, sq, Color(1.0, 1.0, 1.0, EmpireFxData.HEX_ALPHA))
	if k > 0.02:
		var ih := h * k  # Inner half side (px).
		var inner := Rect2(c - Vector2(ih, ih), Vector2(ih, ih) * 2.0)  # The filled part.
		ci.draw_rect(inner, Color(RED, EmpireFxData.FILL_TINT))
		ci.draw_texture_rect_region(hex, inner, inner, Color(1.0, 1.0, 1.0, EmpireFxData.FILL_ALPHA))
		var fm := Color(1.0, 1.0, 1.0, EmpireFxData.FRONT_ALPHA)  # Front modulate.
		var fr := EmpireFxData.FRONT_ROW
		CovenantFx.edge_run(ci, inner.position, Vector2(inner.end.x, inner.position.y), EmpireFxData.FRONT, fm, fr)
		CovenantFx.edge_run(ci, Vector2(inner.end.x, inner.position.y), inner.end, EmpireFxData.FRONT, fm, fr)
		CovenantFx.edge_run(ci, inner.end, Vector2(inner.position.x, inner.end.y), EmpireFxData.FRONT, fm, fr)
		CovenantFx.edge_run(ci, Vector2(inner.position.x, inner.end.y), inner.position, EmpireFxData.FRONT, fm, fr)
	_box_edge(ci, Transform2D.IDENTITY, sq.position, sq.end)
	brackets(ci, c, h * lerpf(1.3, 1.0, _close(k)), Color(1.0, 1.0, 1.0, EmpireFxData.BRACKET_ALPHA))
	_reset(ci)
	return true


## A turret construction frame (the Motherboard's builds) centred on `c`, side
## `side`, `k` (0..1) to the build: an amber-tinted hex square, the four
## brackets on its corners and the scan line rising through it. False when missing.
static func build_frame(ci: CanvasItem, c: Vector2, side: float, k: float) -> bool:
	var hex := CovenantFx.tex(EmpireFxData.HEX, true)  # Seamless hex tile.
	if hex == null or not has(EmpireFxData.FRONT) or not has(EmpireFxData.BRACKET):
		return false
	k = clampf(k, 0.0, 1.0)
	SpriteBank.apply_sharp(ci)
	_reset(ci)
	var h := side * 0.5  # Half side (px).
	var sq := Rect2(c - Vector2(h, h), Vector2(side, side))  # The frame square.
	ci.draw_rect(sq, Color(AMBER, 0.06 + 0.12 * k))
	ci.draw_texture_rect_region(hex, sq, sq, Color(1.0, 1.0, 1.0, 0.25 + 0.35 * k))
	var y := sq.end.y - side * k  # The scan line (rising).
	CovenantFx.edge_run(ci, Vector2(sq.position.x, y), Vector2(sq.end.x, y), EmpireFxData.FRONT, Color(1.0, 1.0, 1.0, 0.95), EmpireFxData.FRONT_ROW)
	brackets(ci, c, h, Color(1.0, 1.0, 1.0, 0.95))
	_reset(ci)
	return true


# =====================================================================================
# Beams (the Death Ray, the laser grid, the Judgment Lance)
# =====================================================================================

## A beam from `a` to `b`, `width` px wide (its exact width): the glow `glow`
## stretched to `glow_mult` x the width under it (opacity `glow_a`), the body
## `body` scrolled `scroll` px outward, and the head strip `tip` (TIP_FRAMES)
## at `b` (and smaller at `a`), its frame by `now`. False when the art is missing.
static func beam(ci: CanvasItem, a: Vector2, b: Vector2, width: float, body: String, glow: String, glow_mult: float, glow_a: float,
		tip: String, scroll: float, now: float, modulate: Color = Color.WHITE) -> bool:
	if not has(body):
		return false
	if (b - a).length() < 1.0:
		return true
	CovenantFx.ray_strip(ci, a, b, glow, width * glow_mult, 0.0, Color(modulate, modulate.a * glow_a))
	CovenantFx.ray_strip(ci, a, b, body, width, scroll, modulate)
	var tt := CovenantFx.tex(tip)  # Head strip.
	if tt != null:
		var f := int(now * EmpireFxData.TIP_FPS)  # Head frame.
		var th := float(tt.get_height())  # Head size (px).
		frame(ci, tip, EmpireFxData.TIP_FRAMES, f, b, 0.0, maxf(0.5, width * 1.5 / th), modulate)
		frame(ci, tip, EmpireFxData.TIP_FRAMES, f + 2, a, 0.0, maxf(0.4, width * 1.0 / th), Color(modulate, modulate.a * 0.8))
	return true


## The Death Ray's beams from `p` (`length` px, `w` px wide; beam k at angle
## `angle` + TAU k / `beams`): four fading afterglow copies trailing each beam
## (the code's TRAIL_ANGLE), the glow, the violet soul-laser body scrolling
## outward and the tip burst. False when the art is missing.
static func death_ray(ci: CanvasItem, p: Vector2, angle: float, beams: int, length: float, w: float, trail: float, now: float) -> bool:
	if not has(EmpireFxData.RAY_BODY) or not has(EmpireFxData.RAY_GLOW):
		return false
	for k in beams:
		var a := angle + TAU * float(k) / float(maxi(1, beams))  # This beam's angle.
		for t in 4:
			var ta := a - trail * float(t + 1) / 4.0  # Afterglow angle.
			CovenantFx.ray_strip(ci, p, p + Vector2.from_angle(ta) * length, EmpireFxData.RAY_GLOW, w * 1.4, 0.0,
				Color(1.0, 1.0, 1.0, maxf(0.0, EmpireFxData.AFTER_ALPHA - EmpireFxData.AFTER_STEP * float(t))))
		beam(ci, p, p + Vector2.from_angle(a) * length, w, EmpireFxData.RAY_BODY, EmpireFxData.RAY_GLOW, EmpireFxData.RAY_GLOW_MULT,
			EmpireFxData.RAY_GLOW_ALPHA, EmpireFxData.RAY_TIP, now * EmpireFxData.RAY_SCROLL, now)
	return true


## A laser grid beam from `a` to `b` (`w` px): telegraphed (`firing` false) a
## dashed sight line blinking and thickening as `tele` (0..1) rises, with armed
## emitters at both ends; firing, the white-hot body in its red glow with firing
## emitters. False when the art is missing.
static func laser(ci: CanvasItem, a: Vector2, b: Vector2, w: float, firing: bool, tele: float, now: float) -> bool:
	if not has(EmpireFxData.LASER_BODY) or not has(EmpireFxData.LASER_WARN):
		return false
	var cap := 1 if firing else 0  # Emitter frame.
	if firing:
		CovenantFx.ray_strip(ci, a, b, EmpireFxData.LASER_GLOW, w * EmpireFxData.LASER_GLOW_MULT, 0.0, Color(1.0, 1.0, 1.0, 0.95))
		CovenantFx.ray_strip(ci, a, b, EmpireFxData.LASER_BODY, w, now * EmpireFxData.LASER_SCROLL)
		for end: Vector2 in [a, b]:
			frame(ci, EmpireFxData.LASER_CAP, 2, cap, end, 0.0, maxf(1.0, w * 0.75 / EmpireFxData.LASER_CAP_R))
		return true
	var blink := 0.55 + 0.45 * float(int(now * 16.0) % 2)  # The code's blink.
	CovenantFx.ray_strip(ci, a, b, EmpireFxData.LASER_WARN, 2.0 + 2.0 * tele, -now * 60.0, Color(1.0, 1.0, 1.0, (0.35 + 0.6 * tele) * blink))
	for end: Vector2 in [a, b]:
		frame(ci, EmpireFxData.LASER_CAP, 2, cap, end, 0.0, (4.0 + 3.0 * tele) / EmpireFxData.LASER_CAP_R, Color(1.0, 1.0, 1.0, 0.9))
	return true


## The band a telegraphed laser will sweep (the code's draw_laser_band
## arguments): the hex grid over the exact band from its start line (`c0`, half
## length `half` along `along`) `sweep` px along `n`, double chevrons pointing
## the way it will sweep, and a sight line on its far edge. False when missing.
static func laser_band(ci: CanvasItem, c0: Vector2, n: Vector2, along: Vector2, half: float, sweep_px: float, tele: float) -> bool:
	var hex := CovenantFx.tex(EmpireFxData.HEX, true)  # Seamless hex tile.
	if hex == null or not has(EmpireFxData.CHEVRON):
		return false
	SpriteBank.apply_sharp(ci)
	var rot := along.angle()  # Band frame: x along the beam, y along n (or against it).
	var ny := 1.0 if along.orthogonal().dot(n) < 0.0 else -1.0  # Which side of the frame n points to.
	var rect := Rect2(-half, 0.0 if ny > 0.0 else -sweep_px, half * 2.0, sweep_px)  # The band in its frame.
	_xf(ci, c0, rot)
	ci.draw_rect(rect, Color(RED, 0.06 + 0.08 * tele))  # The code's red film.
	ci.draw_texture_rect_region(hex, rect, rect, Color(1.0, 1.0, 1.0, EmpireFxData.BAND_ALPHA.x + EmpireFxData.BAND_ALPHA.y * tele))
	_reset(ci)
	var x := -half + EmpireFxData.BAND_CHEVRON_PITCH * 0.5  # Chevron position along the band (px).
	var ca := Color(1.0, 1.0, 1.0, 0.3 + 0.55 * tele)  # Chevron modulate.
	while x < half:
		CovenantFx.still(ci, EmpireFxData.CHEVRON, c0 + along * x + n * sweep_px * 0.5, ca, n.angle())
		x += EmpireFxData.BAND_CHEVRON_PITCH
	CovenantFx.ray_strip(ci, c0 - along * half + n * sweep_px, c0 + along * half + n * sweep_px, EmpireFxData.LASER_WARN, 2.0, 0.0,
		Color(1.0, 1.0, 1.0, 0.25 + 0.4 * tele))
	return true


## The Judgment Lance along `dir` from the node origin (`len` px, `w` px wide):
## telegraphed (`firing` false) a sight line thickening with `k`; firing, the
## amber-white body in its glow with the blazing head. False when missing.
static func lance(ci: CanvasItem, dir: Vector2, len: float, w: float, firing: bool, k: float, now: float) -> bool:
	if not has(EmpireFxData.LANCE_BODY) or not has(EmpireFxData.LASER_WARN):
		return false
	var b := dir * len  # Far end.
	if not firing:
		CovenantFx.ray_strip(ci, Vector2.ZERO, b, EmpireFxData.LASER_WARN, 2.0 + 4.0 * k, -now * 80.0, Color(1.0, 1.0, 1.0, 0.4 + 0.5 * k))
		return true
	var flick := 0.85 + 0.15 * sin(now * 40.0)  # The code's flicker.
	return beam(ci, Vector2.ZERO, b, w, EmpireFxData.LANCE_BODY, EmpireFxData.LANCE_GLOW, EmpireFxData.LANCE_GLOW_MULT, 0.6 * flick,
		EmpireFxData.LANCE_TIP, now * EmpireFxData.LASER_SCROLL, now)


# =====================================================================================
# The Iron Citadel: Shield Gates
# =====================================================================================

## A Shield Gate's energy wall from `a` to `b` (`thick` px: the solid wall),
## powering up from `a` as `power` (0..1) rises: the outer glow, the hex energy
## field scrolling along it, and the chrome emitters at both ends. False when missing.
static func gate_wall(ci: CanvasItem, a: Vector2, b: Vector2, thick: float, power: float, now: float) -> bool:
	if not has(EmpireFxData.GATE_WALL):
		return false
	var flick := 0.85 + 0.15 * sin(now * 13.0)  # The code's flicker.
	var end := a + (b - a) * clampf(power, 0.0, 1.0)  # How far the wall has risen.
	if end.distance_to(a) >= 1.0:
		CovenantFx.ray_strip(ci, a, end, EmpireFxData.GATE_GLOW, thick + 10.0, 0.0, Color(1.0, 1.0, 1.0, flick))
		CovenantFx.ray_strip(ci, a, end, EmpireFxData.GATE_WALL, thick, now * EmpireFxData.GATE_SCROLL, Color(1.0, 1.0, 1.0, 0.85 + 0.15 * flick))
	for p: Vector2 in [a, b]:
		CovenantFx.still(ci, EmpireFxData.GATE_POST, p)
	return true


## A generator's power cable from `from` to the wall end `to`, pulsing toward it.
## False when the art is missing.
static func gate_cable(ci: CanvasItem, from: Vector2, to: Vector2, now: float) -> bool:
	var k := 0.5 + 0.5 * sin(now * 6.0)  # The code's pulse.
	return CovenantFx.ray_strip(ci, from, to, EmpireFxData.GATE_CABLE, 5.0, now * EmpireFxData.CABLE_SCROLL, Color(1.0, 1.0, 1.0, 0.55 + 0.4 * k))


# =====================================================================================
# The Assembly Halls: conveyor belts and furnace channels
# =====================================================================================

## Sets `ci`'s transform so (u along the strip, v across it from its top /
## left edge) maps onto strip `rect` (a swap of axes for a vertical strip).
static func _strip_xf(ci: CanvasItem, rect: Rect2, along_x: bool) -> void:
	if along_x:
		ci.draw_set_transform_matrix(CovenantFx.base * Transform2D(Vector2(1, 0), Vector2(0, 1), rect.position))
	else:
		ci.draw_set_transform_matrix(CovenantFx.base * Transform2D(Vector2(0, 1), Vector2(1, 0), rect.position))


## A conveyor belt filling `rect` (world px) along x (`along_x`) or y, running
## `dir` (+1 / -1), `scroll` px moved so far (game time x speed): its baked
## repeat tile for the belt's width, scrolled with the belt (one textured rect;
## the tile is mirrored for a belt running -x). False when there is no tile for
## this width (the code draws it).
static func belt(ci: CanvasItem, rect: Rect2, along_x: bool, dir: float, scroll: float) -> bool:
	var width := rect.size.y if along_x else rect.size.x  # Across the belt (px).
	var key := String(EmpireFxData.BELTS.get(int(round(width)), ""))  # Its tile.
	var t := CovenantFx.tex(key, true) if key != "" else null  # Repeating tile.
	if t == null or absf(float(t.get_height()) - width) > 0.5:
		return false
	SpriteBank.apply_sharp(ci)
	var length := rect.size.x if along_x else rect.size.y  # Along it (px).
	var start := rect.position.x if along_x else rect.position.y  # World coordinate of its start.
	_strip_xf(ci, rect, along_x)
	if dir >= 0.0:
		# The pattern is anchored to the world and slides with the belt.
		ci.draw_texture_rect_region(t, Rect2(0.0, 0.0, length, width), Rect2(start - scroll, 0.0, length, width))
	else:
		# Mirrored along the belt: the chevrons point -x and slide that way.
		var m := Transform2D(Vector2(-1, 0), Vector2(0, 1), Vector2(length, 0.0))  # u -> length - u.
		if along_x:
			ci.draw_set_transform_matrix(CovenantFx.base * Transform2D(Vector2(1, 0), Vector2(0, 1), rect.position) * m)
		else:
			ci.draw_set_transform_matrix(CovenantFx.base * Transform2D(Vector2(0, 1), Vector2(1, 0), rect.position) * m)
		ci.draw_texture_rect_region(t, Rect2(0.0, 0.0, length, width), Rect2(-(start + length) - scroll, 0.0, length, width))
	_reset(ci)
	return true


## A furnace channel filling `rect` in state `state` (AssemblyDirector DORMANT
## / WARNING / BURNING) at `progress` (0..1) through it, `now` (game s): the
## iron rim along both long sides; cold slag with seams glowing brighter as it
## nears its warning; then molten metal seeping in under blinking hazard
## stripes; burning, molten metal flowing along it with a heat haze and flame
## tongues. Patterns are anchored to the world. False when the art is missing.
static func channel(ci: CanvasItem, rect: Rect2, along_x: bool, state: int, progress: float, now: float) -> bool:
	var slag := CovenantFx.tex(EmpireFxData.FURNACE_SLAG, true)  # Slag tile.
	var molten := CovenantFx.tex(EmpireFxData.FURNACE_MOLTEN[posmod(int(now / EmpireFxData.FURNACE_FLICKER), EmpireFxData.FURNACE_MOLTEN.size())], true)  # This flicker frame.
	if slag == null or molten == null or not has(EmpireFxData.FURNACE_RIM):
		return false
	SpriteBank.apply_sharp(ci)
	var length := rect.size.x if along_x else rect.size.y  # Along it (px).
	var width := rect.size.y if along_x else rect.size.x  # Across it (px).
	var start := rect.position.x if along_x else rect.position.y  # World coordinate along it.
	var across0 := rect.position.y if along_x else rect.position.x  # World coordinate across it.
	var rim := AssemblyGlyphs.RAIL_W  # Rim width (px).
	var trough := Rect2(0.0, rim, length, width - rim * 2.0)  # Strip space.
	var src := Rect2(start, across0 + rim, length, width - rim * 2.0)  # World-anchored pattern.
	_strip_xf(ci, rect, along_x)
	match state:
		AssemblyDirector.DORMANT:
			ci.draw_texture_rect_region(slag, trough, src)
			var emb := CovenantFx.tex(EmpireFxData.FURNACE_EMBERS, true)  # Glowing seams.
			if emb != null:
				ci.draw_texture_rect_region(emb, trough, src, Color(1.0, 1.0, 1.0, 0.35 + 0.45 * progress))
		AssemblyDirector.WARNING:
			ci.draw_texture_rect_region(slag, trough, src)
			ci.draw_texture_rect_region(molten, trough, src, Color(1.0, 1.0, 1.0, 0.25 + 0.55 * progress))
			var emb2 := CovenantFx.tex(EmpireFxData.FURNACE_EMBERS, true)  # Seams, white-hot now.
			if emb2 != null:
				ci.draw_texture_rect_region(emb2, trough, src, Color(1.5, 1.4, 1.2, 0.8))
		_:
			var flow := Rect2(src.position - Vector2(now * EmpireFxData.FURNACE_FLOW, 0.0), src.size)  # Flowing along.
			ci.draw_texture_rect_region(molten, trough, flow)
	_reset(ci)
	# The rim along both long sides (walked so the piece's row 0 faces outward).
	var xf := Transform2D(Vector2(1, 0), Vector2(0, 1), rect.position) if along_x else Transform2D(Vector2(0, 1), Vector2(1, 0), rect.position)  # Strip -> node.
	var top_a := xf * Vector2(0.0, 0.0)
	var top_b := xf * Vector2(length, 0.0)
	var bot_a := xf * Vector2(length, width)
	var bot_b := xf * Vector2(0.0, width)
	if not along_x:  # The axis swap mirrors the walk: walk the other way round.
		var sa := top_a
		top_a = top_b
		top_b = sa
		var sb := bot_a
		bot_a = bot_b
		bot_b = sb
	CovenantFx.edge_run(ci, top_a, top_b, EmpireFxData.FURNACE_RIM, Color.WHITE, 0.0)
	CovenantFx.edge_run(ci, bot_a, bot_b, EmpireFxData.FURNACE_RIM, Color.WHITE, 0.0)
	if state == AssemblyDirector.WARNING:
		var pulse := 0.6 + 0.4 * sin(now * 18.0)  # The code's warning pulse.
		CovenantFx.edge_run(ci, top_a, top_b, EmpireFxData.FURNACE_WARN, Color(1.0, 1.0, 1.0, pulse), 0.0)  # Over the rim, as the code's 2 px edges.
		CovenantFx.edge_run(ci, bot_a, bot_b, EmpireFxData.FURNACE_WARN, Color(1.0, 1.0, 1.0, pulse), 0.0)
	elif state != AssemblyDirector.DORMANT:
		var haze := 1.0 - progress * 0.5  # The code's haze fade.
		CovenantFx.edge_run(ci, top_b, top_a, EmpireFxData.FURNACE_HAZE, Color(1.0, 1.0, 1.0, haze), 0.0)
		CovenantFx.edge_run(ci, bot_b, bot_a, EmpireFxData.FURNACE_HAZE, Color(1.0, 1.0, 1.0, haze), 0.0)
		if AdaptiveQuality.tier() == 0 and has(EmpireFxData.FURNACE_FLAME):
			_channel_flames(ci, xf, start, length, width, now)
	return true


## Flame tongues licking up from a burning channel at world-anchored slots
## (every FURNACE_FLAME_PITCH px along it, alternating sides), each on its own
## frame offset.
static func _channel_flames(ci: CanvasItem, xf: Transform2D, start: float, length: float, width: float, now: float) -> void:
	var pitch := EmpireFxData.FURNACE_FLAME_PITCH  # Slot gap (px).
	var first := ceilf(start / pitch) * pitch - start  # First world-aligned slot (strip px).
	var u := first
	var f0 := int(now * EmpireFxData.FURNACE_FLAME_FPS)  # Flicker frame.
	while u < length:
		var slot := int(round((start + u) / pitch))  # World slot index (stable).
		var v := width * (0.3 if posmod(slot, 2) == 0 else 0.7)  # Across (strip px).
		var foot := xf * Vector2(u, v)  # Its base (node px).
		frame(ci, EmpireFxData.FURNACE_FLAME, EmpireFxData.FURNACE_FLAME_FRAMES, f0 + slot * 3, foot + Vector2(0.0, -6.0))
		u += pitch


# =====================================================================================
# The Scrap Wastes: storm veil, the fallen pylon
# =====================================================================================

## The scrap storm's dust veil round `p` (the code's draw_veil numbers: clear
## radius `clear`, far reach `far`, dust colour `dust`, strength `k` 0..1): the
## radial veil mask scaled so its clear hole lands on `clear`, tinted with the
## dust, and the grit tile drifting with the wind over the view `view`. One
## textured rect each instead of 12-20 wide arcs and 18-46 lines a frame.
## Drawn with the node's plain (linear) filtering: the veil is a smooth mask.
## False when the art is missing.
static func storm(ci: CanvasItem, p: Vector2, clear: float, far: float, dust: Color, k: float, view: Rect2, now: float) -> bool:
	var veil := CovenantFx.tex(EmpireFxData.STORM_VEIL)  # Veil mask.
	if veil == null:
		return false
	var half := maxf(clear / EmpireFxData.STORM_HOLE, far)  # Veil half-size (px).
	ci.draw_texture_rect(veil, Rect2(p - Vector2(half, half), Vector2(half, half) * 2.0), false, Color(dust, k))
	var grit := CovenantFx.tex(EmpireFxData.STORM_GRIT, true)  # Grit tile.
	if grit != null:
		var drift := EmpireFxData.STORM_GRIT_SPEED * now  # Wind drift (px).
		var src := Rect2(view.position - drift, view.size)  # World-anchored, drifting.
		ci.draw_texture_rect_region(grit, view, src, Color(dust.lightened(0.25), EmpireFxData.STORM_GRIT_ALPHA * k))
	return true


## A fallen pylon's toppled mast at `c` (its dead zone's centre). False when missing.
static func pylon_stump(ci: CanvasItem, c: Vector2) -> bool:
	return CovenantFx.still(ci, EmpireFxData.PYLON_STUMP, c)


# =====================================================================================
# Kits: Juggernaut flame, Arc Engineer field, mortar shells, Lock-On
# =====================================================================================

## The Juggernaut's flame stream along `dir` (unit) from the node origin: the
## cone of `reach` px and `half` rad (the code's draw_flame arguments) filled
## with flame billows growing toward the reach, each jittered inside the cone by
## the code's own flicker hash, `now` the game time. False when missing.
static func jug_flame(ci: CanvasItem, dir: Vector2, reach: float, half: float, now: float) -> bool:
	if not has(EmpireFxData.JUG_FLAMES[0]):
		return false
	var flick := int(floorf(now / AssemblyGlyphs.FLICKER))  # The code's flicker frame.
	var n := maxi(4, int(round(float(EmpireFxData.JUG_BILLOWS) * AoeArt.density())))  # Billows.
	var f := int(now * EmpireFxData.JUG_FPS)  # Billow frame.
	for i in n:
		var h := absi(hash(Vector2i(i, flick)))  # The code's hash: same jitter.
		var t := 0.22 + 0.78 * float(i) / float(maxi(1, n - 1))  # Along the stream (0..1).
		var off := (float(h % 100) / 100.0 - 0.5) * 2.0 * half * t * 0.8  # Inside the cone.
		var q := dir.rotated(off) * reach * t * 0.94  # Billow centre (px).
		var size_i := 0 if t < 0.45 else (1 if t < 0.75 else 2)  # Bigger toward the reach.
		frame(ci, EmpireFxData.JUG_FLAMES[size_i], EmpireFxData.JUG_FRAMES, f + i, q, 0.0, 1.0, Color(1.0, 1.0, 1.0, 0.92))
	return true


## The Arc Engineer's static field arming at `at` (radius `r`, `k` 0..1 as it
## arms): a faint amber tint, the hex grid, the crackling red rim on the exact
## edge brightening with k, and eight sparks closing in. False when missing.
static func jam_field(ci: CanvasItem, at: Vector2, r: float, k: float) -> bool:
	if not has(EmpireFxData.STATIC_EDGE):
		return false
	k = clampf(k, 0.0, 1.0)
	CovenantFx.soft_disc(ci, at, r, Color(AMBER, 0.06 + 0.1 * k))
	CovenantFx.hatch_disc(ci, at, r, Color(1.0, 1.0, 1.0, 0.12 + 0.25 * k), EmpireFxData.HEX)
	CovenantFx.ring(ci, at, r, EmpireFxData.STATIC_EDGE, Color(1.0, 1.0, 1.0, 0.55 + 0.4 * k), 1.0, 0.0, TAU, k * 3.0)
	for i in 8:
		var a := TAU * float(i) / 8.0 + k * 2.0  # The code's spark angles.
		frame(ci, EmpireFxData.SPARK, 2, i + int(k * 12.0), at + Vector2.from_angle(a) * r * (1.0 - 0.4 * k))
	return true


## The Arc Engineer's armed static field at `at` (radius `r`, the suppression
## zone's exact radius), `life` 1 -> 0 as it runs out: a faint amber tint, the
## hex grid, the crackling red rim turning on the exact edge and eight sparks
## circling inside it, all fading with life. False when the art is missing.
static func static_field(ci: CanvasItem, at: Vector2, r: float, life: float, now: float) -> bool:
	if not has(EmpireFxData.STATIC_EDGE):
		return false
	var a := clampf(life * 4.0, 0.0, 1.0)  # Fade over its last quarter.
	CovenantFx.soft_disc(ci, at, r, Color(AMBER, 0.12 * a))
	CovenantFx.hatch_disc(ci, at, r, Color(1.0, 1.0, 1.0, 0.3 * a), EmpireFxData.HEX)
	CovenantFx.ring(ci, at, r, EmpireFxData.STATIC_EDGE, Color(1.0, 1.0, 1.0, 0.95 * a), 1.0, 0.0, TAU, now * 1.2)
	for i in 8:
		var ang := TAU * float(i) / 8.0 - now * 0.9  # Circling sparks.
		frame(ci, EmpireFxData.SPARK, 2, i + int(now * 10.0), at + Vector2.from_angle(ang) * r * 0.72, 0.0, 1.0, Color(1.0, 1.0, 1.0, a))
	return true


## A mortar shell in flight at `at` (already lifted by the code's arc height),
## turning by `now`. False when the art is missing.
static func mortar_shell(ci: CanvasItem, at: Vector2, now: float, index: int) -> bool:
	return frame(ci, EmpireFxData.MORTAR_SHELL, 2, int(now * EmpireFxData.MORTAR_SPIN) + index, at)


## A Lock-On reticle on the painted target at `at`: the painting reticle scaled
## to the code's radius `r` (12 -> 9 px), or the locked one, blinking white-hot
## (`blink`). False when the art is missing.
static func lock_reticle(ci: CanvasItem, at: Vector2, r: float, locked: bool, blink: bool) -> bool:
	if locked:
		return frame(ci, EmpireFxData.LOCK_LOCKED, 2, 1 if blink else 0, at)
	return frame(ci, EmpireFxData.LOCK_OPEN, 2, 0, at, 0.0, r / EmpireFxData.LOCK_OPEN_R)


# =====================================================================================
# Deus Ex Machina, the Motherboard
# =====================================================================================

## A footfall shock ring at radius `r` round `c`, fading with `fade` (1 -> 0).
## False when the art is missing.
static func shock(ci: CanvasItem, c: Vector2, r: float, fade: float) -> bool:
	return CovenantFx.ring(ci, c, r, EmpireFxData.SHOCK_EDGE, Color(1.0, 1.0, 1.0, 0.85 * fade), 2.0)


## The overload charge round the hull at `c` (radius `r`), `k` (0..1) rising:
## a red glow and the charge ring closing in. False when missing.
static func pulse_charge(ci: CanvasItem, c: Vector2, r: float, k: float, now: float) -> bool:
	if not has(EmpireFxData.PULSE_CHARGE):
		return false
	var flick := 0.7 + 0.3 * sin(now * 30.0)  # The code's flicker.
	CovenantFx.soft_disc(ci, c, r * (1.0 + 0.6 * k), Color(RED, 0.14 * k * flick))
	CovenantFx.ring(ci, c, r * (1.6 - 0.5 * k), EmpireFxData.PULSE_CHARGE, Color(1.0, 1.0, 1.0, 0.75 * k), 1.5, 0.0, TAU, now * 2.0)
	return true


## A rolling overload pulse front at radius `r` round `c` (`front` px thick,
## the piece's middle row on r), fading as `fade` (1 -> 0) drops. False when missing.
static func pulse_front(ci: CanvasItem, c: Vector2, r: float, fade: float, cull: Rect2 = Rect2()) -> bool:
	if not has(EmpireFxData.PULSE_FRONT):
		return false
	if r <= 1.0:
		return true
	return CovenantFx.ring(ci, c, r, EmpireFxData.PULSE_FRONT, Color(1.0, 1.0, 1.0, minf(1.0, 0.95 * fade + 0.05)), EmpireFxData.PULSE_FRONT_ROW,
		0.0, TAU, 0.0, "", 0, cull)


## A hangar door at `at`, opening as `k` (0..1) rises. False when missing.
static func hangar(ci: CanvasItem, at: Vector2, k: float) -> bool:
	return frame(ci, EmpireFxData.HANGAR_DOOR, 3, mini(2, int(k * 3.0)), at)


## A teleport's destination at `at` (`r` the hull radius, `k` 0..1): a red glow
## and three scan arcs turning round it. False when missing.
static func teleport_glow(ci: CanvasItem, at: Vector2, r: float, k: float, now: float) -> bool:
	if not has(EmpireFxData.FRONT):
		return false
	CovenantFx.soft_disc(ci, at, r * (0.4 + 0.8 * k), Color(RED, 0.15 + 0.2 * k))
	for i in 3:
		var a := now * 3.0 + TAU * float(i) / 3.0  # The code's arc angles.
		CovenantFx.ring(ci, at, r * 1.2, EmpireFxData.FRONT, Color(1.0, 1.0, 1.0, 0.85 * k), EmpireFxData.FRONT_ROW, a, a + 1.0)
	return true


## The finale's soul binding round `c`: three soul-green chains closing on the
## broken engine as `k` (0..1) runs (the code's radii and turns). False when missing.
static func soul_binding(ci: CanvasItem, c: Vector2, big: float, k: float, now: float) -> bool:
	if not has(EmpireFxData.BINDING_EDGE):
		return false
	var fade := 1.0 - k
	for i in 3:
		var r := big * (1.0 - k * 0.6) * (1.0 - 0.25 * float(i))  # This chain's radius.
		var a0 := now * (1.0 + float(i))  # Its turn.
		CovenantFx.ring(ci, c, r, EmpireFxData.BINDING_EDGE, Color(1.0, 1.0, 1.0, 0.85 * fade), 2.5, a0, a0 + TAU * 0.8)
	CovenantFx.soft_disc(ci, c, 14.0 + 10.0 * k, Color(Palette.NECRO_GREEN, 0.3 * fade))
	return true


## The Motherboard's magnet coils round `o` (radius `r`, `k` 0..1 the phase):
## three rings of coil pieces running inward. False when missing.
static func magnet(ci: CanvasItem, o: Vector2, r: float, k: float, pulling: bool) -> bool:
	if not has(EmpireFxData.MAGNET_EDGE):
		return false
	var tint := Color(1.0, 1.0, 1.0) if not pulling else Color(1.3, 1.15, 0.6)  # Amber while it pulls.
	for i in 3:
		var t := fposmod(1.0 - k + float(i) / 3.0, 1.0)  # The code's ring phase.
		CovenantFx.ring(ci, o, r * (0.2 + 0.8 * t), EmpireFxData.MAGNET_EDGE, Color(tint, 0.65 * (1.0 - t) + 0.15), 1.0, 0.0, TAU, k * 2.0)
	return true


## A crane claw at `p` (its cable joins the art's top centre), open or clamped.
## False when the art is missing.
static func claw(ci: CanvasItem, p: Vector2, open: bool) -> bool:
	return frame(ci, EmpireFxData.CLAW, 2, 0 if open else 1, p + Vector2(0.0, 5.0))
