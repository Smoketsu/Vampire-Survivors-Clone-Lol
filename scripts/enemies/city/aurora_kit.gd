## AuroraKit — the kit of AURORA (CityEnemyData "aurora"; Act VIII, Liberty
## Heights; GDD §15.0 "Atlas, Aurora and Nightjar (Act VIII)"; owner-approved
## proposal: "Aurora (a flying energy blaster, figure style; falls out of the
## sky when stunned)"), a SuperKit (guarded x0.6 until her weakness is read).
## Female, the figure-redesign style (clothed): a blonde flier in a fitted
## white-and-gold suit with a flowing cape and glowing hands, no emblem (the
## approved concept act8_lineup.png). Her power and weakness,
## "Flies. Falls when stunned.":
##   * SHE FLIES (row "flies": Enemy.flies, so no summon body-blocks her; the
##     one flag of the rule): the kit owns every tick in the air. She hovers
##     hover_dist px from the nearest necromancer, drifting round him at
##     hover_speed rad/s, and every blast_every s fires blast_count ENERGY
##     BLASTS (hostile bolts, CityEnemyData.BLAST_SOURCE, a ranged City source:
##     Kevlar Bones' hook) at the necromancer, or at the nearest summon when he
##     is out of blast_range px. In the air a grounded melee summon's blow
##     deals aloft_melee_taken of itself (FallenAngelKit.grounded_melee(), as
##     the Court's fliers); ranged hits, spells and airborne summons land in
##     full;
##   * SHE FALLS WHEN STUNNED: any stun or hold (a Deep Freeze, Stasis) while
##     she flies DROPS HER OUT OF THE SKY: she falls fall_time s and lies
##     grounded for grounded_time s (no longer "flies": blockers hold her,
##     every blow lands in full) and is EXPOSED (SuperKit.expose(), "stun")
##     until she rises again (the row's exposed_time matches). The kit's
##     physics does not run while she is held (EnemyDirector), so a hold is
##     seen as a gap between two of her ticks (_held()).
## Determinism: no RNG (the nearest summon, ties in the spatial hash's
## order). Stats: aurora_blasts, aurora_falls, aurora_aloft_grazed.
class_name AuroraKit
extends SuperKit

## Phase: falling out of the sky.
const FALLING: int = 1
## Phase: grounded (exposed) until she rises again.
const GROUNDED: int = 2

## Seconds until her next volley.
var _cd: float = 0.0
## Her angle (rad) round the necromancer as she drifts.
var _angle: float = 0.0
## Direction she drifts (+1 / -1 by think slot).
var _spin: float = 1.0
## Game time (s) of her last kit tick (a hold shows as a gap).
var _last_tick: float = -1.0
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(d["blast_every"]))
	var pl := e.game.nearest_player(e.position)
	_angle = (e.position - pl.position).angle()
	_spin = 1.0 if e.think_slot % 2 == 0 else -1.0
	_last_tick = -1.0
	e.flies = true


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.flies = bool(d.get("flies", false))  # The pooled body flies again as its row says.


## True while she is in the air (her flier's taken share applies).
func aloft() -> bool:
	return phase == IDLE


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var g := e.game
	var held := _held(e, delta)
	_last_tick = g.elapsed
	match phase:
		FALLING:
			hold(e)
			phase_time += delta
			if phase_time >= float(d["fall_time"]):
				set_phase(e, GROUNDED)
			e.queue_redraw()
			return true
		GROUNDED:
			hold(e)
			phase_time += delta
			if phase_time >= float(d["grounded_time"]):
				_rise(e)
			return true
	if held:
		_fall(e)
		return true
	_hover(e, delta)
	_cd -= delta
	if _cd <= 0.0:
		if _volley(e):
			_cd = float(d["blast_every"])
		else:
			_cd = 0.5
	return true


## True when she was held (stunned, frozen) since her last tick.
func _held(e: Enemy, delta: float) -> bool:
	return _last_tick >= 0.0 and e.game.elapsed - _last_tick > delta * 3.5


## Drifts toward her hover point round the nearest necromancer (over
## buildings and the ring: she flies).
func _hover(e: Enemy, delta: float) -> void:
	var pl := e.game.nearest_player(e.position)
	_angle = fmod(_angle + float(d["hover_speed"]) * _spin * delta, TAU)
	var goal := pl.position + Vector2.from_angle(_angle) * float(d["hover_dist"])
	var to := goal - e.position
	var spd := e.move_speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
	var step := minf(spd * delta, to.length())
	if to.length() > 0.5:
		e.position += to.normalized() * step
		e.velocity = to.normalized() * spd
	else:
		e.velocity = Vector2.ZERO
	var at := pl.position - e.position
	facing = at.normalized() if at.length() > 1.0 else facing
	e._update_facing()


## A volley of energy blasts at the necromancer (else the nearest summon
## within reach). False when nothing is in reach.
func _volley(e: Enemy) -> bool:
	var g := e.game
	var reach := float(d["blast_range"])
	var t: Node2D = null
	var pl := g.nearest_player(e.position)
	if not pl.dead and pl.position.distance_to(e.position) <= reach and not g.ultimates.player_untargetable():
		t = pl
	else:
		g.ally_grid.query(e.position, reach, _buf)
		var bd := INF
		for u: SummonedUnit in _buf:
			if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
				continue
			var dd := u.position.distance_to(e.position)
			if dd <= reach and dd < bd:
				bd = dd
				t = u
	if t == null:
		return false
	var dir := (t.position - e.position).normalized() if t.position.distance_to(e.position) > 1.0 else facing
	var n := int(d["blast_count"])
	var spread := float(d["blast_spread"])
	var dmg := float(d["blast_damage"]) * hit_scale(e)
	for i in n:
		var a := dir.angle() + (float(i) - float(n - 1) * 0.5) * spread
		g.projectiles.fire_hostile(e.position, Vector2.from_angle(a), dmg, e.projectile_speed, e.undead_damage_mult,
				Projectile.Kind.RADIANT_BOLT, CityEnemyData.BLAST_SOURCE)
	g.stat_add("aurora_blasts", 1.0)
	rules(e).play_sound("gun_burst", e.position, 0.3)
	e.motion_lunge(dir, MotionData.POWER_CAST)
	return true


## A stun drops her out of the sky: she falls, then lies exposed.
func _fall(e: Enemy) -> void:
	set_phase(e, FALLING)
	hold(e)
	e.flies = false  # Grounded: blockers hold her, every blow lands.
	e.position = e.game.arena.free_point(e.position, e.radius)  # She lands in the street, not on a roof.
	e.game.stat_add("aurora_falls", 1.0)
	e.game.effects.ring(e.position, e.radius * 2.0, Palette.CITY_NEON_CYAN, 0.35)
	expose(e, "stun")


## She rises into the sky again (guarded once her window ends).
func _rise(e: Enemy) -> void:
	set_phase(e, IDLE)
	e.flies = true
	_cd = minf(_cd, float(d["blast_every"]) * 0.5)
	e.game.effects.ring(e.position, e.radius * 1.6, Palette.CITY_NEON_CYAN, 0.3)
	e.queue_redraw()


## In the air a grounded melee blow deals aloft_melee_taken of itself; on
## top of the guarded / exposed share.
func taken_mult(e: Enemy, source: String) -> float:
	var m := super.taken_mult(e, source)
	if aloft() and FallenAngelKit.grounded_melee(source):
		e.game.stat_add("aurora_aloft_grazed", 1.0)
		m *= float(d["aloft_melee_taken"])
	return m


func is_busy() -> bool:
	return phase != IDLE or super.is_busy()


## Her shadow on the ground while she flies (she is drawn lifted). Visual only.
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	if aloft():
		var r := e.radius * 1.2
		e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, e.radius * 0.6), Vector2(r * 2.0, r * 0.8)), false, Color(0.0, 0.0, 0.0, 0.25))
