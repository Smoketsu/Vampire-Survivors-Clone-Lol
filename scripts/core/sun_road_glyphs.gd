## SunRoadGlyphs — code-drawn shapes of THE ROAD TO THE SUN (Act V, Stage 15;
## GDD §15.0 "The Road to the Sun (Act V phase 2)"): the fallbacks of its
## obstacles (their obstacles/<kind>_<size> PNGs replace them), of its kinds
## (the Kitsune, the Sōhei, the Kirin) and of Amaterasu (bosses/amaterasu), and
## the colours of the stage's light: the sun's gold and white, the fox-fire's
## cold blue. The Shogunate's look (lacquer red, indigo, sakura, gold) and
## never the undead's bone and teal on an enemy. Purely visual; no RNG. Only
## drawn when a sprite is missing (and for the code-drawn marks named on each
## function).
class_name SunRoadGlyphs
extends RefCounted

## Outline ink (the lacquer ramp's darkest).
const INK := Color(0.102, 0.043, 0.047)
## A Kitsune's fox-fire (cold pale blue; never the undead's teal).
const FOX_FIRE := Color(0.62, 0.80, 1.0)
## The sun's white-gold core (Amaterasu's light, her beams).
const SUN_WHITE := Color(1.0, 0.96, 0.82)
## The sun's deep gold (her disc's rim, the noon heat).
const SUN_GOLD := Color(1.0, 0.74, 0.22)
## The setting sun's red (her sunset beam, the red light of the last phase).
const SUN_RED := Color(0.95, 0.30, 0.16)
## Vermilion lacquer of the torii posts.
const VERMILION := Color(0.86, 0.26, 0.16)
## Moss and cedar green of the Sacred Forest.
const CEDAR := Color(0.16, 0.26, 0.18)
## Pale cloud white of the High Plain of Heaven.
const CLOUD := Color(0.88, 0.88, 0.92)
## Weathered shrine stone.
const STONE := Color(0.50, 0.49, 0.46)


# =====================================================================================
# Kinds (fallbacks)
# =====================================================================================

## Draws a Road to the Sun kind; false for any other kind (ShogunateGlyphs
## then draws the shared ones).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		SunRoadEnemyData.KITSUNE, SunRoadEnemyData.FOX_FIRE:
			draw_kitsune(ci, o, r, flash, Color.WHITE if kind == SunRoadEnemyData.KITSUNE else Color(0.86, 0.92, 1.0, 0.8))
		SunRoadEnemyData.SOHEI:
			ci.draw_circle(o, r, INK)
			ci.draw_circle(o, r - 1.5, Glyphs._c(Palette.SHOGUN_INDIGO_DARK, flash))  # Dark robes.
			ci.draw_circle(o + Vector2(0, -r * 0.7), r * 0.45, Glyphs._c(Palette.IVORY, flash))  # White hood.
			ci.draw_line(o + Vector2(r * 0.9, r), o + Vector2(r * 0.9, -r * 1.8), Glyphs._c(Palette.SHOGUN_LACQUER_DARK, flash), 2.0)  # Naginata shaft.
			ci.draw_line(o + Vector2(r * 0.9, -r * 1.8), o + Vector2(r * 1.3, -r * 2.5), Glyphs._c(ShogunateGlyphs.STEEL, flash), 2.0)  # Blade.
		SunRoadEnemyData.KIRIN:
			ci.draw_circle(o, r, INK)
			ci.draw_circle(o, r - 2.0, Glyphs._c(SUN_GOLD, flash))  # Golden scales.
			ci.draw_circle(o + Vector2(r * 0.7, -r * 0.6), r * 0.4, Glyphs._c(SUN_WHITE, flash))  # Head and mane.
			ci.draw_line(o + Vector2(r * 0.8, -r * 0.9), o + Vector2(r * 1.1, -r * 1.6), Glyphs._c(Palette.IVORY, flash), 2.0)  # The single horn.
		_:
			return false
	return true


## A Kitsune (or her fox-fire image, `tint`): a white kimono with a sakura
## sash, pale tails fanned behind. Fallback only.
static func draw_kitsune(ci: CanvasItem, o: Vector2, r: float, flash: bool, tint: Color = Color.WHITE) -> void:
	for i in 3:
		var a := PI * 0.75 + float(i) * 0.35
		ci.draw_circle(o + Vector2.from_angle(a) * r * 0.9, r * 0.45, Glyphs._c(Color(Palette.IVORY, tint.a) * tint, flash))  # Tails.
	ci.draw_circle(o, r, Color(INK, tint.a))
	ci.draw_circle(o, r - 1.5, Glyphs._c(Color(Palette.IVORY, tint.a) * tint, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.8, -r * 0.1), Vector2(r * 1.6, r * 0.3)), Glyphs._c(Color(Palette.SHOGUN_SAKURA, tint.a), flash))  # Sash.
	ci.draw_circle(o + Vector2(0, -r * 0.8), r * 0.4, Glyphs._c(Color(Palette.IVORY, tint.a) * tint, flash))  # Fox mask.


## Amaterasu (fallback): a woman robed in white and gold before a sun disc;
## `pose` 1 raises the mirror. `alpha` fades her. Fallback only.
static func draw_amaterasu(ci: CanvasItem, o: Vector2, r: float, flash: bool, alpha: float, pose: int) -> void:
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(o + Vector2(-r * 1.6, -r * 2.6), Vector2(r * 3.2, r * 3.2)), false, Color(SUN_GOLD, 0.35 * alpha))  # The sun behind her.
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.9, r * 1.1), o + Vector2(r * 0.9, r * 1.1), o + Vector2(r * 0.4, -r * 0.6), o + Vector2(-r * 0.4, -r * 0.6)]),
			Glyphs._c(Color(SUN_WHITE, alpha), flash))
	ci.draw_circle(o + Vector2(0, -r * 0.85), r * 0.34, Glyphs._c(Color(Palette.IVORY, alpha), flash))  # Her face.
	var m := o + (Vector2(r * 0.9, -r * 1.3) if pose == 1 else Vector2(r * 0.7, -r * 0.2))
	ci.draw_circle(m, r * 0.32, Color(SUN_GOLD, alpha))  # The mirror.
	ci.draw_circle(m, r * 0.2, Color(SUN_WHITE, alpha))


# =====================================================================================
# Obstacles (fallbacks)
# =====================================================================================

## Draws a Road to the Sun obstacle kind; false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"stone_marker", "step_wall":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), STONE)
			ci.draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(rect.size.x - 4, 3)), STONE.lightened(0.25))
		"torii_post", "sacred_cedar", "moss_rock", "komainu", "cloud_rock", "sun_mirror":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, INK)
			var body := STONE
			match o.kind:
				"torii_post":
					body = VERMILION
				"sacred_cedar":
					body = CEDAR
				"moss_rock":
					body = Color(0.30, 0.36, 0.26)
				"cloud_rock":
					body = CLOUD.darkened(0.25)
				"sun_mirror":
					body = Palette.GOLD
			ci.draw_circle(c, r - 1.5, body)
			ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, body.lightened(0.25))
			if o.kind == "sacred_cedar":
				ci.draw_arc(c, r * 0.8, 0.0, TAU, 16, Palette.IVORY, 1.5)  # The shimenawa rope.
		_:
			return false
	return true
