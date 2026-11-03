## VraskHunterKit — the kit of the Vrask Hunter (ConcordEnemyData
## "vrask_hunter"; Act IX, the Vrask; GDD §15.0 "Act IX foundation (phase
## 1)"; owner-approved proposal: "Vrask Hunter | Vrask | Elite | Cloaked (a
## shimmer while it moves); a three-dot plasma caster lock, then a shot | Area
## damage reveals it"). A reptilian hunter (male) with a shoulder caster:
##   * THE CLOAK (row "cloak"): while it moves at min_speed px/s or more and is
##     not revealed, it is CLOAKED: drawn as a shimmer (its sprite at the
##     cloak's alpha: draws_body() / draw_body()), and a summon's or a hazard's
##     hit deals cloaked_taken of itself (taken_mult(), the kit's one read in
##     Enemy.damage_taken_mult()). A SPELL hit (HundredShadowsData
##     .is_spell_source(): "area damage reveals it") lands in full and REVEALS
##     it for reveal_time s; so does its own shot. It is uncloaked while it
##     stands still to aim.
##   * THE LOCK: its ranged attack is a "lock" beam (BEAM_STYLES: three red dots
##     on its target for the aim, then a 0.15 s pulse) through
##     ConcordKit.fire_ranged(), the one beam path.
## Determinism: no RNG (the cloak reads its own velocity and game time).
## Stats: vrask_cloak_cut (hits cut while cloaked), vrask_reveals.
class_name VraskHunterKit
extends ConcordKit

## True while cloaked (moving, not revealed).
var cloaked: bool = false
## Game time (s) until which it is revealed (a spell hit, its own shot).
var revealed_until: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cloaked = false
	revealed_until = 0.0


## Per tick: the beam holds it still (ConcordKit); otherwise its cloak follows
## its last step's speed and the reveal.
func physics(e: Enemy, delta: float) -> bool:
	if super.physics(e, delta):
		_set_cloak(e, false)
		return true
	var c := cloak()
	var moving := e.velocity.length() >= float(c.get("min_speed", 8.0))
	_set_cloak(e, not c.is_empty() and moving and e.game.elapsed >= revealed_until)
	return false


## Switches the cloak (redraws on a change).
func _set_cloak(e: Enemy, on: bool) -> void:
	if on != cloaked:
		cloaked = on
		e.queue_redraw()


## Its shot reveals it.
func on_beam_fired(e: Enemy) -> void:
	revealed_until = maxf(revealed_until, e.game.elapsed + float(cloak().get("reveal_time", 2.0)))
	_set_cloak(e, false)


## The cloak (see the header): a spell hit reveals it and lands in full; any
## other hit while cloaked deals cloaked_taken.
func taken_mult(e: Enemy, source: String) -> float:
	var m := super.taken_mult(e, source)
	if cloak().is_empty():
		return m
	var g := e.game
	if HundredShadowsData.is_spell_source(source):
		if cloaked:
			g.stat_add("vrask_reveals", 1.0)
		revealed_until = maxf(revealed_until, g.elapsed + float(cloak().get("reveal_time", 2.0)))
		_set_cloak(e, false)
		return m
	if cloaked:
		g.stat_add("vrask_cloak_cut", 1.0)
		return m * float(cloak().get("cloaked_taken", 0.5))
	return m


## While cloaked it draws its own body: the shimmer.
func draws_body(_e: Enemy) -> bool:
	return cloaked


## The shimmer: its sprite at the cloak's alpha (a faint teal ripple without art).
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var a := float(cloak().get("alpha", 0.22))
	var wob := 0.75 + 0.25 * sin(e.game.elapsed * 9.0 + float(e.think_slot))  # The shimmer ripples.
	if SpriteBank.draw(ci, e.motion_sprite_key(), Vector2.ZERO, e.flash > 0.0, Color(1.0, 1.0, 1.0, a * wob)):
		return
	SpriteBank.draw_disc(ci, Vector2(0.0, -e.radius * 0.4), e.radius * 1.1, Color(Palette.CONCORD_VRASK, a * 0.6 * wob))
	SpriteBank.draw_disc(ci, Vector2(0.0, -e.radius * 0.4), e.radius * 0.6, Color(Palette.CONCORD_HULL, a * 0.5 * wob))
