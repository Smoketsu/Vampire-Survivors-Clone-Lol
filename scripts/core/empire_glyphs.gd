## EmpireGlyphs — code-drawn fallback shapes for the ELECTRONIC EMPIRE (Act
## III; GDD §15.0 "Act III foundation (phase 1)"), drawn when a kind has no
## sprite art (assets/sprites/empire/<kind>.png): chrome bodies (the chrome
## ramp, bluer than the undead's grey) with signal-amber and warning-red
## lights. Also the Grave Gunner (a cyborg raised with its rifle, in the
## undead's bone and soul teal) and the Act III stubs' placeholder obstacles.
## Every Empire kind without a shape of its own gets the plain cyborg (or the
## plain drone for a machine that flies). Purely visual.
class_name EmpireGlyphs
extends RefCounted

## Outline ink of the chrome ramp ("ink_chrome").
const INK := Color(0.043, 0.071, 0.125)


## Draws Electronic Empire kind `kind`. Returns false when `kind` is not an
## Empire kind (Glyphs.draw_enemy() then asks the Ancient Eye's glyphs).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	var row := EnemyDirector.empire_def(kind)  # Its design row ({} = not an Empire kind).
	if row.is_empty():
		return false
	match kind:
		"scout_drone":
			_drone(ci, o, r, flash, Palette.EMPIRE_SIGNAL_AMBER)
		"kill_drone":
			_drone(ci, o, r, flash, Palette.EMPIRE_SIGNAL_RED)
		"line_trooper":
			_cyborg(ci, o, r, flash, Palette.EMPIRE_SIGNAL_AMBER)
			# The rifle, held level to the right.
			ci.draw_rect(Rect2(o + Vector2(r * 0.2, -r * 0.05), Vector2(r * 1.25, r * 0.28)), INK)
			ci.draw_rect(Rect2(o + Vector2(r * 0.25, 0.0), Vector2(r * 1.15, r * 0.16)), Glyphs._c(Palette.EMPIRE_CHROME_DARK, flash))
		"spotter":
			_cyborg(ci, o, r, flash, Palette.EMPIRE_SIGNAL_RED)
			# The long rail rifle and its red scope.
			ci.draw_rect(Rect2(o + Vector2(r * 0.1, -r * 0.2), Vector2(r * 1.9, r * 0.24)), INK)
			ci.draw_rect(Rect2(o + Vector2(r * 0.15, -r * 0.15), Vector2(r * 1.8, r * 0.14)), Glyphs._c(Palette.EMPIRE_CHROME_LIGHT, flash))
			ci.draw_circle(o + Vector2(r * 0.7, -r * 0.35), r * 0.16, Glyphs._c(Palette.EMPIRE_SIGNAL_RED, flash))
		_:
			if String(row.get("body", "")) == EmpireEnemyData.MACHINE and bool(row.get("floating", false)):
				_drone(ci, o, r, flash, Palette.EMPIRE_SIGNAL_AMBER)
			else:
				_cyborg(ci, o, r, flash, Palette.EMPIRE_SIGNAL_AMBER)
	return true


## A drone: a chrome disc with stub rotors and one glowing `eye` lens.
static func _drone(ci: CanvasItem, o: Vector2, r: float, flash: bool, eye: Color) -> void:
	for sx: float in [-1.0, 1.0]:
		ci.draw_line(o + Vector2(sx * r * 0.5, -r * 0.2), o + Vector2(sx * r * 1.15, -r * 0.55), INK, 2.0)
		ci.draw_line(o + Vector2(sx * r * 0.8, -r * 0.62), o + Vector2(sx * r * 1.5, -r * 0.62), Glyphs._c(Palette.EMPIRE_CHROME_LIGHT, flash), 1.5)
	ci.draw_circle(o, r * 0.85, INK)
	ci.draw_circle(o, r * 0.72, Glyphs._c(Palette.EMPIRE_CHROME, flash))
	ci.draw_circle(o + Vector2(-r * 0.2, -r * 0.25), r * 0.3, Glyphs._c(Palette.EMPIRE_CHROME_LIGHT, flash))
	ci.draw_circle(o + Vector2(r * 0.15, r * 0.05), r * 0.3, INK)
	ci.draw_circle(o + Vector2(r * 0.15, r * 0.05), r * 0.2, Glyphs._c(eye, flash))


## A cyborg soldier: chrome plate, a helmet with a glowing `visor` band.
static func _cyborg(ci: CanvasItem, o: Vector2, r: float, flash: bool, visor: Color) -> void:
	var body := Rect2(o + Vector2(-r * 0.6, -r * 0.4), Vector2(r * 1.2, r * 1.35))  # Torso and legs.
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.EMPIRE_CHROME, flash))
	ci.draw_rect(Rect2(body.position, Vector2(body.size.x, r * 0.3)), Glyphs._c(Palette.EMPIRE_CHROME_LIGHT, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.75), r * 0.5, INK)
	ci.draw_circle(o + Vector2(0, -r * 0.75), r * 0.42, Glyphs._c(Palette.EMPIRE_CHROME_DARK, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.1, -r * 0.88), Vector2(r * 0.5, r * 0.16)), Glyphs._c(visor, flash))


## The Grave Gunner (a raised cyborg, the undead's now): bone-grey plate, a
## soul-teal visor and its rifle. Used when summons/grave_gunner has no art.
static func draw_gunner(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.6, -r * 0.4), Vector2(r * 1.2, r * 1.35))  # Torso and legs.
	ci.draw_rect(body.grow(1.0), Glyphs.OUTLINE)
	ci.draw_rect(body, Glyphs._c(Palette.UNDEAD_STEEL, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.75), r * 0.5, Glyphs.OUTLINE)
	ci.draw_circle(o + Vector2(0, -r * 0.75), r * 0.42, Glyphs._c(Palette.BONE, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.1, -r * 0.88), Vector2(r * 0.5, r * 0.16)), Glyphs._c(Palette.NECRO_GREEN, flash))
	ci.draw_rect(Rect2(o + Vector2(r * 0.2, -r * 0.05), Vector2(r * 1.25, r * 0.28)), Glyphs.OUTLINE)
	ci.draw_rect(Rect2(o + Vector2(r * 0.25, 0.0), Vector2(r * 1.15, r * 0.16)), Glyphs._c(Palette.BONE, flash))


## Draws one of the Act III stubs' placeholder obstacles (scrap heaps, steel
## crates, signal pylons). Returns false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"scrap_heap":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, INK)
			ci.draw_circle(c, r - 1.5, Palette.EMPIRE_CHROME_DARK)
			for k in 3:
				var a := float((o.variant + k * 211) % 628) * 0.01  # Plate angle.
				var q := c + Vector2.from_angle(a) * r * 0.4
				ci.draw_rect(Rect2(q - Vector2(r * 0.3, r * 0.2), Vector2(r * 0.6, r * 0.4)), Palette.EMPIRE_CHROME)
			ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.18, Palette.EMPIRE_CHROME_LIGHT)
		"steel_crate":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), Palette.EMPIRE_CHROME_DARK)
			ci.draw_rect(rect.grow(-4.0), Palette.EMPIRE_CHROME)
			ci.draw_line(rect.position + Vector2(4, 4), rect.end - Vector2(4, 4), Palette.EMPIRE_CHROME_DARK, 2.0)
			ci.draw_line(Vector2(rect.position.x + 4, rect.end.y - 4), Vector2(rect.end.x - 4, rect.position.y + 4), Palette.EMPIRE_CHROME_DARK, 2.0)
		"signal_pylon":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, INK)
			ci.draw_circle(c, r - 1.5, Palette.EMPIRE_CHROME)
			ci.draw_circle(c, r * 0.45, Palette.EMPIRE_SIGNAL_DARK)
			ci.draw_circle(c, r * 0.3, Palette.EMPIRE_SIGNAL_AMBER)
		_:
			return false
	return true
