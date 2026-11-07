## KrakenArmKit — the kit of the Kraken Arm (CorsairEnemyData "kraken_arm"; Act
## X, the Black Tide; GDD §15.0 "Strikes from the Sea"; owner-approved
## proposal: "Tentacle: grabs one summon, holds it 5 s with the existing
## held_until hook, then drags it overboard (lost until the next replenish).
## Kill the tentacle (200 HP, surfaced 3 s) to free it"). A swimmer STRUCTURE
## (rows "water", "is_structure"): SeaStrikes moves it round the hull, runs its
## TENTACLE strike (a 1 s circle on the rail band, then a grab) and carries
## the grabbed summon; while it is surfaced it can be shot, struck or blasted,
## and its death frees what it holds (CorsairRules.note_gone() ->
## SeaStrikes.release_all()). Off Act X (no deck) it is an inert structure.
## Determinism: no RNG.
class_name KrakenArmKit
extends CorsairKit


## While surfaced: a churn of foam round the arm (visual only).
func draw_under(e: Enemy) -> void:
	if in_water and surfaced(e):
		SpriteBank.draw_disc(e, Vector2.ZERO, e.radius * 1.5, Color(Palette.CORSAIR_FOAM, 0.28))
