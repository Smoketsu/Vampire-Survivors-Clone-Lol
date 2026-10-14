## PreRunHyperSkins — the skin selector and the Hyper mode toggle of the
## pre-run setup screen (PreRunSetup puts it in the hero panel, under the
## character's texts; GDD §15.0 "Front door screens"). One row:
##   * a small portrait tile per skin of the run's character
##     (SkinData.skins_for: default, Hyper skin, achievement skin): a live
##     preview (SkinGlyphs); a locked skin is dark under the pixel padlock.
##     Choosing an unlocked skin sets RunConfig.skin_id (remembered per
##     character in the Meta save when the run begins). Skins are purely
##     cosmetic. Focusing a skin tile shows it on the hero (`skin_focused`),
##   * the HYPER tile (HyperData): the gold badge, "Hyper" and its state;
##     toggles RunConfig.hyper; while locked (Meta.hyper_unlocked) it cannot
##     be switched on (`denied`); a small gold badge notes a Hyper clear of
##     this stage with the run's character.
## Under the row ONE detail line names the focused tile: the skin and, while
## locked, its unlock condition with progress; or Hyper's effect / lock text
## (fewer words on the tiles themselves; the full look is each tile's tooltip).
## Keyboard / mouse / controller navigable: rows() gives the tiles as one row
## for the setup screen's explicit focus wiring (re-done on `rebuilt`);
## Enter / A toggles or chooses. refresh() follows a character change
## (RunConfig.character_key()) by rebuilding the skin tiles.
class_name PreRunHyperSkins
extends VBoxContainer

## Hyper or the skin changed (the setup screen redraws its totals and hero).
signal changed
## The skin tiles were rebuilt for another character (the setup screen
## re-wires its focus neighbours).
signal rebuilt
## A skin tile was focused / hovered ("" = the focus left the skins: show
## the worn skin again).
signal skin_focused(skin_id: String)

## UI kit accent of the Hyper tile while on and of the worn skin (gold frame, UiTheme.style()).
const ON_ACCENT: String = "gold"

## The config being edited (shared with the setup screen).
var config: RunConfig = null
## The Hyper toggle tile.
var _hyper_button: Button
## Hyper tile state label ("On" / "Off" / "Locked").
var _hyper_state: Label
## Hyper tile clear badge (shown after a Hyper clear of this stage).
var _hyper_badge: Control
## Row holding the skin tiles (then the Hyper tile).
var _row: HBoxContainer
## The one detail line under the row.
var _detail: Label
## Skin id -> its tile Button (current character only).
var _skin_buttons: Dictionary = {}
## Skin ids of the tiles, in order.
var _skin_ids: PackedStringArray = PackedStringArray()
## Character the skin tiles were built for.
var _character: String = ""


## Live skin preview: the necromancer drawn in a skin (SkinGlyphs), dark
## under the pixel padlock while the skin is locked.
class SkinPreview:
	extends Control
	## SkinData id drawn.
	var skin_id: String = ""
	## True while the skin is locked (drawn dark).
	var locked: bool = false

	func _init(id: String, is_locked: bool) -> void:
		skin_id = id
		locked = is_locked
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.02, 0.05, 0.9))
		SpriteBank.icon_cap = size.y * 0.92
		SkinGlyphs.draw_skin(self, skin_id, size * 0.5, size.y * 0.28, false)
		SpriteBank.icon_cap = 0.0
		if locked:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, CharacterGlyphs.LOCK_VEIL))
			var s := MaskIcon.art_size("padlock") * float(CharacterGlyphs.LOCK_ICON_SCALE)  # Padlock (px).
			MaskIcon.paint(self, "padlock", size * 0.5 - s * 0.5, CharacterGlyphs.LOCK_ICON_SCALE)


func _ready() -> void:
	if config == null:
		config = RunConfig.new()
	add_theme_constant_override("separation", 4)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 6)
	add_child(_row)
	var fill := Control.new()  # Pushes the Hyper tile to the right.
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(fill)
	_row.add_child(_build_hyper_tile())
	_detail = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_detail.clip_text = true
	_detail.custom_minimum_size.x = FrontDoorData.HERO_TEXT_WIDTH
	add_child(_detail)
	_rebuild_skins()
	refresh()


## The Hyper toggle tile: badge, name, state (and the clear badge).
func _build_hyper_tile() -> Button:
	_hyper_button = Button.new()
	_hyper_button.custom_minimum_size = FrontDoorData.HYPER_TILE
	_hyper_button.focus_mode = Control.FOCUS_ALL
	_hyper_button.tooltip_text = HyperData.TAGLINE
	_hyper_button.pressed.connect(_toggle_hyper)
	_hyper_button.focus_entered.connect(_show_detail.bind("hyper"))
	_hyper_button.mouse_entered.connect(_show_detail.bind("hyper"))
	_hyper_button.focus_exited.connect(_on_left)
	_hyper_button.mouse_exited.connect(_on_left)
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 10
	box.offset_right = -10
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hyper_button.add_child(box)
	var badge := HyperBadge.new(32.0)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(badge)
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(texts)
	texts.add_child(UiTheme.tier_label(HyperData.DISPLAY_NAME, UiTheme.Tier.NAME, UiTheme.TEXT_GOLD))
	var st := HBoxContainer.new()  # State, then the clear badge.
	st.add_theme_constant_override("separation", 6)
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hyper_state = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	st.add_child(_hyper_state)
	_hyper_badge = HyperBadge.new(14.0)
	_hyper_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	st.add_child(_hyper_badge)
	texts.add_child(st)
	return _hyper_button


## (Re)builds one tile per skin of the run's character (before the filler).
func _rebuild_skins() -> void:
	for id: String in _skin_ids:
		var old: Button = _skin_buttons[id]
		_row.remove_child(old)
		old.queue_free()
	_skin_buttons.clear()
	_character = config.character_key()
	_skin_ids = SkinData.skins_for(_character)
	var i := 0  # Insert position.
	for id: String in _skin_ids:
		var b := _build_skin_tile(id)
		_row.add_child(b)
		_row.move_child(b, i)
		i += 1
	rebuilt.emit()


## One skin tile: the preview filling it (its name and look in the tooltip).
func _build_skin_tile(id: String) -> Button:
	var row := SkinData.skin(id)  # The skin's data.
	var unlocked := Meta.is_skin_unlocked(id)  # May be worn.
	var b := Button.new()
	b.custom_minimum_size = FrontDoorData.SKIN_TILE
	b.focus_mode = Control.FOCUS_ALL
	b.tooltip_text = "%s\n%s" % [String(row["display_name"]), String(row["look"])]
	var p := SkinPreview.new(id, not unlocked)
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 4
	p.offset_top = 4
	p.offset_right = -4
	p.offset_bottom = -4
	b.add_child(p)
	b.pressed.connect(_choose_skin.bind(id))
	b.focus_entered.connect(_on_skin_focus.bind(id))
	b.mouse_entered.connect(_on_skin_focus.bind(id))
	b.focus_exited.connect(_on_left)
	b.mouse_exited.connect(_on_left)
	_skin_buttons[id] = b
	return b


## A skin tile is focused / hovered: name it and show it on the hero.
func _on_skin_focus(id: String) -> void:
	_show_detail(id)
	skin_focused.emit(id)


## A tile lost focus / hover: once none is focused, the line and the hero
## return to the worn skin.
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
	skin_focused.emit("")


## Writes the detail line for tile `id` (a skin id, "hyper", or "" = the worn skin).
func _show_detail(id: String) -> void:
	if id == "hyper":
		_detail.text = HyperData.TAGLINE if Meta.hyper_unlocked else "Locked: " + HyperData.LOCK_TEXT
		_detail.add_theme_color_override("font_color", UiTheme.TEXT_DIM if Meta.hyper_unlocked else Palette.CRIMSON.lightened(0.4))
		return
	if id == "":
		id = config.skin_id
	var row := SkinData.skin(id)  # The skin's data.
	if row.is_empty():
		_detail.text = ""
		return
	if Meta.is_skin_unlocked(id):
		_detail.text = "Default look" if String(row["kind"]) == "default" else String(row["display_name"])
		_detail.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if id == config.skin_id else UiTheme.TEXT)
	else:
		var prog := Meta.skin_progress(id)  # "n / goal" or "".
		_detail.text = "%s: %s%s" % [String(row["display_name"]), String(row["unlock_short"]), ("  (%s)" % prog if prog != "" else "")]
		_detail.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.4))


## Every tile, left to right (the skins, then Hyper).
func cards() -> Array:
	var out: Array = []  # Buttons.
	for id: String in _skin_ids:
		out.append(_skin_buttons[id])
	out.append(_hyper_button)
	return out


## The tiles as focus rows (one row, left to right), for the setup screen's
## explicit focus wiring.
func rows() -> Array:
	return [cards()]


## Hyper tile pressed: toggles Hyper (`denied` while locked).
func _toggle_hyper() -> void:
	if not Meta.hyper_unlocked:
		Sfx.play_ui("denied")  # Locked.
		return
	config.hyper = not config.hyper
	Sfx.play("ui_confirm")
	refresh()
	changed.emit()


## Skin tile pressed: wears skin `id` if it is unlocked.
func _choose_skin(id: String) -> void:
	if not Meta.is_skin_unlocked(id):
		Sfx.play_ui("denied")  # Locked.
		return
	config.skin_id = id
	Sfx.play("ui_confirm")
	refresh()
	_show_detail(id)
	changed.emit()


## Turns Hyper off (the setup screen's Standard button).
func reset() -> void:
	config.hyper = false
	refresh()


## Redraws the states; rebuilds the skin tiles when the character changed
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
	_hyper_state.text = ("On" if config.hyper else "Off") if unlocked else "Locked"
	_hyper_state.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if config.hyper else (UiTheme.TEXT_DIM if unlocked else Palette.CRIMSON.lightened(0.4)))
	_hyper_badge.visible = Meta.is_hyper_cleared(config.stage_id, _character)
	for id: String in _skin_ids:
		_style(_skin_buttons[id], id == config.skin_id)
	var f := get_viewport().gui_get_focus_owner() if is_inside_tree() else null  # Current focus.
	if f == null or not is_ancestor_of(f):
		_show_detail("")


## Applies the on / worn look to tile `b` (normal and hover styles).
static func _style(b: Button, on: bool) -> void:
	UiTheme.style_button(b, "button", ON_ACCENT if on else "")
