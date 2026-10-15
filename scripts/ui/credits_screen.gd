## CreditsScreen — the Credits (GDD §15.0 "Credits screen"), opened from
## the main menu with CreditsScreen.open_over(parent). An ornate violet
## panel with two pages (CreditsData.PAGES):
##   * Credits: a slow, elegant roll (CreditsData.ROLL: the logo, the studio,
##     Godot Engine, the fonts, the synthesized audio, the playtesters,
##     "Thanks for playing") that rests at the top for START_DELAY s and
##     then drifts up at SCROLL_SPEED px/s on real time, by fractional pixels
##     (the content is moved inside a clipping pane, not stepped by a
##     ScrollContainer). Up / Down, the mouse wheel or a drag take over; with
##     Reduce motion the roll stays still and is scrolled by hand.
##   * Licences: the notices Godot asks a game to ship (Engine.get_license_text(),
##     the third-party components of Engine.get_copyright_info() and their
##     licence texts, Engine.get_license_info()) and the SIL Open Font
##     License 1.1 of Jersey 10 and Jacquard 24 with both copyright lines
##     (read from assets/fonts/OFL-*.txt). Built the first time the page
##     opens (about 65,000 characters), scrolled with Up / Down or the wheel.
## Pages switch with the two tab buttons, Q / E or LB / RB. Back, Esc or pad
## B close the screen (focus returns to the opener). Text sizes are the
## UiTheme type tiers; Jersey 10 everywhere, Jacquard for the titles.
class_name CreditsScreen
extends Control

## Emitted when the screen is about to be freed.
signal closed

## Control focused again when the screen closes (may be null).
var return_focus: Control = null
## Page id -> its tab Button.
var _tabs: Dictionary = {}
## Page id -> its page Control (one visible at a time).
var _pages: Dictionary = {}
## Id of the page shown.
var _page: String = "credits"
## Back button.
var back_button: Button
## Clipping pane of the credits roll.
var _roll_pane: Control
## The credits roll content (moved up inside _roll_pane).
var _roll: VBoxContainer
## Scroll offset of the roll (px, >= 0; fractional while it drifts).
var _roll_y: float = 0.0
## True while the roll drifts on its own (until the player scrolls).
var _auto: bool = true
## Seconds the roll has rested at the top so far.
var _rest: float = 0.0
## Licences page ScrollContainer (null until first built).
var _licences: ScrollContainer = null
## usec timestamp of the last _process() (real time, unscaled).
var _last_usec: int = 0


## Creates the screen as a full-screen child of `parent` and returns it.
## The control focused at that moment regains focus when it closes.
static func open_over(parent: Control) -> CreditsScreen:
	var s := CreditsScreen.new()
	var vp := parent.get_viewport()  # Null when the parent is not in the tree.
	s.return_focus = vp.gui_get_focus_owner() if vp != null else null
	parent.add_child(s)
	return s


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiTheme.get_theme()
	add_child(UiTheme.backdrop(CreditsData.BACKDROP_ALPHA))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit (no-op at 720 px).
	var panel := UiTheme.ornate_panel("violet")
	panel.custom_minimum_size = CreditsData.PANEL_SIZE
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	vb.add_child(_header())
	vb.add_child(UiTheme.divider())
	var stack := Control.new()  # Holds both pages, one visible.
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(stack)
	_roll_pane = _build_roll()
	stack.add_child(_roll_pane)
	_pages["credits"] = _roll_pane
	var lic_holder := Control.new()  # Filled by _build_licences() on first view.
	lic_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lic_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(lic_holder)
	_pages["licences"] = lic_holder
	add_child(InputHints.bottom_strip([[[InputHints.raw(KEY_Q, JOY_BUTTON_LEFT_SHOULDER), InputHints.raw(KEY_E, JOY_BUTTON_RIGHT_SHOULDER)], "Page"],
		[[InputHints.raw(KEY_UP, JOY_BUTTON_DPAD_UP), InputHints.raw(KEY_DOWN, JOY_BUTTON_DPAD_DOWN)], "Scroll"], ["ui_cancel", "Back"]]))
	_auto = UiMotion.enabled()
	_last_usec = Time.get_ticks_usec()
	_show_page("credits")
	back_button.grab_focus.call_deferred()
	UiMotion.open(self)


## Title, the page tabs and Back.
func _header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var title := UiTheme.tier_label(CreditsData.TITLE, UiTheme.Tier.TITLE, UiTheme.TEXT_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var buttons: Array[Button] = []  # Tabs then Back, left to right (focus row).
	for p: Array in CreditsData.PAGES:
		var b := Button.new()
		b.text = String(p[1])
		b.custom_minimum_size = CreditsData.TAB_SIZE
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.set_meta(UiMotion.META_LIFT, false)
		b.pressed.connect(_show_page.bind(String(p[0])))
		row.add_child(b)
		_tabs[String(p[0])] = b
		buttons.append(b)
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = CreditsData.BACK_SIZE
	back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(close)
	row.add_child(back_button)
	buttons.append(back_button)
	for i in buttons.size():
		var b := buttons[i]
		var left := buttons[maxi(i - 1, 0)]
		var right := buttons[mini(i + 1, buttons.size() - 1)]
		b.focus_neighbor_left = b.get_path_to(left)
		b.focus_neighbor_right = b.get_path_to(right)
		b.focus_neighbor_top = b.get_path_to(b)  # Up / Down scroll the page instead.
		b.focus_neighbor_bottom = b.get_path_to(b)
		b.focus_previous = b.get_path_to(left)
		b.focus_next = b.get_path_to(right)
	return row


## The clipping pane and the credits roll inside it (CreditsData.ROLL).
func _build_roll() -> Control:
	var pane := Control.new()
	pane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pane.clip_contents = true
	pane.mouse_filter = Control.MOUSE_FILTER_PASS
	pane.gui_input.connect(_on_roll_input)
	pane.resized.connect(_layout_roll)
	_roll = VBoxContainer.new()
	_roll.add_theme_constant_override("separation", 6)
	_roll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pane.add_child(_roll)
	for row: Array in CreditsData.ROLL:
		_roll.add_child(_roll_row(String(row[0]), String(row[1])))
	var tail := Control.new()  # Lets the last line scroll up to the middle.
	tail.name = "Tail"
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roll.add_child(tail)
	return pane


## One credits row of `kind` (see CreditsData.ROLL) with `text`.
func _roll_row(kind: String, text: String) -> Control:
	match kind:
		"logo":
			if ResourceLoader.exists(UiArtData.LOGO):
				var tex := load(UiArtData.LOGO) as Texture2D  # The wordmark (art px).
				var logo := TextureRect.new()
				logo.texture = tex
				logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				logo.custom_minimum_size = tex.get_size() * float(UiArtData.LOGO_SCALE)
				logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
				SpriteBank.apply_sharp(logo)
				return logo
			return UiTheme.title("Necropathy", Palette.NECRO_GREEN)
		"label":
			return _centred(UiTheme.tier_label(text, UiTheme.Tier.LABEL, UiTheme.TEXT_DIM))
		"header":
			return _centred(UiTheme.tier_label(text, UiTheme.Tier.HEADER, UiTheme.TEXT_GOLD))
		"name":
			return _centred(UiTheme.tier_label(text, UiTheme.Tier.NAME, UiTheme.TEXT))
		"body":
			return _centred(UiTheme.para(text, CreditsData.COLUMN_WIDTH, UiTheme.TEXT_DIM))
		"divider":
			var holder := MarginContainer.new()  # A short divider, inset from the column's ends.
			holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for side: String in ["margin_left", "margin_right"]:
				holder.add_theme_constant_override(side, CreditsData.DIVIDER_INSET)
			holder.add_theme_constant_override("margin_top", 10)
			holder.add_theme_constant_override("margin_bottom", 10)
			holder.add_child(UiTheme.divider())
			return holder
		"title":
			return UiTheme.title(text, UiTheme.TEXT_GOLD)
	var gap := Control.new()  # "gap" (and unknown kinds).
	gap.custom_minimum_size = Vector2(0.0, CreditsData.GAP)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap


## Centres label `l` (and lets it wrap inside the column).
func _centred(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if l.custom_minimum_size.x > 0.0:
		l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # A paragraph keeps its column width.
	return l


## Sizes the roll to the pane's width and sets its tail so the last line
## can rise to the pane's middle.
func _layout_roll() -> void:
	if _roll == null or _roll_pane == null:
		return
	var tail := _roll.get_node("Tail") as Control
	tail.custom_minimum_size.y = _roll_pane.size.y * 0.5 - float(UiTheme.tier_px(UiTheme.Tier.TITLE))
	_roll.size = Vector2(_roll_pane.size.x, 0.0)
	_roll.position.x = 0.0
	_set_roll(_roll_y)


## Bottom of the roll's scroll range (px).
func _roll_max() -> float:
	return maxf(0.0, _roll.get_combined_minimum_size().y - _roll_pane.size.y)


## Moves the roll to offset `y` (clamped; fractional px allowed).
func _set_roll(y: float) -> void:
	_roll_y = clampf(y, 0.0, _roll_max())
	_roll.position.y = -_roll_y


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()  # Real time (unscaled).
	var dt := clampf(float(now - _last_usec) / 1000000.0, 0.0, 0.1)  # Real step (s).
	_last_usec = now
	if not _auto or _page != "credits" or UiMotion.is_closing(self):
		return
	if _rest < CreditsData.START_DELAY:
		_rest += dt
		return
	_set_roll(_roll_y + CreditsData.SCROLL_SPEED * dt)
	if _roll_y >= _roll_max():
		_auto = false  # The end: "Thanks for playing" rests in view.


## Mouse wheel / drag on the roll: the player takes over the scroll.
func _on_roll_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		_auto = false
		_set_roll(_roll_y + (CreditsData.SCROLL_STEP if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -CreditsData.SCROLL_STEP) * 0.5)
		accept_event()
	var mm := event as InputEventMouseMotion
	if mm != null and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_auto = false
		_set_roll(_roll_y - mm.relative.y)
		accept_event()


## Shows page `id` (and builds the licences on their first view).
func _show_page(id: String) -> void:
	_page = id
	if id == "licences" and _licences == null:
		_build_licences()
	for p: String in _pages:
		(_pages[p] as Control).visible = p == id
	for p: String in _tabs:
		UiTheme.style_button(_tabs[p] as Button, "button", "gold" if p == id else "")


## Shows the next (`step` 1) or previous (-1) page.
func _cycle_page(step: int) -> void:
	var ids: Array[String] = []  # Page ids in order.
	for p: Array in CreditsData.PAGES:
		ids.append(String(p[0]))
	var i := (ids.find(_page) + step + ids.size()) % ids.size()
	Sfx.play("ui_hover")
	_show_page(ids[i])


## Builds the licences page (see the header) in a ScrollContainer.
func _build_licences() -> void:
	_licences = ScrollContainer.new()
	_licences.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_licences.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	(_pages["licences"] as Control).add_child(_licences)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	_licences.add_child(col)
	var w := CreditsData.PANEL_SIZE.x - 80.0  # Text width inside the panel and the scroll bar (px).
	col.add_child(UiTheme.tier_label(CreditsData.GODOT_HEADER, UiTheme.Tier.NAME, UiTheme.TEXT_GOLD))
	col.add_child(UiTheme.para(Engine.get_license_text(), w, UiTheme.TEXT_DIM))
	col.add_child(UiTheme.divider())
	col.add_child(UiTheme.tier_label(CreditsData.FONTS_HEADER, UiTheme.Tier.NAME, UiTheme.TEXT_GOLD))
	var ofl := ""  # The licence text (without its copyright line), read once.
	for f: Array in CreditsData.FONT_LICENCES:
		var text := FileAccess.get_file_as_string(String(f[1]))  # "" when the file is missing.
		var lines := text.split("\n")
		col.add_child(UiTheme.tier_label(String(f[0]), UiTheme.Tier.BODY, UiTheme.TEXT))
		col.add_child(UiTheme.para(lines[0] if lines.size() > 0 else "", w, UiTheme.TEXT_DIM))
		if ofl == "" and lines.size() > 1:
			ofl = "\n".join(lines.slice(1)).strip_edges()
	col.add_child(UiTheme.para(ofl, w, UiTheme.TEXT_DIM))
	col.add_child(UiTheme.divider())
	col.add_child(UiTheme.tier_label(CreditsData.THIRD_PARTY_HEADER, UiTheme.Tier.NAME, UiTheme.TEXT_GOLD))
	for c: Dictionary in Engine.get_copyright_info():
		var lines := PackedStringArray()  # "(c) ..." lines and licences of this component.
		for part: Dictionary in c["parts"]:
			for who: String in part["copyright"]:
				lines.append("(c) " + who)
			lines.append("Licence: " + String(part["license"]))
		col.add_child(UiTheme.tier_label(String(c["name"]), UiTheme.Tier.BODY, UiTheme.TEXT))
		col.add_child(UiTheme.para("\n".join(lines), w, UiTheme.TEXT_DIM))
	col.add_child(UiTheme.divider())
	col.add_child(UiTheme.tier_label(CreditsData.LICENCE_TEXTS_HEADER, UiTheme.Tier.NAME, UiTheme.TEXT_GOLD))
	var info := Engine.get_license_info()  # Licence name -> text.
	for key: Variant in info:
		col.add_child(UiTheme.tier_label(String(key), UiTheme.Tier.BODY, UiTheme.TEXT))
		col.add_child(UiTheme.para(String(info[key]), w, UiTheme.TEXT_DIM))


## Scrolls the shown page by `dy` px (the player takes over the roll).
func _scroll(dy: float) -> void:
	if _page == "credits":
		_auto = false
		_set_roll(_roll_y + dy)
	elif _licences != null:
		_licences.scroll_vertical = int(float(_licences.scroll_vertical) + dy)


## Restores focus to the opener and frees the screen.
func close() -> void:
	if UiMotion.is_closing(self):
		return
	closed.emit()
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	UiMotion.close(self, queue_free)


## Esc / pad B close; Q / E and LB / RB switch pages; Up / Down scroll.
func _input(event: InputEvent) -> void:
	if UiMotion.is_closing(self):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
		return
	var page_step := _page_step(event)  # -1 / +1 for a page switch, 0 otherwise.
	if page_step != 0:
		get_viewport().set_input_as_handled()
		_cycle_page(page_step)
		return
	if event.is_action_pressed("ui_up", true) or event.is_action_pressed("ui_down", true):
		get_viewport().set_input_as_handled()
		_scroll(CreditsData.SCROLL_STEP * (-1.0 if event.is_action_pressed("ui_up", true) else 1.0))


## -1 / +1 when `event` is a page switch press (Q / LB, E / RB), else 0.
static func _page_step(event: InputEvent) -> int:
	var k := event as InputEventKey
	if k != null and k.pressed and not k.echo:
		if k.physical_keycode == KEY_Q:
			return -1
		if k.physical_keycode == KEY_E:
			return 1
	var j := event as InputEventJoypadButton
	if j != null and j.pressed:
		if j.button_index == JOY_BUTTON_LEFT_SHOULDER:
			return -1
		if j.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			return 1
	return 0
