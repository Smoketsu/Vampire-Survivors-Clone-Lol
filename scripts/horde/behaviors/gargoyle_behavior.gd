## GargoyleBehavior — the Crypt Gargoyle's Swoop ("swoop", UnitData). The
## gargoyle claws like any melee summon; its "skirmisher" scoring plus
## score_bonus() favours clustered enemies while the swoop is ready. Then:
##   1. think(): with the swoop ready and its target swoop_range_min..
##      swoop_range_max px away, inside the engagement leash and standing in a
##      cluster (swoop_min_enemies, or an elite / the boss alone), it takes
##      off: `airborne` is set (Arena.resolve_all() skips it, it is left out
##      of the ally grid so enemies neither target nor block it, and
##      CombatResolver.damage_unit() ignores it) and it rises for
##      swoop_takeoff s,
##   2. it flies straight at the target (tracking it) at swoop_speed, over
##      obstacles and bodies, for at most swoop_max_flight s,
##   3. it dives: swoop_damage to every enemy within swoop_radius and a
##      knockback (swoop_knockback / mass), with a shockwave and a small shake,
##   4. it settles for swoop_land s onto Arena.free_point() of the impact (it
##      never lands inside an obstacle), then rejoins the shared FSM.
## Leash and recall stay in charge: a recall changes the FSM state, which
## cancels the swoop and lands the gargoyle at once (SummonBehavior.physics()).
## Stats: gargoyle_swoops, gargoyle_swoop_hits, dmg_gargoyle_swoop,
## summon_special_end_blocked (a landing inside an obstacle: must be 0).
class_name GargoyleBehavior
extends SummonBehavior

## Phase: rising in place (already airborne).
const TAKEOFF: int = 1
## Phase: flying to the dive point.
const FLIGHT: int = 2
## Phase: settling after the dive (still airborne).
const LAND: int = 3

## World point of the dive (follows the dive target while it lives).
var dive_point: Vector2 = Vector2.ZERO
## Enemy the gargoyle dives on (null once it died / was recycled).
var dive_target: Enemy = null
## Generation of `dive_target` at takeoff (stale-reference guard).
var dive_gen: int = 0
## Free ground point the gargoyle lands on.
var land_point: Vector2 = Vector2.ZERO
## Reusable enemy query buffer.
var _buf: Array = []


## Full swoop cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("swoop_cooldown", 7.0))


## Takes off toward a clustered target in range.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0 or not u.target_alive():
		return false
	var t := u.target
	var d := u.position.distance_to(t.position)  # Distance to the target (px).
	if d < float(u.special["swoop_range_min"]) or d > float(u.special["swoop_range_max"]):
		return false
	if t.position.distance_to(u.game.player.position) > UnitData.ENGAGE_RADIUS:
		return false  # Stay inside the engagement leash.
	var n := count_enemies(u.game, t.position, float(u.special["swoop_radius"]), _buf)  # Cluster size.
	if n < int(u.special["swoop_min_enemies"]) and not t.is_elite and not t.is_boss:
		return false
	dive_target = t
	dive_gen = t.generation
	dive_point = t.position
	begin_special(u, TAKEOFF)
	u.airborne = true
	Sfx.play("gargoyle_takeoff", u.position)
	u.game.stat_add("gargoyle_swoops", 1.0)
	return true


## Takeoff -> flight -> dive -> landing.
func step_special(u: SummonedUnit, delta: float) -> bool:
	match phase:
		TAKEOFF:
			u.velocity = Vector2.ZERO
			if phase_time >= float(u.special["swoop_takeoff"]):
				next_phase(FLIGHT)
		FLIGHT:
			if dive_target != null and dive_target.active and dive_target.generation == dive_gen:
				dive_point = dive_target.position
			else:
				dive_target = null
			var to := dive_point - u.position  # Remaining flight vector.
			var step_len := float(u.special["swoop_speed"]) * delta  # px this tick.
			if to.length() <= step_len or phase_time >= float(u.special["swoop_max_flight"]):
				var hit := dive_point if to.length() <= step_len else u.position  # Dive point.
				u.position = hit
				u.velocity = Vector2.ZERO
				_impact(u, hit)
				land_point = u.game.arena.free_point(hit, u.radius)
				next_phase(LAND)
			else:
				u.velocity = to / to.length() * float(u.special["swoop_speed"])
		LAND:
			var left := float(u.special["swoop_land"]) - phase_time  # Seconds of landing left.
			if left <= 0.0:
				_touch_down(u)
				end_special(u, SummonedUnit.State.ENGAGING if u.target_alive() else SummonedUnit.State.FOLLOWING)
			else:
				u.velocity = (land_point - u.position) / maxf(left, delta)
	return true


## The dive lands at `pos`: AoE damage, knockback, shockwave, shake.
func _impact(u: SummonedUnit, pos: Vector2) -> void:
	var game := u.game
	var r := float(u.special["swoop_radius"])  # Impact radius (px).
	var kb := float(u.special["swoop_knockback"])  # Knockback impulse (px/s).
	game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var hits := 0  # Enemies hit.
	for e: Enemy in _buf:
		if not e.active or e.position.distance_to(pos) > r + e.radius:
			continue
		var away := e.position - pos  # Push direction.
		e.knockback += (away / away.length() if away.length() > 0.01 else Vector2.UP) * kb / maxf(e.mass, 0.1)
		hits += 1
		game.combat.damage_enemy(e, float(u.special["swoop_damage"]), "gargoyle_swoop")
	game.effects.ring(pos, r, Palette.VIOLET, 0.3)
	game.effects.ring(pos, r * 0.55, Palette.GARGOYLE_STONE, 0.35)
	Juice.fx.burst(pos, Palette.GARGOYLE_STONE, Palette.VIOLET, 10, r * 2.0, 0.45, 2.5)
	game.shake(float(u.special["swoop_shake"]))
	Sfx.play("gargoyle_dive", pos)
	game.stat_add("gargoyle_swoop_hits", float(hits))


## Lands for good: back on the ground, on a free point.
func _touch_down(u: SummonedUnit) -> void:
	u.position = u.game.arena.free_point(land_point, u.radius)
	u.airborne = false
	if u.game.arena.is_blocked(u.position, u.radius):
		u.game.stat_add("summon_special_end_blocked", 1.0)


## A recall interrupted the swoop: land where it is (on a free point).
func on_cancel(u: SummonedUnit) -> void:
	land_point = u.position
	_touch_down(u)
	dive_target = null


## Cluster preference while the swoop is ready.
func score_bonus(u: SummonedUnit, e: Enemy, _dp: float) -> float:
	if is_busy() or special_cd > 0.0:
		return 0.0
	var n := count_enemies(u.game, e.position, float(u.special["swoop_radius"]), _buf)  # Cluster size.
	return float(u.special["cluster_bonus"]) * clampf(float(n) / maxf(float(u.special["swoop_min_enemies"]), 1.0), 0.0, 1.0)


## Height of the body: rises on takeoff, full in flight, sinks on landing.
func body_lift(u: SummonedUnit) -> float:
	var h := float(u.special.get("swoop_lift", 0.0))  # Full flight height (px).
	match phase:
		TAKEOFF:
			return h * clampf(phase_time / maxf(float(u.special["swoop_takeoff"]), 0.01), 0.0, 1.0)
		FLIGHT:
			return h
		LAND:
			return h * (1.0 - clampf(phase_time / maxf(float(u.special["swoop_land"]), 0.01), 0.0, 1.0))
	return 0.0


## Ground shadow while airborne and the dive marker during the flight.
func draw_under(u: SummonedUnit) -> void:
	if not u.airborne:
		return
	var k := body_lift(u) / maxf(float(u.special["swoop_lift"]), 1.0)  # 0..1 height.
	u.draw_set_transform(Vector2(0, u.radius * 0.8), 0.0, Vector2(1.0, 0.45))
	u.draw_circle(Vector2.ZERO, u.radius * (1.1 - 0.3 * k), Color(0, 0, 0, 0.45 - 0.15 * k))
	body_space(u)
	if phase == FLIGHT or phase == TAKEOFF:
		world_space(u)
		var at := dive_point - u.position  # Dive point in world-aligned local space.
		var r := float(u.special["swoop_radius"])  # Impact radius (px).
		u.draw_circle(at, r, Color(Palette.VIOLET, 0.10))
		u.draw_arc(at, r, 0.0, TAU, 32, Color(Palette.VIOLET, 0.7), 1.5)
		body_space(u)
