## CorsairBoatKit — the kit of the boarding boats (CorsairEnemyData "skiff",
## "longboat", "raider_ship"; Act X, the Black Tide; GDD §15.0 "Boarding").
## A STRUCTURE in the water (row "water": the deck ignores it) that
## BoardingParty spawns alongside the rail with two grapple hooks and moves
## when it drifts or casts off. Destroyed, it SINKS: BoardingParty
## .on_boat_killed() drowns its remaining crew and leaves a floating crate.
## The Barnacle Bones hook applies to it (CorsairKit.taken_mult()).
## Determinism: no RNG.
class_name CorsairBoatKit
extends CorsairKit


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	if e.game.corsair != null:
		e.game.corsair.boarding.on_boat_killed(e)
	e.game.effects.ring(e.position, e.radius * 1.4, Palette.CORSAIR_FOAM, 0.45)


## A low wake of foam round the hull (visual only).
func draw_under(e: Enemy) -> void:
	SpriteBank.draw_disc(e, Vector2.ZERO, e.radius * 1.25, Color(Palette.CORSAIR_FOAM, 0.18))
