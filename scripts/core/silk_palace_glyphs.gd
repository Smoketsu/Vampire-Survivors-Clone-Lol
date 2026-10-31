## SilkPalaceGlyphs — code-drawn shapes of THE PALACE OF SILK AND ASH (Act VI,
## Stage 17; GDD §15.0 "The Palace of Silk and Ash (Act VI phase 2)"): the
## fallbacks of its obstacles (their obstacles/<kind>_<size> PNGs replace them;
## the velvet divans are InfernoGlyphs'), of its kinds (the
## Lilim Witch, the Twin Succubi) and of Lilith (bosses/lilith and
## bosses/lilith_demon), and the colours of the court: rose marble, velvet,
## mirror glass. The Inferno's look (obsidian, lava, demon skin, charm pink);
## never the undead's bone and teal on an enemy. Purely visual; no RNG. Only
## drawn when a sprite is missing.
class_name SilkPalaceGlyphs
extends RefCounted

## Outline ink (the obsidian ramp's darkest).
const INK := Color(0.043, 0.039, 0.063)
## Mirror glass (pale violet).
const GLASS := Color(0.66, 0.60, 0.78)
## Gilt of the frames and candelabra.
const GILT := Color(0.85, 0.66, 0.23)
## Black-rose crimson.
const ROSE := Color(0.61, 0.18, 0.37)
## Thorny black stems.
const THORN := Color(0.12, 0.10, 0.15)
## Rose marble of the columns.
const MARBLE := Color(0.48, 0.39, 0.44)


# =====================================================================================
# Kinds (fallbacks)
# =====================================================================================

## Draws a Palace kind; false for any other kind (InfernoGlyphs then draws the
## shared ones).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		SilkPalaceEnemyData.LILIM_WITCH:
			ci.draw_circle(o, r, INK)
			ci.draw_circle(o, r - 1.5, Glyphs._c(Palette.INFERNO_DEMON, flash))  # The crimson gown.
			ci.draw_circle(o + Vector2(0, -r * 0.8), r * 0.42, Glyphs._c(Palette.IVORY, flash))  # White hair.
			ci.draw_line(o + Vector2(r * 1.0, r), o + Vector2(r * 1.0, -r * 2.0), Glyphs._c(Palette.INFERNO_OBSIDIAN_LIGHT, flash), 2.0)  # The staff.
			SpriteBank.draw_disc(ci, o + Vector2(r * 1.0, -r * 2.2), 2.5, Palette.INFERNO_LAVA)  # Its burning eye.
		SilkPalaceEnemyData.TWIN_NAAMAH, SilkPalaceEnemyData.TWIN_AGRAT:
			var skin := Palette.INFERNO_DEMON if kind == SilkPalaceEnemyData.TWIN_NAAMAH else Palette.CRIMSON
			ci.draw_line(o + Vector2(-r * 0.4, -r * 0.3), o + Vector2(-r * 1.8, -r * 1.3), Glyphs._c(Palette.INFERNO_DEMON_DARK, flash), 4.0)  # Bat wings.
			ci.draw_line(o + Vector2(r * 0.4, -r * 0.3), o + Vector2(r * 1.8, -r * 1.3), Glyphs._c(Palette.INFERNO_DEMON_DARK, flash), 4.0)
			ci.draw_circle(o, r, INK)
			ci.draw_circle(o, r - 1.5, Glyphs._c(skin, flash))
			ci.draw_rect(Rect2(o + Vector2(-r * 0.6, -r * 0.1), Vector2(r * 1.2, r * 0.5)), Glyphs._c(Palette.INFERNO_OBSIDIAN, flash))  # The corset.
			ci.draw_line(o + Vector2(-r * 0.3, -r * 0.8), o + Vector2(-r * 0.2, -r * 1.4), Glyphs._c(Palette.GOLD, flash), 2.0)  # The crown.
			ci.draw_line(o + Vector2(r * 0.3, -r * 0.8), o + Vector2(r * 0.2, -r * 1.4), Glyphs._c(Palette.GOLD, flash), 2.0)
		_:
			return false
	return true


## Lilith (fallback): a pale queen in crimson before great black wings; `demon`
## her true form (four wings, lava cracks). Fallback only.
static func draw_lilith(ci: CanvasItem, o: Vector2, r: float, flash: bool, demon: bool) -> void:
	var wing := Glyphs._c(Palette.INFERNO_OBSIDIAN_DARK if not demon else Palette.INFERNO_DEMON_DARK, flash)
	for s in [-1.0, 1.0]:
		ci.draw_line(o + Vector2(s * r * 0.4, -r * 0.5), o + Vector2(s * r * 2.2, -r * 1.6), wing, 6.0)
		if demon:
			ci.draw_line(o + Vector2(s * r * 0.4, -r * 0.2), o + Vector2(s * r * 2.0, -r * 0.4), wing, 5.0)
	ci.draw_circle(o, r, INK)
	ci.draw_circle(o, r - 2.0, Glyphs._c(Palette.INFERNO_DEMON if demon else Palette.CRIMSON, flash))  # The gown / her demon skin.
	ci.draw_circle(o + Vector2(0, -r * 0.9), r * 0.38, Glyphs._c(Palette.INFERNO_DEMON_LIGHT if demon else Palette.IVORY, flash))  # Her face.
	ci.draw_line(o + Vector2(-r * 0.3, -r * 1.2), o + Vector2(-r * 0.6, -r * 1.6), Glyphs._c(INK, flash), 3.0)  # Horns.
	ci.draw_line(o + Vector2(r * 0.3, -r * 1.2), o + Vector2(r * 0.6, -r * 1.6), Glyphs._c(INK, flash), 3.0)
	ci.draw_line(o + Vector2(-r * 0.2, -r * 1.3), o + Vector2(r * 0.2, -r * 1.3), Glyphs._c(Palette.GOLD, flash), 2.0)  # The crown.


# =====================================================================================
# Obstacles (fallbacks)
# =====================================================================================

## Draws a Palace obstacle kind; false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"mirror_wall":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), GILT)
			ci.draw_rect(rect.grow(-3.0), GLASS)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 4), Vector2(3, 3)), Color.WHITE)  # A glint.
		"black_rosebush", "palace_mirror", "candelabra", "rose_column":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, INK)
			match o.kind:
				"black_rosebush":
					ci.draw_circle(c, r - 1.5, THORN)
					for i in 4:
						ci.draw_circle(c + Vector2.from_angle(TAU * float(i) / 4.0 + 0.4) * r * 0.5, r * 0.25, ROSE)  # The roses.
				"rose_column":
					ci.draw_circle(c, r - 1.5, MARBLE)
					ci.draw_arc(c, r - 2.0, 0.0, TAU, 16, GILT, 1.5)  # The gilt capital.
				"palace_mirror":
					ci.draw_circle(c, r - 1.5, GILT)
					ci.draw_circle(c, r - 3.5, GLASS)
					ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.2, Color.WHITE)
				_:
					ci.draw_circle(c, r - 1.5, Palette.INFERNO_OBSIDIAN)
					for i in 3:
						SpriteBank.draw_disc(ci, c + Vector2((float(i) - 1.0) * r * 0.5, -r * 0.3), 2.0, Palette.INFERNO_CHARM)  # Pink flames.
		_:
			return false
	return true


# =====================================================================================
# Thralls (Enthrall: the Temptation spell, the Succubus class)
# =====================================================================================

## A thrall (Glyphs.draw_summon() "enthralled:<kind>"): the foe's own art in
## any act's folder, tinted TemptData.TINT, a violet-pink heart over its head;
## its glyph without art.
static func draw_enthralled(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> void:
	var top := -r * 1.6  # The head's top (px), for a body without art.
	var drawn := false
	for folder: String in ["enemies/", "inferno/", "shogunate/", "pantheon/", "empire/", "eye/"]:
		var key := folder + kind
		if SpriteBank.has(key):
			SpriteBank.draw(ci, key, o, flash, TemptData.TINT)
			top = -SpriteBank.drawn_height(key) * (0.5 - SpriteData.CENTER_OFFSET)
			drawn = true
			break
	if not drawn:
		Glyphs.draw_enemy(ci, kind, o, r, flash, false)
	InfernoGlyphs.draw_heart(ci, Vector2(o.x, o.y + top - 7.0), 4.0, TemptData.HEART_COLOR)
