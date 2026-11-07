## ScarabSwarmKit — the kit of the SCARAB SWARM (DynastyEnemyData
## "scarab_swarm"; temporary Act XII, the Necropolis Dynasty; GDD §15.0 "The
## Necropolis Dynasty foundation (phase 1)"; owner-approved proposal: "12
## beetles, fast, gnaw a summon's barrier ... no Rebirth | Area damage; Warders
## recast barriers"). One body is one swarm (its art a cluster of beetles). Its
## bites are the shared melee (Enemy._melee_hit()); on top of each bite on a
## summon that holds a Warder's barrier (SummonedUnit.barrier_hp) it tears off
## its row's barrier_gnaw HP more (x the time scaling), so Warders must recast.
## The bite is seen the tick after it lands (its attack cooldown jumped back
## up), on the target it bit. No Rebirth (its row has none: beasts do not
## return). Phase 2: the Orb Shield gnaw (one charge of
## AbilityManager.try_intercept()) if playtests want it. Determinism: game
## state only. Stats: scarab_barrier_gnawed (barrier HP torn).
class_name ScarabSwarmKit
extends DynastyKit

## The attack cooldown seen last tick (a jump up = a bite landed).
var _last_cd: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_last_cd = 0.0


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	if e.attack_cd > _last_cd + 0.01 and e.target is SummonedUnit:
		var u := e.target as SummonedUnit
		if u.active and u.barrier_hp > 0.0:
			var torn := minf(u.barrier_hp, float(d.get("barrier_gnaw", 0.0)) * hit_scale(e))  # Barrier HP torn off.
			u.barrier_hp -= torn
			u.queue_redraw()
			e.game.stat_add("scarab_barrier_gnawed", torn)
	_last_cd = e.attack_cd
	return false
