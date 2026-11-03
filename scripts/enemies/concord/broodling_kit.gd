## BroodlingKit — the kit of the Broodling (ConcordEnemyData "broodling"; Act
## IX, the Brood; GDD §15.0 "Act IX foundation (phase 1)"; owner-approved
## proposal: "Broodling | Brood | Fodder | Fast swarms of 12 | Anything"). A
## small, fast insect: the shared melee AI does everything; this kit only adds
## the Concord's shared parts (ConcordKit: the rules on first use, the heal on
## turf) and a short chitter when a swarm arrives (rate-limited, sound only).
## Determinism: no RNG.
class_name BroodlingKit
extends ConcordKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	rules(e).play_sound("brood_chitter", e.position, 1.5)
