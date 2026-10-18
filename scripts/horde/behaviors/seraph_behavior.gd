## SeraphBehavior — the Fallen Seraph's attacks ("dive", UnitData; Act II,
## GDD §15.0 "Fallen Seraph"). She is granted by slaying Grand Inquisitor
## Seraphine (UnlockData), so nothing here ever runs on a save that never
## slew her.
##   * Feather blades: the class's attack_profile "feather" is released here
##     as one black feather blade at the target (Projectile.Kind.ARROW, no
##     pierce, source = the unit's dmg_source: "fallen_seraph" /
##     "ruin_seraph"); her bullet-heaven volley is a fan of more blades
##     (VolleyData, attack-triggered).
##   * Hovering: the body is drawn FLOAT_LIFT px above a ground shadow (higher
##     during the dive, dive_lift). She is NOT airborne: enemies target, hit
##     and body-check her the whole time, the dive included (unlike the
##     Gargoyle's swoop), and the Arena push-out keeps her out of obstacles.
##   * Dive: think() searches the densest pack when the dive is ready: the
##     first dive_candidates living enemies (spatial-hash order, so
##     deterministic) within dive_range_min..dive_range_max px of her, inside
##     her engagement leash, not structures or Reckoning enemies; each is
##     scored by the enemies within dive_radius of it (count_enemies()), an
##     elite / miniboss / the boss counting as a full pack. The best one
##     (ties: the first) must reach dive_min_enemies; with none she waits
##     dive_retry s before searching again. Then (CASTING, phases below)
##       RISE     dive_rise s rising in place to dive_lift px,
##       DIVE     she flies at the pack centre (fixed at the search, so the
##                dive reads as a committed strike) at dive_speed, for at
##                most dive_max_flight s (it lands wherever she is by then),
##       impact   dive_damage to every enemy within dive_radius (source
##                "seraph_dive", CombatResolver.damage_enemy()) with a small
##                knockback, and a feather ring is laid at the impact
##                (SeraphFeathers.add_ring(): it expands from ring_start x
##                ring_radius to ring_radius in ring_time s and cuts every
##                enemy it passes once for feather_damage, source
##                "seraph_feathers"),
##       RECOVER  dive_recover s hovering over the impact, then she rejoins
##                the shared FSM (ENGAGING / FOLLOWING), which flies her back
##                to her ring post: the feathers cut on her way out.
##     Leash and recall stay in charge (SummonBehavior.physics(): a recall
##     cancels the dive at once; nothing is left to clean up but the ring,
##     which lives on its own in SeraphFeathers).
## Seraph of Ruin (summon evolution; keys from SummonEvolutionData
## "special_set", absent / 0 on the base Seraph, which keeps exactly the
## behaviour above):
##   * chain_dives: after the RECOVER of a dive she dives again at once (no
##     rise) onto the densest pack within chain_range px of the impact that
##     passes the same checks (another centre than the last one); special_time
##     restarts with each chained dive (each dive is bounded on its own, so
##     the autotest overtime check still holds),
##   * rings: every impact lays `rings` feather rings, ring i starting
##     i x ring_delay s later and reaching ring_radius x (1 + i x ring_growth).
## Stats: seraph_dives, seraph_dive_hits, seraph_chain_dives,
## seraph_no_pack (searches that found no pack), seraph_rings /
## seraph_feather_hits (SeraphFeathers), dmg_seraph_dive / dmg_seraph_feathers
## (CombatResolver).
## Determinism (CLAUDE.md): no RNG at all; spatial-hash order and positions.
class_name SeraphBehavior
extends SummonBehavior

## Phase: rising in place before the dive.
const RISE: int = 1
## Phase: diving at the pack.
const DIVE: int = 2
## Phase: hovering over the impact.
const RECOVER: int = 3
## px the hovering body is drawn above its shadow outside the dive.
const FLOAT_LIFT: float = 6.0
## Damage-source tag of the dive impact.
const SRC_DIVE: String = "seraph_dive"
## Damage-source tag of the feather ring.
const SRC_FEATHERS: String = "seraph_feathers"

## World point the running dive is aimed at (the pack centre).
var dive_point: Vector2 = Vector2.ZERO
## World point the dive started from (drawing the dive streak).
var _dive_from: Vector2 = Vector2.ZERO
## Height (px) the body is drawn above the ground at the start of the dive.
var _lift_at_dive: float = 0.0
## Chained dives left in the running special (Seraph of Ruin).
var _chain_left: int = 0
## Reusable enemy query buffer (pack search).
var _buf: Array = []
## Reusable enemy query buffer (pack counting).
var _cnt: Array = []


## Full dive cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("dive_cooldown", 7.0))


## Starts a dive on the densest pack in reach when the dive is ready.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0:
		return false
	var s := u.special  # Special numbers.
	var best := find_pack(u, u.position, float(s["dive_range_min"]), float(s["dive_range_max"]), Vector2.INF)
	if best == Vector2.INF:
		special_cd = float(s.get("dive_retry", 0.6))  # Nothing worth a dive: look again a little later.
		u.game.stat_add("seraph_no_pack", 1.0)
		return false
	dive_point = best
	_chain_left = int(s.get("chain_dives", 0))
	begin_special(u, RISE)
	Sfx.play("gargoyle_takeoff", u.position, 1.18)
	return true


## The densest pack centre within `r_min`..`r_max` px of `from` (and inside
## the unit's engagement leash), or Vector2.INF when none reaches
## dive_min_enemies. A candidate at `exclude` (the last dive's centre) is
## skipped. Elites, minibosses and the boss count as a full pack.
func find_pack(u: SummonedUnit, from: Vector2, r_min: float, r_max: float, exclude: Vector2) -> Vector2:
	var s := u.special  # Special numbers.
	var need := int(s["dive_min_enemies"])  # Pack size worth a dive.
	var r := float(s["dive_radius"])  # Impact radius (px).
	var cap := int(s.get("dive_candidates", 10))  # Candidates compared.
	var player_pos := u.game.player.position
	u.game.enemy_grid.query(from, r_max, _buf)
	var best := Vector2.INF  # Best centre so far.
	var best_n := 0  # Its pack size.
	var seen := 0  # Candidates compared.
	for e: Enemy in _buf:
		if seen >= cap:
			break
		if not e.active or e.is_structure or e.is_reckoning:
			continue
		var d := e.position.distance_to(from)  # Distance from the search point (px).
		if d < r_min or d > r_max or e.position.distance_to(player_pos) > u.engage_radius:
			continue
		if exclude != Vector2.INF and e.position.distance_to(exclude) < r * 0.5:
			continue  # Too close to the pack just struck (a chained dive moves on).
		seen += 1
		var n := count_enemies(u.game, e.position, r, _cnt)  # Pack around this candidate.
		if e.is_elite or e.is_boss or e.is_miniboss:
			n = maxi(n, need)
		if n > best_n:
			best_n = n
			best = e.position
	return best if best_n >= need else Vector2.INF


## Rise -> dive -> impact -> recover (-> chained dives).
func step_special(u: SummonedUnit, delta: float) -> bool:
	var s := u.special  # Special numbers.
	match phase:
		RISE:
			u.velocity = Vector2.ZERO
			if phase_time >= float(s["dive_rise"]):
				_start_dive(u)
		DIVE:
			var to := dive_point - u.position  # Remaining dive vector.
			var step_len := float(s["dive_speed"]) * delta  # px this tick.
			if to.length() <= step_len or phase_time >= float(s["dive_max_flight"]):
				var hit := dive_point if to.length() <= step_len else u.position  # Impact point.
				u.position = hit
				u.velocity = Vector2.ZERO
				_impact(u, hit)
				next_phase(RECOVER)
			else:
				u.velocity = to / to.length() * float(s["dive_speed"])
		RECOVER:
			u.velocity = Vector2.ZERO
			if phase_time >= float(s["dive_recover"]):
				if _chain_left > 0 and _try_chain(u):
					return true
				end_special(u, SummonedUnit.State.ENGAGING if u.target_alive() else SummonedUnit.State.FOLLOWING)
	return true


## Begins the dive phase toward dive_point.
func _start_dive(u: SummonedUnit) -> void:
	_dive_from = u.position
	_lift_at_dive = body_lift(u)
	next_phase(DIVE)
	u.game.stat_add("seraph_dives", 1.0)


## Seraph of Ruin: dives again at once onto the next pack near the impact.
## False when there is none (the special then ends).
func _try_chain(u: SummonedUnit) -> bool:
	_chain_left -= 1
	var s := u.special  # Special numbers.
	var next := find_pack(u, u.position, 0.0, float(s.get("chain_range", 0.0)), dive_point)
	if next == Vector2.INF:
		return false
	dive_point = next
	special_time = 0.0  # Each chained dive is bounded on its own (see the header).
	_start_dive(u)
	u.game.stat_add("seraph_chain_dives", 1.0)
	Sfx.play("gargoyle_takeoff", u.position, 1.3)
	return true


## The dive lands at `pos`: impact damage and knockback, the feather ring(s),
## effects and the evolution's showpiece volley.
func _impact(u: SummonedUnit, pos: Vector2) -> void:
	var game := u.game
	var s := u.special  # Special numbers.
	u.motion_lunge(Vector2.ZERO, MotionData.POWER_MELEE)  # Engine motion: the strike (visual only).
	var r := float(s["dive_radius"])  # Impact radius (px).
	var kb := float(s["dive_knockback"])  # Knockback impulse (px/s).
	game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var hits := 0  # Enemies struck.
	for e: Enemy in _buf:
		if not e.active or e.position.distance_to(pos) > r + e.radius:
			continue
		if not e.is_structure:
			var away := e.position - pos  # Push direction.
			e.knockback += (away / away.length() if away.length() > 0.01 else Vector2.UP) * kb / maxf(e.mass, 0.1)
		hits += 1
		game.combat.damage_enemy(e, float(s["dive_damage"]), SRC_DIVE)
	game.stat_add("seraph_dive_hits", float(hits))
	# The feather ring(s): ring i starts i x ring_delay s later and reaches further.
	var rings := maxi(1, int(s.get("rings", 1)))  # Rings laid by this impact.
	var feathers := u.director.seraph_feathers()  # The pooled feather rings.
	for i in rings:
		var reach := float(s["ring_radius"]) * (1.0 + float(s.get("ring_growth", 0.0)) * float(i))  # This ring's radius (px).
		feathers.add_ring(pos, reach, float(s["ring_start"]), float(s["ring_time"]),
				float(s.get("ring_delay", 0.0)) * float(i), float(s["feather_damage"]), int(s["ring_feathers"]), SRC_FEATHERS)
	game.effects.ring(pos, r, SeraphGlyphs.ASH, 0.3)
	game.effects.burst(pos, r, "seraph_dive")  # Impact strip (art only; nothing without the PNG).
	Juice.fx.burst(pos, SeraphGlyphs.ASH, SeraphGlyphs.SOUL_DIM, 10, r * 2.2, 0.45, 2.5)
	game.shake(float(s["dive_shake"]))
	Sfx.play("gargoyle_dive", pos, 1.12)
	game.volleys.on_special(u, pos, pos + Vector2.RIGHT, float(s["dive_damage"]))  # Seraph of Ruin showpiece (the class volley is attack-triggered).


## "feather" attack profile: one black feather blade at the target.
func release_attack(u: SummonedUnit) -> void:
	if not u.target_alive():
		return
	u.game.projectiles.fire_friendly(Projectile.Kind.ARROW, u.position + Vector2(0, -FLOAT_LIFT), u.target, u.damage,
			u.projectile_speed, 0, u.dmg_source)


## Height of the body: hovering, risen during the rise, sinking through the
## dive onto the pack, low over the impact.
func body_lift(u: SummonedUnit) -> float:
	var h := float(u.special.get("dive_lift", FLOAT_LIFT))  # Top of the rise (px).
	match phase:
		RISE:
			return lerpf(FLOAT_LIFT, h, clampf(phase_time / maxf(float(u.special["dive_rise"]), 0.01), 0.0, 1.0))
		DIVE:
			var total := maxf(_dive_from.distance_to(dive_point), 1.0)  # Dive length (px).
			var k := clampf(u.position.distance_to(_dive_from) / total, 0.0, 1.0)  # Dive progress.
			return lerpf(_lift_at_dive, 1.0, k)
		RECOVER:
			return lerpf(1.0, FLOAT_LIFT, clampf(phase_time / maxf(float(u.special["dive_recover"]), 0.01), 0.0, 1.0))
	return FLOAT_LIFT


## Ground shadow (she hovers) and the dive marker on the pack while she
## rises and dives.
func draw_under(u: SummonedUnit) -> void:
	var k := clampf(body_lift(u) / maxf(float(u.special.get("dive_lift", FLOAT_LIFT)), 1.0), 0.0, 1.0)  # 0..1 height.
	u.draw_set_transform(Vector2(0, u.radius * 0.95), 0.0, Vector2(1.0, 0.4))
	u.draw_circle(Vector2.ZERO, u.radius * (0.95 - 0.25 * k), Color(0, 0, 0, 0.32 - 0.1 * k))
	body_space(u)
	if phase != RISE and phase != DIVE:
		return
	world_space(u)
	var at := dive_point - u.position  # Pack centre in world-aligned local space.
	SeraphGlyphs.draw_dive_mark(u, at, float(u.special["dive_radius"]), phase_time)
	body_space(u)
