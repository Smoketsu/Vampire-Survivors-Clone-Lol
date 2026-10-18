## SpawnKit — the Spawn of the Deep's grip (SpireEnemyData "eye_spawn", kit
## "spawn"; GDD §15.0 "Ul-Thalos, the Risen Spire": "tentacled and armoured;
## grabs and holds the nearest summon"). Its body is the shared "melee" AI:
## it always advances on its target and lashes in contact. On top of that:
##   * Grab: when the cooldown is up and a summon stands within grab_range px
##     of its body's edge, it stops and a tentacle reaches for the NEAREST one
##     (a drowned-teal line, grab_windup s). Then that summon is HELD for
##     grab_hold s through the ONE compel path (SummonedUnit.compel(), no
##     speed): it cannot move or attack, the Spawn drags it to its side at
##     grab_pull px/s and squeezes it for grab_damage (time-scaled) every
##     grab_tick s. The Spawn walks and fights on while it holds. Killing the
##     Spawn frees the summon at once.
## Determinism (CLAUDE.md): no RNG; the first grab is staggered by the think
## slot (CovenantKit.first_cd()); "nearest" ties keep the spatial hash's order.
## Stats: spawn_grabs, spawn_grab_squeezes, spawn_grabs_broken (the Spawn
## died holding); damage as summon_dmg_from_spawn_grab (CombatResolver).
class_name SpawnKit
extends CovenantKit

## Phase: the tentacle reaches (the telegraph).
const REACH: int = 1
## Damage source tag of the squeeze (CombatResolver stats).
const SOURCE: String = "spawn_grab"

## Seconds until the next grab may start.
var cd: float = 0.0
## The summon being reached for / held (null = none).
var held: SummonedUnit = null
## Generation of `held` when it was seized (stale guard).
var held_gen: int = 0
## Seconds left of the hold (0 = not holding).
var hold_left: float = 0.0
## Seconds until the next squeeze.
var squeeze_cd: float = 0.0
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d["grab_first"]))
	_release(e)


func on_deactivate(e: Enemy) -> void:
	if hold_left > 0.0 and e.game != null:
		e.game.stat_add("spawn_grabs_broken", 1.0)
	_release(e)
	super.on_deactivate(e)


## Lets go of the held summon (its compulsion ends now).
func _release(e: Enemy) -> void:
	if held != null and held.active and held.generation == held_gen and e.game != null:
		held.compel_until = minf(held.compel_until, e.game.elapsed)
	held = null
	hold_left = 0.0


## True while the held summon is still the same living unit.
func _held_valid() -> bool:
	return held != null and held.active and held.generation == held_gen


func physics(e: Enemy, delta: float) -> bool:
	cd -= delta
	if hold_left > 0.0:
		_step_hold(e, delta)
	if phase == REACH:
		phase_time += delta
		hold(e)
		e.queue_redraw()  # The tentacle reaches.
		if not _held_valid():
			set_phase(e, IDLE)
			held = null
			cd = 1.0
			return false
		if phase_time >= float(d["grab_windup"]):
			_seize(e)
			set_phase(e, IDLE)
		return true
	if cd > 0.0 or hold_left > 0.0:
		return false
	var u := _nearest(e)
	if u == null:
		cd = 0.4
		return false
	held = u
	held_gen = u.generation
	set_phase(e, REACH)
	e.motion_lunge(u.position - e.position, MotionData.POWER_CAST)  # Engine motion: the tentacle lashes out (visual only).
	return true


## The nearest walking summon within grab_range of its body's edge (null = none).
func _nearest(e: Enemy) -> SummonedUnit:
	var reach := float(d["grab_range"])
	e.game.ally_grid.query(e.position, e.radius + reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var best: SummonedUnit = null
	var best_d := INF
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.is_compelled():
			continue
		var dist := u.position.distance_to(e.position) - e.radius - u.radius
		if dist <= reach and dist < best_d:
			best_d = dist
			best = u
	return best


## The tentacle lands: the summon is held fast.
func _seize(e: Enemy) -> void:
	var g := e.game
	var until := g.elapsed + float(d["grab_hold"])
	if not held.compel(e.position, until, 0.0):
		held = null
		cd = 1.0
		return
	hold_left = float(d["grab_hold"])
	squeeze_cd = float(d["grab_tick"])
	cd = float(d["grab_cooldown"]) + hold_left
	g.stat_add("spawn_grabs", 1.0)
	g.effects.ring(held.position, held.radius * 1.8, Palette.EYE_DROWNED, 0.3)
	Sfx.play("abom_stomp", held.position, 1.6)


## Holding: drag the summon to the Spawn's side and squeeze it.
func _step_hold(e: Enemy, delta: float) -> void:
	if not _held_valid() or not held.is_compelled():
		_release(e)  # It died, or the grip ran out while the Spawn was frozen.
		return
	hold_left -= delta
	e.queue_redraw()  # The tentacle follows the held summon.
	var g := e.game
	var side := held.position - e.position
	var dist := side.length()
	var want := e.radius + held.radius + 2.0  # Held against its body.
	if dist > want:
		held.position = held.position.move_toward(e.position + side / dist * want, float(d["grab_pull"]) * delta)
	squeeze_cd -= delta
	if squeeze_cd <= 0.0:
		squeeze_cd += float(d["grab_tick"])
		g.stat_add("spawn_grab_squeezes", 1.0)
		g.combat.damage_unit(held, float(d["grab_damage"]) * hit_scale(e), SOURCE)
	if hold_left <= 0.0:
		_release(e)


## Autopilot / stuck check: busy while reaching (the hold itself walks on).
func is_busy() -> bool:
	return phase != IDLE


## The tentacle: reaching toward the target, then coiled around the held summon.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var target := held if _held_valid() else null
	if target == null or (phase != REACH and hold_left <= 0.0):
		return
	unmirror(e, ci)
	var to := target.position - e.position
	var k := clampf(phase_time / maxf(0.05, float(d["grab_windup"])), 0.0, 1.0) if phase == REACH else 1.0
	SpireGlyphs.draw_tentacle(ci, Vector2.ZERO, to * k, e.radius * 0.45, phase == REACH)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Redraws while the tentacle moves (the overlay follows the held summon).
func think(e: Enemy) -> void:
	if phase == REACH or hold_left > 0.0:
		e.queue_redraw()
