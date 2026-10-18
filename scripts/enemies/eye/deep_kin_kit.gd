## DeepKinKit — the Deep Kin's leap (Act II, Gullhaven Harbour; HarbourEnemyData
## "deep_kin", GDD §15.0 "Gullhaven Harbour (Act II phase 2)"; owner-approved
## roster "a telegraphed leap onto the front rank; full speed in water"). Its
## body is the shared "melee" AI: it always advances on its target (the
## necromancer, or a summon in its way) and claws in contact. On top of that:
##   * Leap: when the cooldown is up and a summon of the front rank (the
##     nearest summon leap_range_min..leap_range_max px away), or else the
##     necromancer, is in reach, it crouches: a circle of leap_radius px is
##     telegraphed on that spot for leap_telegraph s (locked there), then it
##     jumps (leap_air_time s, flying straight over the line) and lands on it:
##     summons inside take leap_damage_summon and are thrown leap_knockback px
##     out of the circle; the necromancer inside takes leap_damage_player (both
##     time-scaled, through CombatResolver, source "deep_kin_leap"). It crouches
##     leap_recover s, then walks on.
##   * Swimming: the TideDirector never slows it in water (HarbourStage.TIDE
##     "swimmers"); nothing here.
## Determinism (CLAUDE.md): no RNG; the first leap is staggered by the think
## slot (first_cd()). Stats: deep_kin_leaps, deep_kin_leap_summon_hits,
## deep_kin_leap_player_hits.
class_name DeepKinKit
extends CovenantKit

## Phase: the landing circle is telegraphed (crouching).
const WINDUP: int = 1
## Phase: in the air.
const AIR: int = 2
## Phase: crouched after landing.
const RECOVER: int = 3
## Damage source tag of the landing (an area hit for Unholy Resilience).
const SOURCE: String = "deep_kin_leap"

## Seconds until the next leap may start (counts down while walking).
var cd: float = 0.0
## Take-off point (world px).
var from: Vector2 = Vector2.ZERO
## Landing point (world px, locked at the windup).
var to: Vector2 = Vector2.ZERO
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d["leap_first"]))


## Starts a leap at the front rank when ready.
func think(e: Enemy) -> void:
	if phase != IDLE or cd > 0.0:
		return
	var spot := _landing_spot(e)
	if spot == Vector2.INF:
		return
	to = spot
	e.game.effects.telegraph_circle(to, float(d["leap_radius"]), float(d["leap_telegraph"]), e)
	e.game.stat_add("deep_kin_leaps", 1.0)
	set_phase(e, WINDUP)


## The front rank's spot: the nearest summon within the leap's reach, else the
## necromancer when he is in reach (Vector2.INF when nothing is).
func _landing_spot(e: Enemy) -> Vector2:
	var lo := float(d["leap_range_min"])
	var hi := float(d["leap_range_max"])
	var best := Vector2.INF
	var best_d := INF
	e.game.ally_grid.query(e.position, hi, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		var dist := e.position.distance_to(u.position)
		if dist >= lo and dist <= hi and dist < best_d:
			best_d = dist
			best = u.position
	if best == Vector2.INF:
		var dp := e.position.distance_to(e.game.player.position)
		if dp >= lo and dp <= hi:
			best = e.game.player.position
	return best


func physics(e: Enemy, delta: float) -> bool:
	if phase == IDLE:
		cd -= delta
		return false
	phase_time += delta
	match phase:
		WINDUP:
			hold(e)
			if phase_time >= float(d["leap_telegraph"]):
				from = e.position
				e.motion_lunge(to - from, MotionData.POWER_MELEE)  # Engine motion: the spring (visual only).
				set_phase(e, AIR)
		AIR:
			var air := maxf(0.05, float(d["leap_air_time"]))
			var k := clampf(phase_time / air, 0.0, 1.0)
			e.velocity = (to - from) / air
			e.position = from.lerp(to, k)
			if k >= 1.0:
				_land(e)
				set_phase(e, RECOVER)
		RECOVER:
			hold(e)
			if phase_time >= float(d["leap_recover"]):
				cd = float(d["leap_cooldown"])
				set_phase(e, IDLE)
	return true


## The landing: summons inside are hurt and thrown out; the necromancer is hit.
func _land(e: Enemy) -> void:
	var g := e.game
	var r := float(d["leap_radius"])
	var mult := hit_scale(e)  # Time scaling x aura buff x Dirge.
	g.effects.impact(to, r, Palette.EYE_DROWNED, "tide_splash")
	Sfx.play("abom_stomp", to, 1.2)
	var hits := 0  # Summons inside the circle.
	g.ally_grid.query(to, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(to) > r + u.radius:
			continue
		hits += 1
		var away := u.position - to  # Throw direction.
		u.position += (away.normalized() if away.length() > 0.5 else Vector2.UP) * float(d["leap_knockback"])
		g.combat.damage_unit(u, float(d["leap_damage_summon"]) * mult, SOURCE)
	g.stat_add("deep_kin_leap_summon_hits", float(hits))
	var p := g.player
	if p.position.distance_to(to) <= r + p.radius:
		g.stat_add("deep_kin_leap_player_hits", 1.0)
		g.combat.damage_player(float(d["leap_damage_player"]) * mult, SOURCE)


## True while crouching or in the air (the stuck check skips it).
func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the landing circle.
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP and phase != AIR:
		return Vector2.ZERO
	var diff := p - to
	if diff.length() < float(d["leap_radius"]) + 30.0:
		return diff.normalized() if diff.length() > 0.1 else Vector2.RIGHT
	return Vector2.ZERO
