## UnitLayer: one drawing layer of a unit (its body, or the overlays above
## it), a child Node2D whose _draw() calls back into the unit with itself as
## the canvas. Splitting a unit into layers lets UnitMotion move the body
## with a node transform (no redraw per frame, so it costs nothing on the
## cached draw lists) while the ground effects under it and the HP bar,
## shields and status marks over it stay put. The unit redraws its layers
## whenever it redraws itself (its own _draw() queues them). Purely visual.
class_name UnitLayer
extends Node2D

## Draw callback of the owning unit: func(ci: CanvasItem) -> void, drawing
## this layer's content on `ci` (this node). Empty = draws nothing.
var draw_fn: Callable


func _draw() -> void:
	if draw_fn.is_valid():
		draw_fn.call(self)
