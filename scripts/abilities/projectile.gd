## Projectile — one pooled projectile (shadow bolt, skeletal arrow, mage orb,
## priest bolt, Covenant arrow). Pure data + drawing: ProjectileManager moves
## it and resolves hits so all projectile logic lives in one loop
## (GDD §22 ProjectileManager, §38 pooling).
class_name Projectile
extends Node2D

## Projectile kinds (drawing + hit rules). VOID_BOLT / VOID_SHARD belong to
## the Void Barrage evolution (GDD §6.1); FROST_BOLT is the Frost Wraith's.
enum Kind { SHADOW_BOLT, ARROW, MAGE_ORB, PRIEST_BOLT, ENEMY_ARROW, VOID_BOLT, VOID_SHARD, FROST_BOLT }

## Current kind.
var kind: Kind = Kind.SHADOW_BOLT
## True while flying (false = pooled).
var active: bool = false
## True for Covenant projectiles (hit player / summons), false for ours.
var hostile: bool = false
## Velocity in px/s.
var velocity: Vector2 = Vector2.ZERO
## Speed in px/s (magnitude of velocity, kept for homing).
var speed: float = 300.0
## Damage on hit (or per enemy inside an explosion).
var damage: float = 0.0
## Remaining extra enemies this projectile can pass through.
var pierce_left: int = 0
## Remaining lifetime in seconds.
var life: float = 1.5
## Hit radius in px.
var radius: float = 4.0
## Explosion radius in px (AoE projectiles only).
var splash: float = 0.0
## True for projectiles that explode at `dest` instead of hitting on contact.
var is_aoe: bool = false
## World point an AoE projectile explodes at.
var dest: Vector2 = Vector2.ZERO
## Homing turn rate in radians/s toward `target` (0 = straight).
var homing: float = 0.0
## Homing target (friendly projectiles).
var target: Enemy = null
## Generation of `target` when fired.
var target_gen: int = 0
## Overkill reservation amount added to `reserve_target.incoming_damage`.
var reserved: float = 0.0
## Enemy holding this projectile's damage reservation.
var reserve_target: Enemy = null
## Generation of `reserve_target` at reservation time.
var reserve_gen: int = 0
## Damage multiplier against undead summons (hostile projectiles).
var undead_mult: float = 1.0
## Statistics tag of whoever fired it ("bolt", "archer", "mage"...).
var source: String = ""
## Instance ids of enemies already hit (piercing projectiles).
var hit_ids: Array[int] = []
## Void Barrage: shards released on the first enemy hit (0 = no split).
var split_count: int = 0
## Void Barrage: damage of each shard.
var split_damage: float = 0.0
## Void Barrage: shard speed in px/s.
var split_speed: float = 0.0
## Void Barrage: shard lifetime in seconds.
var split_life: float = 0.0
## Frost bolt: fraction of speed its chill removes on hit (0 = no chill).
var chill_slow: float = 0.0
## Frost bolt: seconds the chill lasts.
var chill_time: float = 0.0


func _draw() -> void:
	match kind:
		Kind.SHADOW_BOLT:
			draw_line(Vector2(-14, 0), Vector2.ZERO, Color(Palette.VIOLET, 0.45), 4.0)
			draw_circle(Vector2.ZERO, 5.0, Palette.VIOLET)
			draw_circle(Vector2.ZERO, 2.5, Color(0.92, 0.82, 1.0))
		Kind.ARROW:
			draw_line(Vector2(-9, 0), Vector2(5, 0), Palette.BONE, 1.5)
			draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(3, -3), Vector2(3, 3)]), Palette.NECRO_GREEN)
		Kind.MAGE_ORB:
			draw_circle(Vector2.ZERO, 9.0, Color(Palette.VIOLET, 0.3))
			draw_circle(Vector2.ZERO, 5.5, Palette.VIOLET)
			draw_circle(Vector2(1, -1), 2.0, Palette.NECRO_GREEN)
		Kind.PRIEST_BOLT:
			draw_circle(Vector2.ZERO, 6.0, Color(Palette.NECRO_GREEN, 0.3))
			draw_circle(Vector2.ZERO, 3.0, Palette.NECRO_GREEN)
		Kind.ENEMY_ARROW:
			draw_line(Vector2(-9, 0), Vector2(5, 0), Palette.IVORY, 1.5)
			draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(3, -3), Vector2(3, 3)]), Palette.GOLD)
		Kind.VOID_BOLT:
			# Void Barrage: long green-and-violet trail, black void core.
			draw_line(Vector2(-24, 0), Vector2.ZERO, Color(Palette.NECRO_GREEN, 0.3), 7.0)
			draw_line(Vector2(-16, 0), Vector2.ZERO, Color(Palette.VIOLET, 0.6), 3.5)
			draw_circle(Vector2.ZERO, 7.5, Color(Palette.VIOLET, 0.35))
			draw_circle(Vector2.ZERO, 5.5, Color(0.04, 0.0, 0.07))
			draw_arc(Vector2.ZERO, 5.5, 0.0, TAU, 14, Palette.NECRO_GREEN, 1.5)
			draw_circle(Vector2(1.5, 0), 1.8, Color(0.92, 0.82, 1.0))
		Kind.VOID_SHARD:
			draw_colored_polygon(PackedVector2Array([Vector2(6, 0), Vector2(0, -2.5), Vector2(-5, 0), Vector2(0, 2.5)]), Palette.NECRO_GREEN)
			draw_line(Vector2(-9, 0), Vector2(-4, 0), Color(Palette.VIOLET, 0.6), 1.5)
		Kind.FROST_BOLT:
			# Frost Wraith: an ice shard with a cold-blue trail.
			draw_line(Vector2(-14, 0), Vector2(-2, 0), Color(Palette.COLD_BLUE, 0.45), 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(7, 0), Vector2(0, -3), Vector2(-5, 0), Vector2(0, 3)]), Palette.COLD_BLUE)
			draw_line(Vector2(-3, 0), Vector2(6, 0), PowerupGlyphs.ICE, 1.0)
