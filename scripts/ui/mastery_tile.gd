## MasteryTile — one summon-class tile of the Ossuary's Masteries tab
## (OssuaryMasteriesPanel; Ossuary expansion step 4, GDD §15.0 "Ossuary
## Masteries"): a focusable kit button showing the class's icon, its name, three
## level pips and the next price (the small Soul Ash symbol and a number; "MAX"
## when bought out; the dim word "Lv 5" while the class has not reached level 5
## in a run, with the icon darkened and a padlock over it). The frame accent
## carries the state like OssuaryTile: soul teal = affordable, violet = too
## expensive, gold = maxed, dim = locked. The effect and the unlock hint live in
## the panel's one detail strip. It never touches Meta: the panel reads and
## buys, the tile only shows. flash() and shake() are short real-time tweens
## (skipped with Reduce motion and under the autotest through UiMotion.enabled()).
class_name MasteryTile
extends Button

## Summon class id (a MasteryData.CLASSES entry).
var class_id: String = ""
## Class icon (IconGlyph, OssuaryUiData.TILE_ICON px).
var icon_glyph: IconGlyph
## Class name label (NAME tier).
var name_label: Label
## The three level pips.
var pips: PixelMarks.Pips
## Small Soul Ash symbol in front of the price.
var cost_icon: IconGlyph
## Price label (BODY tier), "MAX" when maxed, "Lv 5" when locked.
var cost_label: Label
## True while the class has not reached level 5 (draws the padlock over the icon).
var locked: bool = false
## Inner row holding icon and texts (the shake moves it, never the tile itself).
var _row: HBoxContainer
## Overlay Control drawing the padlock over the children.
var _fx: Control


func _init(cls: String) -> void:
	class_id = cls
	custom_minimum_size = OssuaryUiData.TILE_SIZE
	focus_mode = Control.FOCUS_ALL
	clip_contents = false
	set_meta(&"ui_lift", true)  # Lift on hover / focus like a card (UiMotion).
	_row = HBoxContainer.new()  # Icon | name over pips + price.
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row.offset_left = OssuaryUiData.TILE_PAD.x
	_row.offset_right = -OssuaryUiData.TILE_PAD.x
	_row.offset_top = OssuaryUiData.TILE_PAD.y
	_row.offset_bottom = -OssuaryUiData.TILE_PAD.y
	_row.add_theme_constant_override("separation", OssuaryUiData.TILE_ICON_GAP)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	icon_glyph = IconGlyph.new(cls, Vector2(OssuaryUiData.TILE_ICON, OssuaryUiData.TILE_ICON))
	icon_glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(icon_glyph)
	var texts := VBoxContainer.new()  # Name line over the pip / price line.
	texts.add_theme_constant_override("separation", 2)
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(texts)
	name_label = UiTheme.tier_label(String(UnitData.UNITS[cls]["display_name"]), UiTheme.Tier.NAME)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	texts.add_child(name_label)
	var line := HBoxContainer.new()  # Pips, spacer, price.
	line.add_theme_constant_override("separation", 4)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(line)
	pips = PixelMarks.Pips.new()
	line.add_child(pips)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(spacer)
	cost_icon = IconGlyph.new("soul_ash_small", Vector2(OssuaryUiData.COST_ICON, OssuaryUiData.COST_ICON))
	cost_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(cost_icon)
	cost_label = UiTheme.tier_label("", UiTheme.Tier.BODY, OssuaryUiData.ASH_COLOR)
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(cost_label)
	_fx = Control.new()
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.draw.connect(_draw_fx)
	add_child(_fx)


func _ready() -> void:
	SpriteBank.apply_sharp(_fx)


## Shows the tile's state: "buy" (affordable), "cost" (too expensive), "maxed" or
## "locked"; `level` fills the pips (of MasteryData.MAX_LEVEL); `cost` is the next
## level's price (ignored when maxed / locked).
func show_state(state: String, level: int, cost: int) -> void:
	locked = state == "locked"
	var accent := "violet"  # Kit frame accent (UiTheme.style()).
	var name_col := UiTheme.TEXT  # Name colour.
	var pip_col := OssuaryUiData.PIP_OWNED  # Lit pip colour.
	cost_icon.visible = true
	cost_label.text = str(cost)
	cost_label.add_theme_color_override("font_color", OssuaryUiData.ASH_COLOR)
	match state:
		"buy":
			accent = "soul"
		"cost":
			cost_label.add_theme_color_override("font_color", OssuaryUiData.COST_SHORT)
		"maxed":
			accent = "gold"
			name_col = UiTheme.TEXT_GOLD
			pip_col = OssuaryUiData.PIP_MAXED
			cost_icon.visible = false
			cost_label.text = OssuaryUiData.MAXED
			cost_label.add_theme_color_override("font_color", UiTheme.TEXT_GOLD)
		"locked":
			accent = "dim"
			name_col = UiTheme.TEXT_DIM
			cost_icon.visible = false
			cost_label.text = MasteryUiData.LOCKED_WORD
			cost_label.add_theme_color_override("font_color", OssuaryUiData.GATE_WORD)
	UiTheme.style_button(self, "button", accent)
	name_label.add_theme_color_override("font_color", name_col)
	pips.set_pips(MasteryData.MAX_LEVEL, level, pip_col)
	icon_glyph.modulate = OssuaryUiData.LOCKED_ICON_TINT if locked else Color.WHITE
	_fx.queue_redraw()


## Purchase feedback: a short bright flash of the whole tile (skipped without UI motion).
func flash() -> void:
	if not UiMotion.enabled():
		return
	var boost := 1.0 + MasteryUiData.FLASH_BOOST
	modulate = Color(boost, boost, boost)
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(self, "modulate", Color.WHITE, MasteryUiData.FLASH_TIME)


## Denied feedback: the tile's contents jiggle sideways (skipped without UI motion).
func shake() -> void:
	if not UiMotion.enabled():
		return
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_method(_shake_step, 0.0, 1.0, MasteryUiData.SHAKE_TIME)
	tw.tween_callback(_shake_step.bind(1.0))


## One shake step (`t` 0..1): an oscillation that fades out around the row's rest
## x (the tile padding); 1 = at rest.
func _shake_step(t: float) -> void:
	var k := 1.0 - t  # Fades out.
	_row.position.x = OssuaryUiData.TILE_PAD.x + roundf(sin(t * MasteryUiData.SHAKE_TIME * MasteryUiData.SHAKE_HZ * TAU) * MasteryUiData.SHAKE_PX * k)


## Draws the padlock over a locked tile's icon.
func _draw_fx() -> void:
	if locked:
		var ip := icon_glyph.position + _row.position  # Icon top-left in tile px.
		PixelMarks.draw_lock(_fx, ip + icon_glyph.size - Vector2(7, 9))
