## DeepSpawnBehavior — the Spawn of the Deep's Grasp ("grasp", UnitData; Act
## II, the finale's reward, GDD §15.0 "Ul-Thalos, the Risen Spire"). The Spawn
## is an ordinary melee "guard" summon and a physical blocker. On top of its
## tentacle lashes:
##   1. think(): when the grasp is ready and a foe stands within grasp_range px
##      of its body's edge, it plants itself (CASTING) and its tentacles reach
##      for the best grasp_targets foes in reach (elites, minibosses and the
##      boss first, elite_bonus; then the nearest), shown for grasp_windup s.
##   2. the grasp: each one is HELD for grasp_duration s through the dive-stun
##      hold (CombatResolver.stun_enemy(): the boss and minibosses get
##      grasp_boss_mult of it, elites grasp_elite_mult, Reckoning foes and
##      structures are immune; Spirit Binding lengthens it), dragged in at
##      grasp_pull px/s (never the boss, a miniboss or a structure) and
##      squeezed for grasp_damage every grasp_tick s ("deep_grasp").
##   3. it stands grasp_recover s, then rejoins the shared FSM; the holds run on
##      while it fights.
## The Leviathan (its evolution, SummonEvolutionData special_set) seizes two
## and, with every grasp, sweeps its tentacles around it: sweep_fraction x a
## squeeze to every foe within sweep_radius px, thrown back by
## sweep_knockback ("leviathan_sweep").
## The Tidecaller's Host Spawns (Call of the Drowned's evolution) are
## temporary summons of this class, so they grasp too.
## Determinism: only positions and game time; ties keep the spatial hash's order.
## Stats: deep_grasps, deep_grasp_holds, deep_grasp_squeezes, deep_grasp_held_seconds,
## leviathan_sweeps, leviathan_sweep_hits.
class_name DeepSpawnBehavior
extends SummonBehavior

## Phase: the tentacles reach.
const REACH: int = 1
## Phase: the short stand after the grasp.
const RECOVER: int = 2
## Damage source tag of a squeeze (PassiveData.MINION_SPECIAL_SOURCES).
const SOURCE: String = "deep_grasp"
## Damage source tag of the Leviathan's sweep (PassiveData.MINION_SPECIAL_SOURCES).
const SWEEP_SOURCE: String = "leviathan_sweep"

## Foes being reached for (this grasp): [Enemy, generation].
var _reach: Array = []
## Foes held: [Enemy, generation, seconds left, seconds to the next squeeze].
var _held: Array = []
## Reusable enemy query buffer.
var _buf: Array = []
## Candidate [score, enemy] pairs of a grasp.
var _cands: Array = []


## Full grasp cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("grasp_cooldown", 7.0))


## Drops every hold (the unit died / was pooled).
func on_deactivate(u: SummonedUnit) -> void:
	super.on_deactivate(u)
	_reach.clear()
	_held.clear()


func on_cancel(_u: SummonedUnit) -> void:
	_reach.clear()


## Starts a grasp when a foe is in reach.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0:
		return false
	var reach := float(u.special["grasp_range"])
	u.game.enemy_grid.query(u.position, u.radius + reach + ProjectileManager.MAX_BODY_RADIUS, _buf)
	_cands.clear()
	for e: Enemy in _buf:
		if not e.active or e.is_structure or e.is_reckoning or e.stun_timer > 0.0:
			continue
		var edge := e.position.distance_to(u.position) - e.radius - u.radius
		if edge > reach:
			continue
		var s := 1.0 - edge / maxf(1.0, reach)  # Nearer is better ...
		if e.is_boss or e.is_miniboss or e.is_elite:
			s += float(u.special.get("elite_bonus", 0.6))  # ... the strong first.
		_cands.append([s, e])
	if _cands.is_empty():
		return false
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	_reach.clear()
	for k in mini(int(u.special.get("grasp_targets", 1)), _cands.size()):
		var e: Enemy = _cands[k][1]
		_reach.append([e, e.generation])
	begin_special(u, REACH)
	return true


## Ticks the holds every tick (also while it walks), then the special.
func physics(u: SummonedUnit, delta: float) -> bool:
	if not _held.is_empty():
		_step_holds(u, delta)
	return super.physics(u, delta)


## Reach -> grasp -> recovery.
func step_special(u: SummonedUnit, _delta: float) -> bool:
	u.velocity = Vector2.ZERO
	match phase:
		REACH:
			if phase_time >= float(u.special["grasp_windup"]):
				_grasp(u)
				next_phase(RECOVER)
		RECOVER:
			if phase_time >= float(u.special["grasp_recover"]):
				end_special(u, SummonedUnit.State.ENGAGING if u.target_alive() else SummonedUnit.State.FOLLOWING)
	return true


## The tentacles close: every reached foe still alive is held (and the
## Leviathan sweeps).
func _grasp(u: SummonedUnit) -> void:
	var game := u.game
	var dur := float(u.special["grasp_duration"])
	var n := 0  # Foes held this grasp.
	var aim := u.position + Vector2.RIGHT * float(signf(u.scale.x) if u.scale.x != 0.0 else 1.0)
	for rec: Array in _reach:
		var e: Enemy = rec[0]
		if not e.active or e.generation != int(rec[1]):
			continue
		var held := game.combat.stun_enemy(e, dur, float(u.special["grasp_boss_mult"]), float(u.special["grasp_elite_mult"]))
		if held <= 0.0:
			continue
		_held.append([e, e.generation, held, float(u.special["grasp_tick"])])
		aim = e.position
		n += 1
		game.stat_add("deep_grasp_holds", 1.0)
	_reach.clear()
	u.motion_lunge(aim - u.position, MotionData.POWER_MELEE)  # Engine motion: the grasp (visual only).
	game.stat_add("deep_grasps", 1.0)
	if int(u.special.get("sweep", 0)) > 0:
		_sweep(u)
	if n > 0:
		Sfx.play("abom_stomp", u.position, 1.5)
		game.volleys.on_special(u, u.position, aim, float(u.special["grasp_damage"]))  # Bullet heaven: brine spray.
	u.queue_redraw()


## The Leviathan's tentacle sweep around it.
func _sweep(u: SummonedUnit) -> void:
	var game := u.game
	var pos := u.position
	var r := float(u.special.get("sweep_radius", 80.0))
	var dmg := float(u.special["grasp_damage"]) * float(u.special.get("sweep_fraction", 1.0))
	var kb := float(u.special.get("sweep_knockback", 160.0))
	game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var hits := 0  # Foes swept.
	for e: Enemy in _buf:
		if not e.active or e.position.distance_to(pos) > r + e.radius:
			continue
		var away := e.position - pos
		var dir := away / away.length() if away.length() > 0.01 else Vector2.RIGHT
		if not (e.is_boss or e.is_miniboss or e.is_structure):
			e.knockback += dir * kb / maxf(e.mass, 0.1)
		game.combat.damage_enemy(e, dmg, SWEEP_SOURCE)
		hits += 1
	game.effects.ring(pos, r, Palette.EYE_DROWNED, 0.35)
	game.stat_add("leviathan_sweeps", 1.0)
	game.stat_add("leviathan_sweep_hits", float(hits))


## Holds: drag the held foes in and squeeze them; a hold ends with its time,
## its foe's death or a stun that ran out.
func _step_holds(u: SummonedUnit, delta: float) -> void:
	var game := u.game
	var i := _held.size() - 1
	while i >= 0:
		var h: Array = _held[i]
		var e: Enemy = h[0]
		h[2] = float(h[2]) - delta
		if not e.active or e.generation != int(h[1]) or float(h[2]) <= 0.0 or e.stun_timer <= 0.0:
			_held.remove_at(i)
			i -= 1
			continue
		game.stat_add("deep_grasp_held_seconds", delta)
		if not (e.is_boss or e.is_miniboss or e.is_structure):
			var side := e.position - u.position
			var want := u.radius + e.radius + 2.0
			if side.length() > want:
				e.position = e.position.move_toward(u.position + side.normalized() * want, float(u.special["grasp_pull"]) * delta)
		h[3] = float(h[3]) - delta
		if float(h[3]) <= 0.0:
			h[3] = float(h[3]) + float(u.special["grasp_tick"])
			game.stat_add("deep_grasp_squeezes", 1.0)
			game.combat.damage_enemy(e, float(u.special["grasp_damage"]), SOURCE)
		i -= 1
	u.queue_redraw()  # The tentacles follow the held foes.


## Tentacles to the foes it reaches for or holds (its overlay layer).
func draw_over(u: SummonedUnit, ci: CanvasItem) -> void:
	if _reach.is_empty() and _held.is_empty():
		return
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(signf(u.scale.x) if u.scale.x != 0.0 else 1.0, 1.0))
	if phase == REACH:
		var k := clampf(phase_time / maxf(0.05, float(u.special["grasp_windup"])), 0.0, 1.0)
		for rec: Array in _reach:
			var e: Enemy = rec[0]
			if e.active and e.generation == int(rec[1]):
				SpireGlyphs.draw_tentacle(ci, Vector2.ZERO, (e.position - u.position) * k, u.radius * 0.4, true)
	for h: Array in _held:
		var e: Enemy = h[0]
		if e.active and e.generation == int(h[1]):
			SpireGlyphs.draw_tentacle(ci, Vector2.ZERO, e.position - u.position, u.radius * 0.4, false)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
