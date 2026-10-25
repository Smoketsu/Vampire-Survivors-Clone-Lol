## PreRunHyperSkins — the skin selector and the Hyper mode toggle of the
## pre-run setup screen (PreRunSetup puts it in the hero panel, under the
## character's texts; GDD §15.0 "Front door screens"). One row:
##   * a small portrait tile per skin of the run's character
##     (SkinData.skins_for: default, Hyper skin, achievement skin, the two
##     universal skins; compact tiles past FrontDoorData.SKIN_TILES_FULL): a live
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
## At the right end of that line sits the RECOLOUR control (Ossuary expansion
## step 6b, RecolourData; cosmetic): one button with a colour chip and the
## recolour's name that cycles the chosen skin's offers (Default, then four
## palette swaps); an owned one is worn at once, an unowned one is only
## previewed on the hero and a Buy button with its Soul Ash price appears
## (a confirm dialog, the one UI that costs Soul Ash here). Hidden while the
## skin is locked. The choice is kept per skin in the Meta save ([recolour_pick]).
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
## Co-op guest (GDD §15.0 "Online co-op: relay and lobby"): the host owns Hyper,
## so the tile only shows the host's choice (pressing it is `denied`) and the
## guest's own Hyper lock never switches it off.
var host_owned: bool = false
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
## The line's row: the detail label, then the recolour controls.
var _line: HBoxContainer
## The recolour controls (cycle and Buy buttons); hidden while the skin is locked.
var _rc_box: HBoxContainer
## Recolour cycle button (chip, name).
var _rc_cycle: Button
## Colour chip inside the cycle button (the previewed recolour's swatch).
var _rc_chip: RecolourChip
## Name of the previewed recolour inside the cycle button.
var _rc_name: Label
## Recolour Buy button (soul ash icon, price); shown only for an unowned preview.
var _rc_buy: Button
## Price label inside the Buy button.
var _rc_cost: Label
## Skin the recolour state belongs to (the worn skin's id; "" = not built yet).
var _rc_skin: String = ""
## RecolourData id previewed on the hero ("" = the skin's own colours). The
## worn one (config.recolour_id) is this one while it is owned, else "".
var _rc_view: String = ""
## "<recolour box shown>/<Buy shown>" of the last _refresh_recolour() (re-wire on change).
var _rc_shape: String = ""
## Skin id -> its tile's preview (so the worn skin's tile shows the recolour).
var _previews: Dictionary = {}
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
	## RecolourData id drawn on it ("" = none; the worn skin's tile only).
	var recolour: String = ""

	func _init(id: String, is_locked: bool) -> void:
		skin_id = id
		locked = is_locked
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.02, 0.05, 0.9))
		SpriteBank.icon_cap = size.y * 0.92
		SkinGlyphs.draw_skin(self, skin_id, size * 0.5, size.y * 0.28, false, recolour)
		SpriteBank.icon_cap = 0.0
		if locked:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, CharacterGlyphs.LOCK_VEIL))
			var s := MaskIcon.art_size("padlock") * float(CharacterGlyphs.LOCK_ICON_SCALE)  # Padlock (px).
			MaskIcon.paint(self, "padlock", size * 0.5 - s * 0.5, CharacterGlyphs.LOCK_ICON_SCALE)


## The colour chip of the recolour button: a small square in the recolour's
## swatch colour with a dark border; a recolour of "" draws a hollow square
## (the skin's own colours).
class RecolourChip:
	extends Control
	## RecolourData id shown ("" = the skin's own colours).
	var recolour: String = ""

	func _init() -> void:
		custom_minimum_size = Vector2(14.0, 14.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)  # The chip box (px).
		draw_rect(r, Color(0.04, 0.02, 0.07))
		var inner := r.grow(-2.0)  # Fill, inside the border.
		if recolour == "":
			draw_rect(inner, Color(0.45, 0.4, 0.55), false, 1.0)
		else:
			draw_rect(inner, RecolourData.swatch(recolour))


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
	_line = HBoxContainer.new()
	_line.add_theme_constant_override("separation", 6)
	_line.custom_minimum_size.x = FrontDoorData.HERO_TEXT_WIDTH
	add_child(_line)
	_detail = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_detail.clip_text = true
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_line.add_child(_detail)
	_build_recolour_controls()
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
	_previews.clear()
	_character = config.character_key()
	_skin_ids = SkinData.skins_for(_character)
	# Content wave 2: more skins (the universal ones) -> compact tiles, so the row keeps its width.
	var compact := _skin_ids.size() > FrontDoorData.SKIN_TILES_FULL  # Compact row.
	_row.add_theme_constant_override("separation", FrontDoorData.SKIN_GAP_COMPACT if compact else 6)
	_hyper_button.custom_minimum_size = FrontDoorData.HYPER_TILE_COMPACT if compact else FrontDoorData.HYPER_TILE
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
	b.custom_minimum_size = FrontDoorData.SKIN_TILE_COMPACT if _skin_ids.size() > FrontDoorData.SKIN_TILES_FULL else FrontDoorData.SKIN_TILE
	b.focus_mode = Control.FOCUS_ALL
	b.tooltip_text = "%s\n%s" % [String(row["display_name"]), String(row["look"])]
	var p := SkinPreview.new(id, not unlocked)
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 4
	p.offset_top = 4
	p.offset_right = -4
	p.offset_bottom = -4
	b.add_child(p)
	_previews[id] = p
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
	if id == "recolour":
		_show_recolour_detail()
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


## The tiles as focus rows (the tiles, then the recolour buttons while shown),
## for the setup screen's explicit focus wiring.
func rows() -> Array:
	var out: Array = [cards()]  # The tiles, then the recolour buttons (when shown).
	if _rc_box.visible:
		var rc: Array = [_rc_cycle]  # Recolour buttons, left to right.
		if _rc_buy.visible:
			rc.append(_rc_buy)
		out.append(rc)
	return out


## Hyper tile pressed: toggles Hyper (`denied` while locked).
func _toggle_hyper() -> void:
	if not Meta.hyper_unlocked or host_owned:
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
	rebuilt.emit()  # The recolour buttons may appear or go (the setup screen re-wires its focus).


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
	var unlocked := Meta.hyper_unlocked or host_owned  # The toggle may be used (co-op guest: shows the host's choice).
	if not unlocked:
		config.hyper = false
	_style(_hyper_button, config.hyper)
	_hyper_state.text = ("On" if config.hyper else "Off") if unlocked else "Locked"
	_hyper_state.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if config.hyper else (UiTheme.TEXT_DIM if unlocked else Palette.CRIMSON.lightened(0.4)))
	_hyper_badge.visible = Meta.is_hyper_cleared(config.stage_id, _character)
	for id: String in _skin_ids:
		_style(_skin_buttons[id], id == config.skin_id)
	_sync_recolour()
	var f := get_viewport().gui_get_focus_owner() if is_inside_tree() else null  # Current focus.
	if f == null or not is_ancestor_of(f):
		_show_detail("")


## Applies the on / worn look to tile `b` (normal and hover styles).
static func _style(b: Button, on: bool) -> void:
	UiTheme.style_button(b, "button", ON_ACCENT if on else "")


# --- Recolour control (Ossuary expansion step 6b) -----------------------------------------------

## Builds the recolour controls at the right end of the detail line: the cycle
## button (chip and name) and the Buy button (Soul Ash icon and price).
func _build_recolour_controls() -> void:
	_rc_box = HBoxContainer.new()
	_rc_box.add_theme_constant_override("separation", 4)
	_rc_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_rc_box.visible = false
	_line.add_child(_rc_box)
	_rc_cycle = Button.new()
	_rc_cycle.custom_minimum_size = FrontDoorData.RECOLOUR_BUTTON
	_rc_cycle.focus_mode = Control.FOCUS_ALL
	_rc_cycle.tooltip_text = "Recolour: change this skin's colours"
	_rc_cycle.pressed.connect(_cycle_recolour)
	_rc_cycle.focus_entered.connect(_on_rc_focus)
	_rc_cycle.mouse_entered.connect(_on_rc_focus)
	_rc_cycle.focus_exited.connect(_on_left)
	_rc_cycle.mouse_exited.connect(_on_left)
	var cb := HBoxContainer.new()
	cb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cb.offset_left = 8
	cb.offset_right = -8
	cb.add_theme_constant_override("separation", 6)
	cb.alignment = BoxContainer.ALIGNMENT_CENTER
	cb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rc_cycle.add_child(cb)
	_rc_chip = RecolourChip.new()
	cb.add_child(_rc_chip)
	_rc_name = UiTheme.tier_label("Default", UiTheme.Tier.BODY, UiTheme.TEXT)
	_rc_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cb.add_child(_rc_name)
	_rc_box.add_child(_rc_cycle)
	_rc_buy = Button.new()
	_rc_buy.custom_minimum_size = FrontDoorData.RECOLOUR_BUY_BUTTON
	_rc_buy.focus_mode = Control.FOCUS_ALL
	_rc_buy.pressed.connect(_press_buy)
	_rc_buy.focus_entered.connect(_on_rc_focus)
	_rc_buy.mouse_entered.connect(_on_rc_focus)
	_rc_buy.focus_exited.connect(_on_left)
	_rc_buy.mouse_exited.connect(_on_left)
	var bb := HBoxContainer.new()
	bb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bb.offset_left = 8
	bb.offset_right = -8
	bb.add_theme_constant_override("separation", 4)
	bb.alignment = BoxContainer.ALIGNMENT_CENTER
	bb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rc_buy.add_child(bb)
	var coin := IconGlyph.new("soul_ash_small", Vector2(OssuaryUiData.COST_ICON, OssuaryUiData.COST_ICON))
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bb.add_child(coin)
	_rc_cost = UiTheme.tier_label("", UiTheme.Tier.BODY, OssuaryUiData.ASH_COLOR)
	_rc_cost.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bb.add_child(_rc_cost)
	_rc_buy.visible = false
	_rc_box.add_child(_rc_buy)


## The recolour state follows the worn skin: on a new skin it shows that skin's
## remembered recolour (the first time, the config's own if it is owned), and
## the controls hide while the skin is locked.
func _sync_recolour() -> void:
	var skin := config.skin_id  # Worn skin id.
	var offers := skin != "" and Meta.is_skin_unlocked(skin) and not RecolourData.ids_for(skin).is_empty()  # Recolours may be used.
	if skin != _rc_skin:
		var want := config.recolour_id if (_rc_skin == "" and Meta.owns_recolour(skin, config.recolour_id)) else Meta.chosen_recolour(skin)  # Recolour shown.
		_rc_skin = skin
		_rc_view = want if offers else ""
		config.recolour_id = _rc_view
	_rc_box.visible = offers
	_refresh_recolour()


## Redraws the recolour controls and the tile previews from `_rc_view`; asks the
## setup screen to re-wire focus when the buttons that exist changed.
func _refresh_recolour() -> void:
	var owned := _rc_view == "" or Meta.owns_recolour(_rc_skin, _rc_view)  # The previewed recolour may be worn.
	_rc_chip.recolour = _rc_view
	_rc_chip.queue_redraw()
	_rc_name.text = RecolourData.display_name(_rc_view)
	var shape := "%s/%s" % [str(_rc_box.visible), str(_rc_box.visible and not owned)]  # Which buttons exist now.
	_rc_buy.visible = _rc_box.visible and not owned
	if not owned:
		_rc_cost.text = str(RecolourData.price(_rc_view))
		var can := Meta.soul_ash >= RecolourData.price(_rc_view)  # Affordable: the soul accent.
		UiTheme.style_button(_rc_buy, "button", "soul" if can else "dim")
		_rc_cost.add_theme_color_override("font_color", OssuaryUiData.ASH_COLOR if can else UiTheme.TEXT_DIM)
	UiTheme.style_button(_rc_cycle, "button", ON_ACCENT if (_rc_view != "" and owned) else "")
	for id: String in _previews:
		var pv: SkinPreview = _previews[id]
		var rc := config.recolour_id if id == config.skin_id else Meta.chosen_recolour(id)  # Recolour that tile would wear.
		if pv.recolour != rc:
			pv.recolour = rc
			pv.queue_redraw()
	if shape != _rc_shape:
		_rc_shape = shape
		rebuilt.emit()


## The recolour previewed on the hero for the worn skin ("" = its own colours).
func shown_recolour() -> String:
	return _rc_view


## Previews recolour `id` ("" = the skin's own colours) on the worn skin: an owned
## one (or "") is worn and remembered at once; an unowned one is only shown, with
## its price and a Buy button. Ignored while the skin is locked / offers no such
## recolour.
func preview_recolour(id: String) -> void:
	if not _rc_box.visible or (id != "" and not RecolourData.offered(_rc_skin, id)):
		return
	_rc_view = id
	var owned := id == "" or Meta.owns_recolour(_rc_skin, id)  # May be worn.
	config.recolour_id = id if owned else ""
	if owned:
		Meta.set_chosen_recolour(_rc_skin, id)
	_refresh_recolour()
	_show_detail("recolour")
	changed.emit()


## The cycle button pressed: the next recolour of the skin (Default first).
func _cycle_recolour() -> void:
	var options := PackedStringArray([""])  # Default, then the skin's offers.
	options.append_array(RecolourData.ids_for(_rc_skin))
	var i := options.find(_rc_view)  # Position now (-1 = unknown: start from Default).
	Sfx.play_ui("ui_tick")
	preview_recolour(options[(i + 1) % options.size()])


## The Buy button pressed: a confirm dialog (Soul Ash is spent), or `denied`
## when the Soul Ash is short.
func _press_buy() -> void:
	if Meta.recolour_block(_rc_skin, _rc_view) != "":
		Sfx.play_ui("denied")
		_show_detail("recolour")
		return
	var skin := _rc_skin  # Skin bought for (captured: the dialog is modal).
	var id := _rc_view  # Recolour bought.
	if GameState.autotest:
		_buy_now(skin, id)  # Nothing opens a dialog under the autotest.
		return
	ConfirmDialog.ask(_dialog_host(), "Buy %s?" % RecolourData.display_name(id), "%d Soul Ash. This skin keeps it." % RecolourData.price(id),
			"Buy", _buy_now.bind(skin, id), false)


## Buys recolour `id` of `skin` and wears it.
func _buy_now(skin: String, id: String) -> void:
	if not Meta.buy_recolour(skin, id):
		Sfx.play_ui("denied")
		return
	Sfx.play_ui("purchase")
	Meta.set_chosen_recolour(skin, id)
	if skin == _rc_skin:
		_rc_view = id
		config.recolour_id = id
		_refresh_recolour()
		_show_detail("recolour")
		changed.emit()
		_rc_cycle.grab_focus.call_deferred()  # The Buy button just went away.


## The full-screen control a dialog opens over: the setup screen (else this row).
func _dialog_host() -> Control:
	var n: Node = self  # Walks up to the PreRunSetup.
	while n != null and not (n is PreRunSetup):
		n = n.get_parent()
	return (n as Control) if n != null else self


## A recolour button focused / hovered: name the recolour, show the worn skin on the hero.
func _on_rc_focus() -> void:
	_show_detail("recolour")
	skin_focused.emit("")


## Detail line for the previewed recolour: its name and, when unowned, its price
## (soul-teal text cannot show here: the amber ash colour when affordable, dim crimson when short).
func _show_recolour_detail() -> void:
	var owned := _rc_view == "" or Meta.owns_recolour(_rc_skin, _rc_view)  # May be worn.
	if _rc_view == "":
		_detail.text = "Own colours"
		_detail.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
	elif owned:
		_detail.text = "%s recolour" % RecolourData.display_name(_rc_view)
		_detail.add_theme_color_override("font_color", UiTheme.TEXT_GOLD)
	else:
		var price := RecolourData.price(_rc_view)  # Soul Ash.
		var short := price - Meta.soul_ash  # Missing Soul Ash (> 0 = cannot buy).
		_detail.text = "%s: %d Soul Ash" % [RecolourData.display_name(_rc_view), price] if short <= 0 else "%s: %d more Soul Ash" % [RecolourData.display_name(_rc_view), short]
		_detail.add_theme_color_override("font_color", OssuaryUiData.ASH_COLOR if short <= 0 else Palette.CRIMSON.lightened(0.4))
