## BogMotherKit — THE BOG MOTHER, the Witchwood's miniboss (WitchwoodEnemyData
## "bog_mother"; Act VII, GDD §15.0 "The Witchwood (Act VII phase 2)"; owner-
## approved proposal: "Miniboss, the Bog Mother, a vast drowned witch who drags
## summons into the fen"). Female (a drowned witch, the figure style). Spawned
## once by WitchwoodDirector (the "bog_mother" timeline event) through the
## normal spawn path; she registers as EnemyDirector.miniboss (the HUD's
## miniboss bar; ChestManager drops the miniboss chest).
##   * HER BOG — black water of bog_radius px around her wherever she wades,
##       checked every BOG_CHECK s: FenWater.wade() (TerrainSlow, the one
##       ground-slow path) slows the necromancer, the summons and the living
##       foes standing in it.
##   * THE DRAG — every drag_every s, when summons stand within drag_reach px,
##       up to drag_count of the nearest are marked (a glowing ring under each
##       for drag_telegraph s); then weed-ropes seize the marked still within
##       reach x 1.2 and drag them into her bog through THE ONE PULL PATH,
##       pull(e, unit, delta): a summon is held by SummonedUnit.compel() (it
##       neither thinks nor attacks while the rope holds it; the shared FSM
##       resumes after) and moved toward her at drag_speed px/s, never into an
##       obstacle, for at most drag_hold s. One dragged to her side is DROWNED:
##       drown_damage (CombatResolver.damage_unit(), she is the attacker, so
##       Bloodfeast feeds her), and the rope lets go. An enemy effect on a
##       unit, like the Gatekeeper's chains: summons have no act rule.
##   * THE MIRE SLAM — a body within slam_trigger px and the slam ready: a
##       telegraphed circle of slam_radius px for slam_windup s, then every
##       necromancer and summon in it is hit and the summons thrown slam_push
##       px out (OlympusHits.circle()).
##   * The forced march — beyond advance_range px she strides
##       advance_speed_mult faster.
## On death: an XP burst (reward_xp in reward_crystals), the miniboss chest,
## every rope lets go. No RNG. Stats: bog_mother_spawned, bog_drags,
## bog_marked, bog_seized, bog_drowned, bog_slams, bog_slam_hits,
## bog_wade_player / _summons / _enemies, bog_mother_kills, bog_mother_ttk.
class_name BogMotherKit
extends CourtKit

## Phase: the drag's marks glow (its windup).
const DRAG_WINDUP: int = 1
## Phase: the slam's circle (its windup).
const SLAM_WINDUP: int = 2
## Seconds between two checks of her bog (the slows linger past it).
const BOG_CHECK: float = 0.25  # TUNING (not in GDD)
## Radius (px) of the mark drawn under a marked summon.
const MARK_RADIUS: float = 14.0  # TUNING (not in GDD) visual
## px of reach the autotest bot keeps beyond the slam's circle.
const DANGER_PAD: float = 18.0  # TUNING (not in GDD) autotest hint only

## One rope dragging a summon.
class Rope:
	extends RefCounted
	## The seized summon.
	var unit: SummonedUnit = null
	## Its generation (stale guard).
	var gen: int = 0
	## Seconds the rope may still hold it.
	var hold: float = 0.0

## Seconds until the next drag.
var _drag_cd: float = 0.0
## Seconds until the next slam.
var _slam_cd: float = 0.0
## Seconds toward the next bog check.
var _bog_acc: float = 0.0
## Summons marked by the current drag (locked at its windup).
var _marked: Array[SummonedUnit] = []
## Their generations.
var _marked_gen: PackedInt32Array = PackedInt32Array()
## Ropes dragging now.
var _ropes: Array[Rope] = []
## Walking speed before the forced march (px/s; -1 = not read yet).
var _base_speed: float = -1.0
## Game time she arrived (time-to-kill stat).
var _spawned_at: float = 0.0
## Grid query buffer.
var _q: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_drag_cd = 3.0
	_slam_cd = float(def["slam_every"]) * 0.5
	_bog_acc = 0.0
	_marked.clear()
	_marked_gen = PackedInt32Array()
	_ropes.clear()
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("bog_mother_spawned", 1.0)


func physics(e: Enemy, delta: float) -> bool:
	_drag_cd -= delta
	_slam_cd -= delta
	e.knockback = Vector2.ZERO  # A vast drowned witch is not shoved.
	if _base_speed < 0.0:
		_base_speed = e.move_speed
	_bog_acc += delta
	if _bog_acc >= BOG_CHECK:
		_bog_acc -= BOG_CHECK
		var at := e.position
		var r := float(d["bog_radius"])
		FenWater.wade(e.game, func(p: Vector2, br: float) -> bool: return p.distance_to(at) <= r - br * 0.33,
				float(d["bog_slow_player"]), float(d["bog_slow_summon"]), float(d["bog_slow_enemy"]), BOG_CHECK + 0.15, "bog_wade")
	_step_ropes(e, delta)
	match phase:
		DRAG_WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(d["drag_telegraph"]):
				_seize(e)
				set_phase(e, IDLE)
			return true
		SLAM_WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(d["slam_windup"]):
				_slam(e)
				set_phase(e, IDLE)
			return true
	var pl := e.game.player
	var dist := e.position.distance_to(pl.position)
	e.move_speed = _base_speed * (float(d["advance_speed_mult"]) if dist > float(d["advance_range"]) else 1.0)
	var t: Node2D = e.target if e.target != null and is_instance_valid(e.target) else pl
	if _slam_cd <= 0.0 and e.position.distance_to(t.position) - e.radius - body_radius(e, t) <= float(d["slam_trigger"]):
		_slam_cd = float(d["slam_every"])
		e.game.effects.telegraph_circle(e.position, float(d["slam_radius"]), float(d["slam_windup"]), e)
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		set_phase(e, SLAM_WINDUP)
		hold(e)
		return true
	if _drag_cd <= 0.0 and _mark(e):
		_drag_cd = float(d["drag_every"])
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		set_phase(e, DRAG_WINDUP)
		hold(e)
		return true
	return false


# =====================================================================================
# The drag and THE ONE PULL PATH
# =====================================================================================

## Marks the nearest summons within reach. False (and a short retry) when none.
func _mark(e: Enemy) -> bool:
	var g := e.game
	var reach := float(d["drag_reach"])
	var picks: Array[SummonedUnit] = []
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _q)
	for u: SummonedUnit in _q:
		if not u.active or u.airborne or u.charmed or u.is_compelled() or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(e.position) <= reach:
			picks.append(u)
	if picks.is_empty():
		_drag_cd = 1.0
		return false
	picks.sort_custom(func(a: SummonedUnit, b: SummonedUnit) -> bool: return a.position.distance_squared_to(e.position) < b.position.distance_squared_to(e.position))
	_marked.clear()
	_marked_gen = PackedInt32Array()
	for i in mini(int(d["drag_count"]), picks.size()):
		_marked.append(picks[i])
		_marked_gen.append(picks[i].generation)
	g.stat_add("bog_drags", 1.0)
	g.stat_add("bog_marked", float(_marked.size()))
	rules(e).play_sound("bog_drag", e.position)
	e.queue_redraw()
	return true


## The ropes seize the marked summons still within reach.
func _seize(e: Enemy) -> void:
	var g := e.game
	var reach := float(d["drag_reach"]) * 1.2
	for i in _marked.size():
		var u := _marked[i]
		if not u.active or u.generation != _marked_gen[i] or u.charmed or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(e.position) > reach:
			continue
		if not u.compel(u.position, g.elapsed + float(d["drag_hold"]), 0.0):
			continue
		var r := Rope.new()
		r.unit = u
		r.gen = u.generation
		r.hold = float(d["drag_hold"])
		_ropes.append(r)
		g.stat_add("bog_seized", 1.0)
		g.effects.ring(u.position, u.radius * 1.6, WitchwoodGlyphs.WEED, 0.25)
	_marked.clear()
	_marked_gen = PackedInt32Array()


## THE ONE PULL PATH of the Bog Mother's ropes: moves seized summon `u` (held
## by SummonedUnit.compel()) toward her at drag_speed px/s, never into an
## obstacle. Returns the px left to her side.
func pull(e: Enemy, u: SummonedUnit, delta: float) -> float:
	var side := u.position - e.position
	var dist := side.length()
	var want := e.radius + u.radius + 4.0  # Dragged against her.
	if dist > want:
		var goal := e.position + side / dist * want
		var to := goal - u.position
		var step := minf(float(d["drag_speed"]) * delta, to.length())
		if step > 0.0:
			var dir := to / to.length()
			u.position += dir * e.game.arena.clear_length(u.position, dir, step, u.radius * 0.5)
	return maxf(0.0, u.position.distance_to(e.position) - want)


## Every rope drags its summon in; at her side it drowns and the rope lets go.
func _step_ropes(e: Enemy, delta: float) -> void:
	if _ropes.is_empty():
		return
	e.queue_redraw()  # The ropes (drawing only).
	var g := e.game
	var mult := hit_scale(e)
	var i := 0
	while i < _ropes.size():
		var r := _ropes[i]
		r.hold -= delta
		var u := r.unit
		if not u.active or u.generation != r.gen or not u.is_compelled() or u.charmed:
			_let_go(r)
			_ropes.remove_at(i)
			continue
		if pull(e, u, delta) <= 2.0:
			g.combat.damage_unit(u, float(d["drown_damage"]) * mult * e.undead_damage_mult, WitchwoodEnemyData.DROWN_SOURCE, e)
			g.stat_add("bog_drowned", 1.0)
			g.effects.ring(u.position, u.radius * 2.0, WitchwoodGlyphs.FEN_WATER, 0.3)
			_let_go(r)
			_ropes.remove_at(i)
			continue
		if r.hold <= 0.0:
			_let_go(r)
			_ropes.remove_at(i)
			continue
		i += 1


## The rope lets go: its summon is free again (its compel ends now).
func _let_go(r: Rope) -> void:
	var u := r.unit
	if u != null and u.active and u.generation == r.gen:
		u.compel_until = minf(u.compel_until, u.game.elapsed)
	r.unit = null


# =====================================================================================
# The slam, death, hints, drawing
# =====================================================================================

## The mire slam: every necromancer and summon in the circle is hit, the summons thrown out.
func _slam(e: Enemy) -> void:
	var g := e.game
	var mult := hit_scale(e)
	g.stat_add("bog_slams", 1.0)
	g.stat_add("bog_slam_hits", float(OlympusHits.circle(g, e.position, float(d["slam_radius"]),
			float(d["slam_damage_player"]) * mult, float(d["slam_damage_summon"]) * mult * e.undead_damage_mult,
			WitchwoodEnemyData.MIRE_SOURCE, e, float(d["slam_push"]), _q)))
	g.effects.impact(e.position, float(d["slam_radius"]), WitchwoodGlyphs.FEN_WATER)
	g.shake(4.0)


## The XP burst, banner and stats of her fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (26.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, WitchwoodGlyphs.FEN_WATER)
	g.shake(8.0)
	g.enemies.show_banner("The Bog Mother sinks into the fen: her ropes go slack!")
	g.stat_add("bog_mother_kills", 1.0)
	g.stat_add("bog_mother_ttk", g.elapsed - _spawned_at)


## Every rope lets go; releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	for r in _ropes:
		_let_go(r)
	_ropes.clear()
	_marked.clear()
	e.game.enemies.clear_miniboss(e)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the slam circle.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase == SLAM_WINDUP:
		var off := p - e.position
		var reach := float(d["slam_radius"]) + DANGER_PAD
		if off.length() < reach:
			return (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 2.5
	return Vector2.ZERO


## Her bog: dark water under her (texture discs; the floor, under her body).
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	var r := float(d["bog_radius"])
	e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r * 0.55), Vector2(r * 2.0, r * 1.1)), false, Color(WitchwoodGlyphs.FEN_WATER, 0.55))
	e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r * 0.7, -r * 0.38), Vector2(r * 1.4, r * 0.77)), false, Color(WitchwoodGlyphs.FEN_DEEP, 0.5))


## The marks under the marked summons and the weed-ropes to the seized ones
## (the Court's thread texture, tinted weed green). Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	super.draw_over(e, ci)
	if _marked.is_empty() and _ropes.is_empty():
		return
	var base := CourtGlyphs.unmirror_xf(e)
	ci.draw_set_transform_matrix(base)
	var k := clampf(phase_time / maxf(0.01, float(d["drag_telegraph"])), 0.0, 1.0) if phase == DRAG_WINDUP else 1.0
	for i in _marked.size():
		var u := _marked[i]
		if u.active and u.generation == _marked_gen[i]:
			var at := u.position - e.position
			ci.draw_texture_rect(CourtGlyphs.ring_texture(), Rect2(at - Vector2.ONE * MARK_RADIUS, Vector2.ONE * MARK_RADIUS * 2.0), false, Color(WitchwoodGlyphs.WEED_LIGHT, 0.4 + 0.5 * k))
	for r in _ropes:
		var u := r.unit
		if u != null and u.active and u.generation == r.gen:
			CourtGlyphs.draw_thread(ci, Vector2.ZERO, u.position - e.position, 3.0, Color(WitchwoodGlyphs.WEED_LIGHT, 0.9), base)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
