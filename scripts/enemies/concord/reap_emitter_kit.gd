## ReapEmitterKit — the kit of a Reaping Emitter (ArkEnemyData "reap_emitter";
## Act IX, the Harvester's Reaping; GDD §15.0 "The Harvester (Act IX)";
## owner-approved proposal: "The Reaping: it opens a tractor beam over the
## whole ring, and every summon starts rising. Four beam emitters around the
## arena must be destroyed before the army is gone"). A STRUCTURE: a gunmetal
## pylon with a plasma lens. BossHarvester places four (or --spawn= drops one
## to test). Every HarvesterData lift_every s it picks the nearest liftable
## summon within lift_range px (Abduction.pick(), deterministic) and LIFTS it
## through Abduction.lift(emitter, u) (THE lift: the summon rises to the
## emitter and is taken after the hold unless the emitter falls). With no
## room under the cap (the Harvester sets Abduction.uncapped for the Reaping)
## the attempt is refused and counted by Abduction. Destroyed, it drops what
## it holds: the rescue (ConcordKit.on_deactivate() -> ConcordRules.note_gone()
## -> Abduction.release_all()). ANCHORED applies as usual: a hit on it calls
## Abduction.on_saucer_hit() (taken_mult(); the passive's hook breaks its
## holds). It never heals on turf.
## Determinism: no RNG (its first lift staggered by its think slot). Stats:
## reap_emitter_lifts, reap_emitters_down.
class_name ReapEmitterKit
extends ConcordKit

## Seconds until its next lift.
var lift_cd: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.is_objective = true  # It stands until broken (never recycled).
	lift_cd = 0.6 + float(e.think_slot % 4) * 0.5  # TUNING (not in GDD) the four emitters start out of step


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	e.game.stat_add("reap_emitters_down", 1.0)
	e.game.effects.ring(e.position, 46.0, Palette.CONCORD_PLASMA, 0.45)
	rules(e).play_sound("saucer_down", e.position, 0.2)


## Every lift_every s: the nearest liftable summon rises (THE lift). Always
## false: the structure's own step holds it still.
func physics(e: Enemy, delta: float) -> bool:
	lift_cd -= delta
	if lift_cd > 0.0:
		return false
	var hd := HarvesterData.BOSS
	var ab := rules(e).abduction
	lift_cd = float(hd["lift_every"])
	if not ab.has_room():
		e.game.stat_add("abduction_refused_cap", 1.0)
		return false
	var u := ab.pick(e.position, float(hd["lift_range"]))
	if u != null and ab.lift(e, u):
		e.game.stat_add("reap_emitter_lifts", 1.0)
		rules(e).play_sound("tractor_beam", e.position, 0.5)
	return false


## A hit on it: Anchored's hook (a no-op while the passive is not owned).
func taken_mult(e: Enemy, source: String) -> float:
	if e.game.concord != null:
		e.game.concord.abduction.on_saucer_hit(e)
	return super.taken_mult(e, source)


## The tractor beam from its lens to every summon it holds (textures).
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	var g := e.game
	if g.concord == null:
		return
	var lens := Vector2(0.0, -e.radius * 1.6)
	for h: Array in g.concord.abduction.holds:
		if h[0] == e:
			var u := h[2] as SummonedUnit
			ConcordGlyphs.draw_tractor(e, lens, u.position - e.position, float(ConcordRulesData.ABDUCTION["cone_width"]), 1.0, g.elapsed, CourtGlyphs.unmirror_xf(e))
			e.draw_set_transform_matrix(Transform2D.IDENTITY)


## Its lens pulses (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var a := 0.45 + 0.3 * sin(e.game.elapsed * 6.0 + float(e.think_slot))
	SpriteBank.draw_disc(ci, Vector2(0.0, -e.radius * 1.6), e.radius * 0.35, Color(Palette.CONCORD_PLASMA, a))
