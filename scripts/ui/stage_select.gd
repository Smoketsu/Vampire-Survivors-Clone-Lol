## StageSelect — the stage-select screen opened by Play (GDD §10.2 "Select
## stage: Graveyard, Crimson March or Sanctum (progression-locked
## initially)"; GDD §15.0 "Front door screens"). Three tall vignette cards,
## one per StageRegistry stage, over the menu's diorama: a composed pixel
## scene of the stage (StageVignette: its floor, props and its boss in an
## attack pose facing the undead), the chapter (LABEL), the name (NAME) and
## ONE line (FrontDoorData.STAGE_LINES; the full GDD description is the
## card's tooltip), then a footer with the best time and boss kills (small
## pixel icons), the stage's Soul Ash bonus and a gold Hyper badge once the
## stage was cleared on Hyper (HyperBadge; Meta.hyper_clears). A LOCKED stage
## (GDD §9.3: slay the previous stage's boss) shows its scene as a silhouette
## under a padlock and a one-liner naming the boss to slay; pressing it plays
## `denied` and shakes the card. Focusing a card turns the diorama to that
## stage's mood (MenuBackdrop.set_mood(): night, dusk, dawn) and brightens
## its scene. Keyboard, mouse and controller navigable (arrows / D-pad
## between cards, Enter / A to march, Esc / B back).
## ACTS (GDD §15.0 "Act II: the Ancient Eye"): the campaign's stages are shown
## one act at a time (StageRegistry.ACTS / "act"): tab buttons above the cards
## (Q / E, LB / RB, or a click) switch between Act I and Act II; the screen opens
## on the act of the last stage played. A registered stage that is not yet
## playable (StageRegistry "playable": false, the Act II foundation stubs) shows
## a locked card reading "Coming soon".
## Choosing an unlocked stage opens the pre-run setup (PreRunSetup) over this
## screen (this screen's cards fade out while it is open); when it confirms,
## `stage_chosen` is emitted with the finished RunConfig. Backing out of it
## returns to the stage card.
class_name StageSelect
extends Control

## A stage was chosen and set up: start a run with `config`.
signal stage_chosen(config: RunConfig)
## The screen closed without a choice (Back / Esc).
signal closed

## Control that gets focus back when the screen closes.
var return_focus: Control = null
## Begin caption of the pre-run setup this screen opens ("Done" from the
## co-op lobby, which takes the RunConfig back instead of starting a run).
var setup_begin_text: String = "Begin"
## Stage id -> its card Button.
var _cards: Dictionary = {}
## Stage id -> its StageVignette.
var _vignettes: Dictionary = {}
## Back button.
var _back: Button
## The screen's own content (title, cards, Back, hint strip): faded out while
## the pre-run setup is open over it.
var _content: Control
## The diorama behind the menu (null when opened elsewhere): follows the
## focused stage's mood.
var _backdrop: MenuBackdrop = null
## Running fade of the content's alpha (null when settled).
var _content_tween: Tween = null
## Act shown (StageRegistry.ACTS key).
var _act: int = 1
## Act number -> its tab Button (empty when only one act has stages).
var _act_tabs: Dictionary = {}
## The row holding the shown act's cards.
var _row: HBoxContainer


## Opens the screen over `parent`; focus returns to `refocus` when it closes.
static func open_over(parent: Control, refocus: Control) -> StageSelect:
	var sel := StageSelect.new()
	sel.return_focus = refocus
	parent.add_child(sel)
	return sel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UiTheme.backdrop(0.85))
	_backdrop = _find_backdrop()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit (no-op at 720 px).
	_content = center
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	center.add_child(vb)
	vb.add_child(UiTheme.title("Choose Your Battlefield"))
	_act = StageRegistry.act_of(GameState.last_stage_id)
	if _acts().size() > 1:
		vb.add_child(_act_row())
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", FrontDoorData.CARD_GAP)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(_row)
	_back = Button.new()
	_back.text = "Back"
	_back.custom_minimum_size = FrontDoorData.STAGE_BACK_SIZE
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(close)
	vb.add_child(_back)
	var strip: Array = [[InputHints.MOVE, "Move"], ["ui_accept", "March"], ["ui_cancel", "Back"]]  # Bottom hints.
	if not _act_tabs.is_empty():
		strip.push_front([[InputHints.raw(KEY_Q, JOY_BUTTON_LEFT_SHOULDER), InputHints.raw(KEY_E, JOY_BUTTON_RIGHT_SHOULDER)], "Act"])
	var hints := InputHints.bottom_strip(strip)
	add_child(hints)
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)
	UiMotion.open(self)  # Fade / rise in.
	_show_act(_act, GameState.last_stage_id)


## Acts that hold at least one stage, in order.
static func _acts() -> Array:
	var out: Array = []
	for a: int in StageRegistry.ACTS:
		if not StageRegistry.stages_of_act(a).is_empty():
			out.append(a)
	out.sort()
	return out


## The act tabs: [Q] Act I · subtitle, Act II · subtitle [E].
func _act_row() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var lb := InputHints.chip(InputHints.raw(KEY_Q, JOY_BUTTON_LEFT_SHOULDER))
	lb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lb)
	for a: int in _acts():
		var b := Button.new()
		b.text = _act_text(a, true)
		b.custom_minimum_size = FrontDoorData.ACT_TAB_SIZE
		b.focus_mode = Control.FOCUS_NONE  # Switched by Q / E or a click; focus stays on the cards.
		b.set_meta(UiMotion.META_LIFT, false)
		b.pressed.connect(func() -> void: _switch_act(a))
		row.add_child(b)
		_act_tabs[a] = b
	var rb := InputHints.chip(InputHints.raw(KEY_E, JOY_BUTTON_RIGHT_SHOULDER))
	rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rb)
	# --- Act V: the Shogunate of the Rising Sun ---
	# Compact from the first layout: five full tabs made the column wider than
	# 1280 px before _show_act() shrank them, and the centred column kept that
	# width (the cards sat ~160 px right of centre).
	_size_act_tabs()
	return row


# --- Act IV: the Olympian Republic ---
## Text of act `a`'s tab: "Act IV · The Olympian Republic" when `full`, else
## "Act IV" (compact tabs, FrontDoorData.ACT_TABS_FULL_MAX).
static func _act_text(a: int, full: bool) -> String:
	var info: Dictionary = StageRegistry.ACTS[a]
	return "%s · %s" % [String(info["name"]), String(info["subtitle"])] if full else String(info["name"])


## Act IV: with more acts than FrontDoorData.ACT_TABS_FULL_MAX, only the shown
## act's tab keeps its full text and size, the others are compact (the row
## fits six acts at 1280 x 600 layout px); with fewer, every tab is full.
func _size_act_tabs() -> void:
	var compact := _act_tabs.size() > FrontDoorData.ACT_TABS_FULL_MAX  # Too many acts for full tabs.
	for a: int in _act_tabs:
		var b := _act_tabs[a] as Button
		var full := not compact or a == _act  # This tab shows its subtitle.
		b.text = _act_text(a, full)
		b.custom_minimum_size = FrontDoorData.ACT_TAB_SIZE if full else FrontDoorData.ACT_TAB_COMPACT_SIZE


## Shows act `act`'s cards (rebuilt), the gold frame on its tab, and focuses
## `focus_id`'s card when it is in the act and unlocked, else the act's first.
func _show_act(act: int, focus_id: String = "") -> void:
	_act = act
	_size_act_tabs()  # Act IV: compact tabs beyond three acts.
	for a: int in _act_tabs:
		UiTheme.style_button(_act_tabs[a] as Button, "button", "gold" if a == act else "")
	for c: Node in _row.get_children():
		_row.remove_child(c)
		c.queue_free()
	_cards = {}
	_vignettes = {}
	var cards: Array = []  # Staggered in.
	for id: String in StageRegistry.stages_of_act(act):
		var card := _build_card(id)
		_row.add_child(card)
		_cards[id] = card
		cards.append(card)
	_wire_focus()
	var ids := StageRegistry.stages_of_act(act)
	var first: Button = _cards.get(focus_id, _cards[ids[0]])
	if not _is_open(String(first.get_meta(&"stage_id"))):
		first = _cards[ids[0]]
	first.grab_focus.call_deferred()
	UiMotion.stagger(cards, 0.05)


## Switches to act `act` (a tab click or Q / E); nothing when already shown.
func _switch_act(act: int) -> void:
	if act == _act or not _act_tabs.has(act):
		return
	Sfx.play_ui("ui_tick")
	_show_act(act)


## True when stage `id` can be played: unlocked and playable.
static func _is_open(id: String) -> bool:
	return StageRegistry.is_playable(id) and Meta.is_stage_unlocked(id)


## One stage card: a Button holding the vignette, the texts and the footer.
func _build_card(id: String) -> Button:
	var def: Dictionary = StageRegistry.STAGES[id]
	var unlocked := _is_open(id)
	var b := Button.new()
	b.custom_minimum_size = FrontDoorData.CARD_SIZE
	b.focus_mode = Control.FOCUS_ALL  # Locked cards stay focusable so their requirement can be read.
	b.set_meta(&"stage_id", id)
	UiTheme.style_button(b, "card", "violet")
	b.tooltip_text = String(def["description"])  # The long GDD description.
	b.pressed.connect(_choose.bind(id))
	b.focus_entered.connect(_on_card_focus.bind(id, true))
	b.focus_exited.connect(_on_card_focus.bind(id, false))
	b.mouse_entered.connect(func() -> void: b.grab_focus())
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset := FrontDoorData.CARD_INSET  # Content inset (px).
	box.offset_left = inset
	box.offset_right = -inset
	box.offset_top = inset
	box.offset_bottom = -inset
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var vig := StageVignette.new(id, not unlocked)
	box.add_child(vig)
	_vignettes[id] = vig
	var gap := Control.new()  # A little air under the scene.
	gap.custom_minimum_size = Vector2(0, 4)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(gap)
	box.add_child(UiTheme.tier_label(String(def["chapter"]), UiTheme.Tier.LABEL, UiTheme.TEXT_DIM))
	box.add_child(UiTheme.tier_label(String(def["display_name"]), UiTheme.Tier.NAME, UiTheme.TEXT_GOLD if unlocked else UiTheme.TEXT_DIM))
	var line := String(FrontDoorData.STAGE_LINES.get(id, ""))  # The one line.
	if unlocked:
		box.add_child(UiTheme.para(line, FrontDoorData.VIGNETTE_SIZE.x, UiTheme.TEXT))
	else:
		box.add_child(_lock_line(def))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)
	box.add_child(_footer(id, def) if unlocked else _locked_footer())
	return b


## A locked card's footer: a small padlock and "Locked".
static func _locked_footer() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := MaskIcon.new("padlock", 1)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var l := UiTheme.tier_label("Locked", UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	return row


## A locked card's one-liner: the boss to slay to open it, in crimson (or
## "Coming soon" for a stage not yet playable).
func _lock_line(def: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := MaskIcon.new("skull_crown", 2)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	row.add_child(UiTheme.tier_label(_lock_text(def), UiTheme.Tier.BODY, Palette.CRIMSON.lightened(0.4)))
	return row


## "Slay <boss>" for the stage `def` requires (StageRegistry unlock), else
## the stage's own unlock text; "Coming soon" for a stage not yet playable.
static func _lock_text(def: Dictionary) -> String:
	if not bool(def.get("playable", true)):
		return FrontDoorData.COMING_SOON
	var req: Dictionary = def.get("unlock", {})
	var need := String(req.get("stage", ""))  # Stage whose boss must fall.
	if StageRegistry.STAGES.has(need):
		return "Slay %s" % String(StageRegistry.STAGES[need]["boss"]["short_name"])
	return String(def.get("unlock_text", "Locked"))


## An unlocked card's footer: best time and boss kills (pixel icons), the
## Soul Ash bonus, and the Hyper badge once cleared on Hyper.
func _footer(id: String, def: Dictionary) -> Control:
	var rec := Meta.stage_record(id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var best := int(float(rec["best_time"]))  # Best time (s).
	row.add_child(_stat("hourglass", "%d:%02d" % [floori(float(best) / 60.0), best % 60] if best > 0 else "--:--"))
	row.add_child(_stat("skull_crown", "%d" % int(float(rec["boss_kills"]))))
	if float(def["ash_mult"]) > 1.0:
		row.add_child(_stat("ember", "×%.2f" % float(def["ash_mult"]), MetaGlyphs.EMBER.lightened(0.25)))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(fill)
	if Meta.hyper_clear_count(id) > 0:
		row.add_child(HyperBadge.row("Hyper", 18))
	return row


## A small footer stat: pixel icon `icon` and `text`.
static func _stat(icon: String, text: String, color: Color = UiTheme.TEXT) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 5)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var i := MaskIcon.new(icon, 2)
	i.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(i)
	var l := UiTheme.tier_label(text, UiTheme.Tier.BODY, color)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(l)
	return hb


## A card gained / lost focus: its scene brightens, the diorama takes the
## stage's mood.
func _on_card_focus(id: String, on: bool) -> void:
	(_vignettes[id] as StageVignette).set_focused(on)
	if on and _backdrop != null:
		_backdrop.set_mood(id)


## Explicit focus neighbours: cards left/right in a row, Back below them.
func _wire_focus() -> void:
	var ids: Array = Array(StageRegistry.stages_of_act(_act))
	for i in ids.size():
		var b: Button = _cards[ids[i]]
		var left: Button = _cards[ids[maxi(0, i - 1)]]
		var right: Button = _cards[ids[mini(ids.size() - 1, i + 1)]]
		b.focus_neighbor_left = b.get_path_to(left)
		b.focus_neighbor_right = b.get_path_to(right)
		b.focus_neighbor_bottom = b.get_path_to(_back)
		b.focus_neighbor_top = b.get_path_to(b)
	var mid: Button = _cards[ids[ids.size() / 2]]
	_back.focus_neighbor_top = _back.get_path_to(mid)
	_back.focus_neighbor_left = _back.get_path_to(_back)
	_back.focus_neighbor_right = _back.get_path_to(_back)
	_back.focus_neighbor_bottom = _back.get_path_to(_back)


## A card was pressed: an unlocked stage opens the pre-run setup with its
## RunConfig (remembered choices); a locked one is denied with a shake.
func _choose(id: String) -> void:
	if not _is_open(id):
		Sfx.play_ui("denied")
		_shake(_cards[id])
		return
	Sfx.play("ui_confirm")
	var setup := PreRunSetup.open_over(self, _cards[id], Meta.prerun_config(id), setup_begin_text)  # Difficulty / modifiers step.
	setup.confirmed.connect(func(c: RunConfig) -> void: stage_chosen.emit(c))


## A short sideways shake of `c` (denied), on real time; none with motion off.
func _shake(c: Control) -> void:
	if not UiMotion.enabled():
		return
	var tw := c.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var amp := FrontDoorData.DENIED_SHAKE_PX  # Amplitude (px).
	var step := FrontDoorData.DENIED_SHAKE_TIME / 5.0  # One swing (s).
	var x := c.position.x  # Rest x.
	for dx: float in [amp, -amp, amp * 0.5, -amp * 0.5, 0.0]:
		tw.tween_property(c, "position:x", x + dx, step)
	tw.tween_callback(func() -> void:
		if c.get_parent() is Container:
			(c.get_parent() as Container).queue_sort())


## The pre-run setup opened over this screen: fade the cards out (the
## setup's own scrim stays low, so the diorama shows around it).
func _on_child_entered(node: Node) -> void:
	if node is PreRunSetup:
		_fade_content(false)


## The pre-run setup is leaving: bring the cards back.
func _on_child_exiting(node: Node) -> void:
	if node is PreRunSetup:
		_fade_content(true)


## Fades this screen's content in (`shown`) or out over MenuBackdropData.DIM_TIME
## (at once with motion off); the hint strip hides with it.
func _fade_content(shown: bool) -> void:
	if _content_tween != null:
		_content_tween.kill()
		_content_tween = null
	if not UiMotion.enabled():
		_content.modulate.a = 1.0 if shown else 0.0
	else:
		_content_tween = create_tween()
		_content_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_content_tween.tween_property(_content, "modulate:a", 1.0 if shown else 0.0, MenuBackdropData.DIM_TIME)
	for c: Node in get_children():
		if c is HBoxContainer:  # The hint strip.
			(c as Control).visible = shown


## The diorama of the MainMenu this screen is opened over (null elsewhere).
func _find_backdrop() -> MenuBackdrop:
	var n: Node = get_parent()
	while n != null:
		if n is MainMenu:
			return (n as MainMenu).backdrop()
		n = n.get_parent()
	return null


## Restores focus to the opener and the diorama's mood, then frees the screen.
func close() -> void:
	if UiMotion.is_closing(self):
		return
	closed.emit()
	if _backdrop != null:
		_backdrop.set_mood(MenuBackdropData.DEFAULT_MOOD)
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	UiMotion.close(self, queue_free)  # Quick fade out, then freed.


## Esc / controller B closes the screen.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
		return
	var step := CreditsScreen._page_step(event)  # -1 / +1 for an act switch (Q / E, LB / RB), 0 otherwise.
	if step != 0 and not _act_tabs.is_empty() and not _has_setup_open():
		get_viewport().set_input_as_handled()
		var acts := _acts()
		var i := clampi(acts.find(_act) + step, 0, acts.size() - 1)
		_switch_act(int(acts[i]))


## True while the pre-run setup is open over this screen (it owns Q / E then).
func _has_setup_open() -> bool:
	for c: Node in get_children():
		if c is PreRunSetup:
			return true
	return false
