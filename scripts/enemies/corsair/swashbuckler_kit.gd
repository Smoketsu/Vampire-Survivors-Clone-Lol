## SwashbucklerKit — the kit of the Swashbuckler (CorsairEnemyData
## "swashbuckler"; Act X, the Black Tide; a woman in the figure-redesign style;
## owner-approved proposal: "Rapier lunge that jumps the first blocker and
## duels the nearest summon | Rogues, Gargoyles, area damage"). Every lunge
## "every" s, when a summon stands within lunge "range" px, she settles
## (windup s), then LUNGES at lunge "speed" toward where it stood, past any
## blocker in between (physics() owns the move), and runs it through
## (CombatResolver.damage_unit(), lunge "damage" x the enemies' damage
## scaling); then she duels it with the shared melee AI (her target).
## Determinism: no RNG (her first lunge staggered by her think slot).
class_name SwashbucklerKit
extends CorsairKit

## Phase: she settles before the lunge.
const WINDUP: int = 1
## Phase: the lunge itself.
const LUNGE: int = 2

## Seconds until she may lunge again.
var lunge_cd: float = 0.0
## The summon she lunges at (null otherwise).
var mark: SummonedUnit = null
## Pool generation of `mark` (stale guard).
var mark_gen: int = 0
## Where she lunges to (world px).
var lunge_to: Vector2 = Vector2.ZERO


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	lunge_cd = first_cd(e, float((d.get("lunge", {}) as Dictionary).get("every", 5.0)) * 0.5)
	mark = null
	mark_gen = 0


func on_deactivate(e: Enemy) -> void:
	mark = null
	super.on_deactivate(e)


func physics(e: Enemy, delta: float) -> bool:
	if super.physics(e, delta):
		return true
	var l: Dictionary = d.get("lunge", {})
	lunge_cd -= delta
	match phase:
		WINDUP:
			phase_time += delta
			hold(e)
			if mark == null or not mark.active or mark.generation != mark_gen:
				set_phase(e, IDLE)
				return false
			if phase_time >= float(l.get("windup", 0.4)):
				lunge_to = mark.position
				set_phase(e, LUNGE)
			return true
		LUNGE:
			phase_time += delta
			var to := lunge_to - e.position
			var step := float(l.get("speed", 420.0)) * delta
			if to.length() <= step + e.radius or phase_time > 0.6:
				if to.length() > 0.01:
					e.position = lunge_to - to.normalized() * minf(to.length(), e.radius)  # Beside it, not on it.
				if mark != null and mark.active and mark.generation == mark_gen:
					# Locals: the hit can kill her (thorns), and on_deactivate() then clears `mark` mid-call.
					var m: SummonedUnit = mark  # The summon hit by this lunge.
					var m_gen: int = mark_gen  # Its pool generation when marked (stale guard for e.target).
					e.game.combat.damage_unit(m, float(l.get("damage", 9.0)) * hit_scale(e), e.kind, e)
					if e.active:
						e.target = m
						e.target_gen = m_gen
				e.game.stat_add("swashbuckler_lunges", 1.0)
				rules(e).play_sound("cutlass_clash", e.position, 0.2)
				lunge_cd = float(l.get("every", 5.0))
				set_phase(e, IDLE)
				return false
			e.position += to.normalized() * step
			e.velocity = Vector2.ZERO
			return true
	if lunge_cd > 0.0:
		return false
	var best: SummonedUnit = null
	var best_d := INF
	var tmp: Array = []
	e.game.ally_grid.query(e.position, float(l.get("range", 120.0)) + UnitData.MAX_BLOCK_RADIUS, tmp)
	for u: SummonedUnit in tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne or u.flies:
			continue
		var dist := u.position.distance_to(e.position)
		if dist > 30.0 and dist <= float(l.get("range", 120.0)) and dist < best_d:
			best = u
			best_d = dist
	if best == null:
		lunge_cd = 0.5
		return false
	mark = best
	mark_gen = best.generation
	set_phase(e, WINDUP)
	return true
