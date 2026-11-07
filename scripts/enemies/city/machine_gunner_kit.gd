## MachineGunnerKit — the kit of the Machine Gunner (CityEnemyData
## "machine_gunner"; Act VIII, Fort Kessler; GDD §15.0 "Fort Kessler (Act VIII
## phase 2)"; owner-approved proposal: "Machine Gunner | Heavy ranged | Sets up
## and sweeps a telegraphed fire lane | Grave Step; Bone Wall in the lane"). An
## army soldier who walks in like a rifleman; when the shared ranged attack is
## due (fire_ranged(): his target within attack_range, every attack_interval s)
## he SETS UP instead of shooting:
##   * SET-UP (setup_time s): he kneels behind the gun; the FIRE LANE shows (a
##     gradient strip, lane_length px long and lane_half px each side, at its
##     start angle; the end of the sweep faint behind it). The telegraph.
##   * SWEEP (sweep_time s): the lane turns through sweep_arc rad across where
##     his target stood (the side it starts from alternates by think slot), and
##     every `tick` s every summon and necromancer inside it takes tick_damage
##     (CombatResolver.damage_unit() / damage_player(), source
##     CityEnemyData.MG_SOURCE: a ranged source for Kevlar Bones; Grave Step's
##     i-frames dodge it there). A BONE WALL segment in the lane (any
##     necromancer's, BoneWall.covers()) stops the lane at the wall: nothing
##     behind it is hit. Buildings do not stop it (the act's rule: buildings
##     block no shot). Airborne summons fly over it.
##   * PACK-UP (pack_time s): he stands, then walks on.
## While set up he does not move (an enemy attack, not a summon rule). The
## autotest bot steps out of the swept sector ahead of the lane (danger_push()).
## Determinism: no RNG (the sweep side comes from the think slot). Stats:
## mg_setups, mg_ticks, mg_hits_summons, mg_hits_you, mg_walled.
class_name MachineGunnerKit
extends CityKit

## Phase: kneeling, the lane telegraphed.
const SETUP: int = 1
## Phase: the lane sweeps and fires.
const SWEEP: int = 2
## Phase: packing up the gun.
const PACK: int = 3
## px between two probes of the lane for a Bone Wall segment.
const WALL_PROBE: float = 14.0  # TUNING (not in GDD) a cost cap (about 21 probes a tick)
## px the autotest bot keeps from the swept sector beyond the lane's width.
const DANGER_MARGIN: float = 22.0  # TUNING (not in GDD) autotest hint only

## Angle (rad) of the lane where the sweep starts.
var _a0: float = 0.0
## Angle (rad) of the lane where the sweep ends.
var _a1: float = 0.0
## The lane's current angle (rad).
var _angle: float = 0.0
## px of the lane that reaches (lane_length, or shorter behind a Bone Wall).
var _reach: float = 0.0
## Seconds toward the lane's next hit.
var _tick_acc: float = 0.0
## True once a Bone Wall stopped the lane in this sweep (counted once).
var _walled: bool = false
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_reach = 0.0
	_walled = false


func fire_ranged(e: Enemy, t: Node2D, dir: Vector2, _dmg: float) -> bool:
	if phase != IDLE:
		return true  # Already set up: the shared attack is spent on the lane.
	var aim := dir.angle()
	if t != null:
		var to := t.position - e.position
		if to.length() > 1.0:
			aim = to.angle()
	var half := float(d.get("sweep_arc", 0.9)) * 0.5
	var side := 1.0 if (e.think_slot % 2) == 0 else -1.0  # The sweep's direction (no RNG).
	_a0 = aim - half * side
	_a1 = aim + half * side
	_angle = _a0
	_reach = float(d.get("lane_length", 300.0))
	_walled = false
	_tick_acc = 0.0
	facing = Vector2.from_angle(aim)
	set_phase(e, SETUP)
	e.game.stat_add("mg_setups", 1.0)
	return true


func physics(e: Enemy, delta: float) -> bool:
	if phase == IDLE:
		return super.physics(e, delta)
	phase_time += delta
	hold(e)
	match phase:
		SETUP:
			_reach = _lane_reach(e)
			if phase_time >= float(d.get("setup_time", 1.2)):
				set_phase(e, SWEEP)
				rules(e).play_sound("mg_sweep", e.position, 0.3)
		SWEEP:
			var span := maxf(float(d.get("sweep_time", 2.2)), 0.01)
			_angle = lerpf(_a0, _a1, clampf(phase_time / span, 0.0, 1.0))
			facing = Vector2.from_angle(_angle)
			_tick_acc += delta
			var tick := float(d.get("tick", 0.2))
			if _tick_acc >= tick:
				_tick_acc -= tick
				_fire(e)
			if phase_time >= span:
				set_phase(e, PACK)
		PACK:
			if phase_time >= float(d.get("pack_time", 0.6)):
				set_phase(e, IDLE)
	e.queue_redraw()
	return true


## The lane's length from `e` along its current angle: lane_length, or up to
## the first Bone Wall segment of any necromancer in it.
func _lane_reach(e: Enemy) -> float:
	var g := e.game
	var full := float(d.get("lane_length", 300.0))
	var dir := Vector2.from_angle(_angle)
	var walls: Array[BoneWall] = []  # Every necromancer's Bone Wall node that exists.
	for k in g.all_players.size():
		var prev := g.bind_index(k)
		var wall: BoneWall = g.abilities.spells.nodes.get("bone_wall")  # Null until a wall exists.
		g.unbind(prev)
		if wall != null:
			walls.append(wall)
	if walls.is_empty():
		return full
	var s := WALL_PROBE
	while s < full:
		var p := e.position + dir * s
		for w in walls:
			if w.covers(p, float(d.get("lane_half", 10.0))):
				return s
		s += WALL_PROBE
	return full


## One hit of the lane: every summon and necromancer inside it.
func _fire(e: Enemy) -> void:
	var g := e.game
	var full := float(d.get("lane_length", 300.0))
	_reach = _lane_reach(e)
	if _reach < full - 0.5 and not _walled:
		_walled = true
		g.stat_add("mg_walled", 1.0)
	g.stat_add("mg_ticks", 1.0)
	var dir := Vector2.from_angle(_angle)
	var perp := Vector2(-dir.y, dir.x)
	var half := float(d.get("lane_half", 10.0))
	var dmg := float(d.get("tick_damage", 1.4)) * hit_scale(e)
	var mid := e.position + dir * _reach * 0.5
	g.ally_grid.query(mid, _reach * 0.5 + half + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
			continue
		var rel := u.position - e.position
		var along := rel.dot(dir)
		if along < 0.0 or along > _reach + u.radius or absf(rel.dot(perp)) > half + u.radius:
			continue
		g.combat.damage_unit(u, dmg * e.undead_damage_mult, CityEnemyData.MG_SOURCE, e)
		g.stat_add("mg_hits_summons", 1.0)
	for pl in g.all_players:
		if pl.dead:
			continue
		var rel := pl.position - e.position
		var along := rel.dot(dir)
		if along < 0.0 or along > _reach + pl.radius or absf(rel.dot(perp)) > half + pl.radius:
			continue
		g.combat.damage_player(dmg, CityEnemyData.MG_SOURCE, pl, e)
		g.stat_add("mg_hits_you", 1.0)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	_reach = 0.0


## Autopilot hint: out of the sector the lane has still to sweep (set-up and
## sweep), sideways toward the side the lane has already passed.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != SETUP and phase != SWEEP:
		return Vector2.ZERO
	var rel := p - e.position
	var dist := rel.length()
	if dist > _reach + DANGER_MARGIN or dist < 1.0:
		return Vector2.ZERO
	var sgn := signf(_a1 - _a0) if _a1 != _a0 else 1.0
	var a := wrapf(rel.angle() - _angle, -PI, PI) * sgn  # How far ahead of the lane (rad, in the sweep's sense).
	var margin := atan2(float(d.get("lane_half", 10.0)) + DANGER_MARGIN, dist)
	var left := absf(_a1 - _angle)  # Sweep still to come (rad).
	if a < -margin or a > left + margin:
		return Vector2.ZERO
	var tangent := Vector2(-rel.y, rel.x).normalized() * sgn  # The sweep's direction at `p`.
	return -tangent * 2.0  # Behind the lane: where it has already been.


## The lane: during the set-up a faint strip at its start (and fainter at its
## end), during the sweep a bright red-orange strip (textures only).
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	if phase != SETUP and phase != SWEEP:
		return
	var xf := CourtGlyphs.unmirror_xf(e)
	var half := float(d.get("lane_half", 10.0))
	if phase == SETUP:
		var k := clampf(phase_time / maxf(float(d.get("setup_time", 1.2)), 0.01), 0.0, 1.0)
		CityGlyphs.draw_headlights(e, Vector2.ZERO, Vector2.from_angle(_a1), float(d.get("lane_length", 300.0)), half, 0.1 + 0.08 * k, xf, Palette.CITY_SIREN_RED)
		CityGlyphs.draw_headlights(e, Vector2.ZERO, Vector2.from_angle(_a0), _reach, half, 0.2 + 0.3 * k, xf, Palette.CITY_SIREN_RED)
	else:
		CityGlyphs.draw_headlights(e, Vector2.ZERO, Vector2.from_angle(_angle), _reach, half, 0.6, xf, Palette.CITY_HERO_ORANGE)
	e.draw_set_transform_matrix(Transform2D.IDENTITY)
