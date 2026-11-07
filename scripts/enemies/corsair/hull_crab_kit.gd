## HullCrabKit — the kit of the Hull Crab (CorsairEnemyData "hull_crab"; Act X,
## the Black Tide, the Treasure Galleon's block; a creature; GDD §15.0 "The
## Treasure Galleon (Act X phase 2)"; owner-approved proposal: "Climbs the hull
## and boards at the rail band; armour 4 | Area damage; push it back over").
## A swimmer (row "water") whose strike is THE CLIMB (SeaStrikes, strike type
## "climb"): it surfaces at the hull point nearest its target, a climbing
## circle shows for its telegraph, then it heaves itself over the rail into
## the rail band (SeaStrikes._climb_aboard() -> CorsairKit.leave_water()) and
## walks and pinches like any deck enemy: its flat armour 4 is the row's
## (CombatResolver's flat armour path), and a hard blow at the rail tips it
## back in (DeckBounds drowns it). Nothing else of its own.
## Determinism: no RNG.
class_name HullCrabKit
extends CorsairKit


## While surfaced in the water: foam churned round its claws (visual only).
func draw_under(e: Enemy) -> void:
	if in_water and surfaced(e):
		SpriteBank.draw_disc(e, Vector2.ZERO, e.radius * 1.4, Color(Palette.CORSAIR_FOAM, 0.25))
