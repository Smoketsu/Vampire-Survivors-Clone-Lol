## PauseMenu — Esc / controller Start pause screen with Resume, Restart and
## Main Menu (GDD §4 "Esc: Pause/settings"). It also owns the "pause" input
## handling because it keeps processing while the tree is paused.
class_name PauseMenu
extends Control

## Resume button pressed (or Esc while open).
signal resume_pressed
## Restart button pressed.
signal restart_pressed
## Main Menu button pressed.
signal main_menu_pressed

## Owning run (asked whether pausing is allowed right now).
var game: Game
## Resume button (focused on open for keyboard / controller users).
var _resume: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	add_child(UiTheme.backdrop(0.6))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(280, 0)
	panel.add_child(vb)
	var title := UiTheme.label("PAUSED", 32, UiTheme.TEXT_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	_resume = _button(vb, "Resume", func() -> void: resume_pressed.emit())
	_button(vb, "Restart", func() -> void: restart_pressed.emit())
	_button(vb, "Main Menu", func() -> void: main_menu_pressed.emit())


## Adds a full-width button to `parent`.
func _button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## Shows the menu and focuses Resume.
func open() -> void:
	visible = true
	_resume.grab_focus.call_deferred()


## Hides the menu.
func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and game != null and game.can_toggle_pause():
		get_viewport().set_input_as_handled()
		game.toggle_pause()
