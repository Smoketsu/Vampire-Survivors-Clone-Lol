## NightjarKit — the kit of NIGHTJAR (CityEnemyData "nightjar"; Act VIII,
## Liberty Heights; GDD §15.0 "Atlas, Aurora and Nightjar (Act VIII)";
## owner-approved proposal: "Nightjar (a gadget vigilante who grapples summons
## out of the ring; must land to strike)"), a SuperKit (guarded x0.6 until his
## weakness is read). Male: a hooded vigilante in a charcoal-and-purple
## armoured suit with round glowing goggles, a short scarf and a grapple gun
## (no cape, no bat shapes, no emblem; the approved concept act8_lineup.png). His
## power and weakness, "Grapples. Must land to strike.":
##   * HE SWINGS over the ring between strikes (row "flies": Enemy.flies, no
##     summon body-blocks him; in the air a grounded melee blow deals
##     aloft_melee_taken of itself): the kit circles him round the necromancer
##     at the Bone Ring's edge;
##   * THE GRAPPLE: every grapple_every s, with a summon within grapple_range
##     px, a line shows from him to it for grapple_windup s; then he REELS it
##     pull_time s OUT OF THE RING, to pull_out px beyond the Bone Ring's outer
##     edge (StanceData.RING_MAX + RING_LAYER) away from the necromancer,
##     through THE HELD HOOK (SummonedUnit.held_until renewed each tick, the
##     Netcaster's net and the Chiropteran King's carry-off: a held summon
##     cannot walk but still strikes; carry() is the one place that moves it).
##     Airborne, spawning, dead, charmed or compelled summons are never
##     grappled. He drops it there (held drop_daze s more) and LANDS beside it;
##   * HE MUST LAND TO STRIKE: landed (land_time s, no longer "flies": his
##     blows land and every blow on him lands in full) he strikes the reeled
##     summon at once (strike_damage) and then fights with the shared melee
##     AI. While he is landed a BLOCKER summon touching him (its block radius)
##     or a STUN or hold EXPOSES him (SuperKit.expose(), "blocker" / "stun").
##     The kit's physics does not run while he is held (EnemyDirector), so a
##     hold is seen as a gap between two of his ticks (_held()).
## Determinism: no RNG (the nearest summon, ties in the spatial hash's
## order). Stats: nightjar_grapples, nightjar_reeled, nightjar_reel_px,
## nightjar_landings, nightjar_strikes, nightjar_aloft_grazed.
class_name NightjarKit
extends SuperKit

## Phase: the grapple line shows.
const AIM: int = 1
## Phase: reeling the summon out of the ring.
const REEL: int = 2
## Phase: landed to strike (the weakness's window).
const LANDED: int = 3
## Seconds a reeled summon's hold is renewed each tick (it lapses on its own
## if he stops renewing it).
const REEL_HOLD: float = 0.2  # TUNING (not in GDD)

## Seconds until his next grapple.
var _cd: float = 0.0
## The grappled summon (null when none).
var _prey: SummonedUnit = null
## Pool generation of `_prey` (stale guard).
var _prey_gen: int = 0
## Where the reel ends (world px).
var _reel_to: Vector2 = Vector2.ZERO
## Where the reel began (world px; the report's distance).
var _reel_from: Vector2 = Vector2.ZERO
## His angle (rad) round the necromancer while he swings.
var _angle: float = 0.0
## Game time (s) of his last kit tick (a hold shows as a gap).
var _last_tick: float = -1.0
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(d["grapple_first"]))
	_prey = null
	_last_tick = -1.0
	_angle = (e.position - e.game.nearest_player(e.position).position).angle()
	e.flies = true


func on_deactivate(e: Enemy) -> void:
	_let_go(e)
	super.on_deactivate(e)
	e.flies = bool(d.get("flies", false))  # The pooled body flies again as its row says.


## True while he swings (in the air).
func aloft() -> bool:
	return phase != LANDED


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var g := e.game
	var held := _held(e, delta)
	_last_tick = g.elapsed
	match phase:
		AIM:
			hold(e)
			phase_time += delta
			if not _prey_ok():
				_let_go(e)
				set_phase(e, IDLE)
				return true
			if phase_time >= float(d["grapple_windup"]):
				_start_reel(e)
			e.queue_redraw()
			return true
		REEL:
			hold(e)
			phase_time += delta
			_reel(e, delta)
			if not _prey_ok() or phase_time >= float(d["pull_time"]):
				_land(e)
			e.queue_redraw()
			return true
		LANDED:
			phase_time += delta
			if held and not is_exposed(e):
				expose(e, "stun")
			elif not is_exposed(e) and _blocker_touching(e):
				expose(e, "blocker")
			if phase_time >= float(d["land_time"]):
				_take_off(e)
				return true
			return false  # Landed: the shared melee AI strikes.
	_swing(e, delta)
	_cd -= delta
	if _cd <= 0.0:
		_cd = 0.5
		_aim(e)
	return true


## True when he was held (stunned, frozen) since his last tick.
func _held(e: Enemy, delta: float) -> bool:
	return _last_tick >= 0.0 and e.game.elapsed - _last_tick > delta * 3.5


## Swinging: he circles the necromancer at the Bone Ring's edge.
func _swing(e: Enemy, delta: float) -> void:
	var pl := e.game.nearest_player(e.position)
	_angle = fmod(_angle + 0.6 * delta, TAU)
	var goal := pl.position + Vector2.from_angle(_angle) * (StanceData.RING_MAX + 10.0)
	var to := goal - e.position
	var spd := e.move_speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
	if to.length() > 0.5:
		e.position += to.normalized() * minf(spd * delta, to.length())
		e.velocity = to.normalized() * spd
	else:
		e.velocity = Vector2.ZERO
	var at := pl.position - e.position
	facing = at.normalized() if at.length() > 1.0 else facing
	e._update_facing()


## Picks the nearest summon in reach and shows the grapple line to it.
func _aim(e: Enemy) -> void:
	var g := e.game
	var reach := float(d["grapple_range"])
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	var best: SummonedUnit = null
	var bd := INF
	for u: SummonedUnit in _buf:
		if not _grabbable(u):
			continue
		var dd := u.position.distance_to(e.position)
		if dd <= reach + u.radius and dd < bd:
			bd = dd
			best = u
	if best == null:
		return
	_prey = best
	_prey_gen = best.generation
	_cd = float(d["grapple_every"])
	g.effects.telegraph_line(e.position, best.position, 6.0, float(d["grapple_windup"]), e)
	g.stat_add("nightjar_grapples", 1.0)
	set_phase(e, AIM)
	hold(e)


## True when summon `u` can be grappled (on the ground, alive, its own).
static func _grabbable(u: SummonedUnit) -> bool:
	return u.active and not u.airborne and not u.charmed and not u.is_compelled() \
			and u.state != SummonedUnit.State.SPAWNING and u.state != SummonedUnit.State.DEAD


## True while the grappled summon is still the one he aimed at, alive.
func _prey_ok() -> bool:
	return _prey != null and _prey.active and _prey.generation == _prey_gen and _prey.state != SummonedUnit.State.DEAD


## The line hits: the reel begins, out of the ring away from the necromancer.
func _start_reel(e: Enemy) -> void:
	var g := e.game
	var pl := g.nearest_player(_prey.position)
	var away := _prey.position - pl.position
	var dir := away.normalized() if away.length() > 1.0 else Vector2.RIGHT
	_reel_from = _prey.position
	_reel_to = g.arena.free_point(pl.position + dir * (StanceData.RING_MAX + StanceData.RING_LAYER + float(d["pull_out"])), _prey.radius)
	_prey.held_until = maxf(_prey.held_until, g.elapsed + REEL_HOLD)
	g.stat_add("nightjar_reeled", 1.0)
	rules(e).play_sound("engine_rev", e.position, 0.4)
	set_phase(e, REEL)


## THE one place that moves a reeled summon: held a moment longer and drawn
## along toward the end of the reel; he swings out with it.
func _reel(e: Enemy, delta: float) -> void:
	if not _prey_ok():
		return
	var g := e.game
	var left := maxf(0.05, float(d["pull_time"]) - phase_time + delta)
	var to := _reel_to - _prey.position
	var step := minf(to.length(), to.length() / left * delta)
	if to.length() > 0.5:
		_prey.position += to.normalized() * step
	_prey.velocity = Vector2.ZERO
	_prey.held_until = maxf(_prey.held_until, g.elapsed + REEL_HOLD)
	var me := _prey.position + (_prey.position - g.nearest_player(_prey.position).position).normalized() * (e.radius + _prey.radius + 6.0)
	e.position = e.position.lerp(me, clampf(8.0 * delta, 0.0, 1.0))


## The reel ends: the summon drops (dazed) and he LANDS beside it to strike.
func _land(e: Enemy) -> void:
	var g := e.game
	if _prey_ok():
		_prey.position = g.arena.free_point(_prey.position, _prey.radius)
		_prey.held_until = maxf(_prey.held_until, g.elapsed + float(d["drop_daze"]))
		g.stat_add("nightjar_reel_px", _reel_from.distance_to(_prey.position))
		var dmg := float(d["strike_damage"]) * hit_scale(e) * e.undead_damage_mult
		g.combat.damage_unit(_prey, dmg, CityEnemyData.STRIKE_SOURCE, e)
		g.stat_add("nightjar_strikes", 1.0)
		g.effects.slash(_prey.position, _prey.position - e.position, Palette.CITY_CONCRETE_LIGHT, e.radius * 1.4)
	e.position = g.arena.free_point(e.position, e.radius)
	e.flies = false
	g.stat_add("nightjar_landings", 1.0)
	if _prey_ok():
		e._set_target(_prey)
	_prey = null
	set_phase(e, LANDED)


## Landed long enough: he fires a line to a rooftop and swings up again.
func _take_off(e: Enemy) -> void:
	e.flies = true
	_angle = (e.position - e.game.nearest_player(e.position).position).angle()
	set_phase(e, IDLE)


## A blocker summon touching him while he is landed (the weakness).
func _blocker_touching(e: Enemy) -> bool:
	e.game.ally_grid.query(e.position, e.radius + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if u.active and u.block_radius > 0.0 and u.state != SummonedUnit.State.DEAD \
				and u.position.distance_to(e.position) <= e.radius + u.block_radius + 2.0:
			return true
	return false


## Lets the reeled summon go where it is (he died or was pooled mid-reel).
func _let_go(e: Enemy) -> void:
	if _prey_ok():
		_prey.position = e.game.arena.free_point(_prey.position, _prey.radius)
		_prey.held_until = minf(_prey.held_until, e.game.elapsed)
	_prey = null


## In the air a grounded melee blow deals aloft_melee_taken of itself; on top
## of the guarded / exposed share.
func taken_mult(e: Enemy, source: String) -> float:
	var m := super.taken_mult(e, source)
	if aloft() and FallenAngelKit.grounded_melee(source):
		e.game.stat_add("nightjar_aloft_grazed", 1.0)
		m *= float(d["aloft_melee_taken"])
	return m


func is_busy() -> bool:
	return phase == AIM or phase == REEL or super.is_busy()


## Under him: his shadow while he swings, and the grapple line while he aims
## and reels (a thin gradient strip). Visual only.
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	if aloft():
		var r := e.radius * 1.2
		e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, e.radius * 0.6), Vector2(r * 2.0, r * 0.8)), false, Color(0.0, 0.0, 0.0, 0.25))
	if (phase == AIM or phase == REEL) and _prey_ok():
		var to := _prey.position - e.position
		if to.length() > 1.0:
			CityGlyphs.draw_headlights(e, Vector2.ZERO, to.normalized(), to.length(), 1.5, 0.8, CourtGlyphs.unmirror_xf(e), Palette.CITY_CONCRETE_LIGHT)
			e.draw_set_transform_matrix(Transform2D.IDENTITY)
