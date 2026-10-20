## SpotterKit — the Spotter's kit (EmpireEnemyData "spotter", an elite; Act
## III, GDD §15.0 "Lock-On: the big shots are telegraphed"). When its attack is
## due (attack_interval s apart, a target within its 520 px range) it asks
## LockOn to paint its target, the necromancer or a summon (the shared AI's
## target choice), with a thin red laser for 1.5 s; it holds still while the
## line is painted (a telegraphed windup, not kiting), then LockOn fires the
## heavy rail shot down the line through EmpireShots. Counters: Grave Step out
## of the line, put a summon in it (Line of Fire), or kill the Spotter first
## (its line is cancelled). When LockOn refuses (3 lines already painted) it
## asks again EmpireRulesData.LOCK_ON.retry s later. It glows warning red
## (draw_over, brighter while painting) and ranks high on every summon's target
## list through its row's target_priority (the existing targeting path). A
## CYBORG: raised, it rises as a Grave Gunner. No RNG.
class_name SpotterKit
extends EmpireKit

## Phase: painting a Lock-On line (held still until LockOn fired or cancelled it).
const PAINTING: int = 1


## The attack is due: paint `t` (no shot of its own; LockOn fires the rail).
func fire_ranged(e: Enemy, t: Node2D, _dir: Vector2, dmg: float) -> bool:
	var lock := e.game.empire_rules().lock_on  # The Lock-On lines.
	if lock.paint(e, t, dmg, e.projectile_speed, e.attack_range, "spotter_rail"):
		set_phase(e, PAINTING)
	else:
		e.attack_cd = float(EmpireRulesData.LOCK_ON["retry"])  # Refused at the cap: ask again soon.
	return true


## Holds still while its line is painted; back to marching once it fired.
func physics(e: Enemy, delta: float) -> bool:
	if phase == PAINTING:
		phase_time += delta
		if e.game.empire_rules().lock_on.has_line(e):
			hold(e)
			return true
		set_phase(e, IDLE)
	return false


## A warning-red glow round the body, brighter while it paints. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var k := 1.0 if phase == PAINTING else 0.55  # Glow strength.
	ci.draw_circle(Vector2.ZERO, e.radius * 1.3, Color(Palette.EMPIRE_SIGNAL_RED, 0.12 * k))
	ci.draw_arc(Vector2.ZERO, e.radius * 1.35, 0.0, TAU, 20, Color(Palette.EMPIRE_SIGNAL_RED, 0.5 * k), 1.5)
