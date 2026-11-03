## WarbeastKit — THE WARBEAST, the Proving Moon's miniboss (ProvingMoonEnemyData
## "warbeast"; Act IX, Stage 26; GDD §15.0 "The Warbeast (Act IX)"; brief: "the
## Vrask's armoured hunting animal (a creature, teal and dark armour plates).
## It has a pounce (a telegraphed leap, longer under low gravity) and
## flat_armor"). Spawned once by ProvingMoonDirector (the "warbeast" timeline
## event) through the normal spawn path; it registers as EnemyDirector.miniboss
## (the HUD's miniboss bar; ChestManager drops the miniboss chest). A plain
## melee walker (the shared walk and bite) with:
##   * ARMOUR PLATES — the row's flat_armor (the existing flat armour path in
##     CombatResolver.damage_enemy(); Wither shreds it).
##   * THE POUNCE — every pounce_every s, when its target stands between
##     pounce_min (edge to edge) and pounce_reach x the low gravity
##     (ConcordRules.gravity(): 2.0 on the moon, twice as far) px away, it
##     CROUCHES for pounce_windup s with a landing circle on the target's spot
##     (EffectManager.telegraph_circle()), then leaps there in pounce_time s,
##     over the Bone Ring (the leap ignores the body-block, as Vargr's), and
##     LANDS: every necromancer and summon in the circle is bitten
##     (OlympusHits.circle(), source POUNCE_SOURCE) and the summons are thrown
##     out pounce_push px x the low gravity. The autotest bot steps out of the
##     circle (danger_push()).
##   * Blows do not shove it (like Mammoth: knockback cleared each tick), so
##     the moon's low gravity throws everything but it.
## Dead: an XP burst (reward_xp in reward_crystals) and the banner.
## No RNG (the first pounce staggered by the think slot). Stats:
## warbeast_spawned, warbeast_pounces, warbeast_pounce_hits,
## warbeast_pounce_reach_max, warbeast_kills, warbeast_ttk.
class_name WarbeastKit
extends ConcordKit

## Phase: the crouch before the pounce (its landing circle shows).
const CROUCH: int = 1
## Phase: the leap.
const LEAP: int = 2
## px the autotest bot keeps from the landing circle beyond its radius.
const DANGER_REACH: float = 22.0  # TUNING (not in GDD) autotest hint only

## Seconds until the next pounce may start.
var _pounce_cd: float = 0.0
## Where the leap starts (world px).
var _from: Vector2 = Vector2.ZERO
## Where the leap lands (world px; locked when it crouches).
var _to: Vector2 = Vector2.ZERO
## Game time it arrived (time-to-kill stat).
var _spawned_at: float = 0.0
## Reusable query buffer of the landing.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_pounce_cd = first_cd(e, float(d.get("pounce_first", 3.0)))
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("warbeast_spawned", 1.0)


## The pounce reach of this kind on this stage (px): the row's x the low gravity.
func pounce_reach(e: Enemy) -> float:
	return float(d.get("pounce_reach", 150.0)) * rules(e).gravity()


func physics(e: Enemy, delta: float) -> bool:
	e.knockback = Vector2.ZERO  # A miniboss: blows do not shove it.
	if super.physics(e, delta):
		return true
	_pounce_cd -= delta
	match phase:
		CROUCH:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("pounce_windup", 0.9)):
				_from = e.position
				set_phase(e, LEAP)
			return true
		LEAP:
			phase_time += delta
			var k := clampf(phase_time / maxf(0.01, float(d.get("pounce_time", 0.45))), 0.0, 1.0)  # 0 -> 1 to the mark.
			e.position = _from.lerp(_to, k)
			e.velocity = Vector2.ZERO
			e.queue_redraw()  # The arc.
			if k >= 1.0:
				_land(e)
				set_phase(e, IDLE)
			return true
	if _pounce_cd > 0.0 or not e._target_valid():
		return false
	var t := e.target
	var to := t.position - e.position
	var dist := to.length()
	var edge := dist - e.radius - body_radius(e, t)
	if edge < float(d.get("pounce_min", 40.0)) or dist > pounce_reach(e):
		return false
	if t is Necromancer and e.game.ultimates.player_untargetable():
		return false
	_pounce_cd = float(d.get("pounce_every", 6.5))
	_to = e.game.arena.free_point(t.position, e.radius * 0.5)
	e.game.effects.telegraph_circle(_to, float(d.get("pounce_radius", 46.0)), float(d.get("pounce_windup", 0.9)), e)
	e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	e.game.stat_add("warbeast_pounces", 1.0)
	e.game.stats["warbeast_pounce_reach_max"] = maxf(float(e.game.stats.get("warbeast_pounce_reach_max", 0.0)), dist)
	set_phase(e, CROUCH)
	hold(e)
	return true


## The landing: the bite on everything in the circle and the throw (x the low gravity).
func _land(e: Enemy) -> void:
	var g := e.game
	var s := hit_scale(e)
	var push := float(d.get("pounce_push", 18.0)) * rules(e).gravity()  # px the summons are thrown.
	g.stat_add("warbeast_pounce_hits", float(OlympusHits.circle(g, _to, float(d.get("pounce_radius", 46.0)),
			float(d.get("pounce_damage_player", 9.0)) * s, float(d.get("pounce_damage_summon", 10.0)) * s * e.undead_damage_mult,
			ProvingMoonEnemyData.POUNCE_SOURCE, e, push, _buf)))
	g.effects.impact(_to, float(d.get("pounce_radius", 46.0)), Palette.CONCORD_VRASK)
	g.shake(4.0)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the landing circle while it crouches and leaps.
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	if phase != CROUCH and phase != LEAP:
		return Vector2.ZERO
	var reach := float(d.get("pounce_radius", 46.0)) + DANGER_REACH
	var off := p - _to
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.5


## Its body: the sprite lifted on the leap's arc (pose 1 while it crouches),
## else ProvingMoonGlyphs' armoured beast.
func draws_body(_e: Enemy) -> bool:
	return true


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var lift := Vector2.ZERO
	if phase == LEAP:
		var k := clampf(phase_time / maxf(0.01, float(d.get("pounce_time", 0.45))), 0.0, 1.0)
		lift = Vector2(0.0, -float(d.get("pounce_height", 26.0)) * 4.0 * k * (1.0 - k))
	var key := e.motion_sprite_key() if phase == IDLE else ProvingMoonEnemyData.WARBEAST_SPRITE
	if SpriteBank.draw(ci, key, lift, e.flash > 0.0):
		return
	ProvingMoonGlyphs.draw_warbeast(ci, lift, e.radius, e.flash > 0.0, phase == CROUCH)


## Its shadow stays on the ground while it leaps.
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	if phase == LEAP:
		e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-e.radius, e.radius * 0.4), Vector2(e.radius * 2.0, e.radius * 0.7)), false, Color(0.0, 0.0, 0.0, 0.35))


## The XP burst, the banner and the stats.
func on_killed(e: Enemy) -> void:
	var g := e.game
	super.on_killed(e)
	var n := maxi(1, int(d.get("reward_crystals", 12)))
	var each := maxi(1, floori(float(d.get("reward_xp", 260)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (28.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.CONCORD_VRASK)
	g.shake(7.0)
	g.enemies.show_banner("The Warbeast falls! The hunters lose their hound.")
	g.stat_add("warbeast_kills", 1.0)
	g.stat_add("warbeast_ttk", g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)
