## BurningGateGlyphs — code-drawn shapes of the Burning Gate (Act VI, Stage 16;
## GDD §15.0 "The Burning Gate (Act VI phase 2)"): the fallbacks of the stage's
## three obstacle kinds (ember rocks, cages of the damned, gate pillars), of its
## kinds (the Hellhound, the Pit Cultist, the Gatekeeper) and of Moloch when
## their sprites are missing. Obsidian, ash, lava and iron (InfernoGlyphs'
## colours); never the undead's bone or soul teal. Rects, lines and texture
## discs only (no polygon redrawn every frame). Purely visual.
class_name BurningGateGlyphs
extends RefCounted

## Ink of the outlines (the obsidian ink).
const INK := Color(0.043, 0.039, 0.063)
## Rusted iron of the cages and chains.
const RUST := Color(0.36, 0.25, 0.20)
## The cultists' robe red.
const ROBE := Color(0.48, 0.10, 0.10)


## Draws one of the Burning Gate's obstacle kinds at its collision shape.
## Returns false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"ember_rock":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, Palette.INFERNO_OBSIDIAN)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Palette.INFERNO_OBSIDIAN_LIGHT)
			ci.draw_line(c + Vector2(-r * 0.4, r * 0.1), c + Vector2(r * 0.3, r * 0.4), Palette.INFERNO_LAVA, 1.0)  # A lava vein.
		"damned_cage", "gate_pillar":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var cage := o.kind == "damned_cage"
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), Color(0.12, 0.10, 0.10) if cage else Palette.INFERNO_OBSIDIAN_DARK)
			var step := 7.0 if cage else 14.0  # Bars / chain links (px).
			var line := RUST if cage else Palette.INFERNO_LAVA_DARK
			if rect.size.x >= rect.size.y:
				var x := rect.position.x + step
				while x < rect.end.x - 2.0:
					ci.draw_line(Vector2(x, rect.position.y + 2.0), Vector2(x, rect.end.y - 2.0), line, 1.0)
					x += step
			else:
				var y := rect.position.y + step
				while y < rect.end.y - 2.0:
					ci.draw_line(Vector2(rect.position.x + 2.0, y), Vector2(rect.end.x - 2.0, y), line, 1.0)
					y += step
			if not cage:
				SpriteBank.draw_disc(ci, c, minf(o.half.x, o.half.y) * 0.6, Palette.BONE)  # The horned skull.
		_:
			return false
	return true


## Draws Burning Gate kind `kind` (InfernoGlyphs.draw_enemy() asks first).
## Returns false for any other kind.
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"lava_hound":
			var body := Rect2(o + Vector2(-r * 1.0, -r * 0.4), Vector2(r * 2.0, r * 0.9))
			ci.draw_rect(body.grow(1.0), INK)
			ci.draw_rect(body, Glyphs._c(Palette.INFERNO_OBSIDIAN_DARK, flash))
			ci.draw_line(body.position + Vector2(r * 0.3, r * 0.3), body.position + Vector2(r * 1.6, r * 0.5), Glyphs._c(Palette.INFERNO_LAVA, flash), 1.5)  # Lava cracks.
			ci.draw_rect(Rect2(o + Vector2(r * 0.6, -r * 0.9), Vector2(r * 0.8, r * 0.7)), Glyphs._c(Palette.INFERNO_OBSIDIAN, flash))  # Head.
			ci.draw_rect(Rect2(o + Vector2(r * 1.0, -r * 0.75), Vector2(r * 0.25, r * 0.18)), Glyphs._c(Palette.INFERNO_LAVA_LIGHT, flash))  # Eye.
		"pit_cultist":
			var robe := Rect2(o + Vector2(-r * 0.55, -r * 0.5), Vector2(r * 1.1, r * 1.6))
			ci.draw_rect(robe.grow(1.0), INK)
			ci.draw_rect(robe, Glyphs._c(ROBE, flash))
			ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.15), Vector2(r * 0.8, r * 0.7)), Glyphs._c(Color(0.16, 0.12, 0.12), flash))  # The horned mask.
			ci.draw_line(o + Vector2(-r * 0.35, -r * 1.15), o + Vector2(-r * 0.55, -r * 1.55), Glyphs._c(Palette.BONE, flash), 2.0)
			ci.draw_line(o + Vector2(r * 0.35, -r * 1.15), o + Vector2(r * 0.55, -r * 1.55), Glyphs._c(Palette.BONE, flash), 2.0)
			SpriteBank.draw_disc(ci, o + Vector2(r * 0.8, r * 0.3), r * 0.25, Glyphs._c(Palette.INFERNO_LAVA, flash))  # The censer.
		"gatekeeper":
			var body := Rect2(o + Vector2(-r * 0.7, -r * 0.6), Vector2(r * 1.4, r * 1.5))
			ci.draw_rect(body.grow(1.5), INK)
			ci.draw_rect(body, Glyphs._c(Color(0.40, 0.38, 0.40), flash))  # Ash-grey hide.
			ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 0.75), Vector2(r * 0.9, r * 0.2)), Glyphs._c(RUST, flash))  # The iron collar.
			ci.draw_rect(Rect2(o + Vector2(-r * 0.35, -r * 1.15), Vector2(r * 0.7, r * 0.45)), Glyphs._c(Color(0.30, 0.28, 0.30), flash))  # Head.
			ci.draw_rect(Rect2(o + Vector2(-r * 0.22, -r * 1.0), Vector2(r * 0.44, r * 0.1)), Glyphs._c(Palette.INFERNO_LAVA_LIGHT, flash))  # Eyes.
			for k in 2:
				var sx := -1.0 if k == 0 else 1.0
				ci.draw_rect(Rect2(o + Vector2(sx * r * 0.9 - r * 0.2, r * 0.3), Vector2(r * 0.4, r * 0.3)), Glyphs._c(RUST, flash))  # Manacles.
				ci.draw_line(o + Vector2(sx * r * 0.9, r * 0.6), o + Vector2(sx * r * 1.3, r * 1.1), Glyphs._c(InfernoGlyphs.IRON, flash), 2.0)  # Trailing chains.
		_:
			return false
	return true


## Moloch without his art: a colossal bull-headed demon, an iron furnace door
## in his belly glowing lava; `molten` runs lava cracks over him (phase 3).
static func draw_moloch(ci: CanvasItem, o: Vector2, r: float, flash: bool, molten: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.8, -r * 0.7), Vector2(r * 1.6, r * 1.7))
	ci.draw_rect(body.grow(1.5), INK)
	ci.draw_rect(body, Glyphs._c(Palette.INFERNO_DEMON_DARK, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 0.2), Vector2(r * 0.8, r * 0.7)), Glyphs._c(Color(0.16, 0.14, 0.16), flash))  # The furnace door.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 0.05), Vector2(r * 0.6, r * 0.45)), Glyphs._c(Palette.INFERNO_LAVA, flash))  # Its fire.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 1.25), Vector2(r * 0.9, r * 0.6)), Glyphs._c(Palette.INFERNO_DEMON, flash))  # The bull's head.
	ci.draw_line(o + Vector2(-r * 0.4, -r * 1.15), o + Vector2(-r * 1.0, -r * 1.6), Glyphs._c(Palette.BONE, flash), 4.0)  # Horns.
	ci.draw_line(o + Vector2(r * 0.4, -r * 1.15), o + Vector2(r * 1.0, -r * 1.6), Glyphs._c(Palette.BONE, flash), 4.0)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 1.05), Vector2(r * 0.6, r * 0.12)), Glyphs._c(Palette.INFERNO_LAVA_LIGHT, flash))  # Eyes.
	if molten:
		ci.draw_line(body.position + Vector2(r * 0.2, r * 0.2), body.position + Vector2(r * 0.6, r * 1.4), Palette.INFERNO_LAVA_LIGHT, 1.5)
		ci.draw_line(body.position + Vector2(r * 1.4, r * 0.3), body.position + Vector2(r * 1.1, r * 1.5), Palette.INFERNO_LAVA_LIGHT, 1.5)
