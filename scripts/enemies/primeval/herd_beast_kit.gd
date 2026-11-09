## HerdBeastKit — base class of the HERD BEASTS' kits (the Longneck, the
## Duckbill; temporary Act XIV, the Age of Titans; GDD §15.0 "Herds"): a
## neutral giant. Herds owns its every tick (Herds.steer(): it grazes, paws
## the ground under the dust line, runs the stampede; it never attacks), and
## its kill may raise a Fossil Giant (Herds.on_killed(), through
## PrimevalRules.note_killed()). Not loaded by any id itself ("herd_beast" is
## no kind): LongneckKit and DuckbillKit extend it. Determinism: no RNG.
class_name HerdBeastKit
extends PrimevalKit

## The herd this beast grazes with (Herds; null = none).
var herd: Herds.Herd = null
## Its HP at the last tick (a drop since then frightens its herd).
var last_hp: float = 0.0
## True when it was hurt since Herds last looked (Herds._frightened_by()).
var hurt: bool = false


func reset(e: Enemy, def: Dictionary) -> void:
	herd = null
	hurt = false
	super.reset(e, def)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	herd = null


func physics(e: Enemy, delta: float) -> bool:
	return rules(e).herds.steer(e, self, delta)


## True while its herd paws the ground or runs (the autotest's stuck check
## skips it).
func is_busy() -> bool:
	return herd != null and herd.state != Herds.GRAZE
