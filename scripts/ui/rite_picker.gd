## RitePicker — the small chooser the pre-run setup screen's Rites strip opens
## (Ossuary expansion steps 5 and 6a, GDD §15.0 "Relics and Grave Offerings"): a
## dim veil and one ornate panel over the setup screen with a title, a grid of
## RelicTiles and one detail line naming the focused tile's full effect.
##   * relic mode (open_relics()): "None" and every OWNED relic (RelicData.ORDER);
##     the one in this slot is gold, one in another slot is tagged with that slot
##     (choosing it moves it here);
##   * offering mode (open_offerings()): "None" and every Grave Offering with its
##     price: teal when the balance can pay it, crimson when it cannot (`denied`),
##     the Borrowed Relic dim while no owned relic is left to lend.
## Choosing calls the `on_pick` callback with the id ("" = none) and closes; Back /
## Esc / B or a click on the veil closes without a change. Focus stays inside the
## panel (explicit neighbours) and returns to the opener tile on close. Never
## touches Meta (the strip edits the RunConfig).
class_name RitePicker
extends Control

## Choice callback: on_pick.call(id) with the chosen id ("" = none).
var on_pick: Callable
## Control focused again when the picker closes.
var return_focus: Control = null
## The title line.
var _title: String = ""
## Tile specs, in order: {"id", "icon", "name", "line", "state", "price", "word", "tip"}.
var _specs: Array = []
## Id -> its RelicTile.
var _tiles: Dictionary = {}
## Id -> the detail line text.
var _tips: Dictionary = {}
## Id -> true when it cannot be chosen (a press answers `denied`).
var _blocked: Dictionary = {}
## The detail line.
var _detail: Label
## The id whose tile is focused first (the current choice).
var _start_id: String = ""


## Opens the relic chooser for slot `slot` (1-based) of `config` over `parent`.
static func open_relics(parent: Control, opener: Control, config: RunConfig, slot: int, pick: Callable) -> RitePicker:
	var p := RitePicker.new()
	p.on_pick = pick
	p.return_focus = opener
	p._title = RelicUiData.PICK_RELIC % slot
	var current := String(config.relics[slot - 1]) if slot - 1 < config.relics.size() else ""  # This slot's relic.
	p._start_id = current
	p._specs.append({"id": "", "icon": "relic_slot", "name": RelicUiData.NONE, "line": RelicUiData.NONE_LINE,
		"state": "chosen" if current == "" else "idle", "price": -1, "word": "", "tip": RelicUiData.NONE_LINE})
	for id: String in RelicData.ORDER:
		if not Meta.relics.is_owned(id):
			continue
		var row: Dictionary = RelicData.RELICS[id]
		var at := config.relics.find(id)  # Its slot index now (-1 = not equipped).
		var state := "chosen" if id == current else "idle"  # Tile state.
		var word := RelicUiData.IN_SLOT % (at + 1) if at >= 0 and id != current else ""  # Another slot's tag.
		p._specs.append({"id": id, "icon": String(row["icon"]), "name": String(row["display_name"]), "line": String(row["short"]),
			"state": state, "price": -1, "word": word, "tip": "%s: %s" % [String(row["display_name"]), String(row["description"])]})
	parent.add_child(p)
	return p


## Opens the Grave Offering chooser for `config` over `parent`.
static func open_offerings(parent: Control, opener: Control, config: RunConfig, pick: Callable) -> RitePicker:
	var p := RitePicker.new()
	p.on_pick = pick
	p.return_focus = opener
	p._title = RelicUiData.PICK_OFFERING
	p._start_id = config.offering_id
	p._specs.append({"id": "", "icon": "offering_slot", "name": RelicUiData.NONE, "line": RelicUiData.NO_OFFERING_LINE,
		"state": "chosen" if config.offering_id == "" else "idle", "price": -1, "word": "", "tip": RelicUiData.OFFERING_TIP})
	for id: String in OfferingData.ORDER:
		var row: Dictionary = OfferingData.OFFERINGS[id]
		var block := Meta.relics.offering_block(id, config.relics)  # "" / "cost" / "borrow".
		var state := "buy"  # Tile state.
		var tip := "%s: %s" % [String(row["display_name"]), String(row["description"])]  # Detail line.
		match block:
			"cost":
				state = "short"
				tip += " " + RelicUiData.OFFERING_SHORT
			"borrow":
				state = "locked"
				tip += " " + RelicUiData.BORROW_NONE
		if id == config.offering_id and block == "":
			state = "chosen"
		p._specs.append({"id": id, "icon": String(row["icon"]), "name": String(row["display_name"]), "line": String(row["short"]),
			"state": state, "price": OfferingData.price(id), "word": "", "tip": tip, "blocked": block != ""})
	parent.add_child(p)
	return p


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := UiTheme.backdrop(0.6)
	veil.gui_input.connect(_on_veil_input)
	add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit.
	var panel := UiTheme.ornate_panel("violet")
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var title := UiTheme.tier_label(_title, UiTheme.Tier.HEADER, UiTheme.TEXT_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var grid := GridContainer.new()
	grid.columns = RelicUiData.PICKER_COLUMNS
	grid.add_theme_constant_override("h_separation", RelicUiData.PICKER_GAP.x)
	grid.add_theme_constant_override("v_separation", RelicUiData.PICKER_GAP.y)
	vb.add_child(grid)
	var order: Array = []  # Tiles in grid order.
	for spec: Dictionary in _specs:
		var id := String(spec["id"])
		var t := RelicTile.new(id, String(spec["icon"]), String(spec["name"]), String(spec["line"]), RelicUiData.PICKER_TILE)
		t.show_state(String(spec["state"]), int(spec["price"]), String(spec["word"]))
		t.pressed.connect(_on_pressed.bind(id))
		t.focus_entered.connect(_show.bind(id))
		t.mouse_entered.connect(_show.bind(id))
		grid.add_child(t)
		_tiles[id] = t
		_tips[id] = String(spec["tip"])
		if bool(spec.get("blocked", false)):
			_blocked[id] = true
		order.append(t)
	_detail = UiTheme.para("", float(RelicUiData.PICKER_COLUMNS) * RelicUiData.PICKER_TILE.x + float((RelicUiData.PICKER_COLUMNS - 1) * RelicUiData.PICKER_GAP.x), UiTheme.TEXT)
	_detail.custom_minimum_size.y = float(UiTheme.tier_px(UiTheme.Tier.BODY)) * 2.0  # Two lines kept: no jump.
	vb.add_child(_detail)
	_wire(order)
	add_child(InputHints.bottom_strip([[InputHints.MOVE, "Move"], ["ui_accept", "Choose"], ["ui_cancel", "Back"]]))
	var first: Control = _tiles.get(_start_id, order[0])  # The current choice.
	first.grab_focus.call_deferred()
	_show(_start_id if _tiles.has(_start_id) else "")
	UiMotion.open(self)


## Explicit neighbours: the grid as rows; every edge stays inside the panel.
func _wire(order: Array) -> void:
	var cols := RelicUiData.PICKER_COLUMNS  # Tiles per row.
	for i in order.size():
		var t: Control = order[i]
		var c := i % cols  # Column.
		var left: Control = order[i - 1] if c > 0 else t
		var right: Control = order[i + 1] if c < cols - 1 and i + 1 < order.size() else t
		var up: Control = order[i - cols] if i - cols >= 0 else t
		var below_row := i - c + cols  # First index of the next row.
		var down: Control = order[mini(i + cols, order.size() - 1)] if below_row < order.size() else t  # A short last row: its last tile.
		t.focus_neighbor_left = t.get_path_to(left)
		t.focus_neighbor_right = t.get_path_to(right)
		t.focus_neighbor_top = t.get_path_to(up)
		t.focus_neighbor_bottom = t.get_path_to(down)
		t.focus_next = t.get_path_to(order[(i + 1) % order.size()])
		t.focus_previous = t.get_path_to(order[(i - 1 + order.size()) % order.size()])


## Writes tile `id`'s full effect in the detail line.
func _show(id: String) -> void:
	_detail.text = String(_tips.get(id, ""))
	_detail.add_theme_color_override("font_color", OssuaryUiData.DENIED if _blocked.has(id) else UiTheme.TEXT)


## A tile was pressed: choose it (or `denied` when it cannot be chosen).
func _on_pressed(id: String) -> void:
	if _blocked.has(id):
		Sfx.play_ui("denied")
		(_tiles[id] as RelicTile).shake()
		_show(id)
		return
	Sfx.play("ui_confirm")
	on_pick.call(id)
	close()


## A click on the veil outside the panel closes the picker.
func _on_veil_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()


## Closes without a change (Back) or after a choice; focus goes back to the opener.
func close() -> void:
	if UiMotion.is_closing(self):
		return
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	UiMotion.close(self, queue_free)


## Esc / controller B closes the picker (and never the setup screen behind it).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
