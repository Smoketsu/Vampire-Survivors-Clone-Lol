## UnitLayer: one drawing layer of a unit (its body, or the overlays above
## it), a child Node2D whose _draw() calls back into the unit with itself as
## the canvas. Splitting a unit into layers lets UnitMotion move the body
## with a node transform (no redraw per frame, so it costs nothing on the
## cached draw lists) while the ground effects under it and the HP bar,
## shields and status marks over it stay put. The unit redraws its layers
## whenever it redraws itself (its own _draw() queues them). Purely visual.
##
## Walk cycles (WalkData): a body layer also carries the walk frame to show.
## SpriteBank.draw() reads `walk_frame` when it draws a sprite that has a walk
## strip on this layer and reports the strip's frame count in `walk_count`;
## UnitMotion picks the frame from the step phase and redraws the layer only
## when the frame changes. No unit or glyph code needs to know about it.
## Idle strips (IdleData) work the same way through `idle_frame` / `idle_count`
## (the breathing loop of a standing unit; a walk frame wins over it).
class_name UnitLayer
extends Node2D

## Draw callback of the owning unit: func(ci: CanvasItem) -> void, drawing
## this layer's content on `ci` (this node). Empty = draws nothing.
var draw_fn: Callable
## Walk frame to draw (0..walk_count - 1), or -1 for the still sprite
## (standing, or a layer that never walks: overlays, death dissolves).
var walk_frame: int = -1
## Frames in the walk strip of the sprite this layer drew last (0 = none: no
## strip, a glyph, or not drawn yet). Set by SpriteBank.draw() during _draw().
var walk_count: int = 0
## Idle frame to draw (0..idle_count - 1), or -1 for the still sprite (walking,
## frozen, dead, dashing, airborne, or a layer that never idles).
var idle_frame: int = -1
## Frames in the idle strip of the sprite this layer drew last (0 = none). Set
## by SpriteBank.draw() during _draw(), like walk_count.
var idle_count: int = 0


func _draw() -> void:
	walk_count = 0
	idle_count = 0
	if draw_fn.is_valid():
		draw_fn.call(self)
