## BastetHunterKit — the kit of the BASTET HUNTER (female, figure style,
## cat-masked; DynastyEnemyData "bastet_hunter"; temporary Act XII, the Temple
## of the Lioness; GDD §15.0 "The Temple of the Lioness (Dynasty phase 2)";
## owner-approved proposal: "A fast duellist; vanishes into the sand and
## ambushes a ranged summon | Area damage reveals her"). An elite duellist with
## twin daggers and three moves (numbers in her row's "stalk"):
##   * IN THE SAND (her first move, and again every "vanish_every" s of the
##     duel): she sinks into the sand and runs at her PREY, the nearest RANGED
##     summon (attack range at least "ranged_reach" px: archers, mages,
##     priests, catapults) within "prey_reach" px of her, at "speed_mult" x her
##     speed, under the Bone Ring (her own steps: the ring does not block what
##     it cannot see; the arena still pushes her out of obstacles). While she
##     is in the sand she is drawn as a running ripple of sand and a hit deals
##     "hidden_taken" of itself, EXCEPT a SPELL hit (HundredShadowsData
##     .is_spell_source(): "area damage reveals her"), which lands in full and
##     throws her out of the sand into the duel. No prey: she walks in like any
##     melee kind (and dives again later).
##   * THE AMBUSH: within "strike_reach" px of her prey she bursts out of the
##     sand ("windup" s, a small telegraph circle on the prey) and strikes it
##     with both daggers ("damage", x the time scaling and her hit
##     multiplier) through CombatResolver.damage_unit(); a necromancer standing
##     in the circle takes "damage_player".
##   * THE DUEL: visible, she fights with the shared melee for "duel_time" s,
##     then vanishes again.
## Elite tier by her numbers (not always_elite). Determinism: no RNG (her first
## dive staggered by the think slot; prey by distance, then position).
## Stats: bastet_dives, bastet_ambushes, bastet_ambush_hits, bastet_reveals,
## bastet_hidden_cut.
class_name BastetHunterKit
extends DynastyKit

## Phase: in the sand, running at her prey.
const STALK: int = 1
## Phase: bursting out of the sand at her prey (its circle shows).
const AMBUSH: int = 2
## px the autotest bot keeps from her ambush circle beyond its radius.
const DANGER_REACH: float = 16.0  # TUNING (not in GDD) autotest hint only

## Her prey (a ranged summon; null = none).
var _prey: SummonedUnit = null
## Pool generation of `_prey` (stale guard).
var _prey_gen: int = 0
## Seconds left of the duel before she dives again.
var _duel_left: float = 0.0
## Seconds until she looks for prey again (in the sand without prey).
var _seek_cd: float = 0.0
## Where the ambush strikes (world px; locked at its start).
var _at: Vector2 = Vector2.ZERO
## Ally query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_prey = null
	_prey_gen = 0
	_duel_left = 0.0
	_seek_cd = first_cd(e, 0.2)
	set_phase(e, STALK)
	e.game.stat_add("bastet_dives", 1.0)


## The stalk's numbers (her row's "stalk").
func stalk() -> Dictionary:
	return d["stalk"]


## True while she is in the sand (drawn as a ripple; hits cut).
func hidden() -> bool:
	return phase == STALK


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var s := stalk()
	match phase:
		STALK:
			phase_time += delta
			_seek_cd -= delta
			if not _prey_valid() and _seek_cd <= 0.0:
				_seek_cd = 0.5
				_pick_prey(e, s)
			if not _prey_valid():
				# No prey: she walks in under the sand like any melee kind, and
				# bursts out at whatever she reaches first.
				if e._target_valid():
					var t := e.target
					if t.position.distance_to(e.position) <= float(s["strike_reach"]) + body_radius(e, t) + e.radius:
						if t is SummonedUnit:
							_prey = t as SummonedUnit
							_prey_gen = _prey.generation
						_start_ambush(e, s, t.position)
						return true
				return false
			var to := _prey.position - e.position
			var dist := to.length()
			if dist <= float(s["strike_reach"]) + _prey.radius + e.radius:
				_start_ambush(e, s, _prey.position)
				return true
			var spd := e.move_speed * float(s["speed_mult"]) * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
			e.velocity = to / dist * spd
			e.position += e.velocity * delta
			e._update_facing()
			return true
		AMBUSH:
			hold(e)
			phase_time += delta
			if phase_time >= float(s["windup"]):
				_strike(e, s)
				_duel_left = float(s["duel_time"])
				set_phase(e, IDLE)
			return true
	_duel_left -= delta
	if _duel_left <= 0.0 and s.has("vanish_every"):
		_duel_left = float(s["vanish_every"])
		_prey = null
		set_phase(e, STALK)
		e.game.stat_add("bastet_dives", 1.0)
		e.game.effects.pop(e.position, Palette.DYN_SAND, e.radius * 2.0)
	return false


## True while her prey is still a live summon of the same life.
func _prey_valid() -> bool:
	return _prey != null and _prey.active and _prey.generation == _prey_gen \
			and _prey.state != SummonedUnit.State.DEAD and not _prey.airborne


## Picks the nearest ranged summon within prey_reach px (ties by position).
func _pick_prey(e: Enemy, s: Dictionary) -> void:
	var reach := float(s["prey_reach"])
	e.game.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var best: SummonedUnit = null
	var best_d := INF
	for u: SummonedUnit in _tmp:
		if not u.active or u.charmed or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if u.attack_range < float(s["ranged_reach"]):
			continue
		var dd := u.position.distance_to(e.position)
		if dd > reach:
			continue
		if dd < best_d or (dd == best_d and best != null and (u.position.x < best.position.x or (u.position.x == best.position.x and u.position.y < best.position.y))):
			best_d = dd
			best = u
	_prey = best
	_prey_gen = best.generation if best != null else 0


## Bursts out of the sand at `at` (her prey's spot): a small circle on it.
func _start_ambush(e: Enemy, s: Dictionary, at: Vector2) -> void:
	_at = at
	set_phase(e, AMBUSH)
	hold(e)
	e.game.effects.telegraph_circle(_at, float(s["strike_radius"]), float(s["windup"]), e)
	e.game.effects.pop(e.position, Palette.DYN_SAND_LIGHT, e.radius * 2.4)
	e.motion_lunge((_at - e.position).normalized() if _at.distance_to(e.position) > 0.5 else Vector2.ZERO, MotionData.POWER_CAST)
	e.game.stat_add("bastet_ambushes", 1.0)
	if e.game.dynasty != null:
		e.game.dynasty.play_sound("bastet_ambush", e.position, 0.3)


## The twin daggers: her prey (if still in the circle) and a necromancer in it.
func _strike(e: Enemy, s: Dictionary) -> void:
	var g := e.game
	var sc := hit_scale(e)
	var r := float(s["strike_radius"])
	if _prey_valid() and _prey.position.distance_to(_at) <= r + _prey.radius:
		g.combat.damage_unit(_prey, float(s["damage"]) * sc * e.undead_damage_mult, LionessTempleEnemyData.BASTET_SOURCE, e)
		g.stat_add("bastet_ambush_hits", 1.0)
		g.effects.slash(_prey.position, _prey.position - e.position, Palette.DYN_BRONZE_LIGHT, e.radius * 1.6)
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(_at) <= r + pl.radius:
			g.combat.damage_player(float(s["damage_player"]) * sc, LionessTempleEnemyData.BASTET_SOURCE, pl, e)
	if _prey_valid():
		e._set_target(_prey)  # She duels the one she ambushed.


## In the sand a hit deals hidden_taken of itself, except a spell hit, which
## lands in full and throws her out into the duel ("area damage reveals her").
func taken_mult(e: Enemy, source: String) -> float:
	var m := super.taken_mult(e, source)
	if phase != STALK:
		return m
	var g := e.game
	if HundredShadowsData.is_spell_source(source):
		g.stat_add("bastet_reveals", 1.0)
		_duel_left = float(stalk()["duel_time"])
		_prey = null
		set_phase(e, IDLE)
		g.effects.pop(e.position, Palette.DYN_SAND_LIGHT, e.radius * 2.6)
		return m
	g.stat_add("bastet_hidden_cut", 1.0)
	return m * float(stalk()["hidden_taken"])


func is_busy() -> bool:
	return phase == AMBUSH


## Autopilot hint: out of her ambush circle while she bursts out.
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	if phase != AMBUSH:
		return Vector2.ZERO
	var reach := float(stalk()["strike_radius"]) + DANGER_REACH
	var off := p - _at
	var dist := off.length()
	if dist >= reach or dist < 0.01:
		return Vector2.ZERO
	return off / dist * (1.0 - dist / reach) * 2.0


## In the sand she draws her own body: a running ripple of sand.
func draws_body(_e: Enemy) -> bool:
	return phase == STALK


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var t := e.game.elapsed * 8.0 + float(e.think_slot)
	var a := 0.55 + 0.2 * sin(t)
	for k in 3:
		var off := Vector2(-6.0 + 6.0 * float(k), e.radius * 0.6 + 2.0 * sin(t + float(k)))
		SpriteBank.draw_disc(ci, off, e.radius * (0.55 - 0.1 * float(k % 2)), Color(Palette.DYN_SAND, a))
	SpriteBank.draw_disc(ci, Vector2(0.0, e.radius * 0.5), e.radius * 0.35, Color(Palette.DYN_SAND_DARK, a))
