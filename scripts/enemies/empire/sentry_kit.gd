## SentryKit — the Sentry Turret's kit (CitadelEnemyData "sentry_turret", kit
## "sentry"; Act III, the Iron Citadel; GDD §15.0 "The Iron Citadel (Act III
## phase 2)"; owner-approved proposal: "Fixed emplacements behind shield walls;
## they never move (structures are the one exception to 'always advance');
## siege them with Catapults and spells; each drops a Soul Ash bounty"). A
## structure and a MACHINE (no corpse). CitadelDirector places it (behind a
## Shield Gate, or in an emplacement) and pays its bounty when it falls.
##   * It turns its barrel toward its target at turn_rate rad/s: the
##     necromancer when he is within attack_range, else the nearest summon in
##     range (a flying Gargoyle is not in the ally grid, so it is never aimed at).
##   * When its burst is due and the barrel is on target, its sensor flares for
##     aim_time s (the telegraph), then it fires burst_rounds bolts burst_gap s
##     apart down the barrel through EmpireShots (style "bolt"): Line of Fire
##     applies to every one, so the army standing between it and him shields him.
## While Stasis, a Deep Freeze or a stun holds it, physics() is not called (it
## waits). Determinism: no RNG; the first burst is staggered by the think slot.
## Stats: sentry_bursts, sentry_bolts (and EmpireShots' los_* counters).
class_name SentryKit
extends EmpireKit

## Phase: the sensor flares before a burst (the telegraph).
const AIMING: int = 1
## Phase: the burst's bolts go out.
const FIRING: int = 2

## Barrel angle (rad, world).
var barrel: float = 0.0
## Seconds until the next burst may start.
var shot_cd: float = 0.0
## Bolts of the current burst still to fire.
var _left: int = 0
## Seconds until the burst's next bolt.
var _gap: float = 0.0
## Index of the next bolt in the burst (its fan offset).
var _index: int = 0
## Current target (the necromancer or a summon; null = none in range).
var _aim: Node2D = null
## Generation of a summon target (stale guard; 0 for the necromancer).
var _aim_gen: int = 0
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	shot_cd = first_cd(e, float(d["first_shot"]))
	var to_p := e.game.player.position - e.position  # It is placed facing the necromancer.
	barrel = to_p.angle() if to_p.length() > 1.0 else 0.0
	_left = 0
	_aim = null


## Picks the target at 5 Hz: the necromancer in range, else the nearest summon.
func think(e: Enemy) -> void:
	var g := e.game
	var reach := e.attack_range
	_aim = null
	if not g.ultimates.player_untargetable() and e.position.distance_to(g.player.position) <= reach:
		_aim = g.player
		_aim_gen = 0
		return
	g.ally_grid.query(e.position, reach, _buf)
	var best := INF
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.DEAD:
			continue
		var dist := e.position.distance_to(u.position)
		if dist < best and dist <= reach:
			best = dist
			_aim = u
			_aim_gen = u.generation


## Turns, aims and fires; never moves.
func physics(e: Enemy, delta: float) -> bool:
	hold(e)
	e.knockback = Vector2.ZERO
	var alive := _aim_alive()
	if alive:
		var want := (_aim.position - e.position).angle()
		var diff := wrapf(want - barrel, -PI, PI)
		var turn := float(d["turn_rate"]) * delta
		barrel += clampf(diff, -turn, turn)
	match phase:
		AIMING:
			phase_time += delta
			if phase_time >= float(d["aim_time"]):
				_left = maxi(1, int(d["burst_rounds"]))
				_index = 0
				_gap = 0.0
				burst_dmg = e.damage * hit_scale(e)  # Time-scaled when the burst begins.
				Sfx.play("turret_fire", e.position)
				e.game.stat_add("sentry_bursts", 1.0)
				set_phase(e, FIRING)
		FIRING:
			_gap -= delta
			if _gap <= 0.0:
				var n := maxi(1, int(d["burst_rounds"]))
				var fan := (float(_index) - float(n - 1) * 0.5) * float(d["burst_spread"])  # Fan offset (rad).
				fire_shot(e, Vector2.from_angle(barrel + fan), burst_dmg)
				e.motion_lunge(Vector2.from_angle(barrel), MotionData.POWER_SHOT)
				e.game.stat_add("sentry_bolts", 1.0)
				_index += 1
				_left -= 1
				_gap = float(d["burst_gap"])
				if _left <= 0:
					set_phase(e, IDLE)
		_:
			shot_cd -= delta
			if shot_cd <= 0.0 and alive:
				var off := absf(wrapf((_aim.position - e.position).angle() - barrel, -PI, PI))  # Aim error (rad).
				if off < 0.25:
					shot_cd = e.attack_interval
					set_phase(e, AIMING)
	if int(e.game.elapsed * 10.0) != int((e.game.elapsed - delta) * 10.0):
		e.queue_redraw()  # The barrel turns (redrawn at 10 Hz).
	return true


## True if the target is still the same living body.
func _aim_alive() -> bool:
	if _aim == null:
		return false
	if _aim is SummonedUnit:
		var u := _aim as SummonedUnit
		return u.active and u.generation == _aim_gen
	return true


## A structure never counts as stuck (the autotest).
func is_busy() -> bool:
	return phase != IDLE


## The barrel (the body sprite is the base) and the sensor flare. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	unmirror(e, ci)
	CitadelGlyphs.draw_turret_barrel(ci, e.radius, barrel, phase == AIMING, clampf(phase_time / maxf(0.01, float(d["aim_time"])), 0.0, 1.0))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
