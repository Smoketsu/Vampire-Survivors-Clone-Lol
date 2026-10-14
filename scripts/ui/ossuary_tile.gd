## OssuaryTile — one upgrade tile of the Ossuary (OssuaryMenu; menu
## modernization wave 2, GDD §15.0 "Ossuary redesign"): a focusable kit
## button showing the upgrade's 32 px badge icon, its name, its level pips
## and its next cost (the small Soul Ash symbol and a number), nothing else:
## the effect, the current → next value and the prerequisite live in the
## screen's one detail panel. The frame accent carries the state (UiTheme
## kit "button"): soul teal = affordable, violet = too expensive, gold =
## maxed, dim = locked (the icon darkens and gets a padlock), crimson = the
## Profane Oath once a tier is owned.
## Feedback (real time, private cosmetic RNG, instant / skipped with Reduce
## motion and under the autotest through UiMotion.enabled()): flash() plays
## a bright flash and a burst of pixel sparks from the icon when a tier is
## bought; shake() jiggles the tile sideways when a press is denied. It never
## touches Meta: the menu reads and buys, the tile only shows.
class_name OssuaryTile
extends Button

## Upgrade id (MetaData.UPGRADES key).
var upgrade_id: String = ""
## Badge icon (IconGlyph, TILE_ICON px).
var icon_glyph: IconGlyph
## Upgrade name label (NAME tier).
var name_label: Label
## Level pips.
var pips: PixelMarks.Pips
## Small Soul Ash symbol in front of the cost.
var cost_icon: IconGlyph
## Next-tier cost label (BODY tier), "MAX" when maxed, empty when locked.
var cost_label: Label
## True while the upgrade is locked (draws the padlock over the icon).
var locked: bool = false
## Real-time stamp (s) when the purchase flash started (-1 = none).
var _flash_t0: float = -1.0
## Real-time stamp (s) when the denied shake started (-1 = none).
var _shake_t0: float = -1.0
## Burst sparks: [position, velocity, colour] per spark (layout px, px/s).
var _sparks: Array = []
## Real-time stamp (s) of the last _process step (spark integration).
var _last_t: float = 0.0
## Private cosmetic RNG for the sparks (never the seeded gameplay RNG).
var _rng := RandomNumberGenerator.new()
## Overlay Control drawing the flash, sparks and padlock over the children.
var _fx: Control
## Rest x position (layout px) of the tile while it shakes (its column's slot).
var _shake_base: float = 0.0


func _init(id: String) -> void:
	upgrade_id = id
	custom_minimum_size = OssuaryUiData.TILE_SIZE
	focus_mode = Control.FOCUS_ALL
	clip_contents = false
	set_meta(&"ui_lift", true)  # Lift on hover / focus like a card (UiMotion).
	var row := HBoxContainer.new()  # Icon | name over pips + cost.
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = OssuaryUiData.TILE_PAD.x
	row.offset_right = -OssuaryUiData.TILE_PAD.x
	row.offset_top = OssuaryUiData.TILE_PAD.y
	row.offset_bottom = -OssuaryUiData.TILE_PAD.y
	row.add_theme_constant_override("separation", OssuaryUiData.TILE_ICON_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	icon_glyph = IconGlyph.new(String(MetaData.UPGRADES[id]["icon"]), Vector2(OssuaryUiData.TILE_ICON, OssuaryUiData.TILE_ICON))
	icon_glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon_glyph)
	var texts := VBoxContainer.new()  # Name line over the pip / cost line.
	texts.add_theme_constant_override("separation", 2)
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)
	name_label = UiTheme.tier_label(String(MetaData.UPGRADES[id]["display_name"]), UiTheme.Tier.NAME)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	texts.add_child(name_label)
	var line := HBoxContainer.new()  # Pips, spacer, cost.
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
	_rng.seed = hash(id)  # Cosmetic only: a fixed private seed per tile.


func _ready() -> void:
	SpriteBank.apply_sharp(_fx)
	set_process(false)


## Shows the tile's state. `state` is "buy" (affordable), "cost" (too
## expensive), "maxed", "locked" or "oath" (an owned Oath tier); `tier` /
## `max_tier` fill the pips; `cost` is the next tier's price (ignored when
## maxed / locked); `idle` lights pips up to that index as owned-but-lowered
## (the Oath).
func show_state(state: String, tier: int, max_tier: int, cost: int, idle: int = 0) -> void:
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
			cost_label.text = ""
	if upgrade_id == PactData.OATH_ID:
		pip_col = OssuaryUiData.PIP_OATH
		if tier > 0 or idle > 0:
			accent = "crimson"
	UiTheme.style_button(self, "button", accent)
	name_label.add_theme_color_override("font_color", name_col)
	pips.set_pips(max_tier, tier, pip_col, idle)
	icon_glyph.modulate = OssuaryUiData.LOCKED_ICON_TINT if locked else Color.WHITE
	_fx.queue_redraw()


## Purchase feedback: a bright flash over the tile and a burst of pixel
## sparks from the icon (skipped when UI motion is off).
func flash() -> void:
	if not UiMotion.enabled():
		return
	_flash_t0 = _now()
	_sparks.clear()
	var origin := icon_glyph.position + icon_glyph.get_parent_control().position + icon_glyph.size * 0.5  # Icon centre in tile px.
	for i in OssuaryUiData.BURST_COUNT:
		var a := _rng.randf_range(-PI, 0.0) if i % 3 != 0 else _rng.randf_range(0.0, TAU)  # Mostly upward.
		var v := Vector2.from_angle(a) * _rng.randf_range(OssuaryUiData.BURST_SPEED.x, OssuaryUiData.BURST_SPEED.y)
		var col: Color = OssuaryUiData.BURST_COLORS[_rng.randi() % OssuaryUiData.BURST_COLORS.size()]
		_sparks.append([origin, v, col])
	_last_t = _flash_t0
	set_process(true)


## Denied feedback: a short sideways shake (skipped when UI motion is off).
func shake() -> void:
	if not UiMotion.enabled():
		return
	if _shake_t0 < 0.0:
		_shake_base = position.x
	_shake_t0 = _now()
	_last_t = _shake_t0
	set_process(true)


## Real time (s), unscaled (UI motion never follows Engine.time_scale).
static func _now() -> float:
	return float(Time.get_ticks_usec()) / 1000000.0


func _process(_delta: float) -> void:
	var t := _now()
	var dt := clampf(t - _last_t, 0.0, 0.05)  # Real step (s).
	_last_t = t
	var busy := false  # Something still animates.
	if _flash_t0 >= 0.0:
		var age := t - _flash_t0
		for s: Array in _sparks:
			s[1] = (s[1] as Vector2) + Vector2(0.0, OssuaryUiData.BURST_GRAVITY * dt)
			s[0] = (s[0] as Vector2) + (s[1] as Vector2) * dt
		if age >= maxf(OssuaryUiData.FLASH_TIME, OssuaryUiData.BURST_TIME):
			_flash_t0 = -1.0
			_sparks.clear()
		else:
			busy = true
	if _shake_t0 >= 0.0:
		var age := t - _shake_t0
		if age >= OssuaryUiData.SHAKE_TIME:
			_shake_t0 = -1.0
			position.x = _shake_base
			var box := get_parent() as Container  # Let the column re-apply its layout.
			if box != null:
				box.queue_sort()
		else:
			var k := 1.0 - age / OssuaryUiData.SHAKE_TIME  # Fades out.
			position.x = _shake_base + roundf(sin(age * OssuaryUiData.SHAKE_HZ * TAU) * OssuaryUiData.SHAKE_PX * k)
			busy = true
	_fx.queue_redraw()
	if not busy:
		set_process(false)


## Draws the padlock (locked), the purchase flash and the sparks over the tile.
func _draw_fx() -> void:
	if locked:
		var ip := icon_glyph.position + icon_glyph.get_parent_control().position  # Icon top-left in tile px.
		PixelMarks.draw_lock(_fx, ip + icon_glyph.size - Vector2(7, 9))
	if _flash_t0 < 0.0:
		return
	var age := _now() - _flash_t0
	if age < OssuaryUiData.FLASH_TIME:
		var a := OssuaryUiData.FLASH_ALPHA * (1.0 - age / OssuaryUiData.FLASH_TIME)  # Fading flash.
		var col := Color(OssuaryUiData.FLASH_COLOR, a)
		# Cut corners like the frame (owner rule): two overlapping rects 3 px in.
		_fx.draw_rect(Rect2(Vector2(5, 3), size - Vector2(10, 6)), col)
		_fx.draw_rect(Rect2(Vector2(3, 5), Vector2(2, size.y - 10)), col)
		_fx.draw_rect(Rect2(Vector2(size.x - 5, 5), Vector2(2, size.y - 10)), col)
	var life := clampf(1.0 - age / OssuaryUiData.BURST_TIME, 0.0, 1.0)  # Spark fade.
	for s: Array in _sparks:
		var p := (s[0] as Vector2).floor()
		_fx.draw_rect(Rect2(p, Vector2.ONE * OssuaryUiData.BURST_PX), Color(s[2] as Color, life))
