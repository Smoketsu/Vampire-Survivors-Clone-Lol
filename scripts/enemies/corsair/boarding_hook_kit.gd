## BoardingHookKit — the kit of a boat's grapple hook (CorsairEnemyData
## "boarding_hook"; Act X, the Black Tide; GDD §15.0 "Boarding";
## owner-approved proposal: "Each hook is a small structure (40 HP) with a
## visible rope"). A STRUCTURE at the rail; BoardingParty spawns two per boat,
## draws their ropes and repels the boat when both are cut. The Barnacle Bones
## hook applies to it (CorsairKit.taken_mult()).
## Determinism: no RNG.
class_name BoardingHookKit
extends CorsairKit


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	if e.game.corsair != null:
		e.game.corsair.boarding.on_hook_killed(e)
		e.game.corsair.play_sound("hook_cut", e.position, 0.1)
