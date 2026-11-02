## BigSalKit — BIG SAL, Skid Row's miniboss on foot (SkidRowEnemyData
## "big_sal"; Act VIII, GDD §15.0 "Big Sal and the Armoured Limo (Act VIII)";
## the brief: "When it dies it leaves a wreck. Big Sal climbs out for a short
## melee finish; kill him to end the miniboss"). Spawned by SkidRowDirector at
## the wreck of his Armoured Limo (or by --spawn=big_sal anywhere), through the
## normal spawn path; he registers as EnemyDirector.miniboss (the HUD's miniboss
## bar; ChestManager drops the miniboss chest on his fall: the row's
## "miniboss"). A huge male enforcer in a pinstripe suit with a sledgehammer:
##   * THE SWING — every swing_every s, with his target within swing_reach px
##       of his edge, he winds up swing_windup s (a telegraphed arc of
##       swing_half_angle rad each side, toward his target) and swings: every
##       summon and necromancer in the arc takes swing_damage (a summon is
##       knocked swing_push px back to a free point; an enemy attack, not a
##       summon rule). Grave Step's i-frames dodge it.
##   * The forced march — beyond advance_range px he strides
##       advance_speed_mult faster (he never kites and is never left behind).
## Between swings he fights in melee with the shared AI (a CityKit: his facing).
## On death: an XP burst (reward_xp in reward_crystals), the miniboss chest.
## No RNG. Stats: big_sal_spawned, big_sal_swings, big_sal_swing_hits,
## big_sal_kills, big_sal_ttk.
class_name BigSalKit
extends CityKit

## Phase: winding up the swing (the arc shows).
const WINDUP: int = 1
## Phase: the swing's follow-through.
const SWING: int = 2
## Seconds of the follow-through pose after the swing lands.
const SWING_TIME: float = 0.25  # TUNING (not in GDD)
## px the autotest bot keeps beyond the swing's reach (autotest hint only).
const DANGER_REACH: float = 18.0  # TUNING (not in GDD) autotest hint only

## Seconds until his next swing.
var _swing_cd: float = 0.0
## Direction of the current swing (unit; locked at the windup).
var _swing_dir: Vector2 = Vector2.RIGHT
## Walking speed before the forced march (px/s; -1 = not read yet).
var _base_speed: float = -1.0
## Game time he arrived (time-to-kill stat).
var _spawned_at: float = 0.0
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_swing_cd = float(def.get("swing_every", 4.5)) * 0.5
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("big_sal_spawned", 1.0)


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)  # The facing.
	_swing_cd -= delta
	e.knockback = Vector2.ZERO  # Like a boss: blows do not shove the enforcer.
	if _base_speed < 0.0:
		_base_speed = e.move_speed
	match phase:
		WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("swing_windup", 0.6)):
				_swing(e)
				set_phase(e, SWING)
			return true
		SWING:
			phase_time += delta
			hold(e)
			if phase_time >= SWING_TIME:
				set_phase(e, IDLE)
			return true
	var g := e.game
	var dist := e.position.distance_to(g.player.position)
	e.move_speed = _base_speed * (float(d.get("advance_speed_mult", 1.6)) if dist > float(d.get("advance_range", 380.0)) else 1.0)
	if _swing_cd > 0.0 or not e._target_valid():
		return false
	var t := e.target
	var to := t.position - e.position
	var edge := to.length() - e.radius - body_radius(e, t)
	if edge > float(d.get("swing_reach", 58.0)) or to.length() < 0.01:
		return false
	_swing_cd = float(d.get("swing_every", 4.5))
	_swing_dir = to.normalized()
	facing = _swing_dir
	g.effects.telegraph_cone(e.position, _swing_dir, e.radius + float(d.get("swing_reach", 58.0)),
			float(d.get("swing_half_angle", 1.0)), float(d.get("swing_windup", 0.6)), e)
	e.motion_lunge(-_swing_dir, MotionData.POWER_CAST)
	g.stat_add("big_sal_swings", 1.0)
	set_phase(e, WINDUP)
	hold(e)
	return true


## The swing lands: every summon and necromancer in the arc is hit.
func _swing(e: Enemy) -> void:
	var g := e.game
	var reach := e.radius + float(d.get("swing_reach", 58.0))
	var half := float(d.get("swing_half_angle", 1.0))
	var dmg := float(d.get("swing_damage", 12.0)) * hit_scale(e)
	var push := float(d.get("swing_push", 40.0))
	var hits := 0
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
			continue
		if not in_sector(e.position, _swing_dir, reach, half, e.radius, u.position, u.radius):
			continue
		g.combat.damage_unit(u, dmg * e.undead_damage_mult, SkidRowEnemyData.SAL_SWING_SOURCE, e)
		hits += 1
		if u.active:
			var away := (u.position - e.position).normalized() if u.position.distance_to(e.position) > 0.5 else _swing_dir
			u.position = g.arena.free_point(u.position + away * push, u.radius)
	for pl in g.all_players:
		if not pl.dead and in_sector(e.position, _swing_dir, reach, half, e.radius, pl.position, pl.radius):
			g.combat.damage_player(dmg, SkidRowEnemyData.SAL_SWING_SOURCE, pl, e)
			hits += 1
	g.stat_add("big_sal_swing_hits", float(hits))
	g.effects.slash(e.position + _swing_dir * e.radius, _swing_dir, Palette.CITY_HAZARD, reach)
	g.shake(3.0)


## The XP burst, banner and stats of his fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 10)))
	var each := maxi(1, floori(float(d.get("reward_xp", 200)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.CITY_HAZARD)
	g.shake(8.0)
	g.stat_add("big_sal_kills", 1.0)
	g.stat_add("big_sal_ttk", g.elapsed - _spawned_at)
	var sr := g.enemies.skid_row  # Skid Row's director (null elsewhere).
	if sr != null:
		sr.on_sal_killed()


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


func is_busy() -> bool:
	return phase != IDLE or super.is_busy()


## Autopilot hint: out of the swing's arc while he winds up.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	var reach := e.radius + float(d.get("swing_reach", 58.0)) + DANGER_REACH
	var off := p - e.position
	var dist := off.length()
	if dist >= reach or absf(_swing_dir.angle_to(off)) > float(d.get("swing_half_angle", 1.0)) + 0.3:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else _swing_dir) * (1.0 - dist / reach) * 2.0
