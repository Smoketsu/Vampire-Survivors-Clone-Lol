## EndScreen — "Run Complete" victory (necromancer died AFTER surviving the
## countdown, i.e. during the Reckoning) or defeat (died before 0:00) screen
## with run statistics, Restart and Main Menu (GDD §19 MVP
## "victory/defeat states"). A second column shows the Soul Ash earned by the
## run (kept on death), its breakdown (including the Profane Pact and
## Profane Oath bonus lines), achievements unlocked and the new balance
## (Meta.award_run(), GDD §9.2).
class_name EndScreen
extends Control

## Restart button pressed.
signal restart_pressed
## Main Menu button pressed.
signal main_menu_pressed

## Big VICTORY / DEFEAT title.
var _title: Label
## One-line flavour text under the title.
var _subtitle: Label
## Multi-line run statistics.
var _stats: Label
## "+N SOUL ASH" headline.
var _ash_title: Label
## Soul Ash breakdown lines (one label per part, right column).
var _ash_lines: Label
## Soul Ash values aligned right next to _ash_lines.
var _ash_values: Label
## New Soul Ash balance and achievement unlock lines.
var _ash_total: Label
## Restart button (focused on open).
var _restart: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	add_child(UiTheme.backdrop(0.75))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(760, 0)
	panel.add_child(vb)
	_title = UiTheme.label("", 44)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)
	_subtitle = UiTheme.label("", 15, UiTheme.TEXT_DIM)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_subtitle)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	vb.add_child(cols)
	_stats = UiTheme.label("", 15)
	_stats.custom_minimum_size = Vector2(390, 0)
	cols.add_child(_stats)
	cols.add_child(_build_ash_column())
	_restart = Button.new()
	_restart.text = "Restart"
	_restart.custom_minimum_size = Vector2(0, 44)
	_restart.pressed.connect(func() -> void: restart_pressed.emit())
	vb.add_child(_restart)
	var menu := Button.new()
	menu.text = "Main Menu"
	menu.custom_minimum_size = Vector2(0, 44)
	menu.pressed.connect(func() -> void: main_menu_pressed.emit())
	vb.add_child(menu)


## Right column: Soul Ash headline, breakdown table and new balance.
func _build_ash_column() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(IconGlyph.new("soul_ash", Vector2(30, 30)))
	_ash_title = UiTheme.label("", 20, MetaGlyphs.EMBER.lightened(0.2))
	head.add_child(_ash_title)
	col.add_child(head)
	var table := HBoxContainer.new()
	_ash_lines = UiTheme.label("", 14, UiTheme.TEXT_DIM)
	_ash_lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table.add_child(_ash_lines)
	_ash_values = UiTheme.label("", 14)
	_ash_values.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	table.add_child(_ash_values)
	col.add_child(table)
	_ash_total = UiTheme.label("", 15, UiTheme.TEXT_GOLD)
	_ash_total.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ash_total.custom_minimum_size = Vector2(340, 0)
	col.add_child(_ash_total)
	return col


## Fills the Soul Ash column from summary["soul_ash"] (Meta.award_run()).
func _show_ash(ash: Dictionary) -> void:
	if ash.is_empty():
		_ash_title.text = ""
		_ash_lines.text = ""
		_ash_values.text = ""
		_ash_total.text = ""
		return
	var parts: Dictionary = ash["parts"]
	var t := int(float(ash["time_survived"]))
	var names := PackedStringArray([
		"Time survived (%d:%02d)" % [floori(float(t) / 60.0), t % 60],
		"Enemies slain (%d)" % int(ash["kill_count"]),
		"Elites slain (%d)" % int(ash["elite_count"]),
		"Sir Alaric slain",
		"Reckoning (+%d s)" % int(float(ash["reckoning_seconds"])),
	])
	var values := PackedStringArray()
	for k: String in ["time", "kills", "elites", "boss", "reckoning"]:
		values.append("+%d" % int(parts[k]))
	if int(ash["bonus"]) > 0:
		names.append("Ash Harvest (+%d%%)" % int(roundf(float(ash["bonus_pct"]) * 100.0)))
		values.append("+%d" % int(ash["bonus"]))
	if int(ash.get("pact_bonus", 0)) > 0:
		names.append("Profane Pact Lv %d (+%d%%)" % [int(ash["pact_level"]), int(roundf(float(ash["pact_pct"]) * 100.0))])
		values.append("+%d" % int(ash["pact_bonus"]))
	if int(ash.get("oath_bonus", 0)) > 0:
		names.append("Profane Oath %s (+%d%%)" % [DifficultyModifiers.roman(int(ash["oath_tier"])), int(roundf(float(ash["oath_pct"]) * 100.0))])
		values.append("+%d" % int(ash["oath_bonus"]))
	if int(ash["bounty"]) > 0:
		names.append("Achievement bounties")
		values.append("+%d" % int(ash["bounty"]))
	_ash_title.text = "+%d SOUL ASH" % (int(ash["total"]) + int(ash["bounty"]))
	_ash_lines.text = "\n".join(names)
	_ash_values.text = "\n".join(values)
	var total_lines := PackedStringArray(["Soul Ash total: %d   (kept even in death)" % int(ash["new_total"])])
	for id: String in ash["achievements"]:
		var def: Dictionary = MetaData.ACHIEVEMENTS[id]
		total_lines.append("Achievement: %s! (%s coming later)" % [def["display_name"], def["unlock"]])
	total_lines.append("Spend it in the Ossuary from the main menu.")
	_ash_total.text = "\n".join(total_lines)


## Shows the screen for a finished run (see Game.build_summary()).
func open(summary: Dictionary) -> void:
	var won: bool = summary["victory"]
	if won:
		_title.text = "VICTORY - RUN COMPLETE"
		_title.add_theme_color_override("font_color", UiTheme.TEXT_GOLD)
		_subtitle.text = "You outlasted the Covenant. The Reckoning finally claimed you."
	else:
		_title.text = "DEFEAT" if summary["reason"] != "timeout" else "TIME'S UP"
		_title.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.2))
		_subtitle.text = "The Covenant purges the necromancer... for now."
	var t := int(float(summary["time"]))
	var counts: Dictionary = summary["horde_counts"]
	var lines := PackedStringArray()
	lines.append("Time survived:  %02d:%02d" % [floori(float(t) / 60.0), t % 60])
	if won:
		var over := int(float(summary["time_past_zero"]))
		lines.append("Survived past 0:00:  +%d:%02d  (%d Reckoning waves)" % [floori(float(over) / 60.0), over % 60, int(summary["reckoning_waves"])])
	else:
		var left := ceili(float(summary["time_remaining"]))
		lines.append("Time left on the countdown:  %d:%02d" % [floori(float(left) / 60.0), left % 60])
	lines.append("Sir Alaric:  %s" % ("slain" if summary["boss_defeated"] else ("not slain" if summary["boss_spawned"] else "never arrived")))
	lines.append("Enemies slain:  %d" % int(summary["kills"]))
	lines.append("Level reached:  %d" % int(summary["level"]))
	lines.append("Army at the end:  %d" % int(summary["horde_total"]))
	var names: Dictionary = summary.get("horde_names", {})  # Class -> plural (evolution name once evolved).
	for cls: String in UnitData.CLASS_ORDER:
		if int(counts[cls]) > 0:
			lines.append("    %s: %d" % [names.get(cls, UnitData.UNITS[cls]["plural"]), int(counts[cls])])
	_stats.text = "\n".join(lines)
	_show_ash(summary.get("soul_ash", {}))
	visible = true
	_restart.grab_focus.call_deferred()
