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
## Cathedral Horror (summon evolution; keys from SummonEvolutionData
## "special_mult" / "special_set", absent / 0 on the base Gargoyle, which
## keeps exactly the behaviour above):
##   * a wider swoop (swoop_radius x special_mult),
##   * the dive stuns every enemy it hits for stun_duration s through
##     CombatResolver.stun_enemy() (the Deep Freeze hold: EnemyDirector skips
##     the enemy's AI, attacks and movement; the boss gets stun_boss_mult,
##     elites stun_elite_mult, Reckoning enemies and structures are immune),
##   * after touching down it turns to stone (phase STONE, still CASTING)
##     for stone_duration s: it stands still and does not attack, takes no
##     damage (SummonedUnit.stone_form, checked first in CombatResolver.
##     damage_unit()) and, being on the ground and in the ally grid, still
##     body-blocks enemies. special_time restarts with the stone phase (a
##     separately bounded hold, so the autotest overtime check still bounds
##     the swoop and the stone each on their own). A recall ends it at once.
## Synergies: every enemy the dive hits is marked swooped
## (SynergyManager.mark_swooped(): only while Death from Above or The Wild
## Hunt is active) before the damage lands.
## Stats: gargoyle_swoops, gargoyle_swoop_hits, dmg_gargoyle_swoop,
## summon_special_end_blocked (a landing inside an obstacle: must be 0);
## Cathedral Horror: horror_stuns, horror_boss_stuns, horror_stone_forms,
## horror_stone_seconds, horror_stone_dmg_prevented (CombatResolver),
## enemy_stunned_seconds (Enemy.step_frozen()).
class_name GargoyleBehavior
extends SummonBehavior

## Phase: rising in place (already airborne).
const TAKEOFF: int = 1
## Phase: flying to the dive point.
const FLIGHT: int = 2
## Phase: settling after the dive (still airborne).
const LAND: int = 3
## Phase: turned to stone after landing (Cathedral Horror only).
const STONE: int = 4

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
	if t.position.distance_to(u.game.player.position) > u.engage_radius:
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
				if float(u.special.get("stone_duration", 0.0)) > 0.0:
					_begin_stone(u)
				else:
					end_special(u, SummonedUnit.State.ENGAGING if u.target_alive() else SummonedUnit.State.FOLLOWING)
			else:
				u.velocity = (land_point - u.position) / maxf(left, delta)
		STONE:
			u.velocity = Vector2.ZERO
			u.game.stat_add("horror_stone_seconds", delta)
			if phase_time >= float(u.special["stone_duration"]):
				_end_stone(u)
				end_special(u, SummonedUnit.State.ENGAGING if u.target_alive() else SummonedUnit.State.FOLLOWING)
	return true


## Cathedral Horror: turns to stone where it landed (no damage taken).
func _begin_stone(u: SummonedUnit) -> void:
	next_phase(STONE)
	special_time = 0.0  # The stone hold is bounded on its own (see header).
	u.velocity = Vector2.ZERO
	u.stone_form = true
	u.self_modulate = ReaperHorrorGlyphs.STONE_TINT
	u.game.effects.ring(u.position, u.radius * 1.8, Palette.GARGOYLE_STONE, 0.35)
	u.game.stat_add("horror_stone_forms", 1.0)
	u.queue_redraw()


## Ends the stone form (flesh again, takes damage).
func _end_stone(u: SummonedUnit) -> void:
	u.stone_form = false
	u.self_modulate = Color.WHITE
	u.queue_redraw()


## The dive lands at `pos`: AoE damage, knockback, shockwave, shake.
func _impact(u: SummonedUnit, pos: Vector2) -> void:
	var game := u.game
	u.motion_lunge(Vector2.ZERO, MotionData.POWER_MELEE)  # Engine motion: the landing (visual only).
	var r := float(u.special["swoop_radius"])  # Impact radius (px).
	var kb := float(u.special["swoop_knockback"])  # Knockback impulse (px/s).
	var stun := float(u.special.get("stun_duration", 0.0))  # Cathedral Horror stun (s; 0 = none).
	game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var hits := 0  # Enemies hit.
	for e: Enemy in _buf:
		if not e.active or e.position.distance_to(pos) > r + e.radius:
			continue
		var away := e.position - pos  # Push direction.
		e.knockback += (away / away.length() if away.length() > 0.01 else Vector2.UP) * kb / maxf(e.mass, 0.1)
		hits += 1
		u.director.synergies.mark_swooped(e)  # Death from Above / The Wild Hunt (no-op without them).
		game.combat.damage_enemy(e, float(u.special["swoop_damage"]), "gargoyle_swoop")
		if stun > 0.0 and e.active:
			# Cathedral Horror: the dive stuns what it hits.
			if game.combat.stun_enemy(e, stun, float(u.special["stun_boss_mult"]), float(u.special["stun_elite_mult"])) > 0.0:
				game.stat_add("horror_stuns", 1.0)
				if e.is_boss:
					game.stat_add("horror_boss_stuns", 1.0)
	game.effects.art_ring(pos, r, Palette.VIOLET, 0.3, "dive")  # Pixel-art impact when its art exists (AoeArt).
	game.effects.art_ring_under(pos, r * 0.55, Palette.GARGOYLE_STONE, 0.35, "dive")
	if stun > 0.0:
		game.effects.art_ring(pos, r * 0.8, Palette.IVORY, 0.25, "stun")  # Stun shock ring.
	Juice.fx.burst(pos, Palette.GARGOYLE_STONE, Palette.VIOLET, 10, r * 2.0, 0.45, 2.5)
	game.shake(float(u.special["swoop_shake"]))
	Sfx.play("gargoyle_dive", pos)
	game.volleys.on_special(u, pos, pos + Vector2.RIGHT, float(u.special["swoop_damage"]))  # Bullet heaven: stone shards.
	game.stat_add("gargoyle_swoop_hits", float(hits))


## Lands for good: back on the ground, on a free point.
func _touch_down(u: SummonedUnit) -> void:
	u.position = u.game.arena.free_point(land_point, u.radius)
	u.airborne = false
	if u.game.arena.is_blocked(u.position, u.radius):
		u.game.stat_add("summon_special_end_blocked", 1.0)


## A recall interrupted the swoop: land where it is (on a free point). In
## stone form it is already on the ground: the stone just ends.
func on_cancel(u: SummonedUnit) -> void:
	if phase == STONE:
		_end_stone(u)
		return
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


## Stone form overlay over the body (cracked stone shell, violet runes); not
## needed when the unit has a stone-form still (SummonedUnit._draw_body()
## draws "summons/<kind>" + MarkerArtData.STONE_SUFFIX instead).
func draw_over(u: SummonedUnit, ci: CanvasItem) -> void:
	if phase == STONE and not SpriteBank.has(u.stone_key()):
		ReaperHorrorGlyphs.draw_stone_shell(ci, Vector2.ZERO, u.radius)


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
		if not AoeArt.telegraph(u, "mark_violet", at, r, 0.0, Palette.VIOLET):  # Pixel-art rim marks (AoeArt).
			u.draw_circle(at, r, Color(Palette.VIOLET, 0.10))
			u.draw_arc(at, r, 0.0, TAU, 32, Color(Palette.VIOLET, 0.7), 1.5)
		body_space(u)
