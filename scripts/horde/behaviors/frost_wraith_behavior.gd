## FrostWraithBehavior — the Frost Wraith's attacks ("frost", UnitData).
##   * Frost bolts: the class's attack_profile "frost" is released here as a
##     Projectile.Kind.FROST_BOLT carrying a chill; on hit ProjectileManager
##     calls CombatResolver.chill_enemy() (a slow of chill_slow for
##     chill_duration s, drawn as a frost tint on the enemy).
##   * Deep Freeze: think() starts it when the freeze is ready, the target is
##     in bolt range, not frozen already, not a Reckoning enemy, and it either
##     stands in a cluster (freeze_min_enemies), is an elite / the boss, or is
##     next to a necromancer who is in danger (UnitData.DANGER_RADIUS and
##     HordeDirector.player_in_danger). A cold-blue circle is
##     telegraphed on the target's spot for freeze_windup s (CASTING), then
##     every enemy inside freeze_radius is frozen for freeze_duration s through
##     CombatResolver.freeze_enemy(): the Stasis freeze path (EnemyDirector
##     skips its AI, attacks and movement, its telegraphs pause, it shows the
##     frost shell). Sir Alaric gets freeze_boss_mult of the duration, elites
##     freeze_elite_mult, Reckoning enemies are immune.
##   * Target preference: enemies closing on the player ("frost" weights),
##     unchilled ones first (score_bonus()), so the slow spreads.
## Stats: frost_deep_freezes, frost_freezes (enemies frozen), frost_chills,
## frost_frozen_seconds (Enemy.step_frozen()), dmg_frost_wraith.
class_name FrostWraithBehavior
extends SummonBehavior

## Phase: the Deep Freeze circle is telegraphed.
const CAST: int = 1

## World point the current Deep Freeze is centred on (locked at cast start).
var freeze_point: Vector2 = Vector2.ZERO
## Reusable enemy query buffer.
var _buf: Array = []


## Full Deep Freeze cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("freeze_cooldown", 9.0))


## Starts a Deep Freeze on the current target when it is worth it.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0 or not u.target_alive():
		return false
	var t := u.target
	if t.is_reckoning or t.is_structure or t.freeze_timer > 0.0 or t.frozen:
		return false
	if u.position.distance_to(t.position) > u.attack_range + t.radius:
		return false
	var near_player := t.position.distance_to(u.game.player.position) <= UnitData.DANGER_RADIUS  # Target is on the necromancer.
	var worth := t.is_elite or t.is_boss or (near_player and u.director.player_in_danger)
	if not worth:
		worth = count_enemies(u.game, t.position, float(u.special["freeze_radius"]), _buf) >= int(u.special["freeze_min_enemies"])
	if not worth:
		return false
	freeze_point = t.position
	begin_special(u, CAST)
	return true


## Windup, then the freeze.
func step_special(u: SummonedUnit, _delta: float) -> bool:
	u.velocity = Vector2.ZERO
	if phase_time >= float(u.special["freeze_windup"]):
		_release_freeze(u)
		end_special(u, SummonedUnit.State.ENGAGING if u.target_alive() else SummonedUnit.State.FOLLOWING)
	return true


## Freezes every enemy inside the circle (CombatResolver.freeze_enemy()).
func _release_freeze(u: SummonedUnit) -> void:
	var game := u.game
	var r := float(u.special["freeze_radius"])  # Freeze radius (px).
	var dur := float(u.special["freeze_duration"])  # Full freeze time (s).
	game.enemy_grid.query(freeze_point, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	for e: Enemy in _buf:
		if e.active and e.position.distance_to(freeze_point) <= r + e.radius * 0.5:
			game.combat.freeze_enemy(e, dur, float(u.special["freeze_boss_mult"]), float(u.special["freeze_elite_mult"]))
	game.effects.ring(freeze_point, r, Palette.COLD_BLUE, 0.4)
	game.effects.ring(freeze_point, r * 0.6, PowerupGlyphs.ICE, 0.5)
	Juice.fx.burst(freeze_point, PowerupGlyphs.ICE, Palette.COLD_BLUE, 12, r * 1.6, 0.6, 2.5)
	Sfx.play("deep_freeze", freeze_point)
	game.stat_add("frost_deep_freezes", 1.0)


## "frost" attack profile: a chilling frost bolt at the target.
func release_attack(u: SummonedUnit) -> void:
	if not u.target_alive():
		return
	var p := u.game.projectiles.fire_friendly(Projectile.Kind.FROST_BOLT, u.position, u.target, u.damage, u.projectile_speed, 0, u.unit_class)
	if p != null:
		p.chill_slow = float(u.special["chill_slow"])
		p.chill_time = float(u.special["chill_duration"])
	Sfx.play("frost_bolt", u.position)


## Unchilled enemies first, so the slow spreads over the crowd.
func score_bonus(u: SummonedUnit, e: Enemy, _dp: float) -> float:
	return float(u.special["unchilled_bonus"]) if e.chill_timer <= 0.0 else 0.0


## Deep Freeze telegraph: a cold-blue circle filling in on the target spot.
func draw_under(u: SummonedUnit) -> void:
	if phase != CAST:
		return
	world_space(u)
	var at := freeze_point - u.position  # Circle centre in world-aligned local space.
	var r := float(u.special["freeze_radius"])  # Freeze radius (px).
	var k := clampf(phase_time / maxf(float(u.special["freeze_windup"]), 0.01), 0.0, 1.0)  # Windup progress.
	u.draw_circle(at, r, Color(Palette.COLD_BLUE, 0.10))
	u.draw_circle(at, r * k, Color(PowerupGlyphs.ICE, 0.18))
	u.draw_arc(at, r, 0.0, TAU, 36, Color(PowerupGlyphs.ICE, 0.8), 1.5)
	u.draw_line(Vector2.ZERO, at, Color(Palette.COLD_BLUE, 0.35), 1.5)
	body_space(u)
