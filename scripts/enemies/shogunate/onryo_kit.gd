## OnryoKit — the kit of the Onryō (ShogunateEnemyData "onryo"; Act V, GDD §15.0
## "Act V foundation (phase 1)"): night fodder, a vengeful ghost. NIGHT (the
## timeline helper keeps it to the night) and ETHEREAL (Enemy.ethereal, the one
## path: it drifts through obstacles and through the Bone Ring, so no summon
## body-blocks it). It sways from side to side as it drifts in (its row's drift
## px/s at drift_rate rad/s, a sine of game time offset by its think slot: no
## RNG); everything else is the shared melee AI.
class_name OnryoKit
extends ShogunateKit


## The drift: a sideways sway across its way to the necromancer; never holds.
func physics(e: Enemy, delta: float) -> bool:
	var to := e.game.player.position - e.position
	if to.length_squared() > 1.0:
		var side := to.normalized().orthogonal()  # Across its way.
		var s := sin(e.game.elapsed * float(d.get("drift_rate", 1.5)) + float(e.think_slot))
		e.position += side * s * float(d.get("drift", 0.0)) * delta
	return false
