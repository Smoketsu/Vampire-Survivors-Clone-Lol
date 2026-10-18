## ArmKit — one of Vhal'Neth's arms (SpireEnemyData "vhalneth_arm", kit
## "arm"; GDD §15.0 "Ul-Thalos, the Risen Spire"): a colossal tentacled arm
## rising out of the sea at the shore. It is a stationary structure (the
## shared Enemy AI picks no target for it); BossVhalneth raises it, sets its
## HP and its pace (slam_pace(), per fight phase) and is wounded when it is
## severed (BossVhalneth.on_arm_severed()).
##   * Slam: every slam_interval / pace s it marks a lane from its root toward
##     the necromancer (or, when he is far, the thickest knot of summons),
##     slam_width px wide and as long as the island lets it (the far shore cuts
##     it, at most slam_length px), for slam_telegraph s: a biolume-edged
##     drowned lane (never gold). Then the arm crashes down along it: the
##     necromancer in it takes slam_damage_player, every summon in it
##     slam_damage_summon (both time-scaled) and is thrown out of the lane by
##     slam_knockback px. Undead do not dodge; only the necromancer steps out.
##     The arm lies along the lane for slam_recover s (drawing), then rises.
##   * While Vhal'Neth changes phase it holds still (hold_until()).
## Determinism (CLAUDE.md): no RNG; slams are staggered by the think slot.
## Stats: boss_atk_slam (the boss's attack line), vhalneth_slam_player_hits,
## vhalneth_slam_summon_hits; damage as player_dmg_from_vhalneth_slam /
## summon_dmg_from_vhalneth_slam (CombatResolver).
class_name ArmKit
extends CovenantKit

## Phase: the lane is telegraphed.
const WINDUP: int = 1
## Phase: the arm lies along the lane after the impact.
const RECOVER: int = 2
## Damage source tag of the slam (CombatResolver stats; an area hit for
## Unholy Resilience, PassiveData.AREA_HOLY_SOURCES).
const SOURCE: String = "vhalneth_slam"

## Seconds until the next slam may start.
var cd: float = 0.0
## Unit direction of the current lane.
var dir: Vector2 = Vector2.RIGHT
## Length (px) of the current lane.
var length: float = 0.0
## Game time until which the arm holds still (Vhal'Neth changing phase).
var _hold_until: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d["slam_first"]))
	_hold_until = 0.0


## The arm holds still until game time `t` (a phase change).
func hold_until(e: Enemy, t: float) -> void:
	_hold_until = maxf(_hold_until, t)
	if phase == WINDUP:
		set_phase(e, IDLE)  # A lane cut short.


## The fight phase's slam rate (1 without Vhal'Neth: an arm forced by --spawn).
func _pace(e: Enemy) -> float:
	var b := e.game.enemies.boss
	if b != null and b.active and b is BossVhalneth:
		return (b as BossVhalneth).slam_pace()
	return 1.0


func physics(e: Enemy, delta: float) -> bool:
	hold(e)
	if e.game.elapsed < _hold_until:
		return true
	match phase:
		WINDUP:
			phase_time += delta
			if int(phase_time * 6.0) != int((phase_time - delta) * 6.0):
				e.queue_redraw()  # The lane pulses.
			if phase_time >= float(d["slam_telegraph"]):
				_slam(e)
				set_phase(e, RECOVER)
			return true
		RECOVER:
			phase_time += delta
			if phase_time >= float(d["slam_recover"]):
				set_phase(e, IDLE)
			return true
	cd -= delta
	if cd > 0.0:
		return true
	cd = float(d["slam_interval"]) / maxf(0.1, _pace(e))
	_aim(e)
	set_phase(e, WINDUP)
	e.motion_lunge(dir, MotionData.POWER_CAST)  # Engine motion: the arm rears up (visual only).
	e.game.stat_add("boss_atk_slam", 1.0)
	Sfx.play("boss_telegraph", e.position, 0.7)
	return true


## Aims the lane: at the necromancer, or at the summons when he is beyond its
## reach; its length is cut at the far shore.
func _aim(e: Enemy) -> void:
	var g := e.game
	var goal := g.player.position
	var reach := float(d["slam_length"])
	if goal.distance_to(e.position) > reach:
		goal = _army_centre(g)
	var to := goal - e.position
	dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	length = reach
	var sink := g.enemies.sinking
	if sink != null:
		# The far shore: where the lane leaves the island (ray / circle).
		var rel := e.position - sink.center
		var b := rel.dot(dir)
		var c := rel.length_squared() - sink.radius * sink.radius
		var disc := b * b - c
		if disc > 0.0:
			length = clampf(-b + sqrt(disc), 120.0, reach)


## Mean position of the living summons (the necromancer's when there are none).
static func _army_centre(g: Game) -> Vector2:
	var sum := Vector2.ZERO
	var n := 0
	for u in g.horde.units:
		if u.active and not u.airborne:
			sum += u.position
			n += 1
	return sum / float(n) if n > 0 else g.player.position


## The arm crashes down along the lane.
func _slam(e: Enemy) -> void:
	var g := e.game
	var half := float(d["slam_width"]) * 0.5
	var scale := hit_scale(e)
	var pl := g.player
	if _in_lane(e.position, pl.position, half + pl.radius):
		g.combat.damage_player(float(d["slam_damage_player"]) * scale, SOURCE)
		g.stat_add("vhalneth_slam_player_hits", 1.0)
	var hits := 0  # Summons struck.
	var perp := Vector2(-dir.y, dir.x)
	for u in g.horde.units:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		if not _in_lane(e.position, u.position, half + u.radius):
			continue
		var side := (u.position - e.position).dot(perp)
		u.position += perp * (signf(side) if side != 0.0 else 1.0) * float(d["slam_knockback"])
		g.combat.damage_unit(u, float(d["slam_damage_summon"]) * scale, SOURCE)
		hits += 1
	g.stat_add("vhalneth_slam_summon_hits", float(hits))
	var steps := maxi(1, int(length / 90.0))
	for i in steps:
		g.effects.pop(e.position + dir * length * (float(i) + 0.5) / float(steps), Palette.EYE_DROWNED, 22.0)
	g.effects.impact(e.position + dir * length * 0.5, 40.0, Palette.EYE_DROWNED_DARK, "vhalneth_slam")
	g.shake(5.0)
	Sfx.play("abom_stomp", e.position + dir * length * 0.5, 0.6)


## True when a point at `p` lies in the lane from `origin` (within `reach` px of its axis).
func _in_lane(origin: Vector2, p: Vector2, reach: float) -> bool:
	var rel := p - origin
	var along := rel.dot(dir)
	if along < -reach or along > length + reach:
		return false
	return absf(rel.dot(Vector2(-dir.y, dir.x))) <= reach


## Autopilot hint: out of a telegraphed lane, sideways.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	var half := float(d["slam_width"]) * 0.5 + 24.0
	if not _in_lane(e.position, p, half):
		return Vector2.ZERO
	var perp := Vector2(-dir.y, dir.x)
	return perp if (p - e.position).dot(perp) >= 0.0 else -perp


## True while a slam runs (the stuck check never applies to a structure).
func is_busy() -> bool:
	return phase != IDLE


## The lane telegraph (under every body), and the arm lying along it after the slam.
func draw_under(e: Enemy) -> void:
	if phase == IDLE:
		return
	unmirror(e)
	var k := clampf(phase_time / maxf(0.05, float(d["slam_telegraph"])), 0.0, 1.0)
	SpireGlyphs.draw_slam_lane(e, Vector2.ZERO, dir, length, float(d["slam_width"]), k, phase == RECOVER)
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
