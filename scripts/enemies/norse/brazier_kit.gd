## BrazierKit — the kit of a brazier body (NorseEnemyData "brazier"; the Hall of
## the Slain, temporarily Act XI; GDD §15.0 "The Long Winter"). A brazier is
## never an Enemy on the field: LongWinter places and runs every brazier
## itself. This kit only lets --spawn=brazier@T (or a phase 2 script's
## spawn_at()) place one: on activation it hands its spot to LongWinter.place()
## and asks LongWinter to take the body off the field (without a kill) on its
## next step (LongWinter.discard_body()).
class_name BrazierKit
extends NorseKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.is_objective = true  # Never recycled before it leaves.
	var w := rules(e).winter
	w.place(e.position)
	w.discard_body(e)


func physics(_e: Enemy, _delta: float) -> bool:
	return true


## Nothing ever hurts the body (it leaves on the next step).
func taken_mult(_e: Enemy, _source: String) -> float:
	return 0.0


## Drawn by LongWinter, never as a body.
func draws_body(_e: Enemy) -> bool:
	return true
