## PreRunUltimates — the ultimate picker of the pre-run setup screen (content
## wave 2, owner-approved Proposal 4; GDD §15.0 "Ultimates (content wave 2)").
## PreRunSetup puts it in the setup panel's right column under the modifiers
## (wide tiles: tile_size / gap / detail_* set by the screen; the defaults are
## the narrow hero-panel layout). One row of
## four tiles (UltimateData.ORDER: Dread Rally, Sovereign's Decree, Eclipse,
## Grave Tide), each the ultimate's 32 px badge icon and its one-word name; the
## chosen one is framed in gold. A locked ultimate (Unlocks.is_open(id) false:
## its UnlockData row's achievement is not earned yet; an id without a row is
## open, and Dread Rally is always open) is dimmed under the pixel padlock and
## cannot be chosen (`denied`). Under the row ONE detail text (two lines kept)
## names the focused (or chosen) tile: its name and when to pick it, or, while
## locked, how to earn it (Unlocks.lock_text()); the full effect is the tile's
## tooltip. Choosing sets RunConfig.ultimate_id (remembered in the Meta save
## [prerun] ultimate when the run begins, kept by Restart); any character.
## Keyboard / mouse / controller navigable: rows() gives the tiles as one row
## for the setup screen's explicit focus wiring; Enter / A chooses.
class_name PreRunUltimates
extends VBoxContainer

## The chosen ultimate changed (the setup screen redraws).
signal changed

## UI kit accent of the chosen tile (gold frame, UiTheme.style()).
const ON_ACCENT: String = "gold"

## The config being edited (shared with the setup screen).
var config: RunConfig = null
## Ultimate id -> its tile Button.
var _buttons: Dictionary = {}
## Ultimate id -> its name Label.
var _names: Dictionary = {}
## The one detail line under the row.
var _detail: Label
## Size (px) of one tile (set before the picker enters the tree).
var tile_size: Vector2 = UltimateData.PICKER_TILE
## Gap (px) between the tiles.
var gap: int = UltimateData.PICKER_GAP
## Width (px) of the detail text under the row.
var detail_width: float = FrontDoorData.HERO_TEXT_WIDTH
## Lines (>= 1) the detail text keeps, so the layout never jumps.
var detail_lines: int = UltimateData.PICKER_DETAIL_LINES
## True: the detail text is ONE clipped line (no wrap, an ellipsis; the full text
## stays in the tooltips), for the setup screen's shared Ultimate / Rites row.
var detail_clip: bool = false


## A dark veil and the pixel padlock over a locked tile's icon.
class LockVeil:
	extends Control

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, CharacterGlyphs.LOCK_VEIL))
		var s := MaskIcon.art_size("padlock") * float(CharacterGlyphs.LOCK_ICON_SCALE)  # Padlock (px).
		MaskIcon.paint(self, "padlock", (size * 0.5 - s * 0.5).round(), CharacterGlyphs.LOCK_ICON_SCALE)


func _ready() -> void:
	if config == null:
		config = RunConfig.new()
	add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", gap)
	add_child(row)
	for id: String in UltimateData.ORDER:
		row.add_child(_build_tile(id))
	_detail = UiTheme.para("", detail_width, UiTheme.TEXT_DIM)
	_detail.custom_minimum_size.y = float(UiTheme.tier_px(UiTheme.Tier.BODY)) * float(maxi(1, detail_lines))  # Kept: no jump.
	if detail_clip:
		_detail.autowrap_mode = TextServer.AUTOWRAP_OFF
		_detail.clip_text = true
		_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_detail)
	refresh()


## True when ultimate `id` may be chosen (Dread Rally always).
static func is_open(id: String) -> bool:
	return id == UltimateData.DEFAULT_ID or Unlocks.is_open(id)


## One tile: the badge icon (veiled while locked) and the one-word name.
func _build_tile(id: String) -> Button:
	var row: Dictionary = UltimateData.ULTIMATES[id]
	var b := Button.new()
	b.custom_minimum_size = tile_size
	b.focus_mode = Control.FOCUS_ALL
	b.tooltip_text = "%s\n%s" % [String(row["display_name"]), String(row["description"])]
	b.pressed.connect(_choose.bind(id))
	b.focus_entered.connect(_show_detail.bind(id))
	b.mouse_entered.connect(_show_detail.bind(id))
	b.focus_exited.connect(_on_left)
	b.mouse_exited.connect(_on_left)
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 4
	box.offset_right = -2
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var icon := IconGlyph.new(String(row["icon"]), Vector2(UltimateData.PICKER_ICON, UltimateData.PICKER_ICON))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	if not is_open(id):
		var veil := LockVeil.new()
		veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.add_child(veil)
	var name_l := UiTheme.tier_label(String(row["short"]), UiTheme.Tier.BODY, UiTheme.TEXT)
	name_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.clip_text = true
	box.add_child(name_l)
	_buttons[id] = b
	_names[id] = name_l
	return b


## A tile lost focus / hover: once none is focused, the line names the choice.
func _on_left() -> void:
	_check_left.call_deferred()


## The deferred half of _on_left().
func _check_left() -> void:
	if not is_inside_tree():
		return
	var f := get_viewport().gui_get_focus_owner()  # Current focus.
	if f != null and is_ancestor_of(f):
		return
	_show_detail("")


## Writes the detail line for ultimate `id` ("" = the chosen one).
func _show_detail(id: String) -> void:
	if id == "":
		id = config.ultimate_id
	var row: Dictionary = UltimateData.ULTIMATES.get(id, {})
	if row.is_empty():
		_detail.text = ""
		return
	if not is_open(id):
		var how := Unlocks.lock_text(id)  # The unlock condition ("" without a row text).
		_detail.text = "Locked. %s" % (how if how != "" else UltimateData.PICKER_LOCKED_TEXT)
		_detail.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.4))
		return
	_detail.text = "%s: %s" % [String(row["display_name"]), String(row["pick"])]
	_detail.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if id == config.ultimate_id else UiTheme.TEXT)


## Tile pressed: chooses ultimate `id` if it is open (`denied` while locked).
func _choose(id: String) -> void:
	if not is_open(id):
		Sfx.play_ui("denied")  # Locked.
		return
	config.set_ultimate(id)
	Sfx.play("ui_confirm")
	refresh()
	_show_detail(id)
	changed.emit()


## Every tile, left to right.
func cards() -> Array:
	var out: Array = []  # Buttons.
	for id: String in UltimateData.ORDER:
		out.append(_buttons[id])
	return out


## The tiles as focus rows (one row, left to right), for the setup screen's
## explicit focus wiring.
func rows() -> Array:
	return [cards()]


## Redraws the chosen state; keeps config.ultimate_id an open ultimate.
func refresh() -> void:
	if not is_open(config.ultimate_id):
		config.set_ultimate(UltimateData.DEFAULT_ID)
	for id: String in UltimateData.ORDER:
		var on := id == config.ultimate_id  # The chosen tile.
		UiTheme.style_button(_buttons[id], "button", ON_ACCENT if on else "")
		(_names[id] as Label).add_theme_color_override("font_color", UiTheme.TEXT_GOLD if on else (UiTheme.TEXT if is_open(id) else UiTheme.TEXT_DIM))
	var f := get_viewport().gui_get_focus_owner() if is_inside_tree() else null  # Current focus.
	if f == null or not is_ancestor_of(f):
		_show_detail("")
