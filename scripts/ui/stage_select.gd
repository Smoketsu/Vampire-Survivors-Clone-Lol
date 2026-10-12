## StageSelect — the stage-select screen opened by Play (GDD §10.2 "Select
## stage: Graveyard, Crimson March or Sanctum (progression-locked
## initially)"). One card per StageRegistry stage: chapter, name, a short
## description, a code-drawn emblem, and either the lock requirement (GDD
## §9.3: defeat the previous stage's boss) or the stage's best time, boss
## kills and Soul Ash bonus (Meta.stage_record()). Keyboard, mouse and
## controller navigable (arrows / D-pad between cards, Enter / A to march,
## Esc / B back), in the shared UiTheme.
## Choosing an unlocked stage opens the pre-run setup (PreRunSetup: GDD
## §8.4 difficulty and §8.5 run modifiers, starting from the choices
## remembered in the Meta save) over this screen; when it confirms,
## `stage_chosen` is emitted with the finished RunConfig. Backing out of it
## returns to the stage card.
class_name StageSelect
extends Control

## A stage was chosen and set up: start a run with `config`.
signal stage_chosen(config: RunConfig)
## The screen closed without a choice (Back / Esc).
signal closed

## Width (px) of one stage card.
const CARD_WIDTH: float = 360.0
## Height (px) of one stage card.
const CARD_HEIGHT: float = 330.0

## Control that gets focus back when the screen closes.
var return_focus: Control = null
## Stage id -> its card Button.
var _cards: Dictionary = {}
## Back button.
var _back: Button


## Small code-drawn stage emblem: a moonlit tombstone (Graveyard), a
## crimson banner over a road to the fortress (Crimson March) or a cathedral
## facade with a rose window under a dawn sun (Sanctum of Judgment).
class StageEmblem:
	extends Control
	## StageRegistry id it depicts.
	var stage_id: String = ""
	## True while the stage is locked (drawn dimmed with a padlock).
	var locked: bool = false

	func _init(id: String, is_locked: bool) -> void:
		stage_id = id
		locked = is_locked
		custom_minimum_size = Vector2(0, 86)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := size
		var c := Vector2(s.x * 0.5, s.y * 0.55)
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.03, 0.02, 0.05, 0.9))
		if stage_id == "sanctum":
			draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, s.y * 0.6)), Color(0.16, 0.12, 0.08, 0.6))  # Dawn sky.
			draw_circle(Vector2(s.x * 0.2, s.y * 0.3), 13.0, Color(Palette.GOLD, 0.85))
			draw_rect(Rect2(Vector2(0, s.y * 0.8), Vector2(s.x, s.y * 0.2)), Color(0.24, 0.23, 0.21))
			var facade := Rect2(Vector2(c.x - 40, s.y * 0.32), Vector2(80, s.y * 0.48))
			draw_rect(facade, Color(0.42, 0.40, 0.37))
			draw_colored_polygon(PackedVector2Array([Vector2(c.x - 44, s.y * 0.32), Vector2(c.x, s.y * 0.06), Vector2(c.x + 44, s.y * 0.32)]), Color(0.36, 0.34, 0.31))
			for tx: float in [c.x - 54.0, c.x + 42.0]:  # Bell towers.
				draw_rect(Rect2(Vector2(tx, s.y * 0.2), Vector2(12, s.y * 0.6)), Color(0.36, 0.34, 0.31))
			draw_circle(Vector2(c.x, s.y * 0.44), 10.0, Palette.GOLD.darkened(0.2))  # Rose window.
			for i in 6:
				draw_line(Vector2(c.x, s.y * 0.44), Vector2(c.x, s.y * 0.44) + Vector2.from_angle(TAU * float(i) / 6.0) * 10.0, Palette.CRIMSON, 1.5)
			draw_rect(Rect2(Vector2(c.x - 9, s.y * 0.62), Vector2(18, s.y * 0.18)), Color(0.10, 0.08, 0.07))  # Doors.
		elif stage_id == "crimson_march":
			draw_rect(Rect2(Vector2(0, s.y * 0.62), Vector2(s.x, s.y * 0.38)), Color(0.12, 0.09, 0.07))
			draw_colored_polygon(PackedVector2Array([Vector2(c.x - 14, s.y), Vector2(c.x + 14, s.y), Vector2(c.x + 3, s.y * 0.62), Vector2(c.x - 3, s.y * 0.62)]), Color(0.24, 0.19, 0.14))
			for i in 3:  # Distant fortress towers.
				var tx := c.x + (float(i) - 1.0) * 34.0
				draw_rect(Rect2(Vector2(tx - 8, s.y * 0.3), Vector2(16, s.y * 0.32)), Color(0.18, 0.17, 0.2))
				draw_rect(Rect2(Vector2(tx - 10, s.y * 0.26), Vector2(20, 6)), Color(0.18, 0.17, 0.2))
			draw_line(Vector2(c.x + 60, s.y * 0.9), Vector2(c.x + 60, s.y * 0.15), Palette.GOLD.darkened(0.3), 2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(c.x + 61, s.y * 0.15), Vector2(c.x + 92, s.y * 0.2), Vector2(c.x + 80, s.y * 0.3), Vector2(c.x + 92, s.y * 0.4), Vector2(c.x + 61, s.y * 0.4)]), Palette.CRIMSON)
		else:
			draw_circle(Vector2(s.x * 0.78, s.y * 0.28), 14.0, Color(0.82, 0.86, 0.85, 0.85))
			draw_rect(Rect2(Vector2(0, s.y * 0.7), Vector2(s.x, s.y * 0.3)), Color(0.06, 0.07, 0.08))
			for i in 5:
				var tx := s.x * (0.12 + 0.19 * float(i))
				var hgt := 18.0 + 8.0 * absf(sin(float(i) * 1.7))
				draw_rect(Rect2(Vector2(tx - 7, s.y * 0.72 - hgt), Vector2(14, hgt)), Color(0.16, 0.17, 0.19))
				draw_circle(Vector2(tx, s.y * 0.72 - hgt), 7.0, Color(0.16, 0.17, 0.19))
				draw_circle(Vector2(tx, s.y * 0.74), 10.0, Color(Palette.NECRO_GREEN, 0.08))
		if locked:
			draw_rect(Rect2(Vector2.ZERO, s), Color(0.0, 0.0, 0.0, 0.55))
			draw_rect(Rect2(c + Vector2(-11, -2), Vector2(22, 18)), Palette.SILVER.darkened(0.3))
			draw_arc(c + Vector2(0, -2), 8.0, PI, TAU, 12, Palette.SILVER.darkened(0.3), 3.0)


## Opens the screen over `parent`; focus returns to `refocus` when it closes.
static func open_over(parent: Control, refocus: Control) -> StageSelect:
	var sel := StageSelect.new()
	sel.return_focus = refocus
	parent.add_child(sel)
	return sel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UiTheme.backdrop(0.85))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var title := UiTheme.label("CHOOSE YOUR BATTLEFIELD", 30, UiTheme.TEXT_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := UiTheme.label("Each chapter is a 20:00 march against the Covenant, its boss with 3:00 left, then the Reckoning.", 13, UiTheme.TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	for id: String in StageRegistry.ORDER:
		var card := _build_card(id)
		row.add_child(card)
		_cards[id] = card
	_back = Button.new()
	_back.text = "Back"
	_back.custom_minimum_size = Vector2(0, 42)
	_back.pressed.connect(close)
	vb.add_child(_back)
	_wire_focus()
	var first: Button = _cards.get(GameState.last_stage_id, _cards[StageRegistry.ORDER[0]])
	if first.disabled:
		first = _cards[StageRegistry.ORDER[0]]
	first.grab_focus.call_deferred()


## One stage card: a Button holding the emblem, the texts and the status.
func _build_card(id: String) -> Button:
	var def: Dictionary = StageRegistry.STAGES[id]
	var unlocked := Meta.is_stage_unlocked(id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	b.disabled = not unlocked
	b.focus_mode = Control.FOCUS_ALL  # Locked cards stay focusable so their requirement can be read.
	b.pressed.connect(_choose.bind(id))
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 12
	box.offset_right = -12
	box.offset_top = 10
	box.offset_bottom = -10
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	box.add_child(StageEmblem.new(id, not unlocked))
	box.add_child(UiTheme.label(String(def["chapter"]).to_upper(), 12, UiTheme.TEXT_DIM))
	box.add_child(UiTheme.label(String(def["display_name"]), 22, UiTheme.TEXT_GOLD if unlocked else UiTheme.TEXT_DIM))
	var desc := UiTheme.label(String(def["description"]), 13, UiTheme.TEXT if unlocked else UiTheme.TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(CARD_WIDTH - 24.0, 0)
	box.add_child(desc)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)
	var status := UiTheme.label(_status_text(id, unlocked), 13, Palette.NECRO_GREEN if unlocked else Palette.CRIMSON.lightened(0.35))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(CARD_WIDTH - 24.0, 0)
	box.add_child(status)
	return b


## Status line of a card: the unlock requirement, or the stage's record.
func _status_text(id: String, unlocked: bool) -> String:
	var def: Dictionary = StageRegistry.STAGES[id]
	if not unlocked:
		return "LOCKED  -  %s" % String(def["unlock_text"])
	var rec := Meta.stage_record(id)
	var best := int(float(rec["best_time"]))
	var parts := PackedStringArray()
	parts.append("Best %d:%02d" % [floori(float(best) / 60.0), best % 60] if best > 0 else "Not yet attempted")
	parts.append("%s slain %d" % [String(def["boss"]["short_name"]), int(float(rec["boss_kills"]))])
	if float(def["ash_mult"]) > 1.0:
		parts.append("Soul Ash x%.2f" % float(def["ash_mult"]))
	return "   |   ".join(parts)


## Explicit focus neighbours: cards left/right in a row, Back below them.
func _wire_focus() -> void:
	var ids: Array = StageRegistry.ORDER
	for i in ids.size():
		var b: Button = _cards[ids[i]]
		var left: Button = _cards[ids[maxi(0, i - 1)]]
		var right: Button = _cards[ids[mini(ids.size() - 1, i + 1)]]
		b.focus_neighbor_left = b.get_path_to(left)
		b.focus_neighbor_right = b.get_path_to(right)
		b.focus_neighbor_bottom = b.get_path_to(_back)
		b.focus_neighbor_top = b.get_path_to(b)
	_back.focus_neighbor_top = _back.get_path_to(_cards[ids[0]])


## An unlocked stage was chosen: open the pre-run setup with its RunConfig
## (remembered difficulty and modifiers); its Begin hands the config on.
func _choose(id: String) -> void:
	if not Meta.is_stage_unlocked(id):
		return
	Sfx.play("ui_confirm")
	var setup := PreRunSetup.open_over(self, _cards[id], Meta.prerun_config(id))  # Difficulty / modifiers step.
	setup.confirmed.connect(func(c: RunConfig) -> void: stage_chosen.emit(c))


## Restores focus to the opener and frees the screen.
func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	queue_free()


## Esc / controller B closes the screen.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
