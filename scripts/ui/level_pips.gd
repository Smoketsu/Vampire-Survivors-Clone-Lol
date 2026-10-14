## LevelPips — a row of level pips with cut corners for a level-up card or
## a chest reward: the levels already owned (violet), the level this pick
## grants (soul-teal, softly pulsing on real time while motion is on), and
## the levels still to come (dark, outlined). Sizes and colours in
## InRunUiData (PIP_*). Purely visual.
class_name LevelPips
extends Control

## Level owned before the pick (0 = new).
var from_level: int = 0
## Level after the pick.
var to_level: int = 1
## Highest level (number of pips, >= 1).
var max_level: int = 5


func _init(p_from: int, p_to: int, p_max: int) -> void:
	from_level = p_from
	to_level = p_to
	max_level = maxi(1, p_max)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := InRunUiData.PIP_SIZE
	custom_minimum_size = Vector2(float(max_level) * s.x + float(max_level - 1) * InRunUiData.PIP_GAP, s.y)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _process(_delta: float) -> void:
	if UiMotion.enabled() and is_visible_in_tree() and to_level > from_level:
		queue_redraw()


func _draw() -> void:
	var s := InRunUiData.PIP_SIZE
	var pulse := 1.0  # Brightness of the new pip.
	if UiMotion.enabled():
		pulse = 0.78 + 0.22 * sin(float(Time.get_ticks_msec()) / 1000.0 * InRunUiData.PIP_PULSE)
	for i in max_level:
		var r := Rect2(Vector2(float(i) * (s.x + InRunUiData.PIP_GAP), 0.0), s)  # This pip.
		var lvl := i + 1  # Level this pip stands for.
		if lvl <= from_level:
			_pip(r, InRunUiData.PIP_OWNED)
		elif lvl <= to_level:
			_pip(r, Color(InRunUiData.PIP_NEW * pulse, 1.0))
		else:
			_pip(r, InRunUiData.PIP_EMPTY_EDGE)
			_pip(r.grow(-1.0), InRunUiData.PIP_EMPTY)


## A filled pip in `r` with its four corner pixels cut.
func _pip(r: Rect2, c: Color) -> void:
	if r.size.x < 2.0 or r.size.y < 2.0:
		draw_rect(r, c)
		return
	draw_rect(Rect2(r.position + Vector2(1.0, 0.0), r.size - Vector2(2.0, 0.0)), c)
	draw_rect(Rect2(r.position + Vector2(0.0, 1.0), r.size - Vector2(0.0, 2.0)), c)
