## DeusDroneKit — a shield drone of DEUS EX MACHINA's Siege Core (CitadelEnemyData
## "deus_shield_drone", kit "deus_drone"; Act III, the Iron Citadel; GDD §15.0
## "The Iron Citadel (Act III phase 2)"; owner-approved proposal: "Shield drones
## orbit it and make the core immune until they are shot down"). A flying
## structure and a MACHINE. BossDeusExMachina launches them, sets their HP and
## calls attach(); every tick each one orbits the core at DeusData.BOSS
## drone_orbit px, drone_speed rad/s, a beam of light tethering it to the core
## (drawing only). The boss counts the living ones (its immunity). No RNG.
class_name DeusDroneKit
extends CovenantKit

## The core it shields (null until attach()).
var boss: Enemy = null
## Generation of `boss` when attached (stale guard).
var boss_gen: int = 0
## Current orbit angle (rad, world).
var angle: float = 0.0
## Orbit radius (px).
var orbit: float = 120.0
## Orbit speed (rad/s).
var speed: float = 0.8


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	boss = null


## Tethers the drone to `p_boss` at orbit angle `a`, `r` px out, `w` rad/s.
func attach(e: Enemy, p_boss: Enemy, a: float, r: float, w: float) -> void:
	boss = p_boss
	boss_gen = p_boss.generation
	angle = a
	orbit = r
	speed = w
	_orbit(e)


## Orbits the core.
func physics(e: Enemy, delta: float) -> bool:
	hold(e)
	e.knockback = Vector2.ZERO
	angle = wrapf(angle + speed * delta, -PI, PI)
	_orbit(e)
	return true


## Puts the drone on its orbit.
func _orbit(e: Enemy) -> void:
	if boss != null and boss.active and boss.generation == boss_gen:
		e.position = boss.position + Vector2.from_angle(angle) * orbit


## The tether of light to the core. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if boss == null or not boss.active or boss.generation != boss_gen:
		return
	unmirror(e, ci)
	CitadelGlyphs.draw_tether(ci, boss.position - e.position, e.game.elapsed)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
