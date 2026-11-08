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
## return). THE ORB SHIELD GNAW (the Necropolis of Sand, phase 2): a bite by a
## swarm that touches a charged Orb Shield orb spends that orb's charge
## (AbilityManager.try_intercept()). Determinism: game state only. Stats:
## scarab_barrier_gnawed (barrier HP torn), scarab_orbs_gnawed.
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
	# --- Act XII (temporary number): the Necropolis of Sand ---
	# THE ORB SHIELD GNAW: a bite (on anything) by a swarm that touches a
	# charged Orb Shield orb spends that orb's charge (OrbShield.try_intercept(),
	# the orbs' own one path: it recharges as after a blocked shot).
	if e.attack_cd > _last_cd + 0.01:
		_gnaw_orbs(e)
	_last_cd = e.attack_cd
	return false


# --- Act XII (temporary number): the Necropolis of Sand ---
## A bite's Orb Shield gnaw: the first charged orb of any necromancer's
## shield that touches the swarm loses its charge (try_intercept(): co-op,
## every slot's shield).
func _gnaw_orbs(e: Enemy) -> void:
	var g := e.game
	if g.coop != null:
		for s in g.coop.slots:
			if s.abilities != null and s.abilities.try_intercept(e.position, e.radius):
				g.stat_add("scarab_orbs_gnawed", 1.0)
				return
		return
	if g.abilities.try_intercept(e.position, e.radius):
		g.stat_add("scarab_orbs_gnawed", 1.0)
