## CoopScreen — the Co-op screen opened by the title screen's Co-op button
## (GDD §15.0 "Online co-op: relay and lobby"; docs/coop/DESIGN.md: online
## only, two players). An ornate panel over the menu diorama with the title,
## one line, and either:
##   * the choice: Host (CoopNet.host(): the relay makes a lobby) and Join
##     (shows the letter pad), or
##   * the Join page (CoopJoinPad: five letter slots, the on-screen pad,
##     Delete / Paste / Join; a `?join=CODE` link opens it filled in),
## then one status line ("Connecting to the relay...", or the error in plain
## words: bad code, lobby full, other version, relay unreachable, host left)
## and Back. Once CoopNet is seated the lobby (CoopLobby) opens over this
## screen, whose content hides meanwhile; when the lobby closes its reason
## shows here. The run's start (`run_started`) is passed on to the title
## screen (MainMenu.coop_start -> Main.start_coop_run()). A stale session (a
## run that ended) is left when the screen opens. Esc / pad B: back from the
## pad to the choice, cancel a connection, else close. Keyboard, controller
## and touch navigable.
class_name CoopScreen
extends Control

## The host started the run (CoopNet.start_info), on both machines.
signal run_started(info: Dictionary)
## The screen closed.
signal closed

## Control that gets focus back when the screen closes.
var return_focus: Control = null
## Code to open the Join pad with ("" = open on the choice).
var join_code: String = ""
## The panel holder (hidden while the lobby is open).
var _content: Control
## The bottom hint strip (hidden while the lobby is open).
var _hints: Control
## The Host / Join row.
var _choice: HBoxContainer
## Host button.
var _host_b: Button
## Join button (opens the pad).
var _join_b: Button
## The Join page.
var _pad: CoopJoinPad
## Status line.
var _status: Label
## Back button.
var _back: Button
## The open lobby (null when none).
var _lobby: CoopLobby = null
## True while connecting (Host or Join pressed, no welcome yet).
var _connecting: bool = false


## Opens the screen over `parent` (focus returns to `refocus`); `code` opens the Join pad filled in.
static func open_over(parent: Control, refocus: Control, code: String = "") -> CoopScreen:
	var s := CoopScreen.new()
	s.return_focus = refocus
	s.join_code = code
	parent.add_child(s)
	return s


func _ready() -> void:
	if CoopNet.active():
		CoopNet.leave()  # A session left over from a finished run.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiTheme.get_theme()
	add_child(UiTheme.backdrop(CoopNetData.SCREEN_SCRIM))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit (no-op at 720 px).
	_content = center
	var panel := UiTheme.ornate_panel("violet")
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size.x = CoopNetData.PANEL_WIDTH
	panel.add_child(vb)
	vb.add_child(UiTheme.title("Co-op"))
	var line := UiTheme.para(CoopNetData.SCREEN_LINE, CoopNetData.PANEL_WIDTH, UiTheme.TEXT)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(line)
	vb.add_child(UiTheme.divider())
	_choice = HBoxContainer.new()
	_choice.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice.add_theme_constant_override("separation", 16)
	vb.add_child(_choice)
	_host_b = _button(_choice, "Host", _on_host, CoopNetData.ACTION_SIZE)
	_join_b = _button(_choice, "Join", _show_pad.bind(""), CoopNetData.ACTION_SIZE)
	_pad = CoopJoinPad.new()
	_pad.visible = false
	_pad.submitted.connect(_on_join)
	vb.add_child(_pad)
	_status = UiTheme.para("", CoopNetData.PANEL_WIDTH, UiTheme.TEXT_DIM)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_status)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	_back = _button(row, "Back", _on_back, CoopNetData.BUTTON_SIZE)
	_hints = InputHints.bottom_strip([[InputHints.MOVE, "Move"], ["ui_accept", "Select"], ["ui_cancel", "Back"]])
	add_child(_hints)
	CoopNet.state_changed.connect(_on_state)
	CoopNet.error_raised.connect(_on_error)
	_wire_choice()
	if join_code != "":
		_show_pad(join_code)
	else:
		_host_b.grab_focus.call_deferred()
	UiMotion.open(self)


## A button with `text` calling `cb`, added to `parent`.
static func _button(parent: Control, text: String, cb: Callable, size_px: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size_px
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## Focus on the choice page: Host / Join side by side, Back under them.
func _wire_choice() -> void:
	for b: Button in [_host_b, _join_b]:
		b.focus_neighbor_bottom = b.get_path_to(_back)
		b.focus_neighbor_top = b.get_path_to(b)
	_host_b.focus_neighbor_left = _host_b.get_path_to(_host_b)
	_host_b.focus_neighbor_right = _host_b.get_path_to(_join_b)
	_join_b.focus_neighbor_left = _join_b.get_path_to(_host_b)
	_join_b.focus_neighbor_right = _join_b.get_path_to(_join_b)
	_back.focus_neighbor_left = _back.get_path_to(_back)
	_back.focus_neighbor_right = _back.get_path_to(_back)
	_back.focus_neighbor_bottom = _back.get_path_to(_back)
	_back.focus_neighbor_top = _back.get_path_to(_host_b)


## Our loadout for a new session: the remembered pre-run choices.
static func _loadout() -> Dictionary:
	return CoopNet.make_loadout(CoopLobby._initial_config(), "")


## Sets the status line (`error` in crimson).
func _say(text: String, error: bool = false) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.4) if error else UiTheme.TEXT_DIM)


## Host: connect and open a lobby.
func _on_host() -> void:
	if _connecting:
		return
	Sfx.play("ui_confirm")
	_connecting = true
	_say(CoopNetData.CONNECTING_TEXT)
	CoopNet.host(_loadout())


## Shows the Join page (filled with `code`).
func _show_pad(code: String) -> void:
	if _connecting:
		return
	_choice.visible = false
	_pad.visible = true
	_pad.set_code(code)
	_say("")
	_pad.link_below(_back)
	_back.focus_neighbor_top = _back.get_path_to(_pad.join_button())
	UiTheme.focus_deferred(_pad.first_focus() if _pad.code.length() < CoopNetData.CODE_LENGTH else _pad.join_button())


## Back to the choice page.
func _show_choice() -> void:
	_pad.visible = false
	_choice.visible = true
	_wire_choice()
	UiTheme.focus_deferred(_host_b)


## Join pressed on the pad with a complete code.
func _on_join(code: String) -> void:
	if _connecting:
		return
	_connecting = true
	_say(CoopNetData.CONNECTING_TEXT)
	CoopNet.join(code, _loadout())


## Back: cancels a connection, leaves the pad, else closes the screen.
func _on_back() -> void:
	if _connecting:
		CoopNet.leave()
		_connecting = false
		_say("")
		Sfx.play_ui("ui_back")
		return
	if _pad.visible and join_code == "":
		Sfx.play_ui("ui_back")
		_show_choice()
		return
	close()


## CoopNet's state: seated -> the lobby opens.
func _on_state(s: int) -> void:
	if s == CoopNet.State.LOBBY and _lobby == null and _connecting:
		_connecting = false
		_say("")
		_open_lobby()
	elif s == CoopNet.State.CLOSED or s == CoopNet.State.OFFLINE:
		_connecting = false


## An error before the lobby opened: shown plainly.
func _on_error(_code: String, text: String) -> void:
	_connecting = false
	if _lobby == null:
		_say(text, true)
		Sfx.play_ui("denied")


## Opens the lobby over this screen (its content hides meanwhile).
func _open_lobby() -> void:
	_lobby = CoopLobby.new()
	_lobby.left_lobby.connect(_on_lobby_left)
	_lobby.run_started.connect(func(info: Dictionary) -> void: run_started.emit(info))
	_content.visible = false
	_hints.visible = false
	add_child(_lobby)


## The lobby closed: this screen returns with the reason.
func _on_lobby_left(reason: String) -> void:
	_lobby = null
	_content.visible = true
	_hints.visible = true
	join_code = ""
	_show_choice()
	_say(reason, reason != "")


## Closes the screen (leaving any connection).
func close() -> void:
	if UiMotion.is_closing(self):
		return
	if CoopNet.active():
		CoopNet.leave()
	closed.emit()
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	UiMotion.close(self, queue_free)


## Esc / pad B: Back (the lobby takes it first while open).
func _input(event: InputEvent) -> void:
	if _lobby != null or UiMotion.is_closing(self):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()
