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
	if SpriteBank.has("pickups/chest"):
		# Sprite art over the code chest's shadow and pulsing gold glow (the ChestPanel reveal stays code-drawn).
		var s := ChestData.SIZE  # Half-width of the code chest (px), sizes the shadow and glow.
		var pulse := 0.5 + 0.5 * sin(age * 4.0)  # 0..1 glow pulse, as in PowerupGlyphs.draw_chest().
		draw_circle(Vector2(0, s * 0.7), s * 1.1, Color(0, 0, 0, 0.35))
		draw_circle(Vector2.ZERO, s * (1.5 + 0.15 * pulse), Color(Palette.GOLD, 0.10 + 0.08 * pulse))
		SpriteBank.draw_flat(self, "pickups/chest", Vector2.ZERO, 0.0)
		return
	PowerupGlyphs.draw_chest(self, Vector2.ZERO, ChestData.SIZE, age, 0.0)
