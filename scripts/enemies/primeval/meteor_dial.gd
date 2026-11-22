## MeteorDial — the HUD's GROWING METEOR of the Last Day (temporary Act XIV;
## GDD §15.0 "The Last Day (Act XIV phase 2)"; owner-approved proposal: "the
## HUD clock shows the meteor growing as the time runs out"). A small lava
## disc with a bone-white streak beside the countdown that grows from
## MIN_R to MAX_R px as the clock runs from 20:00 to 0:00 (one disc texture
## and a few rects; redrawn only when its size moves a pixel). Reads the clock
## only; changes nothing. Created by LastDayDirector when the run has a HUD
## (never headless).
class_name MeteorDial
extends Control

## Radius (layout px) of the meteor at 20:00.
const MIN_R: float = 2.0  # TUNING (not in GDD) drawing only
## Radius (layout px) of the meteor at 0:00.
const MAX_R: float = 13.0  # TUNING (not in GDD) drawing only
## Layout px right of the HUD's centre line (beside the countdown).
const OFFSET := Vector2(92.0, 38.0)  # TUNING (not in GDD) drawing only

## Owning run.
var game: Game
## The radius drawn last (px; a redraw only when it moves).
var _drawn_r: int = -1


## Lays the dial out beside the countdown and redraws when it grew
## (LastDayDirector, every tick).
func refresh() -> void:
	position = Vector2(game.hud.size.x * 0.5, 0.0) + OFFSET
	var k := clampf(game.elapsed / WaveData.RUN_DURATION, 0.0, 1.0)  # The clock run so far.
	var r := int(roundf(lerpf(MIN_R, MAX_R, k)))
	if r != _drawn_r:
		_drawn_r = r
		queue_redraw()


func _draw() -> void:
	var r := float(_drawn_r)
	for i in 4:
		var t := Vector2(-1.0, -0.6).normalized() * (r + 3.0 + 4.0 * float(i))
		draw_rect(Rect2(t - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(Palette.PRIMEVAL_STREAK, 0.7 - 0.15 * float(i)))  # The white streak.
	draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r - 1.0, -r - 1.0), Vector2(r + 1.0, r + 1.0) * 2.0), false, Palette.PRIMEVAL_INK)
	draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r), Vector2(r, r) * 2.0), false, Palette.PRIMEVAL_LAVA)
