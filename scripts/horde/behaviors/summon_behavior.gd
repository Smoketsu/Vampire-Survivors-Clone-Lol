## SummonBehavior — base class of a summon class's special action, plugged
## into the ONE shared SummonedUnit AI (CLAUDE.md: one data-driven AI, class
## specials only as behaviours). Each unit of a class with a UnitData
## "behavior" key owns one instance (SummonBehaviors.for_unit()), reused while
## the unit is pooled. Its numbers come from `u.special` (UnitData "special",
## scaled by HordeDirector._special_stats()), never from constants here.
##
## Contract with SummonedUnit (every hook is optional to override):
##   think(u)            5 Hz, after the leash checks and only while the unit
##                       is not CASTING. Return true after starting a special
##                       (begin_special()) to skip the rest of think().
##   physics(u, delta)   every tick. Ticks the cooldown; while a special runs
##                       it calls step_special() and owns the tick (returns
##                       true; the unit then only integrates `u.velocity`).
##                       A special runs in the CASTING state: if anything
##                       else changes the state (hard / soft recall), the
##                       special is cancelled (on_cancel()) so leash and
##                       recall always win.
##   release_attack(u)   releases a class-specific attack_profile.
##   melee_bonus(u,e)    damage multiplier of a "melee" strike on `e` (1 =
##                       none; Bone Hound Pack Hunt).
##   on_melee_hit(u,e,dealt)  after a "melee" strike landed (Hellhound burn).
##   score_bonus(u,e,dp) extra target score (GDD §27 class preferences).
##   draw_under(u) / body_lift(u)  telegraphs / shadow and the drawn height.
##   draw_over(u, ci)    overlays drawn after the body on `ci`, the unit's
##                       overlay layer (Cathedral Horror stone).
##   adjust_stats(u) / rooted() / taunt_reach(u)  per-unit stats after
##                       apply_stats(), a root without CASTING, a taunt
##                       (content wave 2: the Bone Golem).
##
## Determinism (CLAUDE.md): only the seeded global RNG, never instance ids.
class_name SummonBehavior
extends RefCounted

## Phase value meaning "no special running".
const IDLE: int = 0

## Behaviour id (UnitData "behavior") this instance implements.
var kind: String = ""
## Current special phase (IDLE, or a subclass-defined phase > 0).
var phase: int = IDLE
## Seconds spent in the current phase.
var phase_time: float = 0.0
## Seconds since the special started (autotest: a special that runs far
## longer than designed counts as a stuck unit).
var special_time: float = 0.0
## Seconds until the special may be used again.
var special_cd: float = 0.0


## Called on every (re)activation of the unit: clears the special and
## randomises the first cooldown so a fresh squad does not act in lockstep.
func reset(u: SummonedUnit) -> void:
	phase = IDLE
	phase_time = 0.0
	special_time = 0.0
	special_cd = randf_range(0.3, 0.8) * cooldown(u)


## Called when the unit dies / is pooled: drops any running special.
func on_deactivate(u: SummonedUnit) -> void:
	if phase != IDLE:
		on_cancel(u)
	phase = IDLE


## Full cooldown of the special in seconds (subclasses read their key).
func cooldown(_u: SummonedUnit) -> float:
	return 1.0


## True while a special is running.
func is_busy() -> bool:
	return phase != IDLE


## 5 Hz decision hook; true when a special was started.
func think(_u: SummonedUnit) -> bool:
	return false


## Per-tick hook: cooldown, cancellation, then the running special.
func physics(u: SummonedUnit, delta: float) -> bool:
	if special_cd > 0.0:
		special_cd -= delta
	if phase == IDLE:
		return false
	if u.state != SummonedUnit.State.CASTING:
		# Recalled (or otherwise interrupted): the FSM wins over the special.
		on_cancel(u)
		phase = IDLE
		u.game.stat_add("summon_specials_cancelled", 1.0)
		return false
	phase_time += delta
	special_time += delta
	u.queue_redraw()
	return step_special(u, delta)


## Advances the running special; true while it owns the tick.
func step_special(_u: SummonedUnit, _delta: float) -> bool:
	return false


## Cleans up a special that was interrupted (land, drop references...).
func on_cancel(_u: SummonedUnit) -> void:
	pass


## Releases a class-specific attack profile at the end of a normal windup.
func release_attack(_u: SummonedUnit) -> void:
	pass


## Damage multiplier of the unit's next "melee" strike on `e` (1 = none).
func melee_bonus(_u: SummonedUnit, _e: Enemy) -> float:
	return 1.0


## Called after a "melee" strike on `e` dealt `dealt` (e may have died).
func on_melee_hit(_u: SummonedUnit, _e: Enemy, _dealt: float) -> void:
	pass


## Extra target score for enemy `e` (`dp` = its distance to the player).
func score_bonus(_u: SummonedUnit, _e: Enemy, _dp: float) -> float:
	return 0.0


## Draws telegraphs / shadows before the body (inside u._draw()).
func draw_under(_u: SummonedUnit) -> void:
	pass


## Draws overlays after the body on `_ci`, the unit's overlay layer (engine
## motion, UnitMotion; inside that layer's _draw()).
func draw_over(_u: SummonedUnit, _ci: CanvasItem) -> void:
	pass


## Height in px the body is drawn above its ground position.
func body_lift(_u: SummonedUnit) -> float:
	return 0.0


# --- Content wave 2: Bone Golem (generic hooks; no-ops for every other class) ---

## Per-unit stat adjustment at the end of SummonedUnit.apply_stats(), after
## the director's effective stats were copied (Bone Golem: Ossuary Hunger's max
## HP growth and the Bulwark's block mass). Must change nothing once reset.
func adjust_stats(_u: SummonedUnit) -> void:
	pass


## True while the special roots the unit in place without CASTING: it cannot
## walk, but it still thinks and attacks (Bone Golem Bulwark).
func rooted() -> bool:
	return false


## Taunt reach in px the unit has right now (ColossusKit.refresh(); Bone
## Golem Bulwark); 0 = none.
func taunt_reach(_u: SummonedUnit) -> float:
	return 0.0


# =====================================================================================
# Helpers for subclasses
# =====================================================================================

## Starts a special: the unit stops and enters CASTING in phase `p`.
func begin_special(u: SummonedUnit, p: int) -> void:
	phase = p
	phase_time = 0.0
	special_time = 0.0
	special_cd = cooldown(u)
	u.velocity = Vector2.ZERO
	u.set_state(SummonedUnit.State.CASTING)
	u.queue_redraw()


## Moves to phase `p` of the running special.
func next_phase(p: int) -> void:
	phase = p
	phase_time = 0.0


## Ends the special and hands the unit back to the shared FSM in `s`.
func end_special(u: SummonedUnit, s: SummonedUnit.State) -> void:
	phase = IDLE
	phase_time = 0.0
	u.velocity = Vector2.ZERO
	u.set_state(s)
	u.queue_redraw()


## Number of living enemies within `r` px of `pos` (body edges included).
static func count_enemies(game: Game, pos: Vector2, r: float, buf: Array) -> int:
	game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, buf)
	var n := 0  # Enemies inside.
	for e: Enemy in buf:
		if e.active and e.position.distance_to(pos) <= r + e.radius * 0.5:
			n += 1
	return n


## Applies the unit's mirrored drawing transform reset (bodies are flipped
## through scale.x), so telegraphs can be drawn in world-aligned local space.
static func world_space(u: SummonedUnit) -> void:
	u.draw_set_transform(Vector2.ZERO, 0.0, Vector2(signf(u.scale.x) if u.scale.x != 0.0 else 1.0, 1.0))


## Restores the default drawing transform after world_space().
static func body_space(u: SummonedUnit) -> void:
	u.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
