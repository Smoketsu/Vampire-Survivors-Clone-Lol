## PreRunRites — the pre-run setup screen's "Rites" strip (Ossuary expansion steps
## 5 and 6a, GDD §15.0 "Relics and Grave Offerings"). It shares the setup panel's
## last row with the ultimate picker (the screen was already at the bottom hint
## strip at 1280 x 720, so the row keeps its height): under the section label
## (set by the screen), one badge tile per relic slot (RelicData.MAX_SLOTS) and the
## Grave Offering tile, then ONE clipped detail line naming the focused tile (or
## the choice): "1: Bone Abacus · A free reroll every 5 levels".
##   * an owned slot shows its relic's badge on a gold frame, or an empty socket;
##     pressing it opens the RitePicker on that slot (any owned relic or none;
##     one from another slot swaps places);
##   * a slot not bought yet is dim under a padlock with its price (pressing it
##     answers `denied`: slots are bought in the Ossuary's Relics tab);
##   * the offering tile shows the chosen offering's badge and price (gold while
##     the balance can pay it, crimson when it cannot: it is dropped on Begin),
##     or an empty ember socket; pressing it opens the offering picker.
## The relics travel in RunConfig.relics (slot order, no gaps) and the offering in
## RunConfig.offering_id; Begin remembers the relics (Meta.remember_prerun) and
## RelicLedger.prepare_run() finishes the choice. Every tile's tooltip holds the
## full effect. Keyboard / mouse / controller: tiles() gives the tiles for the
## setup screen's explicit focus wiring; Enter / A opens the picker. The co-op
## guest edits his own rites (they travel in his loadout).
class_name PreRunRites
extends VBoxContainer

## The relics or the offering changed (the setup screen redraws).
signal changed

## The config being edited (shared with the setup screen).
var config: RunConfig = null
## Slot tiles, slot 1 first.
var _slots: Array[RelicTile] = []
## The Grave Offering tile.
var _offering: RelicTile
## The one detail line under the tiles.
var _detail: Label
## The open picker (null while none).
var _picker: RitePicker = null


func _ready() -> void:
	if config == null:
		config = RunConfig.new()
	add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", RelicUiData.STRIP_GAP)
	add_child(row)
	for i in RelicData.MAX_SLOTS:
		var t := RelicTile.new("", "relic_slot", "", "", RelicUiData.STRIP_TILE, true, RelicUiData.STRIP_ICON)
		t.pressed.connect(_on_slot_pressed.bind(i + 1))
		t.focus_entered.connect(_show_detail.bind(i + 1))
		t.mouse_entered.connect(_show_detail.bind(i + 1))
		t.focus_exited.connect(_on_left)
		t.mouse_exited.connect(_on_left)
		row.add_child(t)
		_slots.append(t)
	_offering = RelicTile.new("", "offering_slot", "", "", RelicUiData.STRIP_TILE, true, RelicUiData.STRIP_ICON)
	_offering.pressed.connect(_on_offering_pressed)
	_offering.focus_entered.connect(_show_detail.bind(0))
	_offering.mouse_entered.connect(_show_detail.bind(0))
	_offering.focus_exited.connect(_on_left)
	_offering.mouse_exited.connect(_on_left)
	row.add_child(_offering)
	_detail = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_detail.clip_text = true
	_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_detail.custom_minimum_size.x = RelicUiData.STRIP_DETAIL_WIDTH
	add_child(_detail)
	refresh()


## Every tile, left to right (the slots, then the offering): the setup screen
## adds them to the ultimate picker's focus row.
func tiles() -> Array:
	var out: Array = []  # Tiles.
	for t in _slots:
		out.append(t)
	out.append(_offering)
	return out


## The tiles as focus rows (one row).
func rows() -> Array:
	return [tiles()]


## True while the picker is open (the setup screen leaves Esc to it).
func picker_open() -> bool:
	return _picker != null and is_instance_valid(_picker) and not UiMotion.is_closing(_picker)


## Redraws every tile from the config and the save (cuts the config's relics to
## the save's: owned, within the slots).
func refresh() -> void:
	var led := Meta.relics  # The save's relic ledger.
	config.relics = led.valid_equip(config.relics)
	for i in _slots.size():
		var n := i + 1  # Slot number.
		var t: RelicTile = _slots[i]
		if n > led.slots:
			t.set_item("", "relic_slot", "")
			t.show_state("locked", RelicData.slot_price(n))
			t.tooltip_text = RelicUiData.LOCKED_SLOT_TIP
		elif i < config.relics.size():
			var id := String(config.relics[i])  # The relic in this slot.
			var row: Dictionary = RelicData.RELICS[id]
			t.set_item(id, String(row["icon"]), "")
			t.show_state("chosen", -1, "")
			t.tooltip_text = "%s\n%s" % [String(row["display_name"]), String(row["description"])]
		else:
			t.set_item("", "relic_slot", "")
			t.show_state("idle", -1, "")
			t.tooltip_text = RelicUiData.EMPTY_SLOT_TIP if not led.owned.is_empty() else RelicUiData.NO_RELICS_TIP
	var off := config.offering_id  # The chosen offering ("" = none).
	if OfferingData.has(off):
		var orow: Dictionary = OfferingData.OFFERINGS[off]
		_offering.set_item(off, String(orow["icon"]), "")
		_offering.show_state("chosen" if led.offering_block(off, config.relics) == "" else "short", OfferingData.price(off))
		_offering.tooltip_text = "%s\n%s" % [String(orow["display_name"]), String(orow["description"])]
	else:
		_offering.set_item("", "offering_slot", "")
		_offering.show_state("idle", -1, "")
		_offering.tooltip_text = RelicUiData.OFFERING_TIP
	_on_left()


## The detail line for slot `n` (1..MAX_SLOTS) or the offering (0).
func _show_detail(n: int) -> void:
	var led := Meta.relics  # The save's relic ledger.
	var col := UiTheme.TEXT  # Line colour.
	var text := ""  # Line text.
	if n == 0:
		var off := config.offering_id  # The chosen offering.
		if OfferingData.has(off):
			var orow: Dictionary = OfferingData.OFFERINGS[off]
			text = RelicUiData.STRIP_OFFERING % [String(orow["display_name"]), String(orow["short"])]
			if led.offering_block(off, config.relics) != "":
				col = OssuaryUiData.DENIED
				text += " · " + RelicUiData.OFFERING_SHORT
		else:
			text = RelicUiData.STRIP_NO_OFFERING
			col = UiTheme.TEXT_DIM
	elif n > led.slots:
		text = RelicUiData.STRIP_LOCKED % [n, RelicData.slot_price(n)]
		col = OssuaryUiData.DENIED
	elif n - 1 < config.relics.size():
		var row: Dictionary = RelicData.RELICS[String(config.relics[n - 1])]
		text = RelicUiData.STRIP_RELIC % [n, String(row["display_name"]), String(row["short"])]
		col = UiTheme.TEXT_GOLD
	else:
		text = RelicUiData.STRIP_EMPTY % n
		col = UiTheme.TEXT_DIM
	_detail.text = text
	_detail.add_theme_color_override("font_color", col)


## A tile lost focus / hover: once none is focused, the line sums up the choice.
func _on_left() -> void:
	_check_left.call_deferred()


## The deferred half of _on_left(): the equipped relics and the offering, or the hint.
func _check_left() -> void:
	if not is_inside_tree():
		return
	var f := get_viewport().gui_get_focus_owner()  # Current focus.
	if f != null and is_ancestor_of(f):
		return
	var names := PackedStringArray()  # Chosen relic / offering names.
	for id: String in config.relics:
		names.append(String(RelicData.RELICS[id]["display_name"]))
	if OfferingData.has(config.offering_id):
		names.append(String(OfferingData.OFFERINGS[config.offering_id]["display_name"]))
	_detail.text = ", ".join(names) if not names.is_empty() else RelicUiData.STRIP_HINT
	_detail.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if not names.is_empty() else UiTheme.TEXT_DIM)


## Slot tile `n` pressed: the picker on that slot (`denied` while not bought).
func _on_slot_pressed(n: int) -> void:
	if n > Meta.relics.slots:
		Sfx.play_ui("denied")
		_slots[n - 1].shake()
		return
	Sfx.play_ui("ui_tick")
	_picker = RitePicker.open_relics(_host(), _slots[n - 1], config, n, _set_slot.bind(n))


## The offering tile pressed: the offering picker.
func _on_offering_pressed() -> void:
	Sfx.play_ui("ui_tick")
	_picker = RitePicker.open_offerings(_host(), _offering, config, _set_offering)


## Where the picker goes: the setup screen (the nearest PreRunSetup ancestor).
func _host() -> Control:
	var n: Node = get_parent()
	while n != null and not (n is PreRunSetup):
		n = n.get_parent()
	return n as Control if n != null else get_parent() as Control


## Puts relic `id` in slot `n` ("" = empties it). A relic already in another slot
## swaps places with this slot's (or moves, when this slot is empty); the list
## stays in slot order without gaps.
func _set_slot(id: String, n: int) -> void:
	var list := config.relics.duplicate()  # Equipped, slot order.
	var i := n - 1  # Slot index.
	var at := list.find(id) if id != "" else -1  # Where it is now (-1 = not equipped).
	if id == "":
		if i < list.size():
			list.remove_at(i)
	elif at == i:
		pass
	elif at >= 0 and i < list.size():
		list[at] = list[i]  # Swap the two slots.
		list[i] = id
	elif at >= 0:
		list.remove_at(at)  # Into an empty slot: it moves to the end of the list.
		list.append(id)
	elif i < list.size():
		list[i] = id
	else:
		list.append(id)
	config.relics = Meta.relics.valid_equip(list)
	refresh()
	changed.emit()


## Chooses offering `id` ("" = none).
func _set_offering(id: String) -> void:
	config.offering_id = id
	config.borrowed_relic = ""
	refresh()
	changed.emit()
