## MainMenu — title screen with Play / Ossuary (Soul Ash upgrades, GDD §10.1
## "Upgrades") / Settings / Codex (achievements + compendium, CodexScreen,
## GDD §10.1 "Collection / Codex", "Achievements") / Credits (CreditsScreen) /
## Quit (asks first, ConfirmDialog). It shows the Soul
## Ash balance and a lifetime line (runs, best time, boss kills, achievements).
## Behind it lives the animated pixel-art graveyard diorama (MenuBackdrop,
## GDD §15.0 "Menu diorama"), the menu's first child. Every sub-screen opened
## over the menu (any other child added later: stage select, Ossuary,
## settings, ...) fades the menu's own content out (so no logo or button pokes
## out above the overlay), dims the diorama and lowers the overlay's own
## full-screen scrim so the graveyard stays visible around its panel; closing
## the last overlay restores both. The title is the
## pixel-art NECROPATHY logo (UiArtData.LOGO, drawn at UiArtData.LOGO_SCALE
## through the sharp-pixel shader); the plain label is the fallback when the
## PNG is missing.
## Text sizes come from the UiTheme type tiers; the old controls manual is
## gone (developer text): one InputHints strip at the bottom of the screen
## shows the select chip of the current device and bindings.
## Play opens the stage select (StageSelect, GDD §10.2), which opens the
## pre-run setup (PreRunSetup: difficulty and run modifiers); the finished
## RunConfig reaches Main through `stage_chosen`.
class_name MainMenu
extends Control

## Play pressed (the stage select opens).
signal play_pressed
## A stage was chosen in the stage select: Main starts a run with `config`.
signal stage_chosen(config: RunConfig)

## Play button (focused on open for keyboard / controller users).
var _play: Button
## Soul Ash balance line (refreshed whenever Meta changes).
var _ash_label: Label
## Lifetime statistics line under the balance.
var _lifetime_label: Label
## The animated diorama behind everything (first child). W2 hooks: its
## set_dim(), set_band() and set_mood() (MenuBackdrop header).
var _backdrop: MenuBackdrop
## The menu's own content (logo, Soul Ash, buttons, hints): faded out while an
## overlay is open. Its alpha only goes to 0 (it stays visible), so the
## overlays' close() can still return focus to a menu button.
var _content: Control
## Sub-screens currently open over the menu (direct children other than the
## backdrop and the content).
var _overlays: int = 0
## Running fade of the content's alpha (null when settled).
var _content_tween: Tween = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop = MenuBackdrop.new()
	add_child(_backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_content = center
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.custom_minimum_size = Vector2(420, 0)
	center.add_child(vb)
	vb.add_child(_title())
	var tagline := UiTheme.tier_label("Begin as the hunted. Raise the fallen. Become the army.", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tagline)
	var ash_row := HBoxContainer.new()
	ash_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ash_row.add_theme_constant_override("separation", 8)
	ash_row.add_child(IconGlyph.new("soul_ash", Vector2(30, 30)))
	_ash_label = UiTheme.tier_label("", UiTheme.Tier.NAME, MetaGlyphs.EMBER.lightened(0.2))
	ash_row.add_child(_ash_label)
	vb.add_child(ash_row)
	_lifetime_label = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_lifetime_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_lifetime_label)
	Meta.changed.connect(_refresh_meta)
	_refresh_meta()
	_play = Button.new()
	_play.text = "Play"  # One-word buttons (owner).
	_play.custom_minimum_size = Vector2(0, 52)
	_play.pressed.connect(_open_stage_select)
	vb.add_child(_play)
	var ossuary := Button.new()
	ossuary.text = "Ossuary"
	ossuary.custom_minimum_size = Vector2(0, 44)
	ossuary.pressed.connect(func() -> void: OssuaryMenu.open_over(self, ossuary))
	vb.add_child(ossuary)
	var settings := Button.new()
	settings.text = "Settings"
	settings.custom_minimum_size = Vector2(0, 44)
	settings.pressed.connect(func() -> void: SettingsMenu.open_over(self, settings))
	vb.add_child(settings)
	# W2-NewScreens: Codex (achievements + compendium) and Credits entries.
	var codex := Button.new()
	codex.text = "Codex"
	codex.custom_minimum_size = Vector2(0, 44)
	codex.pressed.connect(func() -> void: CodexScreen.open_over(self))
	vb.add_child(codex)
	var credits := Button.new()
	credits.text = "Credits"
	credits.custom_minimum_size = Vector2(0, 44)
	credits.pressed.connect(func() -> void: CreditsScreen.open_over(self))
	vb.add_child(credits)
	var quit := Button.new()
	quit.text = "Quit"
	quit.custom_minimum_size = Vector2(0, 44)
	# W2-NewScreens: Quit asks first (ConfirmDialog wraps the old handler).
	quit.pressed.connect(func() -> void: ConfirmDialog.ask(self, ConfirmData.QUIT[0], ConfirmData.QUIT[1], ConfirmData.QUIT[2], func() -> void: get_tree().quit()))
	vb.add_child(quit)
	# Release version from project.godot (application/config/version, bumped for each tagged release).
	var version_text: String = "v%s" % str(ProjectSettings.get_setting("application/config/version", "dev"))
	var version := UiTheme.tier_label(version_text, UiTheme.Tier.BODY, Color(UiTheme.TEXT_DIM, 0.6))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(version)
	add_child(InputHints.bottom_strip([["ui_accept", "Select"]]))  # Hint strip at the screen's bottom.
	_play.grab_focus.call_deferred()


## The title: the pixel-art logo when its PNG exists, else the plain label.
func _title() -> Control:
	if ResourceLoader.exists(UiArtData.LOGO):
		var tex := load(UiArtData.LOGO) as Texture2D  # The wordmark (art px).
		var logo := TextureRect.new()
		logo.texture = tex
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.custom_minimum_size = tex.get_size() * float(UiArtData.LOGO_SCALE)
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		SpriteBank.apply_sharp(logo)  # Crisp, even pixels at any window scale.
		return logo
	return UiTheme.title("Necropathy", Palette.NECRO_GREEN)


## Play: opens the stage select over the menu (focus returns to Play when
## it closes); its choice is forwarded to Main.
func _open_stage_select() -> void:
	play_pressed.emit()
	var sel := StageSelect.open_over(self, _play)
	sel.stage_chosen.connect(func(config: RunConfig) -> void: stage_chosen.emit(config))


## Updates the Soul Ash balance and the lifetime line.
func _refresh_meta() -> void:
	_ash_label.text = "%d Soul Ash" % Meta.soul_ash
	var lt: Dictionary = Meta.lifetime
	var best := int(float(lt.get("best_time", 0.0)))
	_lifetime_label.text = "Runs %d   |   Best %d:%02d   |   Bosses slain %d   |   Achievements %d/%d" % [
		int(float(lt.get("runs", 0.0))), floori(float(best) / 60.0), best % 60, int(float(lt.get("boss_kills", 0.0))),
		Meta.achievements.size(), MetaData.ACHIEVEMENT_ORDER.size()]


## A sub-screen was added over the menu: fade the content out, dim the
## diorama, and once the overlay is built lower its full-screen scrim.
func _on_child_entered(node: Node) -> void:
	if node == _backdrop or node == _content:
		return
	_overlays += 1
	if node is Control and not node.is_node_ready():
		node.ready.connect(_tame_scrim.bind(node as Control), CONNECT_ONE_SHOT)
	_set_overlay_look(true)


## A sub-screen is leaving: restore the menu once the last one has gone.
func _on_child_exiting(node: Node) -> void:
	if node == _backdrop or node == _content:
		return
	_overlays = maxi(0, _overlays - 1)
	if _overlays == 0:
		_set_overlay_look(false)


## Fades the menu content out (`covered`) or back in, and dims / undims the
## diorama, over MenuBackdropData.DIM_TIME real seconds.
func _set_overlay_look(covered: bool) -> void:
	_backdrop.set_dim(covered)
	if _content_tween != null:
		_content_tween.kill()
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
