## ArtCheckStand: one unit on an art-check panel (tools/art_check/art_check.gd).
## Draws through the game's own drawing call (`draw_fn`, e.g. SpriteBank.draw
## or a Glyphs function) at its origin. Not part of the game (tools/ is
## ignored by Godot; art_check.py copies it into a scratch project).
class_name ArtCheckStand
extends Node2D

## Drawing call: func(ci: CanvasItem, o: Vector2) -> void, o = the unit's origin (local 0, 0).
var draw_fn: Callable


func _draw() -> void:
	if draw_fn.is_valid():
		draw_fn.call(self, Vector2.ZERO)
