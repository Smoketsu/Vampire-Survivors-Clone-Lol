## HuntsmanKit — the kit of THE HUNTSMAN OF THE WILD HUNT, the Greenwood's
## miniboss (male; GreenwoodEnemyData "huntsman"; temporary Act XV, the Turning
## Year; GDD §15.0 "The Greenwood (Act XV phase 2)"; owner-approved proposal:
## "Miniboss, the Huntsman of the Wild Hunt, who leads three riders in a sweeping
## line"). The shared Wild charge (WildChargeKit) with a following:
##   * on his first tick he brings `riders` Riders of the Wild Hunt (row
##     rider_kind) beside him (EnemyDirector.spawn_at(); they ride without
##     hounds: a first pass with their six hounds overran the naive bot);
##   * every charge_every s he blows his horn and his living riders blink to his
##     flanks, rider_spacing px apart (alternating sides), and sweep his line
##     with him (WildChargeKit.lead(): a led rider never sweeps on its own, its
##     hounds stay behind);
##   * a "miniboss" row registers on the HUD's miniboss bar and drops his XP
##     burst (reward_xp in reward_crystals) when he falls; ChestManager drops
##     the miniboss chest; his riders ride on alone.
## Determinism: no RNG, no instance ids. Stats: huntsman_riders,
## huntsman_lines, huntsman_kills, huntsman_ttk.
class_name HuntsmanKit
extends WildChargeKit

## His riders (Enemy) and their generations when they came.
var riders: Array[Enemy] = []
## Generations of `riders`, index for index.
var rider_gens: Array[int] = []
## Game time (s) he arrived (the miniboss's time to kill).
var spawned_at: float = 0.0
## True once his riders were brought (they come once).
var _brought: bool = false


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	riders.clear()
	rider_gens.clear()
	_brought = false
	spawned_at = e.game.elapsed
	if bool(d.get("miniboss", false)):
		e.game.enemies.set_miniboss(e)


func physics(e: Enemy, delta: float) -> bool:
	if not _brought:
		_brought = true
		var n := int(d.get("riders", 3))
		for i in n:
			var at := e.game.arena.free_point(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * 70.0, 15.0)
			var r := e.game.enemies.spawn_at(String(d.get("rider_kind", WildEnemyData.WILD_RIDER)), at, false)
			if r != null:
				if r.kit is WildRiderKit:
					(r.kit as WildRiderKit).no_hounds()  # His riders ride without hounds: he is their pack.
				riders.append(r)
				rider_gens.append(r.generation)
				e.game.stat_add("huntsman_riders", 1.0)
	return super.physics(e, delta)


## His horn: the living riders take their places in his line (see the header).
func _on_begin(e: Enemy) -> void:
	var side := charge_dir.orthogonal() * float(d.get("rider_spacing", 46.0))
	var k := 0
	for i in riders.size():
		var r := riders[i]
		if not (r.active and r.generation == rider_gens[i]) or not (r.kit is WildChargeKit):
			continue
		var place := float(k / 2 + 1) * (1.0 if k % 2 == 0 else -1.0)
		(r.kit as WildChargeKit).lead(r, e, e.position + side * place, charge_dir, windup)
		k += 1
	e.game.stat_add("huntsman_lines", 1.0)
	rules(e).play_sound("hunt_horn", e.position, 1.0)


## A miniboss's XP burst and the stats of his fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	if not bool(d.get("miniboss", false)):
		return
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 10)))
	var each := maxi(1, floori(float(d.get("reward_xp", 200)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.WILD_FROST)
	g.shake(8.0)
	g.stat_add("huntsman_kills", 1.0)
	g.stat_add("huntsman_ttk", g.elapsed - spawned_at)


## Releases the HUD bar (the miniboss).
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	if bool(d.get("miniboss", false)):
		e.game.enemies.clear_miniboss(e)
