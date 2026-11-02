## RavensmoorGlyphs — code-drawn shapes of Ravensmoor (Act VII, Stage 19; GDD
## §15.0 "Ravensmoor (Act VII phase 2)"): the fallbacks of the stage's six
## obstacle kinds (moor cairns, black pines, grave crosses, village fences,
## thralls' cottages, the old church's broken walls), of its kinds (the Ghoul,
## Old Greymane, the sleeping coffin) and of Vargr when their sprites are
## missing. Peat, moonlit stone, black velvet and blood (CourtGlyphs' colours);
## never the undead's bone or soul teal. Rects, lines and texture discs only (no
## polygon redrawn every frame). Purely visual.
class_name RavensmoorGlyphs
extends RefCounted

## Ink of the outlines (the blood ink).
const INK := Color(0.071, 0.024, 0.039)
## Rotten wood of the fences and cottages.
const WOOD := Color(0.26, 0.19, 0.15)
## Old thatch.
const THATCH := Color(0.38, 0.31, 0.20)
## Grey moor stone.
const STONE := Color(0.34, 0.34, 0.38)
## Black pine needles.
const PINE := Color(0.10, 0.14, 0.13)
## Grey-brown wolf fur (never purple).
const FUR := Color(0.42, 0.38, 0.34)
## A ghoul's grey skin.
const GHOUL_SKIN := Color(0.56, 0.56, 0.54)


## Draws one of Ravensmoor's obstacle kinds at its collision shape. Returns
## false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"moor_cairn", "black_pine", "grave_cross":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			match o.kind:
				"moor_cairn":
					SpriteBank.draw_disc(ci, c, r - 1.5, STONE)
					SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.4, Palette.COURT_MOON_DARK)
					SpriteBank.draw_disc(ci, c + Vector2(r * 0.35, r * 0.2), r * 0.3, Color(0.26, 0.26, 0.30))
				"black_pine":
					SpriteBank.draw_disc(ci, c, r - 1.0, PINE)
					SpriteBank.draw_disc(ci, c + Vector2(-r * 0.25, -r * 0.3), r * 0.5, Color(0.16, 0.21, 0.19))
					SpriteBank.draw_disc(ci, c, r * 0.18, WOOD)  # The trunk.
				_:
					SpriteBank.draw_disc(ci, c, r - 1.5, Color(0.22, 0.22, 0.25))
					ci.draw_rect(Rect2(c + Vector2(-1.5, -r * 0.8), Vector2(3.0, r * 1.5)), STONE)  # The cross.
					ci.draw_rect(Rect2(c + Vector2(-r * 0.5, -r * 0.4), Vector2(r, 3.0)), STONE)
		"village_fence", "thatch_cottage", "church_ruin":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			var face := WOOD
			if o.kind == "thatch_cottage":
				face = THATCH
			elif o.kind == "church_ruin":
				face = STONE
			ci.draw_rect(rect.grow(-1.5), face)
			var step := 6.0 if o.kind == "village_fence" else 10.0  # Pales / beams / courses (px).
			var line := INK if o.kind != "church_ruin" else Color(0.22, 0.22, 0.25)
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
			if o.kind == "thatch_cottage":
				SpriteBank.draw_disc(ci, c, minf(o.half.x, o.half.y) * 0.35, Color(0.95, 0.72, 0.30, 0.8))  # A lit window.
		_:
			return false
	return true


## Draws Ravensmoor kind `kind` (CourtGlyphs.draw_enemy() asks first). Returns
## false for any other kind.
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"ghoul":
			var body := Rect2(o + Vector2(-r * 0.9, -r * 0.4), Vector2(r * 1.8, r * 0.9))
			ci.draw_rect(body.grow(1.0), INK)
			ci.draw_rect(body, Glyphs._c(GHOUL_SKIN, flash))  # Hunched on all fours.
			ci.draw_rect(Rect2(o + Vector2(r * 0.4, -r * 0.9), Vector2(r * 0.7, r * 0.6)), Glyphs._c(Color(0.62, 0.62, 0.60), flash))  # Head.
			ci.draw_rect(Rect2(o + Vector2(r * 0.75, -r * 0.75), Vector2(2, 2)), Palette.COURT_BLOOD_LIGHT)  # Eye.
			ci.draw_rect(Rect2(o + Vector2(r * 0.6, -r * 0.45), Vector2(r * 0.5, 2.0)), Glyphs._c(Palette.COURT_BLOOD, flash))  # The bloody maw.
		"old_greymane":
			SpriteBank.draw_disc(ci, o, r * 1.05, Glyphs._c(INK, flash))
			SpriteBank.draw_disc(ci, o, r, Glyphs._c(FUR, flash))
			SpriteBank.draw_disc(ci, o + Vector2(r * 0.35, -r * 0.45), r * 0.45, Glyphs._c(Color(0.62, 0.60, 0.58), flash))  # The grey head.
			ci.draw_rect(Rect2(o + Vector2(r * 0.5, -r * 0.4), Vector2(r * 0.35, r * 0.15)), Palette.COURT_BLOOD_LIGHT)  # The maw.
			ci.draw_line(o + Vector2(-r * 0.6, -r * 0.2), o + Vector2(-r * 0.1, r * 0.4), Glyphs._c(Palette.COURT_MOON_LIGHT, flash), 1.5)  # An old scar.
		"sleeping_coffin":
			CourtGlyphs.draw_coffin(ci, o, r, flash, false)
		_:
			return false
	return true


## Vargr without his art: a towering black-furred wolf king in a red cloak, an
## iron crown; `eater` lights his maw red (the Moon-Eater).
static func draw_vargr(ci: CanvasItem, o: Vector2, r: float, flash: bool, eater: bool) -> void:
	var cloak := Rect2(o + Vector2(-r * 0.9, -r * 0.5), Vector2(r * 1.8, r * 1.5))
	ci.draw_rect(cloak.grow(1.5), INK)
	ci.draw_rect(cloak, Glyphs._c(Palette.COURT_BLOOD_DARK, flash))  # The red cloak.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.6, -r * 0.8), Vector2(r * 1.2, r * 1.4)), Glyphs._c(Color(0.20, 0.19, 0.19), flash))  # Black fur.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.3), Vector2(r * 0.8, r * 0.6)), Glyphs._c(Color(0.26, 0.25, 0.25), flash))  # Head.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.45), Vector2(r * 0.8, r * 0.15)), Glyphs._c(Palette.COURT_MOON_DARK, flash))  # The iron crown.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.25, -r * 1.15), Vector2(r * 0.5, r * 0.1)), Glyphs._c(Palette.GOLD, flash))  # Eyes.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.2, -r * 0.9), Vector2(r * 0.4, r * 0.12)), Palette.COURT_BLOOD_LIGHT if eater else Glyphs._c(INK, flash))  # The maw.
