## AssemblyGlyphs — code-drawn pieces of the Assembly Halls (Act III, Stage 8;
## GDD §15.0 "The Assembly Halls (Act III phase 2)"), all purely visual and on
## whole layout px (the pixel-art grid):
##   * the conveyor belts and furnace channels (AssemblyDirector draws them in
##     world space under the bodies): flat palette colours, chevrons that scroll
##     with the belt, a molten channel that glows, then flares;
##   * the stage's obstacle fallbacks (when obstacles/<kind>_<size>.png is
##     missing; tools/assembly_props.py draws the sprites);
##   * the kits' telegraphs and props: the Arc Engineer's static field and
##     repair arcs, the Juggernaut's flame stream, a fabricator's build frame,
##     the Motherboard's press-stamp squares, crane claws and magnet coils.
## Colours: the Empire's chrome and signal ramps (never the undead's bone or
## soul teal, never the player's violet), the molten metal in the flame
## orange. Every telegraph is warning red / amber, never the Covenant's gold.
class_name AssemblyGlyphs
extends RefCounted

## Outline ink of the chrome ramp ("ink_chrome").
const INK := Color(0.043, 0.071, 0.125)
## Belt rubber (a near-black blue-grey, darker than every Assembly floor).
const BELT := Color(0.055, 0.063, 0.078)
## Belt rubber, the lighter ridge between two chevrons.
const BELT_RIDGE := Color(0.09, 0.10, 0.12)
## Rail steel of a belt (chrome_dark).
const RAIL := Color(0.173, 0.227, 0.314)
## Rail highlight (chrome_light).
const RAIL_LIGHT := Color(0.616, 0.714, 0.839)
## Cold slag crust of a furnace channel.
const SLAG := Color(0.14, 0.075, 0.05)
## Ember glow in the slag's cracks (a dim flame orange).
const EMBER := Color(0.55, 0.22, 0.06)
## Molten metal (flame).
const MOLTEN := Color(1.0, 0.55, 0.15)
## White-hot core of a burning channel (signal_glow).
const MOLTEN_CORE := Color(1.0, 0.922, 0.659)
## Rim iron of a channel (a warm near-black).
const RIM := Color(0.11, 0.07, 0.06)
## Width (px) of a belt's rail and a channel's iron rim.
const RAIL_W: float = 3.0
## Seconds per flicker frame of a burning channel's flames.
const FLICKER: float = 0.1


# =====================================================================================
# Belts and channels
# =====================================================================================

## A conveyor belt filling `rect` (world px), running along x when `along_x`
## (else y) in direction `dir` (+1 / -1); `scroll` px it has moved so far
## (game time x speed), which slides the chevrons and rollers.
static func draw_belt(ci: CanvasItem, rect: Rect2, along_x: bool, dir: float, scroll: float) -> void:
	ci.draw_rect(rect, BELT)
	var length := rect.size.x if along_x else rect.size.y  # Along the belt (px).
	var width := rect.size.y if along_x else rect.size.x  # Across it (px).
	var start := rect.position.x if along_x else rect.position.y  # Along-coordinate of the rect's start.
	var phase := fposmod(scroll * dir - start, AssemblyDirector.CHEVRON_STEP)  # Chevron offset at the start.
	var inner := width - RAIL_W * 2.0  # The rubber between the rails (px).
	var arm := floorf(inner * 0.28)  # Chevron arm length (px).
	var t := phase - AssemblyDirector.CHEVRON_STEP
	while t < length:
		var a := floorf(t)  # Along position of this chevron's tip.
		# A lighter ridge band and a two-pixel amber chevron pointing along `dir`.
		var mid := RAIL_W + inner * 0.5  # Across position of the chevron's tip.
		var ridge := Rect2(Vector2(a - 3.0, RAIL_W), Vector2(6.0, inner))
		_strip_rect(ci, rect, along_x, ridge, BELT_RIDGE)
		var tip := Vector2(a + dir * arm * 0.5, mid)
		var w1 := Vector2(a - dir * arm * 0.5, mid - arm)
		var w2 := Vector2(a - dir * arm * 0.5, mid + arm)
		_strip_line(ci, rect, along_x, w1, tip, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.42), 2.0)
		_strip_line(ci, rect, along_x, w2, tip, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.42), 2.0)
		t += AssemblyDirector.CHEVRON_STEP
	# Rails, with rollers ticking along them.
	_strip_rect(ci, rect, along_x, Rect2(Vector2(0.0, 0.0), Vector2(length, RAIL_W)), RAIL)
	_strip_rect(ci, rect, along_x, Rect2(Vector2(0.0, width - RAIL_W), Vector2(length, RAIL_W)), RAIL)
	_strip_rect(ci, rect, along_x, Rect2(Vector2(0.0, 0.0), Vector2(length, 1.0)), RAIL_LIGHT)
	var rp := fposmod(scroll * dir - start, AssemblyDirector.ROLLER_STEP)
	var r := rp - AssemblyDirector.ROLLER_STEP
	while r < length:
		_strip_rect(ci, rect, along_x, Rect2(Vector2(floorf(r), 1.0), Vector2(2.0, RAIL_W - 1.0)), INK)
		_strip_rect(ci, rect, along_x, Rect2(Vector2(floorf(r), width - RAIL_W), Vector2(2.0, RAIL_W)), INK)
		r += AssemblyDirector.ROLLER_STEP


## A furnace channel filling `rect` in state `state` (AssemblyDirector
## DORMANT / WARNING / BURNING) at `progress` 0..1 through it; `now` (game s)
## drives the glow pulse and the flame flicker.
static func draw_channel(ci: CanvasItem, rect: Rect2, along_x: bool, state: int, progress: float, now: float) -> void:
	var length := rect.size.x if along_x else rect.size.y  # Along the channel (px).
	var width := rect.size.y if along_x else rect.size.x  # Across it (px).
	ci.draw_rect(rect, RIM)
	var inner := Rect2(Vector2(0.0, RAIL_W), Vector2(length, width - RAIL_W * 2.0))  # The trough (strip space).
	match state:
		AssemblyDirector.DORMANT:
			_strip_rect(ci, rect, along_x, inner, SLAG)
			_cracks(ci, rect, along_x, inner, Color(EMBER, 0.5 + 0.3 * progress), now, false)
		AssemblyDirector.WARNING:
			var pulse := 0.6 + 0.4 * sin(now * 18.0)  # Fast warning pulse.
			_strip_rect(ci, rect, along_x, inner, SLAG.lerp(MOLTEN, 0.25 + 0.45 * progress))
			_cracks(ci, rect, along_x, inner, Color(MOLTEN_CORE, 0.5 + 0.4 * progress), now, false)
			# Warning-red edges blink: the channel is about to flare.
			_strip_rect(ci, rect, along_x, Rect2(Vector2(0.0, 0.0), Vector2(length, 2.0)), Color(Palette.EMPIRE_SIGNAL_RED, pulse))
			_strip_rect(ci, rect, along_x, Rect2(Vector2(0.0, width - 2.0), Vector2(length, 2.0)), Color(Palette.EMPIRE_SIGNAL_RED, pulse))
		_:
			_strip_rect(ci, rect, along_x, inner, MOLTEN)
			var core_w := floorf(inner.size.y * 0.4)  # White-hot core width (px).
			_strip_rect(ci, rect, along_x, Rect2(Vector2(0.0, RAIL_W + floorf((inner.size.y - core_w) * 0.5)), Vector2(length, core_w)), MOLTEN_CORE)
			_cracks(ci, rect, along_x, inner, Color(MOLTEN_CORE, 0.9), now, true)
			# A soft heat haze either side (drawing only; additive look by alpha).
			ci.draw_rect(rect.grow(6.0), Color(MOLTEN, 0.12 * (1.0 - progress * 0.5)))


## Hash-placed cracks / flame tongues along a channel trough `inner` (strip
## space): `tongues` true draws upright flames that flicker every FLICKER s.
static func _cracks(ci: CanvasItem, rect: Rect2, along_x: bool, inner: Rect2, col: Color, now: float, tongues: bool) -> void:
	var length := inner.size.x
	var start := rect.position.x if along_x else rect.position.y  # Along-coordinate of the strip's start (world px).
	var step := 22.0  # Spacing of the crack slots (px).
	var first := floorf(start / step) * step - start  # World-aligned slot positions.
	var frame := int(floorf(now / FLICKER))  # Flicker frame.
	var s := first
	while s < length:
		var slot := int(floorf((start + s) / step))  # World slot index (stable).
		var h := absi(hash(Vector2i(slot, frame if tongues else 0)))
		var a := s + float(h % 14)
		var across := inner.position.y + 2.0 + float((h >> 5) % maxi(1, int(inner.size.y) - 5))
		var len_px := 3.0 + float((h >> 9) % 6)
		if tongues:
			_strip_rect(ci, rect, along_x, Rect2(Vector2(a, across - 1.0), Vector2(len_px, 2.0)), col)
		else:
			_strip_rect(ci, rect, along_x, Rect2(Vector2(a, across), Vector2(len_px, 1.0)), col)
		s += step


## Fills `r` given in strip space (x along the strip, y across it from the
## strip's top / left edge) of strip `rect`.
static func _strip_rect(ci: CanvasItem, rect: Rect2, along_x: bool, r: Rect2, col: Color) -> void:
	if along_x:
		ci.draw_rect(Rect2(rect.position + r.position, r.size), col)
	else:
		ci.draw_rect(Rect2(rect.position + Vector2(r.position.y, r.position.x), Vector2(r.size.y, r.size.x)), col)


## A line between strip-space points `a` and `b` of strip `rect`.
static func _strip_line(ci: CanvasItem, rect: Rect2, along_x: bool, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	if along_x:
		ci.draw_line(rect.position + a, rect.position + b, col, w)
	else:
		ci.draw_line(rect.position + Vector2(a.y, a.x), rect.position + Vector2(b.y, b.x), col, w)


# =====================================================================================
# Obstacle fallbacks
# =====================================================================================

## Draws one of the Assembly Halls' obstacle kinds from code (no PNG). Returns
## false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"fuel_drum", "parts_bin", "robot_arm", "crucible":
			var r := o.radius
			var body := Palette.EMPIRE_CHROME
			var light := Palette.EMPIRE_SIGNAL_AMBER
			match o.kind:
				"fuel_drum":
					body = Color(0.55, 0.16, 0.08)
				"crucible":
					body = Color(0.22, 0.16, 0.14)
					light = MOLTEN
				"robot_arm":
					light = Palette.EMPIRE_SIGNAL_RED
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, INK)
			ci.draw_circle(c, r - 1.5, body)
			ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.3, body.lightened(0.3))
			ci.draw_circle(c, r * 0.3, light)
		"cargo_crate", "press_machine", "servo_cabinet", "ingot_stack":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var body := Palette.EMPIRE_CHROME_DARK
			match o.kind:
				"cargo_crate":
					body = Color(0.42, 0.32, 0.20)
				"ingot_stack":
					body = Color(0.30, 0.24, 0.20)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), body)
			ci.draw_rect(rect.grow(-4.0), body.lightened(0.15))
			ci.draw_rect(Rect2(rect.position + Vector2(3, 3), Vector2(4, 2)), Palette.EMPIRE_SIGNAL_AMBER)
		_:
			return false
	return true


# =====================================================================================
# Kit telegraphs and props (drawn on an enemy's overlay layer, local px)
# =====================================================================================

## The Arc Engineer's static field arming at local `at` (radius `r`, `k` 0..1
## as it arms): a ring of amber sparks closing in, then a warning-red edge.
static func draw_jam_field(ci: CanvasItem, at: Vector2, r: float, k: float) -> void:
	ci.draw_circle(at, r, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.08 + 0.12 * k))
	ci.draw_arc(at, r, 0.0, TAU, 32, Color(Palette.EMPIRE_SIGNAL_RED, 0.5 + 0.4 * k), 2.0)
	for i in 8:
		var a := TAU * float(i) / 8.0 + k * 2.0
		var p := at + Vector2.from_angle(a) * r * (1.0 - 0.4 * k)
		ci.draw_line(p, p + Vector2.from_angle(a + 1.6) * 5.0, Color(Palette.EMPIRE_SIGNAL_GLOW, 0.8), 1.0)


## A crackling repair arc from local `a` to `b` (an Arc Engineer patching a machine).
static func draw_arc_beam(ci: CanvasItem, a: Vector2, b: Vector2, k: float) -> void:
	var n := 5  # Zig-zag segments.
	var prev := a
	var side := (b - a).orthogonal().normalized()
	for i in range(1, n + 1):
		var t := float(i) / float(n)
		var p := a.lerp(b, t) + side * (4.0 if i % 2 == 0 else -4.0) * (1.0 if i < n else 0.0)
		ci.draw_line(prev, p, Color(Palette.EMPIRE_SIGNAL_GLOW, 0.9 * k), 1.5)
		prev = p


## The Juggernaut's flame stream along `dir` (unit, local space): a cone of
## `reach` px and `half` rad, `k` 0..1 through the stream (flicker by `now`).
static func draw_flame(ci: CanvasItem, dir: Vector2, reach: float, half: float, now: float) -> void:
	var frame := int(floorf(now / FLICKER))
	for i in 7:
		var h := absi(hash(Vector2i(i, frame)))
		var t := 0.25 + 0.75 * float(i) / 6.0
		var off := (float(h % 100) / 100.0 - 0.5) * 2.0 * half * t
		var p := dir.rotated(off) * reach * t
		var s := 3.0 + 7.0 * t
		ci.draw_circle(p, s, Color(MOLTEN, 0.55))
		ci.draw_circle(p, s * 0.5, Color(MOLTEN_CORE, 0.8))


## A fabricator's build frame over its bay: an amber bar filling with `k`
## (0..1 to the next build) and a scanning line. Local px around `o`.
static func draw_build_frame(ci: CanvasItem, o: Vector2, r: float, k: float) -> void:
	var w := floorf(r * 1.6)
	var bar := Rect2(o + Vector2(-w * 0.5, -r * 1.9), Vector2(w, 4.0))
	ci.draw_rect(bar.grow(1.0), INK)
	ci.draw_rect(bar, Color(0.12, 0.08, 0.04))
	ci.draw_rect(Rect2(bar.position, Vector2(floorf(w * clampf(k, 0.0, 1.0)), 4.0)), Palette.EMPIRE_SIGNAL_AMBER)


## A press-stamp square telegraph centred on `c` (world px, side `side`),
## `k` 0..1 as the stamp falls: the square fills and its corner brackets close.
static func draw_stamp(ci: CanvasItem, c: Vector2, side: float, k: float) -> void:
	var h := side * 0.5
	var sq := Rect2(c - Vector2(h, h), Vector2(side, side))
	ci.draw_rect(sq, Color(Palette.EMPIRE_SIGNAL_RED, 0.12 + 0.2 * k))
	var inner := side * k
	ci.draw_rect(Rect2(c - Vector2(inner, inner) * 0.5, Vector2(inner, inner)), Color(Palette.EMPIRE_SIGNAL_RED, 0.18))
	var b := 10.0  # Corner bracket length (px).
	var col := Color(Palette.EMPIRE_SIGNAL_AMBER, 0.95)
	for corner: Vector2 in [sq.position, Vector2(sq.end.x, sq.position.y), sq.end, Vector2(sq.position.x, sq.end.y)]:
		var sx := 1.0 if corner.x < c.x else -1.0
		var sy := 1.0 if corner.y < c.y else -1.0
		ci.draw_line(corner, corner + Vector2(sx * b, 0.0), col, 2.0)
		ci.draw_line(corner, corner + Vector2(0.0, sy * b), col, 2.0)


## A crane claw at `p` (local px) hanging from a cable that starts at `root`:
## chrome jaws, open (`open` true) or clamped shut.
static func draw_claw(ci: CanvasItem, root: Vector2, p: Vector2, open: bool) -> void:
	ci.draw_line(root, p, INK, 4.0)
	ci.draw_line(root, p, Palette.EMPIRE_CHROME_DARK, 2.0)
	var spread := 7.0 if open else 3.0
	ci.draw_rect(Rect2(p + Vector2(-5, -4), Vector2(10, 6)), INK)
	ci.draw_rect(Rect2(p + Vector2(-4, -3), Vector2(8, 4)), Palette.EMPIRE_CHROME_LIGHT)
	for sx: float in [-1.0, 1.0]:
		ci.draw_line(p + Vector2(sx * 3.0, 2.0), p + Vector2(sx * spread, 9.0), INK, 3.0)
		ci.draw_line(p + Vector2(sx * 3.0, 2.0), p + Vector2(sx * spread, 9.0), Palette.EMPIRE_CHROME, 1.0)
	ci.draw_circle(p + Vector2(0, -1), 1.5, Palette.EMPIRE_SIGNAL_AMBER)


## The Motherboard's magnet coils charging / pulling around local `o`: rings
## that run inward (`k` 0..1 phase), warning red while charging.
static func draw_magnet(ci: CanvasItem, o: Vector2, r: float, k: float, pulling: bool) -> void:
	var col := Palette.EMPIRE_SIGNAL_AMBER if pulling else Palette.EMPIRE_SIGNAL_RED
	for i in 3:
		var t := fposmod(1.0 - k + float(i) / 3.0, 1.0)
		ci.draw_arc(o, r * (0.2 + 0.8 * t), 0.0, TAU, 48, Color(col, 0.55 * (1.0 - t) + 0.1), 2.0)
