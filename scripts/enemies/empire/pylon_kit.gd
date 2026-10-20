## PylonKit — the Signal Pylon's kit (WastesEnemyData "signal_pylon"; Act III,
## the Scrap Wastes, GDD §15.0 "The Scrap Wastes (Act III phase 2)"). The
## pylon is a structure (no AI, never recycled); its RULE lives in
## WastesDirector (the pylons it placed lengthen the reach of the Empire's
## shooters near them, and shorten it for the rest of the run once destroyed:
## reach_mult_at(), the one reach path). This kit only draws: the red beacon at
## its tip blinks on game time and a faint amber ring marks the reach of its
## signal (WastesStage.WASTES pylon_radius when the stage has it). Visual only.
class_name PylonKit
extends CovenantKit

## Beacon blink state when last drawn (redraw only when it flips).
var _lit: bool = false


## Redraws when the beacon blinks (a structure stands still: nothing else moves).
func physics(e: Enemy, _delta: float) -> bool:
	var on := fmod(e.game.elapsed * 1.6, 1.0) < 0.5  # Blink phase.
	if on != _lit:
		_lit = on
		e.queue_redraw()
	return false


## The signal's reach on the ground: a faint dashed amber ring. Visual only.
func draw_under(e: Enemy) -> void:
	var cfg: Dictionary = e.game.stage_def.get("wastes", {})  # The stage's Wastes config ({} elsewhere).
	if cfg.is_empty():
		return
	var r := float(cfg["pylon_radius"])  # Signal reach (px).
	var n := 36  # Dashes.
	CovenantKit.unmirror(e)
	for i in n:
		if i % 2 == 1:
			continue
		var a0 := TAU * float(i) / float(n)  # Dash start angle (rad).
		e.draw_arc(Vector2.ZERO, r, a0, a0 + TAU / float(n), 4, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.22), 2.0)
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The beacon: a warning-red light at the mast's tip, blinking. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var on := _lit  # Blink phase.
	var tip := Vector2(0.0, e.marker_y(-e.radius * 3.4) + 10.0)  # Mast tip (px).
	ci.draw_circle(tip, 5.0 if on else 3.5, Color(Palette.EMPIRE_SIGNAL_RED, 0.35 if on else 0.15))
	if on:
		ci.draw_circle(tip, 2.0, Palette.EMPIRE_SIGNAL_GLOW)
