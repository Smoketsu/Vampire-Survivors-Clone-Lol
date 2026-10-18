## CodexScreen — the Achievements + Codex screen (GDD §10.1 "Collection /
## Codex" and "Achievements"; GDD §15.0 "Codex and achievements screen"),
## opened from the main menu with CodexScreen.open_over(parent). An ornate
## violet panel with four tabs (CodexData.TABS):
##   * Achievements: every MetaData achievement and every feat (the lifetime
##     counter skin unlocks, the Hyper unlock, the Hyper skins) as a
##     CodexFeatRow: badge, goal, progress bar, reward; earned rows are gold.
##     Read-only: how they are earned is unchanged (Meta.award_run()).
##   * Spells, Summons, Covenant: a grid of tiles per section (CodexData.SECTIONS)
##     on the left (CodexArt: the icon badge or a 1x sprite bust; the bosses
##     get big tiles) and a detail panel on the right for the focused /
##     hovered tile: the big art at a whole scale, name, tag, one-line
##     description, a few stats and a lifetime record. Entries the player has
##     not met yet (CodexLog / Meta [codex]) are silhouettes named "Unknown";
##     evolutions follow the owner's recipe rule: until obtained (Meta
##     [recipes]) they are a "?" with no name, art or description.
## Controls: the tab buttons, Q / E or LB / RB switch tabs (focus goes to
## the new tab's button); explicit focus links make each page a grid (Up
## from the top row reaches the tabs, Down from a tab enters its page); Esc /
## pad B or Back close the screen and focus returns to the opener. Every
## number lives in CodexData; text sizes are the UiTheme type tiers. Opens and
## closes with UiMotion; the tiles enter with a short stagger. Under the
## autotest nothing opens it. On a touchscreen a tap shows a tile's details
## and a finger drags the lists (TouchSupport.pass_drags()).
class_name CodexScreen
extends Control

## Emitted when the screen is about to be freed.
signal closed

## Control focused again when the screen closes (may be null).
var return_focus: Control = null
## Tab id -> its tab Button.
var tab_buttons: Dictionary = {}
## Tab id -> its page Control (one visible at a time).
var _pages: Dictionary = {}
## Tab id -> the Button that takes the focus when entering its page.
var _first: Dictionary = {}
## Tab id -> Array of every focusable item on its page (stagger, settle).
var _items: Dictionary = {}
## Tab id -> its detail panel parts {"art", "name", "tag", "desc", "stats", "record"} (codex pages).
var _details: Dictionary = {}
## Tab id -> its focus grid (Array of rows, each an Array of Buttons), wired
## once every page is in the tree.
var _rows: Dictionary = {}
## Tab id -> its ScrollContainer.
var _scrolls: Dictionary = {}
## Tab id -> its recorded / total count text.
var _counts: Dictionary = {}
## Id of the tab shown.
var current: String = ""
## The Back button.
var back_button: Button
## Count line under the title (recorded / earned of the current tab).
var _count_label: Label


## Creates the screen as a full-screen child of `parent` and returns it.
## The control focused at that moment regains focus when it closes.
static func open_over(parent: Control) -> CodexScreen:
	var s := CodexScreen.new()
	var vp := parent.get_viewport()  # Null when the parent is not in the tree.
	s.return_focus = vp.gui_get_focus_owner() if vp != null else null
	parent.add_child(s)
	return s


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiTheme.get_theme()
	add_child(UiTheme.backdrop(CodexData.BACKDROP_ALPHA))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit (no-op at 720 px).
	var panel := UiTheme.ornate_panel("violet")
	panel.custom_minimum_size = CodexData.PANEL_SIZE
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	vb.add_child(_header())
	vb.add_child(UiTheme.divider())
	var stack := Control.new()  # The pages, one visible.
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(stack)
	stack.add_child(_feats_page())
	var pages := CodexEntries.pages()  # Page id -> sections.
	for t: Array in CodexData.TABS:
		var id := String(t[0])
		if pages.has(id):
			stack.add_child(_codex_page(id, pages[id]))
	add_child(InputHints.bottom_strip([[[InputHints.raw(KEY_Q, JOY_BUTTON_LEFT_SHOULDER), InputHints.raw(KEY_E, JOY_BUTTON_RIGHT_SHOULDER)], "Tab"],
		["ui_cancel", "Back"]]))
	_wire_tabs()
	for id: String in _rows:  # Focus links need every node in the tree (get_path_to).
		_wire_grid(id, _rows[id], id != String(CodexData.TABS[0][0]))
	show_tab(String(CodexData.TABS[0][0]), false)
	(tab_buttons[current] as Button).grab_focus.call_deferred()
	UiMotion.open(self)


# =====================================================================================
# Header and tabs
# =====================================================================================

## Title and count on the left, the tab buttons and Back on the right.
func _header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", -4)
	titles.add_child(UiTheme.tier_label(CodexData.TITLE, UiTheme.Tier.TITLE, UiTheme.TEXT_GOLD))
	_count_label = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	titles.add_child(_count_label)
	row.add_child(titles)
	var lb := InputHints.chip(InputHints.raw(KEY_Q, JOY_BUTTON_LEFT_SHOULDER))
	lb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lb)
	for t: Array in CodexData.TABS:
		var b := Button.new()
		b.text = String(t[1])
		b.custom_minimum_size = Vector2(0.0, CodexData.TAB_HEIGHT)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.set_meta(UiMotion.META_LIFT, false)
		b.pressed.connect(show_tab.bind(String(t[0]), true))
		row.add_child(b)
		tab_buttons[String(t[0])] = b
	var rb := InputHints.chip(InputHints.raw(KEY_E, JOY_BUTTON_RIGHT_SHOULDER))
	rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rb)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(CodexData.BACK_GAP, 0.0)
	row.add_child(gap)
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(CodexData.BACK_WIDTH, CodexData.TAB_HEIGHT)
	back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_button.set_meta(UiMotion.META_LIFT, false)
	back_button.pressed.connect(close)
	row.add_child(back_button)
	return row


## Left / right links along the tab row and Back.
func _wire_tabs() -> void:
	var row: Array[Button] = []  # Tabs then Back.
	for t: Array in CodexData.TABS:
		row.append(tab_buttons[String(t[0])])
	row.append(back_button)
	for i in row.size():
		var b := row[i]
		_link(b, b, b, row[maxi(i - 1, 0)], row[mini(i + 1, row.size() - 1)])
		b.focus_previous = b.get_path_to(row[maxi(i - 1, 0)])
		b.focus_next = b.get_path_to(row[mini(i + 1, row.size() - 1)])


## Shows tab `id`: its page, the gold tab frame, the count line and (when
## `animate`) the staggered entrance of its items. The focus moves to its
## tab button if it was on the page that was hidden.
func show_tab(id: String, animate: bool = true) -> void:
	if id == current:
		return
	var prev := current
	current = id
	for t: String in _pages:
		(_pages[t] as Control).visible = t == id
	for t: String in tab_buttons:
		UiTheme.style_button(tab_buttons[t] as Button, "button", "gold" if t == id else "")
	_count_label.text = String(_counts.get(id, ""))
	for t: String in tab_buttons:
		(tab_buttons[t] as Button).focus_neighbor_bottom = (tab_buttons[t] as Button).get_path_to(_first[id] if _first.has(id) else tab_buttons[t])
	back_button.focus_neighbor_bottom = back_button.get_path_to(_first[id] if _first.has(id) else back_button)
	if prev != "":
		var f := get_viewport().gui_get_focus_owner()  # Focus before the switch.
		if f == null or not f.is_visible_in_tree():
			(tab_buttons[id] as Button).grab_focus()
	if animate:
		UiMotion.stagger((_items.get(id, []) as Array).slice(0, CodexData.STAGGER_COUNT), 0.0, CodexData.STAGGER_INTERVAL)


## Shows the next (`step` 1) or previous (-1) tab.
func _cycle_tab(step: int) -> void:
	var ids: Array[String] = []
	for t: Array in CodexData.TABS:
		ids.append(String(t[0]))
	var i := (ids.find(current) + step + ids.size()) % ids.size()
	show_tab(ids[i])
	(tab_buttons[current] as Button).grab_focus()  # Plays the hover tick (Sfx focus hook).


# =====================================================================================
# Achievements page
# =====================================================================================

## The Achievements page: two sections of CodexFeatRow cards in a scroll.
func _feats_page() -> Control:
	var id := String(CodexData.TABS[0][0])
	var scroll := _scroll()
	_scrolls[id] = scroll
	var pad := MarginContainer.new()  # Keeps the cards clear of the scroll bar.
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", CodexData.SCROLL_GUTTER)
	scroll.add_child(pad)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	pad.add_child(col)
	var rows: Array[Button] = []
	var earned := 0  # Earned rows.
	var feats := CodexEntries.feats()
	var in_feats := false  # The feats section header was added.
	col.add_child(_section_label(CodexData.ACHIEVEMENTS_HEADER))
	for f: Dictionary in feats:
		if bool(f["feat"]) and not in_feats:
			in_feats = true
			col.add_child(_section_label(CodexData.FEATS_HEADER))
		var r := CodexFeatRow.new(f)
		col.add_child(r)
		rows.append(r)
		earned += 1 if bool(f["earned"]) else 0
	var grid: Array = []  # One row per card (a one-column focus grid).
	for r: Button in rows:
		grid.append([r])
	_rows[id] = grid
	_pages[id] = scroll
	_first[id] = rows[0]
	_items[id] = rows
	_counts[id] = CodexData.EARNED_COUNT % [earned, rows.size()]
	TouchSupport.pass_drags(scroll)  # A finger can drag the list from any card.
	return scroll


# =====================================================================================
# Codex pages
# =====================================================================================

## A codex page `id`: the tile grid of `sections` in a scroll on the left
## and the detail panel on the right.
func _codex_page(id: String, sections: Array) -> Control:
	var page := HBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 14)
	var scroll := _scroll()
	_scrolls[id] = scroll
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	scroll.add_child(col)
	var rows: Array = []  # Focus grid: Array of Array[Button], top to bottom.
	var items: Array = []
	for s: Dictionary in sections:
		col.add_child(_section_label(String(s["title"])))
		var grid := GridContainer.new()
		grid.columns = CodexData.COLUMNS
		grid.add_theme_constant_override("h_separation", CodexData.TILE_GAP)
		grid.add_theme_constant_override("v_separation", CodexData.TILE_GAP)
		col.add_child(grid)
		var row: Array[Button] = []
		for e: Dictionary in s["entries"]:
			var big := bool(e["boss"])  # A boss: a big tile.
			if not big and row.size() >= CodexData.COLUMNS:
				rows.append(row)
				row = []
			if big:
				grid.columns = CodexData.BOSS_COLUMNS
			var t := _tile(id, e, big)
			grid.add_child(t)
			row.append(t)
			items.append(t)
		if not row.is_empty():
			rows.append(row)
	page.add_child(_detail_panel(id))
	_rows[id] = rows
	_pages[id] = page
	_first[id] = rows[0][0]
	_items[id] = items
	var c := CodexEntries.counts(sections)
	_counts[id] = CodexData.RECORDED_COUNT % [c.x, c.y]
	_show_detail(id, (sections[0]["entries"] as Array)[0])
	TouchSupport.pass_drags(scroll)  # A finger can drag the grid from any tile.
	return page


## A tile Button for entry `e` of page `page` (big for a boss).
func _tile(page: String, e: Dictionary, big: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CodexData.BOSS_TILE_SIZE if big else CodexData.TILE_SIZE
	b.focus_mode = Control.FOCUS_ALL
	var met := bool(e["met"])
	var accent := "violet"  # Kit frame: gold for an obtained evolution, dim when locked.
	if met and bool(e["evolution"]):
		accent = "gold"
	elif not met:
		accent = "dim"
	UiTheme.style_button(b, "button", accent)
	var art := CodexArt.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset := CodexData.TILE_INSET  # Art inset from the frame (px).
	art.offset_left = inset
	art.offset_top = inset
	art.offset_right = -inset
	art.offset_bottom = -inset
	art.crop = true
	art.max_scale = 2 if String(e["sprite"]) == "" else 1
	art.show_entry(String(e["sprite"]), String(e["icon"]), not met, bool(e["evolution"]) and not met)
	b.add_child(art)
	b.focus_entered.connect(_show_detail.bind(page, e))
	b.mouse_entered.connect(_show_detail.bind(page, e))
	return b


## Explicit focus links of a page's tile `rows` (Array of Array[Button]):
## left / right inside a row, up / down to the nearest column of the row
## above / below (by position, so the big boss tiles line up), Up from the
## top row to the page's tab. With `wrap` the ends of a row lead on to the
## row above / below (the tile grids); without, they stay (the list).
func _wire_grid(page: String, rows: Array, wrap: bool) -> void:
	for r in rows.size():
		var row: Array = rows[r]
		for c in row.size():
			var b: Button = row[c]
			var up: Control = tab_buttons[page] if r == 0 else _nearest(rows[r - 1], b, c)
			var down: Control = b if r == rows.size() - 1 else _nearest(rows[r + 1], b, c)
			var left: Control = row[c - 1] if c > 0 else (rows[r - 1][(rows[r - 1] as Array).size() - 1] if r > 0 and wrap else b)
			var right: Control = row[c + 1] if c < row.size() - 1 else (rows[r + 1][0] if r < rows.size() - 1 and wrap else b)
			_link(b, up, down, left, right)
			b.focus_previous = b.get_path_to(left)
			b.focus_next = b.get_path_to(right)
			if r == 0:
				b.focus_entered.connect(_scroll_top.bind(page))  # Show the first section's header too.


## Scrolls page `page` back to its top (its first row took the focus).
func _scroll_top(page: String) -> void:
	var s := _scrolls.get(page) as ScrollContainer
	if s != null:
		s.set_deferred("scroll_vertical", 0)


## The button of `row` straight above / below button `b` at column `c` of
## its own row: positions are counted in small-tile columns (a big boss
## tile spans two), so the boss row lines up with the rows of small tiles.
static func _nearest(row: Array, b: Button, c: int) -> Button:
	var centre := (float(c) + 0.5) * _span(b)  # Column centre of `b` (small-tile columns).
	var i := floori(centre / _span(row[0] as Button))  # Index in `row` under that centre.
	return row[clampi(i, 0, row.size() - 1)]


## Small-tile columns tile `b` spans (2 for a big boss tile, else 1).
static func _span(b: Button) -> float:
	return float(CodexData.COLUMNS) / float(CodexData.BOSS_COLUMNS) if b.custom_minimum_size.x > CodexData.TILE_SIZE.x else 1.0


## The detail panel of page `page` (portrait, name, tag, text, stats, record).
func _detail_panel(page: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.style("card"))
	panel.custom_minimum_size = Vector2(CodexData.DETAIL_WIDTH, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)
	var art := CodexArt.new(CodexData.PORTRAIT_SIZE)
	art.max_scale = CodexData.PORTRAIT_MAX_SCALE
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(art)
	var name_l := UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(name_l)
	var tag := UiTheme.tier_label("", UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tag)
	vb.add_child(UiTheme.divider())
	var desc := UiTheme.para("", CodexData.DETAIL_WIDTH - 24.0, UiTheme.TEXT)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(desc)
	var stats_margin := MarginContainer.new()  # Insets the stat lines from the card's edges.
	for side: String in ["margin_left", "margin_right"]:
		stats_margin.add_theme_constant_override(side, CodexData.STATS_INSET)
	vb.add_child(stats_margin)
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 0)
	stats_margin.add_child(stats)
	var record := UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_GOLD)
	record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(record)
	_details[page] = {"art": art, "name": name_l, "tag": tag, "desc": desc, "stats": stats, "record": record}
	return panel


## Fills page `page`'s detail panel with entry `e` (or its locked form).
func _show_detail(page: String, e: Dictionary) -> void:
	var d: Dictionary = _details.get(page, {})
	if d.is_empty():
		return
	var met := bool(e["met"])
	var evo := bool(e["evolution"])
	var art: CodexArt = d["art"]
	art.max_scale = CodexData.PORTRAIT_ICON_SCALE if String(e["sprite"]) == "" else CodexData.PORTRAIT_MAX_SCALE
	art.show_entry(String(e["sprite"]), String(e["icon"]), not met, evo and not met)
	var name_l: Label = d["name"]
	name_l.text = String(e["name"]) if met else (CodexData.LOCKED_EVOLUTION if evo else CodexData.LOCKED_NAME)
	name_l.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if met and (evo or bool(e["boss"])) else (UiTheme.TEXT if met else UiTheme.TEXT_DIM))
	(d["tag"] as Label).text = String(e["tag"])
	var hint_key := "evolution" if evo else String(e["section"])  # LOCKED_HINT key.
	var hint := String(e.get("lock_hint", ""))  # An Act II item's unlock condition, if it is locked.
	if hint == "":
		hint = String(CodexData.LOCKED_HINT.get(hint_key, CodexData.LOCKED_HINT.get(page, "")))
	(d["desc"] as Label).text = String(e["desc"]) if met else hint
	var stats: VBoxContainer = d["stats"]
	for c in stats.get_children():
		stats.remove_child(c)
		c.queue_free()
	if met:
		for s: Array in e["stats"]:
			stats.add_child(_stat_row(String(s[0]), String(s[1])))
	(d["record"] as Label).text = String(e["record"]) if met else ""


## One "label ...... value" stat line of the detail panel (a long value,
## such as a recipe, goes centred under its label instead).
func _stat_row(label: String, value: String) -> Control:
	if value.length() > CodexData.STAT_INLINE_CHARS:
		var v_box := VBoxContainer.new()
		v_box.add_theme_constant_override("separation", 0)
		v_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var head := UiTheme.tier_label(label, UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v_box.add_child(head)
		var text := UiTheme.para(value, 0.0, UiTheme.TEXT)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v_box.add_child(text)
		return v_box
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UiTheme.tier_label(label, UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var v := UiTheme.tier_label(value, UiTheme.Tier.BODY, UiTheme.TEXT)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.custom_minimum_size.x = 0.0
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_stretch_ratio = 2.2
	h.add_child(v)
	return h


# =====================================================================================
# Helpers
# =====================================================================================

## A vertical ScrollContainer filling its parent that follows the focus.
func _scroll() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.follow_focus = true
	return s


## A section label (LABEL tier) with a little space above it.
func _section_label(text: String) -> Control:
	var l := UiTheme.tier_label(text, UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	l.custom_minimum_size.y = 26.0
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return l


## Sets the four focus neighbours of `b`.
static func _link(b: Control, up: Control, down: Control, left: Control, right: Control) -> void:
	b.focus_neighbor_top = b.get_path_to(up)
	b.focus_neighbor_bottom = b.get_path_to(down)
	b.focus_neighbor_left = b.get_path_to(left)
	b.focus_neighbor_right = b.get_path_to(right)


## Restores focus to the opener and frees the screen.
func close() -> void:
	if UiMotion.is_closing(self):
		return
	closed.emit()
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	UiMotion.close(self, queue_free)


## Esc / pad B close; Q / E and LB / RB switch tabs.
func _input(event: InputEvent) -> void:
	if UiMotion.is_closing(self):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
		return
	var step := CreditsScreen._page_step(event)  # -1 / +1 for a tab switch, 0 otherwise.
	if step != 0:
		get_viewport().set_input_as_handled()
		_cycle_tab(step)
