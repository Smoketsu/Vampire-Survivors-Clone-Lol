## GrapplerKit — the kit of the Grappler (CorsairEnemyData "grappler"; Act X,
## the Black Tide; GDD §15.0 "The Smuggler's Cutter (Act X phase 2)";
## owner-approved proposal: "Throws a hook line that drags one summon to the
## rail (into the rail band) | Kill first; Sea Legs passive"). A male boarder:
## the shared melee AI drives him between throws. Every grapple "every" s, when
## a grounded summon stands min_range..range px away, he SWINGS the hook
## (windup s, the line drawn toward it), the hook FLIES (throw s) and BITES:
## the summon is held (SummonedUnit.held_until, renewed every tick, plus ONE
## CombatResolver.stun_unit(u, drag, "grapple"): the held hook and the one
## summon stun path) and DRAGGED toward its nearest rail at pull px/s x
## CorsairRules.sea_legs_mult(u) (TerrainSlow.push_summon(), the act's one
## shove path; the deck stops it at the rail: summons never fall) for drag s or
## until it is rail_stop px from the rail. Off Act X (no deck) he drags it
## toward himself. Killing him (or the summon dying) cuts the line; the summon
## keeps a short daze. A body wider than max_radius px is too heavy to drag
## (the tentacle's rule). Not a summon rule: an enemy effect on a summon
## through the existing paths.
## Determinism: no RNG (first throw staggered by his think slot; the nearest
## summon in the ally grid's order). Stats: grapple_throws, grapple_bites,
## grapple_dragged_px, grapple_cut.
class_name GrapplerKit
extends CorsairKit

## Phase: he swings the hook (the telegraph).
const SWING: int = 1
## Phase: the hook flies to the summon.
const THROW: int = 2
## Phase: the line is fast; he hauls.
const HAUL: int = 3

## Seconds until he may throw again.
var throw_cd: float = 0.0
## The summon on (or under) the hook (null otherwise).
var mark: SummonedUnit = null
## Pool generation of `mark` (stale guard).
var mark_gen: int = 0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	throw_cd = first_cd(e, float(_g().get("every", 7.5)) * 0.4)
	mark = null
	mark_gen = 0


## The row's grapple numbers.
func _g() -> Dictionary:
	return d.get("grapple", {})


## The line is cut when he leaves the field.
func on_deactivate(e: Enemy) -> void:
	_let_go(e, true)
	super.on_deactivate(e)


## True while `mark` is the same living summon it was when hooked.
func _mark_ok() -> bool:
	return mark != null and mark.active and mark.generation == mark_gen and mark.state != SummonedUnit.State.DEAD


func physics(e: Enemy, delta: float) -> bool:
	if super.physics(e, delta):
		return true
	var g := _g()
	throw_cd -= delta
	match phase:
		SWING, THROW:
			phase_time += delta
			hold(e)
			if not _mark_ok():
				mark = null
				set_phase(e, IDLE)
				return false
			if phase == SWING and phase_time >= float(g.get("windup", 0.6)):
				set_phase(e, THROW)
				rules(e).play_sound("hook_throw", e.position, 0.2)
			elif phase == THROW and phase_time >= float(g.get("throw", 0.3)):
				_bite(e)
			return true
		HAUL:
			phase_time += delta
			hold(e)
			if not _mark_ok():
				_let_go(e, false)
				return false
			_haul(e, delta)
			return true
	if throw_cd > 0.0:
		return false
	var best := _pick(e, g)
	if best == null:
		throw_cd = 0.5
		return false
	mark = best
	mark_gen = best.generation
	throw_cd = float(g.get("every", 7.5))
	set_phase(e, SWING)
	e.game.stat_add("grapple_throws", 1.0)
	return true


## The nearest grounded, draggable summon min_range..range px away, or null.
func _pick(e: Enemy, g: Dictionary) -> SummonedUnit:
	var reach := float(g.get("range", 180.0))
	var near := float(g.get("min_range", 34.0))
	var heavy := float(g.get("max_radius", 13.0))
	var best: SummonedUnit = null
	var best_d := INF
	var tmp: Array = []
	e.game.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, tmp)
	for u: SummonedUnit in tmp:
		if not u.active or u.airborne or u.flies or u.charmed or u.state == SummonedUnit.State.DEAD \
				or u.state == SummonedUnit.State.SPAWNING or u.held_until > e.game.elapsed or u.radius > heavy:
			continue
		var dist := u.position.distance_to(e.position)
		if dist >= near and dist <= reach and dist < best_d:
			best = u
			best_d = dist
	return best


## The hook bites: the summon is held and stunned for the haul.
func _bite(e: Enemy) -> void:
	var g := _g()
	var drag := float(g.get("drag", 1.4))
	var gm := e.game
	gm.combat.damage_unit(mark, float(g.get("damage", 3.0)) * hit_scale(e), e.kind, e)
	if not _mark_ok():
		mark = null
		set_phase(e, IDLE)
		return
	mark.held_until = maxf(mark.held_until, gm.elapsed + 0.2)
	gm.combat.stun_unit(mark, drag, "grapple")
	gm.stat_add("grapple_bites", 1.0)
	rules(e).play_sound("hook_bite", mark.position, 0.2)
	set_phase(e, HAUL)


## One tick of the haul: the summon slides toward its rail (x Sea Legs).
func _haul(e: Enemy, delta: float) -> void:
	var g := _g()
	var gm := e.game
	var u := mark
	u.held_until = maxf(u.held_until, gm.elapsed + 0.2)
	var dir: Vector2
	var done := phase_time >= float(g.get("drag", 1.4))
	if gm.deck != null:
		var rail: Array = gm.deck.nearest_rail(u.position)
		dir = rail[1]
		if gm.deck.rail_depth(u.position) <= float(g.get("rail_stop", 28.0)) + u.radius:
			done = true
	else:
		var to := e.position - u.position
		dir = to.normalized() if to.length() > e.radius + u.radius + 4.0 else Vector2.ZERO
	if not done and dir != Vector2.ZERO:
		var v := dir * float(g.get("pull", 150.0)) * rules(e).sea_legs_mult(u)
		if TerrainSlow.push_summon(gm, u, v, delta):
			gm.stat_add("grapple_dragged_px", v.length() * delta)
	if done:
		_let_go(e, false)


## The line comes off: the summon keeps only a short daze (`cut`: he was
## killed or pooled mid-haul).
func _let_go(e: Enemy, cut: bool) -> void:
	if _mark_ok() and phase == HAUL:
		mark.held_until = minf(mark.held_until, e.game.elapsed + 0.2)
		if cut:
			e.game.stat_add("grapple_cut", 1.0)
	mark = null
	if phase != IDLE:
		set_phase(e, IDLE)


func is_busy() -> bool:
	return in_water or phase != IDLE


## The hook line: a cream rope from his hands to the hook (swinging, flying or
## fast), drawn in world axes. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase == IDLE or not _mark_ok():
		return
	ci.draw_set_transform_matrix(CourtGlyphs.unmirror_xf(e))
	var to := mark.position - e.position
	var tip := to
	if phase == SWING:
		tip = Vector2.from_angle(phase_time * 14.0) * 14.0 + Vector2(0.0, -e.radius)  # The hook whirls overhead.
	elif phase == THROW:
		tip = to * clampf(phase_time / maxf(float(_g().get("throw", 0.3)), 0.01), 0.0, 1.0)
	ci.draw_line(Vector2(0.0, -e.radius * 0.5), tip, Palette.CORSAIR_SAIL_SHADE, 1.5)
	SpriteBank.draw_disc(ci, tip, 2.5, Palette.CORSAIR_POWDER_LIGHT)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
