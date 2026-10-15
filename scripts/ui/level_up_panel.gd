## LevelUpPanel — pauses combat and shows three large upgrade cards
## (GDD §10.4 "Level-up panel: Pause combat; three large cards with icon, name,
## old/new level, description, actual stat delta, evolution readiness").
## Under the cards, an action bar offers Reroll / Banish (limited charges)
## and Skip (unlimited, small heal), GDD §9.1 and LevelUpData.
##
## Presentation (menu modernization wave 2, numbers in InRunUiData):
##   * "Level N" in the TITLE tier; two columns of violet light (the
##     `level_up` effect strip, UiFx) rise at both sides of the card row each
##     time the panel opens, and the cards rise in one after another
##     (UiMotion.stagger) and lift on hover / focus (UiMotion.liftable).
##   * A card, top to bottom: its number key chip and kind tag (and a
##     soul-teal NEW for a new item), the 64 px icon (the 32 px badge at x2),
##     the name, the level pips (owned levels violet, the level this card
##     grants soul-teal, levels to come dark; LevelPips), a skull divider,
##     the one-sentence description, the stat deltas, and at the bottom the
##     evolution recipe as icons (RecipeIconRow), only once that recipe is
##     discovered (owner decision, GDD §15.0 "Recipe icon row").
##   * Evolution cards are gold (gold = evolution): gold frame, divider and
##     name, the `evolution` strip collapsing into the icon as the card
##     enters, and a gold sheen sweeping across it (UiShimmer).
##   * While the panel is open the HUD banners are hidden (Hud mutes them
##     whenever the run is not PLAYING), so nothing shows through.
## Every motion is instant under the autotest and with "Reduce motion".
##
## Controls (all also reachable by focus navigation + A / Enter / click):
##   pick a card     1 / 2 / 3, click, or focus + A
##   Reroll          R            controller X
##   Banish mode     B            controller LB (then pick the card to banish;
##                                B / LB again, Esc or controller B cancels)
##   Skip            N            controller RB
## Controller Y stays the Shadow Bolt aim toggle, so it is not used here.
## These keys are shown as InputHints chips (the current device's: keyboard
## keys or pad buttons), never as text: a hint strip under the title, a
## "1" / "2" / "3" key chip on each card (keyboard only), a chip inside each
## action button and a cancel chip on the banish prompt.
class_name LevelUpPanel
extends Control

## Emitted with the chosen offer Dictionary (see AbilityManager._offer()); a
## skip emits AbilityManager.skip_offer().
signal card_chosen(offer: Dictionary)

## Clicks/keys within this many ms of opening are ignored, so a held key or
## an in-flight click doesn't pick a card by accident.
const INPUT_GRACE_MSEC: int = 250
## Card number keys (1 / 2 / 3, keyboard only), shown as chips on the cards.
const CARD_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3]

## Owning run (abilities, autotest hook).
var game: Game
## Offers currently displayed.
var _offers: Array[Dictionary] = []
## Level number shown in the title (kept across rerolls / banishes).
var _for_level: int = 0
## Container holding the card buttons.
var _cards_box: HBoxContainer
## "Level N" title.
var _title: Label
## Status line under the cards (banish mode prompt, evolution notice).
var _status: Label
## Cancel chip and word beside the status line (shown in banish mode).
var _status_cancel: Control
## Card buttons in display order (focus / click targets).
var _buttons: Array[Button] = []
## Card root containers in display order (freed when the panel reopens).
var _cards: Array[Control] = []
## The two level-up light pillars beside the card row (left, right).
var _pillars: Array[UiFx] = []
## Zero-height anchor under the card row that holds the pillars.
var _pillar_anchor: Control
## Reroll action button.
var _reroll_btn: Button
## Banish action button (toggles banish mode).
var _banish_btn: Button
## Skip action button.
var _skip_btn: Button
## True while the next card pick banishes instead of taking the card.
var _banish_mode: bool = false
## Time (ms) the panel was last opened.
var _opened_msec: int = 0
## True while waiting for a choice.
var _waiting: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_meta(UiMotion.META_CANCEL_SILENT, true)  # Esc / B is no "back" here.
	add_child(UiTheme.backdrop(InRunUiData.LEVEL_BACKDROP))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit (no-op at 720 px).
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	center.add_child(vb)
	_title = UiTheme.title("Level Up")
	vb.add_child(_title)
	var picks: Array = []  # "1" "2" "3" (keyboard) and A (pad).
	for k: Key in CARD_KEYS:
		picks.append(InputHints.raw(k))
	picks.append(InputHints.raw(-1, JOY_BUTTON_A))
	vb.add_child(InputHints.strip([[picks, "Choose one"]]))
	_cards_box = HBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", InRunUiData.CARD_GAP)
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(_cards_box)
	_build_pillars(vb)
	var status_row := HBoxContainer.new()  # Status line + its cancel hint.
	status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	status_row.add_theme_constant_override("separation", 14)
	status_row.custom_minimum_size = Vector2(0, InputHintData.CHIP_HEIGHT)
	vb.add_child(status_row)
	_status = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_GOLD)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_row.add_child(_status)
	_status_cancel = MarginContainer.new()  # Wrapper: its visibility is ours, the hint's is InputHints'.
	_status_cancel.add_child(InputHints.hint([InputHints.raw(KEY_ESCAPE, JOY_BUTTON_B)], "Cancel"))
	status_row.add_child(_status_cancel)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", InRunUiData.CARD_GAP)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(actions)
	_reroll_btn = _action_button(actions, _reroll, InputHints.raw(KEY_R, JOY_BUTTON_X))
	_banish_btn = _action_button(actions, _toggle_banish, InputHints.raw(KEY_B, JOY_BUTTON_LEFT_SHOULDER))
	_skip_btn = _action_button(actions, _skip, InputHints.raw(KEY_N, JOY_BUTTON_RIGHT_SHOULDER))


## Adds the zero-height anchor right under the card row and the two light
## pillars on it (bottom-anchored `level_up` columns just outside the row).
func _build_pillars(vb: VBoxContainer) -> void:
	_pillar_anchor = Control.new()
	_pillar_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_pillar_anchor)
	var half := (3.0 * InRunUiData.CARD_WIDTH + 2.0 * float(InRunUiData.CARD_GAP)) * 0.5 + InRunUiData.PILLAR_MARGIN  # Pillar x from the centre (px).
	for side: float in [-1.0, 1.0]:
		var fx := UiFx.new("level_up", InRunUiData.PILLAR_SCALE, Vector2(0.5, 1.0))
		fx.anchor_left = 0.5
		fx.anchor_right = 0.5
		fx.offset_left = side * half
		fx.offset_right = side * half
		fx.offset_top = -12.0  # The row's bottom edge (the VBox separation above the anchor).
		fx.offset_bottom = -12.0
		_pillar_anchor.add_child(fx)
		_pillars.append(fx)


## Adds one action-bar button calling `cb` to `parent`, with the key chip of
## `hint` (an InputHints spec) inside its left edge.
func _action_button(parent: Control, cb: Callable, hint: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(InRunUiData.ACTION_WIDTH, InRunUiData.ACTION_HEIGHT)
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(func() -> void: _on_action(cb))
	InputHints.attach(b, hint)
	parent.add_child(b)
	return b


## Shows `offers` as cards for reaching level `for_level`.
func open(offers: Array[Dictionary], for_level: int) -> void:
	_for_level = for_level
	_banish_mode = false
	_opened_msec = Time.get_ticks_msec()
	UiMotion.open(self, false)  # Fade in (no whoosh: the level-up chime plays).
	_show(offers)
	for i in _pillars.size():
		_pillars[i].play(float(i) * InRunUiData.PILLAR_STAGGER)


## (Re)builds the cards for `offers` and refreshes the action bar.
func _show(offers: Array[Dictionary]) -> void:
	_offers = offers
	RunBuild.clear(_cards_box)  # Detached at once: the row never holds two sets (rerolls).
	_cards.clear()
	_buttons.clear()
	for i in offers.size():
		var card := _make_card(offers[i], i)
		_cards_box.add_child(card)
		_cards.append(card)
	_title.text = "Level %d" % _for_level
	visible = true
	_waiting = true
	_refresh_actions()
	UiMotion.stagger(_cards)  # Cards rise in one after another.
	for i in _cards.size():
		if _cards[i].has_meta(&"evo_fx"):
			(_cards[i].get_meta(&"evo_fx") as UiFx).play(float(i) * UiMotionData.STAGGER_INTERVAL)  # Evolution burst as the card enters.
	if not _buttons.is_empty():
		UiTheme.focus_deferred(_buttons[0])
	if game != null and game.autotest != null:
		_autoplay.call_deferred()


## Hides the panel.
func close() -> void:
	UiMotion.hide(self, false)  # Quick fade out, then hidden.
	_waiting = false
	_banish_mode = false


## Updates the action-bar labels / availability and the status line.
func _refresh_actions() -> void:
	var ab := game.abilities
	_reroll_btn.text = "Reroll (%d)" % ab.rerolls_left
	_reroll_btn.disabled = ab.rerolls_left <= 0
	_banish_btn.text = ("Cancel" if _banish_mode else "Banish (%d)" % ab.banishes_left)
	_banish_btn.disabled = ab.banishes_left <= 0 and not _banish_mode
	_skip_btn.text = "Skip +%d%% HP" % int(roundf(LevelUpData.SKIP_HEAL_FRACTION * 100.0))
	var has_evo := false
	for o in _offers:
		has_evo = has_evo or String(o["kind"]) == "evolution"
	if _banish_mode:
		_status.text = "Pick a card to banish"
		_status.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.35))
	elif has_evo:
		_status.text = "Evolution ready"
		_status.add_theme_color_override("font_color", UiTheme.TEXT_GOLD)
	else:
		_status.text = ""
	_status_cancel.visible = _banish_mode
	for i in _cards.size():
		var dim := _banish_mode and not ab.can_banish(_offers[i])
		_cards[i].modulate = Color(1, 1, 1, 0.4) if dim else (Color(1.0, 0.78, 0.78) if _banish_mode else Color.WHITE)


## Builds one card for offer `o` (index `idx`). Layout: a MarginContainer
## root whose minimum size is the max of its children, holding a full-size
## Button (focus / click / controller A) underneath a padded content column
## (and, on an evolution card, the gold sheen over it). The card therefore
## grows to fit its text and can never overflow.
func _make_card(o: Dictionary, idx: int) -> Control:
	var kind := String(o["kind"])
	var evo := kind == "evolution"  # Gold card.
	var accent := "gold" if evo else "violet"  # Kit accent of the frame and divider.
	var card := MarginContainer.new()
	card.custom_minimum_size = Vector2(InRunUiData.CARD_WIDTH, InRunUiData.CARD_MIN_HEIGHT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := Button.new()
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(_choose.bind(idx, false))
	UiTheme.style_button(b, "card", accent)  # Card frame (UI kit).
	card.add_child(b)
	UiMotion.liftable(b, card)  # The whole card lifts on hover / focus.
	_buttons.append(b)
	var content := MarginContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("margin_left", InRunUiData.CARD_PAD_X)
	content.add_theme_constant_override("margin_right", InRunUiData.CARD_PAD_X)
	content.add_theme_constant_override("margin_top", InRunUiData.CARD_PAD_Y)
	content.add_theme_constant_override("margin_bottom", InRunUiData.CARD_PAD_Y)
	card.add_child(content)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 6)
	content.add_child(vb)
	var text_width := InRunUiData.CARD_WIDTH - 2.0 * float(InRunUiData.CARD_PAD_X)  # Wrap width (px).
	vb.add_child(_tag_row(o, idx))
	var icon_box := CenterContainer.new()  # The icon, and the evolution burst over it.
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_child(IconGlyph.new(String(o["icon"]), Vector2(InRunUiData.CARD_ICON, InRunUiData.CARD_ICON)))
	vb.add_child(icon_box)
	if evo:
		var fx := UiFx.new("evolution", InRunUiData.EVO_FX_SCALE)  # Played as the card enters (_show()).
		icon_box.add_child(fx)
		card.set_meta(&"evo_fx", fx)
	var name_label := UiTheme.tier_label(String(o["name"]), UiTheme.Tier.NAME, UiTheme.TEXT_GOLD if evo else UiTheme.TEXT)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Long evolution names wrap.
	name_label.custom_minimum_size = Vector2(text_width, 0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(name_label)
	var lvl_row := _level_row(o)  # Pips, the evolution line, or null (fallback cards).
	if lvl_row != null:
		vb.add_child(lvl_row)
	vb.add_child(UiTheme.divider(accent))
	vb.add_child(UiTheme.para(String(o["description"]), text_width, UiTheme.TEXT_DIM))
	var deltas := UiTheme.tier_label("\n".join(o["deltas"]), UiTheme.Tier.BODY, UiTheme.TEXT_GOOD)
	deltas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deltas.custom_minimum_size = Vector2(text_width, 0)
	vb.add_child(deltas)
	var hint := String(o.get("evo_hint", ""))
	if hint != "":
		vb.add_child(UiTheme.para(hint, text_width, UiTheme.TEXT_GOLD))
	var recipe := RecipeIconRow.for_card(String(o.get("evo_recipe", "")))  # Null = nothing to show.
	if recipe != null:
		var push := Control.new()  # Pushes the recipe to the card's bottom edge.
		push.size_flags_vertical = Control.SIZE_EXPAND_FILL
		push.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(push)
		vb.add_child(recipe)
	if evo:
		content.add_child(UiShimmer.new())  # Gold sheen over the card's content.
	return card


## The card's top row: its number key chip (keyboard only), its kind tag in
## the kind's colour and, for a new item, a soul-teal NEW at the right.
func _tag_row(o: Dictionary, idx: int) -> HBoxContainer:
	var tag_color := Palette.NECRO_GREEN  # Summons.
	match String(o["tag"]):
		"SPELL":
			tag_color = Palette.VIOLET.lightened(0.3)
		"PASSIVE":
			tag_color = Palette.COLD_BLUE
		"RESTORE", "BOON", "EVOLUTION":
			tag_color = Palette.GOLD
		"PACT":
			tag_color = Palette.CRIMSON.lightened(0.3)  # Profane Pact (difficulty passive).
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	row.custom_minimum_size = Vector2(0, InputHintData.CHIP_HEIGHT)
	if idx < CARD_KEYS.size():
		row.add_child(InputHints.chip(InputHints.raw(CARD_KEYS[idx])))
	var tag_l := UiTheme.tier_label(String(o["tag"]), UiTheme.Tier.LABEL, tag_color)
	tag_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(tag_l)
	if _max_level(o) > 0 and int(o["from"]) == 0:
		var new_l := UiTheme.tier_label("New", UiTheme.Tier.LABEL, InRunUiData.PIP_NEW)
		new_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(new_l)
	return row


## The card's level line: level pips for a spell / summon / passive, a gold
## "Lv N -> Evolved" line for an evolution, nothing for the fallback cards.
func _level_row(o: Dictionary) -> Control:
	var kind := String(o["kind"])
	if kind == "evolution":
		var l := UiTheme.tier_label("Lv %d  ->  Evolved" % int(o["from"]), UiTheme.Tier.BODY, UiTheme.TEXT_GOLD)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l
	var top := _max_level(o)  # Pip count (0 = no level track).
	if top <= 0:
		return null
	var row := HBoxContainer.new()  # Pips + "Lv N".
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	row.add_child(LevelPips.new(int(o["from"]), int(o["to"]), top))
	row.add_child(UiTheme.tier_label("Lv %d" % int(o["to"]), UiTheme.Tier.BODY, InRunUiData.PIP_NEW))
	return row


## Highest level of the item offer `o` upgrades (its level table's length),
## or 0 for an offer without levels (evolution, fallback, skip). Read-only.
static func _max_level(o: Dictionary) -> int:
	var id := String(o["id"])
	match String(o["kind"]):
		"spell":
			return (AbilityData.SPELLS[id]["levels"] as Array).size() if AbilityData.SPELLS.has(id) else 0
		"passive":
			return (PassiveData.PASSIVES[id]["levels"] as Array).size() if PassiveData.PASSIVES.has(id) else 0
		"summon":
			return (UnitData.LEVELS[id] as Array).size() if UnitData.LEVELS.has(id) else 0
	return 0


## True while input is accepted (open, waiting, grace period over) or forced.
func _accepting(forced: bool) -> bool:
	if not _waiting:
		return false
	return forced or Time.get_ticks_msec() - _opened_msec >= INPUT_GRACE_MSEC


## Runs an action-bar callback if input is accepted.
func _on_action(cb: Callable) -> void:
	if _accepting(false):
		cb.call()


## Card `idx` was picked: banishes it in banish mode, otherwise emits it
## once (ignores input during the grace period unless `forced` by the
## autotest).
func _choose(idx: int, forced: bool) -> void:
	if not _accepting(forced) or idx < 0 or idx >= _offers.size():
		return
	if _banish_mode:
		_banish(idx)
		return
	_waiting = false
	card_chosen.emit(_offers[idx])


## Spends a reroll and redraws every card.
func _reroll() -> void:
	if game.abilities.use_reroll():
		_banish_mode = false
		_show(game.abilities.build_offers(PlayerData.CARDS_PER_LEVEL))


## Enters / leaves banish mode (the next picked card is banished).
func _toggle_banish() -> void:
	UiMotion.settle(_cards)  # The banish dim must not be overwritten by an entrance.
	_banish_mode = not _banish_mode and game.abilities.banishes_left > 0
	_refresh_actions()


## Banishes card `idx` (if allowed) and redraws that card.
func _banish(idx: int) -> void:
	if not game.abilities.can_banish(_offers[idx]):
		return
	_banish_mode = false
	_show(game.abilities.banish_offer(_offers, idx))
	if idx < _buttons.size():
		UiTheme.focus_deferred(_buttons[idx])


## Skips this level-up (small heal, see LevelUpData).
func _skip() -> void:
	_waiting = false
	card_chosen.emit(game.abilities.skip_offer())


## Autotest: asks the policy for an action and performs it. Rerolls and
## banishes redraw the panel, which asks again (charges bound the loop).
func _autoplay() -> void:
	if not _waiting or game == null or game.autotest == null:
		return
	var act := game.autotest.choose_action(_offers)
	match String(act["action"]):
		"reroll":
			_reroll()
		"banish":
			var i := int(act["index"])
			if i >= 0 and i < _offers.size() and game.abilities.can_banish(_offers[i]):
				_banish_mode = true
				_banish(i)
			else:
				_choose(0, true)
		"skip":
			_skip()
		_:
			_choose(int(act["index"]), true)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _waiting:
		return
	var pad := event as InputEventJoypadButton
	if pad != null and pad.pressed:
		match pad.button_index:
			JOY_BUTTON_X:
				_handled_action(_reroll)
			JOY_BUTTON_LEFT_SHOULDER:
				_handled_action(_toggle_banish)
			JOY_BUTTON_RIGHT_SHOULDER:
				_handled_action(_skip)
			JOY_BUTTON_B:
				if _banish_mode:
					_handled_action(_toggle_banish)
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var idx := -1
	match key.physical_keycode:
		KEY_1, KEY_KP_1:
			idx = 0
		KEY_2, KEY_KP_2:
			idx = 1
		KEY_3, KEY_KP_3:
			idx = 2
		KEY_R:
			_handled_action(_reroll)
		KEY_B:
			_handled_action(_toggle_banish)
		KEY_N:
			_handled_action(_skip)
		KEY_ESCAPE:
			if _banish_mode:
				_handled_action(_toggle_banish)
	if idx >= 0:
		get_viewport().set_input_as_handled()
		_choose(idx, false)


## Marks the event handled and runs action `cb` (grace period applies).
func _handled_action(cb: Callable) -> void:
	get_viewport().set_input_as_handled()
	_on_action(cb)
