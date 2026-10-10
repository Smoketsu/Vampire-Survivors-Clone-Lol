## ChestPanel — the treasure-chest reveal (user request, ChestData). Game
## opens it with the rewards already applied (AbilityManager.chest_rewards)
## while the tree is paused. A code-drawn chest opens over REVEAL_TIME s,
## then one row per reward appears (icon, name, "Lv 2 -> Lv 3" /
## "EVOLVED" / the fallback effect). Confirm (Enter / Space / click / pad A)
## first skips the animation, then closes the panel; Game resumes the run.
## The autotest closes it at once.
class_name ChestPanel
extends Control

## The panel was closed (Game resumes the run).
signal closed

## Owning run (autotest hook).
var game: Game
## Title label ("TREASURE CHEST").
var _title: Label
## Subtitle ("3 upgrades").
var _subtitle: Label
## Code-drawn chest that opens during the reveal.
var _reveal: ChestReveal
## Container of the reward rows.
var _rows_box: VBoxContainer
## One row Control per reward (revealed one by one).
var _rows: Array[Control] = []
## "Claim" button (closes the panel once everything is shown).
var _claim: Button
## Real seconds since the panel opened (reveal clock).
var _t: float = 0.0
## True while the panel is shown and waiting for confirm.
var _open: bool = false


## Draws the opening chest for the reveal (PowerupGlyphs.draw_chest).
class ChestReveal:
	extends Control
	## 0..1 lid opening.
	var open_frac: float = 0.0
	## Seconds of glow animation.
	var age: float = 0.0

	func _draw() -> void:
		PowerupGlyphs.draw_chest(self, size * 0.5 + Vector2(0, 14), 30.0, age, open_frac)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_child(UiTheme.backdrop(0.7))
	var center := CenterContainer.new()  # Centres the panel on screen.
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()  # Framed panel.
	panel.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.BG, Palette.GOLD, 3))
	center.add_child(panel)
	var vb := VBoxContainer.new()  # Panel contents, top to bottom.
	vb.add_theme_constant_override("separation", 8)
	vb.custom_minimum_size = Vector2(460, 0)
	panel.add_child(vb)
	_title = UiTheme.label("TREASURE CHEST", 28, UiTheme.TEXT_GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)
	_subtitle = UiTheme.label("", 14, UiTheme.TEXT_DIM)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_subtitle)
	_reveal = ChestReveal.new()
	_reveal.custom_minimum_size = Vector2(460, 110)
	_reveal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_reveal)
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 4)
	vb.add_child(_rows_box)
	_claim = Button.new()
	_claim.text = "Claim   [Enter / A]"
	_claim.custom_minimum_size = Vector2(220, 42)
	_claim.focus_mode = Control.FOCUS_ALL
	_claim.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_claim.pressed.connect(_confirm)
	vb.add_child(_claim)


## Shows `rewards` (AbilityManager offer Dictionaries, already applied) for a
## chest of `count` upgrades.
func open(rewards: Array[Dictionary], count: int) -> void:
	for r in _rows:
		r.queue_free()
	_rows.clear()
	_subtitle.text = "%d upgrade%s" % [count, "" if count == 1 else "s"]
	for r in rewards:
		var row := _make_row(r)  # One reward line.
		row.modulate.a = 0.0
		_rows_box.add_child(row)
		_rows.append(row)
	_t = 0.0
	_reveal.open_frac = 0.0
	_open = true
	visible = true
	Sfx.play("chest_open")
	_claim.grab_focus.call_deferred()
	if game != null and game.autotest != null:
		_finish.call_deferred()


## One reward row: icon, name and the level change / effect.
func _make_row(r: Dictionary) -> Control:
	var row := HBoxContainer.new()  # Icon + texts.
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(IconGlyph.new(String(r["icon"]), Vector2(40, 40)))
	var texts := VBoxContainer.new()  # Name over the change line.
	texts.add_theme_constant_override("separation", 0)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)
	var kind := String(r["kind"])  # Offer kind (spell / summon / passive / evolution / fallback).
	texts.add_child(UiTheme.label(String(r["name"]), 17, UiTheme.TEXT_GOLD if kind == "evolution" else UiTheme.TEXT))
	var change := ""  # "Lv 2 -> Lv 3", "EVOLVED" or the fallback effect.
	match kind:
		"evolution":
			change = "Lv %d  ->  EVOLVED" % int(r["from"])
		"fallback":
			var deltas: PackedStringArray = r["deltas"]  # Fallback effect lines.
			change = deltas[0] if not deltas.is_empty() else ""
		_:
			change = "NEW!  Lv 1" if int(r["from"]) == 0 else "Lv %d  ->  Lv %d" % [int(r["from"]), int(r["to"])]
	texts.add_child(UiTheme.label(change, 14, UiTheme.TEXT_GOOD))
	return row


func _process(delta: float) -> void:
	if not _open:
		return
	_t += delta
	_reveal.age += delta
	_reveal.open_frac = clampf(_t / ChestData.REVEAL_TIME, 0.0, 1.0)
	_reveal.queue_redraw()
	for i in _rows.size():
		var shown_at := ChestData.REVEAL_TIME + float(i) * ChestData.ROW_INTERVAL  # When row i appears.
		_rows[i].modulate.a = clampf((_t - shown_at) / 0.15, 0.0, 1.0)


## Total reveal length for the current rewards (s).
func _reveal_length() -> float:
	return ChestData.REVEAL_TIME + float(_rows.size()) * ChestData.ROW_INTERVAL


## Confirm: skips the reveal if it is still running, otherwise closes.
func _confirm() -> void:
	if not _open:
		return
	if _t < _reveal_length():
		_t = _reveal_length() + 1.0
		return
	_finish()


## Closes the panel and tells Game to resume.
func _finish() -> void:
	if not _open:
		return
	_open = false
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_confirm()
