## TreantKit — the kit of the TREANT (WildEnemyData "treant"; temporary Act XV, the
## Turning Year; GDD §15.0 "The Greenwood (Act XV phase 2)"; owner-approved
## proposal: "Treant | Heavy | Slow; roots the summon it strikes | Fire, Wither,
## Siegecraft"): the slow heavy and Spring Returns' heavy. The plain melee AI;
## every strike on a summon ROOTS it (SummonedUnit.held_until, the Netcaster's
## hold path) for root_hold s x Deadwood (WildRules.deadwood_mult(), the
## counter-passive's one read). The strike is seen on the next tick (its attack
## timer jumped back up). Determinism: no RNG, no instance ids. Stats:
## treant_roots.
class_name TreantKit
extends WildKit

## Its attack timer as last seen (a jump up means it struck).
var _cd_seen: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd_seen = e.attack_cd


func physics(e: Enemy, _delta: float) -> bool:
	if e.attack_cd > _cd_seen + 0.001 and e.target is SummonedUnit and e._target_valid():
		var u := e.target as SummonedUnit
		if not u.airborne and not u.flies and u.state != SummonedUnit.State.DEAD:
			u.held_until = maxf(u.held_until, e.game.elapsed + float(d.get("root_hold", 1.2)) * rules(e).deadwood_mult())
			e.game.stat_add("treant_roots", 1.0)
	_cd_seen = e.attack_cd
	return false
