## CyclopsKit — the kit of the Cyclops (IlionEnemyData "cyclops"; Act IV, the
## Shores of Ilion, GDD §15.0 "The Shores of Ilion (Act IV phase 2)";
## owner-approved proposal: "Throws boulders with a landing circle; flat
## armour"), and the base of Polyphemus's (PolyphemusKit). The shared melee AI
## walks it at the necromancer (enemies always advance) and its fists strike in
## reach; on its own rhythm it THROWS:
##   * within throw_min..throw_range px of the necromancer and off cooldown it
##     stands throw_windup s with the boulder raised (the engine motion's cast
##     pose), then hurls `boulders` boulders (boulders_now(): Polyphemus's rage
##     adds more): the first lands on the necromancer's position led by
##     boulder_lead of the flight on his movement, the others boulder_spread px
##     around it (fixed angles, no RNG). Each landing point shows a red
##     telegraph circle of boulder_radius px for the whole flight
##     (boulder_flight s); then the boulder lands: the necromancer inside takes
##     boulder_damage_player, each summon inside boulder_damage_summon (x the
##     time scaling). Boulders in flight are this kit's own (drawn arcing over
##     the field); while the thrower is frozen or stunned they hang with it,
##     and they crumble if it dies first (the telegraph goes with it).
## FLAT ARMOUR is the row's "flat_armor" (Enemy.flat_armor, CombatResolver).
## Determinism: no RNG. Stats: cyclops_throws, cyclops_boulders,
## cyclops_boulder_hits_summon, cyclops_boulder_hits_player (Polyphemus's own
## counters through stat_prefix()).
class_name CyclopsKit
extends PantheonKit

## Phase: the boulder raised before the throw.
const THROW_WINDUP: int = 1
## Phase: standing after a throw.
const RECOVER: int = 2
## Height (px) the drawn boulder's arc rises at its top (visual only).
const ARC_HEIGHT: float = 70.0  # TUNING (not in GDD)

## Seconds until the next throw may start.
var throw_cd: float = 0.0
## Landing points of the boulders in flight (world px; empty = none).
var _landing: PackedVector2Array = PackedVector2Array()
## Where the boulders in flight left the hand (world px).
var _from: Vector2 = Vector2.ZERO
## Seconds the boulders in flight have flown.
var _flown: float = 0.0
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	throw_cd = CovenantKit.first_cd(e, float(d["first_throw"]))
	_landing.clear()
	_flown = 0.0


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	_landing.clear()  # The boulders in flight crumble with their thrower.


## Prefix of this kit's stat names ("cyclops"; Polyphemus has his own).
func stat_prefix() -> String:
	return "cyclops"


## Damage source tag of this kit's boulders.
func boulder_source() -> String:
	return IlionEnemyData.BOULDER_SOURCE


## Boulders per throw now (Polyphemus's rage throws more).
func boulders_now() -> int:
	return int(d["boulders"])


## Seconds between two throws now (Polyphemus's rage throws faster).
func throw_cooldown_now() -> float:
	return float(d["throw_cooldown"])


## The boulders in flight, the throw's windup and recovery (see the header).
## Returns true while a throw holds the cyclops still.
func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	_step_boulders(e, delta)
	throw_cd -= delta
	if phase == IDLE:
		if throw_cd <= 0.0 and _landing.is_empty():
			var dist := e.position.distance_to(e.game.player.position)  # To the necromancer (px).
			if dist <= float(d["throw_range"]) and dist >= float(d["throw_min"]):
				throw_cd = throw_cooldown_now()
				e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)  # The boulder raised (visual only).
				set_phase(e, THROW_WINDUP)
		return false
	phase_time += delta
	hold(e)
	match phase:
		THROW_WINDUP:
			if phase_time >= float(d["throw_windup"]):
				_throw(e)
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= float(d["recover_time"]):
				set_phase(e, IDLE)
	return true


## Hurls the boulders (see the header): landing points and their telegraphs.
func _throw(e: Enemy) -> void:
	var g := e.game
	var p := g.player
	var flight := float(d["boulder_flight"])  # s.
	var aim := p.position + p.velocity * flight * float(d["boulder_lead"])  # Led aim point.
	var n := boulders_now()
	var spread := float(d["boulder_spread"])  # px.
	var base := (aim - e.position).angle()  # Ring offset of the extra boulders (rad).
	_landing.clear()
	_landing.append(aim)
	for i in n - 1:
		_landing.append(aim + Vector2.from_angle(base + TAU * float(i) / float(maxi(1, n - 1))) * spread)
	for q in _landing:
		g.effects.telegraph_circle(q, float(d["boulder_radius"]), flight, e)
	_from = e.position + Vector2(0.0, -e.radius * 2.0)
	_flown = 0.0
	g.stat_add(stat_prefix() + "_throws", 1.0)
	g.stat_add(stat_prefix() + "_boulders", float(n))
	if g.pantheon != null:
		g.pantheon.play_sound("boulder_throw", e.position)
	e.motion_lunge(aim - e.position, MotionData.POWER_SHOT)


## Flies the boulders; when their flight ends they land.
func _step_boulders(e: Enemy, delta: float) -> void:
	if _landing.is_empty():
		return
	_flown += delta
	e.queue_redraw()  # The arcing boulders (visual only).
	if _flown < float(d["boulder_flight"]):
		return
	var g := e.game
	var r := float(d["boulder_radius"])  # px.
	var mult := CovenantKit.hit_scale(e)  # Time scaling x buffs.
	var src := boulder_source()
	var hits_u := 0
	var hits_p := 0
	for q in _landing:
		g.effects.impact(q, r, Palette.PANTHEON_MARBLE_DARK)
		g.ally_grid.query(q, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
		for u: SummonedUnit in _tmp:
			if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(q) <= r + u.radius:
				g.combat.damage_unit(u, float(d["boulder_damage_summon"]) * mult, src, e)
				hits_u += 1
		for pl in g.all_players:  # (Co-op: every necromancer under it.)
			if pl.position.distance_to(q) <= r + pl.radius:
				g.combat.damage_player(float(d["boulder_damage_player"]) * mult, src, pl)
				hits_p += 1
	g.stat_add(stat_prefix() + "_boulder_hits_summon", float(hits_u))
	g.stat_add(stat_prefix() + "_boulder_hits_player", float(hits_p))
	if g.pantheon != null:
		g.pantheon.play_sound("boulder_land", _landing[0])
	g.shake(3.0 + 1.5 * float(_landing.size()))
	_landing.clear()
	e.queue_redraw()


## True while a throw holds it (the autotest's stuck check skips it).
func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the nearest landing circle.
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	var reach := float(d["boulder_radius"]) + 26.0  # px.
	for q in _landing:
		var away := p - q
		if away.length() < reach:
			return away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	return Vector2.ZERO


## The boulders in flight, arcing from the hand to their landing points (drawn
## in world-axis offsets from the thrower), and the boulder held up during the
## windup. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if _landing.is_empty() and phase != THROW_WINDUP:
		return
	CovenantKit.unmirror(e, ci)
	var br := maxf(5.0, float(d["boulder_radius"]) * 0.2)  # Drawn boulder radius (px).
	if phase == THROW_WINDUP:
		IlionGlyphs.draw_boulder(ci, Vector2(0.0, -e.radius * 2.6), br)
	var k := clampf(_flown / maxf(0.01, float(d["boulder_flight"])), 0.0, 1.0)  # 0 -> 1 through the flight.
	for q in _landing:
		var at := _from.lerp(q, k) + Vector2(0.0, -4.0 * k * (1.0 - k) * ARC_HEIGHT)
		IlionGlyphs.draw_boulder(ci, at - e.position, br)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
