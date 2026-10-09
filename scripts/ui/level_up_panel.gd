## LevelUpPanel — pauses combat and shows three large upgrade cards
## (GDD §16 "Level-up panel: Pause combat; three large cards with icon, name,
## old/new level, description, actual stat delta"). Pick with the mouse,
## keys 1/2/3, or controller (focus + A). Evolutions are not implemented, so
## no "evolution readiness" line is shown yet.
class_name LevelUpPanel
extends Control

## Emitted with the chosen offer Dictionary (see AbilityManager._offer()).
signal card_chosen(offer: Dictionary)

## Clicks/keys within this many ms of opening are ignored, so a held key or
## an in-flight click doesn't pick a card by accident.
const INPUT_GRACE_MSEC: int = 250
## Card width in px (fixed so text wraps predictably).
const CARD_WIDTH: float = 270.0
## Minimum card height in px; cards grow taller to fit their content and the
## row stretches every card to the tallest one.
const CARD_MIN_HEIGHT: float = 340.0
## Inner padding of a card in px (left/right).
const CARD_PAD_X: int = 14
## Inner padding of a card in px (top/bottom).
const CARD_PAD_Y: int = 12

## Owning run (autotest hook).
var game: Game
## Offers currently displayed.
var _offers: Array[Dictionary] = []
## Container holding the card buttons.
var _cards_box: HBoxContainer
## "LEVEL N" title.
var _title: Label
## Card buttons in display order (focus / click targets).
var _buttons: Array[Button] = []
## Card root containers in display order (freed when the panel reopens).
var _cards: Array[Control] = []
## Time (ms) the panel was last opened.
var _opened_msec: int = 0
## True while waiting for a choice.
var _waiting: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	add_child(UiTheme.backdrop(0.72))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	center.add_child(vb)
	_title = UiTheme.label("LEVEL UP", 34, UiTheme.TEXT_GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)
	var sub := UiTheme.label("Choose one  -  click, press 1 / 2 / 3, or use a controller", 14, UiTheme.TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	_cards_box = HBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 18)
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(_cards_box)


## Shows `offers` as cards for reaching level `for_level`.
func open(offers: Array[Dictionary], for_level: int) -> void:
	_offers = offers
	for c in _cards:
		c.queue_free()
	_cards.clear()
	_buttons.clear()
	for i in offers.size():
		var card := _make_card(offers[i], i)
		_cards_box.add_child(card)
		_cards.append(card)
	_title.text = "LEVEL %d" % for_level
	visible = true
	_waiting = true
	_opened_msec = Time.get_ticks_msec()
	if not _buttons.is_empty():
		_buttons[0].grab_focus.call_deferred()
	if game != null and game.autotest != null:
		_choose.call_deferred(game.autotest.choose_card(offers), true)


## Hides the panel.
func close() -> void:
	visible = false
	_waiting = false


## Builds one card for offer `o` (index `idx`). Layout: a MarginContainer
## root whose minimum size is the max of its children, holding a full-size
## Button (focus / click / controller A) underneath a padded content column.
## The card therefore grows to fit its text and can never overflow.
func _make_card(o: Dictionary, idx: int) -> Control:
	var card := MarginContainer.new()
	card.custom_minimum_size = Vector2(CARD_WIDTH, CARD_MIN_HEIGHT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := Button.new()
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(_choose.bind(idx, false))
	card.add_child(b)
	_buttons.append(b)
	var content := MarginContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("margin_left", CARD_PAD_X)
	content.add_theme_constant_override("margin_right", CARD_PAD_X)
	content.add_theme_constant_override("margin_top", CARD_PAD_Y)
	content.add_theme_constant_override("margin_bottom", CARD_PAD_Y)
	card.add_child(content)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 6)
	content.add_child(vb)
	var text_width := CARD_WIDTH - 2.0 * float(CARD_PAD_X)
	var tag_color := Palette.NECRO_GREEN
	match String(o["tag"]):
		"SPELL":
			tag_color = Palette.VIOLET.lightened(0.3)
		"PASSIVE":
			tag_color = Palette.COLD_BLUE
		"RESTORE":
			tag_color = Palette.GOLD
	vb.add_child(UiTheme.label("[%d]  %s" % [idx + 1, o["tag"]], 12, tag_color))
	var icon_center := CenterContainer.new()
	icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_center.add_child(IconGlyph.new(o["icon"], Vector2(68, 68)))
	vb.add_child(icon_center)
	var name_label := UiTheme.label(o["name"], 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(name_label)
	var lvl_text := ""
	if String(o["kind"]) != "heal":
		lvl_text = "NEW!  Lv 1" if int(o["from"]) == 0 else "Lv %d  ->  Lv %d" % [int(o["from"]), int(o["to"])]
	var lvl_label := UiTheme.label(lvl_text, 15, UiTheme.TEXT_GOLD)
	lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lvl_label)
	var desc := UiTheme.label(o["description"], 13, UiTheme.TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(text_width, 0)
	vb.add_child(desc)
	var deltas := UiTheme.label("\n".join(o["deltas"]), 14, UiTheme.TEXT_GOOD)
	deltas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deltas.custom_minimum_size = Vector2(text_width, 0)
	vb.add_child(deltas)
	return card


## Emits the chosen card once (ignores input during the grace period unless
## `forced` by the autotest).
func _choose(idx: int, forced: bool) -> void:
	if not _waiting or idx < 0 or idx >= _offers.size():
		return
	if not forced and Time.get_ticks_msec() - _opened_msec < INPUT_GRACE_MSEC:
		return
	_waiting = false
	card_chosen.emit(_offers[idx])


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _waiting:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var idx := -1
	match key.physical_keycode:
		KEY_1, KEY_KP_1:
			idx = 0
		KEY_2, KEY_KP_2:
			idx = 1
		KEY_3, KEY_KP_3:
			idx = 2
	if idx >= 0:
		get_viewport().set_input_as_handled()
		_choose(idx, false)
