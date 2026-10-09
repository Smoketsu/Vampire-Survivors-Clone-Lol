## EndScreen — "Run Complete" victory (necromancer died AFTER surviving the
## countdown, i.e. during the Reckoning) or defeat (died before 0:00) screen
## with run statistics, Restart and Main Menu (GDD §19 MVP
## "victory/defeat states").
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
	vb.custom_minimum_size = Vector2(420, 0)
	panel.add_child(vb)
	_title = UiTheme.label("", 44)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)
	_subtitle = UiTheme.label("", 15, UiTheme.TEXT_DIM)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_subtitle)
	_stats = UiTheme.label("", 15)
	vb.add_child(_stats)
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
	for cls: String in UnitData.CLASS_ORDER:
		if int(counts[cls]) > 0:
			lines.append("    %s: %d" % [UnitData.UNITS[cls]["plural"], int(counts[cls])])
	_stats.text = "\n".join(lines)
	visible = true
	_restart.grab_focus.call_deferred()
