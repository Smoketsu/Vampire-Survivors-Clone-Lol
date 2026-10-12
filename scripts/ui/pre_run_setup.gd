## PreRunSetup — the pre-run setup screen (GDD §10.2 "Select ... difficulty
## (§8.4) and modifiers (§8.5). Show the total reward multiplier from stacked
## modifiers"). The stage select opens it after a stage is chosen. It fits
## 1280 x 720 in two columns under a one-line title (GDD §15.0 "Pre-run
## setup layout"): the LEFT column is who plays (character, skin, Hyper),
## the RIGHT column how hard (difficulty, run modifiers, the totals), with
## Back / Standard / Begin across the bottom:
##   * the playable character (CharacterPicker, its own file: portrait
##     tiles and a detail panel; locked ones show their unlock condition),
##   * four difficulty cards in a 2 x 2 grid (DifficultyData, easiest to
##     hardest): name and Soul Ash multiplier, the GDD effect line and every
##     number that differs from the standard level; exactly one is selected,
##   * a grid of the eight run modifiers (RunModifierData): name, effect and
##     its Soul Ash reward; each toggles on / off and they stack,
##   * the Hyper toggle and the skin selector (PreRunHyperSkins, its own
##     file: HyperData, SkinData; Hyper stays locked until Seraphine falls),
##   * the stacked result: the TOTAL Soul Ash multiplier (difficulty x plus
##     the modifiers' rewards) and the combined enemy multipliers, plus a
##     note when a Profane Oath tier is active (it stacks on top),
##   * Back (to the stage select), Standard (Necromancer, no modifiers) and
##     Begin.
## Fully keyboard / mouse / controller navigable (arrows / D-pad move between
## cards and buttons with explicit focus neighbours, Enter / A selects or
## toggles, Esc / B goes back), in the shared UiTheme. The screen opens on
## the choices remembered in the Meta save (Meta.prerun_config) and Begin
## remembers the new ones (Meta.remember_prerun) before emitting `confirmed`
## with the finished RunConfig. All difficulty levels are open from the
## start (GDD §15.0: the GDD names no difficulty unlocks).
class_name PreRunSetup
extends Control

## Begin pressed: start a run with `config` (stage, difficulty, modifiers).
signal confirmed(config: RunConfig)
## The screen closed without starting (Back / Esc).
signal closed

## Width (px) of the left column (character, skin, Hyper).
const LEFT_WIDTH: float = 414.0
## Width (px) of the right column (difficulty, modifiers, totals).
const RIGHT_WIDTH: float = 760.0
## Gap (px) between the two columns.
const COLUMN_GAP: int = 22
## Size (px) of one difficulty card (two per row fill RIGHT_WIDTH).
const LEVEL_CARD_SIZE := Vector2(375, 92)
## Difficulty cards per grid row.
const LEVEL_COLUMNS: int = 2
## Size (px) of one run-modifier card (two per row fill RIGHT_WIDTH).
const MOD_CARD_SIZE := Vector2(375, 46)
## Run-modifier cards per grid row.
const MOD_COLUMNS: int = 2
## Border colour of the selected difficulty card.
const SELECTED_BORDER := Color(1.0, 0.84, 0.4)
## Background of the selected difficulty card.
const SELECTED_BG := Color(0.24, 0.15, 0.08, 0.97)
## Border colour of an active run-modifier card.
const ACTIVE_BORDER := Color(0.95, 0.35, 0.35)
## Background of an active run-modifier card.
const ACTIVE_BG := Color(0.26, 0.05, 0.08, 0.97)

## The config being edited (its stage is fixed; difficulty and modifiers change).
var config: RunConfig = null
## Control that gets focus back when the screen closes.
var return_focus: Control = null
## Difficulty id -> its card Button.
var _level_buttons: Dictionary = {}
## Difficulty id -> its name Label (recoloured when selected).
var _level_names: Dictionary = {}
## Run modifier id -> its card Button.
var _mod_buttons: Dictionary = {}
## Run modifier id -> its "ON" / "off" state Label.
var _mod_states: Dictionary = {}
## Headline: the total Soul Ash multiplier.
var _total_label: Label
## Breakdown of the total and the Oath note.
var _breakdown_label: Label
## Combined enemy multipliers of the current choice.
var _foes_label: Label
## Back button.
var _back: Button
## Standard (reset) button.
var _reset: Button
## Begin button (focused on open).
var _begin: Button
## The playable-character section (CharacterPicker, top of the left column).
var _picker: CharacterPicker
## Skin cards and the Hyper toggle (PreRunHyperSkins, under the picker).
var _extras: PreRunHyperSkins


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
	add_child(UiTheme.backdrop(0.9))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(head)
	head.add_child(UiTheme.label("PREPARE THE RITUAL", 22, UiTheme.TEXT_GOLD))
	var def := config.stage_def()  # The chosen stage.
	head.add_child(UiTheme.label("%s  -  %s" % [String(def["chapter"]), String(def["display_name"])], 14, UiTheme.TEXT_DIM))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", COLUMN_GAP)
	vb.add_child(cols)
	# Left column: who plays (character, skin, Hyper).
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	left.custom_minimum_size = Vector2(LEFT_WIDTH, 0)
	cols.add_child(left)
	_picker = CharacterPicker.new()
	_picker.config = config
	_picker.character_changed.connect(_on_character_changed)
	left.add_child(_picker)
	_extras = PreRunHyperSkins.new()
	_extras.config = config
	_extras.changed.connect(_refresh)
	_extras.rebuilt.connect(_queue_wire)
	left.add_child(_extras)
	# Right column: how hard (difficulty, run modifiers, the totals).
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.custom_minimum_size = Vector2(RIGHT_WIDTH, 0)
	cols.add_child(right)
	right.add_child(UiTheme.label("DIFFICULTY", 12, UiTheme.TEXT_DIM))
	var lgrid := GridContainer.new()
	lgrid.columns = LEVEL_COLUMNS
	lgrid.add_theme_constant_override("h_separation", 10)
	lgrid.add_theme_constant_override("v_separation", 8)
	right.add_child(lgrid)
	for id: String in DifficultyData.ORDER:
		lgrid.add_child(_build_level_card(id))
	right.add_child(UiTheme.label("RUN MODIFIERS  (optional, they stack; each adds Soul Ash)", 12, UiTheme.TEXT_DIM))
	var grid := GridContainer.new()
	grid.columns = MOD_COLUMNS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	right.add_child(grid)
	for id: String in RunModifierData.ORDER:
		grid.add_child(_build_mod_card(id))
	_total_label = UiTheme.label("", 20, MetaGlyphs.EMBER.lightened(0.2))
	_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(_total_label)
	_breakdown_label = _wrapped_total(13, UiTheme.TEXT_DIM)
	right.add_child(_breakdown_label)
	_foes_label = _wrapped_total(13, Palette.CRIMSON.lightened(0.45))
	right.add_child(_foes_label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	vb.add_child(buttons)
	_back = _make_button("Back", buttons, close)
	_reset = _make_button("Standard (Necromancer, no modifiers, no Hyper)", buttons, _reset_choice)
	_begin = _make_button("Begin the march", buttons, _start)
	_refresh()
	_queue_wire()
	_begin.grab_focus.call_deferred()


## A centred, word-wrapped totals line of the right column.
func _wrapped_total(size_px: int, color: Color) -> Label:
	var l := UiTheme.label("", size_px, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(RIGHT_WIDTH, 0)
	return l


## A character was chosen: its skin cards follow (PreRunHyperSkins) and the
## totals redraw.
func _on_character_changed(_id: String) -> void:
	_refresh()


## A bottom-row button that expands to share the row.
func _make_button(text: String, parent: Control, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	parent.add_child(b)
	return b


## Common card Button with a VBox of labels inside (labels ignore the mouse).
func _card(size_px: Vector2) -> Array:
	var b := Button.new()
	b.custom_minimum_size = size_px
	b.focus_mode = Control.FOCUS_ALL
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 10
	box.offset_right = -10
	box.offset_top = 4
	box.offset_bottom = -4
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	return [b, box]


## One difficulty card: name, the GDD effect line and its numbers.
func _build_level_card(id: String) -> Button:
	var lv: Dictionary = DifficultyData.LEVELS[id]
	var parts := _card(LEVEL_CARD_SIZE)
	var b: Button = parts[0]
	var box: VBoxContainer = parts[1]
	b.pressed.connect(_select_level.bind(id))
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_l := UiTheme.label(String(lv["display_name"]), 17, UiTheme.TEXT)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_l)
	head.add_child(UiTheme.label(_level_reward(lv), 12, MetaGlyphs.EMBER.lightened(0.2)))
	box.add_child(head)
	var tag := UiTheme.label(String(lv["tagline"]), 11, UiTheme.TEXT_DIM)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size = Vector2(LEVEL_CARD_SIZE.x - 20.0, 0)
	box.add_child(tag)
	var nums := UiTheme.label(_level_numbers(lv), 11, UiTheme.TEXT)
	nums.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nums.custom_minimum_size = Vector2(LEVEL_CARD_SIZE.x - 20.0, 0)
	box.add_child(nums)
	_level_buttons[id] = b
	_level_names[id] = name_l
	return b


## The reward part of level row `lv` for its card header: the Soul Ash
## multiplier and, when not standard, the XP multiplier (kept on the header
## line so it can never spill past the card's bottom edge).
static func _level_reward(lv: Dictionary) -> String:
	var out := "Soul Ash x%.2f" % float(lv["ash_mult"])  # Header text.
	if float(lv["xp_mult"]) != 1.0:
		out += "  XP x%.2f" % float(lv["xp_mult"])
	return out


## The enemy numbers of level row `lv` that differ from the standard level.
static func _level_numbers(lv: Dictionary) -> String:
	var foes := PackedStringArray()  # "HP x1.20"...
	for key: String in ["enemy_hp", "hp_scaling", "enemy_damage", "damage_scaling", "enemy_spawn", "enemy_speed", "boss_hp"]:
		if float(lv[key]) != 1.0:
			foes.append("%s x%.2f" % [DifficultyData.SHORT[key], float(lv[key])])
	if float(lv["elite_chance"]) > 0.0:
		foes.append("+%.1f%% elites" % (float(lv["elite_chance"]) * 100.0))
	return "Foes: " + (", ".join(foes) if not foes.is_empty() else "standard")


## One run-modifier card: name, Soul Ash reward and state, then the effect.
func _build_mod_card(id: String) -> Button:
	var md: Dictionary = RunModifierData.MODIFIERS[id]
	var parts := _card(MOD_CARD_SIZE)
	var b: Button = parts[0]
	var box: VBoxContainer = parts[1]
	b.pressed.connect(_toggle_mod.bind(id))
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_l := UiTheme.label(String(md["display_name"]), 15, UiTheme.TEXT)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_l)
	head.add_theme_constant_override("separation", 8)
	head.add_child(UiTheme.label("+%d%% Ash" % roundi(float(md["ash_gain"]) * 100.0), 12, MetaGlyphs.EMBER.lightened(0.2)))
	var state := UiTheme.label("", 13, UiTheme.TEXT_DIM)
	head.add_child(state)
	box.add_child(head)
	var desc := UiTheme.label(String(md["description"]), 11, UiTheme.TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(MOD_CARD_SIZE.x - 20.0, 0)
	box.add_child(desc)
	_mod_buttons[id] = b
	_mod_states[id] = state
	return b


## Wires the focus neighbours once the containers have laid the cards out
## (the cross-column links match rows by their on-screen height). Called on
## open and whenever the skin cards are rebuilt for another character.
func _queue_wire() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if is_inside_tree():
		_wire_focus()


## Explicit focus neighbours, so arrows / D-pad never leave the screen:
## inside each column the rows link up and down (left: character tiles, skin
## cards, Hyper; right: difficulty cards, modifier cards), the end of a row
## crosses to the other column's row nearest in height, the last rows lead
## down to the bottom buttons (left: Back / Standard, right: Standard /
## Begin) and the bottom buttons lead back up.
func _wire_focus() -> void:
	var left: Array = _picker.tile_rows() + _extras.rows()  # Left column rows.
	var right: Array = _rows_of(_level_buttons, DifficultyData.ORDER, LEVEL_COLUMNS) + _rows_of(_mod_buttons, RunModifierData.ORDER, MOD_COLUMNS)  # Right column rows.
	_wire_column(left, [], right, [_back, _reset])
	_wire_column(right, left, [], [_reset, _begin])
	var bottom := [_back, _reset, _begin]  # Bottom row, left to right.
	for j in bottom.size():
		var b: Button = bottom[j]
		_link(b, "left", bottom[maxi(0, j - 1)])
		_link(b, "right", bottom[mini(bottom.size() - 1, j + 1)])
		_link(b, "bottom", b)
	_link(_back, "top", (left.back() as Array).front())
	_link(_reset, "top", (right.back() as Array).front())
	_link(_begin, "top", (right.back() as Array).back())


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
## (last) card to the row of `left_rows` (`right_rows`) nearest in height
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


## Redraws the selection states and the stacked totals.
func _refresh() -> void:
	for id: String in DifficultyData.ORDER:
		var sel := id == config.difficulty_id  # This card is the chosen level.
		_style(_level_buttons[id], sel, SELECTED_BG, SELECTED_BORDER)
		(_level_names[id] as Label).add_theme_color_override("font_color", UiTheme.TEXT_GOLD if sel else UiTheme.TEXT)
		(_level_names[id] as Label).text = String(DifficultyData.LEVELS[id]["display_name"]) + ("  (chosen)" if sel else "")
	for id: String in RunModifierData.ORDER:
		var on := config.has_modifier(id)  # This modifier is active.
		_style(_mod_buttons[id], on, ACTIVE_BG, ACTIVE_BORDER)
		var st: Label = _mod_states[id]
		st.text = "ON" if on else "off"
		st.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.5) if on else UiTheme.TEXT_DIM)
	_extras.refresh()
	var lv: Dictionary = DifficultyData.LEVELS[config.difficulty_id]
	var mods_ash := DifficultyModifiers.modifiers_ash(config.modifiers)  # Summed modifier reward.
	_total_label.text = "Total Soul Ash reward:  x%.2f" % DifficultyModifiers.reward_mult(config.difficulty_id, config.modifiers, config.hyper)
	var parts := PackedStringArray([
		"%s x%.2f" % [String(lv["display_name"]), float(lv["ash_mult"])],
		"%d run modifier%s +%d%%" % [config.modifiers.size(), "" if config.modifiers.size() == 1 else "s", roundi(mods_ash * 100.0)],
	])
	if config.hyper:
		parts.append("%s +%d%%" % [HyperData.DISPLAY_NAME, roundi(HyperData.ASH_BONUS * 100.0)])
	var note := "   (the stage bonus, Ash Harvest and the Profane Pact add their own lines)"  # Breakdown tail.
	if Meta.oath_active_tier() > 0:
		note = "   (your Profane Oath %s adds +%d%% Soul Ash and its own penalties on top)" % [
			DifficultyModifiers.roman(Meta.oath_active_tier()), roundi(float(Meta.oath_active_tier()) * float(PactData.OATH_PER_TIER["ash_gain"]) * 100.0)]
	_breakdown_label.text = " + ".join(parts) + note
	var pv := DifficultyModifiers.preview(config.difficulty_id, config.modifiers, config.hyper)  # Combined enemy multipliers.
	var foes := "Foes: HP x%.2f (x%.2f by 0:00)   damage x%.2f (x%.2f by 0:00)   spawn x%.2f   speed x%.2f   boss HP x%.2f" % [
		float(pv["enemy_hp"]), float(pv["enemy_hp_end"]), float(pv["enemy_damage"]), float(pv["enemy_damage_end"]),
		float(pv["enemy_spawn"]), float(pv["enemy_speed"]), float(pv["boss_hp"])]
	if float(pv["elite_chance"]) > 0.0:
		foes += "   trickle elites %.1f%%" % (float(pv["elite_chance"]) * 100.0)
	_foes_label.text = foes


## Applies the selected / active look to card `b` (normal and hover styles).
static func _style(b: Button, on: bool, bg: Color, border: Color) -> void:
	if on:
		b.add_theme_stylebox_override("normal", UiTheme.box(bg, border, 3))
		b.add_theme_stylebox_override("hover", UiTheme.box(bg.lightened(0.08), border, 3))
	else:
		b.remove_theme_stylebox_override("normal")
		b.remove_theme_stylebox_override("hover")


## Begin: remember the choice (Meta save) and hand the config on.
func _start() -> void:
	Sfx.play("ui_confirm")
	Meta.remember_prerun(config)
	confirmed.emit(config)


## Restores focus to the opener and frees the screen.
func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	queue_free()


## Esc / controller B goes back to the stage select.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
