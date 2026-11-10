## WildRiderKit — the kit of the RIDER OF THE WILD HUNT (WildEnemyData
## "wild_rider"; temporary Act XV, the Turning Year; GDD §15.0 "The Greenwood
## (Act XV phase 2)"; owner-approved proposal: "Rider of the Wild Hunt (male) |
## Elite | A spectral horseman and two hounds; sweeps across the arena in a line |
## Step out of the line; Archers"). On its first tick it brings its `hounds`
## Hounds of the Wild Hunt (row hound_kind) beside it (EnemyDirector.spawn_at());
## its SWEEP is the shared Wild charge (WildChargeKit: a long, fast line through
## the necromancer), and its living hounds sweep the same line hound_side px to
## either side (lead()). The Huntsman of the Wild Hunt leads his riders the same
## way (a led rider never sweeps on its own). THE HUNT PASSES: after
## leave_after sweeps of its own a rider rides on out of the wood with its
## hounds (EnemyDirector.despawn(): no kill, no drop), so the Hunt sweeps past
## instead of staying. Determinism: no RNG, no instance ids. Stats:
## hunt_hounds_brought, hunt_riders_passed.
class_name WildRiderKit
extends WildChargeKit

## Its hounds (Enemy) and their generations when they came.
var hounds: Array[Enemy] = []
## Generations of `hounds`, index for index.
var hound_gens: Array[int] = []
## True once its hounds were brought (they come once).
var _brought: bool = false
## Sweeps of its own so far (it rides on after leave_after of them).
var _sweeps: int = 0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	hounds.clear()
	hound_gens.clear()
	_brought = false
	_sweeps = 0


## This rider brings no hounds (the Huntsman's riders: he is their pack).
func no_hounds() -> void:
	_brought = true


func physics(e: Enemy, delta: float) -> bool:
	if not _brought:
		_brought = true
		var side := Vector2.UP
		for i in int(d.get("hounds", 0)):
			var at := e.game.arena.free_point(e.position + side * float(d.get("hound_side", 34.0)) * (1.0 if i % 2 == 0 else -1.0), 9.0)
			var h := e.game.enemies.spawn_at(String(d.get("hound_kind", WildEnemyData.HUNT_HOUND)), at, false)
			if h != null:
				hounds.append(h)
				hound_gens.append(h.generation)
				e.game.stat_add("hunt_hounds_brought", 1.0)
	var was := phase
	var busy := super.physics(e, delta)
	if was == CHARGE and phase == IDLE and not led() and int(d.get("leave_after", 0)) > 0 and _sweeps >= int(d.get("leave_after", 0)):
		_ride_on(e)  # THE HUNT PASSES: after its last sweep it rides on with its hounds.
		return true
	return busy


## It rides on out of the wood with its living hounds (no kill, no drop).
func _ride_on(e: Enemy) -> void:
	for i in hounds.size():
		if hounds[i].active and hounds[i].generation == hound_gens[i]:
			e.game.enemies.despawn(hounds[i])
	hounds.clear()
	hound_gens.clear()
	e.game.stat_add("hunt_riders_passed", 1.0)
	e.game.effects.ring(e.position, e.radius * 2.0, Palette.WILD_FROST, 0.4)
	e.game.enemies.despawn(e)


## Its living hounds sweep beside it (see the header).
func _on_begin(e: Enemy) -> void:
	_sweeps += 1
	var side := charge_dir.orthogonal() * float(d.get("hound_side", 34.0))
	var k := 0
	for i in hounds.size():
		var h := hounds[i]
		if not (h.active and h.generation == hound_gens[i]) or not (h.kit is WildChargeKit):
			continue
		(h.kit as WildChargeKit).lead(h, e, e.position + side * (1.0 if k % 2 == 0 else -1.0), charge_dir, windup)
		k += 1
