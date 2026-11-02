## OldGreymaneKit — OLD GREYMANE, Ravensmoor's miniboss (RavensmoorEnemyData
## "old_greymane"; Act VII, GDD §15.0 "Ravensmoor (Act VII phase 2)";
## owner-approved proposal: "Miniboss, Old Greymane, the pack's alpha, who
## howls the rest of the wolves into beast form early"). Spawned once by
## RavensmoorDirector (the "greymane" timeline event) with his pack of
## werewolf hunters, through the normal spawn path; he registers as
## EnemyDirector.miniboss (the HUD's miniboss bar; ChestManager drops the
## miniboss chest). A huge grey wolf-man, always in beast form (a werebeast:
## Silver Bones' damage hook reads the row flag), whose bites feed him
## (Bloodfeast, the row's "feeds"):
##   * THE HOWL — every howl_every s (the first howl_first s after he
##       arrives) he stops and howls for howl_time s: every werewolf within
##       howl_radius px turns into the beast at once, moon or not
##       (WerewolfKit.howl_turn(), the werewolves' one turning path), and
##       every werewolf there is spurred for howl_buff_time s (+howl_buff_damage
##       damage, +howl_buff_speed speed through Enemy.apply_buff(), the one
##       enemy buff path, as the Banner Bearer's).
##   * THE LUNGE — like the beasts', but only at a SUMMON (he leaps into the
##       ring at your dead, never at the necromancer): when his target is
##       between lunge_min and lunge_trigger px (edge to edge) and the lunge is
##       ready, he crouches
##       lunge_windup s (a red line to his mark), leaps there in lunge_time s
##       and bites for lunge_damage (a feeding blow).
##   * The forced march — beyond advance_range px he strides
##       advance_speed_mult faster (he never kites and is never left behind).
## On death: an XP burst (reward_xp in reward_crystals), the miniboss chest.
## No RNG. Stats: greymane_spawned, greymane_howls, greymane_howl_turned,
## greymane_howl_spurred, greymane_lunges, greymane_lunge_hits,
## greymane_kills, greymane_ttk.
class_name OldGreymaneKit
extends CourtKit

## Phase: the howl.
const HOWL: int = 1
## Phase: the crouch before the lunge.
const CROUCH: int = 2
## Phase: the lunge's leap.
const LEAP: int = 3
## px of reach the autotest bot keeps from the lunge's mark beyond his body.
const DANGER_REACH: float = 20.0  # TUNING (not in GDD) autotest hint only

## Seconds until the next howl.
var _howl_cd: float = 0.0
## Seconds until the next lunge.
var _lunge_cd: float = 0.0
## Where the leap starts (world px).
var _from: Vector2 = Vector2.ZERO
## Where the leap lands (world px; locked when he crouches).
var _to: Vector2 = Vector2.ZERO
## Walking speed before the forced march (px/s; -1 = not read yet).
var _base_speed: float = -1.0
## Game time he arrived (time-to-kill stat).
var _spawned_at: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_howl_cd = float(def.get("howl_first", 2.0))
	_lunge_cd = float(def.get("lunge_every", 7.0)) * 0.5
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("greymane_spawned", 1.0)


func physics(e: Enemy, delta: float) -> bool:
	_howl_cd -= delta
	_lunge_cd -= delta
	e.knockback = Vector2.ZERO  # Like a boss: blows do not shove the alpha.
	if _base_speed < 0.0:
		_base_speed = e.move_speed
	match phase:
		HOWL:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("howl_time", 0.9)):
				set_phase(e, IDLE)
			return true
		CROUCH:
			phase_time += delta
			hold(e)
			e.queue_redraw()  # The line brightens.
			if phase_time >= float(d.get("lunge_windup", 0.5)):
				_from = e.position
				set_phase(e, LEAP)
			return true
		LEAP:
			phase_time += delta
			var k := clampf(phase_time / maxf(0.01, float(d.get("lunge_time", 0.3))), 0.0, 1.0)  # 0 -> 1 to the mark.
			e.position = _from.lerp(_to, k)
			e.velocity = Vector2.ZERO
			if k >= 1.0:
				_land(e)
				set_phase(e, IDLE)
			return true
	var g := e.game
	var dist := e.position.distance_to(g.player.position)
	e.move_speed = _base_speed * (float(d.get("advance_speed_mult", 1.6)) if dist > float(d.get("advance_range", 420.0)) else 1.0)
	if _howl_cd <= 0.0:
		_howl(e)
		return true
	if _lunge_cd > 0.0 or not e._target_valid():
		return false
	var t := e.target
	var to := t.position - e.position
	var dt := to.length()
	var edge := dt - e.radius - body_radius(e, t)
	if edge < float(d.get("lunge_min", 30.0)) or edge > float(d.get("lunge_trigger", 130.0)) or dt < 0.01:
		return false
	if not (t is SummonedUnit):
		return false  # Own decision (tuning): he leaps into the ring at the dead, never at the necromancer.
	_lunge_cd = float(d.get("lunge_every", 7.0))
	_to = g.arena.free_point(t.position - to / dt * (e.radius + body_radius(e, t)), e.radius * 0.5)
	g.stat_add("greymane_lunges", 1.0)
	set_phase(e, CROUCH)
	hold(e)
	return true


## The howl: the werewolves near him turn into beasts and are spurred on.
func _howl(e: Enemy) -> void:
	var g := e.game
	_howl_cd = float(d.get("howl_every", 14.0))
	g.stat_add("greymane_howls", 1.0)
	rules(e).play_sound("wolf_howl", e.position)
	e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	var reach := float(d.get("howl_radius", 380.0))
	var tmp: Array = []
	g.enemy_grid.query(e.position, reach, tmp)
	var turned := 0
	var spurred := 0
	for o: Enemy in tmp:
		if not o.active or not (o.kit is WerewolfKit) or o.position.distance_to(e.position) > reach:
			continue
		if (o.kit as WerewolfKit).howl_turn(o):
			turned += 1
		o.apply_buff(1.0 + float(d.get("howl_buff_damage", 0.2)), 1.0 + float(d.get("howl_buff_speed", 0.15)), 1.0, float(d.get("howl_buff_time", 6.0)))
		spurred += 1
	g.stat_add("greymane_howl_turned", float(turned))
	g.stat_add("greymane_howl_spurred", float(spurred))
	g.effects.ring(e.position, reach * 0.5, Palette.COURT_MOON, 0.5)
	set_phase(e, HOWL)
	hold(e)


## The leap lands: the bite on his target if it is still within reach.
func _land(e: Enemy) -> void:
	var g := e.game
	if not e._target_valid():
		return
	var t := e.target
	if e.position.distance_to(t.position) - e.radius - body_radius(e, t) > e.attack_range + 12.0:
		return
	var dmg := float(d.get("lunge_damage", 18.0)) * hit_scale(e)
	g.stat_add("greymane_lunge_hits", 1.0)
	g.effects.slash(e.position, t.position - e.position, Palette.COURT_BLOOD_LIGHT, e.radius * 1.4)
	if t is SummonedUnit:
		g.combat.damage_unit(t as SummonedUnit, dmg * e.undead_damage_mult, RavensmoorEnemyData.GREYMANE_LUNGE_SOURCE, e)
	else:
		g.combat.damage_player(dmg, RavensmoorEnemyData.GREYMANE_LUNGE_SOURCE, t as Necromancer, e)


## The XP burst, banner and stats of his fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 10)))
	var each := maxi(1, floori(float(d.get("reward_xp", 200)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.COURT_MOON_LIGHT)
	g.shake(8.0)
	g.enemies.show_banner("Old Greymane falls: the pack has lost its alpha!")
	g.stat_add("greymane_kills", 1.0)
	g.stat_add("greymane_ttk", g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: off the lunge's mark while he crouches and leaps.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != CROUCH and phase != LEAP:
		return Vector2.ZERO
	var reach := e.radius + DANGER_REACH
	var off := p - _to
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.0


## While he crouches, a red line on the ground to where he will land.
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	if phase != CROUCH:
		return
	var k := clampf(phase_time / maxf(float(d.get("lunge_windup", 0.5)), 0.01), 0.0, 1.0)
	CourtGlyphs.draw_thread(e, Vector2.ZERO, _to - e.position, 5.0, Color(Palette.COURT_BLOOD, 0.3 + 0.5 * k), CourtGlyphs.unmirror_xf(e))
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
