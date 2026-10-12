## OssuaryMenu — the Soul Ash upgrade shop (GDD §10.1 "Upgrades", §9.2 four
## upgrade trees), opened from the main menu. Four columns (Necromancy,
## Shadowcraft, Survival, Fortune); each upgrade is one button showing its
## code-drawn icon with tier pips, name and tier, the effect delta
## ("Minion HP +6% -> +12%") and its cost / locked / maxed state. Pressing an
## upgrade buys its next tier through the Meta autoload (which saves at once).
## "Refund all" (respec) asks for confirmation first, then returns every
## spent Soul Ash.
## Fully usable with keyboard and controller: explicit focus neighbours make
## the upgrade buttons a grid (up / down inside a tree, left / right across
## trees at the same row, down from the last row to Refund all / Back), A /
## Enter buys, B / Esc closes the confirmation or the menu. The first upgrade
## is focused on open.
## The standalone Profane Oath (opt-in difficulty, MetaData "oath") sits in
## the bottom row between Refund all and Back: its button buys the next tier
## (or raises the active tier again for free when it was lowered), and
## "Lower Oath" asks for confirmation, then lowers the ACTIVE tier by one
## (down to off) with no refund (owned tiers stay owned, Meta.set_oath_active).
## Open it with OssuaryMenu.open_over(parent, button_to_refocus).
class_name OssuaryMenu
extends Control

## Emitted when the menu is about to be freed.
signal closed

## Size (px) of one upgrade button.
const BUTTON_SIZE := Vector2(280, 72)
## Gap (px) between tree columns.
const COLUMN_GAP: int = 14
## Gap (px) between upgrade buttons in a column.
const ROW_GAP: int = 5
## Size (px) of the icon on an upgrade button (includes the pip row).
const ICON_SIZE := Vector2(44, 52)
## Button height (px) and row gap (px) used instead of BUTTON_SIZE.y /
## ROW_GAP when a tree holds more than COMPACT_ROWS upgrades (Necromancy
## with the Spearhead stance unlock), so the screen still fits 720 px.
const COMPACT_BUTTON_HEIGHT: float = 62.0
## Row gap (px) of the compact layout.
const COMPACT_ROW_GAP: int = 3
## Upgrades per tree above which the compact layout is used.
const COMPACT_ROWS: int = 5
## Roman numerals for tier names in prerequisite text.
const ROMAN := ["0", "I", "II", "III", "IV", "V", "VI"]

## Control focused again when the menu closes (may be null).
var return_focus: Control = null
## Upgrade id -> its Button.
var buttons: Dictionary = {}
## Upgrade id -> {"icon": IconGlyph, "name": Label, "effect": Label, "cost": Label}.
var _parts: Dictionary = {}
## Buttons per tree column, in MetaData.TREE_ORDER (focus grid).
var _grid: Array = []
## "Refund all" button.
var refund_button: Button
## "Back" button.
var back_button: Button
## Soul Ash balance label.
var _ash_label: Label
## "Invested" label (ash currently spent on upgrades).
var _spent_label: Label
## Achievement progress line (GDD §9.4).
var _achievements: Label
## Description of the focused upgrade.
var _detail: Label
## Feedback line (purchase result, refund result).
var _status: Label
## Refund confirmation overlay (null while closed).
var _confirm: Control = null
## Confirmation "Refund" button (valid while _confirm is open).
var confirm_yes: Button = null
## Confirmation "Cancel" button (valid while _confirm is open).
var confirm_no: Button = null
## Profane Oath upgrade button (bottom row).
var oath_button: Button
## "Lower Oath" button: lowers / disables the active Oath tier (asks first).
var oath_lower_button: Button
## Button focused again when the confirmation closes.
var _confirm_return: Button = null


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
	var panel := PanelContainer.new()
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)
	root.add_child(_build_header())
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", COLUMN_GAP)
	root.add_child(cols)
	for tree_id: String in MetaData.TREE_ORDER:
		cols.add_child(_build_column(tree_id))
	_achievements = UiTheme.label("", 12, UiTheme.TEXT_DIM)
	root.add_child(_achievements)
	_detail = UiTheme.label("", 14, UiTheme.TEXT)
	_detail.custom_minimum_size = Vector2(0, 20)
	root.add_child(_detail)
	_status = UiTheme.label("", 14, UiTheme.TEXT_GOLD)
	_status.custom_minimum_size = Vector2(0, 20)
	root.add_child(_status)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 18)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(bottom)
	refund_button = _plain_button(bottom, "", _open_confirm)
	refund_button.focus_entered.connect(func() -> void: _detail.text = "Respec: refund every upgrade and get all spent Soul Ash back (asks first).")
	oath_button = _upgrade_button(PactData.OATH_ID)
	bottom.add_child(oath_button)
	oath_lower_button = _plain_button(bottom, "", _open_lower_confirm)
	oath_lower_button.custom_minimum_size = Vector2(170, 42)
	oath_lower_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	oath_lower_button.focus_entered.connect(func() -> void: _detail.text = "Lower the active Profane Oath by one tier (to off). No refund; owned tiers can be raised again for free.")
	back_button = _plain_button(bottom, "Back", close)
	refund_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_button.focus_entered.connect(func() -> void: _detail.text = "Return to the main menu. Purchases are already saved.")
	_wire_focus()
	Meta.changed.connect(_refresh)
	_refresh()
	var first: Button = _grid[0][0]
	first.grab_focus.call_deferred()


## Title, subtitle and the Soul Ash balance.
func _build_header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	titles.add_child(UiTheme.label("THE OSSUARY", 30, UiTheme.TEXT_GOLD))
	titles.add_child(UiTheme.label("Spend Soul Ash on permanent upgrades. Ash is earned every run and kept even in death.", 13, UiTheme.TEXT_DIM))
	row.add_child(titles)
	row.add_child(IconGlyph.new("soul_ash", Vector2(40, 40)))
	var ash_box := VBoxContainer.new()
	ash_box.add_theme_constant_override("separation", 0)
	_ash_label = UiTheme.label("", 22, MetaGlyphs.EMBER.lightened(0.2))
	_ash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ash_box.add_child(_ash_label)
	_spent_label = UiTheme.label("", 13, UiTheme.TEXT_DIM)
	_spent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ash_box.add_child(_spent_label)
	row.add_child(ash_box)
	return row


## One tree column: header plus one button per upgrade.
func _build_column(tree_id: String) -> Control:
	var def: Dictionary = MetaData.TREES[tree_id]
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", COMPACT_ROW_GAP if _compact() else ROW_GAP)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(IconGlyph.new(String(def["icon"]), Vector2(36, 36)))
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.add_child(UiTheme.label(String(def["display_name"]), 18, def["color"]))
	names.add_child(UiTheme.label(String(def["improves"]), 12, UiTheme.TEXT_DIM))
	head.add_child(names)
	vb.add_child(head)
	var column: Array[Button] = []
	for id: String in MetaData.upgrades_in(tree_id):
		var b := _upgrade_button(id)
		vb.add_child(b)
		column.append(b)
	_grid.append(column)
	return vb


## True when the tallest tree has more than COMPACT_ROWS upgrades.
static func _compact() -> bool:
	for tree_id: String in MetaData.TREE_ORDER:
		if MetaData.upgrades_in(tree_id).size() > COMPACT_ROWS:
			return true
	return false


## Builds the button of upgrade `id` (contents are filled by _refresh()).
func _upgrade_button(id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(BUTTON_SIZE.x, COMPACT_BUTTON_HEIGHT) if _compact() else BUTTON_SIZE
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(_on_upgrade_pressed.bind(id))
	b.focus_entered.connect(_show_detail.bind(id))
	b.mouse_entered.connect(_show_detail.bind(id))
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_right = -8
	row.offset_top = 4
	row.offset_bottom = -4
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	var icon := IconGlyph.new(String(MetaData.UPGRADES[id]["icon"]), ICON_SIZE)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(texts)
	var name_label := UiTheme.label("", 14)
	var effect := UiTheme.label("", 13, UiTheme.TEXT_GOOD)
	var cost := UiTheme.label("", 13)
	for l: Label in [name_label, effect, cost]:
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		texts.add_child(l)
	buttons[id] = b
	_parts[id] = {"icon": icon, "name": name_label, "effect": effect, "cost": cost}
	return b


## Adds a bottom-row button calling `cb`.
func _plain_button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 42)
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
			var bottom_row: Array[Control] = [refund_button, oath_button, oath_lower_button, back_button]  # Bottom row, left to right.
			var down: Control = col[r + 1] if r < col.size() - 1 else bottom_row[mini(c, bottom_row.size() - 1)]
			var left_col: Array = _grid[c - 1] if c > 0 else col
			var right_col: Array = _grid[c + 1] if c < n_cols - 1 else col
			var left: Control = left_col[mini(r, left_col.size() - 1)]
			var right: Control = right_col[mini(r, right_col.size() - 1)]
			_set_neighbors(b, up, down, left, right)
			b.focus_previous = b.get_path_to(left)
			b.focus_next = b.get_path_to(right)
	var first_col: Array = _grid[0]
	var last_col: Array = _grid[n_cols - 1]
	var col2: Array = _grid[mini(1, n_cols - 1)]  # Column above the Oath button.
	var col3: Array = _grid[mini(2, n_cols - 1)]  # Column above the Lower button.
	_set_neighbors(refund_button, first_col[first_col.size() - 1], refund_button, refund_button, oath_button)
	_set_neighbors(oath_button, col2[col2.size() - 1], oath_button, refund_button, oath_lower_button)
	_set_neighbors(oath_lower_button, col3[col3.size() - 1], oath_lower_button, oath_button, back_button)
	_set_neighbors(back_button, last_col[last_col.size() - 1], back_button, oath_lower_button, back_button)


## Sets the four focus neighbours of `b`.
func _set_neighbors(b: Control, up: Control, down: Control, left: Control, right: Control) -> void:
	b.focus_neighbor_top = b.get_path_to(up)
	b.focus_neighbor_bottom = b.get_path_to(down)
	b.focus_neighbor_left = b.get_path_to(left)
	b.focus_neighbor_right = b.get_path_to(right)


# =====================================================================================
# Display
# =====================================================================================

## Refreshes the balance, every upgrade button and the refund button.
func _refresh() -> void:
	_ash_label.text = "%d Soul Ash" % Meta.soul_ash
	_spent_label.text = "Invested: %d / %d" % [Meta.spent_total(), MetaData.max_total_cost()]
	for id: String in MetaData.UPGRADE_ORDER:
		_refresh_upgrade(id)
	var ach := PackedStringArray()
	for aid: String in MetaData.ACHIEVEMENT_ORDER:
		var a: Dictionary = MetaData.ACHIEVEMENTS[aid]
		var done := Meta.achievements.has(aid)
		var prog := mini(int(Meta.achievement_progress(aid)), int(a["goal"]))
		ach.append("%s %s (%s)" % ["[x]" if done else "[ ]", a["display_name"], "done" if done else "%d/%d" % [prog, int(a["goal"])]])
	_achievements.text = "Achievements:  " + "    ".join(ach)
	refund_button.text = "Refund all  (+%d)" % Meta.spent_total()
	refund_button.disabled = Meta.spent_total() <= 0
	var active := Meta.oath_active_tier()  # Active Profane Oath tier.
	oath_lower_button.text = "Lower Oath  (%s)" % DifficultyModifiers.roman(active) if active > 0 else "Oath is off"
	oath_lower_button.disabled = active <= 0
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	for id: String in buttons:
		if buttons[id] == focused:
			_show_detail(id)


## Updates one upgrade button: icon pips, name / tier, effect delta, cost
## line and a border colour for its state (affordable green, maxed gold,
## locked dark, too expensive default).
func _refresh_upgrade(id: String) -> void:
	var def: Dictionary = MetaData.UPGRADES[id]
	var p: Dictionary = _parts[id]
	var t := Meta.tier(id)
	var mx := MetaData.max_tier(id)
	(p["icon"] as IconGlyph).set_icon(String(def["icon"]), t, mx)
	var name_label: Label = p["name"]
	name_label.text = "%s  %d/%d" % [def["display_name"], t, mx]
	(p["effect"] as Label).text = effect_text(id)
	var cost: Label = p["cost"]
	var block := Meta.purchase_block(id)
	var border := UiTheme.BORDER
	match block:
		"maxed":
			cost.text = "MAXED"
			cost.add_theme_color_override("font_color", UiTheme.TEXT_GOLD)
			name_label.add_theme_color_override("font_color", UiTheme.TEXT_GOLD)
			border = Palette.GOLD.darkened(0.15)
		"locked":
			var req: Dictionary = def["requires"]
			cost.text = "Needs %s %s" % [MetaData.UPGRADES[req["id"]]["display_name"], ROMAN[int(req["tier"])]]
			cost.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.35))
			name_label.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
			border = UiTheme.BORDER.darkened(0.55)
		"cost":
			cost.text = "Cost %d  (need %d more)" % [Meta.next_cost(id), Meta.next_cost(id) - Meta.soul_ash]
			cost.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
			name_label.add_theme_color_override("font_color", UiTheme.TEXT)
		_:
			cost.text = "Cost %d  -  buy" % Meta.next_cost(id)
			cost.add_theme_color_override("font_color", UiTheme.TEXT_GOOD)
			name_label.add_theme_color_override("font_color", UiTheme.TEXT)
			border = Palette.NECRO_GREEN.darkened(0.2)
	if id == PactData.OATH_ID:
		border = _refresh_oath(p, border)
	var b: Button = buttons[id]
	b.add_theme_stylebox_override("normal", UiTheme.box(UiTheme.BG, border))
	b.add_theme_stylebox_override("hover", UiTheme.box(UiTheme.BG_HOVER, border))


## Profane Oath button extras: the name shows the ACTIVE / owned tiers and,
## when the active tier was lowered, the cost line offers the free raise.
## Returns the border colour to use.
func _refresh_oath(p: Dictionary, border: Color) -> Color:
	var owned := Meta.tier(PactData.OATH_ID)  # Tiers bought.
	var active := Meta.oath_active_tier()  # Tier applied to runs.
	var name_label: Label = p["name"]  # "Profane Oath III (owned 3/5)".
	name_label.text = "Profane Oath  %s (owned %d/%d)" % [DifficultyModifiers.roman(active) if active > 0 else "off", owned, MetaData.max_tier(PactData.OATH_ID)]
	if active < owned:
		var cost: Label = p["cost"]  # Cost / action line.
		cost.text = "Raise to %s  -  free (owned)" % DifficultyModifiers.roman(active + 1)
		cost.add_theme_color_override("font_color", UiTheme.TEXT_GOOD)
		return Palette.CRIMSON.darkened(0.1)
	return Palette.CRIMSON.darkened(0.1) if owned > 0 else border


## Oath effect line: "Foes +16% -> +24% HP, Ash +20% -> +30%" for the next
## active tier (or the current values at the top tier).
static func _oath_effect_text() -> String:
	var t := Meta.oath_active_tier()  # Active tier now.
	var per: Dictionary = PactData.OATH_PER_TIER  # Bonus per tier.
	var hp := float(per["enemy_hp"])  # HP penalty per tier.
	var ash := float(per["ash_gain"])  # Soul Ash reward per tier.
	if t >= MetaData.max_tier(PactData.OATH_ID):
		return "Foes HP +%d%%, Ash +%d%% (max)" % [int(roundf(hp * t * 100.0)), int(roundf(ash * t * 100.0))]
	return "Foes HP +%d%% -> +%d%%, Ash +%d%% -> +%d%%" % [int(roundf(hp * t * 100.0)), int(roundf(hp * (t + 1) * 100.0)),
		int(roundf(ash * t * 100.0)), int(roundf(ash * (t + 1) * 100.0))]


## "Label old -> new" for the next tier (or "Label value (max)").
static func effect_text(id: String) -> String:
	if id == PactData.OATH_ID:
		return _oath_effect_text()
	var def: Dictionary = MetaData.UPGRADES[id]
	var stat_def: Array = MetaData.STATS[String(def["stat"])]
	var per := float(def["per_tier"])
	var t := Meta.tier(id)
	if t >= MetaData.max_tier(id):
		return "%s %s (max)" % [stat_def[0], format_stat(per * float(t), String(stat_def[1]))]
	return "%s %s -> %s" % [stat_def[0], format_stat(per * float(t), String(stat_def[1])), format_stat(per * float(t + 1), String(stat_def[1]))]


## Formats a modifier value per its MetaData.STATS format.
static func format_stat(v: float, fmt: String) -> String:
	match fmt:
		"pct":
			return "+%d%%" % int(roundf(v * 100.0))
		"neg_pct":
			return "-%d%%" % int(roundf(v * 100.0))
		"unlock":
			return "unlocked" if v >= 1.0 else "locked"
	return "+%d" % int(roundf(v))


## Shows the description line of upgrade `id`.
func _show_detail(id: String) -> void:
	var def: Dictionary = MetaData.UPGRADES[id]
	var tree_name: String = MetaData.TREES[String(def["tree"])]["display_name"]
	_detail.text = "%s (%s): %s" % [def["display_name"], tree_name, def["description"]]
	if id == PactData.OATH_ID:
		var parts := PackedStringArray()  # "spawn +8%" per key, per tier.
		for key: String in PactData.KEYS:
			parts.append("%s +%d%%" % [PactData.SHORT[key], int(roundf(float(PactData.OATH_PER_TIER[key]) * 100.0))])
		_detail.text = "Profane Oath (opt-in difficulty), per tier: %s. Stacks with the in-run Profane Pact." % ", ".join(parts)


# =====================================================================================
# Actions
# =====================================================================================

## Buys the next tier of `id`, or explains why it cannot be bought.
func _on_upgrade_pressed(id: String) -> void:
	var display_name: String = MetaData.UPGRADES[id]["display_name"]
	if id == PactData.OATH_ID and Meta.oath_active_tier() < Meta.tier(id):
		# A lowered Oath goes back up for free (the tier is still owned).
		Meta.set_oath_active(Meta.oath_active_tier() + 1)
		Sfx.play("ui_confirm")
		_set_status("Profane Oath raised to %s (no cost: already owned)." % DifficultyModifiers.roman(Meta.oath_active_tier()), Palette.CRIMSON.lightened(0.4))
		return
	match Meta.purchase_block(id):
		"maxed":
			_set_status("%s is already at its highest tier." % display_name, UiTheme.TEXT_GOLD)
		"locked":
			_set_status("%s is locked. Buy its prerequisite first." % display_name, Palette.CRIMSON.lightened(0.35))
		"cost":
			_set_status("Not enough Soul Ash for %s (%d more needed)." % [display_name, Meta.next_cost(id) - Meta.soul_ash], Palette.CRIMSON.lightened(0.35))
		_:
			var cost := Meta.next_cost(id)
			if Meta.purchase(id):
				Sfx.play("ui_confirm")
				_set_status("Bought %s %s for %d Soul Ash." % [display_name, ROMAN[Meta.tier(id)], cost], UiTheme.TEXT_GOOD)


## Sets the feedback line.
func _set_status(text: String, col: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", col)


## True while the refund confirmation is shown.
func confirm_open() -> bool:
	return _confirm != null


## Shows the "Refund all?" confirmation with Cancel focused.
func _open_confirm() -> void:
	if _confirm != null or Meta.spent_total() <= 0:
		return
	_open_dialog("REFUND ALL UPGRADES?", "Every upgrade returns to tier 0 and you get back\n%d Soul Ash to spend again." % Meta.spent_total(),
		"Refund", _confirm_refund, refund_button)


## Shows the "Lower the Oath?" confirmation with Cancel focused.
func _open_lower_confirm() -> void:
	var active := Meta.oath_active_tier()  # Tier before lowering.
	if _confirm != null or active <= 0:
		return
	var to := "off" if active == 1 else "tier %s" % DifficultyModifiers.roman(active - 1)  # Target state text.
	_open_dialog("LOWER THE PROFANE OATH?", "The Oath drops from tier %s to %s for future runs.\nNo Soul Ash is refunded; owned tiers can be raised again for free." % [DifficultyModifiers.roman(active), to],
		"Lower", _confirm_lower, oath_lower_button)


## Confirmed: lowers the active Oath tier by one and closes the dialog.
func _confirm_lower() -> void:
	Meta.set_oath_active(Meta.oath_active_tier() - 1)
	_close_confirm()
	Sfx.play("ui_confirm")
	var active := Meta.oath_active_tier()  # Tier after lowering.
	_set_status("Profane Oath is now %s." % ("off" if active <= 0 else "tier %s" % DifficultyModifiers.roman(active)), UiTheme.TEXT_GOLD)


## Builds a two-button confirmation dialog (Cancel focused). `yes_cb` runs on
## the confirm button; `return_to` regains focus when it closes.
func _open_dialog(title_text: String, body: String, yes_text: String, yes_cb: Callable, return_to: Button) -> void:
	_confirm_return = return_to
	_confirm = Control.new()
	_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm.add_child(UiTheme.backdrop(0.6))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(420, 0)
	panel.add_child(vb)
	var title := UiTheme.label(title_text, 22, UiTheme.TEXT_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var text := UiTheme.label(body, 15)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	confirm_yes = _plain_button(row, yes_text, yes_cb)
	confirm_yes.custom_minimum_size = Vector2(170, 42)
	confirm_no = _plain_button(row, "Cancel", _close_confirm)
	confirm_no.custom_minimum_size = Vector2(170, 42)
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
	var refunded := Meta.refund_all()
	_close_confirm()
	Sfx.play("ui_confirm")
	_set_status("Refunded %d Soul Ash. Every tree is reset." % refunded, UiTheme.TEXT_GOLD)


## Closes the confirmation and focuses Refund all (or Back if now disabled).
func _close_confirm() -> void:
	if _confirm == null:
		return
	_confirm.queue_free()
	_confirm = null
	confirm_yes = null
	confirm_no = null
	if _confirm_return != null and not _confirm_return.disabled:
		_confirm_return.grab_focus()
	else:
		back_button.grab_focus()


## Restores focus to the opener and frees the menu.
func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	queue_free()


## Esc / controller B: closes the confirmation first, then the menu.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _confirm != null:
			_close_confirm()
		else:
			close()
