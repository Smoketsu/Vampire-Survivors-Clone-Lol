## RelicTile — one focusable tile of the relic / Grave Offering screens (Ossuary
## expansion steps 5 and 6a, GDD §15.0 "Relics and Grave Offerings"): the Ossuary's
## Relics and Offerings tabs (OssuaryRelicsPanel, OssuaryOfferingsPanel), the
## pre-run setup screen's Rites strip (PreRunRites) and its picker (RitePicker).
## A kit button with the item's 32 px badge (or a smaller one on the strip), its
## name and ONE short line, plus a corner tag: the Soul Ash symbol and a price, or
## a word ("Owned", a feat word, "Empty"). The frame accent carries the state, as
## on the Ossuary's upgrade tiles (OssuaryTile): soul teal = affordable, violet =
## too expensive / idle, gold = owned or chosen, dim = locked (padlock over the
## icon), crimson = an offering the balance cannot pay. Feedback (real time,
## skipped with Reduce motion and under the autotest through UiMotion.enabled()):
## flash() after a purchase, shake() after a denied press. It never touches Meta:
## its screen reads and buys, the tile only shows.
class_name RelicTile
extends Button

## Item id the tile shows (a RelicData / OfferingData id, a slot key, or "").
var item_id: String = ""
## Badge icon (IconGlyph).
var icon_glyph: IconGlyph
## Name label (NAME tier on big tiles, BODY on compact ones).
var name_label: Label
## The short effect line (BODY tier; hidden on compact tiles).
var line_label: Label
## Small Soul Ash symbol in front of the price.
var cost_icon: IconGlyph
## Price or state word (BODY tier).
var cost_label: Label
## True while locked (draws the padlock over the icon).
var locked: bool = false
## Real-time stamp (s) when the purchase flash started (-1 = none).
var _flash_t0: float = -1.0
## Real-time stamp (s) when the denied shake started (-1 = none).
var _shake_t0: float = -1.0
## Rest x position (layout px) while shaking.
var _shake_base: float = 0.0
## Overlay drawing the padlock and the flash over the children.
var _fx: Control


## A tile of `size_px` for `id` with badge `icon`, `title` and `line` ("" = no
## line); `compact` uses the BODY tier for the name and a `icon_px` badge.
func _init(id: String, icon: String, title: String, line: String, size_px: Vector2, compact: bool = false,
		icon_px: float = OssuaryUiData.TILE_ICON) -> void:
	item_id = id
	custom_minimum_size = size_px
	focus_mode = Control.FOCUS_ALL
	clip_contents = false
	if not compact:
		set_meta(&"ui_lift", true)  # Lift on hover / focus like the Ossuary tiles (UiMotion).
	var row := HBoxContainer.new()  # Icon | name over the line + price.
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = RelicUiData.TILE_PAD.x
	row.offset_right = -RelicUiData.TILE_PAD.x
	row.offset_top = RelicUiData.TILE_PAD.y
	row.offset_bottom = -RelicUiData.TILE_PAD.y
	row.add_theme_constant_override("separation", RelicUiData.TILE_ICON_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	icon_glyph = IconGlyph.new(icon, Vector2(icon_px, icon_px))
	icon_glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon_glyph)
	var texts := VBoxContainer.new()  # Name line over the effect / price line.
	texts.add_theme_constant_override("separation", 0)
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if compact and title == "":
		row.alignment = BoxContainer.ALIGNMENT_CENTER  # A badge tile: badge (and price tag) centred.
		texts.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(texts)
	var top := HBoxContainer.new()  # The name (the compact tile keeps its price here too).
	top.add_theme_constant_override("separation", 4)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(top)
	name_label = UiTheme.tier_label(title, UiTheme.Tier.BODY if compact else UiTheme.Tier.NAME)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.visible = title != ""  # The strip's badge tiles have no name (the detail line names them).
	top.add_child(name_label)
	var bottom := HBoxContainer.new()  # The short effect and the price (big tiles).
	bottom.add_theme_constant_override("separation", 4)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.visible = not compact
	texts.add_child(bottom)
	line_label = UiTheme.tier_label(line, UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	line_label.clip_text = true
	line_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(line_label)
	var tag_row := top if compact else bottom  # Where the price / word goes.
	cost_icon = IconGlyph.new("soul_ash_small", Vector2(OssuaryUiData.COST_ICON, OssuaryUiData.COST_ICON))
	cost_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag_row.add_child(cost_icon)
	cost_label = UiTheme.tier_label("", UiTheme.Tier.BODY, OssuaryUiData.ASH_COLOR)
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag_row.add_child(cost_label)
	_fx = Control.new()
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.draw.connect(_draw_fx)
	add_child(_fx)


func _ready() -> void:
	SpriteBank.apply_sharp(_fx)
	set_process(false)


## Shows a new item: badge `icon`, `title`, `line` (the compact tile ignores it).
func set_item(id: String, icon: String, title: String, line: String = "") -> void:
	item_id = id
	icon_glyph.set_icon(icon)
	name_label.text = title
	name_label.visible = title != ""
	line_label.text = line


## Shows the state. `state`: "buy" (affordable: soul), "cost" (too expensive:
## violet, price dimmed red), "owned" / "chosen" (gold, `word` replaces the
## price), "locked" (dim, padlock, `word` instead of a price), "idle" (violet,
## `word` or the price), "short" (crimson: an offering the balance cannot pay).
## `price` < 0 hides the Soul Ash symbol and shows `word`.
func show_state(state: String, price: int, word: String = "") -> void:
	locked = state == "locked"
	var accent := "violet"  # Kit frame accent (UiTheme.style()).
	var name_col := UiTheme.TEXT  # Name colour.
	var cost_col := OssuaryUiData.ASH_COLOR  # Price / word colour.
	match state:
		"buy":
			accent = "soul"
		"cost":
			cost_col = OssuaryUiData.COST_SHORT
		"owned", "chosen":
			accent = "gold"
			name_col = UiTheme.TEXT_GOLD
			cost_col = UiTheme.TEXT_GOLD
		"locked":
			accent = "dim"
			name_col = UiTheme.TEXT_DIM
			cost_col = OssuaryUiData.GATE_WORD
		"short":
			accent = "crimson"
			cost_col = OssuaryUiData.DENIED
		"idle":
			cost_col = UiTheme.TEXT_DIM if price < 0 else OssuaryUiData.ASH_COLOR
	UiTheme.style_button(self, "button", accent)
	name_label.add_theme_color_override("font_color", name_col)
	cost_icon.visible = price >= 0
	cost_label.text = str(price) if price >= 0 else word
	cost_label.visible = cost_label.text != ""
	cost_label.add_theme_color_override("font_color", cost_col)
	icon_glyph.modulate = OssuaryUiData.LOCKED_ICON_TINT if locked else Color.WHITE
	_fx.queue_redraw()


## Purchase feedback: a short bright flash over the tile (skipped without motion).
func flash() -> void:
	if not UiMotion.enabled():
		return
	_flash_t0 = _now()
	set_process(true)


## Denied feedback: a short sideways shake (skipped without motion).
func shake() -> void:
	if not UiMotion.enabled():
		return
	if _shake_t0 < 0.0:
		_shake_base = position.x
	_shake_t0 = _now()
	set_process(true)


## Real time (s), unscaled (UI motion never follows Engine.time_scale).
static func _now() -> float:
	return float(Time.get_ticks_usec()) / 1000000.0


func _process(_delta: float) -> void:
	var t := _now()  # Real time now (s).
	var busy := false  # Something still animates.
	if _flash_t0 >= 0.0:
		if t - _flash_t0 >= OssuaryUiData.FLASH_TIME:
			_flash_t0 = -1.0
		else:
			busy = true
	if _shake_t0 >= 0.0:
		var age := t - _shake_t0  # Shake age (s).
		if age >= OssuaryUiData.SHAKE_TIME:
			_shake_t0 = -1.0
			position.x = _shake_base
			var box := get_parent() as Container  # Let the container re-apply its layout.
			if box != null:
				box.queue_sort()
		else:
			var k := 1.0 - age / OssuaryUiData.SHAKE_TIME  # Fades out.
			position.x = _shake_base + roundf(sin(age * OssuaryUiData.SHAKE_HZ * TAU) * OssuaryUiData.SHAKE_PX * k)
			busy = true
	_fx.queue_redraw()
	if not busy:
		set_process(false)


## Draws the padlock (locked) and the purchase flash over the tile.
func _draw_fx() -> void:
	if locked:
		var ip := icon_glyph.position + icon_glyph.get_parent_control().position  # Icon top-left in tile px.
		PixelMarks.draw_lock(_fx, ip + icon_glyph.size - Vector2(7, 9))
	if _flash_t0 < 0.0:
		return
	var age := _now() - _flash_t0  # Flash age (s).
	if age < OssuaryUiData.FLASH_TIME:
		var col := Color(OssuaryUiData.FLASH_COLOR, OssuaryUiData.FLASH_ALPHA * (1.0 - age / OssuaryUiData.FLASH_TIME))  # Fading flash.
		# Cut corners like the frame (owner rule): two overlapping rects 3 px in.
		_fx.draw_rect(Rect2(Vector2(5, 3), size - Vector2(10, 6)), col)
		_fx.draw_rect(Rect2(Vector2(3, 5), Vector2(2, size.y - 10)), col)
		_fx.draw_rect(Rect2(Vector2(size.x - 5, 5), Vector2(2, size.y - 10)), col)
