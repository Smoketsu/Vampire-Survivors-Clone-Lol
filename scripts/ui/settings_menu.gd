## SettingsMenu — options screen opened from the main menu and the pause
## menu (GDD §10.1 "Settings", §10.5 visual options). Every change applies
## at once through the Settings autoload; the file is saved when the menu
## closes (Back, Esc / controller B, or the pause action).
##   Left column : Master / Music / SFX volume sliders; Fullscreen, Screen
##                 shake, Damage numbers and Reduce motion toggles.
##   Right column: keyboard rebinding for the Settings.REBINDABLE actions
##                 (press a binding, then any key; controller B or a mouse
##                 click cancels), and "Reset keys".
## Fully usable with a controller: sliders move with left / right, toggles
## and buttons take A, and the first slider is focused on open. Under the
## key rows an InputHints strip (rebind / back chips of the current device
## and bindings) replaces the old prose. Text sizes are UiTheme type tiers:
## the title in Jacquard 24, LABEL section labels, BODY rows and key buttons.
## Open it with SettingsMenu.open_over(parent, button_to_refocus).
class_name SettingsMenu
extends Control

## Emitted after the menu saved and is about to be freed.
signal closed

## Volume slider rows: Settings bus name -> label text.
const VOLUME_ROWS: Dictionary = {"Master": "Master", "Music": "Music", "SFX": "Effects"}
## Width (px) of each of the two columns.
const COLUMN_WIDTH: float = 330.0
## Height (px) of a key-binding button and of Reset keys. With KEY_ROW_GAP it
## keeps the whole menu (11 rebindable actions) inside the 720 px layout,
## Back button included (34 / 6 overflowed it by ~40 px).
const KEY_ROW_HEIGHT: float = 30.0  # TUNING (not in GDD) layout fit
## Vertical gap (px) between the key-binding rows.
const KEY_ROW_GAP: int = 3  # TUNING (not in GDD) layout fit

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
## Back button.
var _back: Button
## Zoom button (cycles ViewData.ZOOM_ORDER).
var zoom_button: Button


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
	var panel := PanelContainer.new()
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)
	root.add_child(UiTheme.title("Settings"))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	root.add_child(cols)
	cols.add_child(_build_left())
	cols.add_child(_build_right())
	_back = Button.new()
	_back.text = "Back"
	_back.custom_minimum_size = Vector2(0, 44)
	_back.pressed.connect(close)
	root.add_child(_back)
	(sliders["Master"] as HSlider).grab_focus.call_deferred()
	UiMotion.open(self)  # Fade / rise in.


## Audio sliders and feel / display toggles.
func _build_left() -> Control:
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	vb.add_theme_constant_override("separation", 8)
	vb.add_child(UiTheme.tier_label("Audio", UiTheme.Tier.LABEL, UiTheme.TEXT_GOLD))
	for bus: String in VOLUME_ROWS.keys():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var name_label := UiTheme.tier_label(VOLUME_ROWS[bus], UiTheme.Tier.BODY)
		name_label.custom_minimum_size = Vector2(70, 0)
		row.add_child(name_label)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 100.0
		s.step = 5.0
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.custom_minimum_size = Vector2(150, 24)
		_style_slider(s)
		s.set_value_no_signal(roundf(float(Settings.volumes[bus]) * 100.0))
		s.value_changed.connect(_on_volume_changed.bind(bus))
		row.add_child(s)
		var value_label := UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
		value_label.custom_minimum_size = Vector2(48, 0)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value_label)
		sliders[bus] = s
		_slider_labels[bus] = value_label
		vb.add_child(row)
		_refresh_slider_label(bus)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vb.add_child(gap)
	vb.add_child(UiTheme.tier_label("Display and feel", UiTheme.Tier.LABEL, UiTheme.TEXT_GOLD))
	_add_toggle(vb, "fullscreen", "Fullscreen", Settings.fullscreen, Settings.set_fullscreen)
	_add_toggle(vb, "screen_shake", "Screen shake", Settings.screen_shake, Settings.set_screen_shake)
	_add_toggle(vb, "damage_numbers", "Damage numbers", Settings.damage_numbers, Settings.set_damage_numbers)
	_add_toggle(vb, "reduce_motion", "Reduce motion", Settings.reduce_motion, Settings.set_reduce_motion)
	zoom_button = Button.new()
	zoom_button.custom_minimum_size = Vector2(0, 36)
	UiTheme.set_tier(zoom_button, UiTheme.Tier.BODY)  # An option row, like the toggles.
	zoom_button.pressed.connect(_on_zoom_pressed)
	vb.add_child(zoom_button)
	_refresh_zoom()
	return vb


## Cycles the camera zoom level (Normal <-> Close, ViewData.ZOOM_ORDER).
func _on_zoom_pressed() -> void:
	var i := ViewData.ZOOM_ORDER.find(Settings.zoom_id)  # Current position in the cycle.
	Settings.set_zoom(String(ViewData.ZOOM_ORDER[(i + 1) % ViewData.ZOOM_ORDER.size()]))
	_refresh_zoom()


## Shows the current zoom level on its button.
func _refresh_zoom() -> void:
	zoom_button.text = "Zoom: %s" % String(ViewData.ZOOM_LEVELS[Settings.zoom_id]["label"])


## Keyboard rebinding rows.
func _build_right() -> Control:
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	vb.add_theme_constant_override("separation", KEY_ROW_GAP)
	vb.add_child(UiTheme.tier_label("Keyboard", UiTheme.Tier.LABEL, UiTheme.TEXT_GOLD))
	for action: String in Settings.REBINDABLE:
		var row := HBoxContainer.new()
		var l := UiTheme.tier_label(String(Settings.ACTION_LABELS.get(action, action)), UiTheme.Tier.BODY)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, KEY_ROW_HEIGHT)
		UiTheme.set_tier(b, UiTheme.Tier.BODY)  # Key names in a 30 px row.
		b.pressed.connect(_start_listening.bind(action))
		row.add_child(b)
		key_buttons[action] = b
		vb.add_child(row)
	var reset := Button.new()
	reset.text = "Reset keys"
	reset.custom_minimum_size = Vector2(0, KEY_ROW_HEIGHT)
	UiTheme.set_tier(reset, UiTheme.Tier.BODY)
	reset.pressed.connect(_on_reset_keys)
	vb.add_child(reset)
	vb.add_child(InputHints.strip([["ui_accept", "Rebind"], ["ui_cancel", "Back"]]))
	var note := UiTheme.tier_label("Arrow keys and the pad stay bound.", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(note)
	_refresh_keys()
	return vb


## Adds a CheckButton bound to a Settings setter.
func _add_toggle(parent: Control, key: String, text: String, on: bool, setter: Callable) -> void:
	var c := CheckButton.new()
	c.text = text
	c.set_pressed_no_signal(on)
	c.custom_minimum_size = Vector2(0, 36)
	c.toggled.connect(func(v: bool) -> void: setter.call(v))
	parent.add_child(c)
	toggles[key] = c


## Gives a slider the UI theme's colours and a visible focus border.
func _style_slider(s: HSlider) -> void:
	if UiTheme.has_kit_slider():  # The Theme's kit track, fill and grabber (UiTheme._kit_slider()).
		s.add_theme_stylebox_override("focus", UiTheme.box(Color(0, 0, 0, 0), UiTheme.BORDER_FOCUS, 2))
		return
	var track := UiTheme.box(Color(0.03, 0.02, 0.05), UiTheme.BORDER, 1)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	s.add_theme_stylebox_override("slider", track)
	var fill := UiTheme.box(Palette.VIOLET.darkened(0.25), Palette.VIOLET, 1)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	s.add_theme_stylebox_override("focus", UiTheme.box(Color(0, 0, 0, 0), UiTheme.BORDER_FOCUS, 2))


func _on_volume_changed(value: float, bus: String) -> void:
	Settings.set_volume(bus, value / 100.0)
	_refresh_slider_label(bus)


func _refresh_slider_label(bus: String) -> void:
	(_slider_labels[bus] as Label).text = "%d%%" % int((sliders[bus] as HSlider).value)


## Updates every key button's caption.
func _refresh_keys() -> void:
	for action: String in key_buttons.keys():
		var b: Button = key_buttons[action]
		b.text = "Press a key..." if action == listening_action else Settings.key_name(action)


func _start_listening(action: String) -> void:
	listening_action = action
	_refresh_keys()


func _stop_listening() -> void:
	var b: Button = key_buttons.get(listening_action, null)
	listening_action = ""
	_refresh_keys()
	if b != null:
		b.grab_focus()


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
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
