## CoopLobby — the co-op lobby (GDD §15.0 "Online co-op: relay and lobby";
## docs/coop/DESIGN.md "Who picks what"), opened by CoopScreen once CoopNet is
## seated. Top to bottom, inside 1280 x 600 layout px:
##   * the title and the lobby code as five big gold letter slots, with Copy
##     (to the clipboard) and, in a browser that has a share sheet, Share (the
##     code and a link that opens the Join pad filled in: `?join=CODE`);
##   * the two seats as CoopPlayerCards (host left, guest right): portrait,
##     name, character, ultimate, title, ready state, round trip;
##   * the run the host chose: stage, difficulty, modifiers, Hyper, Oath;
##   * one status line (what is awaited, or an error in crimson);
##   * the buttons. Host: Leave, Stage (the stage select, then the pre-run
##     setup), Setup (the pre-run setup for the chosen stage: difficulty,
##     modifiers, Hyper and the host's own character, skin, ultimate, title),
##     Start (gold; only once the guest is ready). Guest: Leave, Setup (the
##     pre-run setup with the host's run part read-only: PreRunSetup.coop_guest),
##     Ready (gold while ready; Setup un-readies first).
## The pre-run screens are the solo ones, opened over the lobby with a "Done"
## caption; their RunConfig comes back here and goes out through CoopNet
## (set_settings(), set_loadout()), so each player picks from their own
## unlocks. Leave asks first (ConfirmDialog); Esc / pad B is Leave. When the
## connection closes (host left, relay lost...) the lobby closes with the
## reason (`left_lobby`); when the run starts both machines emit `run_started`.
## Keyboard, controller and touch navigable (explicit focus rows).
class_name CoopLobby
extends Control

## The lobby closed: `reason` is the line to show on the Co-op screen ("" = left on purpose).
signal left_lobby(reason: String)
## The host started the run (CoopNet.start_info), on both machines.
signal run_started(info: Dictionary)

## Caption of the pre-run setup's Begin button when opened from the lobby.
const DONE_TEXT: String = "Done"

## Our pre-run choices (host: the whole RunConfig; guest: the loadout part, the run part mirrors the host's).
var _config: RunConfig = null
## The content holder (faded while a pre-run screen is open over the lobby).
var _content: Control
## The bottom hint strip.
var _hints: Control
## Code letter labels.
var _code_labels: Array[Label] = []
## Copy button.
var _copy: Button
## Share button (null where the browser has no share sheet, and on desktop).
var _share: Button = null
## The two seat cards (host, guest).
var _cards: Array[CoopPlayerCard] = []
## Stage name line of the run panel.
var _run_name: Label
## Difficulty / modifiers / Hyper / Oath line of the run panel.
var _run_line: Label
## Status line.
var _status: Label
## Error line shown in the status until the lobby changes ("" = none).
var _error: String = ""
## Bottom row buttons (null where the seat has none).
var _leave: Button
var _stage: Button = null
var _setup: Button
var _ready_b: Button = null
var _start: Button = null
## The guest's open pre-run setup (kept in step with the host; null when closed).
var _guest_setup: PreRunSetup = null
## True once the lobby is closing.
var _closing: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiTheme.get_theme()
	_config = _initial_config()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit (no-op at 720 px).
	_content = center
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size.x = CoopNetData.LOBBY_WIDTH
	center.add_child(vb)
	vb.add_child(UiTheme.title("Lobby"))
	vb.add_child(_code_row())
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", CoopNetData.CARD_GAP)
	vb.add_child(cards)
	for i in 2:
		var c := CoopPlayerCard.new()
		cards.add_child(c)
		_cards.append(c)
	vb.add_child(_run_panel())
	_status = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_status)
	vb.add_child(_button_row())
	_wire_focus()
	_hints = InputHints.bottom_strip([[InputHints.MOVE, "Move"], ["ui_accept", "Select"], ["ui_cancel", "Leave"]])
	add_child(_hints)
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)
	CoopNet.lobby_changed.connect(_refresh)
	CoopNet.state_changed.connect(_on_state)
	CoopNet.error_raised.connect(_on_error)
	CoopNet.run_started.connect(_on_run)
	CoopNet.partner_left.connect(_on_partner_left)
	CoopNet.partner_joined.connect(func() -> void: _error = "")  # A new partner clears "Your partner left."
	if CoopNet.is_host():
		CoopNet.set_settings(CoopNet.config_dict(_config))
	CoopNet.set_loadout(CoopNet.make_loadout(_config, _my_name()))
	_refresh()
	(_start if _start != null else _ready_b).grab_focus.call_deferred()
	UiMotion.open(self)


## Our starting choices: the remembered pre-run config of the last stage
## played (a stage the host cannot play falls back to the first stage).
static func _initial_config() -> RunConfig:
	var stage := GameState.last_stage_id
	if not StageRegistry.STAGES.has(stage) or not StageRegistry.is_playable(stage) or not Meta.is_stage_unlocked(stage):
		stage = StageRegistry.DEFAULT_ID
	return Meta.prerun_config(stage)


## Our name as the lobby knows it (CoopNet's cleaned loadout name).
func _my_name() -> String:
	if CoopNet.local_slot < 0:
		return ""
	return String((CoopNet.loadouts[CoopNet.local_slot] as Dictionary).get("name", ""))


## The code row: "Code", five gold letter slots, Copy and (browser) Share.
func _code_row() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", CoopNetData.CODE_SLOT_GAP)
	var lab := UiTheme.tier_label("Code", UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	lab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lab)
	for i in CoopNetData.CODE_LENGTH:
		var p := PanelContainer.new()
		p.custom_minimum_size = CoopNetData.CODE_SLOT
		p.add_theme_stylebox_override("panel", UiTheme.style("panel", "gold"))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := UiTheme.tier_label("", UiTheme.Tier.HERO, UiTheme.TEXT_GOLD)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(l)
		row.add_child(p)
		_code_labels.append(l)
	var gap := Control.new()
	gap.custom_minimum_size.x = 8.0
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gap)
	_copy = _button(row, "Copy", _on_copy)
	_copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if _can_share():
		_share = _button(row, "Share", _on_share)
		_share.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return row


## The run panel: the stage name and the run line.
func _run_panel() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.style("panel", "violet"))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(box)
	_run_name = UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT_GOLD)
	_run_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_run_name)
	_run_line = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT)
	_run_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_run_line.clip_text = true
	_run_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(_run_line)
	return p


## The bottom row for our seat (see the header).
func _button_row() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	_leave = _button(row, "Leave", _on_leave)
	if CoopNet.is_host():
		_stage = _button(row, "Stage", _on_stage)
		_setup = _button(row, "Setup", _on_setup)
		_start = _button(row, "Start", _on_start, CoopNetData.ACTION_SIZE)
		UiTheme.style_button(_start, "button", "gold")
	else:
		_setup = _button(row, "Setup", _on_setup)
		_ready_b = _button(row, "Ready", _on_ready, CoopNetData.ACTION_SIZE)
	return row


## A button with `text` calling `cb`, added to `parent`.
static func _button(parent: Control, text: String, cb: Callable, size_px: Vector2 = CoopNetData.BUTTON_SIZE) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size_px
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## Explicit focus: the code row's buttons over the bottom row; nothing leaves the screen.
func _wire_focus() -> void:
	var top: Array[Button] = [_copy]
	if _share != null:
		top.append(_share)
	var bottom: Array[Button] = [_leave]
	for b: Button in [_stage, _setup, _ready_b, _start]:
		if b != null:
			bottom.append(b)
	for rows: Array in [[top, bottom], [bottom, top]]:
		var row: Array[Button] = rows[0]
		var other: Array[Button] = rows[1]
		for j in row.size():
			var b := row[j]
			var k := clampi(roundi(float(j) * float(other.size() - 1) / float(maxi(1, row.size() - 1))), 0, other.size() - 1)
			b.focus_neighbor_left = b.get_path_to(row[j - 1] if j > 0 else b)
			b.focus_neighbor_right = b.get_path_to(row[j + 1] if j < row.size() - 1 else b)
			b.focus_neighbor_top = b.get_path_to(other[k] if row == bottom else b)
			b.focus_neighbor_bottom = b.get_path_to(other[k] if row == top else b)


## Redraws the code, the seats, the run panel, the status and the buttons.
func _refresh() -> void:
	if _closing:
		return
	var c := CoopNet.code
	for i in _code_labels.size():
		_code_labels[i].text = c[i] if i < c.length() else ""
	for slot in 2:
		var peer: Dictionary = CoopNet.peers[slot]
		if peer.is_empty():
			_cards[slot].set_empty(slot)
			continue
		var lo: Dictionary = (CoopNet.loadouts[slot] as Dictionary).duplicate()
		if not lo.has("name"):
			lo["name"] = String(peer.get("name", ""))
			if String(lo["name"]) == "":
				lo["name"] = String(CoopNetData.DEFAULT_NAMES[slot])
		var me := slot == CoopNet.local_slot
		_cards[slot].set_player(slot, lo, me, bool(CoopNet.ready_flags[slot]), CoopNet.partner_rtt_ms if me else CoopNet.rtt_ms)
	_refresh_run()
	_refresh_status()
	if _start != null:
		_start.modulate.a = 1.0 if CoopNet.can_start() else 0.55
	if _ready_b != null:
		UiTheme.style_button(_ready_b, "button", "gold" if bool(CoopNet.ready_flags[1]) else "")
	if _guest_setup != null and is_instance_valid(_guest_setup) and not CoopNet.settings.is_empty():
		_guest_setup.apply_host_run(CoopNet.settings)


## The run panel from the host's settings (ours while the host has sent none).
func _refresh_run() -> void:
	var cfg: Dictionary = CoopNet.settings if not CoopNet.settings.is_empty() else CoopNet.config_dict(_config)
	var stage := String(cfg.get("stage_id", StageRegistry.DEFAULT_ID))
	var def: Dictionary = StageRegistry.STAGES.get(stage, StageRegistry.STAGES[StageRegistry.DEFAULT_ID])
	_run_name.text = "%s  ·  %s" % [String(def["chapter"]), String(def["display_name"])]
	var parts := PackedStringArray()
	var lv: Dictionary = DifficultyData.LEVELS.get(String(cfg.get("difficulty_id", "")), DifficultyData.LEVELS[DifficultyData.DEFAULT_ID])
	parts.append(String(lv["display_name"]))
	var mods: Array = cfg.get("modifiers", [])
	if mods.is_empty():
		parts.append("No modifiers")
	else:
		var names := PackedStringArray()
		for id: Variant in mods:
			if RunModifierData.MODIFIERS.has(String(id)):
				names.append(String(RunModifierData.MODIFIERS[String(id)]["display_name"]))
		parts.append(", ".join(names))
	if bool(cfg.get("hyper", false)):
		parts.append(HyperData.DISPLAY_NAME)
	var oath := int(cfg.get("oath", 0))
	if oath > 0:
		parts.append("Oath %s" % DifficultyModifiers.roman(oath))
	_run_line.text = "  ·  ".join(parts)
	_run_line.tooltip_text = _run_line.text


## The status line: an error in crimson, else what the lobby waits for.
func _refresh_status() -> void:
	if _error != "":
		_status.text = _error
		_status.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.4))
		return
	var text := ""
	if CoopNet.is_host():
		if not CoopNet.has_partner():
			text = CoopNetData.WAITING_TEXT
		elif bool(CoopNet.ready_flags[1]):
			text = CoopNetData.HOST_READY_TEXT
		else:
			text = CoopNetData.HOST_WAIT_READY_TEXT
	else:
		text = CoopNetData.GUEST_READY_TEXT if bool(CoopNet.ready_flags[1]) else CoopNetData.GUEST_WAIT_TEXT
	_status.text = text
	_status.add_theme_color_override("font_color", UiTheme.TEXT_GOOD if CoopNet.can_start() else UiTheme.TEXT_DIM)


## True in a browser that has a share sheet (phones, some desktops).
static func _can_share() -> bool:
	if not OS.has_feature("web"):
		return false
	return str(JavaScriptBridge.eval("typeof navigator.share === 'function' ? 'yes' : 'no'", true)) == "yes"


## Copy: the code to the clipboard ("Copied" on the button for a moment).
func _on_copy() -> void:
	if CoopNet.code == "":
		Sfx.play_ui("denied")
		return
	DisplayServer.clipboard_set(CoopNet.code)
	Sfx.play("ui_confirm")
	_copy.text = "Copied"
	get_tree().create_timer(CoopNetData.COPIED_TIME, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(_copy):
			_copy.text = "Copy")


## Share (browser): the share sheet with the code and a link that opens the Join pad filled in.
func _on_share() -> void:
	var c := CoopNet.code
	if c == "":
		Sfx.play_ui("denied")
		return
	Sfx.play("ui_confirm")
	var js := "(function(){var u=location.origin+location.pathname+'?%s=%s';navigator.share({title:'Necropathy',text:%s,url:u}).catch(function(){});})()" % [
		CoopNetData.JOIN_QUERY_KEY, c, JSON.stringify(CoopNetData.SHARE_TEXT % c)]
	JavaScriptBridge.eval(js, true)


## Host: Stage opens the stage select (then the pre-run setup); its choice becomes the run.
func _on_stage() -> void:
	Sfx.play("ui_confirm")
	var sel := StageSelect.open_over(self, _stage)
	sel.setup_begin_text = DONE_TEXT
	sel.stage_chosen.connect(func(c: RunConfig) -> void:
		_apply_host(c)
		sel.close())


## Setup: the pre-run setup for the current stage (guest: the run part read-only, un-readied first).
func _on_setup() -> void:
	Sfx.play("ui_confirm")
	if CoopNet.is_host():
		var s := PreRunSetup.open_over(self, _setup, _config.duplicate_config(), DONE_TEXT)
		s.confirmed.connect(func(c: RunConfig) -> void:
			_apply_host(c)
			s.close())
		return
	if bool(CoopNet.ready_flags[1]):
		CoopNet.set_ready(false)
	var cfg := _config.duplicate_config()
	if not CoopNet.settings.is_empty():
		var host_cfg := CoopNet.run_config_for({"config": CoopNet.settings, "loadouts": [{}, {}]}, 0)
		cfg.stage_id = host_cfg.stage_id
		cfg.set_difficulty(host_cfg.difficulty_id)
		cfg.set_modifiers(host_cfg.modifiers)
		cfg.hyper = host_cfg.hyper
	_guest_setup = PreRunSetup.open_over(self, _setup, cfg, DONE_TEXT, true)
	var s := _guest_setup
	s.confirmed.connect(func(c: RunConfig) -> void:
		_config = c.duplicate_config()
		CoopNet.set_loadout(CoopNet.make_loadout(_config, _my_name()))
		s.close())


## The host confirmed `c` (stage select or setup): it becomes the run and the host's loadout.
func _apply_host(c: RunConfig) -> void:
	_config = c.duplicate_config()
	_error = ""
	CoopNet.set_settings(CoopNet.config_dict(_config))
	CoopNet.set_loadout(CoopNet.make_loadout(_config, _my_name()))


## Guest: Ready toggles our ready flag.
func _on_ready() -> void:
	Sfx.play("ui_confirm")
	_error = ""
	CoopNet.set_ready(not bool(CoopNet.ready_flags[1]))


## Host: Start (once the guest is ready).
func _on_start() -> void:
	if not CoopNet.start_run():
		Sfx.play_ui("denied")
		return
	Sfx.play("ui_confirm")


## Leave (and Esc / pad B): asks first.
func _on_leave() -> void:
	ConfirmDialog.ask(self, String(CoopNetData.LEAVE_CONFIRM[0]), String(CoopNetData.LEAVE_CONFIRM[1]),
		String(CoopNetData.LEAVE_CONFIRM[2]), _leave_now, true)


## Leaves the lobby on purpose.
func _leave_now() -> void:
	CoopNet.leave()
	_close("")


## The connection closed: the lobby closes with the reason.
func _on_state(s: int) -> void:
	if s == CoopNet.State.CLOSED:
		_close(_error if _error != "" else CoopNet.error_text(CoopNet.last_error if CoopNet.last_error != "" else "lost"))


## An error: shown on the status line (and carried back if the lobby closes).
func _on_error(_code: String, text: String) -> void:
	_error = text
	_refresh_status()


## The partner left: their seat empties (the host stays in the lobby; a
## guest's lobby closes right after with host_left).
func _on_partner_left() -> void:
	_error = CoopNet.error_text("partner_left")
	_refresh()


## The run started (both machines).
func _on_run(info: Dictionary) -> void:
	if _closing:
		return
	_closing = true
	run_started.emit(info)


## Closes the lobby (fade out), telling the Co-op screen why.
func _close(reason: String) -> void:
	if _closing:
		return
	_closing = true
	left_lobby.emit(reason)
	UiMotion.close(self, queue_free)


## A pre-run screen opened over the lobby: fade the lobby out under it.
func _on_child_entered(node: Node) -> void:
	if node is StageSelect or node is PreRunSetup:
		_content.modulate.a = 0.0
		_hints.visible = false


## A pre-run screen is leaving: bring the lobby back.
func _on_child_exiting(node: Node) -> void:
	if node is StageSelect or node is PreRunSetup:
		_content.modulate.a = 1.0
		_hints.visible = true
		if node == _guest_setup:
			_guest_setup = null
		_refresh()


## Esc / pad B: Leave (the screens and dialog over the lobby take it first).
func _input(event: InputEvent) -> void:
	if _closing or UiMotion.is_closing(self):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_leave()
