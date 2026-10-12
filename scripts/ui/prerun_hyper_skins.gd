## PreRunHyperSkins — the Hyper mode toggle and the skin selector of the
## pre-run setup screen (PreRunSetup builds one under the run modifiers; kept
## in its own file so the setup screen's own code stays small). One row of
## cards, the shape of the difficulty row:
##   * the HYPER card (HyperData): toggles RunConfig.hyper; while locked
##     (Meta.hyper_unlocked) it shows the unlock condition and cannot be
##     switched on; a gold badge notes a Hyper clear of this stage with the
##     run's character,
##   * one card per skin of the run's character (SkinData.skins_for: default,
##     Hyper skin, achievement skin): a live preview (SkinGlyphs), the name
##     and, while locked, the unlock condition with its progress. Choosing an
##     unlocked skin sets RunConfig.skin_id (remembered per character in the
##     Meta save when the run begins). Skins are purely cosmetic.
## Keyboard / mouse / controller navigable: wire() links the cards to the
## controls above and below with explicit focus neighbours; Enter / A
## toggles or chooses. refresh() follows a character change (RunConfig
## character_key()) by rebuilding the skin cards.
class_name PreRunHyperSkins
extends VBoxContainer

## Hyper or the skin changed (the setup screen redraws its totals).
signal changed

## Size (px) of every card in the row.
const CARD_SIZE := Vector2(250, 76)
## Size (px) of a skin card's preview.
const PREVIEW_SIZE := Vector2(48, 64)
## Border colour of the Hyper card while on and of the chosen skin.
const ON_BORDER := Color(1.0, 0.82, 0.3)
## Background of the Hyper card while on and of the chosen skin.
const ON_BG := Color(0.24, 0.17, 0.05, 0.97)

## The config being edited (shared with the setup screen).
var config: RunConfig = null
## The Hyper toggle card.
var _hyper_button: Button
## Hyper card name label ("HYPER  ON").
var _hyper_name: Label
## Hyper card detail label (tagline or lock text).
var _hyper_desc: Label
## Hyper card badge row (shown after a Hyper clear of this stage).
var _hyper_badge: Control
## Row holding the cards.
var _row: HBoxContainer
## Skin id -> its card Button (current character only).
var _skin_buttons: Dictionary = {}
## Skin id -> its name Label.
var _skin_names: Dictionary = {}
## Skin ids of the cards, in order.
var _skin_ids: PackedStringArray = PackedStringArray()
## Character the skin cards were built for.
var _character: String = ""
## Controls above the row (focus "top" targets; set by wire()).
var _above: Array = []
## Controls below the row (focus "bottom" targets; set by wire()).
var _below: Array = []


## Live skin preview: the necromancer drawn in a skin (SkinGlyphs), dimmed
## while the skin is locked.
class SkinPreview:
	extends Control
	## SkinData id drawn.
	var skin_id: String = ""
	## True while the skin is locked (drawn dark).
	var locked: bool = false

	func _init(id: String, is_locked: bool) -> void:
		skin_id = id
		locked = is_locked
		custom_minimum_size = PreRunHyperSkins.PREVIEW_SIZE
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.02, 0.05, 0.9))
		SpriteBank.icon_cap = size.y * 0.78
		SkinGlyphs.draw_skin(self, skin_id, size * 0.5 + Vector2(0.0, size.y * 0.06), size.y * 0.28, false)
		SpriteBank.icon_cap = 0.0
		if locked:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.6))
			var c := size * 0.5  # Padlock centre.
			draw_rect(Rect2(c + Vector2(-7, -1), Vector2(14, 11)), Palette.SILVER.darkened(0.2))
			draw_arc(c + Vector2(0, -1), 5.0, PI, TAU, 10, Palette.SILVER.darkened(0.2), 2.0)


func _ready() -> void:
	if config == null:
		config = RunConfig.new()
	add_theme_constant_override("separation", 4)
	add_child(UiTheme.label("HYPER MODE AND SKIN  (skins are purely cosmetic)", 14, UiTheme.TEXT_DIM))
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 10)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_row)
	_row.add_child(_build_hyper_card())
	_rebuild_skins()
	refresh()


## Common card Button with a box of labels inside (labels ignore the mouse).
static func _card(box: Container) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD_SIZE
	b.focus_mode = Control.FOCUS_ALL
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 10
	box.offset_right = -10
	box.offset_top = 6
	box.offset_bottom = -6
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	return b


## The Hyper toggle card.
func _build_hyper_card() -> Button:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_hyper_button = _card(box)
	_hyper_button.pressed.connect(_toggle_hyper)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hyper_name = UiTheme.label("", 17, UiTheme.TEXT)
	_hyper_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_hyper_name)
	_hyper_badge = HyperBadge.row("Cleared", 16, 12)
	head.add_child(_hyper_badge)
	box.add_child(head)
	_hyper_desc = UiTheme.label("", 11, UiTheme.TEXT_DIM)
	_hyper_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hyper_desc.custom_minimum_size = Vector2(CARD_SIZE.x - 20.0, 0)
	box.add_child(_hyper_desc)
	return _hyper_button


## (Re)builds one card per skin of the run's character.
func _rebuild_skins() -> void:
	for id: String in _skin_ids:
		var old: Button = _skin_buttons[id]
		_row.remove_child(old)
		old.queue_free()
	_skin_buttons.clear()
	_skin_names.clear()
	_character = config.character_key()
	_skin_ids = SkinData.skins_for(_character)
	for id: String in _skin_ids:
		_row.add_child(_build_skin_card(id))
	if not _above.is_empty() or not _below.is_empty():
		wire(_above, _below)


## One skin card: preview, name, then its look or its lock condition.
func _build_skin_card(id: String) -> Button:
	var row := SkinData.skin(id)  # The skin's data.
	var unlocked := Meta.is_skin_unlocked(id)  # May be worn.
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var b := _card(box)
	b.pressed.connect(_choose_skin.bind(id))
	b.tooltip_text = String(row["look"]) + ("" if unlocked else "\nUnlock: " + String(row["unlock_text"]))
	box.add_child(SkinPreview.new(id, not unlocked))
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 1)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(texts)
	var name_l := UiTheme.label(String(row["display_name"]), 14, UiTheme.TEXT if unlocked else UiTheme.TEXT_DIM)
	name_l.clip_text = true
	texts.add_child(name_l)
	var detail := ""  # Second line.
	if unlocked:
		detail = {"default": "Default look", "hyper": "Hyper skin", "achievement": "Achievement skin"}.get(String(row["kind"]), "")
	else:
		var prog := Meta.skin_progress(id)  # "n / goal" or "".
		detail = "LOCKED: " + String(row["unlock_short"]) + ("  (%s)" % prog if prog != "" else "")
	var d := UiTheme.label(detail, 10, UiTheme.TEXT_DIM if unlocked else Palette.CRIMSON.lightened(0.4))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(CARD_SIZE.x - PREVIEW_SIZE.x - 28.0, 0)
	texts.add_child(d)
	_skin_buttons[id] = b
	_skin_names[id] = name_l
	return b


## The row's cards, left to right (Hyper first).
func cards() -> Array:
	var out: Array = [_hyper_button]  # Buttons.
	for id: String in _skin_ids:
		out.append(_skin_buttons[id])
	return out


## Explicit focus neighbours: left / right inside the row, "top" to the
## nearest of `above` and "bottom" to the nearest of `below` (by position in
## their rows); `above`'s bottoms and `below`'s tops are pointed at the row.
func wire(above: Array, below: Array) -> void:
	_above = above
	_below = below
	var row := cards()  # This row, left to right.
	for i in row.size():
		var b: Button = row[i]
		_link(b, "left", row[maxi(0, i - 1)])
		_link(b, "right", row[mini(row.size() - 1, i + 1)])
		if not above.is_empty():
			_link(b, "top", above[_nearest(i, row.size(), above.size())])
		if not below.is_empty():
			_link(b, "bottom", below[_nearest(i, row.size(), below.size())])
	for j in above.size():
		_link(above[j], "bottom", row[_nearest(j, above.size(), row.size())])
	for j in below.size():
		_link(below[j], "top", row[_nearest(j, below.size(), row.size())])


## Index in a row of `to_n` items under item `i` of a row of `from_n` items.
static func _nearest(i: int, from_n: int, to_n: int) -> int:
	if from_n <= 1:
		return 0
	return clampi(roundi(float(i) * float(to_n - 1) / float(from_n - 1)), 0, to_n - 1)


## Sets focus neighbour `side` of `b` to `to`.
static func _link(b: Control, side: String, to: Control) -> void:
	b.set("focus_neighbor_" + side, b.get_path_to(to))


## Hyper card pressed: toggles Hyper (no-op while locked).
func _toggle_hyper() -> void:
	if not Meta.hyper_unlocked:
		Sfx.play("ui_hover")
		return
	config.hyper = not config.hyper
	Sfx.play("ui_confirm")
	refresh()
	changed.emit()


## Skin card pressed: wears skin `id` if it is unlocked.
func _choose_skin(id: String) -> void:
	if not Meta.is_skin_unlocked(id):
		Sfx.play("ui_hover")
		return
	config.skin_id = id
	Sfx.play("ui_confirm")
	refresh()
	changed.emit()


## Turns Hyper off (the setup screen's Standard button).
func reset() -> void:
	config.hyper = false
	refresh()


## Redraws the states; rebuilds the skin cards when the character changed
## and keeps config.skin_id a skin of that character that is unlocked.
func refresh() -> void:
	if config.character_key() != _character:
		_rebuild_skins()
	if not _skin_ids.has(config.skin_id) or not Meta.is_skin_unlocked(config.skin_id):
		config.skin_id = Meta.chosen_skin(_character)
	var unlocked := Meta.hyper_unlocked  # The toggle may be used.
	if not unlocked:
		config.hyper = false
	_style(_hyper_button, config.hyper)
	_hyper_name.text = "%s  %s" % [HyperData.DISPLAY_NAME.to_upper(), ("ON" if config.hyper else "off") if unlocked else "LOCKED"]
	_hyper_name.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if config.hyper else (UiTheme.TEXT if unlocked else UiTheme.TEXT_DIM))
	_hyper_desc.text = HyperData.TAGLINE if unlocked else HyperData.LOCK_TEXT
	_hyper_badge.visible = Meta.is_hyper_cleared(config.stage_id, _character)
	for id: String in _skin_ids:
		var on := id == config.skin_id  # The worn skin.
		_style(_skin_buttons[id], on)
		(_skin_names[id] as Label).add_theme_color_override("font_color", UiTheme.TEXT_GOLD if on else (UiTheme.TEXT if Meta.is_skin_unlocked(id) else UiTheme.TEXT_DIM))


## Applies the on / chosen look to card `b` (normal and hover styles).
static func _style(b: Button, on: bool) -> void:
	if on:
		b.add_theme_stylebox_override("normal", UiTheme.box(ON_BG, ON_BORDER, 3))
		b.add_theme_stylebox_override("hover", UiTheme.box(ON_BG.lightened(0.08), ON_BORDER, 3))
	else:
		b.remove_theme_stylebox_override("normal")
		b.remove_theme_stylebox_override("hover")
