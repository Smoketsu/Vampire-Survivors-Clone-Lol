## LegionaryKit — the kit of the Legionary (IlionEnemyData "legionary"; Act IV,
## the Shores of Ilion, GDD §15.0 "The Shores of Ilion (Act IV phase 2)";
## owner-approved proposal: "Scutum and gladius; locks the testudo against
## arrows and volleys from above"). Shoulder to shoulder with two more phalanx
## bodies facing the same way it LOCKS SHIELDS like the Hoplite (the Phalanx
## node does the test, the pace and the front line). Its row's "testudo" makes
## a locked Legionary also roof its line: the Phalanx's front path
## (Phalanx.directed_hit_mult(), the one place) cuts every shot from outside
## its rear cone and every arcing hit from above. This kit only draws the
## raised scuta of the roof over a locked Legionary. BRONZE: Zeus's lightning
## chains to it. No RNG.
class_name LegionaryKit
extends PantheonKit

## True when the roof was drawn at the last redraw (redraw when it changes).
var _roofed: bool = false


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_roofed = false


## The shared facing; redraws when the testudo closes or opens.
func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	if locked != _roofed:
		_roofed = locked
		e.queue_redraw()
	return false


## The testudo's roof while locked: a raised Aegean scutum over the head with
## its bronze rim, tilted along the line (perpendicular to the facing).
## Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if not locked:
		return
	CovenantKit.unmirror(e, ci)
	var top := Vector2(0.0, e.marker_y(-e.radius * 2.4) + 4.0)  # Over the helmet crest (px).
	var side := Vector2(-facing.y, facing.x)  # Along the line.
	if absf(side.x) < 0.3:
		side = Vector2(1.0, 0.0)  # A line running up the screen still shows a flat roof.
	side = side.normalized() * (e.radius + 3.0)
	ci.draw_line(top - side, top + side, PantheonGlyphs.INK, 7.0)
	ci.draw_line(top - side, top + side, Palette.PANTHEON_AEGEAN, 4.0)
	ci.draw_line(top - side + Vector2(0, -2), top + side + Vector2(0, -2), Palette.PANTHEON_BRONZE_LIGHT, 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
