## HexStoneKit — the kit of a hex stone (WitchwoodEnemyData "hex_stone"; Act
## VII, the Witchwood; GDD §15.0 "The Witchwood (Act VII phase 2)"; owner-
## approved proposal: "Hex stones: standing stones that power the covens'
## circles; destroy one and its zone's covens cannot cast"). A structure: it
## registers with WitchHexes while it stands (a coven near it may cast without
## the Blood Moon: WitchHexes.powering_stone()); broken (killed), it leaves dead
## ground where no coven casts (WitchHexes.drop_stone(e, true)); sunk by the
## Witchwood's director at the next zone, it leaves nothing. Drawn as its sprite
## (structures/hex_stone) with its runes pulsing red, else WitchwoodGlyphs. No
## RNG.
class_name HexStoneKit
extends CourtKit

## True once it was broken (its kill already left dead ground).
var _broken: bool = false


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_broken = false
	rules(e).witch_hexes().add_stone(e)


## Broken: dead ground where it stood.
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	_broken = true
	rules(e).witch_hexes().drop_stone(e, true)
	e.game.effects.impact(e.position, e.radius * 2.5, Palette.COURT_MOON)
	rules(e).play_sound("stone_break", e.position)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	var court := e.game.court
	if not _broken and court != null and court.hexes != null:
		court.hexes.drop_stone(e, false)  # Sunk at a zone change: no dead ground.


func draws_body(_e: Enemy) -> bool:
	return true


## Its sprite, and its runes' slow red pulse over it.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	if not SpriteBank.draw(ci, WitchwoodGlyphs.STONE_SPRITE, Vector2.ZERO, e.flash > 0.0):
		WitchwoodGlyphs.draw_hex_stone(ci, Vector2.ZERO, e.radius, e.flash > 0.0, false)
	var k := 0.5 + 0.5 * sin(e.game.elapsed * 2.4)
	SpriteBank.draw_disc(ci, Vector2(0.0, -e.radius * 1.1), e.radius * 0.9, Color(Palette.COURT_BLOOD_LIGHT, 0.12 + 0.12 * k))
