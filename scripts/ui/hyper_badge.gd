## HyperBadge — the gold HYPER badge (HyperData): a code-drawn gold sun disc
## with a dark five-pointed star, used on the stage-select cards of stages
## cleared on Hyper (Meta.hyper_clear_count()) and on the setup screen's
## Hyper card. `row()` builds the badge with its caption as one HBox.
class_name HyperBadge
extends Control

## Gold of the disc and rays.
const GOLD := Color(1.0, 0.82, 0.3)
## Dark star on the disc.
const STAR := Color(0.24, 0.14, 0.04)


func _init(px: float = 18.0) -> void:
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## An HBox holding a badge of `px` px and the caption `text` (gold).
static func row(text: String, px: float = 18.0, font_size: int = 13) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(HyperBadge.new(px))
	hb.add_child(UiTheme.label(text, font_size, UiTheme.TEXT_GOLD))
	return hb


func _draw() -> void:
	var c := size * 0.5  # Centre (px).
	var r := minf(size.x, size.y) * 0.5  # Outer radius (px).
	for i in 8:
		var d := Vector2.from_angle(TAU * float(i) / 8.0)  # Ray direction.
		draw_line(c + d * r * 0.62, c + d * r, GOLD, maxf(1.0, r * 0.16))
	draw_circle(c, r * 0.66, GOLD)
	draw_arc(c, r * 0.66, 0.0, TAU, 20, GOLD.darkened(0.4), 1.0)
	var pts := PackedVector2Array()  # Five-pointed star.
	for i in 10:
		var rr := r * (0.46 if i % 2 == 0 else 0.2)  # Point / notch radius.
		pts.append(c + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * rr)
	draw_colored_polygon(pts, STAR)
