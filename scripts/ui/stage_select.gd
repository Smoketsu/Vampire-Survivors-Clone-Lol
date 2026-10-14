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
	_content = center
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	center.add_child(vb)
	vb.add_child(UiTheme.title("Choose Your Battlefield"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", FrontDoorData.CARD_GAP)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	var cards: Array = []  # Staggered in.
	for id: String in StageRegistry.ORDER:
		var card := _build_card(id)
		row.add_child(card)
		_cards[id] = card
		cards.append(card)
	_back = Button.new()
	_back.text = "Back"
	_back.custom_minimum_size = FrontDoorData.STAGE_BACK_SIZE
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(close)
	vb.add_child(_back)
	var hints := InputHints.bottom_strip([[InputHints.MOVE, "Move"], ["ui_accept", "March"], ["ui_cancel", "Back"]])
	add_child(hints)
	_wire_focus()
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)
	var first: Button = _cards.get(GameState.last_stage_id, _cards[StageRegistry.ORDER[0]])
	if not Meta.is_stage_unlocked(String(first.get_meta(&"stage_id"))):
		first = _cards[StageRegistry.ORDER[0]]
	first.grab_focus.call_deferred()
	UiMotion.open(self)  # Fade / rise in.
	UiMotion.stagger(cards, 0.05)


## One stage card: a Button holding the vignette, the texts and the footer.
func _build_card(id: String) -> Button:
	var def: Dictionary = StageRegistry.STAGES[id]
	var unlocked := Meta.is_stage_unlocked(id)
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


## A locked card's one-liner: the boss to slay to open it, in crimson.
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
## the stage's own unlock text.
static func _lock_text(def: Dictionary) -> String:
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
	var ids: Array = StageRegistry.ORDER
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
	if not Meta.is_stage_unlocked(id):
		Sfx.play_ui("denied")
		_shake(_cards[id])
		return
	Sfx.play("ui_confirm")
	var setup := PreRunSetup.open_over(self, _cards[id], Meta.prerun_config(id))  # Difficulty / modifiers step.
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
