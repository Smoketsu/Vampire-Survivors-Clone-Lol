## RecipesPanel — the pause menu's Recipes view (owner decision "Evolution
## recipe book", GDD §15.0). Evolutions are meant to be discovered: this is
## the only place the game shows a recipe, and only for evolutions the player
## has already obtained in some run (Meta.discovered_recipes, the [recipes]
## save section). One row per recipe in EvolutionRecipes.ids() order, so new
## recipes in EvolutionData / SummonEvolutionData appear automatically:
##   discovered — the evolution's icon and name, its kind, and the recipe as
##                "[icon] Shadow Bolt Lv 5 + [icon] Soul Conduit Lv 5 -> Void
##                Barrage" (both bases for a merge),
##   locked     — a dark "?" tile with no name or ingredients.
## A "N / M discovered" count sits under the title. Opened over the pause
## menu with RecipesPanel.open_over(parent, button_to_refocus); Back, Esc /
## controller B or the pause action close it. Fully keyboard / controller
## navigable: every row takes focus (up / down), the list scrolls to follow
## focus, and the first row is focused on open. It never changes the run.
class_name RecipesPanel
extends Control

## Emitted when the view closes (before it is freed).
signal closed

## Width in px of one recipe row.
const ROW_WIDTH: float = 640.0
## Height in px of the scrolling recipe list.
const LIST_HEIGHT: float = 430.0
## Size in px of the evolution icon / locked tile at the left of a row.
const ICON_SIZE: float = 48.0
## Size in px of an ingredient icon in the recipe line.
const CHIP_ICON_SIZE: float = 22.0
## Inner padding of a row in px (left / right).
const ROW_PAD_X: int = 12
## Inner padding of a row in px (top / bottom).
const ROW_PAD_Y: int = 8

## Control focused again when the view closes (may be null).
var return_focus: Control = null
## Focusable row buttons in display order.
var _rows: Array[Button] = []
## Back button.
var _back: Button


## Creates the view as a full-screen child of `parent` and returns it.
## `refocus` regains focus when it closes.
static func open_over(parent: Control, refocus: Control) -> RecipesPanel:
	var p := RecipesPanel.new()
	p.return_focus = refocus
	parent.add_child(p)
	return p


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UiTheme.backdrop(0.7))
	var center := CenterContainer.new()  # Centres the panel on screen.
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()  # Framed panel.
	center.add_child(panel)
	var vb := VBoxContainer.new()  # Title, count, list, Back.
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var title := UiTheme.label(RecipeBookData.TITLE, 30, UiTheme.TEXT_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var count := UiTheme.label(RecipeBookData.COUNT % [Meta.discovered_count(), EvolutionRecipes.ids().size()], 15, UiTheme.TEXT_DIM)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(count)
	var scroll := ScrollContainer.new()  # Scrolls the rows; follows keyboard / pad focus.
	scroll.custom_minimum_size = Vector2(ROW_WIDTH + 14.0, LIST_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	vb.add_child(scroll)
	scroll.add_child(build_list(Meta.discovered_recipes, _rows))
	_back = Button.new()
	_back.text = "Back"
	_back.custom_minimum_size = Vector2(0, 44)
	_back.pressed.connect(close)
	vb.add_child(_back)
	_link_focus()
	if not _rows.is_empty():
		_rows[0].grab_focus.call_deferred()
	else:
		_back.grab_focus.call_deferred()


## Builds the recipe rows for `discovered` (evolution id -> true) and returns
## their column; every row's focus button is appended to `buttons`. Static
## and tree-free so the autotest can build it headless.
static func build_list(discovered: Dictionary, buttons: Array[Button]) -> VBoxContainer:
	var list := VBoxContainer.new()  # One row per recipe.
	list.add_theme_constant_override("separation", 6)
	for id: String in EvolutionRecipes.ids():
		var row := _make_row(id, discovered.has(id), buttons)
		list.add_child(row)
	return list


## One row: a MarginContainer holding a focusable Button (focus / hover
## frame) under a padded content row, like the level-up cards, so it grows
## to fit its text. `known` = discovered.
static func _make_row(id: String, known: bool, buttons: Array[Button]) -> Control:
	var row := MarginContainer.new()  # Row root; its size is the max of its children.
	row.custom_minimum_size = Vector2(ROW_WIDTH, 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := Button.new()  # Focus target (no action).
	b.focus_mode = Control.FOCUS_ALL
	row.add_child(b)
	buttons.append(b)
	var pad := MarginContainer.new()  # Padding around the content.
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", ROW_PAD_X)
	pad.add_theme_constant_override("margin_right", ROW_PAD_X)
	pad.add_theme_constant_override("margin_top", ROW_PAD_Y)
	pad.add_theme_constant_override("margin_bottom", ROW_PAD_Y)
	row.add_child(pad)
	var hb := HBoxContainer.new()  # Icon | text column.
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 12)
	pad.add_child(hb)
	var text := VBoxContainer.new()  # Name line, recipe line.
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	if not known:
		hb.add_child(_locked_tile())
		hb.add_child(text)
		text.add_child(UiTheme.label(RecipeBookData.LOCKED_NAME, 18, UiTheme.TEXT_DIM))
		var lt := UiTheme.label(RecipeBookData.LOCKED_TEXT, 13, UiTheme.TEXT_DIM)
		lt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(lt)
		pad.modulate = Color(1, 1, 1, RecipeBookData.LOCKED_ALPHA)  # Dims the content, not the focus frame.
		return row
	var r := EvolutionRecipes.recipe(id)  # Normalised recipe.
	var icon_box := CenterContainer.new()  # Keeps the icon square in a tall row.
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_child(IconGlyph.new(String(r["icon"]), Vector2(ICON_SIZE, ICON_SIZE)))
	hb.add_child(icon_box)
	hb.add_child(text)
	var head := HBoxContainer.new()  # Name + kind tag.
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := UiTheme.label(String(r["name"]), 18, UiTheme.TEXT_GOLD)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	var tag_key := "spell" if String(r["kind"]) == "spell" else String(r["mode"])  # RecipeBookData.TAGS key.
	head.add_child(UiTheme.label(String(RecipeBookData.TAGS.get(tag_key, "")), 12, UiTheme.TEXT_DIM))
	text.add_child(head)
	var line := HFlowContainer.new()  # Ingredients + arrow + evolution; wraps if long.
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("h_separation", 6)
	line.add_theme_constant_override("v_separation", 2)
	var first := true
	for ing: Dictionary in r["ingredients"]:
		if not first:
			line.add_child(_mid_label(RecipeBookData.PLUS, UiTheme.TEXT_DIM))
		first = false
		line.add_child(IconGlyph.new(String(ing["icon"]), Vector2(CHIP_ICON_SIZE, CHIP_ICON_SIZE)))
		line.add_child(_mid_label(RecipeBookData.INGREDIENT % [String(ing["name"]), int(ing["level"])], UiTheme.TEXT))
	line.add_child(_mid_label(RecipeBookData.ARROW, UiTheme.TEXT_DIM))
	line.add_child(_mid_label(String(r["name"]), UiTheme.TEXT_GOLD))
	text.add_child(line)
	return row


## A 13 px label centred vertically in the recipe line.
static func _mid_label(s: String, color: Color) -> Label:
	var l := UiTheme.label(s, 13, color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(0, CHIP_ICON_SIZE)
	return l


## The dark "?" tile of a locked recipe (same size as an evolution icon).
static func _locked_tile() -> Control:
	var tile := PanelContainer.new()  # Dark framed square.
	tile.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_theme_stylebox_override("panel", UiTheme.style("panel", "dim"))  # Dark locked frame (UI kit).
	var q := UiTheme.label(RecipeBookData.LOCKED_GLYPH, 26, UiTheme.TEXT_DIM)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tile.add_child(q)
	return tile


## Chains focus explicitly: rows top to bottom, then Back, wrapping around,
## so up / down never leave the view.
func _link_focus() -> void:
	var chain: Array[Control] = []
	for b in _rows:
		chain.append(b)
	chain.append(_back)
	for i in chain.size():
		var prev := chain[(i - 1 + chain.size()) % chain.size()]
		var nxt := chain[(i + 1) % chain.size()]
		chain[i].focus_neighbor_top = chain[i].get_path_to(prev)
		chain[i].focus_neighbor_bottom = chain[i].get_path_to(nxt)
		chain[i].focus_neighbor_left = chain[i].get_path_to(chain[i])
		chain[i].focus_neighbor_right = chain[i].get_path_to(chain[i])
		chain[i].focus_previous = chain[i].get_path_to(prev)
		chain[i].focus_next = chain[i].get_path_to(nxt)


## Closes the view and refocuses the button that opened it.
func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	queue_free()


## Runs before PauseMenu._unhandled_input, so Esc / B / pause close this
## view instead of resuming the run.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
