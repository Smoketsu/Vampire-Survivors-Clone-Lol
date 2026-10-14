## PauseMenu — Esc / controller Start pause screen with Resume, Recipes,
## Settings, Restart and Main Menu (GDD §4 "Esc: Pause/settings"). Recipes
## opens the RecipesPanel view of the discovered evolution recipes (owner
## decision "Evolution recipe book", GDD §15.0). It also owns the "pause" input
## handling because it keeps processing while the tree is paused. While the
## menu is open, ui_cancel (Esc / controller B) also resumes. Under the
## buttons an InputHints strip (move, Shadow Bolt aim, resume: chips of the
## current device and bindings), then one row per army stance (its key chip,
## name and description, StanceData). Text sizes are UiTheme type tiers.
class_name PauseMenu
extends Control

## Resume button pressed (or Esc while open).
signal resume_pressed
## Restart button pressed.
signal restart_pressed
## Main Menu button pressed.
signal main_menu_pressed

## Width (layout px) of the army stance help rows.
const STANCE_WIDTH: float = 620.0
## Width (layout px) of a stance name column in the help rows.
const STANCE_NAME_WIDTH: float = 140.0

## Owning run (asked whether pausing is allowed right now).
var game: Game
## Resume button (focused on open for keyboard / controller users).
var _resume: Button
## Recipes button (regains focus when the Recipes view closes).
var _recipes_btn: Button
## Open Recipes view (null when closed; freed when the menu closes).
var _recipes: RecipesPanel = null
## Army stance help rows (rebuilt on open, so the locked state is current;
## the key chips follow rebinds and the device by themselves).
var _stance_box: VBoxContainer


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
	vb.add_child(UiTheme.title("Paused"))
	_resume = _button(vb, "Resume", func() -> void: resume_pressed.emit())
	_recipes_btn = _button(vb, "Recipes", _open_recipes)
	_button(vb, "Settings", func() -> void: SettingsMenu.open_over(self, get_viewport().gui_get_focus_owner()))
	_button(vb, "Restart", func() -> void: restart_pressed.emit())
	_button(vb, "Main Menu", func() -> void: main_menu_pressed.emit())
	vb.add_child(InputHints.strip([[InputHints.MOVE, "Move"], ["toggle_aim", "Bolt aim"], ["ui_cancel", "Resume"]]))
	vb.add_child(UiTheme.tier_label("Army stance", UiTheme.Tier.LABEL, UiTheme.TEXT_DIM))
	_stance_box = VBoxContainer.new()
	_stance_box.add_theme_constant_override("separation", 4)
	_stance_box.custom_minimum_size = Vector2(STANCE_WIDTH, 0)
	vb.add_child(_stance_box)


## Rebuilds the army stance rows: per stance its key chip, its name (and
## "locked" when the Ossuary unlock is missing) and its description.
func _build_stance_help() -> void:
	for c in _stance_box.get_children():
		c.queue_free()
	for i in StanceData.ORDER.size():
		var id: String = StanceData.ORDER[i]
		var d := StanceData.def(id)
		var locked := game != null and not game.stance.is_unlocked(id)  # Needs its Ossuary unlock.
		var row := HBoxContainer.new()  # Chip | name | description.
		row.add_theme_constant_override("separation", 8)
		var chip := InputHints.chip(StanceData.ACTIONS[i])
		chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(chip)
		var name_l := UiTheme.tier_label(String(d["display_name"]) + (" (locked)" if locked else ""), UiTheme.Tier.BODY, (d["color"] as Color).lightened(0.3) if not locked else UiTheme.TEXT_DIM)
		name_l.custom_minimum_size = Vector2(STANCE_NAME_WIDTH, 0)
		name_l.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(name_l)
		var desc := UiTheme.para(String(d["description"]), 0.0, UiTheme.TEXT_DIM)
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(desc)
		_stance_box.add_child(row)


## Adds a full-width button to `parent`.
func _button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## Opens the Recipes view over the menu (refocusing the Recipes button after).
func _open_recipes() -> void:
	if _recipes != null and is_instance_valid(_recipes):
		return
	_recipes = RecipesPanel.open_over(self, _recipes_btn)


## Shows the menu and focuses Resume.
func open() -> void:
	visible = true
	_build_stance_help()
	_resume.grab_focus.call_deferred()


## Hides the menu (and drops an open Recipes view).
func close() -> void:
	visible = false
	if _recipes != null and is_instance_valid(_recipes):
		_recipes.queue_free()
	_recipes = null


func _unhandled_input(event: InputEvent) -> void:
	var wants_toggle := event.is_action_pressed("pause") or (visible and event.is_action_pressed("ui_cancel"))
	if wants_toggle and game != null and game.can_toggle_pause():
		get_viewport().set_input_as_handled()
		game.toggle_pause()
