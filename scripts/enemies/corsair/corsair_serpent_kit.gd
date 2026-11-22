## CorsairSerpentKit — the kit of the Sea Serpent (CorsairEnemyData
## "corsair_serpent": its id, since Act IV's Olympus owns "sea_serpent";
## Act X, the Black Tide, built with the Maelstrom; GDD §15.0 "The Maelstrom
## (Act X phase 2)"; owner-approved proposal: "Sea Serpent | Swimmer heavy |
## Breaches in a line across the rail band, then submerges | Step out of the
## line"). A swimmer STRUCTURE (rows "water", "is_structure"): SeaStrikes moves
## it round the hull submerged and runs its strike, the BREACH (strike type
## "breach": a lane from the hull across the rail band, telegraphed, then swept
## by its body: SeaStrikes._breach()); it can be hit only while surfaced. Off
## Act X (no deck) it is an inert structure.
## Determinism: no RNG.
class_name CorsairSerpentKit
extends CorsairKit


## Sprite key of its art (the art pass named it after the creature).
const SPRITE: String = "corsair/sea_serpent"


## It draws its own body: submerged, the shared dark shape and fin; surfaced
## (or off Act X), the art pass's sea serpent.
func draws_body(_e: Enemy) -> bool:
	return true


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	if in_water and not surfaced(e):
		super.draw_body(e, ci)
		return
	if not SpriteBank.draw(ci, SPRITE, Vector2.ZERO, e.flash > 0.0):
		CorsairGlyphs.draw_enemy(ci, "kraken_arm", Vector2.ZERO, e.radius, e.flash > 0.0)


## While surfaced: a churn of foam and a teal sheen round its coils (visual only).
func draw_under(e: Enemy) -> void:
	if in_water and surfaced(e):
		SpriteBank.draw_disc(e, Vector2.ZERO, e.radius * 1.6, Color(Palette.CORSAIR_FOAM, 0.26))
		SpriteBank.draw_disc(e, Vector2.ZERO, e.radius * 1.1, Color(Palette.CORSAIR_SERPENT_LIGHT, 0.18))
