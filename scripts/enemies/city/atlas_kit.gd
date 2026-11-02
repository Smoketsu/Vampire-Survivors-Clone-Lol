## AtlasKit — the kit of ATLAS (CityEnemyData "atlas"; Act VIII, Liberty
## Heights; GDD §15.0 "Atlas, Aurora and Nightjar (Act VIII)"; owner-approved
## proposal: "Atlas (a strongman who throws wrecks; a long wind-up)"), a
## SuperKit (guarded x0.6 until his weakness is read). Male: a huge bald,
## bearded strongman in a green-and-gold sleeveless suit with gold arm bands,
## no cape, no emblem (the approved concept act8_lineup.png). His
## power and weakness, "Strong. Slow to throw.":
##   * THE THROW: every throw_every s, with the necromancer within throw_range
##     px, he LIFTS the nearest standing wreck within lift_range px
##     (CityBlocks.remove_wreck(): the wreck leaves the street; the city
##     changes shape again) or, with none, a parked car from the kerb (nothing
##     leaves the map), then WINDS UP for throw_windup s with it over his head
##     (his mark shows on the ground where it will land: the necromancer's
##     spot as the wind-up began). Then he throws it: a CityShells landing
##     circle (THE landing-circle path) of throw_radius px lands throw_flight s
##     later (throw_damage x the time scaling to summons and necromancers, the
##     city's side spared), and on a city-block layout the car lands as a new
##     burning wreck there (CityBlocks.add_wreck(); refused off a street);
##   * SLOW TO THROW: a STUN or a hold (a Deep Freeze, Stasis) during the lift
##     or the wind-up EXPOSES him (SuperKit.expose(), "stun": stunned 1 s,
##     then x1.5 damage taken) and he drops the car at his feet (a wreck there
##     when it fits; no damage). The kit's physics does not run while he is
##     held (EnemyDirector), so a hold is seen as a gap between two of his
##     ticks (_held()); his own expose stun is not one.
## Between throws he fights in melee with the shared AI.
## Determinism: no RNG (the nearest wreck, ties the older one). Stats:
## atlas_throws, atlas_lifts_wreck, atlas_lifts_car, atlas_dropped,
## atlas_wrecks_landed.
class_name AtlasKit
extends SuperKit

## Phase: lifting the car (it rises over his head).
const LIFT: int = 1
## Phase: the wind-up, the car over his head, the mark on the ground.
const WINDUP: int = 2
## Seconds of the lift.
const LIFT_TIME: float = 0.4  # TUNING (not in GDD) part of the long wind-up

## Seconds until his next throw may start.
var _cd: float = 0.0
## Where the car will land (world px; fixed as the wind-up begins).
var _target: Vector2 = Vector2.ZERO
## True while a thrown car flies (its wreck lands at _land_at).
var _flying: bool = false
## Where the thrown car lands (world px).
var _land_at: Vector2 = Vector2.ZERO
## Where the thrown car left his hands (world px; drawn arc).
var _thrown_from: Vector2 = Vector2.ZERO
## Game time (s) the thrown car was released.
var _thrown_at: float = 0.0
## Game time (s) of his last kit tick (a hold shows as a gap).
var _last_tick: float = -1.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(d["throw_first"]))
	_flying = false
	_last_tick = -1.0


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var g := e.game
	var held := _held(e, delta)
	_last_tick = g.elapsed
	if _flying and g.elapsed >= _thrown_at + float(d["throw_flight"]):
		_flying = false
		_leave_wreck(e, _land_at)
	if _flying:
		e.queue_redraw()  # The car on its arc.
	match phase:
		LIFT, WINDUP:
			hold(e)
			if held and not is_exposed(e):
				_drop(e)
				return true
			phase_time += delta
			if phase == LIFT and phase_time >= LIFT_TIME:
				set_phase(e, WINDUP)
			elif phase == WINDUP and phase_time >= float(d["throw_windup"]):
				_throw(e)
			e.queue_redraw()
			return true
	_cd -= delta
	if _cd > 0.0 or g.ultimates.player_untargetable():
		return false
	var pl := g.nearest_player(e.position)
	if pl.position.distance_to(e.position) > float(d["throw_range"]):
		return false
	_cd = float(d["throw_every"])
	_lift(e, pl.position)
	return true


## True when he was held (stunned, frozen) since his last tick: his kit's
## physics skipped at least a few ticks. His own expose stun does not count.
func _held(e: Enemy, delta: float) -> bool:
	return _last_tick >= 0.0 and e.game.elapsed - _last_tick > delta * 3.5


## He lifts the nearest wreck (it leaves the street) or a parked car, and his
## wind-up begins: the mark is the necromancer's spot `at`.
func _lift(e: Enemy, at: Vector2) -> void:
	var g := e.game
	var cb := g.arena.city_blocks
	var w: CityBlocks.Wreck = cb.nearest_wreck(e.position, float(d["lift_range"])) if cb != null else null
	if w != null and cb.remove_wreck(w):
		g.stat_add("atlas_lifts_wreck", 1.0)
		g.effects.ring(w.obstacle.center, 30.0, Palette.CITY_HAZARD, 0.35)
	else:
		g.stat_add("atlas_lifts_car", 1.0)
	_target = g.arena.free_point(at, 8.0)
	facing = (_target - e.position).normalized() if _target.distance_to(e.position) > 1.0 else facing
	set_phase(e, LIFT)
	hold(e)
	rules(e).play_sound("engine_rev", e.position, 0.5)


## The throw: a landing circle on the mark; the car flies there.
func _throw(e: Enemy) -> void:
	var g := e.game
	var dmg := float(d["throw_damage"]) * hit_scale(e) * e.undead_damage_mult
	rules(e).shells.add(_target, float(d["throw_flight"]), float(d["throw_radius"]), dmg, CityEnemyData.THROW_SOURCE, false)
	_flying = true
	_land_at = _target
	_thrown_from = e.position
	_thrown_at = g.elapsed
	g.stat_add("atlas_throws", 1.0)
	e.motion_lunge(facing, MotionData.POWER_CAST)
	rules(e).play_sound("super_arrive", e.position, 0.4)
	set_phase(e, IDLE)


## Held during the wind-up: exposed, and the car drops at his feet.
func _drop(e: Enemy) -> void:
	e.game.stat_add("atlas_dropped", 1.0)
	set_phase(e, IDLE)
	_leave_wreck(e, e.position + facing * (e.radius + 30.0))
	expose(e, "stun")


## A car comes down at `at`: on a city-block layout a new burning wreck there
## (refused off a street or in a taken cell).
func _leave_wreck(e: Enemy, at: Vector2) -> void:
	var cb := e.game.arena.city_blocks
	if cb != null and cb.add_wreck(at, float(d["throw_half"]), e.game.elapsed) != null:
		e.game.stat_add("atlas_wrecks_landed", 1.0)


func is_busy() -> bool:
	return phase != IDLE or super.is_busy()


## The autotest autopilot steps out of his mark during the wind-up (the
## landing circle itself is CityShells').
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != LIFT and phase != WINDUP:
		return Vector2.ZERO
	var off := p - _target
	var reach := float(d["throw_radius"]) + 24.0
	if off.length() >= reach:
		return Vector2.ZERO
	return (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 2.0


## Under him: his mark on the ground during the wind-up. Visual only.
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	if phase != LIFT and phase != WINDUP:
		return
	unmirror(e)
	var k := clampf(phase_time / maxf(float(d["throw_windup"]), 0.01), 0.0, 1.0) if phase == WINDUP else 0.0
	CityGlyphs.draw_shell(e, _target - e.position, float(d["throw_radius"]), k * 0.6, Palette.CITY_HAZARD)
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Over him: the car over his head while he lifts and winds up, and the car
## in flight on its arc. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	super.draw_over(e, ci)
	unmirror(e, ci)
	if phase == LIFT or phase == WINDUP:
		var up := clampf(phase_time / LIFT_TIME, 0.0, 1.0) if phase == LIFT else 1.0
		LibertyHeightsGlyphs.draw_car(ci, Vector2(0.0, -e.radius * (0.6 + 1.6 * up)), 1.0)
	if _flying:
		var t := clampf((e.game.elapsed - _thrown_at) / maxf(float(d["throw_flight"]), 0.01), 0.0, 1.0)
		var at := _thrown_from.lerp(_land_at, t) - e.position + Vector2(0.0, -90.0 * 4.0 * t * (1.0 - t))
		LibertyHeightsGlyphs.draw_car(ci, at, 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
