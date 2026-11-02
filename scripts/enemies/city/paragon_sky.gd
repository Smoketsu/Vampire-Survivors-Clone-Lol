## ParagonSky — the white sky of NO RESTRAINT, Paragon's third phase (Act VIII,
## Liberty Heights; GDD §15.0 "Paragon, the Last Hero (Act VIII)";
## owner-approved proposal: "he stops holding back: the sky turns white").
## Created by BossParagon when No Restraint begins (never headless), released
## when he falls (it fades out, then frees itself). Visual only: it changes
## nothing in the run. Drawn over the world (under the HUD) as ONE rect over
## the visible view in a white, slowly fading in over `fade` s, with an
## ADDITIVE blend-mode material (CanvasItemMaterial.BLEND_MODE_ADD): the
## world brightens toward white. No shader reads the screen (the Web rule in
## CLAUDE.md: "use blend-mode rects instead"), no flash: the fade is slow.
class_name ParagonSky
extends Node2D

## Seconds the white takes to fade back out after he falls.
const FADE_OUT: float = 2.5  # TUNING (not in GDD) drawn only

## Owning run.
var _game: Game = null
## Seconds the white takes to fade in.
var fade: float = 4.0
## Strength (0..1) of the white at full.
var alpha: float = 0.32
## Game time (s) the sky began to turn.
var _since: float = 0.0
## Game time (s) it began to fade out (INF while he fights).
var _released_at: float = INF


## Builds the sky for `game` (`p_fade` s to turn white, `p_alpha` the white's
## strength). `_boss` is kept for the caller's symmetry with VargrDark.
func _init(game: Game, _boss: Enemy, p_fade: float, p_alpha: float) -> void:
	_game = game
	fade = p_fade
	alpha = p_alpha
	_since = game.elapsed
	name = "ParagonSky"
	z_index = 19  # Over the bodies and effects; under the HUD.
	z_as_relative = false
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD  # Brightens toward white (no screen read).
	material = mat


## He fell: the white fades out over FADE_OUT s, then the node frees itself.
func release() -> void:
	if _released_at == INF:
		_released_at = _game.elapsed


func _process(_delta: float) -> void:
	if _released_at != INF and _game.elapsed - _released_at >= FADE_OUT:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := clampf((_game.elapsed - _since) / maxf(fade, 0.01), 0.0, 1.0)  # The sky turning.
	if _released_at != INF:
		k *= 1.0 - clampf((_game.elapsed - _released_at) / FADE_OUT, 0.0, 1.0)
	if k <= 0.0:
		return
	var cam := _game.camera
	var zoom := cam.zoom if cam != null else Vector2.ONE
	var sz := get_viewport_rect().size / zoom  # World px on screen.
	var c := cam.get_screen_center_position() if cam != null else _game.player.position
	draw_rect(Rect2(c - sz * 0.5, sz).grow(64.0), Color(alpha * k, alpha * k, alpha * k * 0.96, 1.0))
