## PantheonKit — base class of the Olympian Republic's kits (Act IV; GDD §15.0
## "Act IV foundation (phase 1)"), a CovenantKit plugged into the shared Enemy
## AI like every kit. Kits load by name from scripts/enemies/pantheon/<id>_kit.gd
## (CovenantKits, after the Eye's and the Empire's folders; an id must not
## repeat an Eye or Empire kit's id). What every Pantheon kind shares:
##   * the FACING: the way its shield (and its front) points. It turns toward
##     what the kind fights (its target: a summon or the necromancer) at
##     PantheonRulesData.PHALANX turn_rate rad/s. The Phalanx's shoulder-to-
##     shoulder test and PantheonRules.hit_from_front() (the one direction
##     test: the Phalanx, phase 2's Achilles' heel and the Legionary's testudo)
##     read it through PantheonRules.facing_of().
##   * the PHALANX state the Phalanx node writes (locked, wall, broken_until)
##     and the free pace it restores when a wall breaks (free_speed).
##   * the row flags as helpers: is_bronze() (Zeus's lightning chains to it),
##     is_phalanx(), is_hero() (Glory), is_fodder() (Poseidon's waves drown it).
##   * creating the shared rules on first use (Game.pantheon_rules()), so a
##     Pantheon kind forced onto any stage with --spawn= still locks shields and
##     carries Glory there (as Act III's Empire kinds do).
## Phase 2 kinds extend this class (override physics() for a windup and call
## super.physics() first; draw_over() for their own marks) and use turn_to()
## / front_point() / rules() below.
## Determinism: no RNG, no instance ids.
class_name PantheonKit
extends CovenantKit

## Unit direction the kind faces (its shield's front; world axes).
var facing: Vector2 = Vector2.RIGHT
## True while this body is locked into a shield wall (Phalanx).
var locked: bool = false
## Id of the wall it is locked into (-1 = none): the lock check's component id.
var wall: int = -1
## Game time (s) until which this body cannot lock (a broken wall's pause).
var broken_until: float = 0.0
## Its own move speed (px/s) outside a wall (-1 until its first tick: the
## director applies the difficulty's speed after activation).
var free_speed: float = -1.0
## Index in the current lock check's member list (Phalanx scratch, -1 = not a member).
var idx: int = -1
## Facing angle (rad) at the last redraw (redraw only on a visible turn).
var _drawn_angle: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	var to := e.game.player.position - e.position  # Toward the necromancer.
	facing = to.normalized() if to.length_squared() > 0.01 else Vector2.LEFT
	_drawn_angle = facing.angle()
	locked = false
	wall = -1
	broken_until = 0.0
	free_speed = -1.0
	idx = -1
	e.game.pantheon_rules()  # The shared rules exist wherever a Pantheon kind walks.


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	locked = false
	wall = -1


## Turns the facing toward the kind's target and records its free pace; never
## holds the enemy (returns false). A subclass calls super.physics() first.
func physics(e: Enemy, delta: float) -> bool:
	if free_speed < 0.0:
		free_speed = e.move_speed
	var aim := e.target.position if e.target != null and is_instance_valid(e.target) else e.game.player.position  # What it faces.
	turn_to(e, aim, delta)
	return false


## Turns the facing toward world point `at` by at most turn_rate x `delta`
## rad; redraws the enemy when the turn is visible.
func turn_to(e: Enemy, at: Vector2, delta: float) -> void:
	var to := at - e.position
	if to.length_squared() <= 1.0:
		return
	var cur := facing.angle()
	var diff := wrapf(to.angle() - cur, -PI, PI)
	var rate := float(PantheonRulesData.PHALANX["turn_rate"]) * delta  # Most it turns this tick (rad).
	facing = Vector2.from_angle(cur + clampf(diff, -rate, rate))
	if absf(wrapf(facing.angle() - _drawn_angle, -PI, PI)) > 0.12:
		_drawn_angle = facing.angle()
		e.queue_redraw()


## World point of the front of the body (its shield face), `extra` px out.
func front_point(e: Enemy, extra: float = 2.0) -> Vector2:
	return e.position + facing * (e.radius + extra)


## The shared rules (created on first use).
static func rules(e: Enemy) -> PantheonRules:
	return e.game.pantheon_rules()


## True for a bronze-clad kind (row "bronze": Zeus's lightning chains to it).
func is_bronze() -> bool:
	return bool(d.get("bronze", false))


## True for a kind that can lock shields (row "phalanx").
func is_phalanx() -> bool:
	return bool(d.get("phalanx", false))


## True for a kind that carries Glory (row "hero").
func is_hero() -> bool:
	return bool(d.get("hero", false))


## True for fodder (row "fodder": Poseidon's waves drown it).
func is_fodder() -> bool:
	return bool(d.get("fodder", false))
