## ConfirmDialog — the one reusable confirm dialog (GDD §15.0 "Confirm
## dialogs"): a small ornate modal over a screen asking before a destructive
## action (Quit, Restart / Main Menu from pause, Refund all, Lower Oath,
## Reset keys). Open it with
##   ConfirmDialog.ask(host, title, body, confirm_label, on_confirm, danger)
## and wire it as a wrap of the old handler, e.g.
##   b.pressed.connect(func() -> void: ConfirmDialog.ask(self, "Quit?", "...", "Quit", get_tree().quit))
## The dialog is a full-rect child of `host`: a backdrop that swallows the
## mouse, an ornate panel (crimson when `danger`, else violet) with a Jacquard
## title, one body line, a divider and two buttons, Cancel and the confirm
## word (crimson when `danger`). It takes the focus (Cancel by default, so
## an accidental A / Enter never confirms) and keeps it: the two buttons only
## lead to each other. Esc / pad B / pause cancel (Sfx plays ui_back for the
## Cancel button and for Esc / B inside a UiMotion screen). It processes
## while the tree is paused (the pause menu) and opens / closes with UiMotion.
## On close the focus goes back to whatever had it when the dialog opened;
## confirming closes first, then calls `on_confirm`. A second ask() on a host
## whose dialog is still open returns that dialog. Under the autotest
## nothing opens it.
class_name ConfirmDialog
extends Control

## Emitted when the dialog closes (confirmed or not), before it is freed.
signal closed(confirmed: bool)

## Title text (TITLE tier, Jacquard 24).
var title_text: String = ""
## Body text (one BODY line, wraps at ConfirmData.WIDTH).
var body_text: String = ""
## Word on the confirm button.
var confirm_label: String = ""
## Called after the dialog closed with Confirm.
var on_confirm: Callable = Callable()
## True for a destructive action: crimson panel and confirm button.
var danger: bool = true
## The confirm button (built in _ready()).
var confirm_button: Button
## The cancel button (built in _ready(); focused on open).
var cancel_button: Button
## Control focused when the dialog opened (focused again on close; may be null).
var _return_focus: Control = null


## Opens a confirm dialog over `host` (see the header) and returns it. If a
## dialog is already open on `host`, that one is returned unchanged.
static func ask(host: Control, title: String, body: String, confirm_label: String, on_confirm: Callable, danger: bool = true) -> ConfirmDialog:
	for c: Node in host.get_children():
		if c is ConfirmDialog and not UiMotion.is_closing(c):
			return c as ConfirmDialog
	var d := ConfirmDialog.new()
	d.title_text = title
	d.body_text = body
	d.confirm_label = confirm_label
	d.on_confirm = on_confirm
	d.danger = danger
	var vp := host.get_viewport()  # Null when the host is not in the tree.
	d._return_focus = vp.gui_get_focus_owner() if vp != null else null
	host.add_child(d)
	return d


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS  # Works over the paused run.
	theme = UiTheme.get_theme()
	var accent := "crimson" if danger else "violet"  # Kit accent of the panel and confirm button.
	add_child(UiTheme.backdrop(ConfirmData.BACKDROP_ALPHA))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := UiTheme.ornate_panel(accent)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(ConfirmData.WIDTH, 0.0)
	panel.add_child(vb)
	vb.add_child(UiTheme.title(title_text, UiTheme.HEADER_TEXT["crimson"] if danger else UiTheme.TEXT_GOLD))  # Pale crimson on a danger panel.
	var body := UiTheme.para(body_text, ConfirmData.WIDTH, UiTheme.TEXT)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(body)
	vb.add_child(UiTheme.divider(accent))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", ConfirmData.BUTTON_GAP)
	vb.add_child(row)
	cancel_button = _button(row, ConfirmData.CANCEL, cancel)
	confirm_button = _button(row, confirm_label, _confirm)
	if danger:
		UiTheme.style_button(confirm_button, "button", "crimson")
	# The focus stays inside: the two buttons only lead to each other.
	for b: Button in [cancel_button, confirm_button]:
		var other: Button = confirm_button if b == cancel_button else cancel_button
		var to_other := b.get_path_to(other)  # Path to the other button.
		var to_self := b.get_path_to(b)  # Path to itself (a dead end).
		b.focus_neighbor_left = to_other if b == confirm_button else to_self
		b.focus_neighbor_right = to_other if b == cancel_button else to_self
		b.focus_neighbor_top = to_self
		b.focus_neighbor_bottom = to_self
		b.focus_next = to_other
		b.focus_previous = to_other
	cancel_button.grab_focus.call_deferred()
	UiMotion.open(self)


## A dialog button with `text` calling `cb`.
func _button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = ConfirmData.BUTTON_SIZE
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## Closes without confirming (Cancel, Esc / pad B, pause).
func cancel() -> void:
	_close(false)


## Confirm pressed: closes, then runs on_confirm.
func _confirm() -> void:
	if UiMotion.is_closing(self):
		return
	_close(true)
	if on_confirm.is_valid():
		on_confirm.call()


## Closes the dialog (fade out, then freed), restoring the opener's focus.
func _close(confirmed: bool) -> void:
	if UiMotion.is_closing(self):
		return
	closed.emit(confirmed)
	UiMotion.close(self, queue_free)
	if _return_focus != null and is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()


## Esc / pad B (ui_cancel) or the pause button cancel; handled here so the
## screen under the dialog (which closes itself on Esc) never sees it.
func _input(event: InputEvent) -> void:
	if UiMotion.is_closing(self):
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		cancel()
