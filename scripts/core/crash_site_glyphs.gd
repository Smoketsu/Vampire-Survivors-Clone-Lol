## CrashSiteGlyphs — code-drawn shapes of the Crash Site (Act IX, Stage 25; GDD
## §15.0 "The Crash Site (Act IX phase 2)"): the fallbacks of the stage's three
## obstacle kinds (the capital's rubble, the scout ship's torn hull shards, the
## glass spires) and of its kinds (the Burrower, the Acid Spitter, the Brood
## Matriarch) when their sprites are missing (the egg draws itself:
## BroodEggKit). The Brood's green-black chitin and acid green, hull white and
## gunmetal (ConcordGlyphs' colours); never the necromancer's violet and bone.
## Rects, lines and texture discs only (no polygon redrawn every frame).
## ConcordGlyphs asks these first. Purely visual.
class_name CrashSiteGlyphs
extends RefCounted

## Ink of the outlines (the Concord's starfield black).
const INK := Palette.CONCORD_INK
## Broken grey stone of the capital's ruins.
const STONE := Color(0.32, 0.31, 0.33)
## Lit stone.
const STONE_LIGHT := Color(0.46, 0.45, 0.47)
## Glassed rock / the glass spires' glass.
const GLASS := Color(0.55, 0.78, 0.74)
## Slate-dark burrower armour.
const SLATE := Color(0.22, 0.24, 0.30)
## Cream claws.
const CLAW := Palette.CONCORD_HIVE_BONE


## Draws one of the Crash Site's obstacle kinds at its collision shape.
## Returns false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"crash_rubble", "glass_spire":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			if o.kind == "crash_rubble":
				SpriteBank.draw_disc(ci, c, r - 1.5, STONE)
				SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.4, STONE_LIGHT)
				SpriteBank.draw_disc(ci, c + Vector2(r * 0.35, r * 0.2), r * 0.25, Palette.CONCORD_GUNMETAL)
			else:
				SpriteBank.draw_disc(ci, c, r - 1.5, Color(GLASS, 0.85))
				ci.draw_rect(Rect2(c + Vector2(-2.0, -r * 1.8), Vector2(4.0, r * 1.8)), INK)  # The spire.
				ci.draw_rect(Rect2(c + Vector2(-1.0, -r * 1.7), Vector2(2.0, r * 1.6)), GLASS)
		"crash_hull_shard":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), Palette.CONCORD_HULL_SHADE)
			var step := 10.0  # Plate seams (px).
			if rect.size.x >= rect.size.y:
				var x := rect.position.x + step
				while x < rect.end.x - 2.0:
					ci.draw_line(Vector2(x, rect.position.y + 2.0), Vector2(x, rect.end.y - 2.0), Color(Palette.CONCORD_GUNMETAL, 0.7), 1.0)
					x += step
			else:
				var y := rect.position.y + step
				while y < rect.end.y - 2.0:
					ci.draw_line(Vector2(rect.position.x + 2.0, y), Vector2(rect.end.x - 2.0, y), Color(Palette.CONCORD_GUNMETAL, 0.7), 1.0)
					y += step
		_:
			return false
	return true


## Draws the Crash Site's kind `kind` when its sprite is missing. Returns false
## for any other kind.
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"burrower":
			SpriteBank.draw_disc(ci, o, r * 1.05, Glyphs._c(INK, flash))
			SpriteBank.draw_disc(ci, o, r * 0.95, Glyphs._c(SLATE, flash))  # Armoured back.
			SpriteBank.draw_disc(ci, o + Vector2(-r * 0.2, -r * 0.3), r * 0.45, Glyphs._c(Palette.CONCORD_GUNMETAL, flash))
			ci.draw_rect(Rect2(o + Vector2(r * 0.5, -r * 0.7), Vector2(r * 0.8, 2.0)), Glyphs._c(CLAW, flash))  # Digging claws.
			ci.draw_rect(Rect2(o + Vector2(r * 0.5, r * 0.4), Vector2(r * 0.8, 2.0)), Glyphs._c(CLAW, flash))
			ci.draw_rect(Rect2(o + Vector2(r * 0.25, -r * 0.2), Vector2(2, 2)), Palette.CONCORD_LASER)  # Its eye.
		"acid_spitter":
			SpriteBank.draw_disc(ci, o, r * 1.05, Glyphs._c(INK, flash))
			SpriteBank.draw_disc(ci, o, r * 0.9, Glyphs._c(Palette.CONCORD_CHITIN, flash))
			SpriteBank.draw_disc(ci, o + Vector2(-r * 0.45, -r * 0.2), r * 0.6, Glyphs._c(Palette.CONCORD_PLASMA_DARK, flash))  # The acid sac.
			ci.draw_rect(Rect2(o + Vector2(r * 0.3, -r * 0.4), Vector2(2, 2)), Palette.CONCORD_PLASMA)  # Eyes.
		"brood_matriarch":
			SpriteBank.draw_disc(ci, o + Vector2(-r * 0.9, -r * 0.4), r * 0.8, Color(Palette.CONCORD_CHITIN_LIGHT, 0.6))  # Wings.
			SpriteBank.draw_disc(ci, o + Vector2(r * 0.9, -r * 0.4), r * 0.8, Color(Palette.CONCORD_CHITIN_LIGHT, 0.6))
			SpriteBank.draw_disc(ci, o, r * 1.05, Glyphs._c(INK, flash))
			SpriteBank.draw_disc(ci, o, r * 0.95, Glyphs._c(Palette.CONCORD_CHITIN, flash))
			SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.6), r * 0.5, Glyphs._c(Palette.CONCORD_CHITIN_LIGHT, flash))  # Head.
			ci.draw_rect(Rect2(o + Vector2(-r * 0.25, -r * 0.7), Vector2(2, 2)), Palette.CONCORD_PLASMA)  # Eyes.
			ci.draw_rect(Rect2(o + Vector2(r * 0.15, -r * 0.7), Vector2(2, 2)), Palette.CONCORD_PLASMA)
			ci.draw_rect(Rect2(o + Vector2(r * 0.6, r * 0.1), Vector2(r * 0.7, 2.0)), Glyphs._c(CLAW, flash))  # Claws.
		_:
			return false
	return true
