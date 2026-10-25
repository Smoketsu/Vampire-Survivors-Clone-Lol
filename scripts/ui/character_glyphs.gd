## CharacterGlyphs — draws the playable characters (CharacterData) in the
## world (Necromancer._draw) and as picker portraits (CharacterPicker).
## The Gravecaller is the classic necromancer (Glyphs.draw_necromancer,
## unchanged). Every other character draws its own art
## (assets/sprites/player/<id>.png, CharacterData "sprite") once it exists;
## until then the necromancer's art is drawn tinted with the character's
## spell-school colour over a soft school aura, and without any art a glyph
## variant (robe, eyes and staff orb in the school colour) is drawn.
## A cosmetic skin without its own art (SkinGlyphs) draws a character
## without art through draw_player() too, passing the skin's palette as
## `skin_tint` (it multiplies the school tint), so the skin keeps that
## character's look rather than the Gravecaller's.
## Purely visual: no gameplay state is read or written.
class_name CharacterGlyphs
extends RefCounted

## How far the school tint is lightened toward white before it multiplies
## the necromancer sprite (0 = full tint, 1 = untinted).
const SPRITE_TINT_LIGHTEN: float = 0.25  # TUNING (not in GDD)
## Fraction of a portrait's height the character is drawn at.
const PORTRAIT_FILL: float = 0.8  # TUNING (not in GDD)
## Fraction of a portrait's side used by the starting-spell icon badge.
const BADGE_FILL: float = 0.34  # TUNING (not in GDD)
## Alpha (0-1) of the dark veil over a locked character's portrait.
const LOCK_VEIL: float = 0.62  # TUNING (not in GDD)
## Scale (layout px per art px) of the pixel padlock (MaskIcon) on a locked portrait.
const LOCK_ICON_SCALE: int = 2  # TUNING (not in GDD)


## Draws character `id` centred near `o` (body radius `r`, hit `flash`).
## `skin_tint` (a skin palette's tint, SkinGlyphs; white = none) multiplies
## the colours of the character's own art or of its tinted fallback.
static func draw_player(ci: CanvasItem, id: String, o: Vector2, r: float, flash: bool, skin_tint: Color = Color.WHITE, recolour: String = "") -> void:
	if id == CharacterData.DEFAULT_ID or not CharacterModifiers.is_known(id):
		Glyphs.draw_necromancer(ci, o, r, flash, recolour)
		return
	var d := CharacterModifiers.def(id)  # Character row.
	var key := String(d["sprite"])  # Own art key.
	if SpriteBank.draw(ci, key, o, flash, skin_tint, recolour):
		return  # The character's own art exists.
	var tint: Color = d["tint"]
	_draw_aura(ci, o, r, tint)
	if SpriteBank.draw(ci, "player/necromancer", o, flash, tint.lerp(Color.WHITE, SPRITE_TINT_LIGHTEN) * skin_tint, recolour):
		return  # The necromancer's art, tinted with the school colour.
	_draw_glyph(ci, o, r, flash, tint, skin_tint)


## Sprite key a non-default character is drawn with: its own art when it
## exists, else the tinted necromancer art, else "" (the glyph variant).
## SkinGlyphs uses it to place a skin's emblem on the head.
static func drawn_sprite_key(id: String) -> String:
	var key := String(CharacterModifiers.def(id)["sprite"])  # Own art key.
	if SpriteBank.has(key):
		return key
	return "player/necromancer" if SpriteBank.has("player/necromancer") else ""


## Soft spell-school aura behind a character without its own art (smaller
## in icon mode, where the sprite fills the box).
static func _draw_aura(ci: CanvasItem, o: Vector2, r: float, tint: Color) -> void:
	var ar := CharacterData.AURA_RADIUS if SpriteBank.icon_cap <= 0.0 else SpriteBank.icon_cap * 0.42  # Aura radius (px).
	if SpriteBank.icon_cap <= 0.0:
		ar = maxf(ar, r * 1.5)
	ci.draw_circle(o, ar, Color(tint, 0.22))
	ci.draw_arc(o, ar, 0.0, TAU, 32, Color(tint, 0.6), 2.0)


## Glyph variant of the necromancer: the robe, eyes and staff orb in the
## school colour `tint` (no art at all); `mult` (a skin's palette tint,
## white = none) multiplies the robe.
static func _draw_glyph(ci: CanvasItem, o: Vector2, r: float, flash: bool, tint: Color, mult: Color = Color.WHITE) -> void:
	ci.draw_circle(o + Vector2(0, r * 0.9), r * 0.9, Color(0, 0, 0, 0.35))
	var robe := PackedVector2Array([o + Vector2(0, -r * 1.25), o + Vector2(-r, r * 1.05), o + Vector2(r, r * 1.05)])
	ci.draw_colored_polygon(robe, _fc(tint.darkened(0.6) * mult, flash))
	ci.draw_line(o + Vector2(-r * 0.5, r * 1.0), o + Vector2(0, -r * 0.2), _fc(tint, flash), 1.5)
	ci.draw_circle(o + Vector2(0, -r * 0.6), r * 0.52, _fc(Color(0.12, 0.05, 0.18), flash))
	ci.draw_circle(o + Vector2(0, -r * 0.52), r * 0.3, _fc(Palette.BONE, flash))
	ci.draw_circle(o + Vector2(-r * 0.12, -r * 0.55), r * 0.08, tint)
	ci.draw_circle(o + Vector2(r * 0.12, -r * 0.55), r * 0.08, tint)
	ci.draw_line(o + Vector2(r * 0.95, r * 1.05), o + Vector2(r * 1.15, -r * 1.3), _fc(Color(0.45, 0.38, 0.3), flash), 2.0)
	ci.draw_circle(o + Vector2(r * 1.17, -r * 1.42), r * 0.55, Color(tint, 0.25))
	ci.draw_circle(o + Vector2(r * 1.17, -r * 1.42), r * 0.3, _fc(tint, flash))


## The flash colour while `flash`, else `c`.
static func _fc(c: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else c


## Picker portrait of character `id` filling `rect`: a dark backdrop in the
## school colour, the character, its starting-spell icon badge (bottom
## right) and, when `locked`, a dimming veil with the pixel padlock (MaskIcon).
static func draw_portrait(ci: CanvasItem, id: String, rect: Rect2, locked: bool) -> void:
	var d := CharacterModifiers.def(id)  # Character row.
	var tint: Color = d["tint"]
	ci.draw_rect(rect, Color(0.04, 0.02, 0.07, 0.95))
	ci.draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.5)), Color(tint, 0.10))
	SpriteBank.icon_cap = rect.size.y * PORTRAIT_FILL
	draw_player(ci, id, rect.get_center(), rect.size.y * 0.24, false)
	SpriteBank.icon_cap = 0.0
	var sid := String(d["spell"])  # Starting spell id.
	if AbilityData.SPELLS.has(sid):
		var side := minf(rect.size.x, rect.size.y) * BADGE_FILL  # Badge size (px).
		Glyphs.draw_icon(ci, String(AbilityData.SPELLS[sid]["icon"]), Rect2(rect.end - Vector2(side, side) - Vector2(2, 2), Vector2(side, side)))
	if locked:
		ci.draw_rect(rect, Color(0.0, 0.0, 0.0, LOCK_VEIL))
		var s := MaskIcon.art_size("padlock") * float(LOCK_ICON_SCALE)  # Pixel padlock (px).
		MaskIcon.paint(ci, "padlock", rect.get_center() - s * 0.5, LOCK_ICON_SCALE)
