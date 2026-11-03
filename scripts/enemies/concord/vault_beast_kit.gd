## VaultBeastKit — the kit of a Freed Beast (ArkEnemyData "vault_beast"; Act
## IX, the Ark of the Concord's Specimen Vaults; GDD §15.0 "The Ark of the
## Concord (Act IX phase 2)"; owner-approved proposal: "break the tanks to free
## captured beasts that attack everyone"). A creature from a broken specimen
## tank (SpecimenTankKit). It is an ENEMY: it fights the army and the
## necromancer as every enemy does (the shared melee AI), and it also strikes
## the Concord's kinds near it:
##   * THE ONE CHECK of whom it attacks, prey(): at 5 Hz (think()) it takes
##     the NEAREST of the summons, the necromancers and the Concord's enemies
##     (a ConcordKit kind that is not a beast, a structure or a boss) within
##     prey_reach px. A summon or a necromancer is left to the shared AI (it
##     is what every enemy hunts); a Concord enemy is its own prey.
##   * ON CONCORD PREY: the kit owns the tick: it runs at the prey and, in
##     reach, bites it every attack_interval s through
##     CombatResolver.damage_enemy() (the friendly damage path, source
##     ArkEnemyData.BEAST_SOURCE: bite_damage x the enemies' HP scaling, from
##     where it stands). A kill there is the run's like any other.
## It never heals on turf (row "heals_on_turf": false), so the report tells it
## apart from the coalition (row "race" ""). Determinism: no RNG (the spatial
## hash's order, the nearest wins). Stats: ark_beast_bites,
## ark_beast_bite_dmg, ark_beast_concord_kills (kills on Concord prey).
class_name VaultBeastKit
extends ConcordKit

## Its Concord prey (null when the nearest is a summon / necromancer, or none).
var prey_e: Enemy = null
## Pool generation of `prey_e` (stale guard).
var prey_gen: int = 0
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	prey_e = null
	prey_gen = 0


func on_deactivate(e: Enemy) -> void:
	prey_e = null
	super.on_deactivate(e)


## 5 Hz: THE ONE CHECK of whom it attacks.
func think(e: Enemy) -> void:
	var p := prey(e)
	if p is Enemy:
		prey_e = p as Enemy
		prey_gen = prey_e.generation
	else:
		prey_e = null


## The nearest of the summons, the necromancers and the Concord's enemies
## within prey_reach px of `e` (null when none): see the header.
func prey(e: Enemy) -> Node2D:
	var g := e.game
	var reach := float(d.get("prey_reach", 220.0))
	var best: Node2D = null
	var best_d := INF
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
			continue
		var du := u.position.distance_to(e.position)
		if du <= reach and du < best_d:
			best = u
			best_d = du
	for pl in g.all_players:
		if pl.dead:
			continue
		var dp := pl.position.distance_to(e.position)
		if dp <= reach and dp < best_d:
			best = pl
			best_d = dp
	g.enemy_grid.query(e.position, reach + ProjectileManager.MAX_BODY_RADIUS, _buf)
	for o: Enemy in _buf:
		if o == e or not o.active or o.is_structure or o.is_boss or o.civilian:
			continue
		if not (o.kit is ConcordKit) or o.kit is VaultBeastKit:
			continue
		var de := o.position.distance_to(e.position)
		if de <= reach and de < best_d:
			best = o
			best_d = de
	return best


## On Concord prey the kit owns the tick (runs at it, bites in reach);
## otherwise the shared AI hunts the army.
func physics(e: Enemy, delta: float) -> bool:
	if prey_e == null or not prey_e.active or prey_e.generation != prey_gen:
		prey_e = null
		return false
	var g := e.game
	var to := prey_e.position - e.position
	var dist := to.length()
	var dir := to / dist if dist > 0.001 else Vector2.RIGHT
	var edge := dist - e.radius - prey_e.radius
	if edge > e.attack_range:
		var spd := e.move_speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
		e.velocity = dir * spd
		e.position += (e.velocity + e.knockback) * delta
	else:
		e.velocity = Vector2.ZERO
		if e.attack_cd <= 0.0:
			e.attack_cd = e.attack_interval
			e.motion_lunge(dir, MotionData.POWER_MELEE)
			var dmg := float(d.get("bite_damage", 9.0)) * g.enemies.hp_mult
			var target := prey_e
			var dealt := g.combat.damage_enemy(target, dmg, ArkEnemyData.BEAST_SOURCE, -1, e.position)
			g.stat_add("ark_beast_bites", 1.0)
			g.stat_add("ark_beast_bite_dmg", dealt)
			if not target.active:
				g.stat_add("ark_beast_concord_kills", 1.0)
			g.effects.slash(e.position + dir * e.radius, dir, Palette.CONCORD_LASER, e.radius * 1.2)
	e._update_facing()
	return true
