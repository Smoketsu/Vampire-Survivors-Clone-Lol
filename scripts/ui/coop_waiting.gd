## CoopWaiting: the non-blocking "Waiting for partner" panel (GDD §15.0 "Co-op
## HUD and visuals"; CoopUi.show_waiting() / clear_waiting(), called by the
## lockstep driver: "Your partner is choosing a card", "Paused by your
## partner", "Connection is slow"). A full-rect Control on its own CanvasLayer
## (CoopHudData.WAITING_LAYER, over the HUD and the run's panels) that never
## takes input: a small violet kit panel low in the middle of the screen (over
## the ability bar, between the touch joystick and buttons) with the NAME-tier
## headline, the caller's BODY line and three soul dots that light in a slow
## wave on real time (still under the autotest and with Reduce motion). It
## opens and hides through UiMotion (instant under the autotest and Reduce
## motion), with no sound: it is a status, not a screen. Processes while the
## tree is paused. Purely visual.
class_name CoopWaiting
extends Control

## The panel (its content: headline, line, dots).
var _panel: PanelContainer
## The caller's line under the headline.
var _line: Label
## The soul dots row (drawn by _draw_dots()).
var _dots: Control
## Times show() was called with a new text (CoopUi's report).
var shows: int = 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS  # Animates while a pause holds the run.
	visible = false
	var holder := VBoxContainer.new()  # Bottom-centre anchor (UiMotion moves the first Container child).
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.anchor_left = 0.5
	holder.anchor_right = 0.5
	holder.anchor_top = 1.0
	holder.anchor_bottom = 1.0
	holder.offset_left = -CoopHudData.WAITING_WIDTH * 0.5
	holder.offset_right = CoopHudData.WAITING_WIDTH * 0.5
	holder.offset_bottom = -CoopHudData.WAITING_BOTTOM
	holder.offset_top = -CoopHudData.WAITING_BOTTOM
	holder.grow_horizontal = Control.GROW_DIRECTION_BOTH
	holder.grow_vertical = Control.GROW_DIRECTION_BEGIN  # Grows upward from its bottom edge.
	holder.alignment = BoxContainer.ALIGNMENT_END
	add_child(holder)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiTheme.style("panel", "violet"))
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.custom_minimum_size = Vector2(CoopHudData.WAITING_WIDTH, 0)
	holder.add_child(_panel)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 0)
	_panel.add_child(vb)
	var head := HBoxContainer.new()  # Headline and the dots beside it.
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 10)
	vb.add_child(head)
	var title := UiTheme.tier_label(CoopHudData.WAITING_TITLE, UiTheme.Tier.NAME, UiTheme.TEXT)
	head.add_child(title)
	_dots = Control.new()
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dots.custom_minimum_size = Vector2(CoopHudData.WAITING_DOT_SPACING * float(CoopHudData.WAITING_DOTS), 12.0)
	_dots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_dots.draw.connect(_draw_dots)
	head.add_child(_dots)
	_line = UiTheme.tier_label("", UiTheme.Tier.BODY, CoopHudData.PARTNER)
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_line)


func _process(_delta: float) -> void:
	if visible and UiMotion.enabled():
		_dots.queue_redraw()


## Shows the panel with line `text` (replaces the line when already shown).
func show_text(text: String) -> void:
	if _line.text != text or not visible:
		shows += 1
	_line.text = text
	_line.visible = text != ""
	if not visible or UiMotion.is_closing(self):
		UiMotion.open(self, false)
	_dots.queue_redraw()


## Hides the panel (no-op when hidden).
func clear() -> void:
	if visible:
		UiMotion.hide(self, false)


## True while the panel shows (or is fading out).
func showing() -> bool:
	return visible and not UiMotion.is_closing(self)


## The text on show ("" when hidden).
func text() -> String:
	return _line.text if showing() else ""


## The three soul dots: one lit at a time in a slow wave (real time), all at
## rest while motion is off.
func _draw_dots() -> void:
	var n := CoopHudData.WAITING_DOTS
	var lit := -1.0  # Wave position in dots (-1 = no wave).
	if UiMotion.enabled():
		lit = fmod(float(Time.get_ticks_msec()) / 1000.0, CoopHudData.WAITING_DOT_PERIOD) / CoopHudData.WAITING_DOT_PERIOD * float(n + 1) - 0.5
	for i in n:
		var c := Vector2(CoopHudData.WAITING_DOT_SPACING * (float(i) + 0.5), _dots.size.y * 0.5).round()
		var k := 0.0 if lit < 0.0 else clampf(1.0 - absf(float(i) - lit), 0.0, 1.0)  # 1 = the lit dot.
		var a := lerpf(CoopHudData.WAITING_DOT_DIM, CoopHudData.WAITING_DOT_LIT, k) if lit >= 0.0 else 0.75
		_dots.draw_circle(c, CoopHudData.WAITING_DOT_RADIUS + 1.0, Color(CoopHudData.INK, a))
		_dots.draw_circle(c, CoopHudData.WAITING_DOT_RADIUS, Color(CoopHudData.PARTNER, a))
