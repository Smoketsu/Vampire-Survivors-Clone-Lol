## SaucerKit — the kit of the Saucer (ConcordEnemyData "saucer"; Act IX, the
## Harvesters; GDD §15.0 "Abduction"; owner-approved proposal: "Saucer |
## Harvester | Elite, flying | Abduction | Gargoyles, Archers, spells"). A
## white-hulled saucer, a FLIER (row "flies": no summon body-blocks it; in
## flight a grounded melee blow finds only air, ConcordKit.taken_mult()). This
## kit owns every tick (it never strikes):
##   * HOVER: it flies to hover_radius px from the nearest standing
##     necromancer (over the Bone Ring's edge) and circles there at hover_turn
##     rad/s (its side from its think slot, no RNG).
##   * THE TRACTOR BEAM: every lift_every s, when Abduction has room, it picks
##     the nearest liftable summon within lift_range px (Abduction.pick(),
##     deterministic), shows a green TRACTOR CONE on the ground for ABDUCTION
##     windup s (it hangs still over the ring) and lifts it through THE ONE
##     CALL, Abduction.lift(). A target that dies, flies off or is held
##     elsewhere during the windup cancels it. With no room (the cap) the
##     attempt is refused and counted (Abduction), and it looks again after
##     BEAMS retry s.
##   * THE HOLD: while it holds a summon (Abduction.holding()) it drifts slowly
##     outward (carry_drift px/s) with the summon hanging under it; Abduction
##     carries the summon, drops it if the saucer falls (the rescue), or takes
##     it after the hold.
##   * SHOT DOWN: its death counts for the report (abduction_saucers_down) and
##     plays the crash; Abduction's rescue drops what it held
##     (ConcordKit.on_deactivate() -> ConcordRules.note_gone()).
## Determinism: no RNG, no instance ids. Stats: saucer_windups,
## saucer_windups_lost, abduction_saucers_down.
class_name SaucerKit
extends ConcordKit

## Phase: the tractor cone shows over its chosen summon.
const WINDUP: int = 1

## Seconds until it may try the next lift.
var lift_cd: float = 0.0
## The summon its tractor cone marks during the windup (null otherwise).
var mark: SummonedUnit = null
## Pool generation of the marked summon (stale guard).
var mark_gen: int = 0
## Its circling side (+1 / -1, from its think slot).
var side: float = 1.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	lift_cd = first_cd(e, float(d.get("lift_every", 7.0)) * 0.5)
	mark = null
	mark_gen = 0
	side = 1.0 if e.think_slot % 2 == 0 else -1.0


func on_deactivate(e: Enemy) -> void:
	mark = null
	super.on_deactivate(e)


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	e.game.stat_add("abduction_saucers_down", 1.0)
	rules(e).play_sound("saucer_down", e.position, 0.3)
	e.game.effects.ring(e.position, e.radius * 2.0, Palette.CONCORD_PLASMA, 0.35)


## Every tick (see the header). Always true: it flies itself.
func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	var ab := rules(e).abduction
	var pl := g.nearest_player(e.position)
	lift_cd -= delta
	if phase == WINDUP:
		phase_time += delta
		hold(e)
		e.queue_redraw()  # The cone grows.
		if mark == null or not mark.active or mark.generation != mark_gen or not ab.liftable(mark):
			g.stat_add("saucer_windups_lost", 1.0)
			_end_windup(e, float(ConcordRulesData.BEAMS["retry"]))
			return true
		if phase_time >= float(ab.cfg["windup"]):
			var ok := ab.lift(e, mark)
			_end_windup(e, float(d.get("lift_every", 7.0)) if ok else float(ConcordRulesData.BEAMS["retry"]))
		return true
	if ab.holding(e):
		var out := e.position - pl.position
		var dir := out.normalized() if out.length() > 1.0 else Vector2.RIGHT
		e.velocity = dir * float(d.get("carry_drift", 10.0))
		e.position += e.velocity * delta
		e._update_facing()
		e.queue_redraw()  # The beam to the held summon.
		return true
	_hover(e, pl, delta)
	if lift_cd <= 0.0 and e.position.distance_to(pl.position) <= float(d.get("hover_radius", 170.0)) + 60.0:
		if not ab.has_room():
			g.stat_add("abduction_refused_cap", 1.0)
			lift_cd = float(ConcordRulesData.BEAMS["retry"]) * 2.0
			return true
		var u := ab.pick(e.position, float(d.get("lift_range", 150.0)))
		if u == null:
			lift_cd = float(ConcordRulesData.BEAMS["retry"])
			return true
		mark = u
		mark_gen = u.generation
		set_phase(e, WINDUP)
		hold(e)
		g.stat_add("saucer_windups", 1.0)
		rules(e).play_sound("tractor_beam", e.position, 0.5)
	return true


## Flies toward its post hover_radius px from `pl`, circling at hover_turn rad/s.
func _hover(e: Enemy, pl: Necromancer, delta: float) -> void:
	var rel := e.position - pl.position
	var ang := rel.angle() if rel.length() > 1.0 else float(e.think_slot)
	ang += float(d.get("hover_turn", 0.25)) * side * delta
	var post := pl.position + Vector2.from_angle(ang) * float(d.get("hover_radius", 170.0))
	var to := post - e.position
	var spd := e.move_speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
	var step := minf(to.length(), spd * delta)
	e.velocity = to.normalized() * spd if to.length() > 1.0 else Vector2.ZERO
	if step > 0.0:
		e.position += to.normalized() * step
	e._update_facing()


## Ends the windup and waits `cd` s before the next try.
func _end_windup(e: Enemy, cd: float) -> void:
	mark = null
	lift_cd = cd
	set_phase(e, IDLE)


func is_busy() -> bool:
	return true  # It flies itself (the stuck check skips it).


## Its shadow (ConcordKit), then the green tractor cone on its marked summon
## during the windup, or its beam down to the summon it holds (textures, in
## world axes).
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	var g := e.game
	var foot := Vector2.INF  # World point the cone stands on.
	var k := 1.0  # Cone strength 0..1.
	if phase == WINDUP and mark != null and mark.active:
		foot = mark.position
		k = clampf(phase_time / maxf(float(rules(e).abduction.cfg["windup"]), 0.01), 0.0, 1.0)
	elif g.concord != null:
		for h: Array in g.concord.abduction.holds:
			if h[0] == e:
				foot = (h[2] as SummonedUnit).position
				break
	if foot == Vector2.INF:
		return
	ConcordGlyphs.draw_tractor(e, Vector2.ZERO, foot - e.position, float(ConcordRulesData.ABDUCTION["cone_width"]), k, g.elapsed, CourtGlyphs.unmirror_xf(e))
	e.draw_set_transform_matrix(Transform2D.IDENTITY)
