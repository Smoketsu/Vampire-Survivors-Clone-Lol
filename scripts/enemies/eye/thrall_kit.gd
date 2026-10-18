## EyeThrallKit — the Drowned Thrall's kit (EyeEnemyData "thrall"; GDD §15.0
## "Act II: the Ancient Eye", Claims): a summon the Ancient Eye claimed, risen
## hostile for a short while. EyeClaims spawns it and calls start(); the kit
## only counts its life down and, when it runs out, lets the soul slip back
## (the Thrall leaves without a kill: no XP, no Dread Rally charge). Killed,
## its soul returns to the necromancer as Dread Rally charge (on_killed). It
## walks and fights through the shared Enemy AI like any melee kind.
## Determinism: no RNG; its life runs on game time (physics ticks).
class_name EyeThrallKit
extends CovenantKit

## Seconds the Thrall still stays risen (set by start()).
var life_left: float = 0.0
## Summon class it was (statistics, the Codex).
var was_class: String = ""


## Arms the Thrall for `life` s; `cls` is the summon class it was.
func start(life: float, cls: String) -> void:
	life_left = life
	was_class = cls


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	life_left = float(EyeEnemyData.CLAIM["thrall_life"])
	was_class = ""


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	if e.game != null and e.game.claims != null:
		e.game.claims.on_thrall_gone()


## Killed by the army or the necromancer: its soul comes back as Dread Rally
## charge.
func on_killed(e: Enemy) -> void:
	if e.game != null and e.game.claims != null:
		e.game.claims.on_thrall_killed(e, was_class)


func physics(e: Enemy, delta: float) -> bool:
	life_left -= delta
	if life_left <= 0.0:
		if e.game != null and e.game.claims != null:
			e.game.claims.on_thrall_expired(e)
		e.game.enemies.despawn(e)
	return false
