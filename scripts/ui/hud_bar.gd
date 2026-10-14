## HudBar — minimal custom-drawn progress bar with optional centred text
## (HP, XP, boss HP, replenish timers). Redraws only when its values change.
## Pixel-art UI kit: the fill gets a 1 px lighter row under its top edge and
## a 1 px darker row above its bottom edge (BEVEL_*; bars 6 px or taller),
## and a bordered bar draws the kit's bar frame (UiTheme.style("bar"), 1 px
## outside its rect) instead of the flat 1 px border when that PNG exists.
## Two optional extras (menu modernization wave 2, InRunUiData): `notch`
## draws a thin dark notch every that fraction of the bar (the HP bar's
## quarters), and `trail` keeps a pale damage trail where the value just
## dropped from, which waits TRAIL_HOLD s and then drains (real time; off
## when UI motion is off, so the autotest never animates it). Colours and
## meanings are unchanged. Purely visual.
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
## Font size of the text in px (as the UI scripts size text; drawn at
## UiTheme.font_px() in the pixel font).
var font_size: int = 13
## Notch spacing as a fraction of the bar (0 = no notches; 0.25 = quarters).
var notch: float = 0.0
## True: show the damage trail when the value drops.
var trail: bool = false
## Fill fraction the damage trail reaches (>= value while it shows).
var _trail_value: float = 1.0
## Real time (usec) the trail starts draining.
var _trail_drain_usec: int = 0
## Real time (usec) of the last trail step.
var _trail_last_usec: int = 0

## Fill bevel: how much lighter the fill's top row is (Color.lightened amount).
const BEVEL_LIGHT: float = 0.3  # TUNING (not in GDD) art pass UI kit
## Fill bevel: how much darker the fill's bottom row is (Color.darkened amount).
const BEVEL_DARK: float = 0.3  # TUNING (not in GDD) art pass UI kit
## Opacity of a notch line.
const NOTCH_ALPHA: float = 0.45  # TUNING (not in GDD) menu modernization


func _init(p_fill: Color = Palette.HP_FRIENDLY, min_size: Vector2 = Vector2(200, 16)) -> void:
	fill_color = p_fill
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


## Updates the bar; redraws only on change.
func set_values(v: float, t: String = "") -> void:
	v = clampf(v, 0.0, 1.0)
	if is_equal_approx(v, value) and t == text:
		return
	if trail and UiMotion.enabled() and v < value - 0.001:
		var now := Time.get_ticks_usec()
		_trail_value = maxf(_trail_value, value)
		_trail_drain_usec = now + int(InRunUiData.TRAIL_HOLD * 1000000.0)
		_trail_last_usec = now
		set_process(true)
	value = v
	if _trail_value < value:
		_trail_value = value
	text = t
	queue_redraw()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var dt := float(now - _trail_last_usec) / 1000000.0  # Real seconds since the last step.
	_trail_last_usec = now
	if now >= _trail_drain_usec:
		_trail_value = maxf(value, _trail_value - InRunUiData.TRAIL_DRAIN * dt)
	if _trail_value <= value + 0.0005:
		_trail_value = value
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, back_color)
	var w := floorf(size.x * value)  # Fill width (whole px).
	if trail and _trail_value > value:
		var tw := floorf(size.x * _trail_value)  # Trail end (whole px).
		draw_rect(Rect2(Vector2(w, 0.0), Vector2(tw - w, size.y)), InRunUiData.TRAIL_COLOR)
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, size.y)), fill_color)
	if w > 0.0 and size.y >= 6.0:  # Bevel rows just inside the edge row (the frame / border covers the edge).
		draw_rect(Rect2(Vector2(0.0, 1.0), Vector2(w, 1.0)), fill_color.lightened(BEVEL_LIGHT))
		draw_rect(Rect2(Vector2(0.0, size.y - 2.0), Vector2(w, 1.0)), fill_color.darkened(BEVEL_DARK))
	if notch > 0.0 and notch < 1.0:
		var n := int(roundf(1.0 / notch))  # Segments.
		for i in range(1, n):
			var x := floorf(size.x * float(i) / float(n))  # Notch column (whole px).
			draw_rect(Rect2(Vector2(x, 1.0), Vector2(1.0, size.y - 2.0)), Color(0.0, 0.0, 0.0, NOTCH_ALPHA))
	if border_color.a > 0.0:
		var frame := UiTheme.style("bar")  # Kit bar frame (a StyleBoxTexture when its PNG exists).
		if frame is StyleBoxTexture:
			SpriteBank.apply_sharp(self)
			draw_style_box(frame, r.grow(1.0))
		else:
			draw_rect(r, border_color, false, 1.0)
	if text != "":
		SpriteBank.apply_sharp(self)  # Pixel-font text is rasterised at layout size (UiArtData).
		var font := UiTheme.font_for() if UiTheme.font_for() != null else get_theme_default_font()  # Pixel font.
		var fs := UiTheme.font_px(font_size) if UiTheme.font_for() != null else font_size  # Drawn size.
		var y := roundf((size.y + font.get_ascent(fs) - font.get_descent(fs) * 0.5) * 0.5)  # Caps centred, whole px.
		draw_string(font, Vector2(1, y + 1), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color.WHITE)
