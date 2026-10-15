## PreRunSetup — the pre-run setup screen (GDD §10.2 "Select ... difficulty
## (§8.4) and modifiers (§8.5). Show the total reward multiplier from stacked
## modifiers"; GDD §15.0 "Front door screens"). The stage select opens it
## after a stage is chosen. It fits 1280 x 720 over the menu's diorama (a low
## scrim, FrontDoorData.PRERUN_SCRIM) under a one-line title, in two columns:
##   * LEFT, the hero (PreRunHero, an ornate panel): the character being
##     looked at, big (3x) and walking in place on the stage's floor, in the
##     skin it would wear, with its name, innate and starting spell; under it
##     the skin tiles and the Hyper tile with one detail line
##     (PreRunHyperSkins: SkinData, HyperData; Hyper stays locked until
##     Seraphine falls),
##   * RIGHT, the setup panel: the character grid (CharacterPicker, one row of
##     twelve portrait tiles; locked ones padlocked), four difficulty cards
##     (DifficultyData, easiest to hardest: an icon, the name, ONE line and the
##     Soul Ash multiplier; every number that differs from the standard level
##     and the GDD line are the card's tooltip; exactly one is selected, in
##     gold), the eight run modifiers as compact toggle tiles (RunModifierData:
##     a rune pip, the name and the Soul Ash reward; active ones crimson; the
##     focused / hovered one's effect shows in the one line under the grid and
##     in its tooltip; they stack), and the TOTAL Soul Ash multiplier as one
##     gold plaque that rolls to each new value (its tooltip holds the
##     breakdown, the combined enemy numbers and the Profane Oath note),
##   * Back (to the stage select), Standard (Necromancer, no modifiers, no
##     Hyper) and the strong gold Begin under the setup panel.
## Fully keyboard / mouse / controller navigable (arrows / D-pad move between
## tiles, cards and buttons with explicit focus neighbours, rebuilt whenever
## the skin tiles change; Enter / A selects or toggles, Esc / B goes back). The
## screen opens on the choices remembered in the Meta save
## (Meta.prerun_config) and Begin remembers the new ones (Meta.remember_prerun)
## before emitting `confirmed` with the finished RunConfig. All difficulty
## levels are open from the start (GDD §15.0: the GDD names no difficulty
## unlocks). Text sizes are UiTheme type tiers.
class_name PreRunSetup
extends Control

## Begin pressed: start a run with `config` (stage, difficulty, modifiers).
signal confirmed(config: RunConfig)
## The screen closed without starting (Back / Esc).
signal closed

## UI kit accent of the selected difficulty card (gold frame, UiTheme.style()).
const SELECTED_ACCENT: String = "gold"
## UI kit accent of an active run-modifier tile (crimson frame).
const ACTIVE_ACCENT: String = "crimson"

## The config being edited (its stage is fixed; difficulty and modifiers change).
var config: RunConfig = null
## Control that gets focus back when the screen closes.
var return_focus: Control = null
## Difficulty id -> its card Button.
var _level_buttons: Dictionary = {}
## Difficulty id -> its name Label (recoloured when selected).
var _level_names: Dictionary = {}
## Run modifier id -> its tile Button.
var _mod_buttons: Dictionary = {}
## Run modifier id -> its rune pip (MaskIcon: lit while active).
var _mod_pips: Dictionary = {}
## Run modifier id -> its name Label.
var _mod_names: Dictionary = {}
## Effect line of the focused / hovered run modifier (under the grid).
var _mod_detail: Label
## The gold total plaque (its tooltip holds the breakdown).
var _plaque: PanelContainer
## The plaque's number ("x1.45").
var _total_label: Label
## The plaque's Profane Oath note ("" when no Oath tier is active).
var _oath_label: Label
## Total Soul Ash multiplier shown right now (rolls toward the real one).
var _shown_total: float = -1.0
## Running roll of the total (null when settled).
var _total_tween: Tween = null
## Back button.
var _back: Button
## Standard (reset) button.
var _reset: Button
## Begin button (focused on open).
var _begin: Button
## The hero panel (left column).
var _hero: PreRunHero
## The playable-character grid (top of the setup panel).
var _picker: CharacterPicker
## Skin tiles and the Hyper tile (PreRunHyperSkins, in the hero panel).
var _extras: PreRunHyperSkins
## Character the hero shows (follows the focused tile).
var _hero_char: String = ""
## Skin previewed on the chosen character while its skin tile is focused
## ("" = none: the worn skin).
var _preview_skin: String = ""


## Opens the screen over `parent` for `p_config`; focus returns to `refocus`
## when it closes.
static func open_over(parent: Control, refocus: Control, p_config: RunConfig) -> PreRunSetup:
	var s := PreRunSetup.new()
	s.config = p_config
	s.return_focus = refocus
	parent.add_child(s)
	return s


func _ready() -> void:
	if config == null:
		config = RunConfig.new()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UiTheme.backdrop(FrontDoorData.PRERUN_SCRIM))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit (no-op at 720 px).
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	center.add_child(vb)
	vb.add_child(_head())
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", FrontDoorData.PRERUN_COLUMN_GAP)
	vb.add_child(cols)
	# Left column: the hero, with the skin / Hyper row.
	_hero = PreRunHero.new()
	_hero.stage_id = config.stage_id
	cols.add_child(_hero)
	_extras = PreRunHyperSkins.new()
	_extras.config = config
	_extras.changed.connect(_on_extras_changed)
	_extras.rebuilt.connect(_queue_wire)
	_extras.skin_focused.connect(_on_skin_focused)
	_hero.add_extra(_extras)
	# Right column: the setup panel, then the buttons.
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.custom_minimum_size.x = FrontDoorData.SETUP_WIDTH
	cols.add_child(right)
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(panel)
	var setup := VBoxContainer.new()
	setup.add_theme_constant_override("separation", 8)
	panel.add_child(setup)
	setup.add_child(_section("Character"))
	_picker = CharacterPicker.new()
	_picker.config = config
	_picker.character_changed.connect(_on_character_changed)
	_picker.shown_changed.connect(_show_hero)
	setup.add_child(_picker)
	setup.add_child(_section("Difficulty"))
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 8)
	setup.add_child(lrow)
	for id: String in DifficultyData.ORDER:
		lrow.add_child(_build_level_card(id))
	setup.add_child(_section("Modifiers"))
	var grid := GridContainer.new()
	grid.columns = FrontDoorData.MOD_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	setup.add_child(grid)
	for id: String in RunModifierData.ORDER:
		grid.add_child(_build_mod_tile(id))
	_mod_detail = UiTheme.tier_label(FrontDoorData.MOD_HINT, UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_mod_detail.clip_text = true
	_mod_detail.custom_minimum_size.x = FrontDoorData.SETUP_WIDTH - 24.0
	setup.add_child(_mod_detail)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup.add_child(spacer)
	setup.add_child(_build_plaque())
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	right.add_child(buttons)
	_back = _make_button("Back", FrontDoorData.PRERUN_BUTTON, buttons, close)
	_reset = _make_button("Standard", FrontDoorData.PRERUN_BUTTON, buttons, _reset_choice)  # Necromancer, no modifiers, no Hyper.
	_reset.tooltip_text = "Necromancer, no modifiers, no Hyper."
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buttons.add_child(fill)
	_begin = _make_button("Begin", FrontDoorData.BEGIN_BUTTON, buttons, _start)
	UiTheme.style_button(_begin, "button", "gold")  # The strong primary action.
	for fc: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		_begin.add_theme_color_override(fc, UiTheme.TEXT_GOLD.lightened(0.25 if fc != "font_color" else 0.0))
	_begin.set_meta(UiMotion.META_LIFT, false)
	_refresh()
	_show_hero(config.character_id)
	_queue_wire()
	add_child(InputHints.bottom_strip([[InputHints.MOVE, "Move"], ["ui_accept", "Select"], ["ui_cancel", "Back"]]))
	_begin.grab_focus.call_deferred()
	UiMotion.open(self)  # Fade / rise in.


## The title line: the TITLE and the chosen stage (LABEL).
func _head() -> Control:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(UiTheme.title("Prepare the Ritual"))
	var def := config.stage_def()  # The chosen stage.
	var stage_l := UiTheme.tier_label("%s  ·  %s" % [String(def["chapter"]), String(def["short_name"])], UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	stage_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(stage_l)
	return head


## A small section label (LABEL tier).
static func _section(text: String) -> Label:
	return UiTheme.tier_label(text, UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)


## A bottom-row button of `size_px`.
func _make_button(text: String, size_px: Vector2, parent: Control, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size_px
	b.pressed.connect(action)
	parent.add_child(b)
	return b


## One difficulty card: icon and name, one line, the Soul Ash multiplier.
func _build_level_card(id: String) -> Button:
	var lv: Dictionary = DifficultyData.LEVELS[id]
	var b := Button.new()
	b.custom_minimum_size = FrontDoorData.LEVEL_CARD
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(_select_level.bind(id))
	b.tooltip_text = "%s\n%s" % [String(lv["tagline"]), _level_numbers(lv)]  # The GDD line and the numbers.
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 10
	box.offset_right = -8
	box.offset_top = 6
	box.offset_bottom = -6
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := MaskIcon.new(String(FrontDoorData.LEVEL_ICONS.get(id, "skull")), FrontDoorData.LEVEL_ICON_SCALE)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(icon)
	var name_l := UiTheme.tier_label(String(lv["display_name"]), UiTheme.Tier.NAME, UiTheme.TEXT)
	name_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(name_l)
	box.add_child(head)
	box.add_child(UiTheme.tier_label(String(FrontDoorData.LEVEL_LINES.get(id, "")), UiTheme.Tier.BODY, UiTheme.TEXT_DIM))
	box.add_child(UiTheme.tier_label(_level_reward(lv), UiTheme.Tier.BODY, MetaGlyphs.EMBER.lightened(0.25)))
	_level_buttons[id] = b
	_level_names[id] = name_l
	return b


## The reward line of level row `lv`: the Soul Ash multiplier and, when not
## standard, the XP multiplier.
static func _level_reward(lv: Dictionary) -> String:
	var out := "Soul Ash ×%.2f" % float(lv["ash_mult"])  # Reward text.
	if float(lv["xp_mult"]) != 1.0:
		out += "  XP ×%.2f" % float(lv["xp_mult"])
	return out


## The enemy numbers of level row `lv` that differ from the standard level.
static func _level_numbers(lv: Dictionary) -> String:
	var foes := PackedStringArray()  # "HP x1.20"...
	for key: String in ["enemy_hp", "hp_scaling", "enemy_damage", "damage_scaling", "enemy_spawn", "enemy_speed", "boss_hp"]:
		if float(lv[key]) != 1.0:
			foes.append("%s ×%.2f" % [DifficultyData.SHORT[key], float(lv[key])])
	if float(lv["elite_chance"]) > 0.0:
		foes.append("+%.1f%% elites" % (float(lv["elite_chance"]) * 100.0))
	return "Foes: " + (", ".join(foes) if not foes.is_empty() else "standard")


## One run-modifier tile: rune pip, name and Soul Ash reward.
func _build_mod_tile(id: String) -> Button:
	var md: Dictionary = RunModifierData.MODIFIERS[id]
	var b := Button.new()
	b.custom_minimum_size = FrontDoorData.MOD_TILE
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(_toggle_mod.bind(id))
	b.tooltip_text = String(md["description"])
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 8
	box.offset_right = -10
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var pip := MaskIcon.new("rune_off", 2)
	pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(pip)
	var name_l := UiTheme.tier_label(String(md["display_name"]), UiTheme.Tier.BODY, UiTheme.TEXT)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_l.clip_text = true
	box.add_child(name_l)
	var ash := UiTheme.tier_label("+%d%%" % roundi(float(md["ash_gain"]) * 100.0), UiTheme.Tier.BODY, MetaGlyphs.EMBER.lightened(0.25))
	ash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(ash)
	b.focus_entered.connect(_show_mod_detail.bind(id))
	b.mouse_entered.connect(_show_mod_detail.bind(id))
	b.focus_exited.connect(_show_mod_detail.bind(""))
	_mod_buttons[id] = b
	_mod_pips[id] = pip
	_mod_names[id] = name_l
	return b


## The gold total plaque: the Soul Ash icon, "Soul Ash", the multiplier.
func _build_plaque() -> Control:
	_plaque = PanelContainer.new()
	_plaque.add_theme_stylebox_override("panel", UiTheme.style("panel", "gold"))
	_plaque.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_plaque.mouse_filter = Control.MOUSE_FILTER_STOP  # For the tooltip.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plaque.add_child(row)
	var icon := MainMenu.soul_ash_icon(FrontDoorData.PLAQUE_ICON_PX)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var name_l := UiTheme.tier_label("Soul Ash", UiTheme.Tier.LABEL, MetaGlyphs.EMBER.lightened(0.25))
	name_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_l)
	_total_label = UiTheme.tier_label("", UiTheme.Tier.HEADER, UiTheme.TEXT_GOLD)
	_total_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_total_label)
	_oath_label = UiTheme.tier_label("", UiTheme.Tier.BODY, Palette.CRIMSON.lightened(0.45))
	_oath_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_oath_label)
	return _plaque


## Shows run modifier `id`'s effect in the line under the grid ("" = the
## general hint).
func _show_mod_detail(id: String) -> void:
	if id == "" or not RunModifierData.MODIFIERS.has(id):
		_mod_detail.text = FrontDoorData.MOD_HINT
		_mod_detail.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
		return
	var md: Dictionary = RunModifierData.MODIFIERS[id]
	_mod_detail.text = "%s: %s" % [String(md["display_name"]), String(md["description"])]
	_mod_detail.add_theme_color_override("font_color", UiTheme.TEXT)


## The hero presents character `id` in the skin it would wear.
func _show_hero(id: String) -> void:
	_hero_char = id
	var skin := config.skin_id if id == config.character_id else Meta.chosen_skin(id)  # Worn skin.
	if id == config.character_id and _preview_skin != "":
		skin = _preview_skin  # A focused skin tile wins.
	_hero.show_character(id, skin, id == config.character_id)


## A skin tile is focused ("" = none): the hero wears it (the chosen character).
func _on_skin_focused(skin_id: String) -> void:
	_preview_skin = skin_id
	_show_hero(config.character_id)


## Hyper or the skin changed: totals and hero redraw.
func _on_extras_changed() -> void:
	_refresh()
	_show_hero(config.character_id)


## A character was chosen: its skin tiles follow (PreRunHyperSkins) and the
## totals redraw.
func _on_character_changed(_id: String) -> void:
	_refresh()
	_show_hero(config.character_id)


## Wires the focus neighbours once the containers have laid the tiles out
## (the cross-column links match rows by their on-screen height). Called on
## open and whenever the skin tiles are rebuilt for another character.
func _queue_wire() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if is_inside_tree():
		_wire_focus()


## Explicit focus neighbours, so arrows / D-pad never leave the screen:
## inside each column the rows link up and down (left: the skin / Hyper row;
## right: the character tiles, difficulty cards, modifier rows), the end of a
## row crosses to the other column's row nearest in height, the last rows
## lead down to the bottom buttons and the bottom buttons lead back up.
func _wire_focus() -> void:
	var left: Array = _extras.rows()  # Left column rows.
	var right: Array = _picker.tile_rows() + _rows_of(_level_buttons, DifficultyData.ORDER, DifficultyData.ORDER.size()) \
			+ _rows_of(_mod_buttons, RunModifierData.ORDER, FrontDoorData.MOD_COLUMNS)  # Right column rows.
	var bottom := [_back, _reset, _begin]  # Bottom row, left to right.
	_wire_column(left, [], right, [_back])
	_wire_column(right, left, [], bottom)
	for j in bottom.size():
		var b: Button = bottom[j]
		_link(b, "left", bottom[maxi(0, j - 1)] if j > 0 else (left.back() as Array).back())
		_link(b, "right", bottom[mini(bottom.size() - 1, j + 1)])
		_link(b, "bottom", b)
		var last: Array = right.back()  # The last modifier row.
		_link(b, "top", last[_nearest(j, bottom.size(), last.size())])


## The Buttons of `buttons` (id -> Button) in `order`, as rows of `cols`.
static func _rows_of(buttons: Dictionary, order: Array, cols: int) -> Array:
	var out: Array = []  # Rows of Buttons.
	for i in range(0, order.size(), cols):
		var row: Array = []  # One row, left to right.
		for k in range(i, mini(order.size(), i + cols)):
			row.append(buttons[order[k]])
		out.append(row)
	return out


## Links one column's `rows`: left / right inside a row, the row's first
## (last) item to the row of `left_rows` (`right_rows`) nearest in height
## (stays put when there is none), up / down between rows by column
## position, the top row's "top" to itself and the last row's "bottom" to
## `below` (spread by column).
func _wire_column(rows: Array, left_rows: Array, right_rows: Array, below: Array) -> void:
	for i in rows.size():
		var row: Array = rows[i]
		for j in row.size():
			var b: Button = row[j]
			if j > 0:
				_link(b, "left", row[j - 1])
			else:
				_link(b, "left", (_nearest_row(b, left_rows) as Array).back() if not left_rows.is_empty() else b)
			if j < row.size() - 1:
				_link(b, "right", row[j + 1])
			else:
				_link(b, "right", (_nearest_row(b, right_rows) as Array).front() if not right_rows.is_empty() else b)
			if i > 0:
				var up: Array = rows[i - 1]
				_link(b, "top", up[_nearest(j, row.size(), up.size())])
			else:
				_link(b, "top", b)
			if i < rows.size() - 1:
				var down: Array = rows[i + 1]
				_link(b, "bottom", down[_nearest(j, row.size(), down.size())])
			else:
				_link(b, "bottom", below[_nearest(j, row.size(), below.size())])


## The row of `rows` whose vertical centre is nearest to `b`'s (screen
## layout), for the cross-column links.
static func _nearest_row(b: Control, rows: Array) -> Array:
	var y := b.get_global_rect().get_center().y  # Height of `b` (px).
	var best: Array = rows[0]
	var best_d := INF  # Smallest height difference so far (px).
	for row: Array in rows:
		var d := absf((row[0] as Control).get_global_rect().get_center().y - y)  # Height difference (px).
		if d < best_d:
			best_d = d
			best = row
	return best


## Index in a row of `to_n` items under item `i` of a row of `from_n` items
## (a single item maps to the middle of the other row).
static func _nearest(i: int, from_n: int, to_n: int) -> int:
	if from_n <= 1:
		return clampi(roundi(float(to_n - 1) * 0.5), 0, maxi(0, to_n - 1))
	return clampi(roundi(float(i) * float(to_n - 1) / float(from_n - 1)), 0, to_n - 1)


## Sets focus neighbour `side` ("left" / "right" / "top" / "bottom") of `b` to `to`.
static func _link(b: Control, side: String, to: Control) -> void:
	b.set("focus_neighbor_" + side, b.get_path_to(to))


## Selects difficulty `id`.
func _select_level(id: String) -> void:
	config.set_difficulty(id)
	Sfx.play("ui_confirm")
	_refresh()


## Toggles run modifier `id`.
func _toggle_mod(id: String) -> void:
	var ids := config.modifiers.duplicate()  # New modifier list.
	if ids.has(id):
		ids.remove_at(ids.find(id))
	else:
		ids.append(id)
	config.set_modifiers(ids)
	Sfx.play("ui_confirm")
	_refresh()


## Standard: the Necromancer level and no run modifiers.
func _reset_choice() -> void:
	config.set_difficulty(DifficultyData.DEFAULT_ID)
	config.set_modifiers(PackedStringArray())
	_extras.reset()  # Hyper off (the skin is kept: cosmetic).
	Sfx.play("ui_confirm")
	_refresh()


## Redraws the selection states and the total plaque.
func _refresh() -> void:
	for id: String in DifficultyData.ORDER:
		var sel := id == config.difficulty_id  # This card is the chosen level.
		UiTheme.style_button(_level_buttons[id], "button", SELECTED_ACCENT if sel else "")
		(_level_names[id] as Label).add_theme_color_override("font_color", UiTheme.TEXT_GOLD if sel else UiTheme.TEXT)
	for id: String in RunModifierData.ORDER:
		var on := config.has_modifier(id)  # This modifier is active.
		UiTheme.style_button(_mod_buttons[id], "button", ACTIVE_ACCENT if on else "")
		(_mod_pips[id] as MaskIcon).set_icon("rune_on" if on else "rune_off")
		(_mod_names[id] as Label).add_theme_color_override("font_color", Color(1.0, 0.78, 0.74) if on else UiTheme.TEXT)
	_extras.refresh()
	_set_total(DifficultyModifiers.reward_mult(config.difficulty_id, config.modifiers, config.hyper))
	var tier := Meta.oath_active_tier()  # Profane Oath tier (0 = off).
	_oath_label.text = "+ Oath %s" % DifficultyModifiers.roman(tier) if tier > 0 else ""
	_oath_label.visible = tier > 0
	_plaque.tooltip_text = _breakdown()


## Rolls the plaque's number to `total` (instant with motion off or on open).
func _set_total(total: float) -> void:
	if _total_tween != null:
		_total_tween.kill()
		_total_tween = null
	if _shown_total < 0.0 or not UiMotion.enabled() or is_equal_approx(_shown_total, total):
		_show_total(total)
		return
	_total_tween = create_tween()
	_total_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_total_tween.tween_method(_show_total, _shown_total, total, FrontDoorData.PLAQUE_COUNT_TIME) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


## Writes total `v` on the plaque (a tick when the shown hundredths change).
func _show_total(v: float) -> void:
	var text := "×%.2f" % v  # Plaque text.
	if _shown_total >= 0.0 and text != _total_label.text:
		Sfx.play("ui_tick")
	_shown_total = v
	_total_label.text = text


## The plaque's tooltip: the breakdown, the combined enemy numbers and the
## Profane Oath note.
func _breakdown() -> String:
	var lv: Dictionary = DifficultyData.LEVELS[config.difficulty_id]
	var mods_ash := DifficultyModifiers.modifiers_ash(config.modifiers)  # Summed modifier reward.
	var parts := PackedStringArray([
		"%s ×%.2f" % [String(lv["display_name"]), float(lv["ash_mult"])],
		"%d modifier%s +%d%%" % [config.modifiers.size(), "" if config.modifiers.size() == 1 else "s", roundi(mods_ash * 100.0)],
	])
	if config.hyper:
		parts.append("%s +%d%%" % [HyperData.DISPLAY_NAME, roundi(HyperData.ASH_BONUS * 100.0)])
	var out := " + ".join(parts) + "\n(plus the stage bonus, Ash Harvest and the Pact)"
	if Meta.oath_active_tier() > 0:
		out += "\nProfane Oath %s: +%d%% Soul Ash, its penalties on top" % [
			DifficultyModifiers.roman(Meta.oath_active_tier()), roundi(float(Meta.oath_active_tier()) * float(PactData.OATH_PER_TIER["ash_gain"]) * 100.0)]
	var pv := DifficultyModifiers.preview(config.difficulty_id, config.modifiers, config.hyper)  # Combined enemy multipliers.
	out += "\nFoes: HP ×%.2f (×%.2f by 0:00), damage ×%.2f (×%.2f by 0:00)\nspawn ×%.2f, speed ×%.2f, boss HP ×%.2f" % [
		float(pv["enemy_hp"]), float(pv["enemy_hp_end"]), float(pv["enemy_damage"]), float(pv["enemy_damage_end"]),
		float(pv["enemy_spawn"]), float(pv["enemy_speed"]), float(pv["boss_hp"])]
	if float(pv["elite_chance"]) > 0.0:
		out += ", trickle elites %.1f%%" % (float(pv["elite_chance"]) * 100.0)
	return out


## Begin: remember the choice (Meta save) and hand the config on.
func _start() -> void:
	Sfx.play("ui_confirm")
	Meta.remember_prerun(config)
	confirmed.emit(config)


## Restores focus to the opener and frees the screen.
func close() -> void:
	if UiMotion.is_closing(self):
		return
	closed.emit()
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	UiMotion.close(self, queue_free)  # Quick fade out, then freed.


## Esc / controller B goes back to the stage select.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
