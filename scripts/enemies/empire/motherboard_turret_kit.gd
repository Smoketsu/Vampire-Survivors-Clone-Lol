## MotherboardTurretKit — a Motherboard Turret (AssemblyEnemyData
## "motherboard_turret", a MACHINE structure; Act III, the Assembly Halls; GDD
## §15.0 "The Assembly Halls (Act III phase 2)"; owner-approved proposal: the
## Motherboard "builds turrets mid-fight"). The boss's own small turret, not the
## Iron Citadel's Sentry Turret. Fixed in place (a structure), it fires one bolt
## every attack_interval s at the necromancer when he is within attack_range px,
## else at the nearest summon in range, through EmpireShots (style
## "turret_bolt"; Line of Fire applies: the army shields him). Siegecraft and
## the Catapults' structure preference reach it. A MACHINE: no corpse. No RNG.
## Stats: mb_turret_shots.
class_name MotherboardTurretKit
extends EmpireKit

## Seconds until the next bolt.
var shot_cd: float = 0.0
## Unit direction of the last bolt (the barrel's facing, drawing only).
var aim: Vector2 = Vector2.LEFT
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	shot_cd = first_cd(e, float(d["first_shot"]))


## Fires on its clock (never owns the tick: the structure step keeps it still).
func physics(e: Enemy, delta: float) -> bool:
	shot_cd -= delta
	if shot_cd > 0.0:
		return false
	var t := _target(e)
	if t == null:
		shot_cd = 0.3  # Nothing in range: look again soon.
		return false
	shot_cd = e.attack_interval
	var to := t.position - e.position
	aim = to.normalized() if to.length() > 0.5 else aim
	if fire_shot(e, aim, e.damage * hit_scale(e)):
		e.game.stat_add("mb_turret_shots", 1.0)
		Sfx.play("turret_shot", e.position)
		e.queue_redraw()
	return false


## The necromancer when in range, else the nearest summon in range (or null).
func _target(e: Enemy) -> Node2D:
	var g := e.game
	var reach := e.attack_range
	if g.player.position.distance_to(e.position) <= reach and not g.player.dead:
		return g.player
	g.ally_grid.query(e.position, reach, _tmp)
	var best: SummonedUnit = null
	var best_d := reach
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		var dist := u.position.distance_to(e.position)
		if dist < best_d:
			best_d = dist
			best = u
	return best


## The twin barrel along its aim (drawn over the body when it has no art pose).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	unmirror(e, ci)
	var tip := aim * (e.radius + 6.0)
	ci.draw_line(Vector2(0, -e.radius * 0.3), tip + Vector2(0, -e.radius * 0.3), AssemblyGlyphs.INK, 4.0)
	ci.draw_line(Vector2(0, -e.radius * 0.3), tip + Vector2(0, -e.radius * 0.3), Palette.EMPIRE_CHROME_LIGHT, 2.0)
	ci.draw_circle(tip + Vector2(0, -e.radius * 0.3), 1.5, Palette.EMPIRE_SIGNAL_RED)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
