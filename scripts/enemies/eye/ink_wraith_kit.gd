## InkWraithKit — the Ink Wraith (ArchiveEnemyData "ink_wraith"; Act II, GDD
## §15.0 "Act II: the Hollow Archive"): a flanker that slips through shelves
## and obstacles (its row's "phases": Arena.resolve_all() skips it) and comes
## out of ink. It walks at the necromancer through the shared melee AI; the
## kit adds the ink:
##   * Rising  — a new Wraith rises out of the ink nearest the necromancer
##               (an ink pool or an Ink Wells well; ArchiveHazards.ink_toward())
##               when one lies within spawn_rise_range px of him and closer
##               than its spawn point, instead of walking in from the ring. It
##               stands still for rise_time s while it rises (the telegraph).
##   * Diving  — every dive_cooldown s, when an ink lies within dive_range px
##               of him and at least dive_gain px nearer to him than the
##               Wraith, it sinks (sink_time s), crosses under the floor and
##               rises out of that ink (rise_time s).
## While it sinks and rises it is drawn fading in and out (Enemy.modulate,
## visual only) and can still be hit. Stats: ink_wraith_rises (out of ink at
## spawn), ink_wraith_dives.
## Determinism: no RNG; first cooldowns staggered by the think slot.
class_name InkWraithKit
extends CovenantKit

## Phase: rising out of the ink.
const RISE: int = 1
## Phase: sinking into the ink.
const SINK: int = 2
## Lowest alpha of the fading body (and its ripple) while it sinks or rises
## (look only: it stays readable, and hittable, under the ink).
const MIN_ALPHA: float = 0.3

## Seconds until the next dive may start.
var dive_cd: float = 0.0
## Where the current dive comes up.
var dive_to: Vector2 = Vector2.ZERO


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	dive_cd = first_cd(e, float(d["dive_first"]))
	e.modulate.a = 1.0
	var at := _ink_near_player(e, float(d["spawn_rise_range"]), 0.0)  # Ink to rise from (INF = none).
	if at != Vector2.INF:
		e.position = at
		e.game.stat_add("ink_wraith_rises", 1.0)
		set_phase(e, RISE)
		e.modulate.a = MIN_ALPHA


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.modulate.a = 1.0


## Starts a dive when an ink lies on the way.
func think(e: Enemy) -> void:
	if phase != IDLE or dive_cd > 0.0:
		return
	var to := _ink_near_player(e, float(d["dive_range"]), float(d["dive_gain"]))
	if to == Vector2.INF:
		dive_cd = 1.0  # No ink on the way: look again in a second (not a balance number).
		return
	dive_to = to
	dive_cd = float(d["dive_cooldown"])
	e.game.stat_add("ink_wraith_dives", 1.0)
	set_phase(e, SINK)


func physics(e: Enemy, delta: float) -> bool:
	dive_cd -= delta
	if phase == IDLE:
		return false
	phase_time += delta
	hold(e)
	match phase:
		SINK:
			var k := phase_time / maxf(0.05, float(d["sink_time"]))  # 0 -> 1.
			e.modulate.a = clampf(1.0 - k, MIN_ALPHA, 1.0)
			if k >= 1.0:
				e.position = dive_to
				set_phase(e, RISE)
		RISE:
			var k := phase_time / maxf(0.05, float(d["rise_time"]))  # 0 -> 1.
			e.modulate.a = clampf(k, MIN_ALPHA, 1.0)
			if k >= 1.0:
				e.modulate.a = 1.0
				set_phase(e, IDLE)
	return true


## The ink nearest the necromancer within `reach` px of him that is at least
## `gain` px nearer to him than the Wraith (Vector2.INF when none; ink exists
## only once an Archive hazard or the Ink Wells exist).
func _ink_near_player(e: Enemy, reach: float, gain: float) -> Vector2:
	var g := e.game
	var hz := g.enemies.archive_haz  # Ink pools (null until an Archive hazard exists).
	if hz != null:
		return hz.ink_toward(g.player.position, e.position, reach, gain)
	if g.enemies.archive != null:
		var best := Vector2.INF
		var best_d := reach
		var base := e.position.distance_to(g.player.position)
		for w: Vector2 in g.enemies.archive.wells_near(g.player.position, reach):
			var dist := w.distance_to(g.player.position)
			if dist < best_d and base - dist >= gain:
				best_d = dist
				best = w
		return best
	return Vector2.INF


## An ink ripple at its feet while it sinks or rises.
func draw_under(e: Enemy) -> void:
	if phase != IDLE:
		ArchiveGlyphs.draw_ink_ripple(e, e.radius, phase_time)
