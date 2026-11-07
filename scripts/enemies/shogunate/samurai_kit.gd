## SamuraiKit — the kit of the Samurai (ShogunateEnemyData "samurai"; Act V, GDD
## §15.0 "Act V foundation (phase 1)" and "The Draw"): a katana duelist. Its
## ELITE uses THE DRAW (ShogunateKit.can_draw()): when the necromancer it
## advances on is within the row's draw_range px, it stops, hand on the hilt,
## and draws a line at him through DrawCuts (the one path: a thin white line for
## 0.8 s, then one cut hitting every body on it, then the dash along the line).
## It holds still while its line flashes; a refused draw (three lines already
## flash) retries a moment later. Every other samurai is the shared melee AI.
## No RNG (first cooldowns staggered by the think slot).
class_name SamuraiKit
extends ShogunateKit

## Phase: the line flashes (the samurai holds, hand on the hilt).
const DRAWING: int = 1
## Seconds before a refused draw is tried again.
const RETRY: float = 0.8  # TUNING (not in GDD) kit rhythm, not balance

## Seconds until this samurai may draw again.
var _cd: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("draw_every", 7.0)) * 0.5)


## The Draw: wait for the cooldown and the range, then hold while the line
## flashes (DrawCuts cuts and dashes the body along it).
func physics(e: Enemy, delta: float) -> bool:
	_cd -= delta
	if phase == DRAWING:
		phase_time += delta
		if phase_time >= float(ShogunateRulesData.DRAW["flash"]) + 0.05 or not rules(e).draws.has_line(e):
			set_phase(e, IDLE)
			return false
		hold(e)
		return true
	if _cd > 0.0 or not can_draw(e):
		return false
	var pl := e.game.player  # The necromancer it advances on (co-op: the nearest, bound).
	if e.position.distance_to(pl.position) > float(d.get("draw_range", 200.0)):
		return false
	if not start_draw(e, pl.position):
		_cd = RETRY
		return false
	_cd = float(d.get("draw_every", 7.0))
	set_phase(e, DRAWING)
	e.game.stat_add("samurai_draws", 1.0)
	hold(e)
	return true


func is_busy() -> bool:
	return phase == DRAWING


## Hand on the hilt: a white glint at the hip while the line flashes. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != DRAWING:
		return
	unmirror(e, ci)
	var k := clampf(phase_time / float(ShogunateRulesData.DRAW["flash"]), 0.0, 1.0)  # 0 .. the cut.
	SpriteBank.draw_disc(ci, Vector2(e.radius * 0.5, e.radius * 0.2), 2.0 + 2.0 * k, Color(1.0, 1.0, 1.0, 0.6 + 0.4 * k))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
