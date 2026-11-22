## SpheresDominionKit — the kit of THE DOMINION OF THE SPHERES, the Wheel of
## Thrones' miniboss (WheelOfThronesEnemyData "dominion_of_the_spheres";
## temporary Act XIII, the Celestial Host; GDD §15.0 "The Wheel of Thrones (Act
## XIII phase 2)"; owner-approved proposal: "the Dominion of the Spheres, who
## keeps halos returning across the whole zone until he falls"). A Dominion
## (DominionKit: the speed aura is the shared aura path, the halos Grace's: his
## row's "regrows" puts him on Grace's regrower list and its "regrow_radius"
## stretches the regrowth over the whole zone, Grace.step(), the one
## regrowth), plus the miniboss's parts: the HUD's miniboss bar
## (EnemyDirector.set_miniboss()), his XP burst (reward_xp in reward_crystals)
## and the stats of his fall; ChestManager drops the miniboss chest.
## Determinism: no RNG. Stats: spheres_dominion_kills, spheres_dominion_ttk.
class_name SpheresDominionKit
extends DominionKit

## Game time (s) he arrived (his time to kill).
var spawned_at: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)


## His XP burst and the stats of his fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 10)))
	var each := maxi(1, floori(float(d.get("reward_xp", 200)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.HOST_STARLIGHT)
	g.shake(8.0)
	g.stat_add("spheres_dominion_kills", 1.0)
	g.stat_add("spheres_dominion_ttk", g.elapsed - spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)
