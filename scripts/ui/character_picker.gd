## CharacterPicker — the playable-character section of the pre-run setup
## screen (PreRunSetup puts it at the top of its left column, the "who"
## column, above the skin and Hyper cards, and wires its focus through
## tile_rows()). Shows one portrait tile per character playable in this build
## (CharacterModifiers.available_ids(): a character whose starting spell is
## missing would stay hidden; all twelve exist now) in a compact grid, and
## under it a detail panel for the focused / hovered tile: portrait, name
## and title, starting spell, the innate passive and the stat modifiers. Locked characters (Meta.is_character_unlocked(): the
## owner's rule, Lv 5 with the character's spell in any run) show a padlock
## and their unlock condition and cannot be chosen. Choosing one (Enter / A
## / click) sets RunConfig.character_id through set_character() and emits
## `character_changed`; PreRunSetup's Begin remembers it in the Meta save.
## Keyboard / controller: arrows / D-pad move between tiles (explicit focus
## neighbours set by PreRunSetup from tile_rows()).
class_name CharacterPicker
extends VBoxContainer

## A character was chosen (RunConfig.character_id already set).
signal character_changed(id: String)

## Size (px) of one portrait tile (six to a row fill the setup screen's
## left column, PreRunSetup.LEFT_WIDTH).
const TILE_SIZE := Vector2(62, 62)
## Tiles per grid row (12 characters = two rows).
const TILE_COLUMNS: int = 6
## Size (px) of the detail panel's big portrait.
const BIG_PORTRAIT := Vector2(84, 84)
## Width (px) of the detail panel's text column (beside the big portrait,
## inside the left column).
const DETAIL_TEXT_WIDTH: float = 330.0
## Minimum height (px) of the detail panel, so the screen does not jump
## when the focused character's texts are shorter or longer.
const DETAIL_MIN_HEIGHT: float = 118.0
## UI kit accent of the chosen character's tile (gold frame, UiTheme.style()).
const SELECTED_ACCENT: String = "gold"

## The config being edited (its character_id changes).
var config: RunConfig = null
## Character ids shown, in CharacterData.ORDER (the available ones).
var _ids: PackedStringArray = PackedStringArray()
## Character id -> its tile Button.
var _tiles: Dictionary = {}
## Character id -> its tile Portrait.
var _portraits: Dictionary = {}
## Character id shown in the detail panel.
var _shown: String = ""
## Detail panel: big portrait.
var _big: Portrait
## Detail panel: name line.
var _name_l: Label
## Detail panel: flavour title.
var _title_l: Label
## Detail panel: starting spell line.
var _spell_l: Label
## Detail panel: innate line.
var _innate_l: Label
## Detail panel: stat modifiers line.
var _stats_l: Label
## Detail panel: lock / unlock condition line.
var _lock_l: Label


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
	add_theme_constant_override("separation", 4)
	var head := UiTheme.label("CHARACTER  (unlock one by reaching Lv %d with its spell)" % CharacterData.UNLOCK_LEVEL, 12, UiTheme.TEXT_DIM)
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.custom_minimum_size = Vector2(TILE_SIZE.x * TILE_COLUMNS + 5.0 * 6.0, 0)
	add_child(head)
	var grid := GridContainer.new()
	grid.columns = TILE_COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	_ids = CharacterModifiers.available_ids()
	for id: String in _ids:
		grid.add_child(_build_tile(id))
	add_child(_build_detail())
	_refresh()
	_show(config.character_id)


## One portrait tile Button (focus / hover show its details, press chooses).
func _build_tile(id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = TILE_SIZE
	b.focus_mode = Control.FOCUS_ALL
	b.tooltip_text = String(CharacterData.CHARACTERS[id]["display_name"])
	var p := Portrait.new(id, not Meta.is_character_unlocked(id), Vector2.ZERO)
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 4
	p.offset_top = 4
	p.offset_right = -4
	p.offset_bottom = -4
	b.add_child(p)
	b.pressed.connect(_choose.bind(id))
	b.focus_entered.connect(_show.bind(id))
	b.mouse_entered.connect(_show.bind(id))
	_tiles[id] = b
	_portraits[id] = p
	return b


## The detail panel: big portrait beside the text lines.
func _build_detail() -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(0, DETAIL_MIN_HEIGHT)
	_big = Portrait.new(CharacterData.DEFAULT_ID, false, BIG_PORTRAIT)
	box.add_child(_big)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 1)
	box.add_child(text)
	_name_l = UiTheme.label("", 17, UiTheme.TEXT)
	text.add_child(_name_l)
	_title_l = _wrapped(12, UiTheme.TEXT_DIM)
	text.add_child(_title_l)
	_spell_l = UiTheme.label("", 13, UiTheme.TEXT)
	text.add_child(_spell_l)
	_innate_l = _wrapped(12, UiTheme.TEXT_GOOD)
	text.add_child(_innate_l)
	_stats_l = _wrapped(12, UiTheme.TEXT)
	text.add_child(_stats_l)
	_lock_l = _wrapped(12, Palette.CRIMSON.lightened(0.45))
	text.add_child(_lock_l)
	return box


## A word-wrapped detail label `size_px` px in `color`.
func _wrapped(size_px: int, color: Color) -> Label:
	var l := UiTheme.body("", size_px, color)  # Detail paragraphs: body font.
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(DETAIL_TEXT_WIDTH, 0)
	return l


## Shows character `id` in the detail panel.
func _show(id: String) -> void:
	if not _tiles.has(id):
		id = CharacterData.DEFAULT_ID
	_shown = id
	var d := CharacterModifiers.def(id)  # Character row.
	var locked := not Meta.is_character_unlocked(id)  # Cannot be chosen yet.
	_big.char_id = id
	_big.locked = locked
	_big.queue_redraw()
	var chosen := id == config.character_id  # The current choice.
	_name_l.text = String(d["display_name"]) + ("  (chosen)" if chosen else "")
	_name_l.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if chosen else UiTheme.TEXT)
	_title_l.text = String(d["title"])
	_spell_l.text = "Starting spell:  %s" % CharacterModifiers.spell_name(id)
	var inn: Dictionary = d["innate"]  # {} = none.
	_innate_l.text = "Innate:  none - the classic necromancer" if inn.is_empty() else "Innate - %s:  %s" % [String(inn["name"]), String(inn["description"])]
	_stats_l.text = CharacterModifiers.stats_text(id)
	_lock_l.text = "LOCKED - %s" % CharacterModifiers.unlock_text(id) if locked else ""


## Chooses character `id` when it is unlocked (else nothing happens; the
## detail panel already says how to unlock it).
func _choose(id: String) -> void:
	if not Meta.is_character_unlocked(id):
		Sfx.play("ui_hover")
		_show(id)
		return
	config.set_character(id)
	Sfx.play("ui_confirm")
	_refresh()
	_show(id)
	character_changed.emit(config.character_id)


## Redraws the chosen / locked looks of every tile.
func _refresh() -> void:
	for id: String in _ids:
		var b: Button = _tiles[id]
		if id == config.character_id:
			UiTheme.style_button(b, "button", SELECTED_ACCENT)
		else:
			UiTheme.style_button(b, "button", "")


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
	for i in range(0, t.size(), TILE_COLUMNS):
		out.append(t.slice(i, mini(t.size(), i + TILE_COLUMNS)))
	return out
