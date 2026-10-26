## OssuaryCasketsPanel — the Ossuary's Caskets tab (owner request, Oct 2026, GDD
## §15.0 "Recolour Caskets (owner request, Oct 2026)"; the tab contract: a Control
## with refresh(), first_focus() and `changed`, loaded by the Ossuary's tab bar).
## Recolours are no longer bought: a casket (CasketData.PRICE Soul Ash) holds one
## prize the player does not own yet (CasketLedger: a recolour of an unlocked skin,
## or a casket-only skin), rolled by rarity with a pity counter. Two columns:
##   * the STAGE panel (ornate; its accent becomes the prize's tier: violet common,
##     soul-teal rare, gold epic / legendary): the casket (the chest art at x5) on a
##     soft glow, and under it the prize's name ("<Skin> · <Recolour>") and its tier
##     word in the tier colour (Legendary also gets the gold sheen, UiShimmer);
##   * the INFO column: the header and one line, the price with the Soul Ash badge
##     (ember when affordable, dim red when not), the Open button (soul-teal when it
##     can open, dim when short; disabled once nothing is left) and, after a reveal,
##     Wear (wears the prize: Meta.caskets.wear(); "Worn" once it is), a status line
##     (too little Soul Ash / nothing left / tap again), the odds per tier
##     (renormalised over the tiers that still hold a prize), the pity line ("Epic or
##     better within N") and the collection count ("Recolours 12 / 148").
## The REVEAL (CasketStage, real time, about 1.15 s in all, CasketUiData): the casket
## rattles harder and harder while its glow turns the tier's colour, bursts open
## (the `chest_open` strip, the lid flying off, light rays) with the tier's sound
## (Sfx.play_ui: `purchase`, `chest_open` for Epic and up), the prize rises out of it
## (the skin's portrait in the won recolour, SkinGlyphs.draw_skin()), then its name
## and tier fade in. Pressing Open again during the reveal skips it; under the
## autotest and with Reduce motion it is instant. The prize is already owned and
## saved when the reveal starts (closing the Ossuary mid-reveal loses nothing).
## On a touchscreen the first tap on Open only arms it (like Ossuary purchases) and
## the second opens. Purely cosmetic: nothing here touches a run or gameplay RNG.
## Keyboard / pad: Open and Wear are neighbours; the outer edges are left to the
## tab bar's geometry.
class_name OssuaryCasketsPanel
extends HBoxContainer

## Emitted after a casket was opened (the Ossuary redraws its balance).
signal changed

## The Open button.
var open_button: Button
## The Wear button (shown after a reveal).
var wear_button: Button
## The reveal stage.
var stage: CasketStage
## The last prize opened on this visit ({} = none yet; CasketLedger prize).
var prize: Dictionary = {}
## The stage panel (ornate; accent follows the prize's tier).
var _stage_panel: PanelContainer
## Prize name under the stage (or the idle caption).
var _name: Label
## Prize tier word under the name.
var _tier: Label
## Gold sheen over the name for a Legendary prize.
var _shimmer: UiShimmer
## Price number beside the Soul Ash badge.
var _price: Label
## Status line under the buttons.
var _status: Label
## Tier id -> its Label on the odds line.
var _odds: Dictionary = {}
## Pity line.
var _pity: Label
## Collection line.
var _collection: Label
## Touch only: true once Open was tapped (the next tap opens).
var _touch_armed: bool = false
## True once the prize's name and tier are shown for the current reveal.
var _text_shown: bool = true


## The prize portrait: the won skin drawn in the won recolour (SkinGlyphs), at a
## whole-number scale inside its box. Moved, scaled and faded by the stage.
class PrizePortrait:
	extends Control
	## SkinData id drawn ("" = nothing).
	var skin_id: String = ""
	## RecolourData id drawn on it ("" = the skin's own colours).
	var recolour: String = ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = CasketUiData.PORTRAIT_BOX
		size = CasketUiData.PORTRAIT_BOX
		pivot_offset = CasketUiData.PORTRAIT_BOX * 0.5

	func _ready() -> void:
		SpriteBank.apply_sharp(self)

	func _draw() -> void:
		if skin_id == "":
			return
		SpriteBank.icon_cap = size.y * 0.92
		SkinGlyphs.draw_skin(self, skin_id, size * 0.5, size.y * 0.28, false, recolour)
		SpriteBank.icon_cap = 0.0


## The reveal stage: the casket on a stepped glow, the rattle, the burst, the lid
## flying off, rays in the tier colour and the prize rising out. Real-time driven
## while revealing (redrawn every frame only then); static otherwise. Clipped to
## its own rect.
class CasketStage:
	extends Control
	## The casket burst open (play the tier's sound).
	signal opened
	## The prize has risen into place (show its name).
	signal risen

	## Tier id of the prize being shown ("" = none: the idle casket).
	var tier: String = ""
	## True while no prize is left (a dimmed, closed casket).
	var empty: bool = false
	## Real time (usec) the reveal started.
	var start_usec: int = 0
	## True when the reveal is done or skipped (or motion is off): drawn settled.
	var settled: bool = true
	## The prize portrait.
	var portrait: PrizePortrait
	## The chest_open burst over the casket.
	var burst: UiFx
	## True once `opened` was emitted for this reveal.
	var _opened_sent: bool = true
	## True once `risen` was emitted for this reveal.
	var _risen_sent: bool = true

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true
		custom_minimum_size = CasketUiData.STAGE_SIZE
		burst = UiFx.new("chest_open", CasketUiData.BURST_SCALE)
		add_child(burst)
		portrait = PrizePortrait.new()
		portrait.visible = false
		add_child(portrait)
		set_process(false)

	func _ready() -> void:
		SpriteBank.apply_sharp(self)

	## Shows the idle casket (nothing opened yet; `is_empty`: nothing left to win).
	func show_idle(is_empty: bool) -> void:
		tier = ""
		empty = is_empty
		settled = true
		portrait.visible = false
		set_process(false)
		queue_redraw()

	## Starts the reveal of `prize` now (settled at once when motion is off).
	func reveal(prize: Dictionary) -> void:
		tier = String(prize.get("tier", ""))
		empty = false
		portrait.skin_id = String(prize.get("skin", ""))
		portrait.recolour = String(prize.get("recolour", ""))
		portrait.queue_redraw()
		start_usec = Time.get_ticks_usec()
		settled = false
		_opened_sent = false
		_risen_sent = false
		burst.stop()
		set_process(true)
		if not UiMotion.enabled():
			settle()
			return
		_place(0.0)
		queue_redraw()

	## True while a reveal is playing.
	func revealing() -> bool:
		return not settled

	## Jumps to the end of the reveal (a press during it, or motion off).
	func settle() -> void:
		settled = true
		set_process(false)
		if not _opened_sent:
			_opened_sent = true
			opened.emit()
		if not _risen_sent:
			_risen_sent = true
			risen.emit()
		_place(age())
		queue_redraw()

	## Seconds since the reveal started (real time); large once settled.
	func age() -> float:
		return 99.0 if settled else float(Time.get_ticks_usec() - start_usec) / 1000000.0

	## Centre (layout px, whole px) of the casket sprite.
	func casket_center() -> Vector2:
		var h := 29.0 * float(CasketUiData.CASKET_SCALE)  # Drawn chest height (the art is 29 px tall).
		var tex := SpriteBank.texture(CasketUiData.CASKET_SPRITE)  # The chest art (null = code chest).
		if tex != null:
			h = float(tex.get_height()) * float(CasketUiData.CASKET_SCALE)
		return Vector2(roundf(size.x * 0.5), roundf(size.y - CasketUiData.CASKET_BOTTOM - h * 0.5))

	## Where the prize settles (its portrait's centre).
	func prize_center() -> Vector2:
		return Vector2(roundf(size.x * 0.5), CasketUiData.PORTRAIT_Y)

	## 0..1 through the rise (eased out); 0 before the casket opens.
	func rise_k(t: float) -> float:
		var k := clampf((t - CasketUiData.SHAKE_TIME) / CasketUiData.RISE_TIME, 0.0, 1.0)  # Linear progress.
		return 1.0 - pow(1.0 - k, 3.0)

	func _process(_delta: float) -> void:
		if settled or not is_visible_in_tree():
			return
		var t := age()
		if not _opened_sent and t >= CasketUiData.SHAKE_TIME:
			_opened_sent = true
			burst.play()
			opened.emit()
		if not _risen_sent and t >= CasketUiData.SHAKE_TIME + CasketUiData.RISE_TIME:
			_risen_sent = true
			risen.emit()
		if t >= CasketUiData.REVEAL_TIME:
			settle()
			return
		_place(t)
		queue_redraw()

	## Moves / scales / fades the portrait and the burst for reveal time `t`.
	func _place(t: float) -> void:
		burst.position = casket_center() + Vector2(0.0, -float(CasketUiData.LID_ROWS) * float(CasketUiData.CASKET_SCALE) * 0.5)
		portrait.visible = tier != "" and t >= CasketUiData.SHAKE_TIME
		if not portrait.visible:
			return
		var e := rise_k(t)  # Rise, eased.
		var from := casket_center() + Vector2(0.0, -20.0)  # Leaves the casket's mouth.
		var c := from.lerp(prize_center(), e)  # Portrait centre now.
		portrait.position = (c - portrait.size * 0.5).round()
		var s := lerpf(CasketUiData.PORTRAIT_START_SCALE, 1.0, e)  # Grows as it rises.
		portrait.scale = Vector2(s, s)
		portrait.modulate.a = clampf(e * 3.0, 0.0, 1.0)

	## The tier colour (the idle violet for "").
	func tier_color() -> Color:
		if tier == "" or not CasketData.TIERS.has(tier):
			return CasketUiData.GLOW_IDLE
		return CasketData.TIERS[tier]["color"]

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), CasketUiData.STAGE_BG)
		var t := age()
		var c := casket_center()
		var shake_k := clampf(t / CasketUiData.SHAKE_TIME, 0.0, 1.0) if tier != "" else 0.0  # 0..1 through the rattle.
		var open_k := clampf((t - CasketUiData.SHAKE_TIME) / CasketUiData.LID_TIME, 0.0, 1.0) if tier != "" else 0.0  # Lid flight.
		var e := rise_k(t) if tier != "" else 0.0  # Prize rise.
		# The glow: violet while waiting, turning the tier colour as it rattles, following the prize up.
		var col := CasketUiData.GLOW_IDLE.lerp(tier_color(), shake_k)
		var alpha := lerpf(CasketUiData.GLOW_IDLE_ALPHA, CasketUiData.GLOW_ALPHA, shake_k)
		if empty:
			alpha *= 0.4
		var gc := c.lerp(prize_center(), e)  # Glow centre.
		for i in CasketUiData.GLOW_STEPS:
			var r := CasketUiData.GLOW_RADIUS * (1.0 - float(i) / float(CasketUiData.GLOW_STEPS))
			draw_circle(gc, r, Color(col, alpha * 0.5))
		if open_k > 0.0:
			_rays(prize_center().lerp(c, 1.0 - e), open_k, t)
		_casket(c, shake_k, open_k, t)

	## Light rays around `o` in the tier colour (alpha `k`); they turn only during the reveal.
	func _rays(o: Vector2, k: float, t: float) -> void:
		var spin := minf(t, CasketUiData.REVEAL_TIME) * CasketUiData.RAY_SPIN  # Rotation (rad), frozen once settled.
		var col := tier_color()
		for i in CasketUiData.RAY_COUNT:
			var a := TAU * float(i) / float(CasketUiData.RAY_COUNT) + spin  # Ray angle.
			var length := CasketUiData.RAY_LENGTH * (1.0 if i % 2 == 0 else CasketUiData.RAY_SHORT)
			var half := CasketUiData.RAY_HALF_ANGLE
			var pts := PackedVector2Array([o, o + Vector2.from_angle(a - half) * length, o + Vector2.from_angle(a + half) * length])
			draw_colored_polygon(pts, Color(col, CasketUiData.RAY_ALPHA * k))

	## The casket at `c`: rattling (`shake_k`), its lid flying off (`open_k`).
	func _casket(c: Vector2, shake_k: float, open_k: float, t: float) -> void:
		var tex := SpriteBank.texture(CasketUiData.CASKET_SPRITE)  # The chest art (null = the code chest).
		var tint := CasketUiData.EMPTY_TINT if empty else Color.WHITE  # A dim casket once nothing is left.
		var shake := Vector2.ZERO  # Rattle offset (whole px).
		if open_k <= 0.0 and shake_k > 0.0 and not settled:
			shake = Vector2(roundf(sin(t * CasketUiData.SHAKE_FREQ) * CasketUiData.SHAKE_PX * shake_k), 0.0)
		if tex == null:
			PowerupGlyphs.draw_chest(self, c + shake, 10.0 * float(CasketUiData.CASKET_SCALE), t, open_k)
			return
		var k := float(CasketUiData.CASKET_SCALE)  # Layout px per art px.
		var w := float(tex.get_width())
		var h := float(tex.get_height())
		var lid_h := float(CasketUiData.LID_ROWS)  # Lid rows (art px).
		var tl := (c - Vector2(w, h) * k * 0.5).round() + shake  # Sprite top-left.
		if open_k > 0.0:  # Light pouring out of the open casket.
			var gap := Rect2(tl + Vector2(3.0 * k, lid_h * k - 2.0 * k), Vector2((w - 6.0) * k, 3.0 * k))
			draw_rect(gap, Color(tier_color(), 0.6 * open_k))
			draw_rect(gap.grow_individual(-gap.size.x * 0.25, 0.0, -gap.size.x * 0.25, -k), Color(1.0, 0.97, 0.85, 0.9 * open_k))
		draw_texture_rect_region(tex, Rect2(tl + Vector2(0.0, lid_h * k), Vector2(w, h - lid_h) * k), Rect2(0.0, lid_h, w, h - lid_h), tint)
		var lid_a := 1.0 - open_k  # The lid fades as it flies.
		if lid_a <= 0.0:
			return
		var lift := roundf(CasketUiData.LID_FLY * open_k) * k  # Rise (layout px).
		var pivot := tl + Vector2(w * k * 0.5, lid_h * k * 0.5 - lift)  # Lid centre.
		draw_set_transform(pivot, CasketUiData.LID_SPIN * open_k, Vector2.ONE)
		draw_texture_rect_region(tex, Rect2(Vector2(-w, -lid_h) * k * 0.5, Vector2(w, lid_h) * k), Rect2(0.0, 0.0, w, lid_h), Color(tint, lid_a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ready() -> void:
	add_theme_constant_override("separation", CasketUiData.COLUMN_GAP)
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_build_stage())
	add_child(_build_info())
	wear_button.focus_neighbor_left = wear_button.get_path_to(open_button)
	wear_button.focus_neighbor_right = wear_button.get_path_to(wear_button)  # Nothing right of Wear.
	if not Meta.changed.is_connected(refresh):
		Meta.changed.connect(refresh)
	refresh()


## The first control to focus when the tab opens (Open).
func first_focus() -> Control:
	return open_button


# =====================================================================================
# Building
# =====================================================================================

## The stage panel: the stage, the prize name and the tier word.
func _build_stage() -> Control:
	_stage_panel = UiTheme.ornate_panel("violet")
	_stage_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	_stage_panel.add_child(vb)
	stage = CasketStage.new()
	stage.opened.connect(_on_opened)
	stage.risen.connect(_on_risen)
	vb.add_child(stage)
	_name = UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.clip_text = true
	_name.custom_minimum_size.x = CasketUiData.STAGE_SIZE.x
	vb.add_child(_name)
	_shimmer = UiShimmer.new(0.0)
	_shimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shimmer.visible = false
	_name.add_child(_shimmer)  # Over the name (a Label is not a Container).
	_tier = UiTheme.tier_label("", UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	_tier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_tier)
	return _stage_panel


## The info column: header, line, price, buttons, status, odds, pity, collection.
func _build_info() -> Control:
	var vb := VBoxContainer.new()
	vb.custom_minimum_size.x = CasketUiData.INFO_WIDTH
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vb.add_theme_constant_override("separation", CasketUiData.INFO_GAP)
	vb.add_child(UiTheme.tier_label(CasketUiData.HEADER, UiTheme.Tier.HEADER, UiTheme.TEXT_GOLD))
	vb.add_child(UiTheme.para(CasketUiData.LINE, CasketUiData.INFO_WIDTH, UiTheme.TEXT_DIM))
	vb.add_child(UiTheme.divider())
	var price_row := HBoxContainer.new()  # Badge and price.
	price_row.add_theme_constant_override("separation", 8)
	var badge := IconGlyph.new("soul_ash", Vector2(OssuaryUiData.BALANCE_ICON, OssuaryUiData.BALANCE_ICON))
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price_row.add_child(badge)
	_price = UiTheme.tier_label(str(CasketData.PRICE), UiTheme.Tier.HEADER, OssuaryUiData.ASH_COLOR)
	_price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_row.add_child(_price)
	vb.add_child(price_row)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", CasketUiData.BUTTON_GAP)
	open_button = Button.new()
	open_button.text = CasketUiData.OPEN
	open_button.custom_minimum_size = CasketUiData.BUTTON_SIZE
	open_button.focus_mode = Control.FOCUS_ALL
	open_button.pressed.connect(_on_open_pressed)
	buttons.add_child(open_button)
	InputHints.attach(open_button, "ui_accept", true, 10.0)
	wear_button = Button.new()
	wear_button.text = CasketUiData.WEAR
	wear_button.custom_minimum_size = CasketUiData.BUTTON_SIZE
	wear_button.focus_mode = Control.FOCUS_ALL
	wear_button.tooltip_text = CasketUiData.WEAR_TIP
	wear_button.pressed.connect(_on_wear_pressed)
	wear_button.visible = false
	buttons.add_child(wear_button)
	vb.add_child(buttons)
	_status = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	vb.add_child(_status)
	vb.add_child(UiTheme.divider())
	var odds_row := HBoxContainer.new()
	odds_row.add_theme_constant_override("separation", CasketUiData.ODDS_GAP)
	var odds_label := UiTheme.tier_label(CasketUiData.ODDS_LABEL, UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	odds_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	odds_row.add_child(odds_label)
	for t: String in CasketData.TIER_ORDER:
		var l := UiTheme.tier_label("", UiTheme.Tier.BODY, CasketData.TIERS[t]["color"])
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		odds_row.add_child(l)
		_odds[t] = l
	vb.add_child(odds_row)
	_pity = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_GOLD)
	vb.add_child(_pity)
	_collection = UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT)
	vb.add_child(_collection)
	return vb


# =====================================================================================
# Display
# =====================================================================================

## Redraws the price, the buttons, the status, odds, pity and collection lines
## (and the idle stage while no prize was opened on this visit).
func refresh() -> void:
	if not is_inside_tree():
		return
	var led := Meta.caskets  # The save's casket ledger.
	var pool := led.prize_pool()  # Prizes left.
	var block := "empty" if pool.is_empty() else ("cost" if Meta.soul_ash < CasketData.PRICE else "")  # As CasketLedger.open_block().
	_price.add_theme_color_override("font_color", OssuaryUiData.ASH_COLOR if block != "cost" else OssuaryUiData.COST_SHORT)
	open_button.disabled = block == "empty"
	UiTheme.style_button(open_button, "button", "soul" if block == "" else "dim")
	match block:
		"empty":
			_set_status(CasketUiData.EMPTY_LINE, UiTheme.TEXT_GOLD)
		"cost":
			_set_status(CasketUiData.SHORT_LINE, OssuaryUiData.DENIED)
		_:
			_set_status(CasketUiData.TAP_AGAIN if _touch_armed and InputHints.device() == InputHints.Device.TOUCH else "", UiTheme.TEXT_GOOD)
	var chances := CasketLedger.odds(pool)  # Tier -> chance (non-empty tiers).
	for t: String in CasketData.TIER_ORDER:
		var l: Label = _odds[t]
		l.visible = chances.has(t)
		if l.visible:
			l.text = CasketUiData.ODDS_ENTRY % [String(CasketData.TIERS[t]["display_name"]), roundi(float(chances[t]) * 100.0)]
	_pity.visible = CasketLedger.has_pity_prize(pool)
	if _pity.visible:
		var left := led.pity_left()  # Caskets until the pity one, counting it.
		_pity.text = CasketUiData.PITY_NEXT if left <= 1 else CasketUiData.PITY_LINE % left
	var col := led.collection()  # Owned / total counts.
	var text := CasketUiData.COLLECTION % [int(col["recolours"]), int(col["recolours_total"])]
	if int(col["skins_total"]) > 0:
		text += "   " + CasketUiData.COLLECTION_SKINS % [int(col["skins"]), int(col["skins_total"])]
	_collection.text = text
	if prize.is_empty():
		stage.show_idle(pool.is_empty())
		_name.text = CasketUiData.EMPTY_NAME if pool.is_empty() else CasketUiData.IDLE_NAME
		_name.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if pool.is_empty() else UiTheme.TEXT_DIM)
		_name.modulate.a = 1.0
		_tier.text = ""
		_shimmer.visible = false
		_stage_panel.add_theme_stylebox_override("panel", UiTheme.style("ornate", "gold" if pool.is_empty() else "violet"))
	elif _text_shown:
		_show_wear()
	open_button.focus_neighbor_right = open_button.get_path_to(wear_button if wear_button.visible else open_button)


## Writes the status line.
func _set_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)


## The prize's name and tier under the stage, faded in over TEXT_TIME (instant
## without motion); the stage frame takes the tier's accent.
func _show_prize_text() -> void:
	_text_shown = true
	var tier := String(prize["tier"])  # The prize's tier.
	var row: Dictionary = CasketData.TIERS[tier]
	var good := CasketData.TIER_ORDER.find(tier) >= CasketData.TIER_ORDER.find(CasketData.PITY_TIER)  # Epic or better.
	_name.text = CasketLedger.prize_name(prize)
	_name.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if good else UiTheme.TEXT)
	_tier.text = String(row["display_name"])
	_tier.add_theme_color_override("font_color", row["color"])
	_shimmer.visible = bool(row["shimmer"])
	_stage_panel.add_theme_stylebox_override("panel", UiTheme.style("ornate", _tier_accent(tier)))
	if UiMotion.enabled():
		for l: Label in [_name, _tier]:
			l.modulate.a = 0.0
			var tw := l.create_tween()
			tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(l, "modulate:a", 1.0, CasketUiData.TEXT_TIME)
	else:
		_name.modulate.a = 1.0
		_tier.modulate.a = 1.0
	_show_wear()


## The kit accent of tier `tier` (violet common, soul rare, gold epic and up).
static func _tier_accent(tier: String) -> String:
	match tier:
		"rare":
			return "soul"
		"epic", "legendary":
			return "gold"
	return "violet"


## Shows Wear for the current prize ("Worn", gold, once it is worn).
func _show_wear() -> void:
	wear_button.visible = not prize.is_empty()
	if not wear_button.visible:
		return
	var worn := Meta.caskets.is_worn(prize)  # Already worn.
	wear_button.text = CasketUiData.WORN if worn else CasketUiData.WEAR
	UiTheme.style_button(wear_button, "button", "gold" if worn else "")
	open_button.focus_neighbor_right = open_button.get_path_to(wear_button)


# =====================================================================================
# Actions
# =====================================================================================

## Open pressed: skips a running reveal; else (touch: on the second tap) opens a
## casket and starts its reveal, or answers `denied`.
func _on_open_pressed() -> void:
	if stage.revealing():
		stage.settle()  # Skip: the prize and its name at once.
		return
	if InputHints.device() == InputHints.Device.TOUCH and not _touch_armed:
		_touch_armed = true  # A finger: the first tap only arms Open (like Ossuary purchases).
		Sfx.play_ui("ui_tick")
		refresh()
		return
	if Meta.caskets.open_block() != "":
		Sfx.play_ui("denied")
		_flash_price()
		return
	var p := Meta.caskets.open()  # Owned and saved; emits Meta.changed (refresh()).
	if p.is_empty():
		Sfx.play_ui("denied")
		return
	prize = p
	changed.emit()  # The Ossuary's balance.
	_begin_reveal()


## Starts the reveal of `prize`: hides its name and Wear, warms the recoloured
## art, and plays the stage (instant without motion).
func _begin_reveal() -> void:
	_text_shown = false
	wear_button.visible = false
	_name.text = ""
	_tier.text = ""
	_shimmer.visible = false
	_stage_panel.add_theme_stylebox_override("panel", UiTheme.style("ornate", "violet"))
	var skin := String(prize["skin"])  # Skin won (or whose recolour was won).
	SkinGlyphs.warm(skin, String(SkinData.skin(skin).get("character", "")), String(prize["recolour"]))
	if UiMotion.enabled():
		Sfx.play_ui(CasketUiData.SOUND_START)
	stage.reveal(prize)
	open_button.focus_neighbor_right = open_button.get_path_to(open_button)


## The casket burst open: the tier's sound.
func _on_opened() -> void:
	Sfx.play_ui(String(CasketUiData.SOUND_REVEAL.get(String(prize.get("tier", "")), "purchase")))


## The prize has risen: its name and tier, and Wear.
func _on_risen() -> void:
	if not prize.is_empty():
		_show_prize_text()


## Wear pressed: wears the prize (free and reversible: the skin row changes it back).
func _on_wear_pressed() -> void:
	if prize.is_empty() or stage.revealing():
		return
	if Meta.caskets.is_worn(prize):
		Sfx.play_ui("ui_tick")
		return
	Meta.caskets.wear(prize)
	Sfx.play("ui_confirm")
	_show_wear()


## The price blinks red (a denied press; skipped without motion).
func _flash_price() -> void:
	if not UiMotion.enabled():
		return
	_price.modulate = Color(1.6, 0.6, 0.6)
	var tw := _price.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_price, "modulate", Color.WHITE, OssuaryUiData.SHAKE_TIME)
