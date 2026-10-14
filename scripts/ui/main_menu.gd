## MainMenu — the title screen (GDD §10.1; GDD §15.0 "Front door screens"),
## composed over the animated pixel-art graveyard diorama (MenuBackdrop,
## GDD §15.0 "Menu diorama", the menu's first child). Top to bottom down the
## centre: the living NECROPATHY logo (MenuLogo: swaying soul flames, a
## breathing glow, rising embers; crisp at its whole-number scale), the
## tagline (BODY), a skull divider, a narrow column of one-word buttons (Play,
## Codex, Ossuary, Settings, Credits, Quit; FrontDoorData.MENU_ITEMS) flanked
## by a soul-wisp marker on the focused one (SoulMarker), a second divider,
## the gold Soul Ash plaque (SoulAshIcon + the balance, rolling up on open)
## and the lifetime stats as small pixel icons with numbers (runs, best time,
## bosses slain, achievements; MaskIcon, names in tooltips). The version sits
## small in the bottom-right corner and the input hint strip at the bottom.
## The diorama's dark band is fitted to the column (set_band()).
##
## Every sub-screen opened over the menu (any child added later: stage
## select, Ossuary, settings, codex, credits, a confirm dialog...) fades ALL
## of the menu's own content out (logo, buttons, plaque, version and hint
## strip live under one `_content` node), dims the diorama and lowers the
## overlay's own scrim so the graveyard stays visible around its panel;
## closing the last overlay restores both and the focus.
##
## Codex and Credits open screens another branch adds (CodexScreen /
## CreditsScreen); Quit asks through ConfirmDialog. Those scripts are loaded at
## RUNTIME by path (_optional()), so this file compiles and runs without them:
## a missing screen plays `denied`, and Quit without the dialog quits at once.
## Play opens the stage select (StageSelect, GDD §10.2), which opens the
## pre-run setup (PreRunSetup); the finished RunConfig reaches Main through
## `stage_chosen`.
class_name MainMenu
extends Control

## Play pressed (the stage select opens).
signal play_pressed
## A stage was chosen in the stage select: Main starts a run with `config`.
signal stage_chosen(config: RunConfig)

## Script of the codex / achievements screen (another branch; static
## open_over(host)). Loaded at runtime, may be missing.
const CODEX_SCRIPT: String = "res://scripts/ui/codex_screen.gd"
## Script of the credits screen (another branch; static open_over(host)).
const CREDITS_SCRIPT: String = "res://scripts/ui/credits_screen.gd"
## Script of the confirm dialog (another branch; static ask(host, title,
## body, confirm_label, on_confirm, danger)).
const CONFIRM_SCRIPT: String = "res://scripts/ui/confirm_dialog.gd"

## Play button (focused on open for keyboard / controller users).
var _play: Button
## Menu item id -> its Button (FrontDoorData.MENU_ITEMS).
var _buttons: Dictionary = {}
## Soul Ash balance number (refreshed whenever Meta changes).
var _ash_label: Label
## Lifetime stat id -> its number Label (runs, best, bosses, achievements).
var _stat_labels: Dictionary = {}
## The animated diorama behind everything (first child). Hooks: set_dim(),
## set_band(), set_mood() (MenuBackdrop header).
var _backdrop: MenuBackdrop
## The menu's own content (column, marker, version, hint strip): faded out
## while an overlay is open. Its alpha only goes to 0 (it stays visible), so
## the overlays' close() can still return focus to a menu button.
var _content: Control
## The soul-wisp focus marker over the button column.
var _marker: SoulMarker
## The last menu button that had focus (restored when the last overlay closes).
var _last_focus: Button = null
## Sub-screens currently open over the menu (direct children other than the
## backdrop and the content).
var _overlays: int = 0
## Running fade of the content's alpha (null when settled).
var _content_tween: Tween = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop = MenuBackdrop.new()
	add_child(_backdrop)
	_backdrop.set_band(0.0, FrontDoorData.MENU_BAND_WIDTH, FrontDoorData.MENU_BAND_ALPHA)
	_content = Control.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)
	var col := VBoxContainer.new()  # The centre column.
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.offset_top = FrontDoorData.MENU_TOP
	col.add_theme_constant_override("separation", FrontDoorData.MENU_BLOCK_GAP)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(col)
	var blocks: Array = []  # Staggered in on open, top to bottom.
	blocks.append(_title())
	var tagline := UiTheme.tier_label(FrontDoorData.MENU_TAGLINE, UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blocks.append(tagline)
	blocks.append(_divider())
	var list := VBoxContainer.new()  # The button column.
	list.add_theme_constant_override("separation", FrontDoorData.MENU_BUTTON_GAP)
	list.custom_minimum_size = Vector2(FrontDoorData.MENU_COLUMN_WIDTH, 0)
	list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for item: Array in FrontDoorData.MENU_ITEMS:
		list.add_child(_menu_button(String(item[0]), String(item[1])))
	_play = _buttons["play"]
	blocks.append(list)
	blocks.append(_divider())
	blocks.append(_plaque())
	blocks.append(_stats_row())
	for b: Control in blocks:
		col.add_child(b)
	_marker = SoulMarker.new()
	_content.add_child(_marker)
	_content.add_child(_version())
	_content.add_child(InputHints.bottom_strip([[InputHints.MOVE, "Move"], ["ui_accept", "Select"]]))
	_wire_focus()
	Meta.changed.connect(_refresh_meta)
	_refresh_meta()
	UiMotion.count_up(_ash_label, Meta.soul_ash, "%d", 0, false)  # The balance rolls up on open (silent).
	UiMotion.stagger(blocks, FrontDoorData.MENU_STAGGER_DELAY)
	_play.grab_focus.call_deferred()


## The title: the living pixel-art logo when its PNG exists, else the word.
func _title() -> Control:
	var logo := MenuLogo.new()
	if logo.has_art():
		logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return logo
	logo.free()
	return UiTheme.title("Necropathy", Palette.NECRO_GREEN)


## A skull divider the width of the logo (ornament between the blocks).
func _divider() -> Control:
	var d := UiTheme.divider()
	d.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	d.custom_minimum_size.x = FrontDoorData.MENU_COLUMN_WIDTH + 120.0
	return d


## One menu button: one word, the column's width; its focus / hover moves
## the soul-wisp marker.
func _menu_button(id: String, caption: String) -> Button:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(FrontDoorData.MENU_COLUMN_WIDTH, FrontDoorData.MENU_BUTTON_HEIGHT)
	b.set_meta(UiMotion.META_LIFT, false)  # The wisp marks focus; no card lift in a list.
	b.pressed.connect(_on_item.bind(id, b))
	b.focus_entered.connect(_on_button_focus.bind(b))
	b.mouse_entered.connect(func() -> void:
		if not UiMotion.is_closing(self) and _overlays == 0:
			b.grab_focus())
	_buttons[id] = b
	return b


## A menu button got focus: mark it.
func _on_button_focus(b: Button) -> void:
	_last_focus = b
	_marker.follow(b)


## Up / down wrap around the column; left / right stay put.
func _wire_focus() -> void:
	var ids: Array = []  # Button ids, top to bottom.
	for item: Array in FrontDoorData.MENU_ITEMS:
		ids.append(String(item[0]))
	for i in ids.size():
		var b: Button = _buttons[ids[i]]
		var up: Button = _buttons[ids[(i - 1 + ids.size()) % ids.size()]]
		var down: Button = _buttons[ids[(i + 1) % ids.size()]]
		b.focus_neighbor_top = b.get_path_to(up)
		b.focus_neighbor_bottom = b.get_path_to(down)
		b.focus_neighbor_left = b.get_path_to(b)
		b.focus_neighbor_right = b.get_path_to(b)


## A menu button was pressed.
func _on_item(id: String, b: Button) -> void:
	match id:
		"play":
			_open_stage_select()
		"ossuary":
			OssuaryMenu.open_over(self, b)
		"settings":
			SettingsMenu.open_over(self, b)
		"codex":
			_open_optional(CODEX_SCRIPT)
		"credits":
			_open_optional(CREDITS_SCRIPT)
		"quit":
			_quit()


## The Soul Ash plaque: a gold frame holding the icon, the balance and its name.
func _plaque() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.style("panel", "gold"))
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", FrontDoorData.PLAQUE_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(row)
	var icon := soul_ash_icon(FrontDoorData.PLAQUE_ICON_PX)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	_ash_label = UiTheme.tier_label("0", UiTheme.Tier.NAME, UiTheme.TEXT_GOLD)
	_ash_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_ash_label)
	var name_l := UiTheme.tier_label("Soul Ash", UiTheme.Tier.LABEL, MetaGlyphs.EMBER.lightened(0.25))
	name_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_l)
	return p


## The Soul Ash icon at `px` (the one function to swap its art: SoulAshIcon
## picks icons/soul_ash.png when it exists, else the code glyph).
static func soul_ash_icon(px: float) -> Control:
	return SoulAshIcon.new(px)


## The lifetime stats: icon + number pairs, their names in tooltips.
func _stats_row() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", FrontDoorData.STAT_GAP)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for s: Array in [["runs", "tomb", "Runs"], ["best", "hourglass", "Best time"],
			["bosses", "skull_crown", "Bosses slain"], ["achievements", "trophy", "Achievements"]]:
		var pair := HBoxContainer.new()  # Icon and number.
		pair.add_theme_constant_override("separation", FrontDoorData.STAT_INNER_GAP)
		pair.tooltip_text = String(s[2])
		pair.mouse_filter = Control.MOUSE_FILTER_STOP  # For the tooltip.
		var icon := MaskIcon.new(String(s[1]), FrontDoorData.STAT_ICON_SCALE)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pair.add_child(icon)
		var l := UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pair.add_child(l)
		_stat_labels[String(s[0])] = l
		row.add_child(pair)
	return row


## The release version, small in the bottom-right corner (project.godot
## application/config/version, bumped for each tagged release).
func _version() -> Label:
	var l := UiTheme.tier_label("v%s" % str(ProjectSettings.get_setting("application/config/version", "dev")),
			UiTheme.Tier.BODY, Color(UiTheme.TEXT_DIM, FrontDoorData.VERSION_ALPHA))
	l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	l.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	l.grow_vertical = Control.GROW_DIRECTION_BEGIN
	l.offset_right = -FrontDoorData.VERSION_INSET.x
	l.offset_bottom = -FrontDoorData.VERSION_INSET.y
	return l


## Play: opens the stage select over the menu (focus returns to Play when
## it closes); its choice is forwarded to Main.
func _open_stage_select() -> void:
	play_pressed.emit()
	var sel := StageSelect.open_over(self, _play)
	sel.stage_chosen.connect(func(config: RunConfig) -> void: stage_chosen.emit(config))


## Opens the screen whose script is at `path` (static open_over(host)) over
## the menu, or plays `denied` when that script is not in this build.
func _open_optional(path: String) -> void:
	var script := _optional(path)
	if script == null:
		Sfx.play_ui("denied")
		return
	script.call("open_over", self)


## Quit: asks first through the confirm dialog when it exists, else quits.
func _quit() -> void:
	var dialog := _optional(CONFIRM_SCRIPT)
	if dialog == null:
		get_tree().quit()
		return
	dialog.call("ask", self, "Quit?", "The dead will wait.", "Quit", func() -> void: get_tree().quit(), true)


## The script at `path` loaded at runtime, or null when it is not in this
## build (so this file never depends on another branch's classes).
static func _optional(path: String) -> Script:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Script


## Updates the Soul Ash balance and the lifetime stats.
func _refresh_meta() -> void:
	_ash_label.text = "%d" % Meta.soul_ash
	var lt: Dictionary = Meta.lifetime
	var best := int(float(lt.get("best_time", 0.0)))  # Best survival time (s).
	(_stat_labels["runs"] as Label).text = "%d" % int(float(lt.get("runs", 0.0)))
	(_stat_labels["best"] as Label).text = "%d:%02d" % [floori(float(best) / 60.0), best % 60]
	(_stat_labels["bosses"] as Label).text = "%d" % int(float(lt.get("boss_kills", 0.0)))
	(_stat_labels["achievements"] as Label).text = "%d/%d" % [Meta.achievements.size(), MetaData.ACHIEVEMENT_ORDER.size()]


## The diorama behind the menu (for screens opened over it: StageSelect
## follows the focused stage with set_mood()).
func backdrop() -> MenuBackdrop:
	return _backdrop


## A sub-screen was added over the menu: fade the content out, dim the
## diorama, and once the overlay is built lower its full-screen scrim.
func _on_child_entered(node: Node) -> void:
	if node == _backdrop or node == _content:
		return
	_overlays += 1
	if node is Control and not node.is_node_ready():
		node.ready.connect(_tame_scrim.bind(node as Control), CONNECT_ONE_SHOT)
	_set_overlay_look(true)


## A sub-screen is leaving: restore the menu (and its focus) once the last
## one has gone.
func _on_child_exiting(node: Node) -> void:
	if node == _backdrop or node == _content:
		return
	_overlays = maxi(0, _overlays - 1)
	if _overlays == 0:
		_set_overlay_look(false)
		_restore_focus.call_deferred()


## Gives the focus back to the last menu button when nothing has it (a
## screen that did not return it).
func _restore_focus() -> void:
	if not is_inside_tree() or _overlays > 0:
		return
	var f := get_viewport().gui_get_focus_owner()  # Current focus (null = none).
	if f == null and _last_focus != null and is_instance_valid(_last_focus):
		_last_focus.grab_focus()


## Fades the menu content out (`covered`) or back in, and dims / undims the
## diorama, over MenuBackdropData.DIM_TIME real seconds (at once with motion off).
func _set_overlay_look(covered: bool) -> void:
	_backdrop.set_dim(covered, not UiMotion.enabled())
	if _content_tween != null:
		_content_tween.kill()
		_content_tween = null
	if not UiMotion.enabled():
		_content.modulate.a = 0.0 if covered else 1.0
		return
	_content_tween = create_tween()
	_content_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_content_tween.tween_property(_content, "modulate:a", 0.0 if covered else 1.0, MenuBackdropData.DIM_TIME)


## Lowers the overlay's own full-screen scrim (a direct ColorRect child, as
## UiTheme.backdrop() makes) to MenuBackdropData.OVERLAY_SCRIM_ALPHA, so the
## dimmed diorama shows around the overlay's panel.
func _tame_scrim(overlay: Control) -> void:
	if not is_instance_valid(overlay):
		return
	for c in overlay.get_children():
		if c is ColorRect:
			var r := c as ColorRect  # The scrim.
			r.color.a = minf(r.color.a, MenuBackdropData.OVERLAY_SCRIM_ALPHA)
			return
