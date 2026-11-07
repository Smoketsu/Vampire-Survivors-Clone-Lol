## RuneStoneKit — the kit of a Rune-Stone body (NorseEnemyData "rune_stone"; the
## Hall of the Slain, temporarily Act XI; GDD §15.0 "Rune-Stones"). A stone is
## never an Enemy on the field: RuneStones raises and runs every stone itself.
## This kit only lets --spawn=rune_stone@T (or a phase 2 script's spawn_at())
## raise one: on activation it hands its spot to RuneStones.raise_stone() and
## asks RuneStones to take the body off the field (without a kill) on its next
## step (RuneStones.discard_body()).
class_name RuneStoneKit
extends NorseKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.is_objective = true  # Never recycled before it leaves.
	var st := rules(e).stones
	st.raise_stone(e.position)
	st.discard_body(e)


func physics(_e: Enemy, _delta: float) -> bool:
	return true


## Nothing ever hurts the body (it leaves on the next step).
func taken_mult(_e: Enemy, _source: String) -> float:
	return 0.0


## Drawn by RuneStones, never as a body.
func draws_body(_e: Enemy) -> bool:
	return true
