## RecipesPanel — the pause menu's Recipes view (owner decision "Evolution
## recipe book", GDD §15.0). Evolutions are meant to be discovered: this is
## the only place the game shows a recipe, and only for evolutions the player
## has already obtained in some run (Meta.discovered_recipes, the [recipes]
## save section). Menu modernization wave 2 (GDD §15.0 "Recipes book grid"):
## a grid of tiles in EvolutionRecipes.ids() order (so new recipes in
## EvolutionData / SummonEvolutionData appear automatically) inside an ornate
## panel, under a "7 / 23 discovered" count:
##   discovered — a gold-framed tile with the recipe as icons, base + passive
##                = evolution (RecipeIconRow; both bases for a merge);
##   locked     — a dark tile with three empty sockets, identical for every
##                undiscovered recipe (no names, no icons, no ingredient
##                count: owner rule, no hints).
## The focused / hovered tile's detail sits under the grid: the evolution's
## name and kind, and its ingredients with their levels (or just
## "Undiscovered"). Opened over the pause menu with
## RecipesPanel.open_over(parent, button_to_refocus); Back, Esc / controller
## B or the pause action close it. Fully keyboard / controller navigable: the
## tiles are a focus grid (arrows / D-pad), down from the last row is Back,
## and the first tile is focused on open. It never changes the run. Layout
## numbers and words are in RecipeBookData.
class_name RecipesPanel
extends Control

## Emitted when the view closes (before it is freed).
signal closed

## Control focused again when the view closes (may be null).
var return_focus: Control = null
## Focusable recipe tiles in display order.
var _rows: Array[Button] = []
## Back button.
var _back: Button
## Detail line: evolution name (NAME tier).
var _detail_name: Label
## Detail line: kind tag (LABEL tier).
var _detail_tag: Label
## Detail line: the ingredient row ("Name Lv 5" labels; the icons are on the tile).
var _detail_line: HBoxContainer


## An undiscovered recipe's tile face: three dark sockets joined by dim
## "+" and "=" marks, the last one holding a dim "?" (the same for every
## locked recipe).
class _LockedFace:
	extends Control

	func _init() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		SpriteBank.apply_sharp(self)

	func _draw() -> void:
		var s := RecipeBookData.SOCKET
		var gap := RecipeBookData.SOCKET_GAP
		var total := s * 3.0 + gap * 2.0  # Width of the three sockets and their gaps.
		var x0 := floorf((size.x - total) * 0.5)
		var y0 := floorf((size.y - s) * 0.5)
		for i in 3:
			var r := Rect2(Vector2(x0 + float(i) * (s + gap), y0), Vector2(s, s))
			PixelMarks.draw_socket(self, r, RecipeBookData.SOCKET_FILL, RecipeBookData.SOCKET_RIM)
		var cy := y0 + floorf(s * 0.5)  # Middle row of the marks.
		var mark := RecipeBookData.SOCKET_MARK
		var px := x0 + s + floorf(gap * 0.5) - 3.0  # "+" between sockets 1 and 2.
		draw_rect(Rect2(Vector2(px, cy - 1.0), Vector2(6, 2)), mark)
		draw_rect(Rect2(Vector2(px + 2.0, cy - 3.0), Vector2(2, 6)), mark)
		var ex := x0 + s * 2.0 + gap + floorf(gap * 0.5) - 3.0  # "=" between sockets 2 and 3.
		draw_rect(Rect2(Vector2(ex, cy - 3.0), Vector2(6, 2)), mark)
		draw_rect(Rect2(Vector2(ex, cy + 1.0), Vector2(6, 2)), mark)
		var f := UiTheme.font_for()
		if f != null:
			var q := RecipeBookData.LOCKED_GLYPH
			var qx := x0 + s * 2.0 + gap * 2.0  # Result socket.
			draw_string(f, Vector2(qx, y0 + s * 0.5 + 7.0), q, HORIZONTAL_ALIGNMENT_CENTER, s, UiTheme.tier_px(UiTheme.Tier.NAME), RecipeBookData.SOCKET_MARK.lightened(0.15))


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
	add_child(UiTheme.backdrop(0.78))
	var center := CenterContainer.new()  # Centres the content on screen.
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var vb := VBoxContainer.new()  # Title, count, panel, Back (with its Esc / B chip).
	vb.add_theme_constant_override("separation", 10)
	center.add_child(vb)
	vb.add_child(UiTheme.title(RecipeBookData.TITLE))
	vb.add_child(_build_count())
	var panel := UiTheme.ornate_panel("violet")
	vb.add_child(panel)
	var inner := VBoxContainer.new()  # Grid, divider, detail.
	inner.add_theme_constant_override("separation", 10)
	panel.add_child(inner)
	var grid := build_list(Meta.discovered_recipes, _rows)
	inner.add_child(grid)
	inner.add_child(UiTheme.divider("violet"))
	inner.add_child(_build_detail())
	_back = Button.new()
	_back.text = RecipeBookData.BACK
	_back.custom_minimum_size = Vector2(240, 44)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.set_meta(&"ui_back", true)
	_back.pressed.connect(close)
	InputHints.attach(_back, "ui_cancel", true, 12.0)
	vb.add_child(_back)
	var ids := EvolutionRecipes.ids()
	for i in _rows.size():
		_rows[i].focus_entered.connect(_show_detail.bind(ids[i]))
		_rows[i].mouse_entered.connect(_show_detail.bind(ids[i]))
	_link_focus()
	if not _rows.is_empty():
		_rows[0].grab_focus.call_deferred()
		_show_detail(ids[0])
	else:
		_back.grab_focus.call_deferred()
	UiMotion.open(self)  # Fade / rise in.
	UiMotion.stagger(_rows, 0.04, 0.012)


## "7 / 23" (HEADER, gold) and "DISCOVERED" (LABEL) centred.
func _build_count() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var num := UiTheme.tier_label(RecipeBookData.COUNT_NUM % [Meta.discovered_count(), EvolutionRecipes.ids().size()], UiTheme.Tier.HEADER, UiTheme.TEXT_GOLD)
	row.add_child(num)
	var word := UiTheme.tier_label(RecipeBookData.COUNT_WORD, UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(word)
	return row


## The detail block under the grid: name + tag row, ingredient row.
func _build_detail() -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size.y = RecipeBookData.DETAIL_HEIGHT
	box.add_theme_constant_override("separation", 2)
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	_detail_name = UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT_GOLD)
	head.add_child(_detail_name)
	_detail_tag = UiTheme.tier_label("", UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	_detail_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(_detail_tag)
	_detail_line = HBoxContainer.new()
	_detail_line.alignment = BoxContainer.ALIGNMENT_CENTER
	_detail_line.add_theme_constant_override("separation", 6)
	box.add_child(_detail_line)
	return box


## Builds the recipe grid for `discovered` (evolution id -> true) and
## returns it (one tile per recipe, EvolutionRecipes.ids() order); every
## tile's focus button is appended to `buttons`. Static and tree-free so the
## autotest can build it headless (it counts the children).
static func build_list(discovered: Dictionary, buttons: Array[Button]) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = RecipeBookData.COLUMNS
	grid.add_theme_constant_override("h_separation", RecipeBookData.TILE_GAP)
	grid.add_theme_constant_override("v_separation", RecipeBookData.TILE_GAP)
	for id: String in EvolutionRecipes.ids():
		grid.add_child(_make_tile(id, discovered.has(id), buttons))
	return grid


## One tile: a focusable kit button (gold frame when discovered, dim when
## not) holding the recipe icon row or the locked face.
static func _make_tile(id: String, known: bool, buttons: Array[Button]) -> Button:
	var b := Button.new()
	b.custom_minimum_size = RecipeBookData.TILE_SIZE
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta(&"ui_lift", true)
	UiTheme.style_button(b, "button", "gold" if known else "dim")
	buttons.append(b)
	if not known:
		b.add_child(_LockedFace.new())
		return b
	var row := RecipeIconRow.new()  # [base] + [passive] = [evolution].
	row.build(id)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(row)
	return b


## Shows recipe `id` in the detail block (or "Undiscovered").
func _show_detail(id: String) -> void:
	for c: Node in _detail_line.get_children():
		c.queue_free()
	if not Meta.is_recipe_discovered(id):
		_detail_name.text = RecipeBookData.LOCKED_TEXT
		_detail_name.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
		_detail_tag.text = ""
		return
	var r := EvolutionRecipes.recipe(id)  # Normalised recipe.
	_detail_name.text = String(r["name"])
	_detail_name.add_theme_color_override("font_color", UiTheme.TEXT_GOLD)
	var tag_key := "spell" if String(r["kind"]) == "spell" else String(r["mode"])  # RecipeBookData.TAGS key.
	_detail_tag.text = String(RecipeBookData.TAGS.get(tag_key, ""))
	var first := true
	for ing: Dictionary in r["ingredients"]:
		if not first:
			_detail_line.add_child(_mid_label(RecipeBookData.PLUS, UiTheme.TEXT_DIM))
		first = false
		_detail_line.add_child(_mid_label(RecipeBookData.INGREDIENT % [String(ing["name"]), int(ing["level"])], UiTheme.TEXT))


## A BODY-tier label centred vertically in the ingredient row.
static func _mid_label(s: String, color: Color) -> Label:
	var l := UiTheme.tier_label(s, UiTheme.Tier.BODY, color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


## Focuses tile `i` (screenshots, tests).
func focus_index(i: int) -> void:
	if i >= 0 and i < _rows.size():
		_rows[i].grab_focus()


## Explicit grid focus: arrows move between tiles (left / right also step to
## the previous / next row's end), down from the last row goes to Back, up
## from Back to the last tile; nothing leaves the view.
func _link_focus() -> void:
	var n := _rows.size()
	var cols := RecipeBookData.COLUMNS
	for i in n:
		var b := _rows[i]
		var up: Control = _rows[i - cols] if i - cols >= 0 else b
		var down: Control = _back
		if i + cols < n:
			down = _rows[i + cols]
		elif floori(float(i) / float(cols)) < floori(float(n - 1) / float(cols)):
			down = _rows[n - 1]  # A short last row: the nearest tile below.
		var left: Control = _rows[i - 1] if i > 0 else b
		var right: Control = _rows[i + 1] if i < n - 1 else b
		b.focus_neighbor_top = b.get_path_to(up)
		b.focus_neighbor_bottom = b.get_path_to(down)
		b.focus_neighbor_left = b.get_path_to(left)
		b.focus_neighbor_right = b.get_path_to(right)
		b.focus_previous = b.get_path_to(left)
		b.focus_next = b.get_path_to(right)
	var last: Control = _rows[n - 1] if n > 0 else _back
	_back.focus_neighbor_top = _back.get_path_to(last)
	_back.focus_neighbor_bottom = _back.get_path_to(_back)
	_back.focus_neighbor_left = _back.get_path_to(_back)
	_back.focus_neighbor_right = _back.get_path_to(_back)


## Closes the view and refocuses the button that opened it.
func close() -> void:
	if UiMotion.is_closing(self):
		return
	closed.emit()
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	UiMotion.close(self, queue_free)  # Quick fade out, then freed.


## Runs before PauseMenu._unhandled_input, so Esc / B / pause close this
## view instead of resuming the run.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
