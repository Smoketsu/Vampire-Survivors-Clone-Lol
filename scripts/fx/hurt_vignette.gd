## HurtVignette: the red screen-edge flash when the necromancer is hurt.
## Drawn as a ring of quads with per-vertex colours (opaque red at the screen
## edge fading to fully transparent inside), instead of a gradient texture: on
## the GL Compatibility renderer the texture's transparent centre could render
## black and hide the whole battlefield. Vertex-colour blending is reliable on
## every renderer. Juice sets `strength` and calls queue_redraw().
class_name HurtVignette
extends Control

## Number of segments around the ellipse (smoothness).
const SEGMENTS: int = 48
## Inner edge of the red band, as a fraction of the half-diagonal (fully transparent inside).
const INNER: float = 0.55
## Outer edge, as a fraction of the half-diagonal (beyond the screen corners).
const OUTER: float = 1.05
## Edge colour at full strength (crimson, alpha = peak opacity).
const EDGE_COLOR: Color = Color(0.6, 0.0, 0.05, 0.85)

## Current strength 0..1 (multiplies the edge opacity).
var strength: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if strength <= 0.0:
		return
	var c := size * 0.5  # Screen centre.
	var r := size * 0.5 * sqrt(2.0)  # Half-extents that reach past the corners.
	var edge := Color(EDGE_COLOR, EDGE_COLOR.a * strength)  # Opaque-ish outer colour.
	var clear := Color(EDGE_COLOR, 0.0)  # Transparent inner colour.
	for i in SEGMENTS:
		var a0 := TAU * float(i) / float(SEGMENTS)  # Segment start angle.
		var a1 := TAU * float(i + 1) / float(SEGMENTS)  # Segment end angle.
		var d0 := Vector2(cos(a0), sin(a0)) * r  # Direction scaled to the ellipse.
		var d1 := Vector2(cos(a1), sin(a1)) * r
		var quad := PackedVector2Array([c + d0 * INNER, c + d1 * INNER, c + d1 * OUTER, c + d0 * OUTER])
		draw_polygon(quad, PackedColorArray([clear, clear, edge, edge]))
