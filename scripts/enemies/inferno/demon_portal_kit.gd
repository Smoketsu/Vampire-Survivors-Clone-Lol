## DemonPortalKit — the kit of the demon portal (InfernoEnemyData
## "demon_portal"; Act VI, GDD §15.0 "Portals"). The portal is a structure (no
## AI, never recycled); its RULE lives in DemonPortals (the squads it pours, its
## sealing ring, the Soul Ash bounty; a portal spawned any other way is adopted
## there on activation). This kit only draws the looping glow in
## code over its sprite (inferno/demon_portal, or InfernoGlyphs' ring when the
## art is missing): a pulsing lava glow under it and charm-pink motes swirling
## into its centre, on game time, redrawn about 12 times a second. A DEMON: the
## pits spare it. Visual only.
class_name DemonPortalKit
extends InfernoKit

## Motes of the swirl.
const MOTES: int = 6
## Last swirl frame drawn (redraw only when it changes).
var _frame: int = -1


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_frame = -1
	rules(e).portals.adopt(e)  # A portal spawned outside DemonPortals.open() still pours and seals.


## Redraws when the swirl moves (about 12 times a second).
func physics(e: Enemy, _delta: float) -> bool:
	var f := int(e.game.elapsed * 12.0)
	if f != _frame:
		_frame = f
		e.queue_redraw()
	return false


## The lava glow under the portal, pulsing. Visual only.
func draw_under(e: Enemy) -> void:
	var t := e.game.elapsed
	var pulse := 0.5 + 0.5 * sin(t * 3.0)  # 0..1.
	SpriteBank.draw_disc(e, Vector2.ZERO, e.radius * (1.6 + 0.25 * pulse), Color(Palette.INFERNO_LAVA, 0.18 + 0.12 * pulse))


## The charm-pink motes swirling into its centre. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	unmirror(e, ci)
	var t := e.game.elapsed
	for i in MOTES:
		var k := fmod(t * 0.6 + float(i) / float(MOTES), 1.0)  # 0 at the rim .. 1 in the centre.
		var a := t * 2.2 + TAU * float(i) / float(MOTES) + k * 3.0
		var p := Vector2.from_angle(a) * e.radius * (1.0 - k) * 0.9 + Vector2(0.0, -e.radius * 0.3)
		SpriteBank.draw_disc(ci, p, 1.8, Color(Palette.INFERNO_CHARM_LIGHT if i % 2 == 0 else Palette.INFERNO_CHARM, 0.9 * (1.0 - k * 0.6)))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
