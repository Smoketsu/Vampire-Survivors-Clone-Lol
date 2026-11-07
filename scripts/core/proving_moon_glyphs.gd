## ProvingMoonGlyphs — code-drawn fallback shapes of the Proving Moon (Act IX,
## Stage 26; GDD §15.0 "The Proving Moon (Act IX phase 2)"), drawn when the art
## is missing (assets/sprites/concord/warbeast.png, bosses/vrask_tal.png,
## obstacles/<kind>_<size>[_v].png): the Warbeast, Vrask'Tal and his skull belt
## (drawn over his sprite too: one skull per kill, the Stalk's trophies), and
## the stage's obstacles (moon_boulder, crater_rim, trophy_pillar). Vrask teal
## and dark gunmetal; never the necromancer's violet and bone (the trophy
## skulls are a weathered yellow-grey, Palette.CONCORD_HIVE_BONE). Discs are
## SpriteBank's textures (no polygon redrawn every frame). Purely visual.
class_name ProvingMoonGlyphs
extends RefCounted

## Outline ink (the Concord's starfield black).
const INK := Palette.CONCORD_INK
## Most skulls drawn on the belt (VraskTalData skull_cap is the damage cap).
const BELT_MAX: int = 8
## Px between two skulls on the belt.
const BELT_STEP: float = 5.0


## The Warbeast: a low, broad armoured hound, teal hide, gunmetal plates, at
## `o` (lifted on its leap), `r` its body radius; crouched lower when `crouch`.
static func draw_warbeast(ci: CanvasItem, o: Vector2, r: float, flash: bool, crouch: bool) -> void:
	var hide := Color.WHITE if flash else Palette.CONCORD_VRASK
	var plate := Color.WHITE if flash else Palette.CONCORD_GUNMETAL
	var y := r * 0.15 if crouch else 0.0  # Crouch drop (px).
	SpriteBank.draw_disc(ci, o + Vector2(0.0, y), r * 1.05, INK)
	SpriteBank.draw_disc(ci, o + Vector2(0.0, y), r * 0.95, hide)
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.25, y - r * 0.25), r * 0.55, plate)  # The back plate.
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.25, y - r * 0.15), r * 0.4, plate)
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.85, y - r * 0.1), r * 0.42, INK)  # The head.
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.85, y - r * 0.1), r * 0.34, hide)
	SpriteBank.draw_disc(ci, o + Vector2(r * 1.0, y - r * 0.2), r * 0.08, Palette.CONCORD_LUMEN)  # An eye.


## Vrask'Tal: a tall reptilian hunter, teal scales, gunmetal armour, the
## shoulder caster's magenta lamp, at `o`; `alpha` < 1 is the cloak's shimmer;
## `aim` lights the caster.
static func draw_vrask_tal(ci: CanvasItem, o: Vector2, r: float, flash: bool, alpha: float, aim: bool) -> void:
	var scale_c := Color(Color.WHITE if flash else Palette.CONCORD_VRASK, alpha)
	var armour := Color(Color.WHITE if flash else Palette.CONCORD_GUNMETAL, alpha)
	var ink := Color(INK, alpha)
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.2), r * 0.95, ink)
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.2), r * 0.85, armour)
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 1.05), r * 0.45, ink)  # The head.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 1.05), r * 0.37, scale_c)
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.12, -r * 1.1), r * 0.07, Color(Palette.CONCORD_LUMEN, alpha))  # The slit eye.
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.55, -r * 0.65), r * 0.22, Color(Palette.CONCORD_LASER, alpha * (1.0 if aim else 0.6)))  # The caster's lamp.
	ci.draw_line(o + Vector2(-r * 0.9, r * 0.6), o + Vector2(r * 1.1, -r * 1.4), Color(Palette.CONCORD_HULL_SHADE, alpha), 2.0)  # The glaive.


## His belt of skulls: `n` small trophy skulls on a line under his chest, at `o`.
static func draw_skull_belt(ci: CanvasItem, o: Vector2, r: float, n: int) -> void:
	var k := mini(n, BELT_MAX)
	if k <= 0:
		return
	var x0 := -BELT_STEP * float(k - 1) * 0.5
	for i in k:
		var p := o + Vector2(x0 + BELT_STEP * float(i), r * 0.05 + (1.0 if i % 2 == 1 else 0.0))
		SpriteBank.draw_disc(ci, p, 2.4, INK)
		SpriteBank.draw_disc(ci, p, 1.8, Palette.CONCORD_HIVE_BONE)


## The stage's obstacle kinds (false for any other kind): a grey moon
## BOULDER, a CRATER RIM (a raised ring of regolith around a dark bowl) and a
## TROPHY PILLAR (a dark stone pillar hung with skulls).
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"moon_boulder", "crater_rim":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, Color(0.36, 0.37, 0.40))
			if o.kind == "crater_rim":
				SpriteBank.draw_disc(ci, c + Vector2(1, 1), r * 0.62, Color(0.12, 0.13, 0.15))  # The bowl.
			else:
				SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color(0.52, 0.53, 0.56))
		"trophy_pillar":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), Palette.CONCORD_GUNMETAL_DARK)
			var step := 9.0  # Skulls along the pillar (px).
			var along_x := rect.size.x >= rect.size.y
			var t := step
			while t < (rect.size.x if along_x else rect.size.y) - 2.0:
				var p := rect.position + (Vector2(t, rect.size.y * 0.5) if along_x else Vector2(rect.size.x * 0.5, t))
				SpriteBank.draw_disc(ci, p, 2.5, Palette.CONCORD_HIVE_BONE)
				t += step
		_:
			return false
	return true
