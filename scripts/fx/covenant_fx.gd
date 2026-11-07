## CovenantFx: draws the pixel art of the Covenant's area effects (GDD §15.0
## "Act I enemy AoE art"; keys and numbers in CovenantFxData, the art made by
## tools/covenant_aoe_art.py). The art stays crisp at any gameplay size
## because nothing big is stretched:
##   * band pieces are TILED at 1:1 along a shape's exact edge (ring(),
##     edge_run(): a circle, a lane's sides and ends, a cone's two sides and
##     arc), each piece turned along the edge, row 0 on the outside;
##   * a seamless hatch tile FILLS a circle or cone as horizontal 2 px rows
##     clipped to the shape (hatch_disc(), hatch_sector()) and a lane as one
##     turned rect: textured rects only, which batch, instead of the per-redraw
##     polygons the code shapes cost on the Web (CLAUDE.md, GDD §15.0 "Web GL id
##     leak patch");
##   * discs are BAKED at the radii the game uses and drawn scaled to the
##     radius asked (disc(): x1 at the shipped radii);
##   * small stills are placed upright on whole px or turned (orbit(), still()).
## Everything goes through the sharp-pixel shader (SpriteBank.apply_sharp()).
## Every function returns false and draws nothing when its art is missing, so
## each drawing site keeps its code shape as the fallback. The shared
## telegraphs (telegraph_circle(), telegraph_line(), telegraph_cone()) are the
## ONE asset set every boss and elite warning uses, in every act (Effect).
## Purely visual: it reads positions and timers, never changes them, and uses
## no randomness, so runs stay deterministic per seed.
class_name CovenantFx
extends RefCounted

## Transform every CovenantFx drawing is composed with (identity by default).
## A unit drawn mirrored for facing (CovenantKit.unmirror()) sets it to its
## un-mirroring scale while it draws world-axis art and resets it right after,
## because draw_set_transform() replaces the canvas transform, never composes.
static var base: Transform2D = Transform2D.IDENTITY

## key (+ "@r" when repeating) -> Texture2D: a linear-filtered CanvasTexture
## around the PNG (for the sharp-pixel shader; set to repeat for tiles), or
## null when the PNG is missing.
static var _cache: Dictionary = {}


## The texture of art `key` (assets/sprites/<key>.png), wrapped for the
## sharp-pixel shader; `repeat` makes it tile when a source rect runs past it.
## Null when the PNG is missing (recorded by --art-misses).
static func tex(key: String, repeat: bool = false) -> Texture2D:
	var ck := key + ("@r" if repeat else "")  # Cache key.
	if _cache.has(ck):
		if ArtMissLog.on and _cache[ck] == null:
			ArtMissLog.miss(key)
		return _cache[ck]
	var path := SpriteData.ROOT + key + ".png"  # Expected file.
	var t: Texture2D = null  # Wrapped texture, or null.
	if ResourceLoader.exists(path):
		var raw := load(path) as Texture2D  # The imported PNG.
		if raw != null:
			var ct := CanvasTexture.new()  # Per-draw filter / repeat override.
			ct.diffuse_texture = raw
			ct.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # The sharp-pixel shader needs linear samples.
			ct.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if repeat else CanvasItem.TEXTURE_REPEAT_DISABLED
			t = ct
	_cache[ck] = t
	if ArtMissLog.on:
		if t == null:
			ArtMissLog.miss(key)
		else:
			ArtMissLog.hit(key)
	return t


## True when the art of `key` exists.
static func has(key: String) -> bool:
	return tex(key) != null


## Sets `ci`'s drawing transform to `base` x (turn `rot` rad, then move to `pos`).
static func _xf(ci: CanvasItem, pos: Vector2, rot: float) -> void:
	ci.draw_set_transform_matrix(base * Transform2D(rot, pos))


## Sets `ci`'s drawing transform back to `base`.
static func _reset(ci: CanvasItem) -> void:
	ci.draw_set_transform_matrix(base)


## Draws a filled translucent disc of radius `r` (px) at `c`: the look of
## draw_circle() without its per-redraw polygon. It uses the 512 px soft disc
## mask CovenantFxData.SOFT_DISC rather than SpriteBank.disc() (64 px): the
## nodes that draw this art carry the sharp-pixel shader, which draws a
## magnified texture as crisp texels, so a 640 px nova glow from the small
## shared disc would show 10 px stair steps. Small discs (radius under
## CovenantFxData.SOFT_DISC_MIN_R, where the big mask would be minified without
## mipmaps) and a missing mask use SpriteBank.draw_disc().
static func soft_disc(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var t := tex(CovenantFxData.SOFT_DISC)  # Soft disc mask, or null.
	if t == null or r < CovenantFxData.SOFT_DISC_MIN_R:
		SpriteBank.draw_disc(ci, c, r, color)
		return
	ci.draw_texture_rect(t, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, color)


## The key in `discs` (baked radius -> key) whose radius is nearest `r` (px);
## "" when `discs` is empty.
static func disc_key(discs: Dictionary, r: float) -> String:
	var best := ""  # Nearest key so far.
	var best_d := INF  # Its radius difference (px).
	for br: int in discs:
		var d := absf(float(br) - r)
		if d < best_d:
			best_d = d
			best = String(discs[br])
	return best


## Draws the baked disc of `discs` nearest radius `r` centred on `c`, scaled
## so its baked radius lands on `r` (x1 at a shipped radius), multiplied by
## `modulate`. False (nothing drawn) when its art is missing.
static func disc(ci: CanvasItem, c: Vector2, r: float, discs: Dictionary, modulate: Color = Color.WHITE) -> bool:
	var key := disc_key(discs, r)  # Baked disc to use.
	var t := tex(key) if key != "" else null  # Its art.
	if t == null:
		return false
	var baked := 0.0  # Its baked radius (px).
	for br: int in discs:
		if String(discs[br]) == key:
			baked = float(br)
	var s := r / maxf(1.0, baked)  # Scale to the radius asked.
	var size := Vector2(float(t.get_width()), float(t.get_height())) * s  # Drawn size (px).
	var tl := c - size * 0.5  # Corner (px).
	if absf(s - 1.0) < 0.001:
		tl = tl.round()  # 1:1: on whole px.
	SpriteBank.apply_sharp(ci)
	_reset(ci)
	ci.draw_texture_rect(t, Rect2(tl, size), false, modulate)
	return true


## Draws still `key` centred on `c`: upright on whole px when `angle` is 0,
## else turned by `angle` (rad; the art points +x); `scale` enlarges it.
## False when its art is missing.
static func still(ci: CanvasItem, key: String, c: Vector2, modulate: Color = Color.WHITE, angle: float = 0.0, scale: float = 1.0) -> bool:
	var t := tex(key)  # Its art.
	if t == null:
		return false
	SpriteBank.apply_sharp(ci)
	var size := Vector2(float(t.get_width()), float(t.get_height())) * scale  # Drawn size (px).
	if angle == 0.0:
		_reset(ci)
		ci.draw_texture_rect(t, Rect2((c - size * 0.5).round() if scale == 1.0 else c - size * 0.5, size), false, modulate)
		return true
	_xf(ci, c, angle)
	ci.draw_texture_rect(t, Rect2(-size * 0.5, size), false, modulate)
	_reset(ci)
	return true


## Places `n` copies of still `key` evenly round the circle (c, r), the
## first at angle `rot` (rad): upright (glints, runes, crosses), or, with
## `turn`, each turned to point outward (rays). False when the art is missing.
static func orbit(ci: CanvasItem, c: Vector2, r: float, key: String, n: int, rot: float, modulate: Color = Color.WHITE, turn: bool = false) -> bool:
	if not has(key):
		return false
	for i in n:
		var a := rot + TAU * float(i) / float(maxi(1, n))  # This copy's angle (rad).
		still(ci, key, c + Vector2.from_angle(a) * r, modulate, a if turn else 0.0)
	return true


## Tiles band piece `key` along the arc of circle (c, r) from angle `a0` to
## `a1` (rad, increasing), each piece turned along the arc with its row `row`
## (art px from its outer row) on the circle and row 0 outside. The pieces are
## stretched by at most half a piece so a whole number fills the arc. With
## `alt_key`, every `alt_every`-th piece is that one instead (the toothed band).
## `phase` (rad) slides the pieces round (turning rings). With a non-empty
## `cull` rect (node space), pieces outside it are skipped (the huge rings of
## Seraphine's nova and collapsing arena). False when missing.
static func ring(ci: CanvasItem, c: Vector2, r: float, key: String, modulate: Color = Color.WHITE, row: float = 0.0,
		a0: float = 0.0, a1: float = TAU, phase: float = 0.0, alt_key: String = "", alt_every: int = 0, cull: Rect2 = Rect2()) -> bool:
	var t := tex(key, true)  # Band piece (repeat: seamless joins).
	if t == null:
		return false
	if r < 2.0 or a1 <= a0:
		return true
	var alt := tex(alt_key, true) if alt_key != "" else null  # Toothed piece, or null.
	SpriteBank.apply_sharp(ci)
	var w := float(t.get_width())  # Piece length (art px).
	var n := maxi(1, int(round((a1 - a0) * r / w)))  # Pieces on the arc.
	var step := (a1 - a0) / float(n)  # Angle per piece (rad).
	# Drawn piece length (px): its share of the arc, widened so the straight
	# pieces still meet at their outer row (no hairline gaps outside the curve).
	var pw := step * (r + row) + 0.6
	var culling := cull.size != Vector2.ZERO  # Skip pieces off the view.
	for i in n:
		var a := a0 + step * (float(i) + 0.5) + phase  # Piece centre angle (rad).
		var at := c + Vector2.from_angle(a) * r  # Piece centre (px).
		if culling and not cull.has_point(at):
			continue
		var piece := alt if (alt != null and alt_every > 0 and i % alt_every == 0) else t  # This piece's art.
		_xf(ci, at, a + PI * 0.5)
		ci.draw_texture_rect(piece, Rect2(-pw * 0.5, -row, pw, float(piece.get_height())), false, modulate)
	_reset(ci)
	return true


## Tiles band piece `key` along the segment `a` -> `b` (row `row` on it, row 0
## on the left of the walk, i.e. outside when a shape's edge is walked
## clockwise on screen), like ring(). False when the art is missing.
static func edge_run(ci: CanvasItem, a: Vector2, b: Vector2, key: String, modulate: Color = Color.WHITE, row: float = 0.0,
		alt_key: String = "", alt_every: int = 0) -> bool:
	var t := tex(key, true)  # Band piece.
	if t == null:
		return false
	var d := b - a  # Walk (px).
	var ln := d.length()  # Its length (px).
	if ln < 1.0:
		return true
	var alt := tex(alt_key, true) if alt_key != "" else null  # Toothed piece, or null.
	SpriteBank.apply_sharp(ci)
	var w := float(t.get_width())  # Piece length (art px).
	var n := maxi(1, int(round(ln / w)))  # Pieces on the segment.
	var pw := ln / float(n)  # Drawn piece length (px).
	var dir := d / ln  # Unit walk direction.
	var ang := d.angle()  # Walk angle (rad).
	for i in n:
		var piece := alt if (alt != null and alt_every > 0 and i % alt_every == 1) else t  # This piece's art.
		_xf(ci, a + dir * pw * (float(i) + 0.5), ang)
		ci.draw_texture_rect(piece, Rect2(-pw * 0.5, -row, pw, float(piece.get_height())), false, modulate)
	_reset(ci)
	return true


## Fills the circle (c, r) with the warning hatch as 2 px rows clipped to the
## circle (the pattern anchored to the node's own space). `key` picks another
## seamless fill tile (the Empire's hex grid, EmpireFx). False when missing.
static func hatch_disc(ci: CanvasItem, c: Vector2, r: float, modulate: Color, key: String = CovenantFxData.T_HATCH) -> bool:
	var t := tex(key, true)  # Seamless hatch tile.
	if t == null:
		return false
	SpriteBank.apply_sharp(ci)
	_reset(ci)
	var hr := CovenantFxData.T_HATCH_ROW  # Row height (px).
	var y := -r  # Row top relative to the centre (px).
	while y < r:
		var ym := y + hr * 0.5  # Row middle.
		var hw := sqrt(maxf(0.0, r * r - ym * ym))  # Half chord (px).
		if hw >= 0.5:
			var rect := Rect2(c.x - hw, c.y + y, hw * 2.0, hr)  # Row strip (px).
			ci.draw_texture_rect_region(t, rect, rect, modulate)
		y += hr
	return true


## Fills the sector at `c` (radius `r`, facing angle `face`, `half` rad each
## side) with the warning hatch as 2 px rows clipped to it: each half of the
## sector (at most 180 degrees, so convex) cuts every row to one interval.
## `key` picks another seamless fill tile. False when the art is missing.
static func hatch_sector(ci: CanvasItem, c: Vector2, r: float, face: float, half: float, modulate: Color, key: String = CovenantFxData.T_HATCH) -> bool:
	var t := tex(key, true)  # Seamless hatch tile.
	if t == null:
		return false
	SpriteBank.apply_sharp(ci)
	_reset(ci)
	_sector_rows(ci, t, c, r, face - half, half, modulate)
	_sector_rows(ci, t, c, r, face, half, modulate)
	return true


## One convex part of hatch_sector(): the sector from angle `a0` spanning
## `span` rad (<= PI) of radius `r` at `c`, as clipped hatch rows.
static func _sector_rows(ci: CanvasItem, t: Texture2D, c: Vector2, r: float, a0: float, span: float, modulate: Color) -> void:
	var d0 := Vector2.from_angle(a0)  # First side.
	var d1 := Vector2.from_angle(a0 + span)  # Second side.
	var ymin := minf(0.0, minf(d0.y, d1.y) * r)  # Row range (px, relative to c).
	var ymax := maxf(0.0, maxf(d0.y, d1.y) * r)
	if fposmod(PI * 0.5 - a0, TAU) <= span:
		ymax = r  # The arc passes straight down.
	if fposmod(-PI * 0.5 - a0, TAU) <= span:
		ymin = -r  # The arc passes straight up.
	var hr := CovenantFxData.T_HATCH_ROW  # Row height (px).
	var y := floorf(ymin / hr) * hr  # Row top (px), on the row grid.
	while y < ymax:
		var ym := y + hr * 0.5  # Row middle.
		var hw := sqrt(maxf(0.0, r * r - ym * ym))  # Circle half chord.
		var lo := -hw  # Interval of x on this row (px, relative to c).
		var hi := hw
		# Inside the first side: cross(d0, p) >= 0, i.e. -d0.y * x + d0.x * ym >= 0.
		var lim := _clip(-d0.y, d0.x * ym, lo, hi)
		# Inside the second side: cross(p, d1) >= 0, i.e. d1.y * x - d1.x * ym >= 0.
		lim = _clip(d1.y, -d1.x * ym, lim.x, lim.y)
		if lim.y - lim.x >= 0.5:
			var rect := Rect2(c.x + lim.x, c.y + y, lim.y - lim.x, hr)  # Row strip (px).
			ci.draw_texture_rect_region(t, rect, rect, modulate)
		y += hr


## Clips the interval [lo, hi] to a * x + b >= 0 (returns (lo, hi); empty when
## lo >= hi).
static func _clip(a: float, b: float, lo: float, hi: float) -> Vector2:
	if a > 0.000001:
		return Vector2(maxf(lo, -b / a), hi)
	if a < -0.000001:
		return Vector2(lo, minf(hi, -b / a))
	return Vector2(lo, hi) if b >= 0.0 else Vector2(0.0, 0.0)


## Draws a stretch of a scrolling ray piece `key` from `a` to `b`, `height`
## px thick (the piece scaled to it, its texels kept square), its pattern
## slid `scroll` px along the ray. False when the art is missing.
static func ray_strip(ci: CanvasItem, a: Vector2, b: Vector2, key: String, height: float, scroll: float, modulate: Color = Color.WHITE) -> bool:
	var t := tex(key, true)  # Repeating ray piece.
	if t == null:
		return false
	var d := b - a  # Ray (px).
	var ln := d.length()
	if ln < 1.0:
		return true
	SpriteBank.apply_sharp(ci)
	var th := float(t.get_height())  # Piece height (art px).
	var k := th / maxf(1.0, height)  # Texels per drawn px.
	_xf(ci, a, d.angle())
	ci.draw_texture_rect_region(t, Rect2(0.0, -height * 0.5, ln, height), Rect2(-scroll * k, 0.0, ln * k, th), modulate)
	_reset(ci)
	return true


# =====================================================================================
# The shared telegraphs (Effect.Kind.TELEGRAPH_CIRCLE / LINE / CONE)
# =====================================================================================

## Warning circle at `c`, radius `r`, timing `k` (0..1): a faint tint, the
## hatch over the whole danger area and denser inside radius r x k, the
## serrated band on the exact edge, the timing front at r x k and the impact
## point. `color` tints the soft base (the art is the Covenant's gold).
## False (nothing drawn) when the art is missing.
static func telegraph_circle(ci: CanvasItem, c: Vector2, r: float, k: float, color: Color) -> bool:
	if not has(CovenantFxData.T_EDGE) or not has(CovenantFxData.T_HATCH) or not has(CovenantFxData.T_FRONT):
		return false
	k = clampf(k, 0.0, 1.0)
	_reset(ci)
	CovenantFx.soft_disc(ci, c, r, Color(color, CovenantFxData.T_BASE_ALPHA))
	hatch_disc(ci, c, r, Color(1.0, 1.0, 1.0, CovenantFxData.T_HATCH_ALPHA))
	if k > 0.02:
		CovenantFx.soft_disc(ci, c, r * k, Color(color, CovenantFxData.T_FILL_TINT))
		hatch_disc(ci, c, r * k, Color(1.0, 1.0, 1.0, CovenantFxData.T_FILL_ALPHA))
		ring(ci, c, r * k, CovenantFxData.T_FRONT, Color(1.0, 1.0, 1.0, CovenantFxData.T_FRONT_ALPHA), 1.5)
	if r >= CovenantFxData.T_TARGET_MIN_RADIUS:
		still(ci, CovenantFxData.T_TARGET, c, Color(1.0, 1.0, 1.0, CovenantFxData.T_TARGET_ALPHA))
	ring(ci, c, r, CovenantFxData.T_EDGE, Color(1.0, 1.0, 1.0, CovenantFxData.T_EDGE_ALPHA), CovenantFxData.T_EDGE_ROW,
		0.0, TAU, 0.0, CovenantFxData.T_EDGE_TOOTH, CovenantFxData.T_TOOTH_EVERY)
	return true


## Warning lane from the node origin to `vec`, `width` px wide, timing `k`
## (0..1): the tint and hatch over the lane, denser over its first k, the
## direction chevrons (lit once the timing passes them), the band round its
## four sides and the timing front across it. False when the art is missing.
static func telegraph_line(ci: CanvasItem, vec: Vector2, width: float, k: float, color: Color) -> bool:
	var hatch := tex(CovenantFxData.T_HATCH, true)  # Seamless hatch tile.
	if hatch == null or not has(CovenantFxData.T_EDGE) or not has(CovenantFxData.T_FRONT):
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
	ci.draw_rect(lane, Color(color, CovenantFxData.T_BASE_ALPHA))
	ci.draw_texture_rect_region(hatch, lane, lane, Color(1.0, 1.0, 1.0, CovenantFxData.T_HATCH_ALPHA))
	if k > 0.02:
		var filled := Rect2(0.0, -h, ln * k, width)  # The part the timing has filled.
		ci.draw_rect(filled, Color(color, CovenantFxData.T_FILL_TINT))
		ci.draw_texture_rect_region(hatch, filled, filled, Color(1.0, 1.0, 1.0, CovenantFxData.T_FILL_ALPHA))
	_reset(ci)
	var dir := vec / ln  # Unit lane direction.
	var x := CovenantFxData.T_CHEVRON_PITCH * 0.5  # Chevron position along the lane (px).
	if width >= 14.0:
		while x < ln - 6.0:
			var lit := x <= ln * k  # The timing has passed it.
			still(ci, CovenantFxData.T_CHEVRON, dir * x, Color(1.0, 1.0, 1.0,
				CovenantFxData.T_CHEVRON_ALPHA.y if lit else CovenantFxData.T_CHEVRON_ALPHA.x), ang)
			x += CovenantFxData.T_CHEVRON_PITCH
	var xf := Transform2D(ang, Vector2.ZERO)  # Lane frame -> node.
	if k > 0.02:
		edge_run(ci, xf * Vector2(ln * k, -h), xf * Vector2(ln * k, h), CovenantFxData.T_FRONT,
			Color(1.0, 1.0, 1.0, CovenantFxData.T_FRONT_ALPHA), 1.5)
	var em := Color(1.0, 1.0, 1.0, CovenantFxData.T_EDGE_ALPHA)  # Band modulate.
	var row := CovenantFxData.T_EDGE_ROW
	# The four sides walked clockwise on screen: the band's outer row outside.
	edge_run(ci, xf * Vector2(0.0, -h), xf * Vector2(ln, -h), CovenantFxData.T_EDGE, em, row, CovenantFxData.T_EDGE_TOOTH, CovenantFxData.T_TOOTH_EVERY)
	edge_run(ci, xf * Vector2(ln, -h), xf * Vector2(ln, h), CovenantFxData.T_EDGE, em, row)
	edge_run(ci, xf * Vector2(ln, h), xf * Vector2(0.0, h), CovenantFxData.T_EDGE, em, row, CovenantFxData.T_EDGE_TOOTH, CovenantFxData.T_TOOTH_EVERY)
	edge_run(ci, xf * Vector2(0.0, h), xf * Vector2(0.0, -h), CovenantFxData.T_EDGE, em, row)
	return true


## Warning cone at `c`, radius `r`, facing `dir`, `half` rad each side, timing
## `k` (0..1): the hatch over the sector (no flat tint: a sector of the shared
## disc would need a polygon) and denser inside r x k, the band along both
## sides and the arc, the timing front on the arc at r x k. `color` is unused
## (the art is the Covenant's gold), kept for the call's symmetry. False when
## the art is missing.
static func telegraph_cone(ci: CanvasItem, c: Vector2, r: float, dir: Vector2, half: float, k: float, color: Color) -> bool:
	if not has(CovenantFxData.T_EDGE) or not has(CovenantFxData.T_HATCH) or not has(CovenantFxData.T_FRONT):
		return false
	k = clampf(k, 0.0, 1.0)
	var face := dir.angle()  # Facing (rad).
	hatch_sector(ci, c, r, face, half, Color(1.0, 1.0, 1.0, CovenantFxData.T_HATCH_ALPHA))
	if k > 0.02:
		hatch_sector(ci, c, r * k, face, half, Color(1.0, 1.0, 1.0, CovenantFxData.T_FILL_ALPHA))
		ring(ci, c, r * k, CovenantFxData.T_FRONT, Color(1.0, 1.0, 1.0, CovenantFxData.T_FRONT_ALPHA), 1.5, face - half, face + half)
	var em := Color(1.0, 1.0, 1.0, CovenantFxData.T_EDGE_ALPHA)  # Band modulate.
	var row := CovenantFxData.T_EDGE_ROW
	var d0 := Vector2.from_angle(face - half)  # First side.
	var d1 := Vector2.from_angle(face + half)  # Second side.
	edge_run(ci, c, c + d0 * r, CovenantFxData.T_EDGE, em, row, CovenantFxData.T_EDGE_TOOTH, CovenantFxData.T_TOOTH_EVERY)
	ring(ci, c, r, CovenantFxData.T_EDGE, em, row, face - half, face + half, 0.0, CovenantFxData.T_EDGE_TOOTH, CovenantFxData.T_TOOTH_EVERY)
	edge_run(ci, c + d1 * r, c, CovenantFxData.T_EDGE, em, row, CovenantFxData.T_EDGE_TOOTH, CovenantFxData.T_TOOTH_EVERY)
	return true


# =====================================================================================
# Beams, columns, flames
# =====================================================================================

## A great holy beam from `a` to `b`, `width` px wide (Seraphine's beams, the
## Cathedral Guardian's beam): a soft glow under it, the scrolling core
## pieces and the blazing head at `b`. `flick` (0..1) scales the glow.
## False when the art is missing.
static func great_beam(ci: CanvasItem, a: Vector2, b: Vector2, width: float, scroll: float, flick: float = 1.0) -> bool:
	if not has(CovenantFxData.BEAM_CORE) or not has(CovenantFxData.BEAM_CAP):
		return false
	if (b - a).length() < 1.0:
		return true
	ray_strip(ci, a, b, CovenantFxData.BEAM_GLOW, width * 2.0, 0.0, Color(1.0, 1.0, 1.0, CovenantFxData.BEAM_GLOW_ALPHA * flick))
	ray_strip(ci, a, b, CovenantFxData.BEAM_CORE, width, scroll)
	var cap := float(tex(CovenantFxData.BEAM_CAP).get_height())  # Head art size (px).
	still(ci, CovenantFxData.BEAM_CAP, b, Color(1.0, 1.0, 1.0, 0.85 + 0.15 * flick), 0.0, maxf(0.5, width * 1.3 / cap))
	still(ci, CovenantFxData.BEAM_CAP, a, Color(1.0, 1.0, 1.0, 0.8), 0.0, maxf(0.5, width * 0.9 / cap))
	return true


## A column of light standing on `foot`, `half_w` px half-wide and `height`
## px tall (the column art stretched to it). False when the art is missing.
static func light_column(ci: CanvasItem, foot: Vector2, half_w: float, height: float, modulate: Color = Color.WHITE) -> bool:
	var t := tex(CovenantFxData.LIGHT_COLUMN)  # Column art.
	if t == null:
		return false
	SpriteBank.apply_sharp(ci)
	_reset(ci)
	ci.draw_texture_rect(t, Rect2(foot.x - half_w, foot.y - height, half_w * 2.0, height), false, modulate)
	return true


## One flame tongue of the strip CovenantFxData.COLLAPSE_FLAME standing on
## `foot`, licking toward angle `toward` (rad), frame by `clock` (s) and its
## own `offset` (frames). False when the art is missing.
static func flame_tongue(ci: CanvasItem, foot: Vector2, toward: float, clock: float, offset: int, modulate: Color = Color.WHITE) -> bool:
	var t := tex(CovenantFxData.COLLAPSE_FLAME)  # Flame strip.
	if t == null:
		return false
	var nf := CovenantFxData.COLLAPSE_FLAME_FRAMES  # Frames.
	var fw := float(t.get_width()) / float(nf)  # Frame width (px).
	var fh := float(t.get_height())  # Frame height (px).
	var f := (int(clock * CovenantFxData.COLLAPSE_FLAME_FPS) + offset) % nf  # This tongue's frame.
	SpriteBank.apply_sharp(ci)
	_xf(ci, foot, toward + PI * 0.5)
	ci.draw_texture_rect_region(t, Rect2(-fw * 0.5, -fh, fw, fh), Rect2(fw * float(f), 0.0, fw, fh), modulate)
	_reset(ci)
	return true
