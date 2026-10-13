## MotionDirector: runs the tier-0 engine motion of a run (GDD §15.0 "Art
## pass (true pixel art)"). Once per rendered frame it updates the
## UnitMotion of the necromancer, every living enemy (bosses and the miniboss
## included) and every summon on or near the screen, and plays the pooled
## death dissolves (UnitDissolve). Gameplay code only reports moments to it:
## a summon rising (on_summon_rise), an enemy or summon dying
## (on_enemy_killed / on_summon_died); hits and attacks go straight to the
## unit's own UnitMotion.
##
## Its clock is Game.elapsed (advanced by the physics tick), so the motion
## slows with the hit-stop, stops while paused and runs 8x under the
## autotest's speed-up, like every other effect. It reads the units and
## never writes gameplay state, uses no RNG and allocates nothing per frame;
## it works headless (the layers simply never draw there).
## Owned by Game, added before the horde and the enemies so dissolving
## bodies sit under the living ones.
class_name MotionDirector
extends Node2D

## Owning run.
var game: Game
## Dissolves playing.
var _active: Array[UnitDissolve] = []
## Idle dissolves ready for reuse.
var _pool: Array[UnitDissolve] = []
## Dissolve nodes ever created (pool health; not part of the autotest summary).
var created: int = 0
## Game.elapsed at the previous frame (s).
var _last_elapsed: float = 0.0
## World rect animated this frame (the camera view plus CULL_MARGIN).
var _view: Rect2 = Rect2()


func _process(_delta: float) -> void:
	if game == null or game.player == null:
		return
	var now := game.elapsed  # Game time (s).
	var dt := maxf(0.0, now - _last_elapsed)  # Game seconds since the last frame (0 while paused).
	_last_elapsed = now
	_update_view()
	var p := game.player
	if p.motion != null:
		p.motion.update(now, dt, p.dead, false, game.grave_step != null and game.grave_step.is_dashing())
	for e: Enemy in game.enemies.active:
		if e.active and e.motion != null and _view.has_point(e.position):
			e.motion.update(now, dt, e.frozen, false)
	for u: SummonedUnit in game.horde.units:
		if u.active and u.motion != null and _view.has_point(u.position):
			u.update_motion(now, dt)
	if not _active.is_empty():
		_step_dissolves(dt)


## The camera's visible world rect grown by MotionData.CULL_MARGIN.
func _update_view() -> void:
	var size := get_viewport_rect().size / maxf(game.camera.zoom.x, 0.01)  # Visible world size (px).
	var m := Vector2.ONE * MotionData.CULL_MARGIN  # Margin on each side (px).
	_view = Rect2(game.camera.position - size * 0.5 - m, size + m * 2.0)


## A new summon rises out of the ground: its rise and a puff of grave dust.
func on_summon_rise(u: SummonedUnit) -> void:
	if u.motion == null:
		return
	u.motion.begin_rise(game.elapsed)
	_dust(u.position + Vector2(0.0, u.motion.feet), MotionData.BONE_DUST_DARK, MotionData.BONE_DUST, MotionData.RISE_DUST, u.radius)


## An enemy died: its body collapses into holy ash. Bosses keep their own
## death sequence and structures only ever react to hits, so neither dissolves.
func on_enemy_killed(e: Enemy) -> void:
	if e.is_boss or e.is_structure or e.motion == null:
		return
	var d := _take()  # The dissolve to play, or null at the cap.
	if d == null:
		return
	var f := 1.0 if e.scale.x >= 0.0 else -1.0  # Facing at death.
	d.start(e.position, f, UnitDissolve.Look.ENEMY, e.kind, e.radius, e.is_elite, 0.0, e.motion.feet, false)
	_dust(e.position + Vector2(0.0, e.motion.feet * 0.5), MotionData.HOLY_ASH, MotionData.HOLY_EMBER, MotionData.DISSOLVE_DUST, e.radius)


## A summon died (a real death, not a merge): it collapses into bone dust.
func on_summon_died(u: SummonedUnit) -> void:
	if u.motion == null or u.airborne:
		return
	var d := _take()  # The dissolve to play, or null at the cap.
	if d == null:
		return
	var f := 1.0 if u.scale.x >= 0.0 else -1.0  # Facing at death.
	var glyph := u.glyph_kind if u.glyph_kind != "" else u.unit_class  # Its look.
	var lift := u.behavior.body_lift(u) if u.behavior != null else 0.0  # Floating height (px).
	d.start(u.position, f, UnitDissolve.Look.SUMMON, glyph, u.radius, false, lift, u.motion.feet, true)
	_dust(u.position + Vector2(0.0, u.motion.feet * 0.5), MotionData.BONE_DUST, MotionData.BONE_DUST_DARK, MotionData.DISSOLVE_DUST, u.radius)


## Takes a dissolve from the pool (or makes one); null at MAX_DISSOLVES.
func _take() -> UnitDissolve:
	if _active.size() >= MotionData.MAX_DISSOLVES:
		return null
	var d: UnitDissolve
	if _pool.is_empty():
		d = UnitDissolve.new()
		add_child(d)
		created += 1
	else:
		d = _pool.pop_back()
	_active.append(d)
	return d


## Advances the dissolves by `dt` game seconds and pools the finished ones.
func _step_dissolves(dt: float) -> void:
	var i := 0
	while i < _active.size():
		var d := _active[i]
		if d.advance(dt):
			i += 1
		else:
			_active[i] = _active[_active.size() - 1]
			_active.pop_back()
			_pool.append(d)


## Dust motes at `pos` (FxLayer, its own cosmetic RNG): `count` scaled up
## to x2 for bodies bigger than MotionData.REF_RADIUS.
func _dust(pos: Vector2, color: Color, alt: Color, count: int, radius: float) -> void:
	if Juice.fx == null:
		return
	var n := int(round(float(count) * clampf(radius / MotionData.REF_RADIUS, 1.0, 2.0)))  # Motes.
	Juice.fx.dust(pos, color, alt, n, radius)
