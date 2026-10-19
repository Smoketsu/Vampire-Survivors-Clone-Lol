## EndScreen — the results card of a finished run: "Victory" (the
## necromancer died AFTER surviving the countdown, i.e. during the Reckoning)
## or "Defeat" (died before 0:00), with Restart and Main Menu (GDD §19 MVP
## "victory/defeat states"). It shows the Soul Ash earned (kept on death),
## its breakdown (including the Profane Pact and Oath lines, the difficulty
## level line (negative on Initiate), the run modifiers line, Hyper mode's
## own +100% line and the stage bonus) and the new balance (Meta.award_run(),
## GDD §9.2, §9.3), and everything the run unlocked.
##
## Layout (menu modernization wave 2, numbers in InRunUiData): an ornate
## panel, gold on a victory and crimson on a defeat (gold = victory, crimson
## = defeat), with the title on a ribbon plate in the TITLE tier and one line
## of flavour under it, then three columns:
##   * the character portrait (its sprite or worn skin at a whole-number
##     scale, crisp, on the stage's floor tile in a recessed frame), with the
##     character's name, the stage and the difficulty (crimson when not the
##     standard run; "+ Hyper" included);
##   * key stats as a 2 x 2 grid of tiles (time survived, with the Reckoning
##     time on a victory; enemies slain; level; the stage boss slain / alive
##     / absent), then the build as icon rows with level pips (spells,
##     passives) and the army as class icons with unit counts (RunBuild;
##     read from the run, `game`, when it is set);
##   * the Soul Ash: a HERO number that counts up with ticks
##     (UiMotion.count_up), each bonus line ticking in one after another,
##     and the new balance;
## and under the columns every unlock of the run (a new character, stage,
## skin, Hyper mode or Hyper clear badge, achievements) as small gold plates.
## Restart (R / pad X) and Main Menu (Esc / pad B) carry their InputHints
## chips. Every motion is instant under the autotest and "Reduce motion".
##
## Victory path (content wave 2, GDD §15.0 "Victory screen (content wave 2)";
## texts and sizes in VictoryData, numbers from VictoryResults, widgets from
## VictoryCard; the defeat card above is unchanged): the ribbon carries the
## stage's victory title, a slot for the player's title (empty and hidden until
## the achievement-reward titles fill it), then the stage boss's line when the
## boss fell (else the act's line); the portrait gives way to the stage seal
## (the stage-select vignette, gold on a Hyper clear) over the same character /
## stage / difficulty lines; the middle column shows the time survived past
## 0:00 with the stage's Best record and a "New record" ribbon, two stat tiles
## and the run highlights; the Soul Ash column and the unlock plates are the
## shared ones; the buttons are Next (the next stage with the same pre-run
## choices, shown only when that stage is unlocked and playable; N / pad Y),
## Again (R / pad X) and Menu (Esc / pad B). `victory_info` keeps the last
## VictoryResults.build() result (the autotest prints it).
class_name EndScreen
extends Control

## Restart button pressed.
signal restart_pressed
## Main Menu button pressed.
signal main_menu_pressed
## Victory card: Next pressed, start stage `stage_id` (VictoryResults.next_stage()).
signal next_pressed(stage_id: String)

## Owning run, read for the build and army icons (set by Game; may be null,
## then the build rows are left out and the army comes from the summary).
var game: Game
## The ornate frame (gold on a victory, crimson on a defeat).
var _panel: PanelContainer
## The ribbon plate behind the title.
var _ribbon: PanelContainer
## Big Victory / Defeat title.
var _title: Label
## One-line flavour text under the title.
var _subtitle: Label
## The character portrait.
var _portrait: Portrait
## Character name under the portrait.
var _char_name: Label
## Stage name under the portrait.
var _stage_name: Label
## Difficulty line under the portrait.
var _difficulty: Label
## The 2 x 2 grid of stat tiles (rebuilt on open).
var _stats_grid: GridContainer
## Build and army rows (rebuilt on open).
var _build_box: VBoxContainer
## "+N" Soul Ash headline (counts up).
var _ash_value: Label
## The Soul Ash breakdown lines (rebuilt on open; tick in one by one).
var _ash_lines: VBoxContainer
## New balance line.
var _ash_total: Label
## The unlock plates under the columns (rebuilt on open; hidden when none).
var _toasts: HFlowContainer
## Restart button (focused on open).
var _restart: Button
## Main Menu button.
var _menu: Button

# --- Content wave 2: A. Victory screen (the victory path) -----------------------------

## VictoryResults.build() of the last victory shown ({} = none yet / a defeat).
var victory_info: Dictionary = {}
## Stage the Next button starts ("" = no next stage: the button is hidden).
var _next_stage: String = ""
## The player's worn title under the victory title (an achievement-reward
## title, TitleData; hidden when none is worn).
var player_title: Label
## The portrait column (its portrait gives way to the seal on a victory).
var _portrait_col: VBoxContainer
## Holder of the stage seal in the portrait column (rebuilt on a victory).
var _seal_box: VBoxContainer
## The defeat card's middle column (stat tiles, build and army).
var _stats_col: VBoxContainer
## The victory card's middle column holder (rebuilt on a victory).
var _victory_box: VBoxContainer
## Defeat buttons row (Restart, Main Menu).
var _defeat_buttons: HBoxContainer
## Victory buttons row (Next, Again, Menu).
var _victory_buttons: HBoxContainer
## Victory: Next button (hidden without a next stage).
var _next: Button
## Victory: Again button (the same stage and pre-run choices).
var _again: Button
## Victory: Menu button.
var _vmenu: Button
## The Soul Ash column frame (narrower on the victory card).
var _ash_frame: Control


## The character portrait: the stage's floor tile (darkened) in the kit's
## recessed slot frame, a soft shadow, and the character (or its worn skin)
## at the largest whole-number scale up to END_PORTRAIT_SCALE that fits.
class Portrait:
	extends Control
	## CharacterData id of the run's character.
	var character_id: String = ""
	## Worn skin id ("" = the character's own look).
	var skin_id: String = ""
	## Floor tile drawn behind (null = a flat dark fill).
	var tile: Texture2D = null

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED  # The floor tile repeats.

	func _ready() -> void:
		SpriteBank.apply_sharp(self)

	## Sprite key the portrait's character is drawn with (for its height).
	func _sprite_key() -> String:
		if skin_id != "" and SpriteBank.has(String(SkinData.skin(skin_id).get("sprite", ""))):
			return String(SkinData.skin(skin_id)["sprite"])
		if character_id != "" and character_id != CharacterData.DEFAULT_ID and CharacterModifiers.is_known(character_id):
			return CharacterGlyphs.drawn_sprite_key(character_id)
		return "player/necromancer"

	func _draw() -> void:
		var frame := UiTheme.style("slot")  # Recessed kit frame, under the picture.
		if frame is StyleBoxTexture:
			draw_style_box(frame, Rect2(Vector2.ZERO, size))
		var r := Rect2(Vector2.ONE * 3.0, size - Vector2.ONE * 6.0)  # The picture, inside the frame ring.
		var d := 1.0 - InRunUiData.PORTRAIT_TILE_DARKEN  # Tile brightness.
		if tile != null:
			draw_texture_rect(tile, r, true, Color(d, d, d))
		else:
			draw_rect(r, Color(0.05, 0.03, 0.08))
		draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.45)), Color(0.02, 0.0, 0.04, 0.45))  # Darker sky band.
		var key := _sprite_key()
		var tex := SpriteBank.texture(key)  # For the scale (null = glyph drawing).
		var cap := minf(r.size.x, r.size.y) - 10.0  # Largest square the sprite may fill (px).
		if tex != null:
			cap = minf(cap, float(maxi(tex.get_width(), tex.get_height()) * InRunUiData.END_PORTRAIT_SCALE))
		SpriteBank.icon_cap = cap
		var h := SpriteBank.drawn_height(key)  # Drawn height (px).
		var feet := r.end.y - 9.0  # Feet line (px).
		var c := Vector2(roundf(r.get_center().x), roundf(feet - h * 0.5))  # Sprite centre.
		draw_set_transform(Vector2(c.x, feet), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, h * 0.32, Color(0, 0, 0, 0.45))  # Shadow at the feet.
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if skin_id == "" or not SkinGlyphs.draw_skin(self, skin_id, c, h * 0.3, false):
			CharacterGlyphs.draw_player(self, character_id, c, h * 0.3, false)
		SpriteBank.icon_cap = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	add_child(UiTheme.backdrop(0.8))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit (no-op at 720 px).
	_panel = UiTheme.ornate_panel("gold")
	center.add_child(_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_panel.add_child(vb)
	_ribbon = UiTheme.ribbon("gold")
	_ribbon.custom_minimum_size = Vector2(InRunUiData.END_RIBBON_WIDTH, 0)
	_ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(_ribbon)
	_title = UiTheme.title("")
	_ribbon.add_child(_title)
	player_title = UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT_GOLD)  # Victory: the player's title slot (empty = hidden).
	player_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_title.visible = false
	vb.add_child(player_title)
	_subtitle = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_subtitle)
	var cols := HBoxContainer.new()  # Portrait | stats + build | Soul Ash.
	cols.add_theme_constant_override("separation", InRunUiData.END_GAP)
	vb.add_child(cols)
	_portrait_col = _build_portrait_column()
	cols.add_child(_portrait_col)
	_stats_col = _build_stats_column()
	cols.add_child(_stats_col)
	_victory_box = VBoxContainer.new()  # Victory middle column (VictoryCard.middle()).
	_victory_box.visible = false
	cols.add_child(_victory_box)
	_ash_frame = _build_ash_column()
	cols.add_child(_ash_frame)
	_toasts = HFlowContainer.new()  # Wraps two or three plates per line.
	_toasts.alignment = FlowContainer.ALIGNMENT_CENTER
	_toasts.add_theme_constant_override("h_separation", 8)
	_toasts.add_theme_constant_override("v_separation", 6)
	vb.add_child(_toasts)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	vb.add_child(buttons)
	_defeat_buttons = buttons
	_restart = _button(buttons, "Restart", InputHints.raw(KEY_R, JOY_BUTTON_X), func() -> void: restart_pressed.emit())
	_menu = _button(buttons, "Main Menu", "ui_cancel", func() -> void: main_menu_pressed.emit())
	_menu.set_meta(&"ui_back", true)  # Plays the back sound (UiMotion / Sfx).
	_victory_buttons = HBoxContainer.new()  # Victory: Next, Again, Menu (one word each).
	_victory_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_victory_buttons.add_theme_constant_override("separation", 18)
	_victory_buttons.visible = false
	vb.add_child(_victory_buttons)
	_next = _button(_victory_buttons, VictoryData.BUTTON_NEXT, InputHints.raw(KEY_N, JOY_BUTTON_Y), func() -> void: _on_next())
	_again = _button(_victory_buttons, VictoryData.BUTTON_AGAIN, InputHints.raw(KEY_R, JOY_BUTTON_X), func() -> void: restart_pressed.emit())
	_vmenu = _button(_victory_buttons, VictoryData.BUTTON_MENU, "ui_cancel", func() -> void: main_menu_pressed.emit())
	_vmenu.set_meta(&"ui_back", true)  # Plays the back sound (UiMotion / Sfx).
	for b: Button in [_next, _again, _vmenu]:
		b.custom_minimum_size = Vector2(VictoryData.BUTTON_WIDTH, VictoryData.BUTTON_HEIGHT)


## A results button with the key chip of `spec` inside its left edge.
func _button(parent: Control, text: String, spec: Variant, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(InRunUiData.END_BUTTON_WIDTH, 44)
	b.pressed.connect(cb)
	InputHints.attach(b, spec)
	parent.add_child(b)
	return b


## Left column: the portrait and the character / stage / difficulty lines.
func _build_portrait_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.custom_minimum_size = Vector2(InRunUiData.END_PORTRAIT_WIDTH, 0)
	_portrait = Portrait.new()
	_portrait.custom_minimum_size = Vector2(InRunUiData.END_PORTRAIT_WIDTH, InRunUiData.END_PORTRAIT_HEIGHT)
	col.add_child(_portrait)
	_seal_box = VBoxContainer.new()  # Victory: the stage seal (VictoryCard.seal()).
	_seal_box.visible = false
	col.add_child(_seal_box)
	var gap := Control.new()  # Air under the frame.
	gap.custom_minimum_size = Vector2(0, 4)
	col.add_child(gap)
	_char_name = UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT)
	_stage_name = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_difficulty = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	for l: Label in [_char_name, _stage_name, _difficulty]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(InRunUiData.END_PORTRAIT_WIDTH, 0)
		col.add_child(l)
	return col


## Middle column: the stat tiles, then the build and the army.
func _build_stats_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.custom_minimum_size = Vector2(InRunUiData.END_STATS_WIDTH, 0)
	_stats_grid = GridContainer.new()
	_stats_grid.columns = 2
	_stats_grid.add_theme_constant_override("h_separation", 8)
	_stats_grid.add_theme_constant_override("v_separation", 8)
	col.add_child(_stats_grid)
	_build_box = VBoxContainer.new()
	_build_box.add_theme_constant_override("separation", 4)
	col.add_child(_build_box)
	return col


## Right column: the Soul Ash headline, its breakdown lines and the balance.
func _build_ash_column() -> Control:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiTheme.style("panel", "dim"))
	frame.custom_minimum_size = Vector2(InRunUiData.END_ASH_WIDTH, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	frame.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)
	var icon := IconGlyph.new("soul_ash", Vector2(40, 40))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(icon)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", -6)
	head.add_child(hv)
	hv.add_child(UiTheme.tier_label("Soul Ash", UiTheme.Tier.LABEL, MetaGlyphs.EMBER.lightened(0.15)))
	_ash_value = UiTheme.tier_label("", UiTheme.Tier.HERO, MetaGlyphs.EMBER.lightened(0.3))
	hv.add_child(_ash_value)
	col.add_child(UiTheme.divider("violet"))
	_ash_lines = VBoxContainer.new()
	_ash_lines.add_theme_constant_override("separation", 0)
	col.add_child(_ash_lines)
	col.add_child(UiTheme.divider("violet"))
	_ash_total = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_GOLD)
	col.add_child(_ash_total)
	return frame


## One stat tile: a LABEL caption over a NAME value in `color`, with an
## optional BODY `extra` beside the value.
func _tile(caption: String, value: String, color: Color = UiTheme.TEXT, extra: String = "", extra_color: Color = UiTheme.TEXT_DIM) -> Control:
	var t := PanelContainer.new()
	t.add_theme_stylebox_override("panel", UiTheme.style("panel", "dim"))
	t.custom_minimum_size = Vector2((InRunUiData.END_STATS_WIDTH - 8.0) * 0.5, InRunUiData.END_TILE_HEIGHT)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", -2)
	t.add_child(vb)
	var cap := RunBuild.caption(caption)
	cap.clip_text = true
	cap.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vb.add_child(cap)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)
	row.add_child(UiTheme.tier_label(value, UiTheme.Tier.NAME, color))
	if extra != "":
		var e := UiTheme.tier_label(extra, UiTheme.Tier.BODY, extra_color)
		e.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(e)
	return t


## Fills the stat tiles from `summary`.
func _show_stats(summary: Dictionary) -> void:
	RunBuild.clear(_stats_grid)
	var won: bool = summary["victory"]
	var t := float(summary["time"])  # Seconds survived.
	if won:
		_stats_grid.add_child(_tile("Survived", RunBuild.clock(t), UiTheme.TEXT, "+%s past 0:00" % RunBuild.clock(float(summary["time_past_zero"])), UiTheme.TEXT_GOLD))
	else:
		_stats_grid.add_child(_tile("Survived", RunBuild.clock(t), UiTheme.TEXT, "%s left" % RunBuild.clock(ceilf(float(summary["time_remaining"])))))
	_stats_grid.add_child(_tile("Enemies slain", "%d" % int(summary["kills"])))
	_stats_grid.add_child(_tile("Level", "%d" % int(summary["level"])))
	var boss := String(summary.get("boss_name", "Sir Alaric"))  # The stage boss.
	if bool(summary["boss_defeated"]):
		_stats_grid.add_child(_tile(boss, "Slain", UiTheme.TEXT_GOLD))
	elif bool(summary["boss_spawned"]):
		_stats_grid.add_child(_tile(boss, "Alive", Palette.CRIMSON.lightened(0.4)))
	else:
		_stats_grid.add_child(_tile(boss, "Never came", UiTheme.TEXT_DIM))


## Fills the build and army rows: from the run (`game`) when it is set, the
## army from `summary` otherwise.
func _show_build(summary: Dictionary) -> void:
	RunBuild.clear(_build_box)
	if game != null:
		var build: Array[Dictionary] = RunBuild.spells(game)
		if not build.is_empty():
			_build_box.add_child(RunBuild.caption("Spells"))
			_build_box.add_child(RunBuild.icon_row(build, InRunUiData.END_ICON))
		var pas := RunBuild.passives(game)
		if not pas.is_empty():
			_build_box.add_child(RunBuild.caption("Passives"))
			_build_box.add_child(RunBuild.icon_row(pas, InRunUiData.END_ICON))
	var army: Array[Dictionary] = RunBuild.army(game) if game != null else _summary_army(summary)
	if not army.is_empty():
		_build_box.add_child(RunBuild.caption("Army  %d" % int(summary["horde_total"])))
		_build_box.add_child(RunBuild.army_row(army, InRunUiData.END_ICON))


## The army entries (RunBuild.army() format) from `summary` alone.
static func _summary_army(summary: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var counts: Dictionary = summary.get("horde_counts", {})
	var names: Dictionary = summary.get("horde_names", {})
	for cls: String in UnitData.CLASS_ORDER:
		if int(counts.get(cls, 0)) > 0:
			out.append({"icon": cls, "level": 1, "count": int(counts[cls]), "name": String(names.get(cls, cls))})
	return out


## Fills the Soul Ash column from summary["soul_ash"] (Meta.award_run());
## `boss_name` names the stage boss's line. Returns the unlock plate texts
## found in it (stages, Hyper, skins, achievements).
func _show_ash(ash: Dictionary, boss_name: String) -> PackedStringArray:
	RunBuild.clear(_ash_lines)
	var unlocks := PackedStringArray()
	if ash.is_empty():
		_ash_value.text = ""
		_ash_total.text = ""
		return unlocks
	var parts: Dictionary = ash["parts"]
	var t := float(ash["time_survived"])
	var lines: Array = [  # [name, value text] per breakdown line.
		["Time survived (%s)" % RunBuild.clock(t), "+%d" % int(parts["time"])],
		["Enemies slain (%d)" % int(ash["kill_count"]), "+%d" % int(parts["kills"])],
		["Elites slain (%d)" % int(ash["elite_count"]), "+%d" % int(parts["elites"])],
		["%s slain" % boss_name, "+%d" % int(parts["boss"])],
		["Reckoning (+%d s)" % int(float(ash["reckoning_seconds"])), "+%d" % int(parts["reckoning"])],
	]
	if int(parts.get("objectives", 0)) > 0:
		lines.append(["Stage objectives", "+%d" % int(parts["objectives"])])  # The Sanctum's chambers and altars.
	if int(ash["bonus"]) > 0:
		lines.append(["Ash Harvest (+%d%%)" % int(roundf(float(ash["bonus_pct"]) * 100.0)), "+%d" % int(ash["bonus"])])
	if int(ash.get("pact_bonus", 0)) > 0:
		lines.append(["Profane Pact Lv %d (+%d%%)" % [int(ash["pact_level"]), int(roundf(float(ash["pact_pct"]) * 100.0))], "+%d" % int(ash["pact_bonus"])])
	if int(ash.get("oath_bonus", 0)) > 0:
		lines.append(["Profane Oath %s (+%d%%)" % [DifficultyModifiers.roman(int(ash["oath_tier"])), int(roundf(float(ash["oath_pct"]) * 100.0))], "+%d" % int(ash["oath_bonus"])])
	if int(ash.get("difficulty_bonus", 0)) != 0:
		lines.append(["%s (%+d%%)" % [String(ash["difficulty_name"]), int(roundf(float(ash["difficulty_pct"]) * 100.0))], "%+d" % int(ash["difficulty_bonus"])])
	if int(ash.get("modifiers_bonus", 0)) > 0:
		lines.append(["Run modifiers x%d (+%d%%)" % [int(ash["modifier_count"]), int(roundf(float(ash["modifiers_pct"]) * 100.0))], "+%d" % int(ash["modifiers_bonus"])])
	if int(ash.get("hyper_bonus", 0)) > 0:
		lines.append(["%s (+%d%%)" % [HyperData.DISPLAY_NAME, int(roundf(float(ash["hyper_pct"]) * 100.0))], "+%d" % int(ash["hyper_bonus"])])
	if int(ash.get("stage_bonus", 0)) > 0:
		lines.append(["Stage bonus (x%.2f)" % (1.0 + float(ash["stage_pct"])), "+%d" % int(ash["stage_bonus"])])
	if int(ash["bounty"]) > 0:
		lines.append(["Achievement bounties", "+%d" % int(ash["bounty"])])
	var rows: Array = []  # Line Controls, for the tick-in.
	for ln: Array in lines:
		var row := HBoxContainer.new()
		var n := UiTheme.tier_label(String(ln[0]), UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(n)
		var v := UiTheme.tier_label(String(ln[1]), UiTheme.Tier.BODY, UiTheme.TEXT if not String(ln[1]).begins_with("-") else Palette.CRIMSON.lightened(0.4))
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(v)
		_ash_lines.add_child(row)
		rows.append(row)
	UiMotion.stagger(rows, InRunUiData.ASH_LINES_DELAY, InRunUiData.ASH_LINE_INTERVAL, UiMotionData.LIST_SLIDE_OFFSET)
	UiMotion.count_up(_ash_value, int(ash["total"]) + int(ash["bounty"]), "+%d")  # Rolls up with ticks.
	_ash_total.text = "Balance  %d   ·   kept in death" % int(ash["new_total"])
	for id: String in ash["achievements"]:
		unlocks.append("Achievement: %s" % String(MetaData.ACHIEVEMENTS[id]["display_name"]))
	for sid: String in ash.get("unlocked_stages", PackedStringArray()):
		unlocks.append("New stage: %s" % String(StageRegistry.STAGES[sid]["display_name"]))
	for item: String in ash.get("unlocked_items", PackedStringArray()):
		unlocks.append(_item_plate(item))  # Act II spells, passives and summon classes (UnlockData).
	if bool(ash.get("hyper_unlocked", false)):
		unlocks.append("Hyper mode unlocked")
	var cleared := String(ash.get("hyper_clear", ""))  # Stage first cleared on Hyper by this character.
	if cleared != "" and StageRegistry.STAGES.has(cleared):
		unlocks.append("Hyper clear: %s" % String(StageRegistry.STAGES[cleared]["display_name"]))
	for sk: String in ash.get("unlocked_skins", PackedStringArray()):
		unlocks.append("New skin: %s" % String(SkinData.skin(sk)["display_name"]))
	return unlocks


## Plate text of a newly unlocked item (UnlockData): "<heading>: <name>"
## ("Spell unlocked", ...; content wave 2: "Ultimate unlocked", "Title
## earned", "Skin unlocked").
static func _item_plate(id: String) -> String:
	var row: Dictionary = UnlockData.UNLOCKS.get(id, {})
	var heading := String(UnlockData.PLATE_HEADINGS.get(String(row.get("type", "")), "Unlocked"))  # "Spell unlocked"...
	return "%s: %s" % [heading, Unlocks.item_name(id)]  # Its name (content wave 2: ultimates, titles and skins too).


## Fills the unlock plates with `texts` (hidden when empty); they rise in
## after the Soul Ash count.
func _show_toasts(texts: PackedStringArray) -> void:
	RunBuild.clear(_toasts)
	_toasts.visible = not texts.is_empty()
	var plates: Array = []  # The plates, for their entrance.
	for s: String in texts:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiTheme.style("button", "gold"))
		p.add_child(UiTheme.tier_label(s, UiTheme.Tier.BODY, UiTheme.TEXT_GOLD))
		_toasts.add_child(p)
		plates.append(p)
	UiMotion.stagger(plates, InRunUiData.TOAST_DELAY)


## Shows the screen for a finished run (see Game.build_summary()).
func open(summary: Dictionary) -> void:
	var won: bool = summary["victory"]
	var accent := "gold" if won else "crimson"  # Gold = victory, crimson = defeat.
	_panel.add_theme_stylebox_override("panel", UiTheme.style("ornate", accent))
	_ribbon.add_theme_stylebox_override("panel", UiTheme.style("ribbon", accent))
	if won:
		_title.text = "Victory"
		_title.add_theme_color_override("font_color", UiTheme.TEXT_GOLD)
		_subtitle.text = "You outlasted the Covenant. The Reckoning claimed you at last."
	else:
		_title.text = "Defeat" if summary["reason"] != "timeout" else "Time's Up"
		_title.add_theme_color_override("font_color", UiTheme.HEADER_TEXT["crimson"])
		_subtitle.text = "The Covenant purges the necromancer... for now."
	var stage_id := String(summary.get("stage_id", "graveyard"))
	_portrait.character_id = String(summary.get("character_id", CharacterData.DEFAULT_ID))
	_portrait.skin_id = String(summary.get("skin_id", ""))
	_portrait.tile = UiFx.sharp_texture("res://assets/sprites/%s.png" % String(InRunUiData.STAGE_TILES.get(stage_id, "tiles/graveyard")))
	_portrait.queue_redraw()
	_char_name.text = String(summary.get("character_name", "The Gravecaller"))
	_stage_name.text = String(summary.get("stage_name", "The Desecrated Graveyard"))
	_show_victory(summary if won else {})  # Victory path (content wave 2); a defeat restores the defeat layout.
	var label := String(summary.get("difficulty_label", summary.get("difficulty_name", "Necromancer")))  # Difficulty (+ Hyper).
	var mods: PackedStringArray = summary.get("modifier_names", PackedStringArray())  # Active run modifiers.
	var standard := String(summary.get("difficulty_id", "necromancer")) == "necromancer" and mods.is_empty() and not bool(summary.get("hyper", false))
	_difficulty.text = label + ("" if mods.is_empty() else " · %d modifier%s" % [mods.size(), "" if mods.size() == 1 else "s"])
	_difficulty.add_theme_color_override("font_color", UiTheme.TEXT_DIM if standard else Palette.CRIMSON.lightened(0.45))
	if not won:
		_show_stats(summary)
		_show_build(summary)
	var unlocks := PackedStringArray()  # Unlock plates: characters first.
	for cid: String in summary.get("unlocked_characters", PackedStringArray()):
		unlocks.append("New character: %s" % String(CharacterModifiers.def(cid)["display_name"]))
	unlocks.append_array(_show_ash(summary.get("soul_ash", {}), String(summary.get("boss_name", "Sir Alaric"))))
	_show_toasts(unlocks)
	UiMotion.open(self)  # Fade / rise in (makes it visible).
	if won:
		UiMotion.stagger([_seal_box], 0.15)  # The seal stamps in.
		(_next if _next.visible else _again).grab_focus.call_deferred()
	else:
		_restart.grab_focus.call_deferred()


## The victory path for `summary` (a won run), or back to the defeat layout
## when `summary` is empty: title, boss / act line, seal, middle column,
## buttons (see the header).
func _show_victory(summary: Dictionary) -> void:
	var won := not summary.is_empty()
	_portrait.visible = not won
	_seal_box.visible = won
	_stats_col.visible = not won
	_victory_box.visible = won
	_defeat_buttons.visible = not won
	_victory_buttons.visible = won
	_portrait_col.custom_minimum_size.x = FrontDoorData.VIGNETTE_SIZE.x + 8.0 if won else InRunUiData.END_PORTRAIT_WIDTH
	for l: Label in [_char_name, _stage_name, _difficulty]:
		l.custom_minimum_size.x = _portrait_col.custom_minimum_size.x
	_ribbon.custom_minimum_size.x = VictoryData.RIBBON_WIDTH if won else InRunUiData.END_RIBBON_WIDTH
	_ash_frame.custom_minimum_size.x = VictoryData.ASH_WIDTH if won else InRunUiData.END_ASH_WIDTH
	player_title.text = TitleData.display_text(Meta.selected_title()) if won else ""  # The worn title ("" = none).
	player_title.visible = won and player_title.text != ""
	if not won:
		victory_info = {}
		_subtitle.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
		return
	victory_info = VictoryResults.build(summary)
	_title.text = String(victory_info["title"])
	var boss_line := String(victory_info["boss_line"])  # "" while the boss lives.
	_subtitle.text = boss_line if boss_line != "" else String(victory_info["line"])
	_subtitle.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if boss_line != "" else UiTheme.TEXT_DIM)
	RunBuild.clear(_seal_box)
	_seal_box.add_child(VictoryCard.seal(victory_info))
	RunBuild.clear(_victory_box)
	var mid: Array = VictoryCard.middle(victory_info, summary)  # [column, record ribbon or null].
	_victory_box.add_child(mid[0] as Control)
	if mid[1] != null:
		UiMotion.stagger([mid[1]], VictoryData.RECORD_DELAY)  # "New record" stamps in.
	_next_stage = VictoryResults.next_stage(String(victory_info["stage_id"]))
	_next.visible = _next_stage != ""
	if _next.visible:
		_next.tooltip_text = String(StageRegistry.STAGES[_next_stage]["display_name"])


## Victory card: Next (only while a next stage exists).
func _on_next() -> void:
	if _next_stage != "":
		next_pressed.emit(_next_stage)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or UiMotion.is_closing(self):
		return
	var key := event as InputEventKey
	var pad := event as InputEventJoypadButton
	if (key != null and key.pressed and not key.echo and key.physical_keycode == KEY_R) \
			or (pad != null and pad.pressed and pad.button_index == JOY_BUTTON_X):
		get_viewport().set_input_as_handled()
		restart_pressed.emit()
	elif _victory_buttons.visible and _next.visible and ((key != null and key.pressed and not key.echo and key.physical_keycode == KEY_N)
			or (pad != null and pad.pressed and pad.button_index == JOY_BUTTON_Y)):
		get_viewport().set_input_as_handled()
		_on_next()  # Victory card: Next.
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		main_menu_pressed.emit()
