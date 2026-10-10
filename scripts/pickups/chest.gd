## Chest — one pooled treasure chest lying in the world (ChestData). Pure
## data + drawing (PowerupGlyphs.draw_chest: a gold-banded Covenant
## reliquary with a pulsing glow); ChestManager spawns, collects and pools it.
class_name Chest
extends Node2D

## True while lying in the world (false = pooled).
var active: bool = false
## Seconds since it was dropped (drives the glow animation).
var age: float = 0.0


## Activates the chest at `pos`.
func setup(pos: Vector2) -> void:
	position = pos
	age = 0.0
	active = true
	visible = true
	queue_redraw()


## Returns the chest to the pool.
func deactivate() -> void:
	active = false
	visible = false


## Advances the glow animation.
func tick(delta: float) -> void:
	age += delta
	queue_redraw()


func _draw() -> void:
	PowerupGlyphs.draw_chest(self, Vector2.ZERO, ChestData.SIZE, age, 0.0)
