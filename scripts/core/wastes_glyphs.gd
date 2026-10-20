## WastesGlyphs — code-drawn fallback shapes of the Scrap Wastes (Act III,
## Stage 7; GDD §15.0 "The Scrap Wastes (Act III phase 2)"), drawn when a piece
## has no sprite art: the Trojan Horse (closed and split), its Swarm Rockets,
## Kestrel (the boss and her decoy holograms) and the stage's six obstacle
## kinds. The Aegis Bot, the Mortar Walker and the Signal Pylon fall back on
## EmpireGlyphs' plain cyborg / drone. Chrome bodies (the chrome ramp) with
## signal-amber and warning-red lights; never the undead's bone or soul teal.
## Purely visual.
class_name WastesGlyphs
extends RefCounted

## Outline ink of the chrome ramp ("ink_chrome").
const INK := Color(0.043, 0.071, 0.125)
## Rust brown of the wrecks (obstacles only; brown ramp).
const RUST := Color(0.31, 0.2, 0.125)
## Slag black-brown (obstacles only).
const SLAG := Color(0.16, 0.13, 0.12)
## Weathered concrete grey (the Outer Wall's obstacles).
const CONCRETE := Color(0.42, 0.41, 0.39)


## A Swarm Rocket at `o` pointing along `dir` (unit), body radius `r`.
static func draw_rocket(ci: CanvasItem, o: Vector2, dir: Vector2, r: float, flash: bool) -> void:
	var side := dir.orthogonal()  # Across the rocket.
	var nose := o + dir * r * 1.4
	var tail := o - dir * r * 1.2
	ci.draw_line(tail, nose, INK, r * 1.1 + 2.0)
	ci.draw_line(tail, nose, Glyphs._c(Palette.EMPIRE_CHROME, flash), r * 1.1)
	ci.draw_line(tail, o + dir * r * 0.4, Glyphs._c(Palette.EMPIRE_CHROME_LIGHT, flash), r * 0.4)
	ci.draw_circle(nose, r * 0.45, Glyphs._c(Palette.EMPIRE_SIGNAL_AMBER, flash))
	for s: float in [-1.0, 1.0]:
		ci.draw_line(tail, tail - dir * r * 0.5 + side * s * r * 0.8, INK, 2.0)


## Kestrel, the Dead Pixel: a slim chrome-plated markswoman (signal-red visor,
## a long rifle in pose 0 / 1, two arm blades in pose 3), tinted by `tint`
## (her decoys' hologram).
static func draw_kestrel(ci: CanvasItem, o: Vector2, r: float, flash: bool, tint: Color, pose: int) -> void:
	var body := Rect2(o + Vector2(-r * 0.45, -r * 0.5), Vector2(r * 0.9, r * 1.5))  # Torso and legs.
	ci.draw_rect(body.grow(1.0), Color(INK, tint.a))
	ci.draw_rect(body, _t(Palette.EMPIRE_CHROME, flash, tint))
	ci.draw_circle(o + Vector2(0, -r * 0.85), r * 0.42, Color(INK, tint.a))
	ci.draw_circle(o + Vector2(0, -r * 0.85), r * 0.34, _t(Palette.EMPIRE_CHROME_LIGHT, flash, tint))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.05, -r * 0.95), Vector2(r * 0.42, r * 0.14)), _t(Palette.EMPIRE_SIGNAL_RED, flash, tint))
	if pose == 3:
		for s: float in [-1.0, 1.0]:
			ci.draw_line(o + Vector2(s * r * 0.5, -r * 0.1), o + Vector2(s * r * 1.4, -r * 0.7), _t(Palette.EMPIRE_SIGNAL_GLOW, flash, tint), 2.0)
	else:
		ci.draw_rect(Rect2(o + Vector2(r * 0.1, -r * 0.3), Vector2(r * 2.0, r * 0.2)), Color(INK, tint.a))
		ci.draw_rect(Rect2(o + Vector2(r * 0.15, -r * 0.27), Vector2(r * 1.9, r * 0.12)), _t(Palette.EMPIRE_CHROME_DARK, flash, tint))


## `col` with the hit flash, multiplied by `tint`.
static func _t(col: Color, flash: bool, tint: Color) -> Color:
	return Glyphs._c(col, flash) * tint


## The Trojan Horse: a four-legged chrome tank hull with two missile pods and a
## red sensor eye; `split` = the hull cracked open.
static func draw_trojan(ci: CanvasItem, o: Vector2, r: float, flash: bool, split: bool) -> void:
	for i in 4:
		var x := (-0.75 + 0.5 * float(i)) * r  # Leg x (px).
		ci.draw_line(o + Vector2(x, 0), o + Vector2(x * 1.1, r * 0.9), INK, 4.0)
		ci.draw_line(o + Vector2(x, 0), o + Vector2(x * 1.1, r * 0.9), Glyphs._c(Palette.EMPIRE_CHROME_DARK, flash), 2.0)
	var hull := Rect2(o + Vector2(-r, -r * 0.7), Vector2(r * 2.0, r * 0.9))
	ci.draw_rect(hull.grow(1.0), INK)
	ci.draw_rect(hull, Glyphs._c(Palette.EMPIRE_CHROME, flash))
	ci.draw_rect(Rect2(hull.position, Vector2(hull.size.x, r * 0.2)), Glyphs._c(Palette.EMPIRE_CHROME_LIGHT, flash))
	if split:
		ci.draw_rect(Rect2(o + Vector2(-r * 0.2, -r * 0.7), Vector2(r * 0.4, r * 0.9)), INK)
		ci.draw_circle(o + Vector2(0, -r * 0.25), r * 0.18, Glyphs._c(Palette.EMPIRE_SIGNAL_AMBER, flash))
	for sx: float in [-0.45, 0.15]:
		ci.draw_rect(Rect2(o + Vector2(r * sx - r * 0.2, -r * 1.2), Vector2(r * 0.4, r * 0.5)), Glyphs._c(Palette.EMPIRE_CHROME_DARK, flash))
	ci.draw_circle(o + Vector2(r * 0.85, -r * 0.4), r * 0.15, Glyphs._c(Palette.EMPIRE_SIGNAL_RED, flash))


## Draws one of the Scrap Wastes' obstacle kinds; false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"slag_mound", "ridge_boulder":
			var r := o.radius
			var body := SLAG if o.kind == "slag_mound" else Color(0.22, 0.21, 0.21)  # Mound / rock colour.
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, INK)
			ci.draw_circle(c, r - 1.5, body)
			ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.4, body.lightened(0.15))
			if o.kind == "slag_mound":
				ci.draw_circle(c + Vector2(r * 0.2, r * 0.1), r * 0.15, Color(Palette.EMPIRE_SIGNAL_DARK, 0.7))  # A glowing slag seam.
		"tank_trap":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			for a: float in [0.0, 1.05, 2.1]:
				var d := Vector2.from_angle(a) * r
				ci.draw_line(c - d, c + d, INK, 6.0)
				ci.draw_line(c - d, c + d, RUST.lightened(0.2), 3.0)
		"wreck_plate", "titan_hull", "wall_segment":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var body := RUST if o.kind == "wreck_plate" else (Palette.EMPIRE_CHROME_DARK if o.kind == "titan_hull" else CONCRETE)  # Material.
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), body)
			ci.draw_rect(Rect2(rect.position + Vector2(1.5, 1.5), Vector2(rect.size.x - 3.0, 3.0)), body.lightened(0.2))
			if o.kind == "titan_hull":
				var long := Vector2(1, 0) if o.half.x >= o.half.y else Vector2(0, 1)  # Along the hull.
				for k in 3:
					var q := c + long * (float(k) - 1.0) * (maxf(o.half.x, o.half.y) * 0.55)
					ci.draw_circle(q, 2.5, Palette.EMPIRE_CHROME)  # Rivets of the fallen titan.
		_:
			return false
	return true
