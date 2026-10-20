## CitadelGlyphs — code-drawn shapes of THE IRON CITADEL (Act III, Stage 9; GDD
## §15.0 "The Iron Citadel (Act III phase 2)"): the fallbacks of its kinds,
## structures, obstacles and boss while a sprite is missing (assets/sprites/
## empire/<kind>.png, bosses/deus_ex_machina*.png, obstacles/<kind>_*.png), and
## the effects that stay code-drawn on purpose: the Shield Gate walls and their
## light cables, the laser grids, the jets, the turret barrels, the blade storm,
## the stomp rings, the overload pulses, the Judgment Lance, the chaingun arc,
## the hangar doors, the teleport glow, the shield-drone tethers and the soul
## binding of the finale. Chrome bodies (the chrome ramp), signal-amber and
## warning-red light (never the Covenant's telegraph gold, never the player's
## violet or the undead's soul teal, except the finale's binding, which is the
## necromancer's). Purely visual.
class_name CitadelGlyphs
extends RefCounted

## Outline ink of the chrome ramp ("ink_chrome").
const INK := Color(0.043, 0.071, 0.125)
## Chrome glint (the ramp's lightest shade).
const GLINT := Color(0.886, 0.933, 1.0)


## Draws an Iron Citadel kind `kind` without art. Returns false for any other kind.
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"valkyrie_duelist", "valkyrie_prime":
			_valkyrie(ci, o, r, flash, kind == "valkyrie_prime")
		"sentry_turret":
			_turret_base(ci, o, r, flash)
		"shield_generator":
			_generator(ci, o, r, flash)
		"deus_leg_plate":
			_plate(ci, o, r, flash)
		"deus_shield_drone":
			_shield_drone(ci, o, r, flash)
		_:
			return false
	return true


## A Valkyrie: chrome armour over a signal-red bodysuit, twin jets on her back,
## a long arm blade (Valkyrie 2.0: a tower shield too, larger jets).
static func _valkyrie(ci: CanvasItem, o: Vector2, r: float, flash: bool, prime: bool) -> void:
	for sx: float in [-1.0, 1.0]:
		ci.draw_rect(Rect2(o + Vector2(-r * 0.55 + sx * r * 0.2, -r * 0.35), Vector2(r * 0.28, r * 0.9)), INK)  # Jet pods.
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.45, -r * 0.4), o + Vector2(r * 0.45, -r * 0.4), o + Vector2(r * 0.6, r * 0.95), o + Vector2(-r * 0.6, r * 0.95)]), INK)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.36, -r * 0.32), o + Vector2(r * 0.36, -r * 0.32), o + Vector2(r * 0.5, r * 0.85), o + Vector2(-r * 0.5, r * 0.85)]), Glyphs._c(Palette.EMPIRE_SIGNAL_DARK, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 0.35), Vector2(r * 0.8, r * 0.35)), Glyphs._c(Palette.EMPIRE_CHROME_LIGHT, flash))  # Breastplate.
	ci.draw_circle(o + Vector2(0, -r * 0.7), r * 0.42, INK)
	ci.draw_circle(o + Vector2(0, -r * 0.7), r * 0.34, Glyphs._c(Palette.EMPIRE_CHROME, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.05, -r * 0.8), Vector2(r * 0.4, r * 0.12)), Glyphs._c(Palette.EMPIRE_SIGNAL_AMBER, flash))  # Visor.
	ci.draw_line(o + Vector2(r * 0.4, r * 0.1), o + Vector2(r * 1.5, -r * 0.4), INK, 3.0)  # The arm blade.
	ci.draw_line(o + Vector2(r * 0.45, r * 0.05), o + Vector2(r * 1.45, -r * 0.42), Glyphs._c(GLINT, flash), 1.5)
	if prime:
		ci.draw_rect(Rect2(o + Vector2(-r * 1.05, -r * 0.45), Vector2(r * 0.42, r * 1.2)), INK)  # Tower shield.
		ci.draw_rect(Rect2(o + Vector2(-r * 1.0, -r * 0.4), Vector2(r * 0.32, r * 1.1)), Glyphs._c(Palette.EMPIRE_CHROME_LIGHT, flash))
		ci.draw_rect(Rect2(o + Vector2(-r * 0.9, -r * 0.1), Vector2(r * 0.12, r * 0.4)), Glyphs._c(Palette.EMPIRE_SIGNAL_AMBER, flash))


## A Sentry Turret's base (its barrel is drawn by draw_turret_barrel()).
static func _turret_base(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	for k in 3:
		var a := PI * 0.5 + TAU * float(k) / 3.0
		ci.draw_line(o, o + Vector2.from_angle(a) * r * 1.1, INK, 4.0)
		ci.draw_line(o, o + Vector2.from_angle(a) * r * 1.05, Glyphs._c(Palette.EMPIRE_CHROME_DARK, flash), 2.0)
	ci.draw_circle(o, r * 0.75, INK)
	ci.draw_circle(o, r * 0.65, Glyphs._c(Palette.EMPIRE_CHROME, flash))
	ci.draw_circle(o + Vector2(-r * 0.15, -r * 0.2), r * 0.25, Glyphs._c(Palette.EMPIRE_CHROME_LIGHT, flash))


## A Shield Generator: a chrome pylon with a humming amber core.
static func _generator(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.55, -r * 1.3), Vector2(r * 1.1, r * 2.1))
	ci.draw_rect(body.grow(1.5), INK)
	ci.draw_rect(body, Glyphs._c(Palette.EMPIRE_CHROME, flash))
	ci.draw_rect(Rect2(body.position, Vector2(r * 0.25, body.size.y)), Glyphs._c(Palette.EMPIRE_CHROME_LIGHT, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.35), r * 0.42, INK)
	ci.draw_circle(o + Vector2(0, -r * 0.35), r * 0.32, Glyphs._c(Palette.EMPIRE_SIGNAL_AMBER, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.35), r * 0.14, Glyphs._c(Palette.EMPIRE_SIGNAL_GLOW, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.75, r * 0.7), Vector2(r * 1.5, r * 0.3)), Glyphs._c(Palette.EMPIRE_CHROME_DARK, flash))


## A leg plate of Deus Ex Machina: a heavy chrome knee guard with a missile pod.
static func _plate(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var pts := PackedVector2Array([o + Vector2(-r, -r * 0.7), o + Vector2(r, -r * 0.7), o + Vector2(r * 0.8, r * 0.8), o + Vector2(0, r * 1.1), o + Vector2(-r * 0.8, r * 0.8)])
	ci.draw_colored_polygon(pts, INK)
	var inner := PackedVector2Array()
	for q in pts:
		inner.append(o + (q - o) * 0.82)
	ci.draw_colored_polygon(inner, Glyphs._c(Palette.EMPIRE_CHROME_LIGHT, flash))
	for k in 3:
		ci.draw_circle(o + Vector2((float(k) - 1.0) * r * 0.45, -r * 0.2), r * 0.16, Glyphs._c(Palette.EMPIRE_SIGNAL_RED, flash))  # Missile tubes.


## A Siege Core shield drone: a small chrome disc with an amber emitter.
static func _shield_drone(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o, r * 1.05, INK)
	ci.draw_circle(o, r * 0.9, Glyphs._c(Palette.EMPIRE_CHROME, flash))
	ci.draw_arc(o, r * 0.9, PI, TAU, 10, Glyphs._c(Palette.EMPIRE_CHROME_LIGHT, flash), 1.5)
	ci.draw_circle(o, r * 0.42, Glyphs._c(Palette.EMPIRE_SIGNAL_AMBER, flash))
	ci.draw_circle(o, r * 0.18, Glyphs._c(Palette.EMPIRE_SIGNAL_GLOW, flash))


# =====================================================================================
# Kit overlays
# =====================================================================================

## Jet flames at `at` (local, world axes) blowing along `dir` (unit), sized by
## `r`; `burning` = full thrust (the lunge / dash), else a flicker (the windup).
static func draw_jets(ci: CanvasItem, at: Vector2, dir: Vector2, r: float, burning: bool) -> void:
	var len := r * (1.4 if burning else 0.6)
	var side := Vector2(-dir.y, dir.x) * r * 0.3
	for s: float in [-1.0, 1.0]:
		var base := at + side * s
		ci.draw_line(base, base + dir * len, Color(Palette.EMPIRE_SIGNAL_RED, 0.55), r * 0.4)
		ci.draw_line(base, base + dir * len * 0.65, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.85), r * 0.22)
		ci.draw_circle(base, r * 0.14, Palette.EMPIRE_SIGNAL_GLOW)


## A Sentry Turret's barrel at `angle` (rad, world) over its base (radius `r`);
## while `aiming` its sensor flares as `k` (0..1) rises.
## With the sprite (empire/sentry_turret, its dome) only a slim gun on the dome's
## top turns to the aim; without it the code turret's hub and eye are drawn too.
static func draw_turret_barrel(ci: CanvasItem, r: float, angle: float, aiming: bool, k: float) -> void:
	var dir := Vector2.from_angle(angle)
	var art := SpriteBank.has("empire/sentry_turret")  # The sprite carries the dome and body.
	var hub := Vector2(0.0, -r * 0.55) if art else Vector2.ZERO  # The gun's pivot: the dome's top with art.
	var tip := hub + dir * r * (1.2 if art else 1.55)
	ci.draw_line(hub, tip, INK, 4.0 if art else 5.0)
	ci.draw_line(hub, tip, Palette.EMPIRE_CHROME_LIGHT, 2.0 if art else 2.5)
	if not art:
		ci.draw_circle(Vector2.ZERO, r * 0.38, INK)
		ci.draw_circle(Vector2.ZERO, r * 0.3, Palette.EMPIRE_CHROME_DARK)
		var eye := Palette.EMPIRE_SIGNAL_GLOW if aiming else Palette.EMPIRE_SIGNAL_AMBER
		ci.draw_circle(dir * r * 0.15, r * 0.16, eye)
	if aiming:
		ci.draw_circle(tip, 2.0 + 4.0 * k, Color(Palette.EMPIRE_SIGNAL_RED, 0.25 + 0.5 * k))
		ci.draw_line(tip, tip + dir * 60.0 * k, Color(Palette.EMPIRE_SIGNAL_RED, 0.35 * k), 1.0)


## The blade storm: two spinning arcs of steel round Valkyrie 2.0 (`r` px).
static func draw_blade_storm(ci: CanvasItem, r: float, t: float) -> void:
	var a := t * 14.0
	for k in 2:
		var a0 := a + PI * float(k)
		ci.draw_arc(Vector2.ZERO, r * 0.85, a0, a0 + 1.2, 12, Color(GLINT, 0.75), 3.0)
		ci.draw_arc(Vector2.ZERO, r * 0.85, a0 - 0.6, a0, 8, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.35), 5.0)
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(Palette.EMPIRE_SIGNAL_RED, 0.25), 1.5)


## A shield drone's tether of light to the core (`to`, local).
static func draw_tether(ci: CanvasItem, to: Vector2, t: float) -> void:
	var k := 0.5 + 0.5 * sin(t * 9.0)
	ci.draw_line(Vector2.ZERO, to, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.2 + 0.2 * k), 3.0)
	ci.draw_line(Vector2.ZERO, to, Color(Palette.EMPIRE_SIGNAL_GLOW, 0.45), 1.0)


# =====================================================================================
# Stage systems (CitadelDirector)
# =====================================================================================

## A Shield Gate's energy wall from `a` to `b` (`thick` px), powering up as
## `power` (0..1) rises: an amber barrier with a scrolling hex lattice and posts.
static func draw_gate_wall(ci: CanvasItem, a: Vector2, b: Vector2, thick: float, power: float, t: float) -> void:
	var ab := b - a
	var len := ab.length()
	if len < 1.0:
		return
	var dir := ab / len
	var n := Vector2(-dir.y, dir.x)
	var flick := 0.85 + 0.15 * sin(t * 13.0)
	ci.draw_line(a, a + ab * power, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.18 * flick), thick + 10.0)
	ci.draw_line(a, a + ab * power, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.38 * flick), thick)
	ci.draw_line(a + n * thick * 0.5, a + n * thick * 0.5 + ab * power, Color(Palette.EMPIRE_SIGNAL_GLOW, 0.7), 1.5)
	ci.draw_line(a - n * thick * 0.5, a - n * thick * 0.5 + ab * power, Color(Palette.EMPIRE_SIGNAL_GLOW, 0.7), 1.5)
	var cell := 22.0  # Lattice step along the wall (px).
	var off := fmod(t * 30.0, cell)
	var x := off
	while x < len * power:
		var c := a + dir * x
		ci.draw_line(c - n * thick * 0.5, c + n * thick * 0.5, Color(Palette.EMPIRE_SIGNAL_GLOW, 0.3), 1.0)
		x += cell
	for end: Vector2 in [a, b]:
		ci.draw_circle(end, thick * 0.6, INK)
		ci.draw_circle(end, thick * 0.45, Palette.EMPIRE_CHROME)


## The light cable from a generator at `from` to its wall end `to`.
static func draw_gate_cable(ci: CanvasItem, from: Vector2, to: Vector2, t: float) -> void:
	var k := 0.5 + 0.5 * sin(t * 6.0)
	ci.draw_line(from, to, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.25 + 0.25 * k), 3.0)
	ci.draw_line(from, to, Color(Palette.EMPIRE_SIGNAL_GLOW, 0.5), 1.0)


## A laser beam from `a` to `b` (`w` px): while telegraphed (`firing` false) a
## thin flickering red line growing as `tele` (0..1) rises, with emitter marks at
## both ends; firing, a hard white-hot beam with a red glow.
static func draw_laser(ci: CanvasItem, a: Vector2, b: Vector2, w: float, firing: bool, tele: float, t: float) -> void:
	if firing:
		ci.draw_line(a, b, Color(Palette.EMPIRE_SIGNAL_RED, 0.35), w * 2.6)
		ci.draw_line(a, b, Color(Palette.EMPIRE_SIGNAL_RED, 0.85), w)
		ci.draw_line(a, b, Color(Palette.EMPIRE_SIGNAL_GLOW, 0.95), maxf(1.0, w * 0.35))
		return
	var blink := 0.55 + 0.45 * float(int(t * 16.0) % 2)
	ci.draw_line(a, b, Color(Palette.EMPIRE_SIGNAL_RED, (0.25 + 0.5 * tele) * blink), 1.0 + tele)
	for end: Vector2 in [a, b]:
		ci.draw_circle(end, 4.0 + 3.0 * tele, Color(Palette.EMPIRE_SIGNAL_RED, 0.6))


## The band a telegraphed beam will sweep: from its start line (`c0`, sweep
## normal `n`, beam direction `along`, half length `half`) `sweep` px along `n`.
static func draw_laser_band(ci: CanvasItem, c0: Vector2, n: Vector2, along: Vector2, half: float, sweep: float, tele: float) -> void:
	var pts := PackedVector2Array([c0 - along * half, c0 + along * half, c0 + along * half + n * sweep, c0 - along * half + n * sweep])
	ci.draw_colored_polygon(pts, Color(Palette.EMPIRE_SIGNAL_RED, 0.06 + 0.08 * tele))


# =====================================================================================
# Deus Ex Machina
# =====================================================================================

## Deus Ex Machina without art (`look`: 0 the Walker, 1 the Siege Core, 2 the
## Founder; `arrive` 0..1 while it descends; `exposed`: the Siege Core open).
## Draws its sprite (bosses/deus_ex_machina, _siege, _founder) when it exists.
static func draw_deus(ci: CanvasItem, o: Vector2, r: float, flash: bool, look: int, arrive: float, t: float, exposed: bool, pose: int = 0) -> void:
	var key := "bosses/deus_ex_machina" + String(["", "_siege", "_founder"][clampi(look, 0, 2)])  # This phase's art.
	var drop := (1.0 - arrive) * -120.0  # It descends from above.
	if arrive < 1.0:
		ci.draw_circle(o, r * (0.6 + 0.6 * arrive), Color(0, 0, 0, 0.25 * arrive))
	var drawn := SpriteBank.draw_pose(ci, key, pose, o + Vector2(0, drop), flash) if look == 0 else SpriteBank.draw(ci, key, o + Vector2(0, drop), flash)  # The Walker has its firing pose (BossPoseData).
	if drawn or (look != 0 and SpriteBank.draw(ci, "bosses/deus_ex_machina", o + Vector2(0, drop), flash)):
		if look == 1 and exposed:
			ci.draw_circle(o + Vector2(0, drop - r * 0.6), r * 0.35, Color(Palette.EMPIRE_SIGNAL_GLOW, 0.35 + 0.15 * sin(t * 8.0)))
		elif look == 2:
			ci.draw_circle(o + Vector2(0, drop - r * 0.6), r * 0.3, Color(Palette.EMPIRE_SIGNAL_RED, 0.25 + 0.15 * sin(t * 10.0)))
		return
	var c := o + Vector2(0, drop - r * 0.4)  # The hull's centre, above its legs.
	if look == 0:
		for leg: Vector2 in DeusData.LEGS:
			ci.draw_line(c, o + leg + Vector2(0, drop), INK, 9.0)
			ci.draw_line(c, o + leg + Vector2(0, drop), Glyphs._c(Palette.EMPIRE_CHROME_DARK, flash), 5.0)
	var hull := PackedVector2Array([c + Vector2(-r * 1.2, -r * 0.4), c + Vector2(-r * 0.6, -r * 1.1), c + Vector2(r * 0.6, -r * 1.1),
			c + Vector2(r * 1.2, -r * 0.4), c + Vector2(r * 0.9, r * 0.7), c + Vector2(-r * 0.9, r * 0.7)])
	ci.draw_colored_polygon(hull, INK)
	var inner := PackedVector2Array()
	for q in hull:
		inner.append(c + (q - c) * 0.9)
	ci.draw_colored_polygon(inner, Glyphs._c(Palette.EMPIRE_CHROME, flash))
	ci.draw_rect(Rect2(c + Vector2(-r * 0.9, -r * 0.5), Vector2(r * 1.8, r * 0.18)), Glyphs._c(Palette.EMPIRE_CHROME_LIGHT, flash))
	var core := Palette.EMPIRE_SIGNAL_AMBER
	if look == 1:
		core = Palette.EMPIRE_SIGNAL_GLOW if exposed else Palette.EMPIRE_CHROME_DARK
	elif look == 2:
		core = Palette.EMPIRE_SIGNAL_RED
	ci.draw_circle(c, r * 0.42, INK)
	ci.draw_circle(c, r * 0.34, Glyphs._c(core, flash))
	if look == 2:
		for k in 4:
			var a := PI * 0.25 + PI * 0.5 * float(k)
			ci.draw_line(c + Vector2.from_angle(a) * r * 0.3, c + Vector2.from_angle(a) * r * 0.9, Glyphs._c(Palette.EMPIRE_SIGNAL_GLOW, flash), 2.0)
	# The cannon arms.
	for sx: float in [-1.0, 1.0]:
		ci.draw_rect(Rect2(c + Vector2(sx * r * 1.15 - r * 0.2, -r * 0.2), Vector2(r * 0.4, r * 0.9)), INK)
		ci.draw_rect(Rect2(c + Vector2(sx * r * 1.15 - r * 0.14, -r * 0.14), Vector2(r * 0.28, r * 0.78)), Glyphs._c(Palette.EMPIRE_CHROME_DARK, flash))


## A footfall / stomp ring at `c` (`r` px) filling as `k` (0..1) nears the landing.
static func draw_stomp_ring(ci: CanvasItem, c: Vector2, r: float, k: float) -> void:
	ci.draw_circle(c, r * k, Color(Palette.EMPIRE_SIGNAL_RED, 0.12 + 0.12 * k))
	ci.draw_arc(c, r, 0.0, TAU, 36, Color(Palette.EMPIRE_SIGNAL_RED, 0.8), 2.0)
	ci.draw_arc(c, r * 0.6, 0.0, TAU, 24, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.4), 1.0)


## The overload charge round the hull at `c` (radius `r`), as `k` (0..1) rises.
static func draw_pulse_charge(ci: CanvasItem, c: Vector2, r: float, k: float, t: float) -> void:
	var flick := 0.7 + 0.3 * sin(t * 30.0)
	ci.draw_circle(c, r * (1.0 + 0.6 * k), Color(Palette.EMPIRE_SIGNAL_RED, 0.12 * k * flick))
	ci.draw_arc(c, r * (1.6 - 0.5 * k), 0.0, TAU, 40, Color(Palette.EMPIRE_SIGNAL_GLOW, 0.6 * k), 2.0)


## A rolling overload pulse front at radius `r` round `c` (`front` px thick),
## fading as `fade` (1 -> 0) drops.
static func draw_pulse_front(ci: CanvasItem, c: Vector2, r: float, front: float, fade: float) -> void:
	if r <= 1.0:
		return
	ci.draw_arc(c, r, 0.0, TAU, 64, Color(Palette.EMPIRE_SIGNAL_RED, 0.35 * fade), front)
	ci.draw_arc(c, r, 0.0, TAU, 64, Color(Palette.EMPIRE_SIGNAL_GLOW, 0.8 * fade), 2.0)


## A telegraphed sweep: the arc from angle `a0` to `a1` (rad) out to `reach` px
## round `o`, filling as `k` (0..1) rises.
static func draw_sweep_arc(ci: CanvasItem, o: Vector2, a0: float, a1: float, reach: float, k: float) -> void:
	var lo := minf(a0, a1)
	var hi := maxf(a0, a1)
	var pts := PackedVector2Array([o])
	var steps := 16
	for i in steps + 1:
		pts.append(o + Vector2.from_angle(lerpf(lo, hi, float(i) / float(steps))) * reach)
	ci.draw_colored_polygon(pts, Color(Palette.EMPIRE_SIGNAL_RED, 0.05 + 0.08 * k))
	ci.draw_line(o, o + Vector2.from_angle(a0) * reach, Color(Palette.EMPIRE_SIGNAL_RED, 0.7), 2.0)
	ci.draw_arc(o, reach, lo, hi, 24, Color(Palette.EMPIRE_SIGNAL_RED, 0.5), 1.5)


## The Judgment Lance along `dir` (`len` px, `w` px wide): telegraphed a thin
## pulsing line (`firing` false, `k` 0..1), firing a blinding amber-white beam.
static func draw_lance(ci: CanvasItem, dir: Vector2, len: float, w: float, firing: bool, k: float, t: float) -> void:
	var b := dir * len
	if not firing:
		ci.draw_line(Vector2.ZERO, b, Color(Palette.EMPIRE_SIGNAL_RED, 0.3 + 0.4 * k), 1.0 + 2.0 * k)
		return
	var flick := 0.85 + 0.15 * sin(t * 40.0)
	ci.draw_line(Vector2.ZERO, b, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.35 * flick), w * 1.8)
	ci.draw_line(Vector2.ZERO, b, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.85), w)
	ci.draw_line(Vector2.ZERO, b, Color(Palette.EMPIRE_SIGNAL_GLOW, 1.0), w * 0.4)
	ci.draw_circle(b, w * 0.8, Color(Palette.EMPIRE_SIGNAL_GLOW, 0.8))


## A hangar door at `at` (local) glowing open as `k` (0..1) rises.
static func draw_hangar(ci: CanvasItem, at: Vector2, k: float) -> void:
	var rect := Rect2(at - Vector2(16, 10), Vector2(32, 20))
	ci.draw_rect(rect.grow(2.0), INK)
	ci.draw_rect(rect, Palette.EMPIRE_CHROME_DARK)
	var open := rect.size.x * 0.5 * k
	ci.draw_rect(Rect2(at - Vector2(open, 8), Vector2(open * 2.0, 16)), Color(Palette.EMPIRE_SIGNAL_RED, 0.8))


## A teleport's destination glow at `at` (local), `r` the hull radius.
static func draw_teleport_glow(ci: CanvasItem, at: Vector2, r: float, k: float, t: float) -> void:
	ci.draw_circle(at, r * (0.4 + 0.8 * k), Color(Palette.EMPIRE_SIGNAL_RED, 0.15 + 0.2 * k))
	for i in 3:
		var a := t * 3.0 + TAU * float(i) / 3.0
		ci.draw_arc(at, r * 1.2, a, a + 1.0, 10, Color(Palette.EMPIRE_SIGNAL_GLOW, 0.7 * k), 2.0)


## The finale's soul binding round `c`: the necromancer's green rings close on
## the broken engine as `k` (0..1) runs.
static func draw_soul_binding(ci: CanvasItem, c: Vector2, big: float, k: float, t: float) -> void:
	var fade := 1.0 - k
	for i in 3:
		var r := big * (1.0 - k * 0.6) * (1.0 - 0.25 * float(i))
		ci.draw_arc(c, r, t * (1.0 + float(i)), t * (1.0 + float(i)) + TAU * 0.8, 40, Color(Palette.NECRO_GREEN, 0.6 * fade), 2.0)
	ci.draw_circle(c, 14.0 + 10.0 * k, Color(Palette.NECRO_GREEN, 0.3 * fade))


# =====================================================================================
# Obstacles
# =====================================================================================

## Draws one of the Iron Citadel's obstacle kinds without art. Returns false
## for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"iron_barricade", "cargo_crate":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), Palette.EMPIRE_CHROME_DARK)
			ci.draw_rect(rect.grow(-4.0), Palette.EMPIRE_CHROME if o.kind == "iron_barricade" else Color(0.30, 0.27, 0.22))
			var horizontal := o.half.x > o.half.y
			var long_len := (o.half.x if horizontal else o.half.y) * 2.0
			var k := 16.0
			while k < long_len - 6.0:
				var p0 := rect.position + (Vector2(k, 3) if horizontal else Vector2(3, k))
				var p1 := p0 + (Vector2(0, rect.size.y - 6) if horizontal else Vector2(rect.size.x - 6, 0))
				ci.draw_line(p0, p1, Palette.EMPIRE_CHROME_DARK, 1.0)
				k += 16.0
			if o.kind == "iron_barricade":
				ci.draw_rect(Rect2(c - Vector2(3, 3), Vector2(6, 6)), Palette.EMPIRE_SIGNAL_AMBER)
		"signal_bollard", "emitter_pylon", "lift_winch", "core_conduit":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, INK)
			ci.draw_circle(c, r - 1.5, Palette.EMPIRE_CHROME)
			ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Palette.EMPIRE_CHROME_LIGHT)
			var lamp := Palette.EMPIRE_SIGNAL_RED if o.kind == "emitter_pylon" else Palette.EMPIRE_SIGNAL_AMBER
			ci.draw_circle(c, r * 0.3, lamp)
		_:
			return false
	return true
