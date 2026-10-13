## AbominationBehavior — the Corpse Abomination's Stomp ("stomp", UnitData).
## The abomination itself is an ordinary melee "guard" summon and a physical
## blocker (block_radius / block_mass, resolved by Enemy.resolve_blocking()
## like a warrior, only wider and heavier). On top of its fist slams:
##   1. think(): when the stomp is ready and stomp_min_enemies enemies stand
##      inside 85% of the ring (or any elite / the boss inside it), it plants
##      its feet (CASTING) and a bone-green ring is telegraphed around it for
##      stomp_windup s,
##   2. impact: every enemy inside stomp_radius takes stomp_damage and is
##      knocked outward (stomp_knockback / enemy mass); a shockwave, dust burst
##      and screen shake (Juice) sell the hit,
##   3. it stands still for stomp_recover s, then rejoins the shared FSM.
## Stats: abom_stomps, abom_stomp_hits, dmg_abom_stomp (via CombatResolver).
class_name AbominationBehavior
extends SummonBehavior

## Phase: the ring is telegraphed, the stomp has not landed yet.
const WINDUP: int = 1
## Phase: the stomp landed; short recovery before moving again.
const RECOVER: int = 2

## Reusable enemy query buffer.
var _buf: Array = []


## Full stomp cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("stomp_cooldown", 6.0))


## Starts a stomp when enough enemies crowd the abomination.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0:
		return false
	var r := float(u.special["stomp_radius"]) * 0.85  # Trigger radius (px).
	u.game.enemy_grid.query(u.position, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var n := 0  # Enemies inside the trigger radius.
	var heavy := false  # An elite or the boss is inside.
	for e: Enemy in _buf:
		if e.active and e.position.distance_to(u.position) <= r + e.radius * 0.5:
			n += 1
			heavy = heavy or e.is_elite or e.is_boss
	if n < int(u.special["stomp_min_enemies"]) and not heavy:
		return false
	begin_special(u, WINDUP)
	return true


## Windup -> impact -> recovery.
func step_special(u: SummonedUnit, _delta: float) -> bool:
	u.velocity = Vector2.ZERO
	match phase:
		WINDUP:
			if phase_time >= float(u.special["stomp_windup"]):
				_impact(u)
				next_phase(RECOVER)
		RECOVER:
			if phase_time >= float(u.special["stomp_recover"]):
				end_special(u, SummonedUnit.State.ENGAGING if u.target_alive() else SummonedUnit.State.FOLLOWING)
	return true


## The stomp lands: damage + knockback to everything in the ring, shockwave.
func _impact(u: SummonedUnit) -> void:
	var game := u.game
	u.motion_lunge(Vector2.ZERO, MotionData.POWER_MELEE)  # Engine motion: the stomp (visual only).
	var pos := u.position  # Stomp centre.
	var r := float(u.special["stomp_radius"])  # Stomp radius (px).
	var dmg := float(u.special["stomp_damage"])  # Damage per enemy.
	var kb := float(u.special["stomp_knockback"])  # Knockback impulse (px/s).
	game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var hits := 0  # Enemies hit.
	for e: Enemy in _buf:
		if not e.active or e.position.distance_to(pos) > r + e.radius:
			continue
		var away := e.position - pos  # Push direction.
		var dir := away / away.length() if away.length() > 0.01 else Vector2.RIGHT
		e.knockback += dir * kb / maxf(e.mass, 0.1)
		hits += 1
		game.combat.damage_enemy(e, dmg, "abom_stomp")
	game.effects.ring(pos, r, Palette.BONE, 0.35)
	game.effects.ring(pos, r * 0.6, Palette.CORPSE_FLESH, 0.3)
	Juice.fx.burst(pos, Palette.CORPSE_FLESH, Palette.BONE, 14, r * 2.0, 0.5, 3.0)
	game.shake(float(u.special["stomp_shake"]))
	Sfx.play("abom_stomp", pos)
	game.stat_add("abom_stomps", 1.0)
	game.stat_add("abom_stomp_hits", float(hits))


## Telegraph: a bone-green ring that fills in as the stomp winds up.
func draw_under(u: SummonedUnit) -> void:
	if phase != WINDUP:
		return
	var r := float(u.special["stomp_radius"])  # Stomp radius (px).
	var k := clampf(phase_time / maxf(float(u.special["stomp_windup"]), 0.01), 0.0, 1.0)  # Windup progress.
	u.draw_circle(Vector2.ZERO, r, Color(Palette.CORPSE_FLESH, 0.10))
	u.draw_circle(Vector2.ZERO, r * k, Color(Palette.CORPSE_FLESH, 0.22))
	u.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(Palette.BONE, 0.75), 2.0)
