## SiegeTowerKit — the kit of the Siege Tower (IlionEnemyData "siege_tower";
## Act IV, the Shores of Ilion, GDD §15.0 "The Shores of Ilion (Act IV phase
## 2)"; owner-approved proposal: "Siege towers roll toward the walls;
## destroying one spills its soldiers and pays a bounty"). The tower is a
## structure with the "cart" behaviour: Enemy rolls it toward its post_pos (the
## walls) at its move speed; its RULES (the garrison, the bounty, reaching the
## walls) live in IlionDirector, which placed it. This kit only adds the look of
## a rolling tower: a creak now and then (on game time) and the dust and ruts
## behind its wheels. Visual and sound only; no RNG.
class_name SiegeTowerKit
extends PantheonKit

## Seconds between two creaks of the timbers while it rolls.
const CREAK_EVERY: float = 3.5  # TUNING (not in GDD)

## Seconds until its next creak.
var _creak: float = 0.0
## Wheel turn phase (0..1) at the last redraw (redraw on a visible change).
var _wheel: int = 0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_creak = CovenantKit.first_cd(e, 1.0)
	_wheel = 0


## The creak and the dust's redraw while it rolls.
func physics(e: Enemy, delta: float) -> bool:
	_creak -= delta
	if _creak <= 0.0 and e.velocity.length_squared() > 1.0:
		_creak = CREAK_EVERY
		rules(e).play_sound("siege_creak", e.position)
	var w := int(e.game.elapsed * 4.0) % 4  # Dust puff step.
	if w != _wheel:
		_wheel = w
		e.queue_redraw()
	return false


## Ruts and dust behind the wheels (on the ground under the tower). Visual only.
func draw_under(e: Enemy) -> void:
	CovenantKit.unmirror(e)
	var back := -e.velocity.normalized() if e.velocity.length_squared() > 1.0 else Vector2.DOWN  # Behind it.
	var side := Vector2(-back.y, back.x) * e.radius * 0.6  # Between the wheels.
	for s: float in [-1.0, 1.0]:
		e.draw_line(side * s, side * s + back * e.radius * 2.6, Color(Palette.PANTHEON_BRONZE_INK, 0.35), 3.0)
	for i in 3:
		var k := float((i + _wheel) % 4) / 4.0  # 0..1 along the trail.
		e.draw_circle(back * e.radius * (1.0 + 1.6 * k) + side * (0.5 - k), 4.0 + 5.0 * k, Color(Palette.PANTHEON_MARBLE_DARK, 0.22 * (1.0 - k)))
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
