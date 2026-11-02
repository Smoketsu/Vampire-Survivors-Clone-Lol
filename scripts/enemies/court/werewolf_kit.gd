## WerewolfKit — the kit of the Werewolf (CourtEnemyData "werewolf"; Act VII,
## GDD §15.0 "Act VII foundation (phase 1)"; owner-approved proposal: "A human
## hunter with a silver crossbow until the Blood Moon or half HP, then a huge
## beast that lunges and feeds hard"). A WEREBEAST (row "werebeast"):
##   * THE HUNTER: the row's "ranged" behaviour, a silver crossbow bolt (the
##     shared hostile shot: it names no attacker, so it never feeds).
##   * THE TURNING: the moment the Blood Moon is up (BloodMoon.is_up(), THE
##     test) or it falls to beast_at of its max HP, it turns for good: a melee
##     BEAST (beast_* keys: speed, blow, reach, body, weight), drawn as the
##     beast's sprite (court/werewolf_beast, else CourtGlyphs' fallback), with
##     a howl. Its blows feed it through the shared melee path (Bloodfeast).
##   * THE LUNGE (the beast): when its target is between lunge_min and
##     lunge_trigger px away (edge to edge) and the lunge is ready, it crouches
##     for lunge_windup s (a red line on the ground to where it will land; the
##     autotest bot steps off it), leaps there in lunge_time s and bites its
##     target for lunge_damage if it is still within reach (a feeding blow:
##     CombatResolver names it as the attacker).
## The Silver Bones hook (summon hits deal more) is CourtKit's.
## No RNG. Stats: werewolf_turned, werewolf_turned_moon, werewolf_turned_hp,
## werewolf_lunges, werewolf_lunge_hits.
class_name WerewolfKit
extends CourtKit

## Phase: the beast crouches before the leap.
const CROUCH: int = 1
## Phase: the leap.
const LEAP: int = 2
## px of reach the autotest bot keeps from the landing point beyond the body.
const DANGER_REACH: float = 18.0  # TUNING (not in GDD) autotest hint only

## True once it turned into the beast (for good).
var beast: bool = false
## Seconds until the next lunge may start.
var _lunge_cd: float = 0.0
## Where the leap starts (world px).
var _from: Vector2 = Vector2.ZERO
## Where the leap lands (world px; locked when it crouches).
var _to: Vector2 = Vector2.ZERO


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	beast = false
	_lunge_cd = first_cd(e, float(def.get("lunge_every", 6.0)) * 0.5)


func physics(e: Enemy, delta: float) -> bool:
	if not beast:
		var g := e.game
		var moon := g.court != null and g.court.moon.is_up()
		if moon or e.hp <= e.max_hp * float(d.get("beast_at", 0.5)):
			_turn(e, moon)
		return false
	_lunge_cd -= delta
	match phase:
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
			var k := clampf(phase_time / maxf(0.01, float(d.get("lunge_time", 0.25))), 0.0, 1.0)  # 0 -> 1 to the mark.
			e.position = _from.lerp(_to, k)
			e.velocity = Vector2.ZERO
			if k >= 1.0:
				_land(e)
				set_phase(e, IDLE)
			return true
	if _lunge_cd > 0.0 or not e._target_valid():
		return false
	var t := e.target
	var to := t.position - e.position
	var dist := to.length()
	var edge := dist - e.radius - body_radius(e, t)
	if edge < float(d.get("lunge_min", 30.0)) or edge > float(d.get("lunge_trigger", 110.0)) or dist < 0.01:
		return false
	if t == e.game.player and e.game.ultimates.player_untargetable():
		return false
	_lunge_cd = float(d.get("lunge_every", 6.0))
	_to = t.position - to / dist * (e.radius + body_radius(e, t))
	e.game.stat_add("werewolf_lunges", 1.0)
	set_phase(e, CROUCH)
	hold(e)
	return true


## Turns into the beast for good (`moon`: under the Blood Moon, else at half HP).
func _turn(e: Enemy, moon: bool) -> void:
	var g := e.game
	beast = true
	e.behavior = "melee"
	e.move_speed = float(d.get("beast_speed", 66.0))
	e.damage = float(d.get("beast_damage", 12.0))
	e.attack_interval = float(d.get("beast_interval", 1.2))
	e.attack_range = float(d.get("beast_range", 14.0))
	e.radius = float(d.get("beast_radius", 20.0))
	e.glory_base_radius = e.radius
	e.mass = float(d.get("beast_mass", 5.0))
	e.attack_cd = minf(e.attack_cd, 0.6)
	g.stat_add("werewolf_turned", 1.0)
	if moon:
		g.stat_add("werewolf_turned_moon", 1.0)
		g.court.moon.transforms += 1
	else:
		g.stat_add("werewolf_turned_hp", 1.0)
	if e.motion != null:
		e.motion.reset(UnitMotion.feet_of(CourtEnemyData.BEAST_SPRITE, "", e.radius), e.radius, 1.0, false)
	g.effects.ring(e.position, e.radius * 2.2, Palette.COURT_BLOOD, 0.4)
	rules(e).play_sound("wolf_howl", e.position, 0.5)
	e.queue_redraw()


## The leap lands: the bite on its target if it is still within reach.
func _land(e: Enemy) -> void:
	var g := e.game
	if not e._target_valid():
		return
	var t := e.target
	var edge := e.position.distance_to(t.position) - e.radius - body_radius(e, t)
	if edge > e.attack_range + 10.0:
		return
	var dmg := float(d.get("lunge_damage", 12.0)) * hit_scale(e)
	g.stat_add("werewolf_lunge_hits", 1.0)
	g.effects.slash(e.position, t.position - e.position, Palette.COURT_BLOOD_LIGHT, e.radius * 1.4)
	if t is SummonedUnit:
		g.combat.damage_unit(t as SummonedUnit, dmg * e.undead_damage_mult, CourtEnemyData.LUNGE_SOURCE, e)
	else:
		g.combat.damage_player(dmg, CourtEnemyData.LUNGE_SOURCE, t as Necromancer, e)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: off the landing point while it crouches and leaps.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != CROUCH and phase != LEAP:
		return Vector2.ZERO
	var reach := e.radius + DANGER_REACH
	var off := p - _to
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.0


## The beast draws itself (its own sprite); the hunter is the kind's art.
func draws_body(_e: Enemy) -> bool:
	return beast


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	if not SpriteBank.draw(ci, CourtEnemyData.BEAST_SPRITE, Vector2.ZERO, e.flash > 0.0):
		CourtGlyphs.draw_beast(ci, Vector2.ZERO, e.radius, e.flash > 0.0)


## While it crouches, a red line on the ground to where it will land.
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	if phase != CROUCH:
		return
	var k := clampf(phase_time / maxf(float(d.get("lunge_windup", 0.5)), 0.01), 0.0, 1.0)
	CourtGlyphs.draw_thread(e, Vector2.ZERO, _to - e.position, 4.0, Color(Palette.COURT_BLOOD, 0.3 + 0.5 * k), CourtGlyphs.unmirror_xf(e))
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
