## CoopWaitBridge — the lockstep driver's way to the "waiting for partner"
## overlay (co-op milestone 2). The overlay itself is the HUD agent's CoopUi
## component (branch coop-hud: show_waiting(text) / clear_waiting()); this
## bridge finds it at run time so the two branches merge without either
## naming the other's class:
##   1. the HUD's `coop_ui` property, when the HUD has one with those methods;
##   2. else a global script class named CoopUi (ProjectSettings' class list),
##      built here and added to the run's UI root;
##   3. else a small fallback (one centred line on a cut-corner kit panel,
##      UiTheme BODY tier), so the waiting states show before the merge too.
## Visual only: nothing here touches gameplay.
class_name CoopWaitBridge
extends RefCounted

## Global class name of the HUD agent's overlay component.
const COOP_UI_CLASS: String = "CoopUi"
## Fallback band: width and height (layout px), top offset from the screen centre (px), opacity (0-1).
const STUB_WIDTH: float = 560.0  # TUNING (not in GDD) fallback only
const STUB_HEIGHT: float = 48.0  # TUNING (not in GDD) fallback only
const STUB_OFFSET_Y: float = -150.0  # TUNING (not in GDD) fallback only
const STUB_ALPHA: float = 0.92  # TUNING (not in GDD) fallback only

## The overlay object in use (a CoopUi, or the fallback band).
var _target: Object = null


func _init(game: Game) -> void:
	if game == null or game.hud == null:
		return
	var from_hud: Variant = game.hud.get("coop_ui")  # 1. The HUD's own instance.
	if from_hud is Object and (from_hud as Object).has_method("show_waiting"):
		_target = from_hud
		return
	for c: Dictionary in ProjectSettings.get_global_class_list():  # 2. The class, built here.
		if String(c.get("class", "")) == COOP_UI_CLASS:
			var script := load(String(c["path"])) as Script
			var inst: Object = script.new() if script != null else null
			if inst is Node and inst.has_method("show_waiting"):
				if "game" in inst:
					inst.set("game", game)
				game.hud.get_parent().add_child(inst)
				_target = inst
				return
	_target = _make_stub(game.hud.get_parent())  # 3. The fallback.


## Shows `text` as the waiting line.
func show_waiting(text: String) -> void:
	if _target == null:
		return
	if _target.has_method("show_waiting"):
		_target.call("show_waiting", text)
	elif _target is Control:
		var band := _target as Control
		(band.get_child(0) as Label).text = text
		band.visible = true


## Hides the waiting line.
func clear_waiting() -> void:
	if _target == null:
		return
	if _target.has_method("clear_waiting"):
		_target.call("clear_waiting")
	elif _target is Control:
		(_target as Control).visible = false


## The fallback band under `root` (hidden until show_waiting()): a cut-corner
## kit panel (UiTheme "panel", violet) across the middle of the screen.
static func _make_stub(root: Node) -> Control:
	var band := PanelContainer.new()
	band.add_theme_stylebox_override("panel", UiTheme.style("panel", "violet"))
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.anchor_left = 0.5
	band.anchor_right = 0.5
	band.anchor_top = 0.5
	band.anchor_bottom = 0.5
	band.offset_left = -STUB_WIDTH * 0.5
	band.offset_right = STUB_WIDTH * 0.5
	band.offset_top = STUB_OFFSET_Y
	band.offset_bottom = STUB_OFFSET_Y + STUB_HEIGHT
	band.modulate.a = STUB_ALPHA
	var line := UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_GOLD)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	band.add_child(line)
	band.visible = false
	root.add_child(band)
	return band
