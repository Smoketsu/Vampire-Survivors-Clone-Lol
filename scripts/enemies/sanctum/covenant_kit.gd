## CovenantKit — base class of a Covenant kind's special actions (the Sanctum
## of Judgment kinds, SanctumEnemyData "kit"), plugged into the ONE shared,
## data-driven Enemy AI the same way SummonBehavior plugs into SummonedUnit.
## Each enemy whose row has a "kit" key owns one instance
## (CovenantKits.for_enemy()), reused while the enemy is pooled. Its numbers
## come from the kind's row (`d`), never from constants here.
##
## Contract with Enemy (every hook is optional to override):
##   reset(e, def)       on every activation (end of Enemy.activate()).
##   on_deactivate(e)    the enemy died, despawned or was pooled.
##   on_killed(e)        the enemy was killed (before it is pooled;
##                       CovenantRites calls it from EnemyDirector).
##   think(e)            5 Hz, at the start of Enemy.think() (after an aura
##                       pulse), before the default target choice.
##   physics(e, delta)   every unfrozen tick, after the shared timers. Return
##                       true while a special owns the tick (windup / cast /
##                       recovery): the enemy then stands still; Enemy only
##                       resolves warrior blocking afterwards.
##   danger_push(e, p)   autotest autopilot hint: a push away from this
##                       kit's live telegraph at `p` (zero when none).
##   draw_under(e) / draw_over(e, ci)  drawn before / after the body
##                       (draw_over on `ci`, the enemy's overlay layer).
## While Stasis, a Deep Freeze or a dive stun holds the enemy, physics() is
## not called, so its windups pause with it (telegraph effects are tied to
## the enemy and pause too).
## Determinism (CLAUDE.md): no RNG and no instance ids; first cooldowns are
## staggered by the enemy's think slot (first_cd()).
class_name CovenantKit
extends RefCounted

## Phase value meaning "no special running".
const IDLE: int = 0
## Seconds of first-cooldown stagger per think slot (0..11), so a squad
## spawned together does not act in lockstep.
const SLOT_STAGGER: float = 0.15

## Kit id (SanctumEnemyData "kit") this instance implements.
var kind: String = ""
## The enemy's design row (SanctumEnemyData.ENEMIES entry).
var d: Dictionary = {}
## Current special phase (IDLE, or a subclass-defined phase > 0).
var phase: int = IDLE
## Seconds spent in the current phase.
var phase_time: float = 0.0


## Called on every activation: keeps the row and clears the special.
func reset(_e: Enemy, def: Dictionary) -> void:
	d = def
	phase = IDLE
	phase_time = 0.0


## Called when the enemy leaves the field (killed, despawned, pooled).
func on_deactivate(_e: Enemy) -> void:
	phase = IDLE


## Called when the enemy is killed, before it is pooled.
func on_killed(_e: Enemy) -> void:
	pass


## 5 Hz decision hook.
func think(_e: Enemy) -> void:
	pass


## Per-tick hook; true while a special owns the tick.
func physics(_e: Enemy, _delta: float) -> bool:
	return false


## True while a special runs (the autotest's stuck check skips the enemy).
func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: push away from this kit's telegraph at `p`.
func danger_push(_e: Enemy, _p: Vector2) -> Vector2:
	return Vector2.ZERO


## Drawn before the enemy's body (telegraph accents, auras).
func draw_under(_e: Enemy) -> void:
	pass


## Drawn after the enemy's body on `_ci`, its overlay layer (casting glows,
## beams; engine motion, UnitMotion).
func draw_over(_e: Enemy, _ci: CanvasItem) -> void:
	pass


## Changes phase, resets its timer and redraws the enemy.
func set_phase(e: Enemy, p: int) -> void:
	phase = p
	phase_time = 0.0
	e.queue_redraw()


## Standing still during a windup / cast / recovery.
func hold(e: Enemy) -> void:
	e.velocity = Vector2.ZERO


## First cooldown: `first` s plus the think-slot stagger (no RNG).
static func first_cd(e: Enemy, first: float) -> float:
	return first + float(e.think_slot) * SLOT_STAGGER


## Body radius of the necromancer or a summon (`n` is one of them).
static func body_radius(e: Enemy, n: Node2D) -> float:
	if n is SummonedUnit:
		return (n as SummonedUnit).radius
	return e.game.player.radius


## Enemy damage multiplier of a special: the time scaling (and difficulty)
## times the enemy's aura buff, like every Covenant hit.
static func hit_scale(e: Enemy) -> float:
	return e.game.enemies.damage_mult * e.hit_mult()


## Makes the enemy's draw calls use world-axis offsets from its centre: the
## node is mirrored by scale.x to face its movement, so this applies the same
## mirror again (scale.x is +-1, its own inverse). Reset with
## e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE). `ci` (default: the
## enemy itself) is the canvas being drawn, e.g. its overlay layer.
static func unmirror(e: Enemy, ci: CanvasItem = null) -> void:
	(ci if ci != null else e).draw_set_transform(Vector2.ZERO, 0.0, Vector2(e.scale.x, 1.0))


## True if a body of radius `r` at `p` lies inside the sector at `origin`
## facing `dir` (`reach` px, `half_angle` rad each side); a body touching
## the origin's own body (`own_r`) is always inside.
static func in_sector(origin: Vector2, dir: Vector2, reach: float, half_angle: float, own_r: float, p: Vector2, r: float) -> bool:
	var rel := p - origin
	var dist := rel.length()
	if dist > reach + r:
		return false
	if dist < own_r + r:
		return true
	return absf(dir.angle_to(rel)) <= half_angle
