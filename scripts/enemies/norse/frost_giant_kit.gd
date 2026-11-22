## FrostGiantKit — the kit of the Frost Giant (NorseEnemyData "frost_giant";
## the Hall of the Slain, temporarily Act XI; GDD §15.0 "The Hall of the Slain
## foundation (phase 1)"; owner-approved proposal: "Frost Giant (male) | Heavy
## | Throws boulders on a landing circle; a stomp | Siegecraft, Wither"), also
## the base of the Fire-Giant (FireGiantKit: the stomp only). Two specials:
##   * THE BOULDER (a row with boulder_every): every boulder_every s, when its
##     target is between boulder_range_min and boulder_range_max px away, it
##     heaves a boulder at the target's spot: a telegraph circle of
##     boulder_radius px (the shared one, which the autotest bot steps out of)
##     for boulder_flight s, then the boulder lands: every summon and
##     necromancer inside takes boulder_damage (BOULDER_SOURCE; x
##     undead_damage_mult on a summon). It keeps walking while it flies (an
##     arcing throw: the ring cannot block it).
##   * THE STOMP (a row with stomp_every): every stomp_every s, when a summon or
##     a necromancer is within stomp_radius px, it rears up for stomp_windup s
##     (standing, a telegraph circle), then stamps: every body inside takes
##     stomp_damage (STOMP_SOURCE) and the summons are thrown stomp_push px
##     back.
## A giant whose row "douses" (the frost giant) first turns aside to a lit
## brazier near it and stamps it out (NorseKit.douse_step(), the Long Winter).
## A giant dying with a boulder in the air takes it with him (the telegraph is
## his). No RNG. Stats: giant_boulders, giant_boulder_hits, giant_stomps,
## giant_stomp_hits.
class_name FrostGiantKit
extends NorseKit

## Phase: rearing up for the stomp (the windup).
const STOMP: int = 1

## Seconds until the next boulder may be thrown.
var _boulder_cd: float = 0.0
## Seconds until the next stomp may start.
var _stomp_cd: float = 0.0
## Where the boulder in the air lands (world px).
var _land_at: Vector2 = Vector2.ZERO
## Game time (s) it lands (INF = none in the air).
var _land_t: float = INF
## Scratch for the grid queries.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_boulder_cd = first_cd(e, float(def.get("boulder_every", 0.0)) * 0.5)
	_stomp_cd = first_cd(e, float(def.get("stomp_every", 0.0)) * 0.5)
	_land_t = INF


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	_land_t = INF


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var g := e.game
	_boulder_cd -= delta
	_stomp_cd -= delta
	if g.elapsed >= _land_t:
		_land_t = INF
		_strike(e, _land_at, float(d.get("boulder_radius", 40.0)), float(d.get("boulder_damage", 12.0)), 0.0,
				NorseRulesData.BOULDER_SOURCE, "giant_boulder_hits")
		g.effects.impact(_land_at, float(d.get("boulder_radius", 40.0)), Palette.NORSE_FROST_SHADE)
		if g.norse != null:
			g.norse.play_sound("boulder_land", _land_at, 0.4)
	if phase == STOMP:
		phase_time += delta
		hold(e)
		if phase_time >= float(d.get("stomp_windup", 0.7)):
			var r := float(d.get("stomp_radius", 60.0))
			_strike(e, e.position, r, float(d.get("stomp_damage", 9.0)), float(d.get("stomp_push", 30.0)),
					NorseRulesData.STOMP_SOURCE, "giant_stomp_hits")
			g.effects.impact(e.position, r, Palette.NORSE_FIRE if e.kind == NorseEnemyData.FIRE_GIANT else Palette.NORSE_FROST)
			g.shake(2.0)
			set_phase(e, IDLE)
		return true
	if douse_step(e, delta):
		return true  # The Long Winter: it stamps out a brazier on its way (rows with "douses").
	var t: Node2D = e.target if e.target != null and is_instance_valid(e.target) else g.player
	var dist := e.position.distance_to(t.position)
	if d.has("stomp_every") and _stomp_cd <= 0.0 and dist - body_radius(e, t) <= float(d.get("stomp_radius", 60.0)):
		_stomp_cd = float(d["stomp_every"])
		g.effects.telegraph_circle(e.position, float(d.get("stomp_radius", 60.0)), float(d.get("stomp_windup", 0.7)), e)
		g.stat_add("giant_stomps", 1.0)
		set_phase(e, STOMP)
		hold(e)
		return true
	if d.has("boulder_every") and _boulder_cd <= 0.0 and _land_t == INF \
			and dist >= float(d.get("boulder_range_min", 90.0)) and dist <= float(d.get("boulder_range_max", 340.0)):
		if t == g.player and g.ultimates.player_untargetable():
			return false
		_boulder_cd = float(d["boulder_every"])
		_land_at = t.position
		var flight := float(d.get("boulder_flight", 1.2))
		_land_t = g.elapsed + flight
		g.effects.telegraph_circle(_land_at, float(d.get("boulder_radius", 40.0)), flight, e)
		e.motion_lunge((t.position - e.position).normalized(), MotionData.POWER_SHOT)
		g.stat_add("giant_boulders", 1.0)
		if g.norse != null:
			g.norse.play_sound("boulder_throw", e.position, 0.4)
	return false


## Every summon and necromancer within `r` px of `at` takes `base` damage
## (scaled), tagged `source`; the summons are thrown `push` px back; each hit
## counts in stat `stat`.
func _strike(e: Enemy, at: Vector2, r: float, base: float, push: float, source: String, stat: String) -> void:
	var g := e.game
	var dmg := base * hit_scale(e)
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(at) <= r + pl.radius:
			g.combat.damage_player(dmg, source, pl, e)
			g.stat_add(stat, 1.0)
	g.ally_grid.query(at, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING or u.airborne:
			continue
		if u.position.distance_to(at) > r + u.radius:
			continue
		g.combat.damage_unit(u, dmg * e.undead_damage_mult, source, e)
		g.stat_add(stat, 1.0)
		if push > 0.0 and u.active and u.state != SummonedUnit.State.DEAD:
			var away := (u.position - at).normalized() if u.position.distance_squared_to(at) > 1.0 else Vector2.RIGHT
			u.position += away * g.arena.clear_length(u.position, away, push, u.radius)


## Autopilot hint: out of the landing circle of the boulder in the air.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if _land_t == INF:
		return Vector2.ZERO
	var reach := float(d.get("boulder_radius", 40.0)) + 16.0
	var off := p - _land_at
	var dist := off.length()
	if dist >= reach or e.game.elapsed > _land_t:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.0
