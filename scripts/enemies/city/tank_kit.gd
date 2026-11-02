## TankKit — the kit of the Tank (CityEnemyData "tank"; Act VIII, GDD §15.0
## "Armour"; owner-approved proposal: "armour rules; a cannon shell with a
## landing circle; flat armour. Siegecraft, Wither; let it ram a wreck"): an
## army VEHICLE (the CityKit's drive: the lane, the headlights, the run-over,
## the turn, the ram, the wreck), with FRONT ARMOUR (row "armour_front") and
## FLAT ARMOUR (row "flat_armor", the existing path), and a CANNON: every
## shell_every s, with its target within shell_range px, a shell that lands
## shell_windup s later on the target's spot (a landing circle, CityShells:
## summons and the necromancer within shell_radius px take shell_damage). It
## is Martial Law's heavy. No RNG (its first shell staggered by the think slot).
class_name TankKit
extends CityKit

## Seconds until its next shell may be fired.
var _shell_cd: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_shell_cd = first_cd(e, float(d.get("shell_every", 6.0)) * 0.5)


func physics(e: Enemy, delta: float) -> bool:
	var owns := super.physics(e, delta)  # The drive.
	_shell_cd -= delta
	if _shell_cd <= 0.0 and e._target_valid():
		var at := e.target.position
		if at.distance_to(e.position) <= float(d.get("shell_range", 380.0)):
			_shell_cd = float(d.get("shell_every", 6.0))
			rules(e).shells.add(at, float(d.get("shell_windup", 1.1)), float(d.get("shell_radius", 44.0)),
					float(d.get("shell_damage", 16.0)) * hit_scale(e), CityEnemyData.SHELL_SOURCE, false)
			e.game.stat_add("tank_shells", 1.0)
			rules(e).play_sound("gun_burst", e.position, 0.3)
	return owns
