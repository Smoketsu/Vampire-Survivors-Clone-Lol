## KibaKit — the kit of the Kiba-musha (KuroganeEnemyData "kiba_musha"; Act V,
## Castle Kurogane, GDD §15.0 "Castle Kurogane (Act V phase 2)"; owner-approved
## proposal: "Kiba-musha: mounted samurai cavalry, a charging soldier"), and the
## base of the General of the Left's (GeneralKit). Its CHARGE: every
## charge_every s, when the necromancer it advances on (co-op: the bound one)
## is charge_min..charge_max px away, it reins in for charge_telegraph s with a
## lane charge_width px wide on the ground (EffectManager.telegraph_line(), the
## shared lane telegraph, which the autotest bot steps out of through
## danger_push()), then gallops along the lane at charge_speed (up to
## charge_length px, cut short by obstacles: Arena.clear_length()): the
## necromancer in it is struck once (charge_damage_player), every summon in it
## struck once (charge_damage_summon x the kind's undead_damage_mult) and
## thrown charge_push px aside: a horse is not stopped by a blocker. Then it
## stands charge_recover s and walks on with the shared melee AI.
## Subclasses override charge_source(), charges_in_row() and on_charge_end().
## No RNG (first cooldowns staggered by the think slot). Stats: <prefix>_charges,
## <prefix>_charge_hits_summon, <prefix>_charge_hits_player.
class_name KibaKit
extends ShogunateKit

## Phase: reined in, the lane telegraphed.
const WINDUP: int = 1
## Phase: galloping down the lane.
const GALLOP: int = 2
## Phase: standing after the gallop.
const RECOVER: int = 3
## px of reach the autotest bot keeps from a lane beyond its half width.
const DANGER_REACH: float = 24.0  # TUNING (not in GDD) autotest hint only

## Seconds until the next charge may start.
var charge_cd: float = 0.0
## Unit direction of the current charge (locked at its windup).
var _dir: Vector2 = Vector2.RIGHT
## World px the current lane starts at (the danger hint).
var _from: Vector2 = Vector2.ZERO
## Length (px) of the current lane.
var _len: float = 0.0
## px of the lane still to gallop.
var _left: float = 0.0
## Charges still to run in the current chain (the General's rage runs two).
var _chain: int = 0
## Summons already struck by the current gallop.
var _hit_units: Array[SummonedUnit] = []
## Necromancers already struck by the current gallop.
var _hit_players: Array[Necromancer] = []
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	charge_cd = first_cd(e, float(def.get("charge_every", 6.0)) * 0.5)
	_chain = 0


## Prefix of this kit's stats ("kiba"; the General overrides it).
func stat_prefix() -> String:
	return "kiba"


## Damage source tag of the charge.
func charge_source() -> String:
	return KuroganeEnemyData.KIBA_CHARGE_SOURCE


## Charges in a row this time (1; the General's rage more).
func charges_in_row(_e: Enemy) -> int:
	return 1


## Called when a chain of charges ends (the General calls his riders here).
func on_charge_end(_e: Enemy) -> void:
	pass


## The charge machine (see the header).
func physics(e: Enemy, delta: float) -> bool:
	charge_cd -= delta
	if phase == IDLE:
		if charge_cd > 0.0:
			return false
		var aim := e.game.player.position  # The necromancer it rides at.
		var dist := e.position.distance_to(aim)
		if dist < float(d["charge_min"]) or dist > float(d["charge_max"]):
			return false
		charge_cd = float(d["charge_every"])
		_chain = charges_in_row(e)
		_start(e)
		return true
	phase_time += delta
	match phase:
		WINDUP:
			hold(e)
			if phase_time >= float(d["charge_telegraph"]):
				_hit_units.clear()
				_hit_players.clear()
				e.game.stat_add(stat_prefix() + "_charges", 1.0)
				rules(e).play_sound("cavalry_charge", e.position)
				set_phase(e, GALLOP)
		GALLOP:
			_gallop(e, delta)
		RECOVER:
			hold(e)
			if phase_time >= float(d["charge_recover"]):
				if _chain > 0 and e.position.distance_to(e.game.player.position) >= float(d["charge_min"]) * 0.5:
					_start(e)
				else:
					_chain = 0
					on_charge_end(e)
					set_phase(e, IDLE)
	return true


## Reins in and telegraphs the lane toward the necromancer.
func _start(e: Enemy) -> void:
	_chain -= 1
	var to := e.game.player.position - e.position
	_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	_from = e.position
	_len = e.game.arena.clear_length(e.position, _dir, float(d["charge_length"]), e.radius * 0.8)
	_left = _len
	e.game.effects.telegraph_line(e.position, e.position + _dir * _len, float(d["charge_width"]), float(d["charge_telegraph"]), e)
	e.motion_lunge(-_dir, MotionData.POWER_CAST)
	set_phase(e, WINDUP)


## Gallops down the lane, striking what it meets (see the header).
func _gallop(e: Enemy, delta: float) -> void:
	var g := e.game
	var step_len := minf(float(d["charge_speed"]) * delta, _left)
	e.position += _dir * step_len
	e.velocity = _dir * float(d["charge_speed"])
	_left -= step_len
	var hw := float(d["charge_width"]) * 0.5  # Lane half-width (px).
	var mult := hit_scale(e)  # Time scaling x buffs.
	var src := charge_source()
	for p in g.all_players:  # (Co-op: every necromancer in the lane, once.)
		if not _hit_players.has(p) and p.position.distance_to(e.position) <= hw + p.radius:
			_hit_players.append(p)
			g.combat.damage_player(float(d["charge_damage_player"]) * mult, src, p)
			g.stat_add(stat_prefix() + "_charge_hits_player", 1.0)
	g.ally_grid.query(e.position, hw + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.airborne or _hit_units.has(u):
			continue
		var rel := u.position - e.position
		if rel.length() > hw + u.radius:
			continue
		_hit_units.append(u)
		var side := rel - _dir * rel.dot(_dir)
		var push := side.normalized() if side.length() > 0.1 else _dir.orthogonal()
		u.position += push * float(d["charge_push"])
		g.combat.damage_unit(u, float(d["charge_damage_summon"]) * mult * e.undead_damage_mult, src, e)
		g.stat_add(stat_prefix() + "_charge_hits_summon", 1.0)
	if _left <= 0.0:
		e.motion_lunge(_dir, MotionData.POWER_MELEE)
		set_phase(e, RECOVER)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: sideways out of the telegraphed or running lane.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP and phase != GALLOP:
		return Vector2.ZERO
	var rel := p - _from
	var along := rel.dot(_dir)
	if along < -20.0 or along > _len + 30.0:
		return Vector2.ZERO
	var side := rel - _dir * along
	var reach := float(d["charge_width"]) * 0.5 + DANGER_REACH + e.game.player.radius
	if side.length() >= reach:
		return Vector2.ZERO
	return (side.normalized() if side.length() > 0.5 else _dir.orthogonal()) * (1.0 - side.length() / reach) * 2.5
