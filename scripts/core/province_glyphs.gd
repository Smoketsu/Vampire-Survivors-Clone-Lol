## ProvinceGlyphs — code-drawn shapes of the Burning Province (Act V, Stage 13;
## GDD §15.0 "The Burning Province (Act V phase 2)"): the fallback glyphs of its
## kinds (the Kunoichi, the Kappa, Shuten-dōji) and of Kage when their sprites
## are missing, the stage's obstacle kinds without art (rice sheaves, bamboo
## stands, burning houses, shrine halls), and the small effects drawn every
## frame that stay code on purpose: a sake barrel in flight, Kage's kunai
## chains, a smoke cloud and the smoke over a blinded summon's eyes. Smoke and
## blind marks are soft discs (SpriteBank.draw_disc(), a texture that batches:
## no polygon redrawn per frame, the Web GL rule). Purely visual; no RNG.
class_name ProvinceGlyphs
extends RefCounted

## Obstacle kind id of the burning house (ProvinceDirector flares fire beside it).
const BURNING_HOUSE: String = "burning_house"
## Smoke grey of a smoke cloud (indigo-tinted ash).
const SMOKE := Color(0.36, 0.37, 0.44)
## Thatch straw.
const STRAW := Color(0.74, 0.62, 0.34)
## Dark timber.
const TIMBER := Color(0.28, 0.18, 0.11)
## Ember orange of the flames.
const EMBER := Color(1.0, 0.48, 0.14)
## Kappa green.
const KAPPA_GREEN := Color(0.30, 0.52, 0.30)


# =====================================================================================
# Kinds (fallbacks when the sprite art is missing)
# =====================================================================================

## Draws Province kind `kind` (false for any other kind: ShogunateGlyphs goes on).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		ProvinceEnemyData.KUNOICHI:
			_kunoichi(ci, o, r, flash)
		ProvinceEnemyData.KAPPA:
			_kappa(ci, o, r, flash)
		ProvinceEnemyData.SHUTEN_DOJI:
			_shuten(ci, o, r, flash)
		ProvinceEnemyData.KAGE_CLONE:
			draw_kage(ci, o, r, flash, KageCloneKit.SHADOW_TINT)
		_:
			return false
	return true


## A Kunoichi: an indigo-black figure with a lacquer-red sash and scarf, a tanto.
static func _kunoichi(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.45, -r * 0.3), Vector2(r * 0.9, r * 1.25))
	ci.draw_rect(body.grow(1.5), Glyphs._c(Palette.SHOGUN_INDIGO_LIGHT, flash))  # The rim.
	ci.draw_rect(body, Glyphs._c(Palette.SHOGUN_INDIGO_DARK, flash))
	ci.draw_rect(Rect2(body.position + Vector2(0, r * 0.45), Vector2(body.size.x, r * 0.2)), Glyphs._c(Palette.SHOGUN_LACQUER, flash))  # Sash.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.38, -r * 0.95), Vector2(r * 0.76, r * 0.66)), Glyphs._c(Palette.SHOGUN_INDIGO_DARK, flash))  # Hood.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.28, -r * 0.7), Vector2(r * 0.56, r * 0.14)), Glyphs._c(Color(0.86, 0.72, 0.58), flash))  # Eyes.
	ci.draw_line(o + Vector2(-r * 0.3, -r * 0.3), o + Vector2(-r * 1.2, -r * 0.1), Glyphs._c(Palette.SHOGUN_LACQUER_LIGHT, flash), 2.0)  # Scarf tail.
	ci.draw_line(o + Vector2(r * 0.5, r * 0.3), o + Vector2(r * 1.1, -r * 0.3), Glyphs._c(ShogunateGlyphs.STEEL, flash), 2.0)  # Tanto.


## A Kappa: a squat green river imp with a turtle shell and a water dish on its head.
static func _kappa(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o + Vector2(0, r * 0.2), r * 0.95, ShogunateGlyphs.INK)
	SpriteBank.draw_disc(ci, o + Vector2(0, r * 0.2), r * 0.85, Glyphs._c(Color(0.45, 0.36, 0.20), flash))  # Shell.
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.55), r * 0.55, Glyphs._c(KAPPA_GREEN, flash))  # Head.
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.95), r * 0.3, Glyphs._c(Palette.SHOGUN_INDIGO_LIGHT, flash))  # The water dish.
	ci.draw_rect(Rect2(o + Vector2(r * 0.25, -r * 0.6), Vector2(r * 0.4, r * 0.18)), Glyphs._c(Palette.GOLD, flash))  # Beak.


## Shuten-dōji: a huge crimson oni with a white mane, a sake barrel on his shoulder.
static func _shuten(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.7, -r * 0.55), Vector2(r * 1.4, r * 1.45))
	ci.draw_rect(body.grow(1.5), ShogunateGlyphs.INK)
	ci.draw_rect(body, Glyphs._c(Palette.SHOGUN_LACQUER_LIGHT, flash))
	ci.draw_rect(Rect2(body.position + Vector2(0, body.size.y * 0.62), Vector2(body.size.x, body.size.y * 0.24)), Glyphs._c(Palette.SHOGUN_INDIGO, flash))  # Hakama.
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.9), r * 0.6, Glyphs._c(Color(0.92, 0.90, 0.86), flash))  # The white mane.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.35, -r * 1.0), Vector2(r * 0.7, r * 0.5)), Glyphs._c(Palette.SHOGUN_LACQUER, flash))  # Face.
	ci.draw_line(o + Vector2(-r * 0.3, -r * 1.1), o + Vector2(-r * 0.5, -r * 1.55), Glyphs._c(Palette.SHOGUN_SAKURA_LIGHT, flash), 3.0)  # Horns.
	ci.draw_line(o + Vector2(r * 0.3, -r * 1.1), o + Vector2(r * 0.5, -r * 1.55), Glyphs._c(Palette.SHOGUN_SAKURA_LIGHT, flash), 3.0)
	draw_barrel(ci, o + Vector2(-r * 0.75, -r * 0.6), r * 0.35)  # The barrel on his shoulder.
	ci.draw_line(o + Vector2(r * 0.8, r * 0.7), o + Vector2(r * 1.15, -r * 1.2), Glyphs._c(Color(0.22, 0.22, 0.25), flash), 6.0)  # The kanabō.


## Kage (and her shadows, `tint`): a slender indigo-black figure with a long
## lacquer-red scarf and a ninjato across her back.
static func draw_kage(ci: CanvasItem, o: Vector2, r: float, flash: bool, tint: Color = Color.WHITE) -> void:
	var body := Rect2(o + Vector2(-r * 0.45, -r * 0.45), Vector2(r * 0.9, r * 1.5))
	ci.draw_rect(body.grow(1.5), Glyphs._c(Palette.SHOGUN_INDIGO_LIGHT * tint, flash))
	ci.draw_rect(body, Glyphs._c(Palette.SHOGUN_INDIGO_DARK * tint, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.15), Vector2(r * 0.8, r * 0.75)), Glyphs._c(Palette.SHOGUN_INDIGO_DARK * tint, flash))  # Hood.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 0.9), Vector2(r * 0.6, r * 0.15)), Glyphs._c(Color(0.86, 0.72, 0.58) * tint, flash))  # Eyes.
	ci.draw_line(o + Vector2(-r * 0.3, -r * 0.4), o + Vector2(-r * 1.4, -r * 0.1), Glyphs._c(Palette.SHOGUN_LACQUER * tint, flash), 3.0)  # Scarf.
	ci.draw_line(o + Vector2(-r * 0.5, r * 0.5), o + Vector2(r * 0.7, -r * 1.2), Glyphs._c(ShogunateGlyphs.STEEL * tint, flash), 2.0)  # Ninjato.


# =====================================================================================
# Obstacles (fallbacks when the sprite art is missing)
# =====================================================================================

## Draws one of the Burning Province's obstacle kinds at its collision shape.
## Returns false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"rice_sheaves":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, Color(0.36, 0.27, 0.12))
			SpriteBank.draw_disc(ci, c, r - 1.5, STRAW)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.25, -r * 0.3), r * 0.4, STRAW.lightened(0.2))
		"bamboo_stand":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			for k in 6:
				var p := c + Vector2.from_angle(TAU * float(k) / 6.0 + float(o.variant % 7) * 0.3) * r * 0.6  # One cane.
				ci.draw_rect(Rect2(p - Vector2(2.5, 2.5), Vector2(5, 5)), ShogunateGlyphs.INK)
				ci.draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color(0.46, 0.62, 0.30))
			SpriteBank.draw_disc(ci, c, r * 0.5, Color(0.30, 0.46, 0.22, 0.85))
		"burning_house", "shrine_hall":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var roof := STRAW if o.kind == "burning_house" else Palette.SHOGUN_LACQUER_DARK  # Thatch / lacquered roof.
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, TIMBER)
			ci.draw_rect(rect.grow(-2.0), roof)
			ci.draw_line(Vector2(rect.position.x + 2.0, c.y), Vector2(rect.end.x - 2.0, c.y), roof.darkened(0.35), 2.0)  # The ridge.
			if o.kind == "burning_house":
				for k in 3:
					var q := rect.position + Vector2(rect.size.x * (0.25 + 0.25 * float(k)), rect.size.y * 0.3)
					SpriteBank.draw_disc(ci, q, 5.0, Color(EMBER, 0.9))
					SpriteBank.draw_disc(ci, q + Vector2(0, -2), 2.5, Color(1.0, 0.85, 0.4))
		_:
			return false
	return true


# =====================================================================================
# Effects (code on purpose: small, simple, drawn every frame)
# =====================================================================================

## A sake barrel of radius `r` at local `o`: staves, two iron hoops, a red seal.
static func draw_barrel(ci: CanvasItem, o: Vector2, r: float) -> void:
	SpriteBank.draw_disc(ci, o, r + 1.0, TIMBER.darkened(0.4))
	SpriteBank.draw_disc(ci, o, r, Color(0.62, 0.44, 0.24))
	ci.draw_rect(Rect2(o + Vector2(-r, -r * 0.45), Vector2(r * 2.0, 1.5)), Color(0.20, 0.20, 0.22))
	ci.draw_rect(Rect2(o + Vector2(-r, r * 0.35), Vector2(r * 2.0, 1.5)), Color(0.20, 0.20, 0.22))
	SpriteBank.draw_disc(ci, o, r * 0.35, Palette.SHOGUN_LACQUER)


## Kage's kunai chain from local `from` to local `to` (her hand to the kunai,
## or to the hooked summon when `taut`): steel links and the kunai's head.
static func draw_chain(ci: CanvasItem, from: Vector2, to: Vector2, taut: bool) -> void:
	var span := to - from
	var n := clampi(int(span.length() / 8.0), 1, 60)  # Links.
	for i in n + 1:
		var p := from + span * (float(i) / float(n))
		SpriteBank.draw_disc(ci, p, 1.6, ShogunateGlyphs.STEEL if i % 2 == 0 else Color(0.45, 0.48, 0.55))
	var d := span.normalized() if span.length() > 0.1 else Vector2.RIGHT
	ci.draw_line(to - d * 6.0, to + d * 3.0, ShogunateGlyphs.STEEL, 3.0 if taut else 2.0)  # The kunai.


## A smoke cloud at `o` of radius `r` (`k` = life left 1..0, `t` the game time
## for its slow churn): a few overlapping soft grey discs.
static func draw_smoke(ci: CanvasItem, o: Vector2, r: float, k: float, t: float) -> void:
	var a := clampf(k * 1.4, 0.0, 1.0) * 0.55  # Opacity of each puff.
	for i in 6:
		var ang := TAU * float(i) / 6.0 + t * 0.4
		var p := o + Vector2.from_angle(ang) * r * 0.45
		SpriteBank.draw_disc(ci, p, r * 0.6, Color(SMOKE, a * 0.7))
	SpriteBank.draw_disc(ci, o, r * 0.7, Color(SMOKE.lightened(0.15), a))


## The smoke over a blinded summon's eyes (radius `r`; `t` the game time).
static func draw_blinded(ci: CanvasItem, r: float, t: float) -> void:
	var y := -r * 1.5
	for i in 3:
		var p := Vector2((float(i) - 1.0) * r * 0.55, y + sin(t * 3.0 + float(i)) * 1.5)
		SpriteBank.draw_disc(ci, p, r * 0.45, Color(SMOKE, 0.7))
