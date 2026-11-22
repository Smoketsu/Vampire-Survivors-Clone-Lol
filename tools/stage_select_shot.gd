## Stage select screenshot (GDD §15.0 "The reorder pass, part 1 (order and
## numbering)"): opens the stage select over a sample profile in memory (every
## boss slain up to the act before `--stage`, so that act's first stage is open)
## on the act of `--stage=ID` (default ravensmoor: Part One) and saves the window
## to PATH. Drawing only; nothing is saved. Needs a real window (xvfb-run):
##   godot res://tools/stage_select_shot.tscn -- --autotest --shot=PATH [--stage=ID] [--phone]
## --phone uses an 844 x 390 CSS px landscape phone at 2x with the mobile UI
## scale (TouchData.UI_SCALE_MAX). tools/.gdignore keeps it out of exports.
extends Node

## Screenshot target path.
var _shot: String = ""
## Stage whose act the screen opens on.
var _stage: String = "ravensmoor"
## Emulate a landscape phone.
var _phone: bool = false


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot = a.trim_prefix("--shot=")
		elif a.begins_with("--stage="):
			_stage = a.trim_prefix("--stage=")
		elif a == "--phone":
			_phone = true
	if _shot == "" or not StageRegistry.STAGES.has(_stage):
		push_error("stage_select_shot needs --shot=PATH and a known --stage=ID")
		get_tree().quit(2)
		return
	var win := get_window()
	if _phone:
		win.size = Vector2i(1688, 780)  # 844 x 390 CSS px at 2x (a landscape phone).
		win.content_scale_factor = TouchData.UI_SCALE_MAX
	else:
		win.size = Vector2i(1280, 720)
	Meta._reset()
	for id: String in StageRegistry.ORDER:
		if id == _stage:
			break
		(Meta.stage_records[id] as Dictionary)["boss_kills"] = 1.0
		(Meta.stage_records[id] as Dictionary)["best_time"] = 1250.0
	GameState.last_stage_id = _stage
	var bg := ColorRect.new()  # The main menu is not behind it here: a plain dark ground.
	bg.color = Color(0.05, 0.04, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(bg)
	add_child(holder)
	StageSelect.open_over(holder, null)
	for i in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_shot.get_base_dir())
	var err := img.save_png(_shot)
	print("[stage_select_shot] %s (%dx%d): %s" % [_shot, img.get_width(), img.get_height(), error_string(err)])
	Meta._reset()
	get_tree().quit(0 if err == OK else 1)
