## CastleSanguisGlyphs — code-drawn shapes of CASTLE SANGUIS (Act VII, Stage
## 21; GDD §15.0 "Castle Sanguis (Act VII phase 2)"): the fallbacks of its
## obstacles (their obstacles/<kind>_<size> PNGs replace them), of its kinds
## (the Chiropteran, the Chiropteran King; the Blood Bearer wears the thrall's
## art), of Queen Carmilla and the Elder (bosses/carmilla, bosses/elder) and of
## the Banquet's blood fountain (structures/blood_fountain). The Court's look:
## blood red, black velvet, candle gold and moonlit silver, castle stone;
## never the undead's bone and teal on an enemy. Purely visual; no RNG. Only
## drawn when a sprite is missing.
class_name CastleSanguisGlyphs
extends RefCounted

## Sprite key of a blood fountain (CastleSanguisDirector).
const FOUNTAIN_SPRITE: String = "structures/blood_fountain"
## Outline ink (the blood ramp's darkest).
const INK := Color(0.071, 0.024, 0.039)
## Grey castle stone (walls, well, statues, pillars).
const STONE := Color(0.36, 0.36, 0.40)
## Dark oak of the tables and barrels.
const OAK := Color(0.28, 0.18, 0.12)
## Grey-brown fur of the bat-folk.
const FUR := Color(0.40, 0.34, 0.30)
## Pale vampire skin (moonlit).
const PALE := Color(0.86, 0.85, 0.88)


# =====================================================================================
# Kinds (fallbacks)
# =====================================================================================

## Draws a Castle Sanguis kind; false for any other kind (CourtGlyphs then
## draws the shared ones).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		CastleSanguisEnemyData.CHIROPTERAN:
			_bat_wings(ci, o, r * 1.7, flash)
			SpriteBank.draw_disc(ci, o, r, INK)
			SpriteBank.draw_disc(ci, o, r - 1.5, Glyphs._c(FUR, flash))  # The furred body.
			SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.7), r * 0.42, Glyphs._c(FUR.darkened(0.2), flash))  # The bat head.
			ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 0.8), Vector2(2, 2)), Palette.COURT_BLOOD_LIGHT)  # Red eyes.
			ci.draw_rect(Rect2(o + Vector2(r * 0.15, -r * 0.8), Vector2(2, 2)), Palette.COURT_BLOOD_LIGHT)
		CastleSanguisEnemyData.KING:
			_bat_wings(ci, o, r * 1.9, flash)
			SpriteBank.draw_disc(ci, o, r, INK)
			SpriteBank.draw_disc(ci, o, r - 2.0, Glyphs._c(FUR, flash))
			SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.7), r * 0.4, Glyphs._c(FUR.darkened(0.25), flash))
			for k in 3:
				ci.draw_rect(Rect2(o + Vector2(-r * 0.3 + float(k) * r * 0.25, -r * 1.25), Vector2(3, 5)), Glyphs._c(Palette.BONE, flash))  # The bone crown.
			ci.draw_rect(Rect2(o + Vector2(-r * 0.2, -r * 0.8), Vector2(3, 2)), Palette.COURT_BLOOD_LIGHT)
			ci.draw_rect(Rect2(o + Vector2(r * 0.1, -r * 0.8), Vector2(3, 2)), Palette.COURT_BLOOD_LIGHT)
		_:
			return false
	return true


## A pair of leathery bat wings spread behind a body at `o`, `span` px wide.
static func _bat_wings(ci: CanvasItem, o: Vector2, span: float, flash: bool) -> void:
	var wing := Glyphs._c(Palette.COURT_VELVET, flash)
	ci.draw_rect(Rect2(o + Vector2(-span, -span * 0.35), Vector2(span * 0.85, span * 0.45)), wing)
	ci.draw_rect(Rect2(o + Vector2(span * 0.15, -span * 0.35), Vector2(span * 0.85, span * 0.45)), wing)
	ci.draw_rect(Rect2(o + Vector2(-span, -span * 0.35), Vector2(span * 0.85, 2)), Glyphs._c(Palette.COURT_VELVET_LIGHT, flash))
	ci.draw_rect(Rect2(o + Vector2(span * 0.15, -span * 0.35), Vector2(span * 0.85, 2)), Glyphs._c(Palette.COURT_VELVET_LIGHT, flash))


## Queen Carmilla (fallback): a pale queen in a blood-red gown and black
## velvet, a gold crown; `alpha` fades her. Fallback only.
static func draw_carmilla(ci: CanvasItem, o: Vector2, r: float, flash: bool, alpha: float) -> void:
	SpriteBank.draw_disc(ci, o, r, Color(INK, alpha))
	SpriteBank.draw_disc(ci, o, r - 2.0, Glyphs._c(Color(Palette.COURT_BLOOD, alpha), flash))  # The gown.
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.2), r * 0.5, Glyphs._c(Color(Palette.COURT_VELVET, alpha), flash))  # The velvet bodice.
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.85), r * 0.36, Glyphs._c(Color(PALE, alpha), flash))  # Her face.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 1.3), Vector2(r * 0.6, 3)), Color(Palette.GOLD, alpha))  # The crown.


## The Elder (fallback): a hunched, bat-winged horror, grey and gaunt with
## red eyes. Fallback only.
static func draw_elder(ci: CanvasItem, o: Vector2, r: float, flash: bool, alpha: float) -> void:
	_bat_wings(ci, o, r * 1.8, flash)
	SpriteBank.draw_disc(ci, o, r, Color(INK, alpha))
	SpriteBank.draw_disc(ci, o, r - 2.0, Glyphs._c(Color(Palette.COURT_MOON_DARK, alpha), flash))  # The gaunt grey body.
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.7), r * 0.4, Glyphs._c(Color(PALE.darkened(0.2), alpha), flash))  # The bald head.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.2, -r * 0.75), Vector2(3, 3)), Palette.COURT_BLOOD_LIGHT)  # Red eyes.
	ci.draw_rect(Rect2(o + Vector2(r * 0.1, -r * 0.75), Vector2(3, 3)), Palette.COURT_BLOOD_LIGHT)


## The Elder's first form, the vampire lord (fallback until the
## "bosses/elder_vampire" art lands): a tall, pale lord in a high-collared
## black-and-crimson cloak with a blood-red blade; `alpha` fades him. Fallback only.
static func draw_elder_lord(ci: CanvasItem, o: Vector2, r: float, flash: bool, alpha: float) -> void:
	SpriteBank.draw_disc(ci, o, r, Color(INK, alpha))
	SpriteBank.draw_disc(ci, o, r - 2.0, Glyphs._c(Color(Palette.COURT_VELVET_DARK, alpha), flash))  # The black cloak.
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.1), r * 0.55, Glyphs._c(Color(Palette.COURT_BLOOD_DARK, alpha), flash))  # The crimson lining.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.55, -r * 1.05), Vector2(r * 1.1, r * 0.3)), Glyphs._c(Color(Palette.COURT_BLOOD, alpha), flash))  # The high collar.
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.85), r * 0.34, Glyphs._c(Color(PALE, alpha), flash))  # The pale face.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.15, -r * 0.9), Vector2(2, 2)), Palette.COURT_BLOOD_LIGHT)  # Red eyes.
	ci.draw_rect(Rect2(o + Vector2(r * 0.05, -r * 0.9), Vector2(2, 2)), Palette.COURT_BLOOD_LIGHT)
	ci.draw_rect(Rect2(o + Vector2(r * 0.6, -r * 0.6), Vector2(3, r * 1.4)), Glyphs._c(Color(Palette.COURT_BLOOD_LIGHT, alpha), flash))  # The blood-blade.


## A blood fountain (fallback): a stone basin brimming red (pale and dry
## while denied); `alpha` fades it in. Fallback only.
static func draw_fountain(ci: CanvasItem, o: Vector2, r: float, dry: bool, alpha: float) -> void:
	SpriteBank.draw_disc(ci, o, r * 0.75, Color(INK, alpha))
	SpriteBank.draw_disc(ci, o, r * 0.68, Color(STONE, alpha))
	SpriteBank.draw_disc(ci, o, r * 0.5, Color(Palette.COURT_MOON_DARK if dry else Palette.COURT_BLOOD, alpha))
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.2), r * 0.18, Color(STONE.lightened(0.2), alpha))  # The spout.
	if not dry:
		SpriteBank.draw_disc(ci, o + Vector2(-r * 0.15, -r * 0.1), r * 0.12, Color(Palette.COURT_BLOOD_LIGHT, alpha))


# =====================================================================================
# Obstacles (fallbacks)
# =====================================================================================

## Draws a Castle Sanguis obstacle kind; false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"castle_wall", "feast_table", "sarcophagus":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var face := STONE
			if o.kind == "feast_table":
				face = OAK
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), face)
			ci.draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(rect.size.x - 4, 3)), face.lightened(0.25))
			if o.kind == "feast_table":
				ci.draw_rect(Rect2(c - Vector2(o.half.x * 0.8, 2.0), Vector2(o.half.x * 1.6, 4.0)), Palette.COURT_BLOOD)  # The red runner.
		"castle_well", "gargoyle_statue", "candelabra", "wine_barrel", "crypt_pillar", "blood_urn":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			var body := STONE
			match o.kind:
				"wine_barrel":
					body = OAK
				"candelabra":
					body = Palette.GOLD.darkened(0.35)
				"blood_urn":
					body = Palette.COURT_BLOOD_DARK
			SpriteBank.draw_disc(ci, c, r - 1.5, body)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, body.lightened(0.25))
			if o.kind == "castle_well" or o.kind == "blood_urn":
				SpriteBank.draw_disc(ci, c, r * 0.45, Palette.COURT_BLOOD)  # Blood within.
			elif o.kind == "candelabra":
				SpriteBank.draw_disc(ci, c, r * 0.3, Palette.GOLD)  # The candle flames.
		_:
			return false
	return true
