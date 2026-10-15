## RotateOverlay: the "turn your device" screen shown while a phone or tablet
## is held in portrait (GDD §15.0 "Mobile browser support"; TouchSupport shows
## and hides it, words and sizes in TouchData). The game is laid out for
## landscape and a browser can only lock the orientation in fullscreen, so
## this opaque layer covers everything above every other layer (and eats the
## taps) until the device is turned; Main pauses a running game meanwhile.
## It draws one block in layout px at the type tiers (the title in Jacquard
## 24, the line in Jersey 10), an upright phone outline, an arrow and the
## same phone turned to landscape, every outline with cut corners, and
## scales the block as a whole to fill TouchData.ROTATE_FILL of the screen
## width. Static: no motion, so nothing to slow down for Reduce motion.
class_name RotateOverlay
extends CanvasLayer

## The full-screen Control that draws the overlay and stops the taps.
var _pane: Control = null


func _init() -> void:
	layer = 128  # Above the HUD, panels and the fade through black.
	visible = false


func _ready() -> void:
	_pane = Control.new()
	_pane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pane.mouse_filter = Control.MOUSE_FILTER_STOP  # Nothing behind it can be tapped.
	_pane.draw.connect(_draw_pane)
	_pane.resized.connect(_pane.queue_redraw)
	add_child(_pane)
	SpriteBank.apply_sharp(_pane)  # Crisp pixel fonts under the block's scale.
	visibility_changed.connect(_pane.queue_redraw)


## Draws the backdrop and the scaled block.
func _draw_pane() -> void:
	var view := _pane.size  # Visible layout area.
	_pane.draw_rect(Rect2(Vector2.ZERO, view), TouchData.ROTATE_BACKDROP)
	var b := TouchData.ROTATE_BLOCK
	var s := minf(view.x * TouchData.ROTATE_FILL / b.x, view.y * TouchData.ROTATE_FILL / b.y)  # Block scale.
	s = maxf(s, 0.1)
	var origin := (view - b * s) * 0.5  # Block top-left (layout px).
	_pane.draw_set_transform(origin, 0.0, Vector2(s, s))
	var col := TouchData.ROTATE_COLOR
	var ph := TouchData.ROTATE_PHONE_SIZE
	var mid := Vector2(b.x * 0.5, ph.y * 0.5 + 4.0)  # Centre of the drawing row.
	var gap := TouchData.ROTATE_GAP
	var upright := Rect2(Vector2(mid.x - gap * 0.5 - ph.x, mid.y - ph.y * 0.5), ph)  # Phone held upright.
	var turned := Rect2(Vector2(mid.x + gap * 0.5, mid.y - ph.x * 0.5), Vector2(ph.y, ph.x))  # Phone in landscape.
	_phone(upright, Color(col, 0.45))
	_phone(turned, col)
	_arrow(Vector2(mid.x - gap * 0.32, mid.y), Vector2(mid.x + gap * 0.32, mid.y), col)
	var title_font := _title_font()
	var title_px := UiTheme.tier_px(UiTheme.Tier.TITLE)  # Jacquard 24 at its one size.
	var ty := ph.y + 30.0 + float(title_px)  # Title baseline.
	_pane.draw_string(title_font, Vector2(0.0, ty), TouchData.ROTATE_TITLE, HORIZONTAL_ALIGNMENT_CENTER, b.x, title_px, UiTheme.TEXT_GOLD)
	var body := UiTheme.font_for()
	var f: Font = body if body != null else ThemeDB.fallback_font
	var body_px := UiTheme.tier_px(UiTheme.Tier.NAME)
	_pane.draw_string(f, Vector2(0.0, ty + 18.0 + float(body_px)), TouchData.ROTATE_TEXT, HORIZONTAL_ALIGNMENT_CENTER, b.x, body_px, UiTheme.TEXT_DIM)
	_pane.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A phone outline in `r` (cut corners, a screen inset and a home dot).
func _phone(r: Rect2, col: Color) -> void:
	var cut := minf(r.size.x, r.size.y) * 0.18  # Corner cut (layout px).
	var outline := TouchControls.chamfer(r, cut)
	_pane.draw_colored_polygon(outline, Color(0.08, 0.05, 0.12))
	outline.append(outline[0])
	_pane.draw_polyline(outline, col, 3.0)
	var inset := minf(r.size.x, r.size.y) * 0.14  # Screen inset (layout px).
	var screen := r.grow(-inset)
	var sp := TouchControls.chamfer(screen, cut * 0.4)
	sp.append(sp[0])
	_pane.draw_polyline(sp, Color(col, 0.5), 1.5)


## A short arrow from `a` to `b` (shaft and a solid head).
func _arrow(a: Vector2, b: Vector2, col: Color) -> void:
	var d := (b - a).normalized()  # Arrow direction.
	var n := Vector2(-d.y, d.x)  # Its normal.
	var head := 14.0  # Head length (layout px).
	_pane.draw_line(a, b - d * head * 0.6, col, 4.0)
	_pane.draw_colored_polygon(PackedVector2Array([b, b - d * head + n * head * 0.7, b - d * head - n * head * 0.7]), col)


## Jacquard 24 (the TITLE tier font), or the pixel font when it is missing.
func _title_font() -> Font:
	var probe := Label.new()  # Reads the font the tier would give a Label.
	UiTheme.set_tier(probe, UiTheme.Tier.TITLE)
	var f := probe.get_theme_font("font")
	probe.free()
	if f != null:
		return f
	return UiTheme.font_for() if UiTheme.font_for() != null else ThemeDB.fallback_font
