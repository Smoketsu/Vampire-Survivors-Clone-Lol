## Powerup — one pooled power-up drop lying in the world (PowerupData).
## Pure data + drawing; PowerupManager handles spawning, ageing, pickup and
## pooling. Drawn in code by PowerupGlyphs as a dark token with a pulsing
## ring and the power-up's icon; it blinks during its last BLINK_TIME s.
class_name Powerup
extends Node2D

## True while lying in the world (false = pooled).
var active: bool = false
## Power-up id (PowerupData.ORDER).
var kind: String = ""
## Seconds left before it despawns.
var life: float = 0.0
## Seconds since it was dropped (drives the bob and pulse animation).
var age: float = 0.0
## Spawn order number (the oldest live drop is replaced first).
var serial: int = 0


## Activates the drop as power-up `p_kind` at `pos`.
func setup(p_kind: String, pos: Vector2, p_serial: int) -> void:
	kind = p_kind
	position = pos
	life = PowerupData.LIFETIME
	age = 0.0
	serial = p_serial
	active = true
	visible = true
	queue_redraw()


## Returns the drop to the pool.
func deactivate() -> void:
	active = false
	visible = false


## Ages the drop; returns false once it has expired.
func tick(delta: float) -> bool:
	life -= delta
	age += delta
	queue_redraw()
	return life > 0.0


func _draw() -> void:
	# Blink in the final seconds: hidden for part of every 0.25 s cycle.
	if life < PowerupData.BLINK_TIME and fmod(age, 0.25) < 0.1:
		return
	var bob := sin(age * 3.0) * 1.5  # Small vertical float (px).
	PowerupGlyphs.draw_token(self, kind, Vector2(0, bob), PowerupData.TOKEN_RADIUS, age)
