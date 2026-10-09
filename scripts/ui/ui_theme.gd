## UiTheme — builds the shared dark-gothic UI Theme in code (no .tres assets):
## violet-bordered panels and buttons on near-black purple, bone-white text.
## Built once and cached; every UI root assigns it so children inherit it.
class_name UiTheme
extends RefCounted

## Default font size for all controls (px).
const FONT_SIZE: int = 16
## Panel / button background.
const BG := Color(0.08, 0.05, 0.12, 0.94)
## Hovered / focused button background.
const BG_HOVER := Color(0.2, 0.11, 0.3, 0.97)
## Pressed button background.
const BG_PRESSED := Color(0.3, 0.16, 0.42, 1.0)
## Border colour of panels and buttons.
const BORDER := Color(0.45, 0.3, 0.7)
## Border colour for focused controls (controller / keyboard navigation).
const BORDER_FOCUS := Color(0.55, 1.0, 0.65)
## Main text colour.
const TEXT := Color(0.92, 0.9, 0.84)
## Dim secondary text colour.
const TEXT_DIM := Color(0.68, 0.64, 0.74)
## Highlight text for stat deltas.
const TEXT_GOOD := Color(0.55, 1.0, 0.65)
## Gold text for banners / titles.
const TEXT_GOLD := Color(1.0, 0.84, 0.4)

## Cached theme instance.
static var _theme: Theme = null


## Returns the shared Theme, building it on first use.
static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = FONT_SIZE
	t.set_stylebox("normal", "Button", box(BG, BORDER))
	t.set_stylebox("hover", "Button", box(BG_HOVER, BORDER))
	t.set_stylebox("pressed", "Button", box(BG_PRESSED, BORDER))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), BORDER_FOCUS, 3))
	t.set_stylebox("disabled", "Button", box(BG, BORDER.darkened(0.5)))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", TEXT_GOOD)
	t.set_stylebox("panel", "Panel", box(BG, BORDER))
	t.set_stylebox("panel", "PanelContainer", box(BG, BORDER))
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.8))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	_theme = t
	return t


## Flat style box with a border and rounded corners.
static func box(bg: Color, border: Color, border_width: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


## Convenience: creates a Label with text, font size and colour.
static func label(text: String, size: int = FONT_SIZE, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Convenience: creates a full-screen dimming backdrop.
static func backdrop(alpha: float = 0.65) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.02, 0.0, 0.04, alpha)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r
