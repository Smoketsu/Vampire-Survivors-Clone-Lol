## AttackHelicopterKit — the kit of the Attack Helicopter (CityEnemyData
## "attack_helicopter"; Act VIII, Fort Kessler; GDD §15.0 "Fort Kessler (Act
## VIII phase 2)"; owner-approved proposal: "Attack Helicopter | Vehicle,
## flying | Strafing runs over the ring, rocket pods | Gargoyles, Archers and
## spells"). A VEHICLE row (Convoy counts it, the bot reads its lane, a dead
## one leaves a wreck) that never drives the streets and never runs anything
## over: it FLIES (row "flies": no summon body-blocks it; "phases": it passes
## over the roofs). This kit owns every tick:
##   * BANK: it flies (turn_time s at most) to the start of its next STRAFING
##     RUN: the street lane through the necromancer (CityBlocks.lane(); off a
##     blocks stage a straight line through him), run_half px behind him; the
##     runs alternate between the two street axes.
##   * RUN: it flies the lane at its move_speed to run_half px past him. While
##     the necromancer stands within rocket_reach px of the lane, every
##     rocket_every s it fires a ROCKET POD: a landing circle rocket_lead px
##     ahead of it on the lane (CityShells, the one shell path; rocket_radius
##     px, landing after rocket_windup s for rocket_damage, summons and the
##     necromancer only, source CityEnemyData.HELI_ROCKET_SOURCE: ranged).
##   * ROTOR HEIGHT (taken_mult(), the kit hook Enemy.damage_taken_mult()
##     reads): a MELEE summon's hit deals melee_mult (a summon class whose base
##     attack range is under PassiveData.OVERCLOCK_MIN_RANGE; the Gargoyle's
##     dive excepted). Archers, Mages, Gargoyles, every ranged class and every
##     spell hit it in full: "Gargoyles, Archers and spells answer it".
##   * THE CRASH: shot down, it falls onto the nearest street centre line (a
##     wreck never lands on a roof) and leaves its wreck there (Convoy).
## Determinism: no RNG (the axis alternates, the side follows the necromancer).
## Stats: heli_runs, heli_rockets, heli_melee_cut, heli_crash_moved.
class_name AttackHelicopterKit
extends CityKit

## Flight phase: banking round to the next run's start.
const BANK: int = 1
## Flight phase: on a strafing run.
const RUN: int = 2
## px within which it counts as at its run's start.
const ARRIVE: float = 12.0  # TUNING (not in GDD)
## x its move_speed while it banks round (it hurries to the next run).
const BANK_SPEED: float = 1.3  # TUNING (not in GDD)
## px its ground shadow is drawn below its body (its altitude, visual only).
const SHADOW_DROP: float = 26.0  # TUNING (not in GDD)

## Its flight phase (BANK / RUN).
var flight: int = BANK
## Seconds in the current flight phase.
var _flight_t: float = 0.0
## The current run's start (world px).
var _start: Vector2 = Vector2.ZERO
## The current run's end (world px).
var _end: Vector2 = Vector2.ZERO
## The street axis of the next run (0 along x, 1 along y).
var _next_axis: int = 0
## Seconds until its next rocket pod.
var _rocket_cd: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_next_axis = e.think_slot % 2
	_rocket_cd = 0.0
	_plan_run(e)


## Plans the next strafing run through the nearest necromancer's street and
## banks toward its start.
func _plan_run(e: Enemy) -> void:
	var tp := e.game.nearest_player(e.position).position
	var dir := Vector2.RIGHT if _next_axis == 0 else Vector2.DOWN
	if (tp - e.position).dot(dir) < 0.0:
		dir = -dir  # In from the side it is on.
	var through := tp
	var cb := e.game.arena.city_blocks
	if cb != null:
		var ln := cb.lane(tp, dir)
		dir = ln["dir"]
		through = ln["point"]
	var half := float(d.get("run_half", 520.0))
	_start = through - dir * half
	_end = through + dir * half
	drive_dir = dir
	_next_axis = 1 - _next_axis
	flight = BANK
	_flight_t = 0.0


func physics(e: Enemy, delta: float) -> bool:
	_flight_t += delta
	var spd := e.move_speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
	if flight == BANK:
		var to := _start - e.position
		var step := spd * BANK_SPEED * delta
		if to.length() <= maxf(step, ARRIVE) or _flight_t >= float(d.get("turn_time", 2.4)):
			e.position = _start if to.length() <= maxf(step, ARRIVE) else e.position + to.normalized() * step
			flight = RUN
			_flight_t = 0.0
			e.game.stat_add("heli_runs", 1.0)
			rules(e).play_sound("rotor_pass", e.position, 0.8)
		else:
			e.position += to.normalized() * step
			e.velocity = to.normalized() * spd * BANK_SPEED
	if flight == RUN:
		e.position += drive_dir * spd * delta
		e.velocity = drive_dir * spd
		_rocket_cd -= delta
		if _rocket_cd <= 0.0:
			_rocket_cd = float(d.get("rocket_every", 0.55))
			_fire_rocket(e)
		if (e.position - _end).dot(drive_dir) >= 0.0:
			_plan_run(e)
	facing = drive_dir if flight == RUN else (e.velocity.normalized() if e.velocity.length() > 1.0 else drive_dir)
	e._update_facing()
	return true


## One rocket pod: a landing circle ahead on the lane, while the necromancer
## stands near the lane.
func _fire_rocket(e: Enemy) -> void:
	var tp := e.game.nearest_player(e.position).position
	var rel := tp - e.position
	var perp := Vector2(-drive_dir.y, drive_dir.x)
	var reach := float(d.get("rocket_reach", 360.0))
	if absf(rel.dot(perp)) > reach or rel.dot(drive_dir) < -reach:
		return  # He is far off the lane, or already behind it.
	var at := e.position + drive_dir * float(d.get("rocket_lead", 150.0))
	rules(e).shells.add(at, float(d.get("rocket_windup", 0.9)), float(d.get("rocket_radius", 30.0)),
			float(d.get("rocket_damage", 4.0)) * hit_scale(e), CityEnemyData.HELI_ROCKET_SOURCE, false)
	e.game.stat_add("heli_rockets", 1.0)


## ROTOR HEIGHT: a melee summon's hit deals melee_mult; every other hit in full.
func taken_mult(e: Enemy, source: String) -> float:
	var cls := String(SynergyData.SOURCE_CLASS.get(source, source))  # The hit's summon class (or the tag itself).
	if cls == "gargoyle" or not UnitData.UNITS.has(cls):
		return 1.0  # The Gargoyle's dive, a spell, the necromancer: full.
	if float((UnitData.UNITS[cls] as Dictionary).get("attack_range", 0.0)) >= PassiveData.OVERCLOCK_MIN_RANGE:
		return 1.0  # A ranged class (Archers, Mages, ...).
	e.game.stat_add("heli_melee_cut", 1.0)
	return float(d.get("melee_mult", 0.5))


## THE CRASH: it falls onto the nearest street centre line first, so its
## wreck takes a street cell (Convoy.wreck_vehicle(), through CityKit).
func on_killed(e: Enemy) -> void:
	var cb := e.game.arena.city_blocks
	if cb != null and not (cb.in_h_street(e.position) or cb.in_v_street(e.position)):
		var hy := cb.h_street_y(cb.h_street(e.position))
		var vx := cb.v_street_x(cb.v_street(e.position))
		if absf(e.position.y - hy) <= absf(e.position.x - vx):
			e.position.y = hy
		else:
			e.position.x = vx
		e.game.stat_add("heli_crash_moved", 1.0)
	super.on_killed(e)


func is_busy() -> bool:
	return true  # It never walks: the stuck check skips it.


## Its shadow on the ground below it (its altitude); no headlights.
func draw_under(e: Enemy) -> void:
	e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-e.radius * 1.2, SHADOW_DROP - e.radius * 0.35), Vector2(e.radius * 2.4, e.radius * 0.7)), false, Color(0.0, 0.0, 0.0, 0.3))
