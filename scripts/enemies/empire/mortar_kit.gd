## MortarKit — the Mortar Walker's kit (WastesEnemyData "mortar_walker"; Act
## III, the Scrap Wastes, GDD §15.0 "The Scrap Wastes (Act III phase 2)";
## owner-approved proposal: "Lobs shells with a landing circle; arcing shots
## ignore Line of Fire. Keep moving; Catapults and Gargoyles reach it"). A
## heavy MACHINE that walks on like every ranged kind (enemies always advance)
## and, when its attack is due and a target is in range (its reach through the
## shared EmpireKit reach path), lobs ONE shell through EmpireKit.fire_arc_at():
## the shell flies mortar_flight s to where its target will be (led by
## mortar_lead of the flight along the target's velocity), its warning-red
## landing circle shows for the last EmpireRulesData.ARC_TELEGRAPH s, and it
## bursts on everything inside its splash (Line of Fire does not apply). Stats:
## wastes_mortar_shells. No RNG.
class_name MortarKit
extends EmpireKit


## The attack is due: lob a shell at where `t` will be.
func fire_ranged(e: Enemy, t: Node2D, _dir: Vector2, dmg: float) -> bool:
	var flight := float(d["mortar_flight"])  # Flight time (s).
	var vel := Vector2.ZERO  # The target's velocity (px/s).
	if t is SummonedUnit:
		vel = (t as SummonedUnit).velocity
	elif t is Necromancer:
		vel = (t as Necromancer).velocity
	var dest := t.position + vel * flight * float(d["mortar_lead"])  # Landing point.
	if fire_arc_at(e, dest, flight, dmg):
		e.game.stat_add("wastes_mortar_shells", 1.0)
		Sfx.play("mortar_launch", e.position)
	return true
