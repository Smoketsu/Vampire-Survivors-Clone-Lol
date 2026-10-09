## HudBar — minimal custom-drawn progress bar with optional centred text
## (HP, XP, boss HP, replenish timers). Redraws only when its values change.
class_name HudBar
extends Control

## Fill fraction 0..1.
var value: float = 1.0
## Fill colour.
var fill_color: Color = Palette.HP_FRIENDLY
## Background colour.
var back_color: Color = Color(0, 0, 0, 0.6)
## Border colour (transparent = no border).
var border_color: Color = Color(0.45, 0.3, 0.7)
## Text drawn centred on the bar ("" = none).
var text: String = ""
## Font size of the text in px.
var font_size: int = 13


func _init(p_fill: Color = Palette.HP_FRIENDLY, min_size: Vector2 = Vector2(200, 16)) -> void:
	fill_color = p_fill
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Updates the bar; redraws only on change.
func set_values(v: float, t: String = "") -> void:
	v = clampf(v, 0.0, 1.0)
	if is_equal_approx(v, value) and t == text:
		return
	value = v
	text = t
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, back_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * value, size.y)), fill_color)
	if border_color.a > 0.0:
		draw_rect(r, border_color, false, 1.0)
	if text != "":
		var font := get_theme_default_font()
		var y := (size.y + float(font_size) * 0.75) * 0.5
		draw_string(font, Vector2(1, y + 1), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color.WHITE)
