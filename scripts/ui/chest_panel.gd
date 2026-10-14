## ChestPanel — the treasure-chest reveal (user request, ChestData). Game
## opens it with the rewards already applied (AbilityManager.chest_rewards)
## while the tree is paused. Confirm (Enter / Space / click / pad A, or Esc /
## B) first skips the reveal, then closes the panel; Game resumes the run.
## The autotest closes it at once.
##
## Presentation (menu modernization wave 2, numbers in InRunUiData): a gold
## ornate panel (gold = chest) with the title, a "3 UPGRADES" label and the
## chest stage (ChestStage): the real chest art (pickups/chest.png) at a
## whole-number scale, which rattles, then bursts open (the `chest_open`
## effect strip, UiFx), its lid lifting off on a band of light, with slowly
## turning rays and a glow behind it, all clipped to the stage so nothing
## runs into the text above. Then the rewards rise in one by one, centred:
## one framed row per reward (icon, name, the level change as text and as
## level pips; LevelPips). An evolution reward gets a gold row, gold name,
## the `evolution` burst over its icon and a gold sheen (UiShimmer). The
## Claim button is gold and carries the confirm key's InputHints chip.
## Every motion is instant under the autotest and with "Reduce motion"
## (the chest is shown open, the rows at once).
class_name ChestPanel
extends Control

## The panel was closed (Game resumes the run).
signal closed

## Owning run (autotest hook).
var game: Game
## Title label ("Treasure Chest").
var _title: Label
## Subtitle ("3 UPGRADES").
var _subtitle: Label
## The chest stage (chest art, rays, glow, burst).
var _stage: ChestStage
## Container of the reward rows.
var _rows_box: VBoxContainer
## One row Control per reward (revealed one by one).
var _rows: Array[Control] = []
## "Claim" button (closes the panel once everything is shown).
var _claim: Button
## Real time (ms) the panel opened (reveal clock).
var _opened_msec: int = 0
## True while the panel is shown and waiting for confirm.
var _open: bool = false
## True once the player skipped the reveal (everything shown).
var _skipped: bool = false


## The chest stage: the chest sprite at a whole-number scale on a glow, with
## light rays behind it once open, the lid lifted on a band of light, and the
## `chest_open` burst (a UiFx child) centred on the chest. Clipped to its own
## rect. Real-time driven; static (open) when motion is off.
class ChestStage:
	extends Control
	## Real time (usec) the reveal started.
	var start_usec: int = 0
	## True when the reveal is skipped or motion is off: drawn fully open.
	var settled: bool = true
	## The chest_open burst, centred on the chest.
	var burst: UiFx
	## True once the burst has been started for this reveal.
	var _burst_started: bool = false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true
		burst = UiFx.new("chest_open", InRunUiData.CHEST_FX_SCALE)
		add_child(burst)

	func _ready() -> void:
		SpriteBank.apply_sharp(self)

	## Starts the reveal now (or shows it settled when motion is off).
	func restart() -> void:
		start_usec = Time.get_ticks_usec()
		settled = not UiMotion.enabled()
		_burst_started = settled
		burst.stop()
		queue_redraw()

	## Jumps to the open chest (the player skipped the reveal).
	func settle() -> void:
		settled = true
		queue_redraw()

	## Seconds since the reveal started (real time); large when settled.
	func age() -> float:
		return 99.0 if settled else float(Time.get_ticks_usec() - start_usec) / 1000000.0

	## Centre of the chest sprite (layout px, whole px).
	func chest_center() -> Vector2:
		return Vector2(roundf(size.x * 0.5), roundf(size.y - 12.0 - 29.0 * float(InRunUiData.CHEST_SCALE) * 0.5))

	func _process(_delta: float) -> void:
		if not is_visible_in_tree():
			return
		var t := age()
		if not _burst_started and t >= InRunUiData.CHEST_SHAKE_TIME:
			_burst_started = true
			burst.play()
		if UiMotion.enabled():
			queue_redraw()  # Rays turn, lid lifts.
		burst.position = chest_center() + Vector2(0.0, -8.0)

	func _draw() -> void:
		var t := age()
		var c := chest_center()
		var open_k := clampf((t - InRunUiData.CHEST_SHAKE_TIME) / 0.15, 0.0, 1.0)  # 0 closed .. 1 open.
		var light_k := clampf((t - InRunUiData.CHEST_SHAKE_TIME) / 0.35, 0.0, 1.0)  # Glow and rays fade in.
		var glow := InRunUiData.GLOW_COLOR
		for i in 3:  # Soft stepped glow under the chest.
			var r := InRunUiData.GLOW_RADIUS * (1.0 - float(i) * 0.25)
			draw_circle(c, r, Color(glow, glow.a * (0.35 + 0.65 * light_k)))
		if light_k > 0.0:
			_rays(c + Vector2(0.0, -10.0), light_k, t)
		var tex := SpriteBank.texture("pickups/chest")  # Chest art (null = code chest).
		if tex == null:
			PowerupGlyphs.draw_chest(self, c, 30.0, t, open_k)
			return
		var k := float(InRunUiData.CHEST_SCALE)  # Layout px per art px.
		var w := float(tex.get_width())
		var h := float(tex.get_height())
		var shake := Vector2.ZERO  # Rattle offset (whole px).
		if t < InRunUiData.CHEST_SHAKE_TIME:
			var a := InRunUiData.CHEST_SHAKE_PX * (t / InRunUiData.CHEST_SHAKE_TIME)  # Grows into the burst.
			shake = Vector2(roundf(sin(t * InRunUiData.CHEST_SHAKE_FREQ) * a), 0.0)
		var tl := (c - Vector2(w, h) * k * 0.5).round() + shake  # Sprite top-left.
		var lid_h := float(InRunUiData.CHEST_LID_ROWS)  # Lid rows (art px).
		var lift := roundf(float(InRunUiData.CHEST_LID_LIFT) * open_k) * k  # Lid rise (layout px).
		if open_k > 0.0:  # Light pouring out of the open gap: a soft band with a bright core.
			var gap := Rect2(tl + Vector2(3.0 * k, lid_h * k - lift), Vector2((w - 6.0) * k, lift + k))
			draw_rect(gap, Color(1.0, 0.78, 0.4, 0.55 * open_k))
			var core := Rect2(gap.position + Vector2(roundf(gap.size.x * 0.2 / k) * k, k), Vector2(roundf(gap.size.x * 0.6 / k) * k, maxf(k, gap.size.y - 2.0 * k)))
			draw_rect(core, Color(1.0, 0.96, 0.8, 0.9 * open_k))
		draw_texture_rect_region(tex, Rect2(tl + Vector2(0.0, lid_h * k), Vector2(w, h - lid_h) * k), Rect2(0.0, lid_h, w, h - lid_h))
		draw_texture_rect_region(tex, Rect2(tl - Vector2(0.0, lift), Vector2(w, lid_h) * k), Rect2(0.0, 0.0, w, lid_h))

	## Turning light rays around `c` (alpha `k`, real time `t`).
	func _rays(c: Vector2, k: float, t: float) -> void:
		var spin := t * InRunUiData.RAY_SPIN if UiMotion.enabled() else 0.0  # Rotation (rad).
		var n := InRunUiData.RAY_COUNT
		for i in n:
			var a := TAU * float(i) / float(n) + spin  # Ray angle.
			var length := InRunUiData.RAY_LENGTH * (1.0 if i % 2 == 0 else InRunUiData.RAY_SHORT) \
					* (1.0 + InRunUiData.RAY_WIDEN * absf(cos(a)))  # Longer sideways.
			var half := InRunUiData.RAY_HALF_ANGLE
			var pts := PackedVector2Array([c, c + Vector2.from_angle(a - half) * length, c + Vector2.from_angle(a + half) * length])
			var col := InRunUiData.RAY_COLOR
			draw_colored_polygon(pts, Color(col, col.a * k))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_meta(UiMotion.META_CANCEL_SILENT, true)  # Esc / B claims here, no "back".
	add_child(UiTheme.backdrop(InRunUiData.CHEST_BACKDROP))
	var center := CenterContainer.new()  # Centres the panel on screen.
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiTheme.ornate_panel("gold")  # Gold hero frame (gold = chest).
	center.add_child(panel)
	var vb := VBoxContainer.new()  # Panel contents, top to bottom.
	vb.add_theme_constant_override("separation", 8)
	vb.custom_minimum_size = Vector2(InRunUiData.CHEST_WIDTH, 0)
	panel.add_child(vb)
	_title = UiTheme.title("Treasure Chest")
	vb.add_child(_title)
	_subtitle = UiTheme.tier_label("", UiTheme.Tier.LABEL, UiTheme.TEXT_GOLD.darkened(0.25))
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_subtitle)
	_stage = ChestStage.new()
	_stage.custom_minimum_size = Vector2(InRunUiData.CHEST_WIDTH, InRunUiData.CHEST_STAGE_HEIGHT)
	vb.add_child(_stage)
	vb.add_child(UiTheme.divider("gold"))
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 6)
	_rows_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(_rows_box)
	_claim = Button.new()
	_claim.text = "Claim"
	UiTheme.style_button(_claim, "button", "gold")
	InputHints.attach(_claim, "ui_accept")  # Confirm key chip (Enter / A).
	_claim.custom_minimum_size = Vector2(220, 42)
	_claim.focus_mode = Control.FOCUS_ALL
	_claim.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_claim.pressed.connect(_confirm)
	vb.add_child(_claim)


## Shows `rewards` (AbilityManager offer Dictionaries, already applied) for a
## chest of `count` upgrades.
func open(rewards: Array[Dictionary], count: int) -> void:
	RunBuild.clear(_rows_box)  # Detached at once (the panel never measures two sets).
	_rows.clear()
	_subtitle.text = "%d upgrade%s" % [count, "" if count == 1 else "s"]
	for r in rewards:
		var row := _make_row(r)  # One reward line.
		_rows_box.add_child(row)
		_rows.append(row)
	_opened_msec = Time.get_ticks_msec()
	_skipped = false
	_open = true
	UiMotion.open(self, false)  # Fade in (the chest sound plays instead of the whoosh).
	_stage.restart()
	UiMotion.stagger(_rows, InRunUiData.ROWS_START, InRunUiData.ROW_INTERVAL, InRunUiData.ROW_RISE)  # Rows rise in after the burst.
	for i in _rows.size():
		if _rows[i].has_meta(&"evo_fx"):
			(_rows[i].get_meta(&"evo_fx") as UiFx).play(InRunUiData.ROWS_START + float(i) * InRunUiData.ROW_INTERVAL)
	Sfx.play("chest_open")
	_claim.grab_focus.call_deferred()
	if game != null and game.autotest != null:
		_finish.call_deferred()


## One reward row, a fixed-width framed line: icon, name over the level
## change, and the level pips (or the evolution / fallback mark) at the
## right. Evolution rows are gold with a burst and a sheen.
func _make_row(r: Dictionary) -> Control:
	var kind := String(r["kind"])  # Offer kind (spell / summon / passive / evolution / fallback).
	var evo := kind == "evolution"
	var frame := PanelContainer.new()  # The row's kit frame.
	frame.add_theme_stylebox_override("panel", UiTheme.style("button", "gold") if evo else UiTheme.style("panel", "dim"))
	frame.custom_minimum_size = Vector2(InRunUiData.ROW_WIDTH, 0)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()  # Icon + texts + level mark.
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(row)
	var icon_box := CenterContainer.new()  # The icon (and the evolution burst over it).
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_child(IconGlyph.new(String(r["icon"]), Vector2(InRunUiData.ROW_ICON, InRunUiData.ROW_ICON)))
	row.add_child(icon_box)
	if evo:
		var fx := UiFx.new("evolution", 1)
		icon_box.add_child(fx)
		frame.set_meta(&"evo_fx", fx)
	var texts := VBoxContainer.new()  # Name over the change line.
	texts.add_theme_constant_override("separation", 0)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(texts)
	texts.add_child(UiTheme.tier_label(String(r["name"]), UiTheme.Tier.NAME, UiTheme.TEXT_GOLD if evo else UiTheme.TEXT))
	var change := ""  # "Lv 2 -> Lv 3", "Evolved" or the fallback effect.
	var change_col := UiTheme.TEXT_GOOD  # Its colour.
	match kind:
		"evolution":
			change = "Lv %d  ->  Evolved" % int(r["from"])
			change_col = UiTheme.TEXT_GOLD
		"fallback":
			var deltas: PackedStringArray = r["deltas"]  # Fallback effect lines.
			change = deltas[0] if not deltas.is_empty() else ""
		_:
			change = "New" if int(r["from"]) == 0 else "Lv %d  ->  Lv %d" % [int(r["from"]), int(r["to"])]
	texts.add_child(UiTheme.tier_label(change, UiTheme.Tier.BODY, change_col))
	var top := LevelUpPanel._max_level(r)  # Pip count (0 = none).
	if top > 0:
		row.add_child(LevelPips.new(int(r["from"]), int(r["to"]), top))
	if evo:
		var sheen := UiShimmer.new(InRunUiData.ROWS_START)  # Gold sheen over the row.
		sheen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.add_child(sheen)
	return frame


## Total reveal length for the current rewards (s).
func _reveal_length() -> float:
	return InRunUiData.ROWS_START + float(_rows.size()) * InRunUiData.ROW_INTERVAL + UiMotionData.STAGGER_TIME


## Confirm: skips the reveal if it is still running, otherwise closes.
func _confirm() -> void:
	if not _open:
		return
	if UiMotion.enabled() and not _skipped and float(Time.get_ticks_msec() - _opened_msec) / 1000.0 < _reveal_length():
		_skipped = true
		_stage.settle()
		UiMotion.settle(_rows)  # Every row at once.
		return
	_finish()


## Closes the panel and tells Game to resume.
func _finish() -> void:
	if not _open:
		return
	_open = false
	UiMotion.hide(self, false)  # Quick fade out, then hidden.
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_confirm()
