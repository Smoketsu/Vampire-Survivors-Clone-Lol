## PandemoniumGlyphs — code-drawn shapes of PANDEMONIUM (Act VI, Stage 18; GDD
## §15.0 "Pandemonium (Act VI phase 2)"): the fallbacks of its obstacles (their
## obstacles/<kind>_<size> PNGs replace them), of its kinds (the Fallen Angel,
## the Fallen Seraph General) and of the Morning Star (bosses/morning_star and
## bosses/morning_star_beast), and the colours of the stage: iron, the holy
## light of the Angel's beams. The Inferno's look (obsidian, lava, demon skin,
## charm pink) with gold; never the undead's bone and teal on an enemy. Purely
## visual; no RNG. Only drawn when a sprite is missing.
class_name PandemoniumGlyphs
extends RefCounted

## Outline ink (the obsidian ramp's darkest).
const INK := Color(0.043, 0.039, 0.063)
## Black iron of the city (braziers, chain posts, walls, rails).
const IRON := Color(0.26, 0.26, 0.30)
## Grey ash stone of the cathedral.
const ASH_STONE := Color(0.30, 0.29, 0.32)
## The Angel's pale gold light (his light beams, his sword).
const LIGHT := Color(1.0, 0.95, 0.70)
## The bone of the skull pillars and the Beast's skull.
const SKULL := Color(0.78, 0.74, 0.62)


# =====================================================================================
# Kinds (fallbacks)
# =====================================================================================

## Draws a Pandemonium kind; false for any other kind (InfernoGlyphs then
## draws the shared ones).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		PandemoniumEnemyData.FALLEN_ANGEL:
			_wings(ci, o, r * 1.6, 1, flash)
			ci.draw_circle(o, r, INK)
			ci.draw_circle(o, r - 1.5, Glyphs._c(Palette.INFERNO_OBSIDIAN_DARK, flash))  # Black bodysuit.
			ci.draw_circle(o + Vector2(0, -r * 0.8), r * 0.42, Glyphs._c(Palette.IVORY, flash))  # Silver hair, pale face.
			ci.draw_arc(o + Vector2(0, -r * 1.5), r * 0.4, 0.0, TAU, 12, Glyphs._c(Palette.GOLD, flash), 1.5)  # The cracked halo.
			ci.draw_line(o + Vector2(r * 0.9, r), o + Vector2(r * 0.9, -r * 1.8), Glyphs._c(Palette.INFERNO_LAVA, flash), 2.0)  # The burning spear.
		PandemoniumEnemyData.SERAPH_GENERAL:
			_wings(ci, o, r * 1.4, 2, flash)
			ci.draw_circle(o, r, INK)
			ci.draw_circle(o, r - 2.0, Glyphs._c(Palette.INFERNO_OBSIDIAN, flash))  # Black and gold plate.
			ci.draw_arc(o, r - 3.0, -PI, 0.0, 16, Glyphs._c(Palette.GOLD, flash), 2.0)
			ci.draw_circle(o + Vector2(0, -r * 0.7), r * 0.35, Glyphs._c(Palette.IVORY, flash))  # His face.
			ci.draw_line(o + Vector2(r * 0.8, r * 0.6), o + Vector2(r * 1.4, -r * 1.2), Glyphs._c(Palette.INFERNO_LAVA_LIGHT, flash), 3.0)  # The burning greatsword.
		_:
			return false
	return true


## `pairs` pairs of black wings fanned behind a body at `o`, `span` px wide.
static func _wings(ci: CanvasItem, o: Vector2, span: float, pairs: int, flash: bool) -> void:
	for k in pairs:
		var lift := float(k) * span * 0.35  # Each pair a little higher.
		for s: float in [-1.0, 1.0]:
			ci.draw_line(o + Vector2(0, -lift * 0.5), o + Vector2(span * s, -span * 0.6 - lift), Glyphs._c(Palette.INFERNO_OBSIDIAN_LIGHT, flash), 3.0)
			ci.draw_line(o + Vector2(span * s, -span * 0.6 - lift), o + Vector2(span * 0.8 * s, span * 0.2 - lift), Glyphs._c(Palette.INFERNO_OBSIDIAN, flash), 2.0)


## The Morning Star's Angel (fallback): a tall black-armoured figure with six
## wings, a halo and a burning sword; `alpha` fades him. Fallback only.
static func draw_angel(ci: CanvasItem, o: Vector2, r: float, flash: bool, alpha: float) -> void:
	_wings(ci, o, r * 1.8, 3, flash)
	ci.draw_circle(o, r, Color(INK, alpha))
	ci.draw_circle(o, r - 2.0, Glyphs._c(Color(Palette.INFERNO_OBSIDIAN, alpha), flash))
	ci.draw_circle(o + Vector2(0, -r * 0.8), r * 0.34, Glyphs._c(Color(Palette.IVORY, alpha), flash))  # His face, silver hair.
	ci.draw_arc(o + Vector2(0, -r * 1.2), r * 0.6, 0.0, TAU, 20, Color(Palette.GOLD, alpha), 2.0)  # The halo.
	ci.draw_line(o + Vector2(r * 0.6, r * 0.9), o + Vector2(r * 0.6, -r * 1.4), Color(LIGHT, alpha), 3.0)  # The burning sword.


## The Morning Star's Beast (fallback): a huge horned skull on a black body
## with lava cracks. Fallback only.
static func draw_beast(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	_wings(ci, o, r * 1.6, 2, flash)
	ci.draw_circle(o, r, INK)
	ci.draw_circle(o, r - 2.0, Glyphs._c(Palette.INFERNO_OBSIDIAN_DARK, flash))
	ci.draw_line(o + Vector2(-r * 0.5, r * 0.2), o + Vector2(r * 0.4, r * 0.6), Glyphs._c(Palette.INFERNO_LAVA, flash), 2.0)  # A lava crack.
	ci.draw_circle(o + Vector2(0, -r * 0.7), r * 0.5, Glyphs._c(SKULL, flash))  # The skull.
	ci.draw_circle(o + Vector2(-r * 0.18, -r * 0.75), r * 0.1, LIGHT)  # Burning eyes.
	ci.draw_circle(o + Vector2(r * 0.18, -r * 0.75), r * 0.1, LIGHT)
	for s: float in [-1.0, 1.0]:
		ci.draw_line(o + Vector2(r * 0.4 * s, -r * 1.0), o + Vector2(r * 0.9 * s, -r * 1.5), Glyphs._c(SKULL.darkened(0.3), flash), 3.0)  # The horns.


# =====================================================================================
# Obstacles (fallbacks)
# =====================================================================================

## Draws a Pandemonium obstacle kind; false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"iron_wall", "bridge_rail", "ash_pew":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var face := IRON if o.kind != "ash_pew" else ASH_STONE
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), face)
			ci.draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(rect.size.x - 4, 3)), face.lightened(0.25))
		"iron_brazier", "chain_post", "ash_column", "burning_censer", "skull_pillar", "obsidian_shard":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			var body := IRON
			match o.kind:
				"ash_column":
					body = ASH_STONE
				"skull_pillar":
					body = SKULL
				"obsidian_shard":
					body = Palette.INFERNO_OBSIDIAN
			SpriteBank.draw_disc(ci, c, r - 1.5, body)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, body.lightened(0.25))
			if o.kind == "iron_brazier" or o.kind == "burning_censer" or o.kind == "obsidian_shard":
				SpriteBank.draw_disc(ci, c, r * 0.3, Palette.INFERNO_LAVA)  # The fire / a molten core.
		_:
			return false
	return true
