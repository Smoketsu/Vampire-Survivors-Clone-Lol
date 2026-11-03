## PrismKit — the kit of the Star-Seer (ConcordEnemyData "prism"; Act IX, the
## Luminous; GDD §15.0 "Act IX foundation (phase 1)"; owner-approved proposal:
## "Prism | Luminous | Support (figure style, the Star-Seer) | Splits any beam
## that passes through it into three | Kill it before the beams line up"). A
## woman of the Luminous (figure style; an opaque, fully covering gown) with a
## floating prism. She fires nothing (ConcordKit.fire_ranged(): no "beam"
## row); THE SPLIT is ConcordBeams' (a beam whose line passes through her ends
## there and splits into three; ConcordRules keeps the prism list from her
## row's "prism" flag). This kit only draws her prism's glint over her
## (drawing only).
## Determinism: no RNG.
class_name PrismKit
extends ConcordKit


## Her floating prism's glint over her head, turning on game time (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var t := e.game.elapsed
	var at := Vector2(cos(t * 1.7) * e.radius * 0.5, e.marker_y(-e.radius * 2.2) + sin(t * 2.3) * 2.0)
	SpriteBank.draw_disc(ci, at, 3.0, Color(Palette.CONCORD_LUMEN, 0.55 + 0.35 * sin(t * 4.0)))
