## WitchwoodGlyphs — code-drawn shapes of the Witchwood (Act VII, Stage 20; GDD
## §15.0 "The Witchwood (Act VII phase 2)"): the fallbacks of the stage's four
## obstacle kinds (fen snags, standing stones, witches' cauldrons, charm
## fences), of its kinds (the Crimson Witch, the Bloated Thrall, the Bog Mother,
## Isolde's sisters, the hex stone), of Isolde when their sprites are missing,
## and the Fen's black water (draw_fen_pool(), the floor's pools). Blood red,
## black velvet and moonlit silver (the Court's colours) with the fen's black
## water and weed green; never the undead's bone or soul teal. Rects, lines and
## texture discs only (no polygon redrawn every frame). Purely visual.
class_name WitchwoodGlyphs
extends RefCounted

## Sprite key of a hex stone (assets/sprites/structures/).
const STONE_SPRITE: String = "structures/hex_stone"
## Sprite key of a broken hex stone's stump (the dead ground).
const STONE_BROKEN_SPRITE: String = "structures/hex_stone_broken"
## Sprite key of Isolde, drawn tinted for each of her sisters.
const SISTER_SPRITE: String = "bosses/isolde"
## The fen's black water (shallow).
const FEN_WATER := Color(0.07, 0.10, 0.11)
## The fen's deep water.
const FEN_DEEP := Color(0.03, 0.05, 0.06)
## Pondweed green (the Bog Mother's ropes, the reeds).
const WEED := Color(0.18, 0.29, 0.13)
## Light pondweed green (the ropes' glint, the marks).
const WEED_LIGHT := Color(0.31, 0.48, 0.21)
## Drowned skin (the Bog Mother).
const DROWNED := Color(0.43, 0.55, 0.48)
## Dark wood (snags, fences, staffs).
const WOOD := Color(0.14, 0.10, 0.07)
## Grey-green standing stone.
const STONE := Color(0.31, 0.35, 0.32)
## Outline ink (the Court's blood ink).
const INK := Color(0.071, 0.024, 0.039)


# =====================================================================================
# Kinds
# =====================================================================================

## Draws one of the Witchwood's kinds. Returns false for any other kind
## (CourtGlyphs then draws the shared kinds).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"crimson_witch":
			_witch(ci, o, r, flash)
		"bloated_thrall":
			_bloated(ci, o, r, flash)
		"bog_mother":
			_bog_mother(ci, o, r, flash)
		"isolde_sister":
			draw_isolde(ci, o, r, flash, Color.WHITE)
		"hex_stone":
			draw_hex_stone(ci, o, r, flash, false)
		_:
			return false
	return true


## The Crimson Witch: a crimson pointed hat, a velvet gown, a staff.
static func _witch(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var gown := Color.WHITE if flash else Palette.COURT_VELVET
	SpriteBank.draw_disc(ci, o + Vector2(0, r * 0.3), r * 1.0, INK)
	SpriteBank.draw_disc(ci, o + Vector2(0, r * 0.3), r * 0.9, gown)
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.6), r * 0.5, CourtGlyphs.PALE)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.9, -r * 1.05), Vector2(r * 1.8, r * 0.3)), Palette.COURT_BLOOD)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 1.9), Vector2(r * 0.6, r * 0.9)), Palette.COURT_BLOOD)
	ci.draw_line(o + Vector2(r * 1.1, -r * 1.4), o + Vector2(r * 1.1, r * 1.2), WOOD, 2.0)
	SpriteBank.draw_disc(ci, o + Vector2(r * 1.1, -r * 1.5), 2.5, Palette.COURT_BLOOD_LIGHT)


## The Bloated Thrall: a vast pale belly with a red wound.
static func _bloated(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o, r * 1.05, INK)
	SpriteBank.draw_disc(ci, o, r, Color.WHITE if flash else CourtGlyphs.PALE)
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.2, r * 0.15), r * 0.3, Palette.COURT_BLOOD)
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.95), r * 0.38, CourtGlyphs.PALE)
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.12, -r * 0.85), r * 0.1, Palette.COURT_BLOOD_LIGHT)


## The Bog Mother: a vast drowned witch, weed hanging from her.
static func _bog_mother(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o + Vector2(0, r * 0.2), r * 1.05, INK)
	SpriteBank.draw_disc(ci, o + Vector2(0, r * 0.2), r * 0.95, Color.WHITE if flash else Palette.COURT_VELVET_DARK)
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.75), r * 0.42, DROWNED)
	for i in 5:
		var x := -r * 0.8 + r * 0.4 * float(i)
		ci.draw_line(o + Vector2(x, -r * 0.6), o + Vector2(x * 1.1, r * 0.9), WEED, 2.0)
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.15, -r * 0.8), 2.0, Palette.COURT_MOON_LIGHT)
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.15, -r * 0.8), 2.0, Palette.COURT_MOON_LIGHT)


## Isolde (and her sisters, `tint`): a tall black hat with a gold crescent, a
## crimson corset, red hair.
static func draw_isolde(ci: CanvasItem, o: Vector2, r: float, flash: bool, tint: Color) -> void:
	var gown := Color.WHITE if flash else Palette.COURT_VELVET * tint
	SpriteBank.draw_disc(ci, o + Vector2(0, r * 0.3), r * 1.0, INK)
	SpriteBank.draw_disc(ci, o + Vector2(0, r * 0.3), r * 0.9, gown)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.35, -r * 0.2), Vector2(r * 0.7, r * 0.4)), Palette.COURT_BLOOD * tint)
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 0.6), r * 0.48, CourtGlyphs.PALE)
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.4, -r * 0.4), r * 0.3, Palette.COURT_BLOOD_DARK * tint)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.8, -r * 1.05), Vector2(r * 1.6, r * 0.25)), Palette.COURT_VELVET_DARK)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.25, -r * 2.0), Vector2(r * 0.5, r * 1.0)), Palette.COURT_VELVET_DARK)
	SpriteBank.draw_disc(ci, o + Vector2(0, -r * 1.9), r * 0.18, CourtGlyphs.CANDLE)


## A hex stone (or, `broken`, its stump): grey-green stone, red runes.
static func draw_hex_stone(ci: CanvasItem, o: Vector2, r: float, flash: bool, broken: bool) -> void:
	var h := r * (1.0 if broken else 2.6)  # Height (px).
	var rect := Rect2(o + Vector2(-r * 0.7, -h + r * 0.4), Vector2(r * 1.4, h))
	ci.draw_rect(Rect2(rect.position + Vector2(3, 4), rect.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(rect, INK)
	ci.draw_rect(rect.grow(-1.5), Color.WHITE if flash else STONE)
	if broken:
		ci.draw_rect(Rect2(o + Vector2(r * 0.8, -r * 0.1), Vector2(r * 1.6, r * 0.6)), Color(STONE, 0.8))
		return
	var y := rect.position.y + 4.0
	while y < rect.end.y - 4.0:
		ci.draw_line(Vector2(rect.position.x + 3.0, y), Vector2(rect.end.x - 3.0, y + 2.0), Palette.COURT_BLOOD_LIGHT, 1.0)
		y += 7.0


# =====================================================================================
# Obstacles and the fen
# =====================================================================================

## Draws one of the Witchwood's obstacle kinds at its collision shape. Returns
## false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"fen_snag", "standing_stone", "witch_cauldron":
			var r := o.radius
			var face := WOOD
			var hi := Color(0.24, 0.18, 0.12)
			if o.kind == "standing_stone":
				face = STONE
				hi = Color(0.45, 0.50, 0.46)
			elif o.kind == "witch_cauldron":
				face = Color(0.12, 0.11, 0.15)
				hi = Color(0.22, 0.20, 0.27)
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, face)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, hi)
			if o.kind == "witch_cauldron":
				SpriteBank.draw_disc(ci, c, r * 0.6, Palette.COURT_BLOOD)  # The brew.
			elif o.kind == "fen_snag":
				SpriteBank.draw_disc(ci, c + Vector2(r * 0.2, r * 0.3), r * 0.25, WEED)  # Moss.
		"charm_fence":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), WOOD)
			var step := 9.0  # Stakes (px).
			if rect.size.x >= rect.size.y:
				var x := rect.position.x + step
				while x < rect.end.x - 2.0:
					ci.draw_line(Vector2(x, rect.position.y + 2.0), Vector2(x, rect.end.y - 2.0), Color(Palette.COURT_BLOOD, 0.8), 1.0)
					x += step
			else:
				var y := rect.position.y + step
				while y < rect.end.y - 2.0:
					ci.draw_line(Vector2(rect.position.x + 2.0, y), Vector2(rect.end.x - 2.0, y), Color(Palette.COURT_BLOOD, 0.8), 1.0)
					y += step
		_:
			return false
	return true


## One pool of the Fen's black water at `c` (radius `r` px): a dark disc, its
## deeper middle and a few reeds at its rim (`h` a hash for their places).
## Textures and lines only (the floor redraws on a cell change, not per frame).
static func draw_fen_pool(ci: CanvasItem, c: Vector2, r: float, h: int) -> void:
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(r, r * 0.8), Vector2(r * 2.0, r * 1.6)), false, Color(FEN_WATER, 0.9))
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(r * 0.6, r * 0.45), Vector2(r * 1.2, r * 0.9)), false, Color(FEN_DEEP, 0.9))
	ci.draw_line(c + Vector2(-r * 0.3, -r * 0.2), c + Vector2(r * 0.05, -r * 0.2), Color(Palette.COURT_MOON_DARK, 0.35), 1.0)  # A glint.
	for i in 4:
		var a := float((h >> (i * 4)) % 16) / 16.0 * TAU
		var p := c + Vector2(cos(a) * r * 0.95, sin(a) * r * 0.75)
		ci.draw_line(p, p + Vector2(-1.0, -6.0), WEED, 1.0)
		ci.draw_line(p + Vector2(2.0, 0.0), p + Vector2(3.0, -5.0), WEED_LIGHT, 1.0)
