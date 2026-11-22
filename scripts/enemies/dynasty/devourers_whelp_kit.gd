## DevourersWhelpKit — the kit of THE DEVOURER'S WHELP, the Hall of Two Truths'
## miniboss (TwoTruthsEnemyData "devourers_whelp"; temporary Act XII, the
## Necropolis Dynasty; GDD §15.0 "The Hall of Two Truths (Necropolis Dynasty
## phase 2)"; owner-approved proposal: "Miniboss: The Devourer's Whelp (a young
## hippo-lion-crocodile beast), who eats corpses"). A creature, a sacred beast
## (no Rebirth). TwoTruthsDirector sends it (the "devourers_whelp" event); on
## activation it registers for the HUD's miniboss bar
## (EnemyDirector.set_miniboss()) and the ChestManager drops its chest when it
## falls (row "miniboss"). Between its bites (the shared melee):
##   * IT EATS CORPSES: whenever a cartouche (a Dynasty Name waiting over its
##     body, Rebirth) lies within seek_reach px it leaves its prey and lopes to
##     the nearest at seek_speed_mult x its speed (the kit moves it, never into
##     an obstacle) and EATS it (Rebirth.eat(), the one eat path: that body
##     never returns), healing eat_heal of its max HP through
##     CombatResolver.heal_enemy() (the shared heal) and taking a HUNGER stack
##     (+hunger_damage x its bite and its gulp, +hunger_speed x its speed), at
##     most hunger_max. A sealed cartouche (a Canopic Jar holds it) is eaten too: the
##     jar's seal keeps the necromancer's blows off a Name, not the Devourer's
##     teeth.
##   * THE GULP: every gulp_every s, once a summon or the necromancer is near,
##     it plants its feet and telegraphs a bite gulp_radius px in front of it
##     for gulp_warn s, then snaps: every summon in it takes gulp_damage and the
##     necromancer half of it (x the time scaling, its hit multiplier and its
##     hunger).
## Determinism: no RNG (the nearest cartouche, the nearest body; ties in list
## order). Stats: whelp_spawned, whelp_eaten, whelp_healed, whelp_gulps,
## whelp_gulp_hits, whelp_kill_time, whelp_hunger_peak.
class_name DevourersWhelpKit
extends DynastyKit

## Phase: planting its feet before the gulp.
const GULP: int = 1

## Hunger stacks (Names eaten, capped at hunger_max).
var hunger: int = 0
## Seconds until the next gulp may start.
var _gulp_cd: float = 0.0
## Where the gulp lands (world px), set when it is telegraphed.
var _gulp_at: Vector2 = Vector2.ZERO
## Game time (s) it arrived (the report's kill time).
var _arrived_at: float = 0.0
## Its base move speed (px/s) from the row (hunger scales it).
var _base_speed: float = 0.0
## Its base bite (before the scalings) from the row (hunger scales it).
var _base_damage: float = 0.0
## Query buffer.
var _q: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	hunger = 0
	_gulp_cd = first_cd(e, float(d["gulp_first"]))
	_gulp_at = Vector2.ZERO
	_arrived_at = e.game.elapsed
	_base_speed = e.move_speed
	_base_damage = e.damage
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("whelp_spawned", 1.0)
	rules(e).play_sound("whelp_roar", e.position, 1.0)


func on_deactivate(e: Enemy) -> void:
	e.game.enemies.clear_miniboss(e)
	super.on_deactivate(e)


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	g.stats["whelp_kill_time"] = g.elapsed - _arrived_at
	g.effects.ring(e.position, 110.0, Palette.DYN_CARNELIAN, 0.6)
	g.effects.impact(e.position, 60.0, Palette.DYN_BRONZE)


## x its bite and its gulp: its hunger.
func hunger_mult() -> float:
	return 1.0 + float(d["hunger_damage"]) * float(hunger)


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var g := e.game
	if phase == GULP:
		hold(e)
		phase_time += delta
		if phase_time >= float(d["gulp_warn"]):
			_snap(e)
			set_phase(e, IDLE)
		return true
	_gulp_cd -= delta
	# The corpses first: a Name within reach draws it off its prey.
	if g.dynasty != null and g.dynasty.rebirth.alive_count() > 0:
		var c := _nearest_name(e)
		if c != null:
			_lope(e, c, delta)
			return true
	if _gulp_cd <= 0.0:
		var t := _gulp_point(e)
		if t != Vector2.INF:
			_gulp_at = t
			_gulp_cd = float(d["gulp_every"])
			set_phase(e, GULP)
			g.effects.telegraph_circle(_gulp_at, float(d["gulp_radius"]), float(d["gulp_warn"]), e)
			g.stat_add("boss_atk_whelp_gulp", 1.0)
			return true
	return false


## The nearest cartouche within seek_reach px (null = none).
func _nearest_name(e: Enemy) -> Enemy:
	var best: Enemy = null
	var best_d := float(d["seek_reach"])
	for c in e.game.dynasty.rebirth.cartouches:
		if not c.active:
			continue
		var dd := c.position.distance_to(e.position)
		if dd <= best_d:
			best_d = dd
			best = c
	return best


## Lopes toward cartouche `c` (never into an obstacle) and eats it on arrival.
func _lope(e: Enemy, c: Enemy, delta: float) -> void:
	var g := e.game
	var to := c.position - e.position
	var dist := to.length()
	if dist - e.radius - c.radius <= float(d["eat_reach"]):
		_eat(e, c)
		return
	var dir := to / maxf(dist, 0.01)
	var spd := _speed(e) * float(d["seek_speed_mult"])
	e.velocity = dir * spd
	e.position += dir * g.arena.clear_length(e.position, dir, minf(spd * delta, dist), e.radius * 0.5)
	e._update_facing()  # Faces where it lopes (the shared facing).


## Its move speed now (its row's, its hunger, slows).
func _speed(e: Enemy) -> float:
	var s := _base_speed * (1.0 + float(d["hunger_speed"]) * float(hunger))
	if e.slow_timer > 0.0:
		s *= 1.0 - e.slow_factor
	return s


## Eats cartouche `c`: the Name is gone for good, it heals and grows hungrier.
func _eat(e: Enemy, c: Enemy) -> void:
	var g := e.game
	var at := c.position
	g.dynasty.rebirth.eat(c)
	var healed := g.combat.heal_enemy(e, e.max_hp * float(d["eat_heal"]))
	hunger = mini(hunger + 1, int(d["hunger_max"]))
	e.move_speed = _base_speed * (1.0 + float(d["hunger_speed"]) * float(hunger))
	e.damage = _base_damage * hunger_mult()  # Its bite (the shared melee).
	g.stat_add("whelp_eaten", 1.0)
	g.stat_add("whelp_healed", healed)
	g.stats["whelp_hunger_peak"] = maxf(float(g.stats.get("whelp_hunger_peak", 0.0)), float(hunger))
	g.effects.pop(at, Palette.DYN_CARNELIAN, 16.0)
	rules(e).play_sound("whelp_eat", at, 0.3)


## Where its gulp would land: a point gulp_radius px toward the nearest
## summon or necromancer within twice that (INF = nobody near).
func _gulp_point(e: Enemy) -> Vector2:
	var g := e.game
	var reach := float(d["gulp_radius"]) * 2.0 + e.radius
	var best: Node2D = null
	var best_d := reach
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= best_d:
			best_d = pl.position.distance_to(e.position)
			best = pl
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _q)
	for u: SummonedUnit in _q:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(e.position) < best_d:
			best_d = u.position.distance_to(e.position)
			best = u
	if best == null:
		return Vector2.INF
	var dir := (best.position - e.position).normalized() if best_d > 0.5 else Vector2.RIGHT
	return e.position + dir * (e.radius + float(d["gulp_radius"]) * 0.6)


## The gulp: every summon in the circle takes its damage, the necromancer half.
func _snap(e: Enemy) -> void:
	var g := e.game
	var r := float(d["gulp_radius"])
	var dmg := float(d["gulp_damage"]) * hit_scale(e) * hunger_mult()  # Per body.
	var hits := 0
	g.ally_grid.query(_gulp_at, r + UnitData.MAX_BLOCK_RADIUS, _q)
	for u: SummonedUnit in _q:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(_gulp_at) <= r + u.radius:
			g.combat.damage_unit(u, dmg * e.undead_damage_mult, e.kind + "_gulp", e)
			hits += 1
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(_gulp_at) <= r + pl.radius:
			g.combat.damage_player(dmg * 0.5, e.kind + "_gulp", pl, e)
			hits += 1
	g.stat_add("whelp_gulps", 1.0)
	g.stat_add("whelp_gulp_hits", float(hits))
	g.effects.ring(_gulp_at, r, Palette.DYN_CARNELIAN, 0.25)
	rules(e).play_sound("whelp_eat", _gulp_at, 0.2)
	e.motion_lunge((_gulp_at - e.position).normalized(), MotionData.POWER_CAST)


func is_busy() -> bool:
	return phase != IDLE


## The autotest autopilot's push out of the telegraphed gulp.
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	if phase != GULP:
		return Vector2.ZERO
	var r := float(d["gulp_radius"]) + 14.0
	var off := p - _gulp_at
	if off.length() >= r or off.length() < 0.01:
		return Vector2.ZERO
	return off.normalized() * (1.0 - off.length() / r)
