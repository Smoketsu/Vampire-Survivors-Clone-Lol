## SettingsMenu — options screen opened from the main menu and the pause
## menu (GDD §10.1 "Settings", §10.5 visual options). Menu modernization wave
## 2 (GDD §15.0 "Settings tabs"): three tabs over one ornate panel, no prose,
## one hint strip at the bottom. Every change applies at once through the
## Settings autoload; the file is saved when the menu closes (Back, Esc /
## controller B, or the pause action).
##   Audio   : Master / Music / Effects volume (the kit slider).
##   Video   : Fullscreen, Zoom (Normal / Close), Effects (Full / Reduced:
##             a lighter visual load for phones; EffectsData), Screen shake,
##             Damage numbers, Reduce motion (UI motion instant). Where the
##             browser has no page fullscreen (iPhone Safari) a dim line takes
##             the Fullscreen toggle's place (Settings.fullscreen_mode()).
##   Controls: the twelve rebindable actions in three groups (Move, Actions,
##             Stances): each row shows its keyboard key as a key chip on a
##             button (press it, then any key; controller B or a mouse click
##             cancels; binding a key another action uses swaps the two) and
##             its controller binding as a read-only pad chip (the pad layout
##             is fixed). "Reset keys" restores the defaults after the shared
##             ConfirmDialog (it wraps _on_reset_keys()).
## Tabs: click / focus a tab button, or Q / E (LB / RB on a pad) from
## anywhere. Fully usable with a controller: explicit focus links join the
## tab row and each page, sliders move with left / right, toggles and
## buttons take A, and the first tab is focused on open. Every size, word and
## key is in SettingsUiData.
## Open it with SettingsMenu.open_over(parent, button_to_refocus).
class_name SettingsMenu
extends Control

## Emitted after the menu saved and is about to be freed.
signal closed

## Control focused again when the menu closes (may be null).
var return_focus: Control = null
## Settings bus name -> its volume slider.
var sliders: Dictionary = {}
## Settings bus name -> its "NN%" value label.
var _slider_labels: Dictionary = {}
## Option name ("fullscreen", "screen_shake", "damage_numbers", "reduce_motion") -> CheckButton.
var toggles: Dictionary = {}
## Action -> its rebinding button.
var key_buttons: Dictionary = {}
## Action waiting for a key press ("" = not listening).
var listening_action: String = ""
## Zoom button (cycles ViewData.ZOOM_ORDER).
var zoom_button: Button
## Label showing the zoom level on the zoom button.
var _zoom_value: Label
## Effects quality button (cycles EffectsData.ORDER: Full / Reduced).
var effects_button: Button
## Label showing the effects quality on its button.
var _effects_value: Label
## Reset keys button (Controls tab).
var reset_button: Button
## Back button.
var _back: Button
## Tab buttons, in SettingsUiData.TABS order.
var _tabs: Array[Button] = []
## Page Controls, in SettingsUiData.TABS order (one visible at a time).
var _pages: Array[Control] = []
## Focus targets of each page, in reading order (the first gets focus from
## the tab row; its last leads down to Back).
var _page_focus: Array = []
## Index of the visible tab (SettingsUiData.TABS).
var _tab: int = 0
## The hint strip's "Select" / "Rebind" word.
var _accept_word: Label
## Top key button of each Controls group (their "up" leads to the tab row).
var _bind_tops: Array[Control] = []


## One keyboard binding: a Button showing its key as a key chip (InputHints,
## keyboard style, from the current binding), "..." while listening.
class _KeyButton:
	extends Button
	## Rebindable action shown.
	var action: String = ""
	## Chip drawer over the button (redraws on rebinds).
	var _cap: Control

	func _init(p_action: String) -> void:
		action = p_action
		custom_minimum_size = SettingsUiData.KEY_BUTTON_SIZE
		focus_mode = Control.FOCUS_ALL
		_cap = Control.new()
		_cap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cap.draw.connect(_draw_cap)
		add_child(_cap)

	func _ready() -> void:
		SpriteBank.apply_sharp(_cap)
		Settings.changed.connect(_cap.queue_redraw)

	## Shows the key chip, or the listening caption when `listening`.
	func show_key(listening: bool) -> void:
		text = SettingsUiData.LISTENING if listening else ""
		_cap.visible = not listening
		_cap.queue_redraw()

	func _draw_cap() -> void:
		var g := InputHints.glyph(action, InputHints.Device.KEYBOARD)  # Keyboard chip of the binding.
		var w := float(InputHints.chip_width(g))
		var pos := ((_cap.size - Vector2(w, float(InputHintData.CHIP_HEIGHT))) * 0.5).floor()
		InputHints.draw_chip(_cap, pos, g)


## One read-only pad binding: the action's controller chip (InputHints,
## pad style), centred in its cell.
class _PadCell:
	extends Control
	## Action shown.
	var action: String = ""

	func _init(p_action: String) -> void:
		action = p_action
		custom_minimum_size = Vector2(SettingsUiData.PAD_CELL_WIDTH, InputHintData.CHIP_HEIGHT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _ready() -> void:
		SpriteBank.apply_sharp(self)

	func _draw() -> void:
		var g := InputHints.glyph(action, InputHints.Device.PAD)  # Pad chip (fixed layout).
		var w := float(InputHints.chip_width(g))
		InputHints.draw_chip(self, Vector2(floorf((size.x - w) * 0.5), 0.0), g)


## Creates the menu as a full-screen child of `parent` and returns it.
## `refocus` regains focus when the menu closes.
static func open_over(parent: Control, refocus: Control) -> SettingsMenu:
	var m := SettingsMenu.new()
	m.return_focus = refocus
	parent.add_child(m)
	return m


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UiTheme.backdrop(0.7))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit (no-op at 720 px).
	var root := VBoxContainer.new()  # Title, tabs, panel, Back, hints.
	root.add_theme_constant_override("separation", 12)
	center.add_child(root)
	root.add_child(UiTheme.title(SettingsUiData.TITLE))
	root.add_child(_build_tab_row())
	var panel := UiTheme.ornate_panel("violet")
	root.add_child(panel)
	var stack := Control.new()  # The pages, stacked; one visible.
	stack.custom_minimum_size = SettingsUiData.PAGE_SIZE
	panel.add_child(stack)
	for id: String in SettingsUiData.TABS:
		var page := _build_page(id)
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stack.add_child(page)
		_pages.append(page)
	_back = Button.new()
	_back.text = SettingsUiData.HINT_BACK
	_back.custom_minimum_size = Vector2(SettingsUiData.TAB_SIZE.x * 1.5, SettingsUiData.TAB_SIZE.y)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.set_meta(&"ui_back", true)
	_back.pressed.connect(close)
	root.add_child(_back)
	root.add_child(_build_hints())
	_refresh_keys()
	select_tab(0)
	_tabs[0].grab_focus.call_deferred()
	UiMotion.open(self)  # Fade / rise in.


## The tab row: one button per tab between the previous / next tab chips.
func _build_tab_row() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", SettingsUiData.TAB_GAP)
	row.add_child(InputHints.chip(InputHints.raw(SettingsUiData.TAB_PREV_KEY, SettingsUiData.TAB_PREV_PAD)))
	for i in SettingsUiData.TABS.size():
		var b := Button.new()
		b.text = String(SettingsUiData.TAB_NAMES[SettingsUiData.TABS[i]])
		b.custom_minimum_size = SettingsUiData.TAB_SIZE
		b.focus_mode = Control.FOCUS_ALL
		b.set_meta(&"ui_lift", false)
		b.pressed.connect(select_tab.bind(i))
		b.focus_entered.connect(select_tab.bind(i))
		row.add_child(b)
		_tabs.append(b)
	row.add_child(InputHints.chip(InputHints.raw(SettingsUiData.TAB_NEXT_KEY, SettingsUiData.TAB_NEXT_PAD)))
	return row


## The bottom hint strip: Select (Rebind on Controls) and Back (the tab
## keys sit as chips on both sides of the tab row).
func _build_hints() -> Control:
	var strip := InputHints.strip([
		["ui_accept", SettingsUiData.HINT_SELECT],
		["ui_cancel", SettingsUiData.HINT_BACK],
	])
	var first := strip.get_child(0)  # The accept hint: its last child is the word.
	_accept_word = first.get_child(first.get_child_count() - 1) as Label
	return strip


## Builds the page of tab `id` (a column centred in the page area).
func _build_page(id: String) -> Control:
	var page := VBoxContainer.new()  # The page area; its column is centred both ways.
	page.alignment = BoxContainer.ALIGNMENT_CENTER
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", SettingsUiData.ROW_GAP)
	vb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(vb)
	var focus: Array[Control] = []
	match id:
		"audio":
			_build_audio(vb, focus)
		"video":
			_build_video(vb, focus)
		"controls":
			_build_controls(vb, focus)
	_page_focus.append(focus)
	return page


## Audio: one row per bus (name, kit slider, "80%").
func _build_audio(vb: VBoxContainer, focus: Array[Control]) -> void:
	for bus: String in SettingsUiData.VOLUME_ROWS.keys():
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(SettingsUiData.ROW_WIDTH, SettingsUiData.ROW_HEIGHT)
		row.add_theme_constant_override("separation", 14)
		var name_label := UiTheme.tier_label(String(SettingsUiData.VOLUME_ROWS[bus]), UiTheme.Tier.NAME)
		name_label.custom_minimum_size.x = SettingsUiData.VOLUME_LABEL_WIDTH
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(name_label)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 100.0
		s.step = SettingsUiData.VOLUME_STEP
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.custom_minimum_size = Vector2(150, 24)
		s.add_theme_stylebox_override("focus", UiTheme.style("focus"))
		s.set_value_no_signal(roundf(float(Settings.volumes[bus]) * 100.0))
		s.value_changed.connect(_on_volume_changed.bind(bus))
		row.add_child(s)
		var value_label := UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT_DIM)
		value_label.custom_minimum_size.x = SettingsUiData.VOLUME_VALUE_WIDTH
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(value_label)
		sliders[bus] = s
		_slider_labels[bus] = value_label
		vb.add_child(row)
		focus.append(s)
		_refresh_slider_label(bus)


## Video: the toggles and the zoom level.
func _build_video(vb: VBoxContainer, focus: Array[Control]) -> void:
	Settings.sync_fullscreen()  # Web: the browser's real fullscreen state.
	var setters: Dictionary = {
		"fullscreen": [Settings.fullscreen, Settings.set_fullscreen],
		"screen_shake": [Settings.screen_shake, Settings.set_screen_shake],
		"damage_numbers": [Settings.damage_numbers, Settings.set_damage_numbers],
		"reduce_motion": [Settings.reduce_motion, Settings.set_reduce_motion],
	}  # Option key -> [current value, Settings setter].
	for key: String in SettingsUiData.TOGGLES.keys():
		if key == "fullscreen" and Settings.fullscreen_mode() != Settings.FULLSCREEN_TOGGLE:
			_add_fullscreen_note(vb)  # iPhone Safari: no page fullscreen (a line, or nothing).
			_add_zoom(vb, focus)
			_add_effects(vb, focus)
			continue
		var c := CheckButton.new()
		c.text = String(SettingsUiData.TOGGLES[key])
		UiTheme.set_tier(c, UiTheme.Tier.NAME)
		c.set_pressed_no_signal(bool(setters[key][0]))
		# An "on" row looks like an "off" row: the kit toggle icon shows the state
		# (the theme's pressed look would light the whole row up).
		c.add_theme_stylebox_override("pressed", UiTheme.style("button", "violet", "normal"))
		c.add_theme_stylebox_override("hover_pressed", UiTheme.style("button", "violet", "hover"))
		c.add_theme_color_override("font_pressed_color", UiTheme.TEXT)
		c.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
		c.custom_minimum_size = Vector2(SettingsUiData.ROW_WIDTH, SettingsUiData.ROW_HEIGHT)
		var setter: Callable = setters[key][1]
		c.toggled.connect(func(v: bool) -> void: setter.call(v))
		vb.add_child(c)
		toggles[key] = c
		focus.append(c)
		if key == "fullscreen":
			_add_zoom(vb, focus)
			_add_effects(vb, focus)


## Web build without page fullscreen (Settings.fullscreen_mode()): a dim, unfocusable
## line in place of the Fullscreen toggle saying what works instead (nothing when the
## game already runs fullscreen from the home screen).
func _add_fullscreen_note(vb: VBoxContainer) -> void:
	var mode := Settings.fullscreen_mode()  # Settings.FULLSCREEN_* value.
	if mode == Settings.FULLSCREEN_NONE:
		return
	var text := SettingsUiData.FULLSCREEN_HOME_SCREEN if mode == Settings.FULLSCREEN_HOME_SCREEN else SettingsUiData.FULLSCREEN_UNAVAILABLE  # The line's words.
	var note := UiTheme.tier_label(text, UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	note.custom_minimum_size = Vector2(SettingsUiData.ROW_WIDTH, SettingsUiData.ROW_HEIGHT)
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vb.add_child(note)


## The zoom row: a button cycling ViewData.ZOOM_ORDER, its value on the right.
func _add_zoom(vb: VBoxContainer, focus: Array[Control]) -> void:
	zoom_button = Button.new()
	zoom_button.text = SettingsUiData.ZOOM
	zoom_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	zoom_button.custom_minimum_size = Vector2(SettingsUiData.ROW_WIDTH, SettingsUiData.ROW_HEIGHT)
	zoom_button.pressed.connect(_on_zoom_pressed)
	_zoom_value = UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT_GOLD)
	_zoom_value.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_zoom_value.offset_left = -160.0
	_zoom_value.offset_right = -12.0
	_zoom_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_zoom_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	zoom_button.add_child(_zoom_value)
	vb.add_child(zoom_button)
	focus.append(zoom_button)
	_refresh_zoom()


## The effects row: a button cycling EffectsData.ORDER (Full / Reduced),
## its value on the right (like the zoom row).
func _add_effects(vb: VBoxContainer, focus: Array[Control]) -> void:
	effects_button = Button.new()
	effects_button.text = SettingsUiData.EFFECTS
	effects_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	effects_button.custom_minimum_size = Vector2(SettingsUiData.ROW_WIDTH, SettingsUiData.ROW_HEIGHT)
	effects_button.pressed.connect(_on_effects_pressed)
	_effects_value = UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT_GOLD)
	_effects_value.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_effects_value.offset_left = -160.0
	_effects_value.offset_right = -12.0
	_effects_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_effects_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effects_button.add_child(_effects_value)
	vb.add_child(effects_button)
	focus.append(effects_button)
	_refresh_effects()


## Controls: three binding groups side by side, then Reset keys.
func _build_controls(vb: VBoxContainer, focus: Array[Control]) -> void:
	var groups := HBoxContainer.new()
	groups.add_theme_constant_override("separation", SettingsUiData.GROUP_GAP)
	vb.add_child(groups)
	var columns: Array = []  # Per group: its key buttons, top to bottom.
	for g: Array in SettingsUiData.GROUPS:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", SettingsUiData.BIND_ROW_GAP)
		groups.add_child(col)
		var head := HBoxContainer.new()  # Group label, then the Key / Pad captions over their columns.
		head.add_theme_constant_override("separation", 6)
		var gl := UiTheme.tier_label(String(g[0]), UiTheme.Tier.LABEL, UiTheme.TEXT_GOLD)
		gl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(gl)
		for cap: Array in [[SettingsUiData.COL_KEY, SettingsUiData.KEY_BUTTON_SIZE.x], [SettingsUiData.COL_PAD, SettingsUiData.PAD_CELL_WIDTH]]:
			var l := UiTheme.tier_label(String(cap[0]), UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
			l.custom_minimum_size.x = float(cap[1])
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			head.add_child(l)
		col.add_child(head)
		var buttons: Array[Control] = []
		for action: String in g[1]:
			var row := HBoxContainer.new()
			row.custom_minimum_size.y = SettingsUiData.BIND_ROW_HEIGHT
			row.add_theme_constant_override("separation", 6)
			var l := UiTheme.tier_label(String(SettingsUiData.SHORT_LABELS.get(action, action)), UiTheme.Tier.NAME)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l.custom_minimum_size.x = 120.0
			row.add_child(l)
			var b := _KeyButton.new(action)
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			b.pressed.connect(_start_listening.bind(action))
			row.add_child(b)
			row.add_child(_PadCell.new(action))
			col.add_child(row)
			key_buttons[action] = b
			buttons.append(b)
		columns.append(buttons)
	reset_button = Button.new()
	reset_button.text = SettingsUiData.RESET
	reset_button.custom_minimum_size = SettingsUiData.RESET_SIZE
	reset_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	# Reset keys asks first (the shared ConfirmDialog wraps the handler; not a danger action).
	reset_button.pressed.connect(func() -> void: ConfirmDialog.ask(self, ConfirmData.RESET_KEYS[0], ConfirmData.RESET_KEYS[1], ConfirmData.RESET_KEYS[2], _on_reset_keys, false))
	var gap := Control.new()
	gap.custom_minimum_size.y = 6.0
	vb.add_child(gap)
	vb.add_child(reset_button)
	# Grid focus: up / down inside a group, left / right across groups at the
	# same row, down from the last row to Reset keys.
	for c in columns.size():
		var col: Array = columns[c]
		for r in col.size():
			var b: Control = col[r]
			var left: Array = columns[c - 1] if c > 0 else col
			var right: Array = columns[c + 1] if c < columns.size() - 1 else col
			b.focus_neighbor_bottom = b.get_path_to(col[r + 1] if r < col.size() - 1 else reset_button)
			if r > 0:
				b.focus_neighbor_top = b.get_path_to(col[r - 1])
			b.focus_neighbor_left = b.get_path_to(left[r])
			b.focus_neighbor_right = b.get_path_to(right[r])
	var last_col: Array = columns[columns.size() - 1]
	reset_button.focus_neighbor_top = reset_button.get_path_to(last_col[last_col.size() - 1])
	reset_button.focus_neighbor_left = reset_button.get_path_to(reset_button)
	reset_button.focus_neighbor_right = reset_button.get_path_to(reset_button)
	focus.append_array(columns[0])
	focus.append(reset_button)
	_bind_tops.clear()
	for col: Array in columns:
		_bind_tops.append(col[0])


# =====================================================================================
# Tabs
# =====================================================================================

## Number of tabs.
func tab_count() -> int:
	return _tabs.size()


## Shows tab `i`: its page, its button in gold, and re-links focus so the
## tab row leads into this page and the page's last control leads to Back.
func select_tab(i: int) -> void:
	i = wrapi(i, 0, _tabs.size())
	if listening_action != "":
		_stop_listening()
	_tab = i
	for k in _tabs.size():
		_pages[k].visible = k == i
		UiTheme.style_button(_tabs[k], "button", "gold" if k == i else "")
		_tabs[k].add_theme_color_override("font_color", UiTheme.TEXT_GOLD if k == i else UiTheme.TEXT_DIM)
	var focus: Array = _page_focus[i]
	var first: Control = focus[0]
	var last: Control = focus[focus.size() - 1]
	for k in _tabs.size():
		var t: Button = _tabs[k]
		t.focus_neighbor_bottom = t.get_path_to(first)
		t.focus_neighbor_top = t.get_path_to(t)
		t.focus_neighbor_left = t.get_path_to(_tabs[maxi(k - 1, 0)])
		t.focus_neighbor_right = t.get_path_to(_tabs[mini(k + 1, _tabs.size() - 1)])
	if SettingsUiData.TABS[i] == "controls":
		for top: Control in _bind_tops:
			top.focus_neighbor_top = top.get_path_to(_tabs[i])
	else:
		for j in focus.size():
			var c: Control = focus[j]
			c.focus_neighbor_top = c.get_path_to(focus[j - 1] if j > 0 else _tabs[i])
			c.focus_neighbor_bottom = c.get_path_to(focus[j + 1] if j < focus.size() - 1 else _back)
			if not c is HSlider:
				c.focus_neighbor_left = c.get_path_to(c)
				c.focus_neighbor_right = c.get_path_to(c)
	last.focus_neighbor_bottom = last.get_path_to(_back)
	_back.focus_neighbor_top = _back.get_path_to(last)
	_back.focus_neighbor_bottom = _back.get_path_to(_back)
	_back.focus_neighbor_left = _back.get_path_to(_back)
	_back.focus_neighbor_right = _back.get_path_to(_back)
	if _accept_word != null:
		_accept_word.text = SettingsUiData.HINT_REBIND if SettingsUiData.TABS[i] == "controls" else SettingsUiData.HINT_SELECT


## Q / E (LB / RB): the previous / next tab, focus on its tab button (or
## kept in the page when it was there: then on the new page's first control).
func _step_tab(d: int) -> void:
	var f := get_viewport().gui_get_focus_owner()
	# True when a tab button has focus (`_tabs` is a typed Button array, so only a Button may be looked up).
	var on_tabs := f is Button and _tabs.has(f as Button)
	select_tab(_tab + d)
	Sfx.play("ui_hover")
	if on_tabs:
		_tabs[_tab].grab_focus()
	else:
		(_page_focus[_tab][0] as Control).grab_focus()


# =====================================================================================
# Options
# =====================================================================================

## Cycles the camera zoom level (Normal <-> Close, ViewData.ZOOM_ORDER).
func _on_zoom_pressed() -> void:
	var i := ViewData.ZOOM_ORDER.find(Settings.zoom_id)  # Current position in the cycle.
	Settings.set_zoom(String(ViewData.ZOOM_ORDER[(i + 1) % ViewData.ZOOM_ORDER.size()]))
	_refresh_zoom()


## Shows the current zoom level on its button.
func _refresh_zoom() -> void:
	_zoom_value.text = String(ViewData.ZOOM_LEVELS[Settings.zoom_id]["label"])


## Cycles the effects quality (Full <-> Reduced, EffectsData.ORDER).
func _on_effects_pressed() -> void:
	var i := EffectsData.ORDER.find(Settings.effects)  # Current position in the cycle.
	Settings.set_effects(EffectsData.ORDER[(i + 1) % EffectsData.ORDER.size()])
	_refresh_effects()


## Shows the current effects quality on its button.
func _refresh_effects() -> void:
	_effects_value.text = String(EffectsData.LABELS.get(Settings.effects, ""))


func _on_volume_changed(value: float, bus: String) -> void:
	Settings.set_volume(bus, value / 100.0)
	_refresh_slider_label(bus)


func _refresh_slider_label(bus: String) -> void:
	(_slider_labels[bus] as Label).text = "%d%%" % int((sliders[bus] as HSlider).value)


## Updates every key button (key chip, or "..." while listening).
func _refresh_keys() -> void:
	for action: String in key_buttons.keys():
		(key_buttons[action] as _KeyButton).show_key(action == listening_action)


func _start_listening(action: String) -> void:
	listening_action = action
	_refresh_keys()


func _stop_listening() -> void:
	var b: Button = key_buttons.get(listening_action, null)
	listening_action = ""
	_refresh_keys()
	if b != null:
		b.grab_focus()


## Reset keys confirmed: restores every default key binding at once (the
## Reset keys button asks first through the shared ConfirmDialog).
func _on_reset_keys() -> void:
	listening_action = ""
	Settings.reset_bindings()
	_refresh_keys()


## Saves, restores focus to the opener and frees the menu.
func close() -> void:
	if UiMotion.is_closing(self):
		return
	Settings.save_settings()
	closed.emit()
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	UiMotion.close(self, queue_free)  # Quick fade out, then freed.


## Key capture runs in _input (before the GUI and before PauseMenu's
## _unhandled_input) so the captured key, Esc and B never leak through.
## Also: Q / E and LB / RB switch tabs; Esc / B / pause close.
func _input(event: InputEvent) -> void:
	if listening_action != "":
		var key := event as InputEventKey
		if key != null:
			if key.pressed and not key.echo:
				var code := int(key.physical_keycode) if key.physical_keycode != KEY_NONE else int(key.keycode)
				Settings.set_binding(listening_action, code)
				_stop_listening()
			get_viewport().set_input_as_handled()
		elif (event is InputEventJoypadButton or event is InputEventMouseButton) and event.is_pressed():
			_stop_listening()
			get_viewport().set_input_as_handled()
		return
	var k := event as InputEventKey
	if k != null and k.pressed and not k.echo:
		var code := int(k.physical_keycode) if k.physical_keycode != KEY_NONE else int(k.keycode)
		if code == SettingsUiData.TAB_PREV_KEY or code == SettingsUiData.TAB_NEXT_KEY:
			get_viewport().set_input_as_handled()
			_step_tab(-1 if code == SettingsUiData.TAB_PREV_KEY else 1)
			return
	var jb := event as InputEventJoypadButton
	if jb != null and jb.pressed and (jb.button_index == SettingsUiData.TAB_PREV_PAD or jb.button_index == SettingsUiData.TAB_NEXT_PAD):
		get_viewport().set_input_as_handled()
		_step_tab(-1 if jb.button_index == SettingsUiData.TAB_PREV_PAD else 1)
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
