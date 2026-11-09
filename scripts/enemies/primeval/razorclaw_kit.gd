## RazorclawKit — the kit of the RAZORCLAW (PrimevalEnemyData "razorclaw";
## temporary Act XIV, the Age of Titans; GDD §15.0 "Packs"; proposal:
## "Razorclaw (female alpha, males in the pack) | Pack leap over the first
## blocker, rakes the nearest summon | Kill the alpha first"). Its steering is
## the pack's (PackBrain.steer(): the circle, the hold, the rush; the default
## AI while it stalks, after the rush, once a blocker holds it or once its
## alpha fell). THE ALPHA (the pack's first member) wears its own art when it
## exists (row "alpha_sprite": the female) and a bone-white mark over its head
## (visual only). Phase 2 may add the leap here. Determinism: no RNG.
class_name RazorclawKit
extends PrimevalKit

## The pack this Razorclaw runs with (PackBrain; null = none: a pack never
## formed, or the run ended).
var pack: PackBrain.Pack = null


func reset(e: Enemy, def: Dictionary) -> void:
	pack = null
	super.reset(e, def)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	pack = null


func physics(e: Enemy, delta: float) -> bool:
	return rules(e).packs.steer(e, self, delta)


## True when this Razorclaw is its pack's living alpha.
func is_alpha(e: Enemy) -> bool:
	return pack != null and pack.alpha == e and pack.alpha_gen == e.generation


func is_busy() -> bool:
	return pack != null and pack.state in [PackBrain.CIRCLE, PackBrain.HOLD]


func draws_body(e: Enemy) -> bool:
	return is_alpha(e) and SpriteBank.has(String(d.get("alpha_sprite", "")))


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	SpriteBank.draw(ci, String(d["alpha_sprite"]), Vector2.ZERO, e.flash > 0.0)


## The alpha's mark: a small bone-white chevron over its head (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if not is_alpha(e):
		return
	var top := Vector2(0.0, -e.radius * 2.2)
	ci.draw_rect(Rect2(top + Vector2(-4.0, 0.0), Vector2(8.0, 2.0)), Palette.PRIMEVAL_INK)
	ci.draw_rect(Rect2(top + Vector2(-3.0, 0.5), Vector2(6.0, 1.0)), Palette.PRIMEVAL_BONE)
	ci.draw_rect(Rect2(top + Vector2(-1.0, -2.0), Vector2(2.0, 2.0)), Palette.PRIMEVAL_BONE)
