## KunoichiKit — the kit of the Kunoichi (ProvinceEnemyData "kunoichi"; Act V,
## the Burning Province, GDD §15.0 "The Burning Province (Act V phase 2)";
## owner-approved roster: "Smoke bombs that blind summons 2 s, a lunge at the
## necromancer | Kill on appear"). An ELITE AMBUSHER: the stages hand her squads
## to ShadowAmbush (she appears out of an obstacle's shadow after the puff).
## She walks at the necromancer with the shared melee AI (enemies always
## advance) and, on her own rhythm:
##   * SMOKE BOMB — when a summon stands within smoke_range px of her and the
##     bomb is ready, she throws it at the summons between her and the
##     necromancer (the point on her way to him smoke_range x 0.6 px out,
##     shown as a landing circle for smoke_flight s); it bursts into a smoke
##     cloud of smoke_radius px (ProvinceHazards) that BLINDS every summon in
##     it for smoke_blind s through THE one summon blind path
##     (CombatResolver.blind_unit()): they keep to the ring but find no foe.
##   * LUNGE — when the necromancer stands lunge_min..lunge_max px from her
##     and the lunge is ready, she crouches for lunge_telegraph s over a
##     telegraphed lane of lunge_width px, then leaps along it at lunge_speed
##     px/s up to lunge_length px (Arena.clear_length(): never through an
##     obstacle), over the ring: the necromancer in the lane takes
##     lunge_damage once; summons are not hit.
## Determinism: no RNG (first cooldowns staggered by the think slot). Stats:
## kunoichi_smokes, kunoichi_lunges, kunoichi_lunge_hits.
class_name KunoichiKit
extends ShogunateKit

## Phase: crouched over the lunge lane.
const LUNGE_WINDUP: int = 1
## Phase: leaping along the lane.
const LUNGING: int = 2
## px of reach the autotest bot keeps from her lane beyond its half width.
const DANGER_REACH: float = 24.0  # TUNING (not in GDD) autotest hint only

## Seconds until the next smoke bomb may be thrown.
var _smoke_cd: float = 0.0
## Seconds until the next lunge may start.
var _lunge_cd: float = 0.0
## World px where the bomb in flight lands (INF = none in flight).
var _bomb_at: Vector2 = Vector2.INF
## Seconds the bomb has flown.
var _bomb_t: float = 0.0
## Where the bomb left her hand (world px; drawing).
var _bomb_from: Vector2 = Vector2.ZERO
## Unit direction of the lunge (locked at its windup).
var _dir: Vector2 = Vector2.RIGHT
## Distance (px) of the lane still to leap.
var _left: float = 0.0
## Start of the lane (world px; the autopilot hint).
var _lane_from: Vector2 = Vector2.ZERO
## Necromancers already struck by this lunge (co-op: each once).
var _hit: Array[Necromancer] = []
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_smoke_cd = first_cd(e, float(def.get("smoke_every", 7.0)) * 0.3)
	_lunge_cd = first_cd(e, float(def.get("lunge_every", 6.0)) * 0.5)
	_bomb_at = Vector2.INF
	_hit.clear()


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	_bomb_at = Vector2.INF  # A bomb in flight falls with her.


## The bomb in flight, the lunge's windup and leap, and the triggers.
func physics(e: Enemy, delta: float) -> bool:
	_smoke_cd -= delta
	_lunge_cd -= delta
	_step_bomb(e, delta)
	match phase:
		LUNGE_WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(d["lunge_telegraph"]):
				_hit.clear()
				set_phase(e, LUNGING)
			return true
		LUNGING:
			_step_lunge(e, delta)
			return true
	var pl := e.game.player  # The necromancer she advances on (co-op: the nearest, bound).
	var dist := e.position.distance_to(pl.position)
	if _lunge_cd <= 0.0 and dist >= float(d["lunge_min"]) and dist <= float(d["lunge_max"]):
		_start_lunge(e, pl.position)
		return true
	if _smoke_cd <= 0.0 and _bomb_at == Vector2.INF and _summon_near(e):
		_throw_bomb(e, pl.position)
	return false


## True when a summon stands within smoke_range px of her.
func _summon_near(e: Enemy) -> bool:
	var r := float(d["smoke_range"])
	e.game.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.state != SummonedUnit.State.DEAD and u.position.distance_to(e.position) <= r + u.radius:
			return true
	return false


## Throws the smoke bomb toward the necromancer's ring (see the header).
func _throw_bomb(e: Enemy, at: Vector2) -> void:
	_smoke_cd = float(d["smoke_every"])
	var to := at - e.position
	var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	var reach := minf(to.length(), float(d["smoke_range"]) * 0.6)  # Into the summons between them.
	_bomb_at = e.position + dir * reach
	_bomb_t = 0.0
	_bomb_from = e.position
	e.game.effects.telegraph_circle(_bomb_at, float(d["smoke_radius"]), float(d["smoke_flight"]), e)
	e.motion_lunge(dir, MotionData.POWER_SHOT)
	e.game.stat_add("kunoichi_smokes", 1.0)


## Flies the bomb; it bursts into the smoke cloud when its flight ends.
func _step_bomb(e: Enemy, delta: float) -> void:
	if _bomb_at == Vector2.INF:
		return
	_bomb_t += delta
	e.queue_redraw()
	if _bomb_t < float(d["smoke_flight"]):
		return
	var at := _bomb_at
	_bomb_at = Vector2.INF
	e.game.enemies.province_hazards().add_smoke(at, float(d["smoke_radius"]), float(d["smoke_life"]), float(d["smoke_blind"]),
			0.0, 0.0, "kunoichi_smoke")
	rules(e).play_sound("smoke_puff", at)


## Crouches over the lane toward `at` (the telegraph).
func _start_lunge(e: Enemy, at: Vector2) -> void:
	_lunge_cd = float(d["lunge_every"])
	var to := at - e.position
	_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	_left = e.game.arena.clear_length(e.position, _dir, float(d["lunge_length"]), e.radius * 0.8)
	_lane_from = e.position
	e.game.effects.telegraph_line(e.position, e.position + _dir * _left, float(d["lunge_width"]), float(d["lunge_telegraph"]), e)
	e.motion_lunge(-_dir, MotionData.POWER_CAST)
	e.game.stat_add("kunoichi_lunges", 1.0)
	set_phase(e, LUNGE_WINDUP)
	hold(e)


## Leaps along the lane, over the ring: strikes each necromancer once.
func _step_lunge(e: Enemy, delta: float) -> void:
	var spd := float(d["lunge_speed"])
	var step_len := minf(spd * delta, _left)
	e.position += _dir * step_len
	_left -= step_len
	e.velocity = Vector2.ZERO
	var hw := float(d["lunge_width"]) * 0.5
	for pl in e.game.all_players:  # (Co-op: every necromancer in the lane, once.)
		if not _hit.has(pl) and pl.position.distance_to(e.position) <= hw + pl.radius:
			_hit.append(pl)
			e.game.combat.damage_player(float(d["lunge_damage"]) * hit_scale(e), ProvinceEnemyData.LUNGE_SOURCE, pl)
			e.game.stat_add("kunoichi_lunge_hits", 1.0)
	if _left <= 0.0:
		e.game.effects.slash(e.position, _dir, Palette.SHOGUN_LACQUER_LIGHT, e.radius * 1.6)
		set_phase(e, IDLE)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: sideways out of her lane, else out of the bomb's circle.
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	if phase == LUNGE_WINDUP or phase == LUNGING:
		var rel := p - _lane_from
		var along := rel.dot(_dir)
		if along > -20.0 and along < float(d["lunge_length"]) + 20.0:
			var side := rel - _dir * along
			if side.length() < float(d["lunge_width"]) * 0.5 + DANGER_REACH:
				return side.normalized() if side.length() > 0.5 else _dir.orthogonal()
	return Vector2.ZERO


## The bomb in flight (a small dark ball arcing to its circle). Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if _bomb_at == Vector2.INF:
		return
	unmirror(e, ci)
	var k := clampf(_bomb_t / maxf(0.01, float(d["smoke_flight"])), 0.0, 1.0)  # 0 -> 1 through the flight.
	var at := _bomb_from.lerp(_bomb_at, k) + Vector2(0.0, -4.0 * k * (1.0 - k) * 40.0)
	SpriteBank.draw_disc(ci, at - e.position, 3.5, Palette.SHOGUN_INDIGO_DARK)
	SpriteBank.draw_disc(ci, at - e.position + Vector2(-1.0, -1.0), 1.5, Palette.SHOGUN_LACQUER_LIGHT)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
