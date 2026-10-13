## Effect — one pooled, purely cosmetic visual effect (death pop, slash, heal
## beam, blast ring, spawn ring) or a boss telegraph (warning circle / lane).
## Effects never apply gameplay; the system that spawns a telegraph keeps its
## own timer and applies damage itself, the Effect just shows the warning for
## the same duration. Managed and pooled by EffectManager.
class_name Effect
extends Node2D

## What to draw. ABYSS is the imploding vortex of Abyssal Detonation;
## TELEGRAPH_CONE is a boss sector warning (Marshal Vael's Radiant Cleave).
enum Kind { POP, SLASH, RING, BEAM, SPAWN, TELEGRAPH_CIRCLE, TELEGRAPH_LINE, IMPACT, ABYSS, TELEGRAPH_CONE }

## Current effect kind.
var kind: Kind = Kind.POP
## Effect animation id (AnimData / assets/sprites/effects/<id>.png) played
## instead of the drawn shape when its art exists; "" = always drawn.
var anim_id: String = ""
## Animation id whose art replaces this effect: while that strip exists the
## effect draws nothing (it still lives its full time); "" = always drawn.
## Set by EffectManager.ring_under().
var hide_with: String = ""
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
## SLASH / TELEGRAPH_CONE facing direction.
var vec: Vector2 = Vector2.RIGHT
## Line width in px (beams, telegraph lanes); TELEGRAPH_CONE: half-angle (rad).
var width: float = 2.0
## Enemy whose attack this telegraph announces (null = none). While that
## enemy is frozen by a Stasis power-up the telegraph holds still.
var owner_enemy: Enemy = null
## Generation of `owner_enemy` when the telegraph started (stale guard).
var owner_gen: int = 0


## Starts the effect. Called by EffectManager after taking it from the pool.
func start(p_kind: Kind, pos: Vector2, p_color: Color, p_size: float, p_duration: float, p_vec: Vector2 = Vector2.RIGHT, p_width: float = 2.0) -> void:
	kind = p_kind
	position = pos
	color = p_color
	size = p_size
	duration = maxf(p_duration, 0.01)
	vec = p_vec
	width = p_width
	owner_enemy = null
	owner_gen = 0
	anim_id = ""
	hide_with = ""
	t = 0.0
	active = true
	visible = true
	# Telegraphs sit under bodies, everything else above.
	z_index = -5 if (kind == Kind.TELEGRAPH_CIRCLE or kind == Kind.TELEGRAPH_LINE or kind == Kind.TELEGRAPH_CONE) else 5
	queue_redraw()


## Advances the animation; returns false once finished. A telegraph whose
## owner is frozen by Stasis does not advance (it resumes with its owner).
func step(delta: float) -> bool:
	if owner_enemy != null and owner_enemy.active and owner_enemy.generation == owner_gen and owner_enemy.frozen:
		return true
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
	if hide_with != "" and SpriteBank.has_anim(hide_with):
		return  # Its animation draws this part (EffectManager.ring_under()).
	if anim_id != "":
		# Sprite-sheet animation scaled to the gameplay radius (size).
		var fill: float = AnimData.ANIMS.get(anim_id, {}).get("fill", AnimData.DEFAULT_FILL)  # Diameter multiple.
		if SpriteBank.draw_anim(self, anim_id, Vector2.ZERO, size * 2.0 * fill, k):
			return
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
		Kind.TELEGRAPH_CONE:
			# Sector toward `vec`: outline + fill sweeping outward until the strike.
			var ang := vec.angle()
			var outer := PackedVector2Array([Vector2.ZERO])
			var inner := PackedVector2Array([Vector2.ZERO])
			for i in 17:
				var a := ang - width + 2.0 * width * float(i) / 16.0
				outer.append(Vector2.from_angle(a) * size)
				inner.append(Vector2.from_angle(a) * size * k)
			draw_colored_polygon(outer, Color(color, 0.12))
			if k > 0.02:
				draw_colored_polygon(inner, Color(color, 0.28))
			outer.append(Vector2.ZERO)
			draw_polyline(outer, Color(color, 0.85), 2.0)
		Kind.ABYSS:
			# Dark disc collapsing inward with a green rim and violet spiral arms.
			var rr := size * (1.0 - 0.65 * k)
			draw_circle(Vector2.ZERO, rr, Color(0.04, 0.0, 0.07, 0.55 * fade + 0.15))
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 48, Color(Palette.NECRO_GREEN, fade), 3.0)
			for i in 4:
				var a := TAU * float(i) / 4.0 + k * 4.0
				draw_arc(Vector2.ZERO, rr * 0.7, a, a + 1.1, 10, Color(color, 0.8 * fade), 2.0)
