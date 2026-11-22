## BogCrocKit — the kit of the BOG CROC (PrimevalEnemyData "bog_croc"; temporary
## Act XIV, the Fern Basin; GDD §15.0 "The Fern Basin (Act XIV phase 2)";
## owner-approved proposal: "Bog Croc (male) | Ambush | Hides in tar and river
## tiles; lunges at the rail of the ring | Wither, Area, avoid the tar"). A
## tar-black crocodile. Its phases:
##   * SUBMERGED (from its first tick): it lies still where it came up (the
##     Fern Basin brings it up in a tar pool: FernBasinDirector), only its eyes
##     above the tar. It is UNTARGETABLE (Enemy.untargetable: out of the enemy
##     grid, so nothing aims at it or hits it) and ETHEREAL (no summon
##     body-blocks it), both the existing one paths. A summon or necromancer
##     within lunge_reach px wakes it; after max_wait s it comes up anyway
##     (enemies always advance).
##   * EMERGE (emerge_time s): it rears out of the pool, targetable and solid
##     again: the telegraph (a line shows the lunge).
##   * LUNGE: it runs lunge_speed px/s up to lunge_len px at the body it
##     picked (the nearest summon or necromancer: the rail of the ring); the
##     first summon or necromancer it touches takes lunge_damage / lunge_player
##     once (x the time scaling, CombatResolver.damage_unit() /
##     damage_player()), and the lunge ends.
##   * then the shared melee AI (IDLE).
## A freeze or stun holds it like any kit (Enemy). Determinism: no RNG, no
## instance ids. Stats: croc_ambushes, croc_lunges, croc_lunge_hits,
## croc_lunge_on_you, croc_tired (came up without a body near).
class_name BogCrocKit
extends PrimevalKit

## Phase: lying in the tar.
const SUBMERGED: int = 1
## Phase: rearing out of the pool (the telegraph).
const EMERGE: int = 2
## Phase: the lunge.
const LUNGE: int = 3
## px between two drawn marks of the lunge's line (visual only).
const MARK_STEP: float = 8.0  # TUNING (not in GDD) visual only

## The lunge's direction (unit).
var lunge_dir: Vector2 = Vector2.RIGHT
## px of the lunge run so far.
var lunge_run: float = 0.0
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	lunge_run = 0.0
	set_phase(e, SUBMERGED)
	_hide(e, true)


func on_deactivate(e: Enemy) -> void:
	_hide(e, false)
	super.on_deactivate(e)


## Every tick (see the header): true while a phase owns the tick.
func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	match phase:
		SUBMERGED:
			phase_time += delta
			hold(e)
			var near := _nearest_body(e, float(d.get("lunge_reach", 150.0)))
			if near != null or phase_time >= float(d.get("max_wait", 10.0)):
				if near == null:
					g.stat_add("croc_tired", 1.0)
					near = g.nearest_player(e.position)
				else:
					g.stat_add("croc_ambushes", 1.0)
				var to := near.position - e.position
				lunge_dir = to.normalized() if to.length() > 0.5 else Vector2.RIGHT
				_hide(e, false)
				rules(e).play_sound("croc_lunge", e.position, 0.3)
				set_phase(e, EMERGE)
			return true
		EMERGE:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("emerge_time", 0.55)):
				lunge_run = 0.0
				g.stat_add("croc_lunges", 1.0)
				e.motion_lunge(lunge_dir, MotionData.POWER_CAST)
				set_phase(e, LUNGE)
			return true
		LUNGE:
			var step := float(d.get("lunge_speed", 340.0)) * delta
			e.velocity = lunge_dir * float(d.get("lunge_speed", 340.0))
			e.position += lunge_dir * step
			e._update_facing()
			lunge_run += step
			if _bite(e) or lunge_run >= float(d.get("lunge_len", 180.0)):
				set_phase(e, IDLE)
			return true
	return false


## The nearest grounded summon or standing necromancer within `reach` px of
## `e`, or null.
func _nearest_body(e: Enemy, reach: float) -> Node2D:
	var g := e.game
	var best: Node2D = null
	var best_d := reach
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING or u.airborne or u.flies:
			continue
		var dd := u.position.distance_to(e.position) - u.radius
		if dd < best_d:
			best_d = dd
			best = u
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(e.position) - pl.radius < best_d:
			best_d = pl.position.distance_to(e.position) - pl.radius
			best = pl
	return best


## THE lunge bite (the Bog Croc's, Ironjaw's): the first grounded summon or
## necromancer touching `e` takes `dmg_summon` / `dmg_player` (already scaled)
## once, tagged `source` ("" = `e`'s kind). Returns 1 for a summon, 2 for a
## necromancer, 0 when nothing was touched. `buf` is the caller's query buffer.
static func bite_first(e: Enemy, dmg_summon: float, dmg_player: float, buf: Array, source: String = "") -> int:
	var g := e.game
	var src := source if source != "" else e.kind
	g.ally_grid.query(e.position, e.radius + UnitData.MAX_BLOCK_RADIUS, buf)
	for u: SummonedUnit in buf:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING or u.airborne or u.flies:
			continue
		if u.position.distance_to(e.position) <= e.radius + u.radius + 2.0:
			g.combat.damage_unit(u, dmg_summon * e.undead_damage_mult, src, e)
			return 1
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= e.radius + pl.radius + 2.0:
			g.combat.damage_player(dmg_player, src, pl, e)
			return 2
	return 0


## The croc's lunge bite (bite_first()). Returns true when it bit.
func _bite(e: Enemy) -> bool:
	var ts := hit_scale(e)
	var hit := bite_first(e, float(d.get("lunge_damage", 14.0)) * ts, float(d.get("lunge_player", 9.0)) * ts, _buf)
	if hit == 1:
		e.game.stat_add("croc_lunge_hits", 1.0)
	elif hit == 2:
		e.game.stat_add("croc_lunge_on_you", 1.0)
	return hit > 0


## Under the tar (`on`): untargetable and ethereal; back up: neither.
func _hide(e: Enemy, on: bool) -> void:
	e.untargetable = on
	e.ethereal = on
	e.phases_obstacles = on


func is_busy() -> bool:
	return phase != IDLE


## Under the tar nothing reaches it (a hit that walks the active list rather
## than the enemy grid finds nothing to hurt).
func taken_mult(e: Enemy, source: String) -> float:
	if phase == SUBMERGED:
		return 0.0
	return super.taken_mult(e, source)


## Autopilot hint: out of the lunge's line while it rears up.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != EMERGE:
		return Vector2.ZERO
	var rel := p - e.position
	var along := rel.dot(lunge_dir)
	if along < 0.0 or along > float(d.get("lunge_len", 180.0)) + 20.0:
		return Vector2.ZERO
	var lat := rel.dot(lunge_dir.orthogonal())
	if absf(lat) > e.radius + 24.0:
		return Vector2.ZERO
	return lunge_dir.orthogonal() * (1.5 if lat >= 0.0 else -1.5)


## Under the tar only its eyes and a ripple show.
func draws_body(_e: Enemy) -> bool:
	return phase == SUBMERGED


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	if SpriteBank.draw(ci, PrimevalEnemyData.SPRITE_DIR + "bog_croc_submerged", Vector2.ZERO, false):
		return
	var w := 10.0 + 1.5 * sin(e.game.elapsed * 3.0 + float(e.think_slot))  # A slow ripple.
	SpriteBank.draw_disc(ci, Vector2.ZERO, w, Color(Palette.PRIMEVAL_TAR, 0.6))
	for s: float in [-1.0, 1.0]:
		SpriteBank.draw_disc(ci, Vector2(4.0 + s * 3.0, -2.0), 1.6, Palette.PRIMEVAL_LAVA)  # Its eyes above the tar.


## Overlay: the lunge's line while it rears (visual only, rects in world axes).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != EMERGE:
		return
	unmirror(e, ci)
	var k := clampf(phase_time / maxf(0.01, float(d.get("emerge_time", 0.55))), 0.0, 1.0)
	var s := e.radius
	while s < float(d.get("lunge_len", 180.0)):
		ci.draw_rect(Rect2(lunge_dir * s - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(Palette.PRIMEVAL_LAVA, 0.3 + 0.5 * k))
		s += MARK_STEP
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
