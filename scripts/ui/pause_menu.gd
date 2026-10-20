## PauseMenu — Esc / controller Start pause screen (GDD §4 "Esc:
## Pause/settings"). It also owns the "pause" input handling because it keeps
## processing while the tree is paused. While the menu is open, ui_cancel
## (Esc / controller B) also resumes.
##
## Layout (menu modernization wave 2, numbers in InRunUiData), two columns:
##   * left, a framed run summary (rebuilt on every open, read-only): the
##     stage and the time left (the Reckoning time once past 0:00), the
##     character and, when the run is not the standard one, the difficulty
##     and modifiers in crimson; the build as icon rows with level pips
##     (spells, passives) and the army as class icons with unit counts
##     (RunBuild), and the run's ultimate (icon and name; content wave 2); then the four army stances as compact tiles (stance icon,
##     name, a two-word tagline, the key / pad chip; the active one framed in
##     its colour, a locked one dimmed with a padlock; the full description
##     is the tile's tooltip);
##   * right, an ornate panel (bone filigree, skull keystone) with the
##     "Paused" title and the buttons Resume, Recipes, Settings, Feedback,
##     Restart, Main Menu. Recipes opens the RecipesPanel view of the discovered
##     evolution recipes (owner decision "Evolution recipe book", GDD §15.0).
##     Feedback (only while a form link is set, FeedbackReport.enabled()) opens
##     the feedback form in the browser with this run's facts (FeedbackButton;
##     GDD §15.0 "Feedback button (owner request, Oct 2026)"); the run stays
##     paused and the menu open.
## Under the two columns an InputHints strip shows the run controls
## (move, Grave Step, Dread Rally, Shadow Bolt aim, resume) as chips of the
## current device and bindings. Restart and Main Menu go through
## _on_restart() / _on_main_menu() so a confirm step can wrap them.
class_name PauseMenu
extends Control

## Resume button pressed (or Esc while open).
signal resume_pressed
## Restart button pressed.
signal restart_pressed
## Main Menu button pressed.
signal main_menu_pressed

## Owning run (asked whether pausing is allowed right now; read for the
## run summary).
var game: Game
## Resume button (focused on open for keyboard / controller users).
var _resume: Button
## Recipes button (regains focus when the Recipes view closes).
var _recipes_btn: Button
## Open Recipes view (null when closed; freed when the menu closes).
var _recipes: RecipesPanel = null
## The run summary column's content (rebuilt on open).
var _info_box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	add_child(UiTheme.backdrop(0.66))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit (no-op at 720 px).
	var outer := VBoxContainer.new()  # The two columns over the hint strip.
	outer.add_theme_constant_override("separation", 14)
	center.add_child(outer)
	var cols := HBoxContainer.new()  # Run summary | buttons.
	cols.add_theme_constant_override("separation", InRunUiData.PAUSE_GAP)
	outer.add_child(cols)
	var info := PanelContainer.new()  # Left: the run summary.
	info.add_theme_stylebox_override("panel", UiTheme.style("panel", "violet"))
	cols.add_child(info)
	var pad := MarginContainer.new()  # Inner padding of the summary.
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 8)
	info.add_child(pad)
	_info_box = VBoxContainer.new()
	_info_box.add_theme_constant_override("separation", 8)
	_info_box.custom_minimum_size = Vector2(InRunUiData.PAUSE_INFO_WIDTH, 0)
	pad.add_child(_info_box)
	var menu := UiTheme.ornate_panel("violet")  # Right: the buttons.
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cols.add_child(menu)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.custom_minimum_size = Vector2(InRunUiData.PAUSE_BUTTON_WIDTH, 0)
	menu.add_child(vb)
	vb.add_child(UiTheme.title("Paused"))
	vb.add_child(UiTheme.divider("violet"))
	_resume = _button(vb, "Resume", func() -> void: resume_pressed.emit())
	_recipes_btn = _button(vb, "Recipes", _open_recipes)
	_button(vb, "Settings", func() -> void: SettingsMenu.open_over(self, get_viewport().gui_get_focus_owner()))
	if FeedbackReport.enabled():
		var fb := FeedbackButton.make(func() -> Dictionary: return FeedbackReport.pause_context(game))  # Stays paused.
		fb.custom_minimum_size = Vector2(0, InRunUiData.PAUSE_BUTTON_HEIGHT)
		vb.add_child(fb)
	_button(vb, "Restart", _on_restart)
	_button(vb, "Main Menu", _on_main_menu)
	var ult_word := String(game.ultimates.row()["short"]) if game != null and game.ultimates != null else "Rally"  # The run's ultimate, one word.
	outer.add_child(InputHints.strip([[InputHints.MOVE, "Move"], ["dash", "Step"], ["ultimate", ult_word],
		["toggle_aim", "Bolt aim"], ["ui_cancel", "Resume"]]))


## Restart pressed: asks first through the shared ConfirmDialog.
func _on_restart() -> void:
	# asks first (the run in progress would be lost).
	ConfirmDialog.ask(self, ConfirmData.RESTART[0], ConfirmData.RESTART[1], ConfirmData.RESTART[2], func() -> void: restart_pressed.emit())


## Main Menu pressed: asks first through the shared ConfirmDialog.
func _on_main_menu() -> void:
	# asks first (the run in progress would be lost).
	ConfirmDialog.ask(self, ConfirmData.MAIN_MENU[0], ConfirmData.MAIN_MENU[1], ConfirmData.MAIN_MENU[2], func() -> void: main_menu_pressed.emit())


## Rebuilds the run summary from the run's current state (read-only).
func _rebuild_info() -> void:
	RunBuild.clear(_info_box)  # Detached at once (the panel never measures two copies).
	if game == null:
		return
	_info_box.add_child(_header_row())
	var sub := UiTheme.tier_label(game.character.display_name(), UiTheme.Tier.BODY, UiTheme.TEXT_DIM)  # Character line.
	_info_box.add_child(sub)
	var dif := game.difficulty  # The one difficulty path.
	if dif.is_active() or dif.has_run_setup():
		var mods := UiTheme.para(" · ".join(dif.hud_lines()), InRunUiData.PAUSE_INFO_WIDTH, Palette.CRIMSON.lightened(0.45))
		_info_box.add_child(mods)
	_info_box.add_child(UiTheme.divider("violet"))
	var grid := GridContainer.new()  # Caption | icon row.
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	_info_box.add_child(grid)
	_build_line(grid, "Spells", RunBuild.icon_row(RunBuild.spells(game), InRunUiData.PAUSE_ICON), RunBuild.spells(game).is_empty())
	_build_line(grid, "Passives", RunBuild.icon_row(RunBuild.passives(game), InRunUiData.PAUSE_ICON), RunBuild.passives(game).is_empty())
	var army := RunBuild.army(game)
	var army_row := RunBuild.army_row(army, InRunUiData.PAUSE_ICON)
	_build_line(grid, "Army", army_row, army.is_empty())
	_build_line(grid, "Ultimate", RunBuild.ultimate_row(game, InRunUiData.PAUSE_ICON), false)  # Content wave 2: the chosen ultimate.


## The summary's first row: the stage name and the countdown (or the
## Reckoning time past 0:00, in crimson).
func _header_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var stage := UiTheme.tier_label(String(game.stage_def["display_name"]), UiTheme.Tier.NAME, UiTheme.TEXT)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stage.clip_text = true
	row.add_child(stage)
	var clock := UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT_GOLD)
	if game.countdown_finished():
		clock.text = "Reckoning +" + RunBuild.clock(game.elapsed - WaveData.RUN_DURATION)
		clock.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.3))
	else:
		clock.text = RunBuild.clock(ceilf(game.time_remaining())) + " left"
	row.add_child(clock)
	return row


## One build line in `grid`: the LABEL caption `title` and `row` (or a dim
## "None" when `empty`).
func _build_line(grid: GridContainer, title: String, row: Control, empty: bool) -> void:
	var cap := RunBuild.caption(title)
	cap.custom_minimum_size = Vector2(96, 0)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_child(cap)
	if empty:
		row.queue_free()
		var none := UiTheme.tier_label("None", UiTheme.Tier.BODY, UiTheme.TEXT_DIM.darkened(0.2))
		none.custom_minimum_size = Vector2(0, InRunUiData.PAUSE_ICON)
		none.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		grid.add_child(none)
	else:
		grid.add_child(row)


## Adds a full-width button to `parent`.
func _button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, InRunUiData.PAUSE_BUTTON_HEIGHT)
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
	_rebuild_info()
	UiMotion.open(self)  # Fade / rise in (makes it visible).
	_resume.grab_focus.call_deferred()


## Hides the menu (and drops an open Recipes view).
func close() -> void:
	UiMotion.hide(self)  # Quick fade out, then hidden.
	if _recipes != null and is_instance_valid(_recipes):
		_recipes.queue_free()
	_recipes = null


func _unhandled_input(event: InputEvent) -> void:
	var wants_toggle := event.is_action_pressed("pause") or (visible and event.is_action_pressed("ui_cancel"))
	if wants_toggle and game != null and game.can_toggle_pause():
		get_viewport().set_input_as_handled()
		game.toggle_pause()
