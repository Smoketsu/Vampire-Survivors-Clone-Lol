## OssuaryOfferingsPanel — the Ossuary's Offerings tab (Ossuary expansion step 6a,
## GDD §15.0 "Relics and Grave Offerings"; the tab contract: a Control with
## refresh() and `changed`, loaded by the Ossuary's tab bar). It only LISTS the
## Grave Offerings (OfferingData.ORDER): nothing is bought here; one is chosen on
## the pre-run setup screen's Rites strip and paid as its run starts. One header
## line, then two columns of RelicTiles (badge, name, the short effect, the price:
## Soul Ash orange when the balance can pay it, dimmed red when it cannot), and
## one detail line under them with the focused offering's full effect. Pressing a
## tile only shows its line (`ui_tick`). `changed` is never emitted (nothing is
## bought). Keyboard / pad: explicit neighbours between the tiles; the outer edges
## are left to the tab bar.
class_name OssuaryOfferingsPanel
extends VBoxContainer

## Never emitted (part of the tab contract: nothing is bought on this tab).
@warning_ignore("unused_signal")
signal changed

## Offering id -> its RelicTile.
var tiles: Dictionary = {}
## The detail line under the tiles.
var _detail: Label
## Offering shown in the detail line ("" = none yet).
var _focus_id: String = ""


func _ready() -> void:
	add_theme_constant_override("separation", RelicUiData.BLOCK_GAP)
	custom_minimum_size.x = RelicUiData.PANEL_WIDTH
	var head := UiTheme.tier_label(RelicUiData.OFFERINGS_LINE, UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	add_child(head)
	var grid := GridContainer.new()
	grid.columns = RelicUiData.OFFERING_COLUMNS
	grid.add_theme_constant_override("h_separation", RelicUiData.OFFERING_GAP.x)
	grid.add_theme_constant_override("v_separation", RelicUiData.OFFERING_GAP.y)
	add_child(grid)
	for id: String in OfferingData.ORDER:
		var row: Dictionary = OfferingData.OFFERINGS[id]
		var t := RelicTile.new(id, String(row["icon"]), String(row["display_name"]), String(row["short"]), RelicUiData.OFFERING_TILE)
		t.tooltip_text = String(row["description"])
		t.pressed.connect(_on_pressed.bind(id))
		t.focus_entered.connect(_show_detail.bind(id))
		t.mouse_entered.connect(_show_detail.bind(id))
		grid.add_child(t)
		tiles[id] = t
	var panel := UiTheme.ornate_panel("violet")
	panel.custom_minimum_size.x = RelicUiData.PANEL_WIDTH
	add_child(panel)
	_detail = UiTheme.para("", RelicUiData.PANEL_WIDTH - 60.0, UiTheme.TEXT)
	panel.add_child(_detail)
	_wire_focus()
	if not Meta.changed.is_connected(refresh):
		Meta.changed.connect(refresh)
	refresh()
	_show_detail(String(OfferingData.ORDER[0]))


## The first tile to focus when the tab opens.
func first_focus() -> Control:
	return tiles[OfferingData.ORDER[0]]


## The tiles as rows, top to bottom (for the tab bar's own wiring).
func focus_rows() -> Array:
	var out: Array = []  # Rows of tiles.
	for i in range(0, OfferingData.ORDER.size(), RelicUiData.OFFERING_COLUMNS):
		var row: Array = []
		for k in range(i, mini(OfferingData.ORDER.size(), i + RelicUiData.OFFERING_COLUMNS)):
			row.append(tiles[OfferingData.ORDER[k]])
		out.append(row)
	return out


## Explicit neighbours between the tiles (row ends and the top / bottom rows stay
## to the tab bar's geometry).
func _wire_focus() -> void:
	var rows := focus_rows()  # Tile rows.
	for r in rows.size():
		var row: Array = rows[r]
		for c in row.size():
			var t: Control = row[c]
			t.focus_neighbor_left = t.get_path_to(row[maxi(0, c - 1)])
			t.focus_neighbor_right = t.get_path_to(row[mini(row.size() - 1, c + 1)])
			if r > 0:
				t.focus_neighbor_top = t.get_path_to((rows[r - 1] as Array)[mini(c, (rows[r - 1] as Array).size() - 1)])
			if r < rows.size() - 1:
				t.focus_neighbor_bottom = t.get_path_to((rows[r + 1] as Array)[mini(c, (rows[r + 1] as Array).size() - 1)])


## Redraws the prices (affordable or not) and the detail line.
func refresh() -> void:
	if not is_inside_tree():
		return
	for id: String in OfferingData.ORDER:
		(tiles[id] as RelicTile).show_state("idle" if Meta.soul_ash >= OfferingData.price(id) else "cost", OfferingData.price(id))
	if _focus_id != "":
		_show_detail(_focus_id)


## Shows offering `id`'s full effect (and, when too dear, that it is) in the line.
func _show_detail(id: String) -> void:
	_focus_id = id
	var row: Dictionary = OfferingData.OFFERINGS[id]
	var text := "%s: %s" % [String(row["display_name"]), String(row["description"])]  # The line.
	if Meta.soul_ash < OfferingData.price(id):
		text += " " + RelicUiData.OFFERING_SHORT
	_detail.text = text


## A tile was pressed: nothing to buy here; the line names it.
func _on_pressed(id: String) -> void:
	_show_detail(id)
	Sfx.play_ui("ui_tick")
