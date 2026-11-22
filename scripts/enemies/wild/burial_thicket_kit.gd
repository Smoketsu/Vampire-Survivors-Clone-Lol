## BurialThicketKit — the kit of one thicket of THE BURIAL (WorldTreeEnemyData
## "burial_thicket"; temporary Act XV, the World-Tree; GDD §15.0 "The Green
## Mother (Act XV phase 2)"; owner-approved proposal: "she pulls the summons
## into the earth one by one; each buried summon becomes a thicket until the
## ring cuts it free"). A structure the Green Mother grows over a summon
## (BossGreenMother._bury() -> bind()): every tick it keeps its place on the
## summon and holds it (SummonedUnit.held_until, the enemy hold path: the
## summon still strikes from the earth). It falls to the army's blows (the
## summon is free at once), or withers when its time is up (`until`, the
## burial time x Deadwood) or its summon is gone. Not a summon rule: an enemy
## effect on a summon through the existing path. Determinism: no RNG, no
## instance ids. Stats: burial_freed (cut down), burial_withered.
class_name BurialThicketKit
extends WildKit

## The buried summon (null when free; generation-checked).
var held: SummonedUnit = null
## Generation of `held` when it was buried.
var held_gen: int = 0
## Game time (s) it withers on its own.
var until: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	held = null
	held_gen = 0
	until = 0.0


## Grows the thicket over summon `u` until game time `p_until`.
func bind(u: SummonedUnit, p_until: float) -> void:
	held = u
	held_gen = u.generation
	until = p_until


## True while it still holds its living summon.
func holding() -> bool:
	return held != null and held.active and held.generation == held_gen and held.state != SummonedUnit.State.DEAD


func physics(e: Enemy, _delta: float) -> bool:
	e.velocity = Vector2.ZERO
	e.knockback = Vector2.ZERO
	if not holding() or e.game.elapsed >= until:
		held = null
		e.game.stat_add("burial_withered", 1.0)
		e.game.enemies.despawn(e)  # It withers (no kill, no drop).
		return true
	e.position = held.position
	held.held_until = maxf(held.held_until, e.game.elapsed + 0.2)  # Renewed each tick: free a moment after it falls.
	return true


## Cut down by the ring: its summon walks free (the hold lapses within 0.2 s).
func on_killed(e: Enemy) -> void:
	held = null
	e.game.stat_add("burial_freed", 1.0)
