## EpilogueScreen — the CAMPAIGN EPILOGUE (EpilogueData; GDD §15.0
## "Ul-Thalos, the Risen Spire"), opened from the main menu's Epilogue button
## (shown once Dawn Extinguished or The Dead God Serves is earned) with
## EpilogueScreen.open_over(parent). An ornate violet panel: the title and
## Back, then the two parts in reading order (the act, a gold heading, the
## paragraphs); a part whose achievement is not earned yet reads "Sealed" with
## its goal. Up / Down or the wheel scroll; Back, Esc or pad B close it and
## the focus returns to the opener. Text sizes are the UiTheme type tiers;
## UiMotion opens and closes it. Under the autotest nothing opens it.
class_name EpilogueScreen
extends Control

## Emitted when the screen is about to be freed.
signal closed

## Px scrolled per Up / Down press.
const SCROLL_STEP: float = 60.0

## Control focused again when the screen closes (may be null).
var return_focus: Control = null
## The Back button.
var back_button: Button
## The text's ScrollContainer.
var _scroll: ScrollContainer


## Creates the screen as a full-screen child of `parent` and returns it.
## The control focused at that moment regains focus when it closes.
static func open_over(parent: Control) -> EpilogueScreen:
	var s := EpilogueScreen.new()
	var vp := parent.get_viewport()  # Null when the parent is not in the tree.
	s.return_focus = vp.gui_get_focus_owner() if vp != null else null
	parent.add_child(s)
	return s


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiTheme.get_theme()
	add_child(UiTheme.backdrop(EpilogueData.BACKDROP_ALPHA))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit (no-op at 720 px).
	var panel := UiTheme.ornate_panel("violet")
	panel.custom_minimum_size = EpilogueData.PANEL_SIZE
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var row := HBoxContainer.new()
	var title := UiTheme.tier_label(EpilogueData.TITLE, UiTheme.Tier.TITLE, UiTheme.TEXT_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(EpilogueData.BACK_WIDTH, EpilogueData.BACK_HEIGHT)
	back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(close)
	row.add_child(back_button)
	vb.add_child(row)
	vb.add_child(UiTheme.divider())
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(_scroll)
	TouchSupport.pass_drags(_scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	_scroll.add_child(col)
	var w := EpilogueData.PANEL_SIZE.x - 90.0  # Text width inside the panel and the scroll bar (px).
	for part: Dictionary in EpilogueData.PARTS:
		col.add_child(UiTheme.tier_label(String(part["act"]), UiTheme.Tier.LABEL, UiTheme.TEXT_DIM))
		if EpilogueData.is_open(part):
			col.add_child(UiTheme.tier_label(String(part["heading"]), UiTheme.Tier.HEADER, UiTheme.TEXT_GOLD))
			for line: String in part["lines"]:
				col.add_child(UiTheme.para(line, w, UiTheme.TEXT))
		else:
			var goal := String((MetaData.ACHIEVEMENTS[String(part["achievement"])] as Dictionary)["description"])
			col.add_child(UiTheme.para(EpilogueData.SEALED % goal, w, UiTheme.TEXT_DIM))
		col.add_child(UiTheme.divider())
	add_child(InputHints.bottom_strip([[[InputHints.raw(KEY_UP, JOY_BUTTON_DPAD_UP), InputHints.raw(KEY_DOWN, JOY_BUTTON_DPAD_DOWN)], "Scroll"], ["ui_cancel", "Back"]]))
	back_button.grab_focus.call_deferred()
	UiMotion.open(self)


## Esc / pad B close; Up / Down scroll.
func _input(event: InputEvent) -> void:
	if UiMotion.is_closing(self):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
		return
	if event.is_action_pressed("ui_up", true) or event.is_action_pressed("ui_down", true):
		get_viewport().set_input_as_handled()
		var dy := SCROLL_STEP * (-1.0 if event.is_action_pressed("ui_up", true) else 1.0)
		_scroll.scroll_vertical = int(float(_scroll.scroll_vertical) + dy)


## Restores focus to the opener and frees the screen.
func close() -> void:
	if UiMotion.is_closing(self):
		return
	closed.emit()
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	UiMotion.close(self, queue_free)
