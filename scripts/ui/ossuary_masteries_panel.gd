## OssuaryMasteriesPanel — the Masteries tab of the Ossuary (Ossuary expansion
## step 4, owner decision "Masteries for summon classes only", GDD §15.0 "Ossuary
## Masteries"). The tab bar (agent A) loads this script by path and shows it under
## the Soul Ash balance; the contract is `refresh()` and the `changed` signal.
##   * a grid of 17 class tiles (MasteryTile: class icon, name, three level pips,
##     next price), four columns like the four trees;
##   * a tile whose class has not reached level 5 in a run is dimmed with a
##     padlock and the word "Lv 5"; the detail strip below says "Take <class> to
##     level 5 in a run" (Meta.is_mastery_open());
##   * ONE ornate detail strip that follows the focused / hovered tile: icon, name,
##     pips, the class's flavour line, HP and Damage current -> next, the price
##     with the Soul Ash symbol (or the unlock hint / "Maxed") and a Buy chip.
## Pressing / Enter / A on an affordable tile buys its next level through
## Meta.buy_mastery() (saves at once) with the `purchase` sound and a flash; a
## locked, too expensive or maxed tile answers `denied` with a shake. On a
## touchscreen (no hover) the first tap shows the details and a second tap on the
## same tile buys. Keyboard / pad navigation is a grid by explicit focus
## neighbours. Prices and values come from MasteryData, wording and layout from
## MasteryUiData / OssuaryUiData. It never changes a stat itself: the bonus
## reaches summons through MetaModifiers (one stat path).
class_name OssuaryMasteriesPanel
extends VBoxContainer

## Emitted after a purchase (the tab bar updates the Soul Ash balance).
signal changed

## Class id -> its MasteryTile.
var tiles: Dictionary = {}
## Soul Ash spent by the last purchase (the tab bar may float "-N"); 0 before any.
var last_spent: int = 0
## Tiles in grid order (MasteryData.CLASSES), row-major.
var _order: Array[MasteryTile] = []
## Class id shown in the detail strip ("" = none yet).
var _focus_cls: String = ""
## Touch input only: the class tile tapped once (details shown); a second tap on
## it buys ("" = none). Keys, pads and mice buy at once.
var _touch_armed: String = ""
## Detail strip (ornate PanelContainer; its accent follows the state).
var _detail_panel: PanelContainer
## Detail strip parts: "icon" IconGlyph, "name" Label, "pips" Pips, "desc" Label,
## "stat" / "cur" / "arrow" / "next" (HP), "stat2" / "cur2" / "arrow2" / "next2"
## (Damage), "cost_icon" IconGlyph, "cost" Label, "hint" input hint, "hint_word" Label.
var _d: Dictionary = {}


func _ready() -> void:
	add_theme_constant_override("separation", MasteryUiData.DETAIL_GAP)
	var grid := GridContainer.new()
	grid.columns = MasteryUiData.COLUMNS
	grid.add_theme_constant_override("h_separation", OssuaryUiData.COLUMN_GAP)
	grid.add_theme_constant_override("v_separation", OssuaryUiData.ROW_GAP)
	add_child(grid)
	for cls: String in MasteryData.CLASSES:
		var t := MasteryTile.new(cls)
		t.pressed.connect(_on_pressed.bind(cls))
		t.focus_entered.connect(_show_detail.bind(cls))
		t.mouse_entered.connect(_show_detail.bind(cls))
		grid.add_child(t)
		tiles[cls] = t
		_order.append(t)
	add_child(_build_detail())
	_wire_focus()
	Meta.changed.connect(refresh)
	refresh()
	_show_detail(MasteryData.CLASSES[0])


## Updates every tile and the detail strip from Meta (the tab bar calls it when
## the tab opens; a purchase elsewhere calls it through Meta.changed).
func refresh() -> void:
	if _order.is_empty():
		return
	for cls: String in tiles:
		_refresh_tile(cls)
	if _focus_cls != "":
		_show_detail(_focus_cls)


## Gives the first tile focus (the tab bar calls it when it hands focus down).
func focus_first() -> void:
	_order[0].grab_focus()


## The first row of tiles (the tab bar wires their "up" focus to its tabs).
func first_row() -> Array[MasteryTile]:
	var row: Array[MasteryTile] = []
	for i in mini(MasteryUiData.COLUMNS, _order.size()):
		row.append(_order[i])
	return row


## The ornate detail strip (contents filled by _show_detail()).
func _build_detail() -> Control:
	_detail_panel = UiTheme.ornate_panel("violet")
	_detail_panel.custom_minimum_size = Vector2(
		OssuaryUiData.TILE_SIZE.x * float(MasteryUiData.COLUMNS) + float(OssuaryUiData.COLUMN_GAP) * float(MasteryUiData.COLUMNS - 1),
		MasteryUiData.DETAIL_HEIGHT)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	_detail_panel.add_child(hb)
	var icon := IconGlyph.new("", Vector2(OssuaryUiData.DETAIL_ICON, OssuaryUiData.DETAIL_ICON))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(icon)
	_d["icon"] = icon
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	desc.custom_minimum_size.x = 600.0  # The strip's width decides; this only stops a long line widening it.
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(desc)
	_d["desc"] = desc
	var vals := HBoxContainer.new()  # Two values, spacer, price, Buy chip.
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
			var gap := Control.new()  # Between the two value groups.
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
	var hint := InputHints.hint("ui_accept", MasteryUiData.BUY)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vals.add_child(hint)
	_d["hint"] = hint
	_d["hint_word"] = hint.get_child(hint.get_child_count() - 1)
	return _detail_panel


## Explicit focus neighbours so D-pad / stick / arrow navigation is a grid. The
## last row is short: a move into a missing cell stays on the tile.
func _wire_focus() -> void:
	var cols := MasteryUiData.COLUMNS
	var n := _order.size()
	for i in n:
		var b := _order[i]
		var up := _order[i - cols] if i >= cols else b
		var down := _order[i + cols] if i + cols < n else b
		var left := _order[i - 1] if i % cols > 0 else b
		var right := _order[i + 1] if i % cols < cols - 1 and i + 1 < n else b
		b.focus_neighbor_top = b.get_path_to(up)
		b.focus_neighbor_bottom = b.get_path_to(down)
		b.focus_neighbor_left = b.get_path_to(left)
		b.focus_neighbor_right = b.get_path_to(right)
		b.focus_previous = b.get_path_to(_order[(i - 1 + n) % n])
		b.focus_next = b.get_path_to(_order[(i + 1) % n])


# =====================================================================================
# Display
# =====================================================================================

## The display state of class `cls`: "buy", "cost", "maxed" or "locked"
## (Meta.mastery_block()).
static func state_of(cls: String) -> String:
	var block := Meta.mastery_block(cls)
	return "buy" if block == "" else block


## Updates one tile from Meta.
func _refresh_tile(cls: String) -> void:
	var state := state_of(cls)
	var cost := Meta.mastery_cost(cls) if state != "maxed" else 0
	(tiles[cls] as MasteryTile).show_state(state, Meta.mastery_level(cls), cost)


## "+4%" style value (fraction -> whole percent).
static func format_pct(v: float) -> String:
	return "+%d%%" % int(roundf(v * 100.0))


## Shows class `cls` in the detail strip: icon, name, pips, flavour line, HP and
## Damage current -> next, the price (or the unlock hint / "Maxed") and the Buy chip.
func _show_detail(cls: String) -> void:
	_focus_cls = cls
	var state := state_of(cls)
	var lv := Meta.mastery_level(cls)
	var mx := MasteryData.MAX_LEVEL
	var icon: IconGlyph = _d["icon"]
	icon.set_icon(cls)
	icon.modulate = OssuaryUiData.LOCKED_ICON_TINT if state == "locked" else Color.WHITE
	var name_label: Label = _d["name"]
	name_label.text = String(UnitData.UNITS[cls]["display_name"])
	var accent := "violet"  # Detail strip frame accent.
	var name_col := UiTheme.TEXT
	match state:
		"maxed":
			accent = "gold"
			name_col = UiTheme.TEXT_GOLD
		"locked":
			name_col = UiTheme.TEXT_DIM
	name_label.add_theme_color_override("font_color", name_col)
	_detail_panel.add_theme_stylebox_override("panel", UiTheme.style("ornate", accent))
	(_d["pips"] as PixelMarks.Pips).set_pips(mx, lv, OssuaryUiData.PIP_MAXED if state == "maxed" else OssuaryUiData.PIP_OWNED)
	(_d["desc"] as Label).text = String(MasteryData.FLAVOUR.get(cls, ""))
	var top := lv >= mx  # No next level.
	_set_value("", MasteryUiData.HP_LABEL, format_pct(MasteryData.hp_bonus(lv)), "" if top else format_pct(MasteryData.hp_bonus(lv + 1)))
	_set_value("2", MasteryUiData.DAMAGE_LABEL, format_pct(MasteryData.damage_bonus(lv)), "" if top else format_pct(MasteryData.damage_bonus(lv + 1)))
	_show_cost(cls, state)


## Fills value group `suffix` ("" or "2"): `stat` label, `cur` value, and `nxt`
## after the arrow (no arrow / next when empty: maxed).
func _set_value(suffix: String, stat: String, cur: String, nxt: String) -> void:
	(_d["stat" + suffix] as Label).text = stat
	(_d["cur" + suffix] as Label).text = cur
	(_d["arrow" + suffix] as Control).visible = nxt != ""
	(_d["next" + suffix] as Label).text = nxt
	(_d["next" + suffix] as Label).visible = nxt != ""


## The price corner of the detail strip for class `cls` in `state`.
func _show_cost(cls: String, state: String) -> void:
	var cost: Label = _d["cost"]
	var icon: IconGlyph = _d["cost_icon"]
	var hint: Control = _d["hint"]
	icon.visible = true
	hint.visible = false
	cost.add_theme_color_override("font_color", OssuaryUiData.ASH_COLOR)
	UiTheme.set_tier(cost, UiTheme.Tier.NAME)
	match state:
		"maxed":
			icon.visible = false
			cost.text = MasteryUiData.MAXED
			cost.add_theme_color_override("font_color", UiTheme.TEXT_GOLD)
		"locked":
			# One BODY line naming what opens it, so it fits beside the values.
			icon.visible = false
			cost.text = MasteryUiData.LOCKED_LINE % String(UnitData.UNITS[cls]["display_name"])
			UiTheme.set_tier(cost, UiTheme.Tier.BODY)
			cost.add_theme_color_override("font_color", OssuaryUiData.DENIED)
		"cost":
			cost.text = str(Meta.mastery_cost(cls))
			cost.add_theme_color_override("font_color", OssuaryUiData.COST_SHORT)
		_:
			cost.text = str(Meta.mastery_cost(cls))
			hint.visible = true


# =====================================================================================
# Actions
# =====================================================================================

## Buys the next level of `cls`, or answers `denied` with a shake when it cannot
## be bought (locked, too expensive or maxed). On touch the first tap only shows.
func _on_pressed(cls: String) -> void:
	var tile: MasteryTile = tiles[cls]
	if InputHints.device() == InputHints.Device.TOUCH and _touch_armed != cls:
		# A finger has no hover: the first tap on a tile shows its details,
		# a second tap on the same tile buys (GDD §15.0 "Mobile browser support").
		_touch_armed = cls
		_show_detail(cls)
		Sfx.play_ui("ui_tick")
		return
	if Meta.mastery_block(cls) != "":
		Sfx.play_ui("denied")
		tile.shake()
		_flash_cost()
		return
	var price := Meta.mastery_cost(cls)
	if Meta.buy_mastery(cls):  # Emits Meta.changed: refresh() runs.
		last_spent = price
		Sfx.play_ui("purchase")
		tile.flash()
		changed.emit()


## The detail strip's price blinks red (a denied press).
func _flash_cost() -> void:
	var cost: Label = _d["cost"]
	if not UiMotion.enabled():
		return
	cost.modulate = Color(1.6, 0.6, 0.6)
	var tw := cost.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(cost, "modulate", Color.WHITE, MasteryUiData.SHAKE_TIME)
