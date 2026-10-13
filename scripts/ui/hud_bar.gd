## HudBar — minimal custom-drawn progress bar with optional centred text
## (HP, XP, boss HP, replenish timers). Redraws only when its values change.
## Pixel-art UI kit: the fill gets a 1 px lighter row under its top edge and
## a 1 px darker row above its bottom edge (BEVEL_*; bars 6 px or taller),
## and a bordered bar draws the kit's bar frame (UiTheme.style("bar"), 1 px
## outside its rect) instead of the flat 1 px border when that PNG exists.
## Colours and meanings are unchanged.
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
## Font size of the text in px (pixel font, UiTheme.font_for()).
var font_size: int = 13

## Fill bevel: how much lighter the fill's top row is (Color.lightened amount).
const BEVEL_LIGHT: float = 0.3  # TUNING (not in GDD) art pass UI kit
## Fill bevel: how much darker the fill's bottom row is (Color.darkened amount).
const BEVEL_DARK: float = 0.3  # TUNING (not in GDD) art pass UI kit


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
	var w := floorf(size.x * value)  # Fill width (whole px).
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, size.y)), fill_color)
	if w > 0.0 and size.y >= 6.0:  # Bevel rows just inside the edge row (the frame / border covers the edge).
		draw_rect(Rect2(Vector2(0.0, 1.0), Vector2(w, 1.0)), fill_color.lightened(BEVEL_LIGHT))
		draw_rect(Rect2(Vector2(0.0, size.y - 2.0), Vector2(w, 1.0)), fill_color.darkened(BEVEL_DARK))
	if border_color.a > 0.0:
		var frame := UiTheme.style("bar")  # Kit bar frame (a StyleBoxTexture when its PNG exists).
		if frame is StyleBoxTexture:
			SpriteBank.apply_sharp(self)
			draw_style_box(frame, r.grow(1.0))
		else:
			draw_rect(r, border_color, false, 1.0)
	if text != "":
		SpriteBank.apply_sharp(self)  # Pixel-font text is rasterised at layout size (UiArtData).
		var fs := font_size
		var font := UiTheme.font_for(fs) if UiTheme.font_for(fs) != null else get_theme_default_font()  # Pixel font.
		var y := roundf((size.y + float(fs) * 0.75) * 0.5)  # Baseline on a whole layout px.
		draw_string(font, Vector2(1, y + 1), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color.WHITE)
