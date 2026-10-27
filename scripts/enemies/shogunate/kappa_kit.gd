## KappaKit — the kit of the Kappa (ProvinceEnemyData "kappa"; Act V, the
## Burning Province, GDD §15.0 "The Burning Province (Act V phase 2)";
## owner-approved brief: "night yokai fodder of the paddies. Water-strong (no
## slow in water), it grapples a summon briefly"). NIGHT (the timeline helper
## keeps it to the night). Water-strong is its row's "swimmer": the
## ProvinceDirector's paddy check never slows it. It walks at the necromancer
## with the shared melee AI and, on its own rhythm, GRAPPLES: when a summon on
## the ground stands within grapple_reach px of its body (edge to edge) and the
## grapple is ready, it seizes it for grapple_hold s through THE one compel
## path (SummonedUnit.compel() with no speed: the summon is held fast, neither
## thinking nor fighting; an enemy effect on a unit, no summon rule), holds
## still itself and squeezes every grapple_tick s (grapple_damage). The grip
## ends early when the kappa dies, is frozen or stunned (its physics stops),
## or the summon dies. Determinism: no RNG. Stats: kappa_grapples,
## kappa_squeezes.
class_name KappaKit
extends ShogunateKit

## Phase: holding a summon.
const HOLDING: int = 1

## Seconds until the next grapple may start.
var _cd: float = 0.0
## The summon it holds (null = none).
var _held: SummonedUnit = null
## Generation of `_held` when seized.
var _held_gen: int = 0
## Seconds until the next squeeze.
var _squeeze_cd: float = 0.0
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("grapple_every", 7.0)) * 0.5)
	_held = null


func on_deactivate(e: Enemy) -> void:
	_release(e)
	super.on_deactivate(e)


## The grapple (see the header). Returns true while it holds a summon.
func physics(e: Enemy, delta: float) -> bool:
	_cd -= delta
	if phase == HOLDING:
		phase_time += delta
		hold(e)
		if _held == null or not _held.active or _held.generation != _held_gen or not _held.is_compelled() \
				or phase_time >= float(d["grapple_hold"]):
			_release(e)
			return false
		_squeeze_cd -= delta
		if _squeeze_cd <= 0.0:
			_squeeze_cd += float(d["grapple_tick"])
			e.game.combat.damage_unit(_held, float(d["grapple_damage"]) * hit_scale(e) * e.undead_damage_mult, ProvinceEnemyData.GRAPPLE_SOURCE, e)
			e.game.stat_add("kappa_squeezes", 1.0)
		return true
	if _cd > 0.0:
		return false
	var u := _nearest(e)
	if u == null:
		return false
	var until := e.game.elapsed + float(d["grapple_hold"])
	if not u.compel(u.position, until, 0.0):
		_cd = 1.0
		return false
	_held = u
	_held_gen = u.generation
	_cd = float(d["grapple_every"])
	_squeeze_cd = float(d["grapple_tick"]) * 0.5
	e.game.stat_add("kappa_grapples", 1.0)
	e.motion_lunge(u.position - e.position, MotionData.POWER_MELEE)
	set_phase(e, HOLDING)
	hold(e)
	return true


## The nearest grounded summon within grapple_reach of its body's edge (null = none).
func _nearest(e: Enemy) -> SummonedUnit:
	var reach := float(d["grapple_reach"])
	e.game.ally_grid.query(e.position, e.radius + reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var best: SummonedUnit = null
	var best_d := INF
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD or u.is_compelled():
			continue
		var dist := u.position.distance_to(e.position) - e.radius - u.radius
		if dist <= reach and dist < best_d:
			best_d = dist
			best = u
	return best


## Lets go of the held summon (its compel ends now).
func _release(e: Enemy) -> void:
	if _held != null and _held.active and _held.generation == _held_gen and e.game != null:
		_held.compel_until = minf(_held.compel_until, e.game.elapsed)  # The grip opens (as the Spawn of the Deep's: the compel path frees it next tick).
	_held = null
	if phase == HOLDING:
		set_phase(e, IDLE)


func is_busy() -> bool:
	return phase == HOLDING
