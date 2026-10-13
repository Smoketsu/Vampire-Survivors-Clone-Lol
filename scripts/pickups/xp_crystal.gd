## XpCrystal — one pooled experience crystal dropped by a dead enemy
## (GDD §3 "Enemies drop XP crystals"). Pure data + drawing; XpManager handles
## magnet movement and collection.
class_name XpCrystal
extends Node2D

## True while lying in the world (false = pooled).
var active: bool = false
## XP granted on collection.
var value: int = 1
## True once inside the pickup radius: it then flies to the player.
var magnet: bool = false
## Current fly speed in px/s while magnetised.
var speed: float = 0.0


## Activates the crystal at `pos` worth `p_value` XP.
func setup(pos: Vector2, p_value: int) -> void:
	position = pos
	value = p_value
	magnet = false
	speed = 0.0
	active = true
	visible = true
	queue_redraw()


func _draw() -> void:
	# Bigger / bluer crystals are worth more.
	var s := 3.5 + minf(float(value), 10.0) * 0.45
	var col := Palette.NECRO_GREEN if value < 3 else (Palette.COLD_BLUE if value < 8 else Palette.VIOLET)
	# Sprite art per value tier (same thresholds as the colours), over the same faint glow.
	var key := "pickups/xp_crystal_s" if value < 3 else ("pickups/xp_crystal_m" if value < 8 else "pickups/xp_crystal_l")
	if SpriteBank.has(key):
		draw_circle(Vector2.ZERO, s * 1.4, Color(col, 0.15))
		SpriteBank.draw_flat(self, key, Vector2.ZERO, 0.0)
		return
	var pts := PackedVector2Array([Vector2(0, -s * 1.3), Vector2(s, 0), Vector2(0, s * 1.3), Vector2(-s, 0)])
	draw_circle(Vector2.ZERO, s * 1.4, Color(col, 0.15))
	draw_colored_polygon(pts, col)
	draw_line(Vector2(0, -s * 1.1), Vector2(s * 0.4, 0), Color(1, 1, 1, 0.6), 1.0)
