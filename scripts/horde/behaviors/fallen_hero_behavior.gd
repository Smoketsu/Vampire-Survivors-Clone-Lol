## FallenHeroBehavior — the Fallen Hero's HERO'S SLAM ("hero_slam", UnitData
## "fallen_hero"; Act VIII, Liberty Heights's finale reward; GDD §15.0 "The
## Fallen Hero, Black Paragon and Origin Story"; owner-approved proposal:
## "Finale summon class: the Fallen Hero, a raised Super who flies around the
## ring and slams into packs (evolution Black Paragon)"). A raised Super (male)
## who fights in melee on the Bone Ring's front posts between slams. Its
## special, a class special that works the same on every stage (owner rule:
## summons never get act-only rules):
##   1. think(): with the slam ready, it picks the DENSEST PACK within
##      slam_range px of its necromancer (the enemy with the most foes within
##      slam_radius px, of at most SCAN enemies; a pack of slam_min_enemies, or
##      an elite / the boss alone) and takes off: `airborne` (Arena.resolve_all()
##      skips it, it leaves the ally grid: enemies neither target nor block it,
##      CombatResolver.damage_unit() ignores it), rising slam_takeoff s;
##   2. ORBIT: it FLIES AROUND THE RING for slam_orbit s (ORBIT_SPEED rad/s
##      round the necromancer at its distance, clamped to the Bone Ring);
##   3. FLIGHT: it flies at the pack at slam_speed px/s (tracking it), at most
##      MAX_FLIGHT s;
##   4. the SLAM: slam_damage to every enemy within slam_radius px and a
##      knockback (slam_knockback / mass), a shockwave and a small shake;
##   5. evolved into BLACK PARAGON (SummonEvolutionData "black_paragon",
##      special_set chain_slams / slam_stun / stun_boss_mult / stun_elite_mult):
##      each slam also stuns what it hits slam_stun s (CombatResolver
##      .stun_enemy(): bosses stun_boss_mult, elites stun_elite_mult) and it
##      flies on to chain_slams more packs within CHAIN_RANGE px before
##      landing;
##   6. it settles slam_land s onto Arena.free_point() of the last impact (it
##      never lands inside an obstacle), then rejoins the shared FSM.
## Leash and recall stay in charge: a recall cancels the slam and lands it at
## once (SummonBehavior.physics()). Origin Story (its paired passive) widens
## every class special in HordeDirector._special_stats() (the one path).
## Determinism: no RNG (the densest pack, ties in the spatial hash's order).
## Stats: fallen_hero_slams, fallen_hero_slam_hits, fallen_hero_chains,
## black_paragon_stuns, dmg_fallen_hero_slam / dmg_black_paragon_slam,
## summon_special_end_blocked (a landing inside an obstacle: must be 0).
class_name FallenHeroBehavior
extends SummonBehavior

## Phase: rising in place (already airborne).
const TAKEOFF: int = 1
## Phase: flying around the ring.
const ORBIT: int = 2
## Phase: flying at the pack.
const FLIGHT: int = 3
## Phase: settling after the last slam (still airborne).
const LAND: int = 4
## Enemies scanned for the densest pack (cost bound).
const SCAN: int = 24  # TUNING (not in GDD)
## Radians per second it circles the ring in the orbit phase.
const ORBIT_SPEED: float = 2.8  # TUNING (not in GDD)
## Most seconds of one flight at a pack (it slams wherever it is by then).
const MAX_FLIGHT: float = 1.4  # TUNING (not in GDD)
## Px from an impact within which Black Paragon's chained slam looks for the
## next pack.
const CHAIN_RANGE: float = 180.0  # TUNING (not in GDD)
## Damage-source tag of the slam.
const SOURCE: String = "fallen_hero_slam"
## Damage-source tag of Black Paragon's slam.
const EVOLVED_SOURCE: String = "black_paragon_slam"

## World point of the slam (follows the pack's enemy while it lives).
var slam_point: Vector2 = Vector2.ZERO
## The pack's enemy it dives on (null once it died / was recycled).
var slam_target: Enemy = null
## Generation of `slam_target` at the pick (stale-reference guard).
var slam_gen: int = 0
## Free ground point it lands on.
var land_point: Vector2 = Vector2.ZERO
## Chained slams left (Black Paragon).
var chains_left: int = 0
## Its angle (rad) round the necromancer during the orbit.
var _orbit_a: float = 0.0
## Its distance (px) from the necromancer during the orbit.
var _orbit_r: float = 80.0
## Reusable enemy query buffer.
var _buf: Array = []
## Second reusable enemy query buffer (the pack counts).
var _buf2: Array = []


## Full slam cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("slam_cooldown", 6.5))


## Takes off toward the densest pack within reach of its necromancer.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0:
		return false
	var e := _densest(u, u.game.player.position, float(u.special["slam_range"]), [])
	if e == null:
		return false
	slam_target = e
	slam_gen = e.generation
	slam_point = e.position
	chains_left = int(u.special.get("chain_slams", 0))
	var off := u.position - u.game.player.position
	_orbit_a = off.angle()
	_orbit_r = clampf(off.length(), 60.0, StanceData.RING_MAX)
	begin_special(u, TAKEOFF)
	u.airborne = true
	Sfx.play("gargoyle_takeoff", u.position)
	u.game.stat_add("fallen_hero_slams", 1.0)
	return true


## The enemy with the most foes within slam_radius px, of the first SCAN
## enemies within `reach` px of `from` (none in `skip`); null without a pack
## (slam_min_enemies, or an elite / the boss alone).
func _densest(u: SummonedUnit, from: Vector2, reach: float, skip: Array) -> Enemy:
	var game := u.game
	var r := float(u.special["slam_radius"])
	game.enemy_grid.query(from, reach, _buf)
	var best: Enemy = null
	var best_n := 0
	var seen := 0
	for e: Enemy in _buf:
		if seen >= SCAN:
			break
		if not e.active or e.is_structure or e.civilian or skip.has(e) or e.position.distance_to(from) > reach:
			continue
		seen += 1
		var n := count_enemies(game, e.position, r, _buf2)
		if e.is_elite or e.is_boss:
			n = maxi(n, int(u.special["slam_min_enemies"]))
		if n > best_n:
			best_n = n
			best = e
	return best if best_n >= int(u.special["slam_min_enemies"]) else null


## Takeoff -> orbit -> flight -> slam (-> chained flights) -> landing.
func step_special(u: SummonedUnit, delta: float) -> bool:
	var p := u.game.player.position
	match phase:
		TAKEOFF:
			u.velocity = Vector2.ZERO
			if phase_time >= float(u.special["slam_takeoff"]):
				next_phase(ORBIT)
		ORBIT:
			_orbit_a += ORBIT_SPEED * delta
			var goal := p + Vector2.from_angle(_orbit_a) * _orbit_r
			u.velocity = (goal - u.position) / maxf(delta, 0.001)
			if u.velocity.length() > float(u.special["slam_speed"]) * 1.5:
				u.velocity = u.velocity.normalized() * float(u.special["slam_speed"]) * 1.5
			if phase_time >= float(u.special["slam_orbit"]):
				next_phase(FLIGHT)
		FLIGHT:
			if slam_target != null and slam_target.active and slam_target.generation == slam_gen:
				slam_point = slam_target.position
			else:
				slam_target = null
			var to := slam_point - u.position
			var step_len := float(u.special["slam_speed"]) * delta
			if to.length() <= step_len or phase_time >= MAX_FLIGHT:
				var hit := slam_point if to.length() <= step_len else u.position
				u.position = hit
				u.velocity = Vector2.ZERO
				var hits := _impact(u, hit)
				if chains_left > 0 and _chain(u, hit, hits):
					return true
				land_point = u.game.arena.free_point(hit, u.radius)
				next_phase(LAND)
			else:
				u.velocity = to / to.length() * float(u.special["slam_speed"])
		LAND:
			var left := float(u.special["slam_land"]) - phase_time
			if left <= 0.0:
				_touch_down(u)
				end_special(u, SummonedUnit.State.ENGAGING if u.target_alive() else SummonedUnit.State.FOLLOWING)
			else:
				u.velocity = (land_point - u.position) / maxf(left, delta)
	return true


## Black Paragon: flies on to the next pack near the impact. False when none.
func _chain(u: SummonedUnit, at: Vector2, hit: Array) -> bool:
	var e := _densest(u, at, CHAIN_RANGE, hit)
	if e == null:
		return false
	chains_left -= 1
	slam_target = e
	slam_gen = e.generation
	slam_point = e.position
	u.game.stat_add("fallen_hero_chains", 1.0)
	next_phase(FLIGHT)
	return true


## The slam lands at `pos`: AoE damage, knockback, the stun (Black Paragon),
## shockwave, shake. Returns the enemies hit.
func _impact(u: SummonedUnit, pos: Vector2) -> Array:
	var game := u.game
	u.motion_lunge(Vector2.ZERO, MotionData.POWER_MELEE)  # Engine motion: the slam (visual only).
	var r := float(u.special["slam_radius"])
	var kb := float(u.special["slam_knockback"])
	var stun := float(u.special.get("slam_stun", 0.0))
	var src := EVOLVED_SOURCE if stun > 0.0 else SOURCE
	game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var hit: Array = []
	for e: Enemy in _buf.duplicate():
		if not e.active or e.position.distance_to(pos) > r + e.radius:
			continue
		var away := e.position - pos
		e.knockback += (away / away.length() if away.length() > 0.01 else Vector2.UP) * kb / maxf(e.mass, 0.1)
		hit.append(e)
		game.combat.damage_enemy(e, float(u.special["slam_damage"]), src)
		if stun > 0.0 and e.active:
			if game.combat.stun_enemy(e, stun, float(u.special["stun_boss_mult"]), float(u.special["stun_elite_mult"])) > 0.0:
				game.stat_add("black_paragon_stuns", 1.0)
	game.effects.art_ring(pos, r, Palette.NECRO_GREEN, 0.3, "dive")
	game.effects.art_ring_under(pos, r * 0.6, Palette.IVORY, 0.35, "dive")
	Juice.fx.burst(pos, Palette.IVORY, Palette.NECRO_GREEN, 10, r * 2.0, 0.45, 2.5)
	game.shake(float(u.special["slam_shake"]))
	Sfx.play("gargoyle_dive", pos)
	game.volleys.on_special(u, pos, pos + Vector2.RIGHT, float(u.special["slam_damage"]))  # Bullet heaven: the showpiece.
	game.stat_add("fallen_hero_slam_hits", float(hit.size()))
	return hit


## Lands for good: back on the ground, on a free point.
func _touch_down(u: SummonedUnit) -> void:
	u.position = u.game.arena.free_point(land_point, u.radius)
	u.airborne = false
	if u.game.arena.is_blocked(u.position, u.radius):
		u.game.stat_add("summon_special_end_blocked", 1.0)


## A recall interrupted the slam: land where it is (on a free point).
func on_cancel(u: SummonedUnit) -> void:
	land_point = u.position
	_touch_down(u)
	slam_target = null


## Cluster preference while the slam is ready.
func score_bonus(u: SummonedUnit, e: Enemy, _dp: float) -> float:
	if is_busy() or special_cd > 0.0:
		return 0.0
	var n := count_enemies(u.game, e.position, float(u.special["slam_radius"]), _buf2)
	return float(u.special["cluster_bonus"]) * clampf(float(n) / maxf(float(u.special["slam_min_enemies"]), 1.0), 0.0, 1.0)


## Height of the body: rises on takeoff, full in the orbit and the flight,
## sinks on landing.
func body_lift(u: SummonedUnit) -> float:
	var h := float(u.special.get("slam_lift", 0.0))
	match phase:
		TAKEOFF:
			return h * clampf(phase_time / maxf(float(u.special["slam_takeoff"]), 0.01), 0.0, 1.0)
		ORBIT, FLIGHT:
			return h
		LAND:
			return h * (1.0 - clampf(phase_time / maxf(float(u.special["slam_land"]), 0.01), 0.0, 1.0))
	return 0.0


## Ground shadow while airborne and the slam marker in flight (textures).
func draw_under(u: SummonedUnit) -> void:
	if not u.airborne:
		return
	var k := body_lift(u) / maxf(float(u.special["slam_lift"]), 1.0)
	var r := u.radius * (1.1 - 0.3 * k)
	u.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, u.radius * 0.8 - r * 0.45), Vector2(r * 2.0, r * 0.9)), false, Color(0, 0, 0, 0.45 - 0.15 * k))
	if phase == FLIGHT:
		world_space(u)
		var at := slam_point - u.position
		var rr := float(u.special["slam_radius"])
		if not AoeArt.telegraph(u, "mark_violet", at, rr, 0.0, Palette.NECRO_GREEN):
			u.draw_texture_rect(SpriteBank.disc(), Rect2(at - Vector2(rr, rr), Vector2(rr, rr) * 2.0), false, Color(Palette.NECRO_GREEN, 0.12))
		body_space(u)


## Passive id of Origin Story (PassiveData, UnlockData; read by
## HordeDirector._special_stats()).
const ORIGIN: String = "origin_story"
## Its level-row key: extra share (0..) of every class special's reach (its
## *_radius / *_length keys).
const ORIGIN_KEY: String = "special_reach"
