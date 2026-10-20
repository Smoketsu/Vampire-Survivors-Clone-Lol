## CoopJoinPad — the Join page of the Co-op screen (CoopScreen; GDD §15.0
## "Online co-op: relay and lobby"): the lobby code as five big letter slots
## (HERO tier; filled ones gold, the next one to fill in the violet frame),
## an on-screen letter pad of the 20 code letters (CoopNetData.CODE_ALPHABET,
## CoopNetData.PAD_COLUMNS per row: a phone never needs its virtual keyboard)
## and one action row: Delete, Paste (desktop: the clipboard's first code) and
## the gold Join. Keyboard users can also type the letters (a letter outside
## the alphabet is ignored), Backspace deletes and Enter joins once the code
## is complete; a controller moves over the pad with the D-pad. Join with a
## short code plays `denied`. Emits `submitted` with the code.
class_name CoopJoinPad
extends VBoxContainer

## Join pressed with a complete code.
signal submitted(code: String)

## The code typed so far (upper case, at most CoopNetData.CODE_LENGTH letters).
var code: String = ""
## The letter slot panels, left to right.
var _slot_panels: Array[PanelContainer] = []
## The letter slot labels, left to right.
var _slot_labels: Array[Label] = []
## Letter -> its pad key.
var _keys: Dictionary = {}
## The action row's buttons.
var _delete: Button
var _paste: Button = null
var _join: Button


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", CoopNetData.CODE_SLOT_GAP)
	add_child(slots)
	for i in CoopNetData.CODE_LENGTH:
		var p := PanelContainer.new()
		p.custom_minimum_size = CoopNetData.CODE_SLOT
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := UiTheme.tier_label("", UiTheme.Tier.HERO, UiTheme.TEXT_GOLD)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(l)
		slots.add_child(p)
		_slot_panels.append(p)
		_slot_labels.append(l)
	var grid := GridContainer.new()
	grid.columns = CoopNetData.PAD_COLUMNS
	grid.add_theme_constant_override("h_separation", CoopNetData.PAD_GAP)
	grid.add_theme_constant_override("v_separation", CoopNetData.PAD_GAP)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(grid)
	for ch in CoopNetData.CODE_ALPHABET:
		var b := Button.new()
		b.text = ch
		b.custom_minimum_size = CoopNetData.PAD_KEY
		b.focus_mode = Control.FOCUS_ALL
		UiTheme.set_tier(b, UiTheme.Tier.NAME)
		b.set_meta(UiMotion.META_LIFT, false)
		b.pressed.connect(_add.bind(ch))
		grid.add_child(b)
		_keys[ch] = b
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", CoopNetData.PAD_GAP)
	add_child(row)
	_delete = _button(row, "Delete", _remove, CoopNetData.BUTTON_SIZE)
	if not OS.has_feature("web") and not TouchSupport.is_mobile():  # A browser cannot read the clipboard on demand.
		_paste = _button(row, "Paste", _paste_code, CoopNetData.BUTTON_SIZE)
	_join = _button(row, "Join", _submit, CoopNetData.ACTION_SIZE)
	UiTheme.style_button(_join, "button", "gold")
	_wire_focus()
	_refresh()


## A button with `text` calling `cb`, added to `parent`.
static func _button(parent: Control, text: String, cb: Callable, size_px: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size_px
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## Explicit focus: the pad as a grid, the action row under it, nothing leaves.
func _wire_focus() -> void:
	var letters := CoopNetData.CODE_ALPHABET
	var cols := CoopNetData.PAD_COLUMNS
	var rows := ceili(float(letters.length()) / float(cols))
	var actions: Array[Button] = [_delete]
	if _paste != null:
		actions.append(_paste)
	actions.append(_join)
	for i in letters.length():
		var b: Button = _keys[letters[i]]
		var r := i / cols
		var c := i % cols
		_link(b, "left", _keys[letters[i - 1]] if c > 0 else b)
		_link(b, "right", _keys[letters[i + 1]] if c < cols - 1 and i + 1 < letters.length() else b)
		_link(b, "top", _keys[letters[i - cols]] if r > 0 else b)
		if r < rows - 1 and i + cols < letters.length():
			_link(b, "bottom", _keys[letters[i + cols]])
		else:
			_link(b, "bottom", actions[clampi(roundi(float(c) * float(actions.size() - 1) / float(cols - 1)), 0, actions.size() - 1)])
	var last_row := (rows - 1) * cols  # Index of the bottom row's first key.
	for j in actions.size():
		var b := actions[j]
		_link(b, "left", actions[j - 1] if j > 0 else b)
		_link(b, "right", actions[j + 1] if j < actions.size() - 1 else b)
		_link(b, "bottom", b)
		var c := clampi(roundi(float(j) * float(cols - 1) / float(maxi(1, actions.size() - 1))), 0, cols - 1)
		_link(b, "top", _keys[letters[mini(last_row + c, letters.length() - 1)]])


## Sets focus neighbour `side` of `b` to `to`.
static func _link(b: Control, side: String, to: Control) -> void:
	b.set("focus_neighbor_" + side, b.get_path_to(to))


## The first focus target (the first pad key).
func first_focus() -> Control:
	return _keys[CoopNetData.CODE_ALPHABET[0]]


## The Join button (the screen's Back links up to it).
func join_button() -> Button:
	return _join


## Points the action row's "down" at `c` (the screen's Back under the pad).
func link_below(c: Control) -> void:
	for b: Button in [_delete, _paste, _join]:
		if b != null:
			_link(b, "bottom", c)


## Replaces the code (filtered to the alphabet, cut to the code length).
func set_code(c: String) -> void:
	code = ""
	for ch in CoopNet.normalize_code(c):
		if CoopNetData.CODE_ALPHABET.contains(ch) and code.length() < CoopNetData.CODE_LENGTH:
			code += ch
	_refresh()


## Adds letter `ch` (a full code plays `denied`).
func _add(ch: String) -> void:
	if code.length() >= CoopNetData.CODE_LENGTH:
		Sfx.play_ui("denied")
		return
	code += ch
	Sfx.play_ui("ui_tick")
	_refresh()
	if code.length() == CoopNetData.CODE_LENGTH:
		_join.grab_focus()  # Complete: one more press joins.


## Removes the last letter.
func _remove() -> void:
	if code.is_empty():
		Sfx.play_ui("denied")
		return
	code = code.left(code.length() - 1)
	Sfx.play_ui("ui_back")
	_refresh()


## Paste (desktop): the clipboard's letters as the code.
func _paste_code() -> void:
	set_code(DisplayServer.clipboard_get())
	Sfx.play_ui("ui_tick" if code.length() == CoopNetData.CODE_LENGTH else "denied")


## Join: submits a complete code (`denied` otherwise).
func _submit() -> void:
	if code.length() != CoopNetData.CODE_LENGTH:
		Sfx.play_ui("denied")
		return
	Sfx.play("ui_confirm")
	submitted.emit(code)


## Redraws the slots (filled gold, the next one framed) and the Join look.
func _refresh() -> void:
	for i in _slot_labels.size():
		_slot_labels[i].text = code[i] if i < code.length() else ""
		var accent := "gold" if i < code.length() else "violet"
		_slot_panels[i].add_theme_stylebox_override("panel", UiTheme.style("panel", accent))
		_slot_panels[i].modulate.a = 1.0 if i <= code.length() else 0.55
	_join.modulate.a = 1.0 if code.length() == CoopNetData.CODE_LENGTH else 0.6


## Typed letters, Backspace and Enter (keyboards); handled so they never move the focus.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or (k.echo and k.keycode != KEY_BACKSPACE):  # Held Backspace repeats; nothing else does.
		return
	if k.ctrl_pressed and k.keycode == KEY_V and _paste != null:
		get_viewport().set_input_as_handled()
		_paste_code()
		return
	if k.keycode == KEY_BACKSPACE:
		get_viewport().set_input_as_handled()
		_remove()
		return
	if (k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER) and code.length() == CoopNetData.CODE_LENGTH:
		get_viewport().set_input_as_handled()
		_submit()
		return
	if k.ctrl_pressed or k.alt_pressed or k.meta_pressed or k.unicode == 0:
		return
	var ch := String.chr(k.unicode).to_upper()
	if CoopNetData.CODE_ALPHABET.contains(ch):
		get_viewport().set_input_as_handled()
		_add(ch)
