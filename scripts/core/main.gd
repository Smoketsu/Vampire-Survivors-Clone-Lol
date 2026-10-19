## Main — entry scene script (scenes/main.tscn). Switches between the main
## menu and a run. A run is a fresh Game node every time, so Restart is
## simply "free the old Game, build a new one" with the same RunConfig.
## Play opens the stage select (StageSelect) over the menu; choosing a stage
## opens the pre-run setup (PreRunSetup: difficulty level and run
## modifiers), which yields the RunConfig the run is built with. In autotest
## mode the menu is skipped and a run starts immediately on the --stage=
## stage (locks ignored) with --difficulty=, --modifiers=, --character= and
## --hyper (its unlock bypassed).
## Switching between the menu and a run (and Restart) fades through black
## (UiMotion.transition; instant under the autotest and with Reduce motion).
## Main also installs the UI motion hook (UiMotion.install: card lift and
## button squash) once at startup.
## Phones and tablets (GDD §15.0 "Mobile browser support"): Main installs
## TouchSupport (touch input hints, the mobile UI scale, the portrait
## overlay) and pauses a running game when the device turns to portrait.
## Victory card (content wave 2): its Next button asks for the next stage with
## the same pre-run choices (Game.next_stage_requested -> _start_next_stage()).
## A --victory-preview debug run skips the menu like the autotest.
## Music: the menu asks Sfx for the main menu theme, a run for the in-run
## loop (Sfx.play_music crossfades them; the menu-to-run fade starts with the
## fade through black).
extends Node

## Current run (null while the menu is shown).
var _game: Game = null
## CanvasLayer holding the main menu (null while a run is active).
var _menu_layer: CanvasLayer = null
## Pre-run choices of the current / last run (reused by Restart).
var _run_config: RunConfig = null


func _ready() -> void:
	UiMotion.install()
	var touch := TouchSupport.install(self)  # Phones / tablets: touch hints, UI scale, portrait overlay (null in the autotest).
	if touch != null:
		touch.portrait_changed.connect(_on_portrait_changed)
	if GameState.autotest or GameState.victory_preview:
		_run_config = RunConfig.for_stage(GameState.autotest_stage)
		_run_config.set_difficulty(GameState.autotest_difficulty)
		_run_config.set_modifiers(GameState.autotest_modifiers)
		_run_config.set_character(GameState.autotest_character)
		_run_config.hyper = GameState.autotest_hyper
		_run_config.set_ultimate(GameState.autotest_ultimate)  # --ultimate= (lock bypassed).
		_start_game()
	else:
		_show_menu()


## Frees whatever is shown and displays the main menu.
func _show_menu() -> void:
	var after_run := _game != null  # Back from a run (not the startup menu).
	_clear()
	Sfx.play_music(Sfx.MUSIC_MENU)
	_menu_layer = CanvasLayer.new()
	add_child(_menu_layer)
	var menu := MainMenu.new()
	menu.theme = UiTheme.get_theme()
	menu.stage_chosen.connect(_on_stage_chosen, CONNECT_DEFERRED)
	_menu_layer.add_child(menu)
	# Content wave 2 (illustrated epilogue): back from a run, an epilogue part
	# the run opened (and the player has not seen) plays once over the menu;
	# `--epilogue[=all]` opens it at startup (debug, screenshots).
	var debug := EpilogueScreen.debug_request()  # "" = none.
	if debug != "":
		EpilogueScreen.open_debug(menu, debug == EpilogueScreen.DEBUG_ALL)
	elif after_run:
		EpilogueScreen.play_unseen(menu)


## The stage select and pre-run setup confirmed a config: start a run with it.
func _on_stage_chosen(config: RunConfig) -> void:
	_run_config = config
	GameState.last_stage_id = config.stage_id
	Sfx.play_music(Sfx.run_mode_for(config.stage_id))
	UiMotion.transition(self, _start_game)


## Frees whatever is shown and starts a new run with `_run_config`.
func _start_game() -> void:
	_clear()
	Sfx.play_music(Sfx.run_mode_for(_run_config.stage_id if _run_config != null else StageRegistry.DEFAULT_ID))
	_game = Game.new()
	_game.run_config = _run_config.duplicate_config() if _run_config != null else RunConfig.new()
	_game.restart_requested.connect(UiMotion.transition.bind(self, _start_game), CONNECT_DEFERRED)
	_game.main_menu_requested.connect(UiMotion.transition.bind(self, _show_menu), CONNECT_DEFERRED)
	_game.next_stage_requested.connect(_start_next_stage, CONNECT_DEFERRED)  # Victory card: Next.
	add_child(_game)


## The victory card's Next: the same pre-run choices (difficulty, modifiers,
## character, Hyper, skin and anything else RunConfig.duplicate_config() keeps)
## on stage `stage_id`, through the usual fade.
func _start_next_stage(stage_id: String) -> void:
	var c := _run_config.duplicate_config() if _run_config != null else RunConfig.new()
	c.stage_id = stage_id if StageRegistry.STAGES.has(stage_id) else c.stage_id
	_run_config = c
	GameState.last_stage_id = c.stage_id
	UiMotion.transition(self, _start_game)


## A phone or tablet turned to portrait: a running game pauses (its pause
## menu waits under the "turn your device" overlay).
func _on_portrait_changed(portrait: bool) -> void:
	if portrait and _game != null and _game.run_state == Game.RunState.PLAYING:
		_game.toggle_pause()


## Unpauses and removes the current run / menu.
func _clear() -> void:
	get_tree().paused = false
	if _game != null:
		remove_child(_game)
		_game.queue_free()
		_game = null
	if _menu_layer != null:
		remove_child(_menu_layer)
		_menu_layer.queue_free()
		_menu_layer = null
