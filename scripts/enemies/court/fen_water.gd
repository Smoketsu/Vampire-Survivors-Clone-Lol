## FenWater — the Witchwood's black water slowing whoever wades it (Act VII, the
## Witchwood; GDD §15.0 "The Witchwood (Act VII phase 2)"; owner-approved
## proposal: "the Fen (water slows everyone)"; "the Bog Mother ... drags summons
## into the fen"). ONE helper for every stretch of fen water (the Fen zone's
## pools, WitchwoodDirector; the Bog Mother's own bog, BogMotherKit), so the
## slows go through the one ground-slow path:
##   * the necromancer(s): TerrainSlow.slow_player() (Brinewalker applies; in
##     co-op each slot is bound in turn, so it reads its own passives);
##   * the summons on the ground: TerrainSlow.slow_summon() (fliers, the
##     airborne and the charmed are spared);
##   * the living foes: their own Enemy.apply_slow() (the floating, the
##     structures, the bosses, the minibosses and the untargetable are spared,
##     as on the Styx).
## Deterministic, no RNG; called on a fixed check clock by its owners.
class_name FenWater
extends RefCounted


## Slows everyone for whom `in_water.call(pos, radius)` is true: the
## necromancer by `slow_player`, summons by `slow_summon`, living foes by
## `slow_enemy` (shares of their speed), for `linger` s. `stat` prefixes the
## counters (<stat>_player, <stat>_summons, <stat>_enemies).
static func wade(game: Game, in_water: Callable, slow_player: float, slow_summon: float, slow_enemy: float, linger: float, stat: String) -> void:
	for pl in game.all_players:
		if pl.dead or not bool(in_water.call(pl.position, pl.radius)):
			continue
		game.stat_add(stat + "_player", 1.0)
		if game.coop == null:
			TerrainSlow.slow_player(game, slow_player, linger)
		else:
			var prev := game.coop.bound
			game.coop.bind(game.coop.slot_of(pl))
			TerrainSlow.slow_player(game, slow_player, linger)
			game.coop.bind(prev)
	for h in game.all_hordes:
		for u in h.units:
			if not u.active or u.airborne or u.flies or u.charmed or u.state == SummonedUnit.State.DEAD:
				continue
			if bool(in_water.call(u.position, u.radius)) and TerrainSlow.slow_summon(game, u, slow_summon, linger) > 0.0:
				game.stat_add(stat + "_summons", 1.0)
	for e in game.enemies.active:
		if not e.active or e.is_structure or e.is_boss or e.is_miniboss or e.floating or e.untargetable:
			continue
		if bool(in_water.call(e.position, e.radius)):
			e.apply_slow(slow_enemy, linger)
			game.stat_add(stat + "_enemies", 1.0)
