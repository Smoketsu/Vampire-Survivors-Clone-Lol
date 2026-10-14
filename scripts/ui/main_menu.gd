## MainMenu — title screen with Play / Ossuary (Soul Ash upgrades, GDD §10.1
## "Upgrades") / Settings / Codex (achievements + compendium, CodexScreen,
## GDD §10.1 "Collection / Codex", "Achievements") / Credits (CreditsScreen) /
## Quit (asks first, ConfirmDialog). It shows the Soul
## Ash balance and a lifetime line (runs, best time, boss kills, achievements).
## The candle-lit crypt backdrop is drawn in _draw(). The title is the
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


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
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


func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.03, 0.02, 0.05))
	# Moon and its glow.
	var moon := Vector2(s.x * 0.8, s.y * 0.2)
	draw_circle(moon, 90.0, Color(0.6, 0.75, 0.8, 0.05))
	draw_circle(moon, 48.0, Color(0.82, 0.86, 0.85, 0.85))
	# Rolling graveyard ground.
	var ground := PackedVector2Array([Vector2(0, s.y), Vector2(0, s.y * 0.78)])
	for i in 9:
		var x := s.x * float(i) / 8.0
		ground.append(Vector2(x, s.y * (0.76 + 0.03 * sin(float(i) * 1.7))))
	ground.append(Vector2(s.x, s.y))
	draw_colored_polygon(ground, Color(0.06, 0.07, 0.08))
	# Tombstone silhouettes with faint necrotic glows.
	for i in 12:
		var x := s.x * (0.04 + 0.08 * float(i))
		var y := s.y * (0.80 + 0.02 * sin(float(i) * 2.3))
		var hgt := 26.0 + 10.0 * absf(sin(float(i) * 1.3))
		draw_circle(Vector2(x, y + 4), 22.0, Color(Palette.NECRO_GREEN, 0.04))
		draw_rect(Rect2(Vector2(x - 9, y - hgt), Vector2(18, hgt)), Color(0.12, 0.13, 0.15))
		draw_circle(Vector2(x, y - hgt), 9.0, Color(0.12, 0.13, 0.15))
	# Red Covenant torches on the horizon (GDD §11: red torches advance).
	for i in 5:
		var tp := Vector2(s.x * (0.15 + 0.17 * float(i)), s.y * 0.74)
		draw_circle(tp, 10.0, Color(Palette.FLAME, 0.12))
		draw_circle(tp, 3.0, Palette.FLAME)
