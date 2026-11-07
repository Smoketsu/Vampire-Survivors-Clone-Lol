## SkidRowGlyphs — the code-drawn fallbacks of Skid Row's own art (Act VIII,
## Stage 22; GDD §15.0 "Skid Row (Act VIII phase 2)"), drawn only when a
## sprite PNG is missing: Big Sal's Armoured Limo, Big Sal, the bounty board
## (asked first by CityGlyphs.draw_enemy()), Don Marrow and his limo cover
## (BossDonMarrow), and Hearse Run's spectral hearse (HearseRun). Simple
## textured shapes in the City palette with city-ink outlines (SpriteBank's
## disc and CityGlyphs' white texel: no polygon redrawn every frame). Purely
## visual.
class_name SkidRowGlyphs
extends RefCounted

## Body colour of the limo and the hearse (black lacquer).
const LACQUER := Color(0.09, 0.09, 0.11)
## Trim colour of the limo, the board and Don Marrow (gold).
const TRIM := Palette.GOLD
## Colour of Don Marrow's white suit.
const SUIT := Color(0.88, 0.86, 0.8)


## Draws Skid Row kind `kind` when it has no sprite. Returns false when it is
## not one of Skid Row's own kinds (CityGlyphs then draws the shared ones).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		SkidRowEnemyData.LIMO:
			draw_limo(ci, o, r, flash)
		SkidRowEnemyData.BIG_SAL:
			_man(ci, o, r, Color(0.2, 0.2, 0.24) if not flash else Color.WHITE, Color(0.86, 0.72, 0.6))
			CityGlyphs._box(ci, Rect2(o + Vector2(r * 0.5, -r * 1.2), Vector2(r * 0.3, r * 1.6)), Palette.CITY_CONCRETE_LIGHT, true)  # The sledgehammer.
		SkidRowEnemyData.BOUNTY_BOARD:
			CityGlyphs._box(ci, Rect2(o + Vector2(-r * 0.9, -r * 0.2), Vector2(r * 0.2, r * 1.0)), Palette.CITY_CONCRETE, true)  # A leg.
			CityGlyphs._box(ci, Rect2(o + Vector2(r * 0.7, -r * 0.2), Vector2(r * 0.2, r * 1.0)), Palette.CITY_CONCRETE, true)  # A leg.
			CityGlyphs._box(ci, Rect2(o + Vector2(-r * 1.2, -r * 1.4), Vector2(r * 2.4, r * 1.4)), Color(0.86, 0.8, 0.62) if not flash else Color.WHITE, true)  # The board.
			for k in 3:
				CityGlyphs._box(ci, Rect2(o + Vector2(-r + float(k) * r * 0.7, -r * 1.2), Vector2(r * 0.5, r * 0.7)), Color(0.95, 0.92, 0.82), false)  # A wanted poster.
			CityGlyphs._box(ci, Rect2(o + Vector2(-r * 1.2, -r * 1.5), Vector2(r * 2.4, r * 0.18)), TRIM, false)  # The gold trim.
		_:
			return false
	return true


## The Armoured Limo seen from above-front, facing right, centred on `o`.
static func draw_limo(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var hl := r * 1.9
	var hw := r * 0.85
	CityGlyphs._box(ci, Rect2(o - Vector2(hl, hw), Vector2(hl, hw) * 2.0), LACQUER if not flash else Color.WHITE, true)
	CityGlyphs._box(ci, Rect2(o + Vector2(-hl * 0.6, -hw * 0.7), Vector2(hl * 1.1, hw * 1.4)), Color(0.16, 0.17, 0.2), false)  # The long roof.
	CityGlyphs._box(ci, Rect2(o + Vector2(hl * 0.55, -hw * 0.75), Vector2(hl * 0.15, hw * 1.5)), Color(0.24, 0.28, 0.34), false)  # The windscreen.
	CityGlyphs._box(ci, Rect2(o + Vector2(-hl, -hw), Vector2(hl * 2.0, 2.0)), TRIM, false)  # Gold trim.


## Don Marrow seen from the front: a white suit and a gold cane; with
## `covered` his limo stands in front of him (drawn by the boss).
static func draw_don(ci: CanvasItem, r: float, flash: bool, _covered: bool) -> void:
	_man(ci, Vector2.ZERO, r, SUIT if not flash else Color.WHITE, Color(0.84, 0.7, 0.58))
	CityGlyphs._box(ci, Rect2(Vector2(r * 0.7, -r * 0.6), Vector2(r * 0.15, r * 1.5)), TRIM, true)  # The gold cane.


## Hearse Run's spectral hearse at `o` driving along unit `dir`, `half_length`
## x `half_width` px, faded by `alpha` (0..1). The art faces right and is
## mirrored for a hearse driving left (never turned upside down; on a vertical
## lane it keeps its side view, like the City's vehicles). Draws in `ci`'s
## current space.
static func draw_hearse(ci: CanvasItem, o: Vector2, dir: Vector2, half_length: float, half_width: float, alpha: float, tex: Texture2D) -> void:
	ci.draw_set_transform(o, 0.0, Vector2(-1.0 if dir.x < -0.01 else 1.0, 1.0))
	if tex != null:
		var s := tex.get_size()
		ci.draw_texture(tex, (-s * 0.5).round(), Color(1.0, 1.0, 1.0, alpha))
	else:
		var ghost := Color(0.55, 0.95, 0.8, 0.55 * alpha)  # Spectral soul-green.
		ci.draw_texture_rect(CityGlyphs.white(), Rect2(Vector2(-half_length, -half_width), Vector2(half_length, half_width) * 2.0), false, ghost)
		ci.draw_texture_rect(CityGlyphs.white(), Rect2(Vector2(-half_length * 0.5, -half_width * 0.6), Vector2(half_length * 1.0, half_width * 1.2)), false, Color(0.1, 0.1, 0.12, 0.6 * alpha))  # The coffin bay.
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A simple standing man (a disc body, a head), outlined.
static func _man(ci: CanvasItem, o: Vector2, r: float, body: Color, skin: Color) -> void:
	SpriteBank.draw_disc(ci, o + Vector2(1.5, 2.0), r, Color(0.0, 0.0, 0.0, 0.3))
	SpriteBank.draw_disc(ci, o, r, CityGlyphs.INK)
	SpriteBank.draw_disc(ci, o, r - 1.5, body)
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.55), r * 0.42, skin)
