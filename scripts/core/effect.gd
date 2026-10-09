## Effect — one pooled, purely cosmetic visual effect (death pop, slash, heal
## beam, blast ring, spawn ring) or a boss telegraph (warning circle / lane).
## Effects never apply gameplay; the system that spawns a telegraph keeps its
## own timer and applies damage itself, the Effect just shows the warning for
## the same duration. Managed and pooled by EffectManager.
class_name Effect
extends Node2D

## What to draw. ABYSS is the imploding vortex of Abyssal Detonation.
enum Kind { POP, SLASH, RING, BEAM, SPAWN, TELEGRAPH_CIRCLE, TELEGRAPH_LINE, IMPACT, ABYSS }

## Current effect kind.
var kind: Kind = Kind.POP
## True while the effect is playing (false = sitting in the pool).
var active: bool = false
## Seconds since the effect started.
var t: float = 0.0
## Total lifetime in seconds.
var duration: float = 0.3
## Main colour.
var color: Color = Color.WHITE
## Size parameter in px (radius for circles, length for slashes).
var size: float = 10.0
## Secondary vector: BEAM/TELEGRAPH_LINE end point relative to `position`;
## SLASH facing direction.
var vec: Vector2 = Vector2.RIGHT
## Line width in px (beams, telegraph lanes).
var width: float = 2.0


## Starts the effect. Called by EffectManager after taking it from the pool.
func start(p_kind: Kind, pos: Vector2, p_color: Color, p_size: float, p_duration: float, p_vec: Vector2 = Vector2.RIGHT, p_width: float = 2.0) -> void:
	kind = p_kind
	position = pos
	color = p_color
	size = p_size
	duration = maxf(p_duration, 0.01)
	vec = p_vec
	width = p_width
	t = 0.0
	active = true
	visible = true
	# Telegraphs sit under bodies, everything else above.
	z_index = -5 if (kind == Kind.TELEGRAPH_CIRCLE or kind == Kind.TELEGRAPH_LINE) else 5
	queue_redraw()


## Advances the animation; returns false once finished.
func step(delta: float) -> bool:
	t += delta
	if t >= duration:
		active = false
		visible = false
		return false
	queue_redraw()
	return true


func _draw() -> void:
	var k := clampf(t / duration, 0.0, 1.0)
	var fade := 1.0 - k
	match kind:
		Kind.POP:
			# Expanding ring + four bone shards flying outward (cosmetic corpse).
			draw_arc(Vector2.ZERO, size * (0.5 + k), 0.0, TAU, 16, Color(color, fade), 2.0)
			for i in 4:
				var dir := Vector2.from_angle(TAU * float(i) / 4.0 + 0.6)
				draw_line(dir * size * (0.2 + k), dir * size * (0.5 + k * 1.3), Color(Palette.BONE, fade * 0.8), 1.5)
		Kind.SLASH:
			var ang := vec.angle()
			draw_arc(Vector2.ZERO, size, ang - 0.9, ang + 0.9, 8, Color(color, fade), 2.5)
		Kind.RING:
			draw_circle(Vector2.ZERO, size * (0.3 + 0.7 * k), Color(color, 0.22 * fade))
			draw_arc(Vector2.ZERO, size * (0.3 + 0.7 * k), 0.0, TAU, 40, Color(color, fade), 3.0)
		Kind.BEAM:
			draw_line(Vector2.ZERO, vec, Color(color, fade), width)
			draw_circle(vec, 4.0 * fade + 1.0, Color(color, fade))
		Kind.SPAWN:
			draw_arc(Vector2.ZERO, size * (1.2 - 0.6 * k), 0.0, TAU, 20, Color(color, fade), 2.0)
			draw_line(Vector2(0, 4), Vector2(0, -size * 1.5 * (1.0 - k)), Color(color, 0.5 * fade), 2.0)
		Kind.TELEGRAPH_CIRCLE:
			# Outer warning + inner disc growing to full size at impact time.
			draw_circle(Vector2.ZERO, size, Color(color, 0.12))
			draw_arc(Vector2.ZERO, size, 0.0, TAU, 48, Color(color, 0.85), 2.0)
			draw_circle(Vector2.ZERO, size * k, Color(color, 0.28))
		Kind.TELEGRAPH_LINE:
			var dir := vec.normalized()
			var perp := Vector2(-dir.y, dir.x) * width * 0.5
			var lane := PackedVector2Array([perp, vec + perp, vec - perp, -perp])
			draw_colored_polygon(lane, Color(color, 0.12))
			var fill := PackedVector2Array([perp, vec * k + perp, vec * k - perp, -perp])
			draw_colored_polygon(fill, Color(color, 0.28))
			var outline := lane.duplicate()
			outline.append(lane[0])
			draw_polyline(outline, Color(color, 0.85), 2.0)
		Kind.IMPACT:
			draw_circle(Vector2.ZERO, size * (0.6 + 0.4 * k), Color(color, 0.45 * fade))
			draw_arc(Vector2.ZERO, size * (0.8 + 0.4 * k), 0.0, TAU, 40, Color(Palette.IVORY, fade), 3.0)
		Kind.ABYSS:
			# Dark disc collapsing inward with a green rim and violet spiral arms.
			var rr := size * (1.0 - 0.65 * k)
			draw_circle(Vector2.ZERO, rr, Color(0.04, 0.0, 0.07, 0.55 * fade + 0.15))
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 48, Color(Palette.NECRO_GREEN, fade), 3.0)
			for i in 4:
				var a := TAU * float(i) / 4.0 + k * 4.0
				draw_arc(Vector2.ZERO, rr * 0.7, a, a + 1.1, 10, Color(color, 0.8 * fade), 2.0)
