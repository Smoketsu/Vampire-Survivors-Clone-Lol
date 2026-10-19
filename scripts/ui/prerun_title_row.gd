## PreRunTitleRow — the title picker of the pre-run setup screen (content
## wave 2, owner-approved Proposal 2; PreRunSetup puts it in the hero panel
## under the skin / Hyper row). One small row:
##   * a cycle tile: "Title" and the worn title (gold) or "None"; pressing it
##     (Enter / A / click) wears the next unlocked title, then None again
##     (Meta.set_selected_title(): a free, reversible cosmetic choice, saved
##     at once); with no title earned it is `denied`,
##   * one detail line: how many titles are earned and, while some are
##     locked, the next locked one; the tile's (and the line's) tooltip lists
##     every title and how to earn it (and so does the Codex).
## The worn title shows under the character's name on the hero (PreRunHero),
## with its portrait frame (Heretic's Bane: TitleFrame). Titles are purely
## cosmetic. rows() gives the tile as one focus row for the setup screen's
## explicit focus wiring.
class_name PreRunTitleRow
extends HBoxContainer

## The worn title changed (the setup screen redraws the hero).
signal changed

## UI kit accent of the tile while a title is worn (gold = selection).
const ON_ACCENT: String = "gold"

## The cycle tile.
var _button: Button
## The tile's title name label.
var _name: Label
## The detail line.
var _detail: Label


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_button = Button.new()
	_button.custom_minimum_size = TitleData.ROW_TILE
	_button.focus_mode = Control.FOCUS_ALL
	_button.pressed.connect(_cycle)
	add_child(_button)
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 10
	box.offset_right = -10
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button.add_child(box)
	var lab := UiTheme.tier_label(TitleData.ROW_LABEL, UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	lab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(lab)
	_name = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT)
	_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.clip_text = true
	box.add_child(_name)
	_detail = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_detail.clip_text = true
	_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_detail.mouse_filter = Control.MOUSE_FILTER_PASS  # For its tooltip.
	add_child(_detail)
	refresh()


## The choices the tile cycles through: "" (none), then every unlocked title.
func choices() -> PackedStringArray:
	var out := PackedStringArray([""])
	out.append_array(Meta.unlocked_titles())
	return out


## The tile as focus rows (one row of one), for the setup screen's wiring.
func rows() -> Array:
	return [[_button]]


## Tile pressed: wears the next choice (`denied` with no title earned).
func _cycle() -> void:
	var opts := choices()  # None + unlocked titles.
	if opts.size() <= 1:
		Sfx.play_ui("denied")  # Nothing earned yet.
		return
	var i := opts.find(Meta.selected_title())  # Current choice (-1 = none found: start over).
	Meta.set_selected_title(opts[(i + 1) % opts.size()])
	Sfx.play("ui_confirm")
	refresh()
	changed.emit()


## Redraws the tile, the detail line and the tooltip.
func refresh() -> void:
	var worn := Meta.selected_title()  # "" = none.
	_name.text = TitleData.display_text(worn) if worn != "" else TitleData.NONE_TEXT
	_name.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if worn != "" else UiTheme.TEXT_DIM)
	UiTheme.style_button(_button, "button", ON_ACCENT if worn != "" else "")
	var earned := Meta.unlocked_titles()  # Unlocked titles.
	var text := TitleData.COUNT_TEXT % [earned.size(), TitleData.ORDER.size()]  # Detail line.
	var tips := PackedStringArray()  # Tooltip lines, one per title.
	var next := ""  # First locked title.
	for id: String in TitleData.ORDER:
		var open := earned.has(id)  # Earned.
		if not open and next == "":
			next = id
		tips.append("%s: %s" % [TitleData.display_text(id), "earned" if open else Unlocks.lock_text(id)])
	if next != "":
		text += TitleData.NEXT_TEXT % TitleData.display_text(next)
	_detail.text = text
	_button.tooltip_text = "\n".join(tips)
	_detail.tooltip_text = _button.tooltip_text
