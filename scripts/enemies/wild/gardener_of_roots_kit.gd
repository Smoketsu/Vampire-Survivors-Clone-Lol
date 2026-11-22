## GardenerOfRootsKit — the kit of THE GARDENER OF ROOTS, the World-Tree's
## miniboss (no sex: a great treant with root-hands; WorldTreeEnemyData
## "gardener_of_roots"; temporary Act XV, the Turning Year; GDD §15.0 "The
## World-Tree (Act XV phase 2)"; owner-approved proposal: "Miniboss, the
## Gardener of Roots, a treant that tends the tree and calls every root in
## reach"). The Treant's kit (TreantKit: every strike on a summon roots it),
## plus THE CALL: while he lives he is a root caller of SeasonCycle
## (call_roots(), the roots' one path, one new radius rule): every body that
## stands still within root_call_radius px of him is grabbed whatever the
## season, with the Spring roots' numbers. A "miniboss" row registers on the
## HUD's miniboss bar and drops his XP burst when he falls; ChestManager drops
## the miniboss chest. Determinism: no RNG, no instance ids. Stats:
## treant_roots (his strikes), gardener_roots (grabs of the call outside spring).
class_name GardenerOfRootsKit
extends TreantKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	if bool(d.get("miniboss", false)):
		e.game.enemies.set_miniboss(e)


## The call renewed every tick (SeasonCycle drops a dead caller itself), then
## the Treant's rooting strike.
func physics(e: Enemy, delta: float) -> bool:
	rules(e).seasons.call_roots(e, float(d.get("root_call_radius", 300.0)))
	return super.physics(e, delta)
