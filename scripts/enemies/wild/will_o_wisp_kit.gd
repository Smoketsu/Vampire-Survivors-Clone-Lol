## WillOWispKit — the kit of the WILL-O'-WISP (WildEnemyData "will_o_wisp";
## temporary Act XV, the Turning Year; GDD §15.0 "The Greenwood (Act XV phase
## 2)"; owner-approved proposal: "Will-o'-Wisp | Lure | Draws summons away from
## the ring (the existing misdirect() hook) | Kill it; area damage"). The plain
## melee AI drifts it in; every lure_every s it LURES up to lure_cap summons
## within lure_radius px: each walks toward it for lure_time s at lure_speed x
## its speed, fighting nothing (SummonedUnit.misdirect(), the one path that
## turns a summon around; the leash still holds). Determinism: no RNG, no
## instance ids (the summons in the spatial hash's order). Stats: wisp_lures.
class_name WillOWispKit
extends WildKit

## Seconds until the next lure.
var cd: float = 0.0
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d.get("lure_first", 1.5)))


func physics(e: Enemy, delta: float) -> bool:
	cd -= delta
	if cd > 0.0:
		return false
	cd = float(d.get("lure_every", 3.0))
	var g := e.game
	var r := float(d.get("lure_radius", 110.0))
	var n := 0
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if n >= int(d.get("lure_cap", 3)):
			break
		if not u.active or u.misdirect_until > g.elapsed or u.position.distance_to(e.position) > r + u.radius:
			continue
		if u.misdirect(e.position - u.position, float(d.get("lure_time", 1.6)), float(d.get("lure_speed", 0.8))):
			n += 1
	if n > 0:
		g.stat_add("wisp_lures", float(n))
	return false
