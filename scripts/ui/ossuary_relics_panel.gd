## OssuaryRelicsPanel — the Ossuary's Relics tab (Ossuary expansion step 5, GDD
## §15.0 "Relics and Grave Offerings"; the tab contract: a Control with refresh()
## and `changed`, loaded by the Ossuary's tab bar). Three blocks, 1200 px wide like
## the tree columns:
##   * the slot row: "Relic slots", one tile per slot (RelicData.MAX_SLOTS): the
##     first is owned from the start, the next one shows its price (teal when
##     affordable), the one after it waits for it; and the relic count;
##   * the relic grid (RelicData.ORDER, 5 x 3 RelicTiles): badge, name, the short
##     effect and the price; gold "Owned" once bought; a relic sold only after a
##     feat (RelicData.FEATS) is dim under a padlock with the feat's word;
##   * ONE ornate detail panel following the focused / hovered tile: the badge at
##     x2, the name, the full effect, and the price with a Buy chip, or the feat
##     to earn / "Owned".
## Pressing an affordable tile buys it through Meta.relics (RelicLedger, saved at
## once) with the `purchase` sound and a flash, then emits `changed` (the
## Ossuary's balance counts down); anything else answers `denied` with a shake.
## On a touchscreen the first tap shows the details and a second tap buys
## (like the upgrade tiles). Relics are equipped on the pre-run setup screen.
## Keyboard / pad: explicit neighbours inside the panel (the slot row over the
## grid, the grid as rows); the panel's outer edges are left to the tab bar.
class_name OssuaryRelicsPanel
extends VBoxContainer

## Emitted after a purchase (the Ossuary redraws its balance).
signal changed

## Relic id -> its RelicTile.
var tiles: Dictionary = {}
## Slot tiles, slot 1 first.
var slot_tiles: Array[RelicTile] = []
## The relic count beside the slot row.
var _count_label: Label
## Detail panel (ornate; its accent follows the state).
var _detail_panel: PanelContainer
## Detail panel parts: "icon", "name", "desc", "state", "cost_icon", "cost", "hint".
var _d: Dictionary = {}
## Id shown in the detail panel (a relic id or "slot_N"; "" = none yet).
var _focus_id: String = ""
## Touch only: the tile tapped once (details shown); a second tap buys ("" = none).
var _touch_armed: String = ""


func _ready() -> void:
	add_theme_constant_override("separation", RelicUiData.BLOCK_GAP)
	custom_minimum_size.x = RelicUiData.PANEL_WIDTH
	add_child(_build_slot_row())
	add_child(_build_grid())
	add_child(_build_detail())
	_wire_focus()
	if not Meta.changed.is_connected(refresh):
		Meta.changed.connect(refresh)
	refresh()
	_show_detail(String(RelicData.ORDER[0]))


## The first tile to focus when the tab opens (the first relic).
func first_focus() -> Control:
	return tiles[RelicData.ORDER[0]]


## The panel's focusable tiles as rows, top to bottom (the slot row, then the
## grid rows): for the tab bar's own wiring.
func focus_rows() -> Array:
	var out: Array = [slot_tiles.duplicate()]  # Rows of Controls.
	out.append_array(_grid_rows())
	return out


# =====================================================================================
# Building
# =====================================================================================

## "Relic slots", one tile per slot and the relic count.
func _build_slot_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", RelicUiData.GRID_GAP.x)
	var label := UiTheme.tier_label(RelicUiData.SLOTS_LABEL, UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	label.custom_minimum_size.x = RelicUiData.SLOT_LABEL_WIDTH
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	for i in RelicData.MAX_SLOTS:
		var key := "slot_%d" % (i + 1)  # Detail id of this slot.
		var t := RelicTile.new(key, "relic_slot", RelicUiData.SLOT_NAME % (i + 1), "", RelicUiData.RELIC_TILE)
		t.pressed.connect(_on_slot_pressed.bind(i + 1))
		t.focus_entered.connect(_show_detail.bind(key))
		t.mouse_entered.connect(_show_detail.bind(key))
		row.add_child(t)
		slot_tiles.append(t)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	_count_label = UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT_DIM)
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_count_label)
	return row


## The relic grid (RelicData.ORDER, GRID_COLUMNS per row).
func _build_grid() -> Control:
	var grid := GridContainer.new()
	grid.columns = RelicUiData.GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", RelicUiData.GRID_GAP.x)
	grid.add_theme_constant_override("v_separation", RelicUiData.GRID_GAP.y)
	for id: String in RelicData.ORDER:
		var row: Dictionary = RelicData.RELICS[id]
		var t := RelicTile.new(id, String(row["icon"]), String(row["display_name"]), String(row["short"]), RelicUiData.RELIC_TILE)
		t.tooltip_text = String(row["description"])
		t.pressed.connect(_on_relic_pressed.bind(id))
		t.focus_entered.connect(_show_detail.bind(id))
		t.mouse_entered.connect(_show_detail.bind(id))
		grid.add_child(t)
		tiles[id] = t
	return grid


## The ornate detail panel (filled by _show_detail()).
func _build_detail() -> Control:
	_detail_panel = UiTheme.ornate_panel("violet")
	_detail_panel.custom_minimum_size.x = RelicUiData.PANEL_WIDTH
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	_detail_panel.add_child(hb)
	var icon := IconGlyph.new("", Vector2(RelicUiData.DETAIL_ICON, RelicUiData.DETAIL_ICON))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(icon)
	_d["icon"] = icon
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 3)
	hb.add_child(vb)
	var name_label := UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT)
	vb.add_child(name_label)
	_d["name"] = name_label
	var desc := UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	desc.clip_text = true
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.custom_minimum_size.x = 600.0  # The panel's width decides; this only stops a long line widening it.
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(desc)
	_d["desc"] = desc
	var line := HBoxContainer.new()  # State line, spacer, price, Buy chip.
	line.add_theme_constant_override("separation", 8)
	vb.add_child(line)
	var state := UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(state)
	_d["state"] = state
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(spacer)
	var cost_icon := IconGlyph.new("soul_ash_small", Vector2(OssuaryUiData.COST_ICON, OssuaryUiData.COST_ICON))
	cost_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(cost_icon)
	_d["cost_icon"] = cost_icon
	var cost := UiTheme.tier_label("", UiTheme.Tier.NAME, OssuaryUiData.ASH_COLOR)
	line.add_child(cost)
	_d["cost"] = cost
	var hint := InputHints.hint("ui_accept", OssuaryUiData.BUY)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(hint)
	_d["hint"] = hint
	return _detail_panel


## The grid's tiles as rows (GRID_COLUMNS each).
func _grid_rows() -> Array:
	var out: Array = []  # Rows of tiles.
	for i in range(0, RelicData.ORDER.size(), RelicUiData.GRID_COLUMNS):
		var row: Array = []
		for k in range(i, mini(RelicData.ORDER.size(), i + RelicUiData.GRID_COLUMNS)):
			row.append(tiles[RelicData.ORDER[k]])
		out.append(row)
	return out


## Explicit neighbours inside the panel: rows left / right (ends stay), up / down
## by column; slot j sits over grid column j + 1 (the label takes column 0's
## place), the grid's first row leads up to the slot row.
func _wire_focus() -> void:
	var rows := _grid_rows()  # Grid rows.
	for r in rows.size():
		var row: Array = rows[r]
		for c in row.size():
			var t: Control = row[c]
			_link(t, "left", row[maxi(0, c - 1)])
			_link(t, "right", row[mini(row.size() - 1, c + 1)])
			if r > 0:
				var up: Array = rows[r - 1]
				_link(t, "top", up[mini(c, up.size() - 1)])
			else:
				_link(t, "top", slot_tiles[clampi(c - 1, 0, slot_tiles.size() - 1)])
			if r < rows.size() - 1:
				var down: Array = rows[r + 1]
				_link(t, "bottom", down[mini(c, down.size() - 1)])
	for j in slot_tiles.size():
		var s: Control = slot_tiles[j]
		_link(s, "left", slot_tiles[maxi(0, j - 1)])
		_link(s, "right", slot_tiles[mini(slot_tiles.size() - 1, j + 1)])
		_link(s, "bottom", (rows[0] as Array)[mini(j + 1, (rows[0] as Array).size() - 1)])


## Sets focus neighbour `side` of `c` to `to`.
static func _link(c: Control, side: String, to: Control) -> void:
	c.set("focus_neighbor_" + side, c.get_path_to(to))


# =====================================================================================
# Display
# =====================================================================================

## Redraws every tile, the count and the detail panel from Meta.relics.
func refresh() -> void:
	if not is_inside_tree():
		return
	var led := Meta.relics  # The save's relic ledger.
	for id: String in RelicData.ORDER:
		var t: RelicTile = tiles[id]
		match led.buy_block(id):
			"owned":
				t.show_state("owned", -1, RelicUiData.OWNED)
			"feat":
				t.show_state("locked", -1, String(RelicData.FEATS[String(RelicData.RELICS[id]["feat"])]["short"]))
			"cost":
				t.show_state("cost", RelicData.price(id))
			_:
				t.show_state("buy", RelicData.price(id))
	for i in slot_tiles.size():
		var n := i + 1  # Slot number.
		var t: RelicTile = slot_tiles[i]
		if n <= led.slots:
			t.show_state("owned", -1, RelicUiData.SLOT_OWNED)
			t.line_label.text = RelicUiData.SLOT_OWNED_LINE
		elif n == led.slots + 1:
			t.show_state("buy" if led.slot_block() == "" else "cost", RelicData.slot_price(n))
			t.line_label.text = RelicUiData.SLOT_NEXT_LINE
		else:
			t.show_state("locked", RelicData.slot_price(n))
			t.line_label.text = RelicUiData.SLOT_LATER_LINE
		t.line_label.visible = true
	_count_label.text = RelicUiData.SPENT % [led.owned.size(), RelicData.ORDER.size()]
	if _focus_id != "":
		_show_detail(_focus_id)


## Shows relic `id` (or slot "slot_N") in the detail panel.
func _show_detail(id: String) -> void:
	_focus_id = id
	var led := Meta.relics  # The save's relic ledger.
	var icon: IconGlyph = _d["icon"]
	var name_l: Label = _d["name"]
	var desc: Label = _d["desc"]
	var state: Label = _d["state"]
	var cost: Label = _d["cost"]
	var cost_icon: IconGlyph = _d["cost_icon"]
	var hint: Control = _d["hint"]
	var accent := "violet"  # Detail frame accent.
	var price := -1  # Price shown (-1 = none).
	var can_buy := false  # The Buy chip shows.
	state.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
	if id.begins_with("slot_"):
		var n := id.substr(5).to_int()  # Slot number.
		icon.set_icon("relic_slot")
		icon.modulate = Color.WHITE
		name_l.text = RelicUiData.SLOT_NAME % n
		desc.text = RelicUiData.SLOT_DETAIL % n
		if n <= led.slots:
			accent = "gold"
			state.text = RelicUiData.SLOT_OWNED
			state.add_theme_color_override("font_color", UiTheme.TEXT_GOLD)
		elif n == led.slots + 1:
			price = RelicData.slot_price(n)
			can_buy = led.slot_block() == ""
			state.text = ""
		else:
			price = RelicData.slot_price(n)
			state.text = RelicUiData.SLOT_DETAIL_LATER % (led.slots + 1)
			state.add_theme_color_override("font_color", OssuaryUiData.DENIED)
	else:
		var row: Dictionary = RelicData.RELICS[id]
		var block := led.buy_block(id)  # Why it cannot be bought ("" = it can).
		icon.set_icon(String(row["icon"]))
		icon.modulate = OssuaryUiData.LOCKED_ICON_TINT if block == "feat" else Color.WHITE
		name_l.text = String(row["display_name"])
		desc.text = String(row["description"])
		match block:
			"owned":
				accent = "gold"
				state.text = RelicUiData.OWNED_LINE
				state.add_theme_color_override("font_color", UiTheme.TEXT_GOLD)
			"feat":
				state.text = String(RelicData.FEATS[String(row["feat"])]["text"])
				state.add_theme_color_override("font_color", OssuaryUiData.DENIED)
			_:
				price = RelicData.price(id)
				can_buy = block == ""
				state.text = ""
	name_l.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if accent == "gold" else UiTheme.TEXT)
	_detail_panel.add_theme_stylebox_override("panel", UiTheme.style("ornate", accent))
	cost_icon.visible = price >= 0
	cost.visible = price >= 0
	cost.text = str(price)
	cost.add_theme_color_override("font_color", OssuaryUiData.ASH_COLOR if can_buy else OssuaryUiData.COST_SHORT)
	hint.visible = can_buy


# =====================================================================================
# Actions
# =====================================================================================

## A relic tile was pressed: buy it, or `denied`.
func _on_relic_pressed(id: String) -> void:
	if _touch_first(id):
		return
	var t: RelicTile = tiles[id]
	if Meta.relics.buy(id):  # Saves and emits Meta.changed (refresh()).
		Sfx.play_ui("purchase")
		t.flash()
		changed.emit()
		return
	Sfx.play_ui("denied")
	t.shake()


## Slot tile `n` was pressed: buy it when it is the next one, else `denied`.
func _on_slot_pressed(n: int) -> void:
	if _touch_first("slot_%d" % n):
		return
	var t: RelicTile = slot_tiles[n - 1]
	if n == Meta.relics.slots + 1 and Meta.relics.buy_slot():
		Sfx.play_ui("purchase")
		t.flash()
		changed.emit()
		return
	Sfx.play_ui("denied")
	t.shake()


## Touch input: the first tap on a tile only shows its details (a finger has no
## hover). Returns true when this press was that first tap.
func _touch_first(id: String) -> bool:
	if InputHints.device() != InputHints.Device.TOUCH or _touch_armed == id:
		return false
	_touch_armed = id
	_show_detail(id)
	Sfx.play_ui("ui_tick")
	return true
