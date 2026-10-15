## OssuaryMenu — the Soul Ash upgrade shop (GDD §10.1 "Upgrades", §9.2 four
## upgrade trees), opened from the main menu. Menu modernization wave 2 (GDD
## §15.0 "Ossuary redesign"; owner: "go the extra mile", "less wordy"):
##   * a title row: "The Ossuary" and the Soul Ash balance (the Soul Ash
##     badge and the number, which counts down after a purchase while the
##     spent amount floats away);
##   * four tree columns (Necromancy, Shadowcraft, Survival, Fortune) under
##     header bands with their pixel emblems; each upgrade is one OssuaryTile
##     (icon, name, level pips, next cost; its frame colour is its state:
##     soul teal affordable, violet too expensive, gold maxed, dim locked);
##   * ONE ornate detail panel that follows the focused / hovered tile: its
##     icon at x2, name and pips, the one-line effect, the current → next
##     value with a pixel arrow, the cost with the Soul Ash symbol (or what it
##     needs / "Maxed") and a Buy chip when it can be bought;
##   * bottom right: the standalone Profane Oath tile (opt-in difficulty,
##     MetaData "oath", crimson once owned: its pips show the active tiers
##     bright and owned-but-lowered tiers dark), "Lower Oath" (lowers the
##     ACTIVE tier by one at once: free and reversible, owned tiers stay owned,
##     Meta.set_oath_active), "Refund all" (respec; asks first) and Back.
## Pressing an affordable tile buys its next tier through the Meta autoload
## (which saves at once) with the `purchase` sound, a flash and spark burst on
## the tile; a locked, too expensive or maxed tile plays `denied` and shakes.
## A lowered Oath tile raises the active tier again for free. Refund all and
## Lower Oath never look disabled (Lower Oath turns crimson while an Oath
## tier is active): with nothing to refund / lower they answer `denied`.
## Fully usable with keyboard and controller: explicit focus neighbours make
## the tiles a grid (up / down inside a tree, left / right across trees at the
## same row, down from any tree to the Oath tile, up from it back to the tree
## last visited), A / Enter buys, B / Esc closes the confirmation or the
## menu. On a touchscreen (no hover) the first tap on a tile shows its
## details and a second tap on the same tile buys. The first upgrade is focused on open. Every number is in
## OssuaryUiData; the upgrade data stays in MetaData.
## Open it with OssuaryMenu.open_over(parent, button_to_refocus).
class_name OssuaryMenu
extends Control

## Emitted when the menu is about to be freed.
signal closed

## Roman numerals for tier names in prerequisite text (index = tier, 0..6).
const ROMAN := ["0", "I", "II", "III", "IV", "V", "VI"]

## Control focused again when the menu closes (may be null).
var return_focus: Control = null
## Upgrade id -> its OssuaryTile (the four trees and the Oath).
var buttons: Dictionary = {}
## Tiles per tree column, in MetaData.TREE_ORDER (the focus grid).
var _grid: Array = []
## "Refund all" button.
var refund_button: Button
## "Back" button.
var back_button: Button
## Profane Oath tile (bottom right).
var oath_button: OssuaryTile
## "Lower Oath" button: lowers the active Oath tier by one (free, reversible).
var oath_lower_button: Button
## Soul Ash balance label (HEADER tier).
var _ash_label: Label
## Floating "-N" label shown next to the balance after a purchase.
var _spent_float: Label
## Balance to count from on the next refresh (-1 = set the text at once).
var _count_from: int = -1
## Upgrade id shown in the detail panel ("" = none yet).
var _focus_id: String = ""
## Tree column (0..3) of the last focused upgrade tile (the Oath tile's "up").
var _last_col: int = 0
## Touch input only: the upgrade tile tapped once (its details shown); a
## second tap on it buys ("" = none). Keys, pads and mice buy at once.
var _touch_armed: String = ""
## Detail panel (ornate PanelContainer; its accent follows the state).
var _detail_panel: PanelContainer
## Detail panel parts: "icon" IconGlyph, "name" Label, "pips" Pips, "desc"
## Label, "stat" / "cur" / "arrow" / "next" (first value), "stat2" / "cur2" /
## "arrow2" / "next2" (second value, the Oath's Ash line), "cost_icon"
## IconGlyph, "cost" Label, "hint" input hint, "hint_word" its Label.
var _d: Dictionary = {}
## Refund confirmation overlay (null while closed).
var _confirm: Control = null
## Confirmation "Refund" button (valid while _confirm is open).
var confirm_yes: Button = null
## Confirmation "Cancel" button (valid while _confirm is open).
var confirm_no: Button = null


## Creates the menu as a full-screen child of `parent` and returns it.
## `refocus` regains focus when the menu closes.
static func open_over(parent: Control, refocus: Control) -> OssuaryMenu:
	var m := OssuaryMenu.new()
	m.return_focus = refocus
	parent.add_child(m)
	return m


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UiTheme.backdrop(0.82))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit (no-op at 720 px).
	var root := VBoxContainer.new()  # Title row, trees, bottom row.
	root.add_theme_constant_override("separation", OssuaryUiData.BLOCK_GAP)
	center.add_child(root)
	root.add_child(_build_header())
	var cols := HBoxContainer.new()  # The four tree columns.
	cols.add_theme_constant_override("separation", OssuaryUiData.COLUMN_GAP)
	root.add_child(cols)
	for tree_id: String in MetaData.TREE_ORDER:
		cols.add_child(_build_column(tree_id))
	root.add_child(_build_bottom())
	_wire_focus()
	Meta.changed.connect(_refresh)
	_refresh()
	var first: Button = _grid[0][0]
	first.grab_focus.call_deferred()
	_show_detail(String((first as OssuaryTile).upgrade_id))
	UiMotion.open(self)  # Fade / rise in.
	var tiles: Array = []  # Entrance order: column by column.
	for col: Array in _grid:
		tiles.append_array(col)
	UiMotion.stagger(tiles, 0.04, 0.018)


## Title and the Soul Ash balance (badge, number and the floating "-N").
func _build_header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var title := UiTheme.tier_label(OssuaryUiData.TITLE, UiTheme.Tier.TITLE, UiTheme.TEXT_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	var icon := IconGlyph.new("soul_ash", Vector2(OssuaryUiData.BALANCE_ICON, OssuaryUiData.BALANCE_ICON))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	_ash_label = UiTheme.tier_label("", UiTheme.Tier.HEADER, OssuaryUiData.ASH_COLOR)
	_ash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ash_label.custom_minimum_size.x = 96.0  # Room for 5 digits: the row does not jump while counting.
	row.add_child(_ash_label)
	_spent_float = UiTheme.tier_label("", UiTheme.Tier.NAME, OssuaryUiData.DENIED)
	_spent_float.modulate.a = 0.0
	_ash_label.add_child(_spent_float)  # Floats over the balance (a Label is not a Container).
	return row


## One tree column: a header band (emblem + name), then one tile per upgrade.
func _build_column(tree_id: String) -> Control:
	var def: Dictionary = MetaData.TREES[tree_id]
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", OssuaryUiData.ROW_GAP)
	vb.add_child(_tree_band(def))
	var column: Array[Button] = []
	for id: String in MetaData.upgrades_in(tree_id):
		var b := _make_tile(id)
		vb.add_child(b)
		column.append(b)
	_grid.append(column)
	return vb


## A tree's header band: the kit header strip holding the tree emblem and
## its name in the tree's colour.
func _tree_band(def: Dictionary) -> Control:
	var band := PanelContainer.new()
	band.add_theme_stylebox_override("panel", UiTheme.style("header", "violet"))
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.custom_minimum_size.x = OssuaryUiData.TILE_SIZE.x
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 8)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(hb)
	var icon := IconGlyph.new(String(def["icon"]), Vector2(OssuaryUiData.TREE_ICON, OssuaryUiData.TREE_ICON))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(icon)
	var name_label := UiTheme.tier_label(String(def["display_name"]), UiTheme.Tier.NAME, (def["color"] as Color).lightened(0.3))
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(name_label)
	return band


## Builds the tile of upgrade `id` (its state is filled by _refresh()).
func _make_tile(id: String) -> OssuaryTile:
	var b := OssuaryTile.new(id)
	b.pressed.connect(_on_upgrade_pressed.bind(id))
	b.focus_entered.connect(_on_tile_focus.bind(id))
	b.mouse_entered.connect(_show_detail.bind(id))
	buttons[id] = b
	return b


## Bottom row: the detail panel (left, three columns wide) and the Oath /
## Refund all / Back cluster (right, one column wide).
func _build_bottom() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", OssuaryUiData.COLUMN_GAP)
	row.add_child(_build_detail())
	var right := VBoxContainer.new()  # Oath tile, Lower + Refund, Back.
	right.add_theme_constant_override("separation", OssuaryUiData.ROW_GAP)
	right.custom_minimum_size.x = OssuaryUiData.TILE_SIZE.x
	right.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(right)
	oath_button = _make_tile(PactData.OATH_ID)
	right.add_child(oath_button)
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", OssuaryUiData.ROW_GAP)
	right.add_child(pair)
	oath_lower_button = _plain_button(pair, OssuaryUiData.LOWER, lower_oath)
	refund_button = _plain_button(pair, OssuaryUiData.REFUND, _on_refund_pressed)
	back_button = _plain_button(right, OssuaryUiData.BACK, close)
	back_button.set_meta(&"ui_back", true)
	InputHints.attach(back_button, "ui_cancel", true, 12.0)
	return row


## The ornate detail panel (contents filled by _show_detail()).
func _build_detail() -> Control:
	_detail_panel = UiTheme.ornate_panel("violet")
	_detail_panel.custom_minimum_size.x = OssuaryUiData.TILE_SIZE.x * 3.0 + float(OssuaryUiData.COLUMN_GAP) * 2.0
	_detail_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	_detail_panel.add_child(hb)
	var icon := IconGlyph.new("", Vector2(OssuaryUiData.DETAIL_ICON, OssuaryUiData.DETAIL_ICON))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(icon)
	_d["icon"] = icon
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 3)
	hb.add_child(vb)
	var top := HBoxContainer.new()  # Name, pips.
	top.add_theme_constant_override("separation", 12)
	vb.add_child(top)
	var name_label := UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT_GOLD)
	top.add_child(name_label)
	_d["name"] = name_label
	var pips := PixelMarks.Pips.new(OssuaryUiData.PIP_SIZE_BIG)
	top.add_child(pips)
	_d["pips"] = pips
	var desc := UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	desc.clip_text = true
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.custom_minimum_size.x = 600.0  # The panel's width decides; this only stops a long line widening it.
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(desc)
	_d["desc"] = desc
	var vals := HBoxContainer.new()  # Stat values, spacer, cost, Buy chip.
	vals.add_theme_constant_override("separation", 8)
	vb.add_child(vals)
	for suffix: String in ["", "2"]:
		var stat := UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
		stat.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		vals.add_child(stat)
		var cur := UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT)
		vals.add_child(cur)
		var arrow := PixelMarks.Arrow.new(UiTheme.TEXT_DIM)
		vals.add_child(arrow)
		var nxt := UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT_GOOD)
		vals.add_child(nxt)
		_d["stat" + suffix] = stat
		_d["cur" + suffix] = cur
		_d["arrow" + suffix] = arrow
		_d["next" + suffix] = nxt
		if suffix == "":
			var gap := Control.new()  # Between the Oath's two value groups.
			gap.custom_minimum_size.x = 14.0
			gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vals.add_child(gap)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vals.add_child(spacer)
	var cost_icon := IconGlyph.new("soul_ash_small", Vector2(OssuaryUiData.COST_ICON, OssuaryUiData.COST_ICON))
	cost_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vals.add_child(cost_icon)
	_d["cost_icon"] = cost_icon
	var cost := UiTheme.tier_label("", UiTheme.Tier.NAME, OssuaryUiData.ASH_COLOR)
	vals.add_child(cost)
	_d["cost"] = cost
	var hint := InputHints.hint("ui_accept", OssuaryUiData.BUY)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vals.add_child(hint)
	_d["hint"] = hint
	_d["hint_word"] = hint.get_child(hint.get_child_count() - 1)
	return _detail_panel


## Adds a bottom-row button calling `cb`.
func _plain_button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2((OssuaryUiData.TILE_SIZE.x - float(OssuaryUiData.ROW_GAP)) * 0.5, OssuaryUiData.BUTTON_HEIGHT)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## Explicit focus neighbours so D-pad / stick / arrow navigation is a grid.
func _wire_focus() -> void:
	var n_cols := _grid.size()
	for c in n_cols:
		var col: Array = _grid[c]
		for r in col.size():
			var b: Button = col[r]
			var up: Control = col[r - 1] if r > 0 else b
			var down: Control = col[r + 1] if r < col.size() - 1 else oath_button
			var left_col: Array = _grid[c - 1] if c > 0 else col
			var right_col: Array = _grid[c + 1] if c < n_cols - 1 else col
			var left: Control = left_col[mini(r, left_col.size() - 1)]
			var right: Control = right_col[mini(r, right_col.size() - 1)]
			_set_neighbors(b, up, down, left, right)
			b.focus_previous = b.get_path_to(left)
			b.focus_next = b.get_path_to(right)
	var last_col: Array = _grid[n_cols - 1]
	_set_neighbors(oath_button, last_col[last_col.size() - 1], oath_lower_button, oath_button, oath_button)
	_set_neighbors(oath_lower_button, oath_button, back_button, oath_lower_button, refund_button)
	_set_neighbors(refund_button, oath_button, back_button, oath_lower_button, refund_button)
	_set_neighbors(back_button, oath_lower_button, back_button, back_button, back_button)


## Sets the four focus neighbours of `b`.
func _set_neighbors(b: Control, up: Control, down: Control, left: Control, right: Control) -> void:
	b.focus_neighbor_top = b.get_path_to(up)
	b.focus_neighbor_bottom = b.get_path_to(down)
	b.focus_neighbor_left = b.get_path_to(left)
	b.focus_neighbor_right = b.get_path_to(right)


## A tile took focus: show it, and make the Oath tile's "up" return to this
## tree column.
func _on_tile_focus(id: String) -> void:
	_show_detail(id)
	for c in _grid.size():
		var col: Array = _grid[c]
		for b: Button in col:
			if b == buttons[id]:
				_last_col = c
				var back_to: Button = col[col.size() - 1]  # Bottom tile of this column.
				oath_button.focus_neighbor_top = oath_button.get_path_to(back_to)
				return


# =====================================================================================
# Display
# =====================================================================================

## Refreshes the balance, every tile, the bottom buttons and the detail panel.
func _refresh() -> void:
	_show_balance()
	for id: String in buttons:
		_refresh_tile(id)
	# Never the disabled look: Lower Oath turns crimson while an Oath tier is
	# active; with nothing to lower / refund a press answers `denied`.
	UiTheme.style_button(oath_lower_button, "button", "crimson" if Meta.oath_active_tier() > 0 else "")
	if _focus_id != "":
		_show_detail(_focus_id)


## Writes the Soul Ash balance: counts from _count_from when a purchase or
## refund just changed it (UiMotion.count_up(); instant without motion).
func _show_balance() -> void:
	if _count_from >= 0 and _count_from != Meta.soul_ash:
		UiMotion.count_up(_ash_label, Meta.soul_ash, "%d", _count_from, false, 0.0, OssuaryUiData.COUNT_TIME)
	else:
		_ash_label.text = str(Meta.soul_ash)
	_count_from = -1


## The display state of upgrade `id`: "buy", "cost", "maxed" or "locked"
## (Meta.purchase_block(); a lowered Oath counts as "buy": its raise is free).
static func _state_of(id: String) -> String:
	if id == PactData.OATH_ID and Meta.oath_active_tier() < Meta.tier(id):
		return "buy"
	var block := Meta.purchase_block(id)
	return "buy" if block == "" else block


## Updates one tile from Meta.
func _refresh_tile(id: String) -> void:
	var tile: OssuaryTile = buttons[id]
	var state := _state_of(id)
	var t := Meta.tier(id)
	var mx := MetaData.max_tier(id)
	var cost := Meta.next_cost(id) if state != "maxed" else 0
	if id == PactData.OATH_ID:
		tile.show_state(state, Meta.oath_active_tier(), mx, cost, t)
		if Meta.oath_active_tier() < t:
			tile.cost_icon.visible = false
			tile.cost_label.text = OssuaryUiData.FREE
			tile.cost_label.add_theme_color_override("font_color", UiTheme.TEXT_GOOD)
		return
	tile.show_state(state, t, mx, cost)


## "+6%" style value of upgrade `id` at tier `t` (MetaData.STATS format).
static func _value(id: String, t: int) -> String:
	var def: Dictionary = MetaData.UPGRADES[id]
	var stat_def: Array = MetaData.STATS[String(def["stat"])]
	return format_stat(float(def["per_tier"]) * float(t), String(stat_def[1]))


## Formats a modifier value per its MetaData.STATS format.
static func format_stat(v: float, fmt: String) -> String:
	match fmt:
		"pct":
			return "+%d%%" % int(roundf(v * 100.0))
		"neg_pct":
			return "-%d%%" % int(roundf(v * 100.0))
		"unlock":
			return "Unlocked" if v >= 1.0 else "Locked"
	return "+%d" % int(roundf(v))


## Shows upgrade `id` in the detail panel: icon, name, pips, one-line
## effect, current → next value, cost (or prerequisite / Maxed) and the Buy
## chip when it can be bought.
func _show_detail(id: String) -> void:
	_focus_id = id
	var def: Dictionary = MetaData.UPGRADES[id]
	var state := _state_of(id)
	var t := Meta.tier(id)
	var mx := MetaData.max_tier(id)
	var is_oath := id == PactData.OATH_ID
	(_d["icon"] as IconGlyph).set_icon(String(def["icon"]))
	(_d["icon"] as IconGlyph).modulate = OssuaryUiData.LOCKED_ICON_TINT if state == "locked" else Color.WHITE
	var name_label: Label = _d["name"]
	name_label.text = String(def["display_name"])
	var accent := "violet"  # Detail panel frame accent.
	var name_col := UiTheme.TEXT
	match state:
		"maxed":
			accent = "gold"
			name_col = UiTheme.TEXT_GOLD
		"locked":
			name_col = UiTheme.TEXT_DIM
	if is_oath:
		accent = "crimson"
		name_col = UiTheme.HEADER_TEXT["crimson"]
	name_label.add_theme_color_override("font_color", name_col)
	_detail_panel.add_theme_stylebox_override("panel", UiTheme.style("ornate", accent))
	var pips: PixelMarks.Pips = _d["pips"]
	if is_oath:
		pips.set_pips(mx, Meta.oath_active_tier(), OssuaryUiData.PIP_OATH, t)
	else:
		pips.set_pips(mx, t, OssuaryUiData.PIP_MAXED if state == "maxed" else OssuaryUiData.PIP_OWNED)
	(_d["desc"] as Label).text = OssuaryUiData.OATH_LINE if is_oath else String(def["description"])
	if is_oath:
		_show_oath_values()
	else:
		var stat_def: Array = MetaData.STATS[String(def["stat"])]
		_set_value("", String(stat_def[0]), _value(id, t), _value(id, t + 1) if t < mx else "")
		_set_value("2", "", "", "")
	_show_cost(id, state)


## Fills value group `suffix` ("" or "2"): `stat` label, `cur` value, and
## `nxt` after the arrow (no arrow / next when empty: maxed). An empty
## `stat` hides the whole group.
func _set_value(suffix: String, stat: String, cur: String, nxt: String) -> void:
	var on := stat != ""
	(_d["stat" + suffix] as Label).text = stat
	(_d["stat" + suffix] as Label).visible = on
	(_d["cur" + suffix] as Label).text = cur
	(_d["cur" + suffix] as Label).visible = on
	(_d["arrow" + suffix] as Control).visible = on and nxt != ""
	(_d["next" + suffix] as Label).text = nxt
	(_d["next" + suffix] as Label).visible = on and nxt != ""


## The Oath's two values for the next ACTIVE tier: enemy HP and Soul Ash.
func _show_oath_values() -> void:
	var t := Meta.oath_active_tier()  # Active tier now.
	var per: Dictionary = PactData.OATH_PER_TIER  # Bonus per tier.
	var hp := float(per["enemy_hp"])
	var ash := float(per["ash_gain"])
	var top := t >= MetaData.max_tier(PactData.OATH_ID)  # No next tier.
	_set_value("", OssuaryUiData.OATH_HP, "+%d%%" % int(roundf(hp * t * 100.0)), "" if top else "+%d%%" % int(roundf(hp * (t + 1) * 100.0)))
	_set_value("2", OssuaryUiData.OATH_ASH, "+%d%%" % int(roundf(ash * t * 100.0)), "" if top else "+%d%%" % int(roundf(ash * (t + 1) * 100.0)))
	(_d["next"] as Label).add_theme_color_override("font_color", OssuaryUiData.DENIED)


## The cost corner of the detail panel for upgrade `id` in `state`.
func _show_cost(id: String, state: String) -> void:
	var cost: Label = _d["cost"]
	var icon: IconGlyph = _d["cost_icon"]
	var hint: Control = _d["hint"]
	var word: Label = _d["hint_word"]
	(_d["next"] as Label).add_theme_color_override("font_color", OssuaryUiData.DENIED if id == PactData.OATH_ID else UiTheme.TEXT_GOOD)
	icon.visible = true
	hint.visible = false
	word.text = OssuaryUiData.BUY
	cost.add_theme_color_override("font_color", OssuaryUiData.ASH_COLOR)
	if id == PactData.OATH_ID and Meta.oath_active_tier() < Meta.tier(id):
		icon.visible = false
		cost.text = OssuaryUiData.FREE
		cost.add_theme_color_override("font_color", UiTheme.TEXT_GOOD)
		word.text = OssuaryUiData.RAISE
		hint.visible = true
		return
	match state:
		"maxed":
			icon.visible = false
			cost.text = OssuaryUiData.MAXED_LONG
			cost.add_theme_color_override("font_color", UiTheme.TEXT_GOLD)
		"locked":
			var req: Dictionary = MetaData.UPGRADES[id]["requires"]
			icon.visible = false
			cost.text = OssuaryUiData.NEEDS % [String(MetaData.UPGRADES[req["id"]]["display_name"]), ROMAN[int(req["tier"])]]
			cost.add_theme_color_override("font_color", OssuaryUiData.DENIED)
		"cost":
			cost.text = str(Meta.next_cost(id))
			cost.add_theme_color_override("font_color", OssuaryUiData.COST_SHORT)
		_:
			cost.text = str(Meta.next_cost(id))
			hint.visible = true


# =====================================================================================
# Actions
# =====================================================================================

## Buys the next tier of `id` (or raises a lowered Oath for free), or
## answers `denied` with a shake when it cannot be bought.
func _on_upgrade_pressed(id: String) -> void:
	var tile: OssuaryTile = buttons[id]
	if InputHints.device() == InputHints.Device.TOUCH and _touch_armed != id:
		# A finger has no hover: the first tap on a tile shows its details,
		# a second tap on the same tile buys (GDD §15.0 "Mobile browser support").
		_touch_armed = id
		_show_detail(id)
		Sfx.play_ui("ui_tick")
		return
	if id == PactData.OATH_ID and Meta.oath_active_tier() < Meta.tier(id):
		# A lowered Oath goes back up for free (the tier is still owned).
		Meta.set_oath_active(Meta.oath_active_tier() + 1)
		Sfx.play_ui("purchase")
		tile.flash()
		return
	if Meta.purchase_block(id) != "":
		Sfx.play_ui("denied")  # Maxed, locked or too expensive.
		tile.shake()
		_flash_cost()
		return
	var cost := Meta.next_cost(id)
	_count_from = Meta.soul_ash
	if Meta.purchase(id):  # Emits Meta.changed: _refresh() counts the balance down.
		Sfx.play_ui("purchase")  # Bright bone-chime.
		tile.flash()
		_float_spent(cost)
	_count_from = -1


## The detail panel's cost line blinks red (a denied press).
func _flash_cost() -> void:
	var cost: Label = _d["cost"]
	if not UiMotion.enabled():
		return
	cost.modulate = Color(1.6, 0.6, 0.6)
	var tw := cost.create_tween()  # Short, real time is not needed (menus run at time scale 1).
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(cost, "modulate", Color.WHITE, OssuaryUiData.SHAKE_TIME)


## Shows "-N" over the balance, rising and fading (skipped without motion).
func _float_spent(n: int) -> void:
	if not UiMotion.enabled():
		return
	_spent_float.text = "-%d" % n
	var y0 := -OssuaryUiData.SPENT_FLOAT_START  # Just above the balance number.
	_spent_float.position = Vector2(0.0, y0)
	_spent_float.modulate.a = 1.0
	var tw := _spent_float.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(_spent_float, "position:y", y0 - OssuaryUiData.SPENT_FLOAT_RISE, OssuaryUiData.SPENT_FLOAT_TIME).set_ease(Tween.EASE_OUT)
	tw.tween_property(_spent_float, "modulate:a", 0.0, OssuaryUiData.SPENT_FLOAT_TIME).set_ease(Tween.EASE_IN)


## Lower Oath: lowers the ACTIVE Oath tier by one at once (free and
## reversible: owned tiers stay owned and raise again for free), or answers
## `denied` when the Oath is off.
func lower_oath() -> void:
	var active := Meta.oath_active_tier()
	if active <= 0:
		Sfx.play_ui("denied")
		return
	Meta.set_oath_active(active - 1)
	Sfx.play("ui_confirm")


## Refund all pressed: asks first (or `denied` when nothing is spent).
## The Ossuary keeps its own refund dialog (it shows the Soul Ash it returns).
func _on_refund_pressed() -> void:
	if Meta.spent_total() <= 0:
		Sfx.play_ui("denied")
		return
	_ask_refund()


## Refunds every upgrade (respec): the balance counts back up.
func refund_all() -> void:
	_count_from = Meta.soul_ash
	Meta.refund_all()
	_count_from = -1
	Sfx.play_ui("purchase")


# --- Refund confirmation (a small crimson ornate dialog, Cancel focused) -----------------

## True while the refund confirmation is shown.
func confirm_open() -> bool:
	return _confirm != null


## Shows "Refund every upgrade?" with the Soul Ash it returns; Cancel is focused.
func _ask_refund() -> void:
	if _confirm != null:
		return
	_confirm = Control.new()
	_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm.add_child(UiTheme.backdrop(0.6))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.add_child(center)
	var panel := UiTheme.ornate_panel("crimson")
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(380, 0)
	panel.add_child(vb)
	var title := UiTheme.tier_label(OssuaryUiData.REFUND_ASK, UiTheme.Tier.NAME, UiTheme.HEADER_TEXT["crimson"])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var gain := HBoxContainer.new()  # Soul Ash symbol and "+N".
	gain.alignment = BoxContainer.ALIGNMENT_CENTER
	gain.add_theme_constant_override("separation", 8)
	vb.add_child(gain)
	var icon := IconGlyph.new("soul_ash", Vector2(OssuaryUiData.BALANCE_ICON, OssuaryUiData.BALANCE_ICON))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gain.add_child(icon)
	gain.add_child(UiTheme.tier_label(OssuaryUiData.REFUND_GAIN % Meta.spent_total(), UiTheme.Tier.HEADER, OssuaryUiData.ASH_COLOR))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	confirm_yes = _plain_button(row, OssuaryUiData.REFUND_YES, _confirm_refund)
	UiTheme.style_button(confirm_yes, "button", "crimson")
	confirm_no = _plain_button(row, OssuaryUiData.REFUND_NO, _close_confirm)
	confirm_no.set_meta(&"ui_back", true)
	for b: Button in [confirm_yes, confirm_no]:
		b.custom_minimum_size = Vector2(160, OssuaryUiData.BUTTON_HEIGHT)
	add_child(_confirm)
	# Focus stays inside the dialog: the two buttons only lead to each other.
	_set_neighbors(confirm_yes, confirm_yes, confirm_yes, confirm_yes, confirm_no)
	_set_neighbors(confirm_no, confirm_no, confirm_no, confirm_yes, confirm_no)
	confirm_yes.focus_next = confirm_yes.get_path_to(confirm_no)
	confirm_yes.focus_previous = confirm_yes.get_path_to(confirm_no)
	confirm_no.focus_next = confirm_no.get_path_to(confirm_yes)
	confirm_no.focus_previous = confirm_no.get_path_to(confirm_yes)
	confirm_no.grab_focus()


## Confirmed: refunds everything and closes the dialog.
func _confirm_refund() -> void:
	_close_confirm()
	refund_all()


## Closes the confirmation and focuses Refund all again.
func _close_confirm() -> void:
	if _confirm == null:
		return
	_confirm.queue_free()
	_confirm = null
	confirm_yes = null
	confirm_no = null
	refund_button.grab_focus()


## Restores focus to the opener and frees the menu.
func close() -> void:
	if UiMotion.is_closing(self):
		return
	closed.emit()
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	UiMotion.close(self, queue_free)  # Quick fade out, then freed.


## Esc / controller B: closes the confirmation first, then the menu.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _confirm != null:
			_close_confirm()
		else:
			close()
