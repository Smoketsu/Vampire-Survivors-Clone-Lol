## CharacterPicker — the playable-character grid of the pre-run setup screen
## (PreRunSetup puts it at the top of its setup column and wires its focus
## through tile_rows(); GDD §15.0 "Front door screens"). One portrait tile per
## character playable in this build (CharacterModifiers.available_ids(): a
## character whose starting spell is missing would stay hidden; all twelve
## exist now) in a tidy grid (FrontDoorData.CHAR_COLUMNS per row, one row
## of twelve), the chosen one in a gold frame. The character a tile shows is
## presented big in the hero panel (PreRunHero) while its tile is focused or
## hovered (`shown_changed`); when the focus leaves the grid the hero returns
## to the chosen character. Locked characters (Meta.is_character_unlocked():
## the owner's rule, Lv 5 with the character's spell in any run) show a
## padlock and cannot be chosen (pressing plays `denied`; the hero panel names
## the unlock). Choosing one (Enter / A / click) sets RunConfig.character_id
## through set_character() and emits `character_changed`; PreRunSetup's Begin
## remembers it in the Meta save. Name and flavour title are each tile's
## tooltip.
class_name CharacterPicker
extends GridContainer

## A character was chosen (RunConfig.character_id already set).
signal character_changed(id: String)
## The hero panel should present character `id` (a tile was focused /
## hovered, or the focus left the grid: the chosen one).
signal shown_changed(id: String)

## UI kit accent of the chosen character's tile (gold frame, UiTheme.style()).
const SELECTED_ACCENT: String = "gold"

## The config being edited (its character_id changes).
var config: RunConfig = null
## Character ids shown, in CharacterData.ORDER (the available ones).
var _ids: PackedStringArray = PackedStringArray()
## Character id -> its tile Button.
var _tiles: Dictionary = {}


## A character portrait (CharacterGlyphs.draw_portrait) filling its rect.
class Portrait:
	extends Control
	## CharacterData id drawn.
	var char_id: String = ""
	## True while that character is locked (padlock veil).
	var locked: bool = false

	func _init(p_id: String, p_locked: bool, min_size: Vector2) -> void:
		char_id = p_id
		locked = p_locked
		custom_minimum_size = min_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		CharacterGlyphs.draw_portrait(self, char_id, Rect2(Vector2.ZERO, size), locked)


func _ready() -> void:
	if config == null:
		config = RunConfig.new()
	columns = FrontDoorData.CHAR_COLUMNS
	add_theme_constant_override("h_separation", FrontDoorData.CHAR_GAP)
	add_theme_constant_override("v_separation", FrontDoorData.CHAR_GAP)
	_ids = CharacterModifiers.available_ids()
	for id: String in _ids:
		add_child(_build_tile(id))
	_refresh()


## One portrait tile Button (focus / hover present it, press chooses).
func _build_tile(id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = FrontDoorData.CHAR_TILE
	b.focus_mode = Control.FOCUS_ALL
	b.tooltip_text = "%s\n%s" % [String(CharacterData.CHARACTERS[id]["display_name"]), String(CharacterData.CHARACTERS[id]["title"])]
	var p := Portrait.new(id, not Meta.is_character_unlocked(id), Vector2.ZERO)
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 4
	p.offset_top = 4
	p.offset_right = -4
	p.offset_bottom = -4
	b.add_child(p)
	b.pressed.connect(_choose.bind(id))
	b.focus_entered.connect(func() -> void: shown_changed.emit(id))
	b.mouse_entered.connect(func() -> void: shown_changed.emit(id))
	b.focus_exited.connect(_on_tile_left)
	b.mouse_exited.connect(_on_tile_left)
	_tiles[id] = b
	return b


## A tile lost focus / hover: once neither the focus nor the mouse is on a
## tile, the hero shows the chosen character again.
func _on_tile_left() -> void:
	_check_left.call_deferred()


## The deferred half of _on_tile_left().
func _check_left() -> void:
	if not is_inside_tree():
		return
	var f := get_viewport().gui_get_focus_owner()  # Current focus.
	if f != null and is_ancestor_of(f):
		return
	for id: String in _ids:
		if (_tiles[id] as Button).is_hovered():
			return
	shown_changed.emit(config.character_id)


## Chooses character `id` when it is unlocked (else `denied`; the hero panel
## already names its unlock).
func _choose(id: String) -> void:
	if not Meta.is_character_unlocked(id):
		Sfx.play_ui("denied")
		shown_changed.emit(id)
		return
	config.set_character(id)
	Sfx.play("ui_confirm")
	_refresh()
	character_changed.emit(config.character_id)
	shown_changed.emit(id)


## Redraws the chosen look of every tile.
func _refresh() -> void:
	for id: String in _ids:
		UiTheme.style_button(_tiles[id] as Button, "button", SELECTED_ACCENT if id == config.character_id else "")


## The tile Buttons in display order.
func tiles() -> Array[Button]:
	var out: Array[Button] = []
	for id: String in _ids:
		out.append(_tiles[id])
	return out


## The tile Buttons as grid rows (top to bottom, each left to right), for
## the setup screen's focus wiring.
func tile_rows() -> Array:
	var t := tiles()
	var out: Array = []  # Rows of Buttons.
	for i in range(0, t.size(), FrontDoorData.CHAR_COLUMNS):
		out.append(t.slice(i, mini(t.size(), i + FrontDoorData.CHAR_COLUMNS)))
	return out
