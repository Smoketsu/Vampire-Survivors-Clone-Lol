## CityKit — base class of the Last Line's kits (Act VIII; GDD §15.0 "Act VIII
## foundation (phase 1)"), a CovenantKit plugged into the shared Enemy AI like
## every kit. Kits load by name from scripts/enemies/city/<id>_kit.gd
## (CovenantKits, after the Eye's, the Empire's, the Pantheon's, the
## Shogunate's, the Inferno's and the Court's folders; an id must not repeat
## theirs). What every City kind shares:
##   * creating the shared rules on first use (Game.city_rules()), so a City
##     kind forced onto any stage with --spawn= still has its front, its
##     vehicle and its Super kit there (the escalation, the civilians and Martial
##     Law stay off off Act VIII);
##   * the row flags as helpers: tier(), armour_front() (Armour's front share),
##     is_vehicle(), is_civilian(), super_def();
##   * THE FACING (`facing`): toward its foe (else along its walk); a vehicle's
##     is its drive direction. Armour.hit_from_front() reads it (the one front
##     test of the act, like Act IV's Phalanx);
##   * THE DRIVE of a VEHICLE (row "vehicle": physics() owns every tick, an
##     enemy attack, not a summon rule): it snaps onto the street lane nearest
##     to it (CityBlocks.lane(); it spawns off screen), drives straight along it
##     toward the necromancer's street (one turn at a crossing onto his street
##     when it is another), past him by `overrun` px, turns (turn_time s) and
##     comes again; a wreck (or any obstacle) ahead is RAMMED: it stops for
##     ram_stop s, loses ram_damage of its max HP (a wreck only) and turns;
##     every tick it RUNS OVER what is in its body box (Convoy.run_over()); its
##     HEADLIGHTS show the lane `headlight_time` s ahead (draw_under()); dead,
##     it leaves a burning wreck (Convoy.wreck_vehicle()). Off a blocks stage it
##     drives straight lines at the necromancer and turns the same way.
## Phase 2 kinds extend this class: override physics() for a special and call
## super.physics() first (it keeps the facing; a vehicle's drive owns the tick);
## call super.reset() / super.on_deactivate() / super.on_killed() /
## super.draw_under() / super.draw_over() when they override those.
## Determinism: no RNG, no instance ids (the lane offset comes from the think
## slot).
class_name CityKit
extends CovenantKit

## A vehicle's drive state: driving its lane.
const DRIVE: int = 0
## A vehicle's drive state: stopped to turn round (at the lane's end).
const TURN: int = 1
## A vehicle's drive state: stopped after ramming a wreck.
const RAM: int = 2

## The facing (unit): toward its foe, else along its walk; a vehicle's drive
## direction (Armour's front test).
var facing: Vector2 = Vector2.RIGHT
## A vehicle's drive direction (unit).
var drive_dir: Vector2 = Vector2.RIGHT
## A vehicle's lane axis: 0 along x, 1 along y, -1 free (no city blocks).
var drive_axis: int = -1
## A vehicle's lane centre line (the fixed coordinate, px; without its offset).
var lane_c: float = 0.0
## A vehicle's drive state (DRIVE / TURN / RAM).
var drive_state: int = DRIVE
## Seconds in the current TURN / RAM stop.
var _drive_t: float = 0.0
## Its position at the last tick (a jump means it was recycled: re-snap).
var _last_pos: Vector2 = Vector2.ZERO
## Body -> game time (s) of its last run-over by this vehicle (Convoy).
var _hits: Dictionary = {}


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	facing = Vector2.RIGHT
	drive_state = DRIVE
	_drive_t = 0.0
	_hits.clear()
	var r := e.game.city_rules()  # The shared rules exist wherever a City kind walks.
	r.note_spawn(e)
	if is_vehicle():
		r.convoy.register(e)
		_snap_to_lane(e)


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	if is_vehicle():
		rules(e).convoy.wreck_vehicle(e, half_length())


## The shared rules (created on first use).
static func rules(e: Enemy) -> CityRules:
	return e.game.city_rules()


## The kind's escalation tier (row "tier").
func tier() -> String:
	return String(d.get("tier", ""))


## Armour's front share (row "armour_front", 0..1; 0 = no front).
func armour_front() -> float:
	return float(d.get("armour_front", 0.0))


## True for a vehicle (row "vehicle"): Convoy.
func is_vehicle() -> bool:
	return bool(d.get("vehicle", false))


## True for a civilian (row "civilian"): Civilians.
func is_civilian() -> bool:
	return bool(d.get("civilian", false))


## The Super's plate and weakness (row "super"; {} = not a Super).
func super_def() -> Dictionary:
	return d.get("super", {})


## A vehicle's half length along its lane (px; row half_length).
func half_length() -> float:
	return float(d.get("half_length", 20.0))


## A vehicle's half width across its lane (px; row half_width).
func half_width() -> float:
	return float(d.get("half_width", 12.0))


## Per-tick hook: a vehicle's drive owns the tick; any other kind keeps its
## facing and lets the shared AI move it (subclasses add their specials).
func physics(e: Enemy, delta: float) -> bool:
	if is_vehicle():
		return _drive(e, delta)
	_face(e)
	return false


## The facing: toward the foe it fights, else along its walk.
func _face(e: Enemy) -> void:
	if e._target_valid():
		var to := e.target.position - e.position
		if to.length_squared() > 1.0:
			facing = to.normalized()
			return
	if e.velocity.length_squared() > 25.0:
		facing = e.velocity.normalized()


func is_busy() -> bool:
	return phase != IDLE or drive_state != DRIVE


# =====================================================================================
# The drive (vehicles)
# =====================================================================================

## Snaps a vehicle onto the street lane nearest to it and points it at the
## necromancer (it spawns or recycles off screen, so the snap is never seen).
func _snap_to_lane(e: Enemy) -> void:
	var cb := e.game.arena.city_blocks
	var tp := e.game.nearest_player(e.position).position
	if cb == null:
		drive_axis = -1
		var to := tp - e.position
		drive_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	else:
		var dy := absf(e.position.y - cb.h_street_y(cb.h_street(e.position)))
		var dx := absf(e.position.x - cb.v_street_x(cb.v_street(e.position)))
		if dy <= dx:
			drive_axis = 0
			lane_c = cb.h_street_y(cb.h_street(e.position))
			e.position.y = lane_c + _lane_offset(e)
			drive_dir = Vector2(1.0 if tp.x >= e.position.x else -1.0, 0.0)
		else:
			drive_axis = 1
			lane_c = cb.v_street_x(cb.v_street(e.position))
			e.position.x = lane_c + _lane_offset(e)
			drive_dir = Vector2(0.0, 1.0 if tp.y >= e.position.y else -1.0)
	facing = drive_dir
	_last_pos = e.position


## px this vehicle keeps off its lane's centre line (by think slot), so two in
## one street do not stack.
func _lane_offset(e: Enemy) -> float:
	return float(e.think_slot % 3 - 1) * float(CityRulesData.CONVOY["lane_jitter"])


## One tick of a vehicle's drive (see the header). Always true (the drive owns
## the tick).
func _drive(e: Enemy, delta: float) -> bool:
	var g := e.game
	var conv := rules(e).convoy
	if e.position.distance_to(_last_pos) > 150.0:
		_snap_to_lane(e)  # Recycled to the spawn ring: onto a lane again.
	if drive_state != DRIVE:
		hold(e)
		_drive_t += delta
		var wait := float(CityRulesData.CONVOY["ram_stop"] if drive_state == RAM else CityRulesData.CONVOY["turn_time"])
		if _drive_t >= wait:
			if drive_state == RAM:
				_turn(e)  # After the crash, it backs off the other way.
			else:
				drive_state = DRIVE
		_last_pos = e.position
		return true
	var tp := g.nearest_player(e.position).position  # The necromancer it hunts.
	var cb := g.arena.city_blocks
	var spd := e.move_speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
	var step := spd * delta
	var overrun := float(CityRulesData.CONVOY["overrun"])
	if cb != null and drive_axis >= 0:
		var hy := cb.h_street_y(cb.h_street(tp))  # The necromancer's horizontal street.
		var vx := cb.v_street_x(cb.v_street(tp))  # His vertical street.
		var along := e.position.x if drive_axis == 0 else e.position.y  # Its coordinate along the lane.
		var dsign := drive_dir.x if drive_axis == 0 else drive_dir.y  # +1 / -1 along the lane.
		var same := absf(lane_c - (hy if drive_axis == 0 else vx)) < 1.0  # On his street already.
		if same:
			var proj := tp.x if drive_axis == 0 else tp.y
			if dsign * (along - proj) > overrun:
				_turn(e)
				return true
		else:
			var cross := vx if drive_axis == 0 else hy  # The crossing onto his street.
			if absf(cross - along) <= step + 1.0:
				# At the crossing: onto his street, toward him.
				if drive_axis == 0:
					e.position = Vector2(cross, e.position.y)
					drive_axis = 1
					lane_c = vx
					e.position.x = lane_c + _lane_offset(e)
					drive_dir = Vector2(0.0, 1.0 if tp.y >= e.position.y else -1.0)
				else:
					e.position = Vector2(e.position.x, cross)
					drive_axis = 0
					lane_c = hy
					e.position.y = lane_c + _lane_offset(e)
					drive_dir = Vector2(1.0 if tp.x >= e.position.x else -1.0, 0.0)
				g.stat_add("city_vehicle_corners", 1.0)
			elif signf(cross - along) != dsign:
				_turn(e)  # Heading away from the crossing: turn round.
				return true
	elif drive_axis < 0 and (e.position - tp).dot(drive_dir) > overrun:
		_turn(e)
		return true
	# A wreck (or any obstacle) dead ahead: the vehicle rams it.
	var ahead := e.position + drive_dir * (half_length() + step + 2.0)
	var o := g.arena.obstacle_at(ahead)
	if o != null and Arena.separation(o, ahead, half_width() * 0.8) != Vector2.ZERO:
		var wreck := o.kind == CityEnemyData.WRECK
		conv.on_ram(e, wreck)
		if wreck:
			# --- Act VIII: Skid Row --- a row may set its own share (the Armoured Limo's
			# plated grille); every other vehicle keeps CONVOY's.
			g.combat.damage_enemy(e, e.max_hp * float(d.get("ram_damage", CityRulesData.CONVOY["ram_damage"])), "wreck_ram")
		drive_state = RAM
		_drive_t = 0.0
		hold(e)
		rules(e).play_sound("vehicle_wreck", e.position, 0.3)
		return true
	e.position += drive_dir * step
	if drive_axis == 0:
		e.position.y = move_toward(e.position.y, lane_c + _lane_offset(e), 60.0 * delta)
	elif drive_axis == 1:
		e.position.x = move_toward(e.position.x, lane_c + _lane_offset(e), 60.0 * delta)
	e.velocity = drive_dir * spd
	facing = drive_dir
	e._update_facing()
	conv.run_over(e, drive_dir, half_length(), half_width(), float(d.get("run_damage", 8.0)) * hit_scale(e), _hits)
	_last_pos = e.position
	return true


## Stops a vehicle to turn round (the lane's end, a crossing behind it, after a
## ram): reverses its drive direction (off a blocks stage: points it at the
## necromancer again).
func _turn(e: Enemy) -> void:
	if drive_axis < 0:
		var to := e.game.nearest_player(e.position).position - e.position
		drive_dir = to.normalized() if to.length() > 1.0 else -drive_dir
	else:
		drive_dir = -drive_dir
	facing = drive_dir
	drive_state = TURN
	_drive_t = 0.0
	hold(e)
	rules(e).convoy.on_turn()
	rules(e).play_sound("engine_rev", e.position, 0.6)


# =====================================================================================
# Drawing (visual only)
# =====================================================================================

## A vehicle's headlights: its lane lit `headlight_time` s ahead (a texture
## strip in world axes).
func draw_under(e: Enemy) -> void:
	if not is_vehicle() or drive_state == RAM:
		return
	var reach := e.move_speed * float(CityRulesData.CONVOY["headlight_time"])
	CityGlyphs.draw_headlights(e, drive_dir * half_length(), drive_dir, reach, half_width(), 0.32, CourtGlyphs.unmirror_xf(e))
	e.draw_set_transform_matrix(Transform2D.IDENTITY)


## A squad car's light bar (row "siren"): a slow blue / red pulse.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if bool(d.get("siren", false)):
		CityGlyphs.draw_light_bar(ci, Vector2(0.0, -e.radius * 0.6), e.game.elapsed, CityRulesData.SIREN_PULSE_HZ)
