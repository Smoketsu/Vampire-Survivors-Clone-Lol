## OrbShield — Shadow Orb Shield spell (GDD §8): orbs orbit the necromancer,
## damage enemies they touch and intercept hostile projectiles. Interception
## is charge-limited (GDD §8 "to avoid invulnerability"): an orb that eats a
## projectile goes dim and must recharge before it can intercept again (it
## still deals contact damage while recharging).
## Created by AbilityManager the first time the spell is learned.
## Evolved into Eclipse Ward (GDD §6.1, stats with "pulse_interval"): six
## eclipse orbs joined by a rotating barrier band that releases periodic
## damage pulses with an outward shove.
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
## Effective stats for the current spell level or evolution (see
## AbilityManager.spell_stats()).
var _stats: Dictionary = {}
## Eclipse Ward: seconds until the next damage pulse.
var _pulse_timer: float = 1.0
## Eclipse Ward: true while the evolved stats are in use (drawing).
var _eclipse: bool = false
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
	_eclipse = stats.has("pulse_interval")
	if _eclipse:
		_pulse_timer -= delta
		if _pulse_timer <= 0.0:
			_pulse_timer = float(stats["pulse_interval"]) if _pulse(stats) else 0.25
	queue_redraw()


## Eclipse Ward pulse: damages and shoves every enemy within pulse_radius.
## Returns false (retry soon) if nobody was in range.
func _pulse(stats: Dictionary) -> bool:
	var r: float = stats["pulse_radius"]
	game.enemy_grid.query(position, r + 30.0, _tmp)
	var hit := false
	for e: Enemy in _tmp:
		if not e.active or e.position.distance_to(position) > r + e.radius:
			continue
		hit = true
		var away := e.position - position
		if away.length() > 0.01:
			e.knockback += away.normalized() * float(stats["pulse_knockback"]) / maxf(e.mass, 0.1)
		game.combat.damage_enemy(e, float(stats["pulse_damage"]), "eclipse")
	if hit:
		game.effects.ring(position, r, Palette.NECRO_GREEN, 0.35)
		game.stat_add("eclipse_pulses", 1.0)
	return hit


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
	if _eclipse:
		_draw_eclipse()
		return
	draw_arc(Vector2.ZERO, float(_stats["orbit_radius"]), 0.0, TAU, 48, Color(Palette.VIOLET, 0.12), 1.0)
	for i in orb_positions.size():
		var local := orb_positions[i] - position
		var charged := recharge[i] <= 0.0
		draw_circle(local, AbilityData.ORB_RADIUS + 3.0, Color(Palette.VIOLET, 0.25 if charged else 0.08))
		draw_circle(local, AbilityData.ORB_RADIUS, Palette.VIOLET if charged else Color(Palette.VIOLET, 0.45))
		if charged:
			draw_circle(local, AbilityData.ORB_RADIUS * 0.4, Color(0.92, 0.82, 1.0))


## Eclipse Ward look: a dark rotating barrier band with green segments between
## black "eclipsed" orbs ringed by a violet corona; an inner ring fills up as
## the next pulse charges.
func _draw_eclipse() -> void:
	var r: float = _stats["orbit_radius"]
	var n := orb_positions.size()
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(0.05, 0.0, 0.08, 0.45), 9.0)
	for i in n:
		var a0 := angle + TAU * float(i) / float(n)
		draw_arc(Vector2.ZERO, r, a0 + 0.22, a0 + TAU / float(n) - 0.22, 10, Color(Palette.NECRO_GREEN, 0.55), 2.0)
	var charge := 1.0 - clampf(_pulse_timer / maxf(float(_stats["pulse_interval"]), 0.01), 0.0, 1.0)
	draw_arc(Vector2.ZERO, r * 0.45, -PI / 2.0, -PI / 2.0 + TAU * charge, 32, Color(Palette.VIOLET, 0.35), 2.0)
	for i in n:
		var local := orb_positions[i] - position
		var charged := recharge[i] <= 0.0
		draw_circle(local, AbilityData.ORB_RADIUS + 4.0, Color(Palette.VIOLET, 0.45 if charged else 0.12))
		draw_circle(local, AbilityData.ORB_RADIUS + 0.5, Color(0.03, 0.0, 0.05))
		var face := (local).angle()
		draw_arc(local, AbilityData.ORB_RADIUS + 0.5, face - 1.2, face + 1.2, 10, Palette.NECRO_GREEN if charged else Color(Palette.NECRO_GREEN, 0.35), 2.0)
