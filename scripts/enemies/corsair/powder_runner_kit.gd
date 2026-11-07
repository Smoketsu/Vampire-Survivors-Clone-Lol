## PowderRunnerKit — the kit of the Powder Runner (CorsairEnemyData
## "powder_runner"; Act X, the Black Tide; GDD §15.0 "Act X foundation: the
## Black Tide (phase 1)"; owner-approved proposal: "Sprints with a lit keg, 1 s
## fuse, blast hits both sides and knocks everyone 60 px | Kill at range; let
## the blast push the crew overboard"). He runs at his target like any melee
## boarder; within the keg's fuse_range of a body he stops and the FUSE burns
## (keg "fuse" s, a lit spark; physics() holds him), then THE KEG GOES OFF:
## CorsairRules.powder_blast() (both sides, everyone knocked `push` px; at the
## rail his own crew go overboard) and he dies in it. Killed before that, the
## keg goes off where he falls (on_killed()): kill him at range and the blast
## hurts only his crew. One blast per run of his life (`blown`).
## Determinism: no RNG.
class_name PowderRunnerKit
extends CorsairKit

## Phase: the fuse burns.
const FUSE: int = 1

## True once his keg went off (it never goes off twice).
var blown: bool = false


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	blown = false


## The keg goes off where he falls.
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	_blow(e)


## Sets off the keg once at his feet.
func _blow(e: Enemy) -> void:
	if blown:
		return
	blown = true
	var keg: Dictionary = d.get("keg", {})
	if keg.is_empty():
		return
	rules(e).powder_blast(e.position, keg, e)


func physics(e: Enemy, delta: float) -> bool:
	if super.physics(e, delta):
		return true
	var keg: Dictionary = d.get("keg", {})
	if phase == FUSE:
		phase_time += delta
		hold(e)
		if phase_time >= float(keg.get("fuse", 1.0)):
			_blow(e)
			if e.active:
				e.game.combat.damage_enemy(e, e.hp * 100.0 + e.max_hp, CorsairRulesData.POWDER_SOURCE)  # He goes up with it (the one kill path).
		return true
	var t := e.target
	if t != null and is_instance_valid(t) and e.position.distance_to(t.position) - e.radius - body_radius(e, t) <= float(keg.get("fuse_range", 26.0)):
		set_phase(e, FUSE)
		e.game.stat_add("powder_fuses", 1.0)
		rules(e).play_sound("fuse_hiss", e.position, 0.2)
		return true
	return false


## The lit fuse: a spark over the keg that brightens as it burns (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != FUSE:
		return
	var k := clampf(phase_time / maxf(float((d.get("keg", {}) as Dictionary).get("fuse", 1.0)), 0.01), 0.0, 1.0)
	SpriteBank.draw_disc(ci, Vector2(0.0, -e.radius * 1.3), 2.5 + 3.0 * k, Color(Palette.CORSAIR_LANTERN_LIGHT, 0.6 + 0.4 * k))
