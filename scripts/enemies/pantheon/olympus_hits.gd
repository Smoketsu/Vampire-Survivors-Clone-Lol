## OlympusHits — the two shapes of hit the gods of Mount Olympus deal (Act IV,
## Stage 11; GDD §15.0 "Mount Olympus (Act IV phase 2)"): a LANE (Ares's spear
## charge, Poseidon's trident, Zeus's thunderbolt beam, the sea serpent's
## lunge) and a CIRCLE (the Amazon's landing, Zeus's Thunder Stomp). Static
## helpers only, no state: every hit goes through CombatResolver (the
## necromancer: damage_player(); summons: damage_unit(), naming the attacker
## for Glory), co-op aware (every necromancer of Game.all_players).
## Determinism: no RNG; targets in the spatial hash's order.
class_name OlympusHits
extends RefCounted


## Hits every necromancer and summon inside the lane from world point `from`
## along unit `dir`, `length` px long and `width` px wide, ONCE each:
## `struck` remembers who was hit (pass the same dictionary for a lane that
## sweeps over several ticks). `dmg_player` / `dmg_summon` are already scaled;
## `source` tags the stats; `by` is the attacker (Glory). `tmp` is the
## caller's query buffer. Returns the summons hit by this call.
static func lane(g: Game, from: Vector2, dir: Vector2, length: float, width: float, dmg_player: float, dmg_summon: float,
		source: String, by: Enemy, struck: Dictionary, tmp: Array) -> int:
	var half := width * 0.5  # Lane half-width (px).
	var side := dir.orthogonal()  # Across the lane.
	for pl in g.all_players:
		if struck.has(pl) or pl.dead:
			continue
		var rel := pl.position - from
		var along := rel.dot(dir)
		if along >= -pl.radius and along <= length + pl.radius and absf(rel.dot(side)) <= half + pl.radius:
			struck[pl] = true
			g.combat.damage_player(dmg_player, source, pl)
	var hits := 0
	g.ally_grid.query(from + dir * length * 0.5, length * 0.5 + half + UnitData.MAX_BLOCK_RADIUS, tmp)
	for u: SummonedUnit in tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or struck.has(u):
			continue
		var rel := u.position - from
		var along := rel.dot(dir)
		if along < -u.radius or along > length + u.radius or absf(rel.dot(side)) > half + u.radius:
			continue
		struck[u] = true
		g.combat.damage_unit(u, dmg_summon, source, by)
		hits += 1
	return hits


## Hits every necromancer and summon inside the circle of `r` px at `at`
## (bodies count): `dmg_player` / `dmg_summon` already scaled, tagged
## `source`, attacker `by`. Summons are thrown `push` px out from the centre
## (0 = none). `tmp` is the caller's query buffer. Returns the summons hit.
static func circle(g: Game, at: Vector2, r: float, dmg_player: float, dmg_summon: float, source: String, by: Enemy,
		push: float, tmp: Array) -> int:
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(at) <= r + pl.radius:
			g.combat.damage_player(dmg_player, source, pl)
	var hits := 0
	g.ally_grid.query(at, r + UnitData.MAX_BLOCK_RADIUS, tmp)
	for u: SummonedUnit in tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(at) > r + u.radius:
			continue
		if push > 0.0:
			var away := u.position - at
			u.position += (away.normalized() if away.length() > 0.5 else Vector2.UP) * push
		g.combat.damage_unit(u, dmg_summon, source, by)
		hits += 1
	return hits


## Summons within `r` px of `at` (bodies count).
static func summons_near(g: Game, at: Vector2, r: float, tmp: Array) -> int:
	g.ally_grid.query(at, r + UnitData.MAX_BLOCK_RADIUS, tmp)
	var n := 0
	for u: SummonedUnit in tmp:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(at) <= r + u.radius:
			n += 1
	return n


## The first summon of block mass >= `mass` within `reach` px of `at`
## (bodies count), or null: the blocker that stops a charge or catches a leap.
static func blocker_at(g: Game, at: Vector2, reach: float, mass: float, tmp: Array) -> SummonedUnit:
	g.ally_grid.query(at, reach + UnitData.MAX_BLOCK_RADIUS, tmp)
	for u: SummonedUnit in tmp:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.block_mass >= mass and u.position.distance_to(at) <= reach + u.radius:
			return u
	return null
