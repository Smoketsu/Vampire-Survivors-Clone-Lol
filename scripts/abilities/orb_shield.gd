## OrbShield — Shadow Orb Shield spell (GDD §8): orbs orbit the necromancer,
## damage enemies they touch and intercept hostile projectiles. Interception
## is charge-limited (GDD §8 "to avoid invulnerability"): an orb that eats a
## projectile goes dim and must recharge before it can intercept again (it
## still deals contact damage while recharging).
## Created by AbilityManager the first time the spell is learned.
class_name OrbShield
extends Node2D

## Owning run.
var game: Game
## Current orbit angle in radians.
var angle: float = 0.0
## World positions of each orb this tick.
var orb_positions: PackedVector2Array = PackedVector2Array()
## Per-orb seconds until it can intercept again (<= 0 means charged).
var recharge: PackedFloat32Array = PackedFloat32Array()
## Stats row for the current spell level (AbilityData.SPELLS.orb_shield).
var _stats: Dictionary = {}
## Reusable query buffer.
var _tmp: Array = []


func _ready() -> void:
	z_index = 3


## Moves orbs, applies contact damage and ticks recharge timers.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	var n: int = stats["orbs"]
	if recharge.size() != n:
		recharge.resize(n)
	orb_positions.resize(n)
	angle = wrapf(angle + float(stats["orbit_speed"]) * delta, 0.0, TAU)
	position = game.player.position
	var orbit_r: float = stats["orbit_radius"]
	var dmg: float = stats["damage"]
	var hit_cd: float = stats["hit_cooldown"]
	for i in n:
		var pos := position + Vector2.from_angle(angle + TAU * float(i) / float(n)) * orbit_r
		orb_positions[i] = pos
		recharge[i] = recharge[i] - delta
		game.enemy_grid.query(pos, AbilityData.ORB_RADIUS + 30.0, _tmp)
		for e: Enemy in _tmp:
			if e.active and e.orb_hit_cd <= 0.0 and e.position.distance_to(pos) <= e.radius + AbilityData.ORB_RADIUS:
				e.orb_hit_cd = hit_cd
				game.combat.damage_enemy(e, dmg, "orb")
	queue_redraw()


## Consumes a charged orb touching a projectile at `pos` (radius `r`).
## Returns true if the projectile was intercepted.
func try_intercept(pos: Vector2, r: float) -> bool:
	for i in orb_positions.size():
		if recharge[i] <= 0.0 and orb_positions[i].distance_to(pos) <= AbilityData.ORB_RADIUS + r + 4.0:
			recharge[i] = float(_stats["recharge"])
			return true
	return false


## Number of orbs currently able to intercept (HUD "shields").
func charges_ready() -> int:
	var n := 0
	for i in recharge.size():
		if recharge[i] <= 0.0:
			n += 1
	return n


func _draw() -> void:
	if _stats.is_empty():
		return
	draw_arc(Vector2.ZERO, float(_stats["orbit_radius"]), 0.0, TAU, 48, Color(Palette.VIOLET, 0.12), 1.0)
	for i in orb_positions.size():
		var local := orb_positions[i] - position
		var charged := recharge[i] <= 0.0
		draw_circle(local, AbilityData.ORB_RADIUS + 3.0, Color(Palette.VIOLET, 0.25 if charged else 0.08))
		draw_circle(local, AbilityData.ORB_RADIUS, Palette.VIOLET if charged else Color(Palette.VIOLET, 0.45))
		if charged:
			draw_circle(local, AbilityData.ORB_RADIUS * 0.4, Color(0.92, 0.82, 1.0))
