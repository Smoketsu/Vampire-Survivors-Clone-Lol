## PantheonFx: draws the pixel art of the Olympian Republic's effects (GDD §15.0
## "Missing art round wired"; keys and numbers in PantheonFxData, the wiring
## plan in docs/art/missing_art_round/WIRING.md): Divine Wrath's wave, bolt
## and fissure telegraphs and hazards, the lightning arcs (Divine Wrath's
## chains and Stolen Thunder), River Styx / Lethe's Flood. It builds on
## CovenantFx (band pieces tiled at 1:1 along the exact hit edge, a seamless
## fill laid as clipped rows, repeating strips along a line). The art fills
## exactly the shape and size the code drawing used; it never has a hit area of
## its own. Every function returns false and draws nothing when its art is
## missing, so each drawing site keeps its code shape as the fallback.
## Textured rects only (they batch): no per-frame polygons (CLAUDE.md, GDD
## §15.0 "Web GL id leak patch"). Purely visual: it reads positions and timers,
## never changes them, and uses no randomness.
class_name PantheonFx
extends RefCounted


## Sets `ci`'s drawing transform to CovenantFx.base x (turn `rot`, then move to `pos`).
static func _xf(ci: CanvasItem, pos: Vector2, rot: float) -> void:
	ci.draw_set_transform_matrix(CovenantFx.base * Transform2D(rot, pos))


## Sets `ci`'s drawing transform back to CovenantFx.base.
static func _reset(ci: CanvasItem) -> void:
	ci.draw_set_transform_matrix(CovenantFx.base)


## A wave's telegraph: the warning band along its starting line (centre
## `line_c`, `half` px each side along the wall, the danger on the `dir` side)
## and the chevrons every `step` px, pushed `14 + 30 k` px ahead by the timing
## `k` (0..1); `blink` (0..1) pulses the band. False when the art is missing.
static func wave_warn(ci: CanvasItem, line_c: Vector2, dir: Vector2, half: float, k: float, blink: float, step: float) -> bool:
	if not CovenantFx.has(PantheonFxData.EDGE) or not CovenantFx.has(PantheonFxData.CHEVRON):
		return false
	var perp := Vector2(-dir.y, dir.x)  # Along the wall.
	# Walked toward -perp so the band's outer row faces away from the danger.
	CovenantFx.edge_run(ci, line_c + perp * half, line_c - perp * half, PantheonFxData.EDGE,
		Color(1.0, 1.0, 1.0, PantheonFxData.EDGE_ALPHA * (0.55 + 0.45 * blink)), PantheonFxData.EDGE_ROW,
		PantheonFxData.EDGE_TICK, PantheonFxData.TICK_EVERY)
	var s := -half  # Chevron position along the wall (px).
	while s <= half:
		CovenantFx.still(ci, PantheonFxData.CHEVRON, line_c + perp * s + dir * (14.0 + 30.0 * k),
			Color(1.0, 1.0, 1.0, PantheonFxData.CHEVRON_ALPHA), dir.angle() + PI)  # The art points -x.
		s += step
	return true


## A rolling wave from origin `o` along `dir`: the water from `back` to the
## front `f` (px along dir from o), `half` px each side, its pattern scrolled
## `scroll` px along dir, and the foam front on the front line. False when the
## art is missing.
static func wave(ci: CanvasItem, o: Vector2, dir: Vector2, half: float, back: float, f: float, scroll: float) -> bool:
	var front := CovenantFx.tex(PantheonFxData.WAVE_FRONT, true)  # Repeating front tile.
	var body := CovenantFx.tex(PantheonFxData.WAVE_BODY, true)  # Repeating water tile.
	if front == null or body == null:
		return false
	SpriteBank.apply_sharp(ci)
	# The wave's frame: +y along dir (art-down = the advancing edge), x along the wall.
	_xf(ci, o, dir.angle() - PI * 0.5)
	var row := PantheonFxData.WAVE_FRONT_ROW  # Front art row laid on the front line.
	var end := f - row + 1.0  # The water runs under the front's top rows (px).
	if end > back:
		var r := Rect2(-half, back, half * 2.0, end - back)  # The water's rect in the wave's frame.
		ci.draw_texture_rect_region(body, r, Rect2(0.0, back - scroll, half * 2.0, end - back))
	var fh := float(front.get_height())  # Front height (px).
	ci.draw_texture_rect_region(front, Rect2(-half, f - row, half * 2.0, fh), Rect2(0.0, 0.0, half * 2.0, fh))
	_reset(ci)
	return true


## A bolt's warning circle at `at`, radius `r`, timing `k` (0..1): the fill
## over the whole circle and denser inside r x k, the band on the exact edge,
## the impact point, and over the last moment the bolt coming down from the
## sky onto the centre. False when the art is missing.
static func bolt_warn(ci: CanvasItem, at: Vector2, r: float, k: float) -> bool:
	if not CovenantFx.has(PantheonFxData.EDGE) or not CovenantFx.has(PantheonFxData.FILL):
		return false
	CovenantFx.hatch_disc(ci, at, r, Color(1.0, 1.0, 1.0, PantheonFxData.FILL_BASE_ALPHA), PantheonFxData.FILL)
	if k > 0.02:
		CovenantFx.hatch_disc(ci, at, r * k, Color(1.0, 1.0, 1.0, PantheonFxData.FILL_ALPHA), PantheonFxData.FILL)
	if r >= PantheonFxData.TARGET_MIN_RADIUS:
		CovenantFx.still(ci, PantheonFxData.TARGET, at)
	CovenantFx.ring(ci, at, r, PantheonFxData.EDGE, Color(1.0, 1.0, 1.0, PantheonFxData.EDGE_ALPHA), PantheonFxData.EDGE_ROW,
		0.0, TAU, 0.0, PantheonFxData.EDGE_TICK, PantheonFxData.TICK_EVERY)
	var u := clampf((k - PantheonFxData.BOLT_COLUMN_FROM) / (1.0 - PantheonFxData.BOLT_COLUMN_FROM), 0.0, 1.0)  # 0 -> 1 as it comes down.
	var col := CovenantFx.tex(PantheonFxData.BOLT_COLUMN)  # Column art (base on its bottom row).
	if u > 0.0 and col != null:
		_reset(ci)
		var w := float(col.get_width())  # Column width (px).
		var h := float(col.get_height())  # Full height above the centre (px).
		var top := (at - Vector2(w * 0.5, h)).round()  # Its top-left corner at full height.
		# Only its top u share: the bolt reaches down from the sky, the ground at u = 1.
		ci.draw_texture_rect_region(col, Rect2(top, Vector2(w, h * u)), Rect2(0.0, 0.0, w, h * u))
	return true


## A lightning arc from `a` to `b` (thick for a bolt from the sky), the
## segment art repeating along it at 1:1, faded by `alpha`. False when missing.
static func arc(ci: CanvasItem, a: Vector2, b: Vector2, thick: bool, alpha: float) -> bool:
	var key := PantheonFxData.ARC_THICK if thick else PantheonFxData.ARC_THIN  # Segment art.
	var t := CovenantFx.tex(key)  # Its art.
	if t == null:
		return false
	return CovenantFx.ray_strip(ci, a, b, key, float(t.get_height()), 0.0, Color(1.0, 1.0, 1.0, alpha))


## A fissure's telegraph along `a` -> `b`: the crack art repeating along it,
## enlarged 1 -> FISSURE_WARN_GROW by the timing `k` (0..1), faded by `alpha`.
## False when the art is missing.
static func fissure_warn(ci: CanvasItem, a: Vector2, b: Vector2, k: float, alpha: float) -> bool:
	var t := CovenantFx.tex(PantheonFxData.FISSURE_WARN)  # Its art.
	if t == null:
		return false
	var h := float(t.get_height()) * lerpf(1.0, PantheonFxData.FISSURE_WARN_GROW, clampf(k, 0.0, 1.0))  # Drawn height (px).
	return CovenantFx.ray_strip(ci, a, b, PantheonFxData.FISSURE_WARN, h, 0.0, Color(1.0, 1.0, 1.0, alpha))


## An open fissure along `a` -> `b`, `width` px across: the left cap at a, the
## crack tile repeating between, the cap turned half round at b, scaled so the
## art's opening is `width`. False when the art is missing.
static func fissure(ci: CanvasItem, a: Vector2, b: Vector2, width: float) -> bool:
	var body := CovenantFx.tex(PantheonFxData.FISSURE_BODY, true)  # Repeating crack tile.
	var cap := CovenantFx.tex(PantheonFxData.FISSURE_CAP)  # Left cap.
	if body == null or cap == null:
		return false
	var ln := a.distance_to(b)  # Length (px).
	if ln < 1.0:
		return true
	SpriteBank.apply_sharp(ci)
	var s := width / PantheonFxData.FISSURE_OPENING  # Art px -> px.
	var h := float(body.get_height()) * s  # Drawn height (px).
	var cw := minf(float(cap.get_width()) * s, ln * 0.5)  # Drawn cap length (px; short cracks share it).
	var ang := (b - a).angle()  # Along the crack (rad).
	_xf(ci, a, ang)
	ci.draw_texture_rect(cap, Rect2(0.0, -h * 0.5, cw, h), false)
	if ln > cw * 2.0:
		var mid := ln - cw * 2.0  # Length between the caps (px).
		ci.draw_texture_rect_region(body, Rect2(cw, -h * 0.5, mid, h), Rect2(0.0, 0.0, mid / s, float(body.get_height())))
	_xf(ci, b, ang + PI)
	ci.draw_texture_rect(cap, Rect2(0.0, -h * 0.5, cw, h), false)
	_reset(ci)
	return true


## A river from `a` to `b`, `r` px each side of its line: the water repeating
## over the rectangle, its pattern drifting `scroll` px along the river, and a
## bank along each long side (row 0 outside); Lethe's look when `lethe`, faded
## by `alpha`. False when the art is missing.
static func river(ci: CanvasItem, a: Vector2, b: Vector2, r: float, lethe: bool, scroll: float, alpha: float) -> bool:
	var water_key := PantheonFxData.LETHE_WATER if lethe else PantheonFxData.STYX_WATER  # Water art.
	var bank_key := PantheonFxData.LETHE_BANK if lethe else PantheonFxData.STYX_BANK  # Bank art.
	var water := CovenantFx.tex(water_key, true)  # Repeating water tile.
	if water == null or not CovenantFx.has(bank_key):
		return false
	var ln := a.distance_to(b)  # Length (px).
	if ln < 1.0:
		return true
	SpriteBank.apply_sharp(ci)
	var m := Color(1.0, 1.0, 1.0, alpha)  # Fade.
	_xf(ci, a, (b - a).angle())
	ci.draw_texture_rect_region(water, Rect2(0.0, -r, ln, r * 2.0), Rect2(-scroll, -r, ln, r * 2.0), m)
	_reset(ci)
	var side := (b - a).orthogonal().normalized() * r  # From the line to the bank on the walk's left (px).
	# Each bank walked so its outer row (left of the walk) faces out: a -> b on
	# the left side, b -> a on the right.
	CovenantFx.edge_run(ci, a + side, b + side, bank_key, m, PantheonFxData.BANK_ROW)
	CovenantFx.edge_run(ci, b - side, a - side, bank_key, m, PantheonFxData.BANK_ROW)
	return true
