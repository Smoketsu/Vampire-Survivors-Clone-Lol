## ReefSharkKit — the kit of the Reef Shark (CorsairEnemyData "reef_shark"; Act
## X, the Black Tide; GDD §15.0 "Strikes from the Sea"; owner-approved
## proposal: "Circles; leaps at the ring every ~10 s | Hit it at the leap; Orb
## Shield"). A swimmer (row "water"): SeaStrikes moves it round the hull
## submerged and runs its strike, the LEAP (a 0.8 s shadow on the deck, then
## it lands there as an ordinary deck enemy: CorsairKit.leave_water()). On the
## deck the shared melee AI drives it, and a knock past the rail drowns it
## like any boarder. Off Act X (no deck) it is an ordinary melee body.
## Determinism: no RNG.
class_name ReefSharkKit
extends CorsairKit


## While surfaced in the water: a ring of foam where it breaks the surface.
func draw_under(e: Enemy) -> void:
	if in_water and surfaced(e):
		SpriteBank.draw_disc(e, Vector2.ZERO, e.radius * 1.4, Color(Palette.CORSAIR_FOAM, 0.3))
