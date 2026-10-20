## DeusPlateKit — one armour plate on a leg of DEUS EX MACHINA (CitadelEnemyData
## "deus_leg_plate", kit "deus_plate"; Act III, the Iron Citadel; GDD §15.0 "The
## Iron Citadel (Act III phase 2)"; owner-approved proposal: "Each leg carries an
## armour plate you can break separately, like Vhal'Neth's arms"). A structure
## and a MACHINE. BossDeusExMachina raises four of them in its Walker phase,
## sets their HP and calls attach(); every tick the plate rides on its leg
## (the boss's position plus its LEGS offset), so summons, spells and the
## combat resolver treat it like any enemy. The boss is wounded when one breaks
## (BossDeusExMachina._step_plates()). Never recycled (is_objective). No RNG.
class_name DeusPlateKit
extends CovenantKit

## The boss it is bolted to (null until attach()).
var boss: Enemy = null
## Generation of `boss` when attached (stale guard).
var boss_gen: int = 0
## Leg index (DeusData.LEGS) the plate rides on.
var leg: int = 0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	boss = null
	leg = 0


## Bolts the plate to leg `p_leg` of `p_boss`.
func attach(e: Enemy, p_boss: Enemy, p_leg: int) -> void:
	boss = p_boss
	boss_gen = p_boss.generation
	leg = p_leg
	_ride(e)


## Rides on its leg; never moves on its own.
func physics(e: Enemy, _delta: float) -> bool:
	hold(e)
	e.knockback = Vector2.ZERO
	_ride(e)
	return true


## Puts the plate on its leg.
func _ride(e: Enemy) -> void:
	if boss != null and boss.active and boss.generation == boss_gen:
		var legs: Array = DeusData.LEGS
		e.position = boss.position + (legs[leg % legs.size()] as Vector2)
