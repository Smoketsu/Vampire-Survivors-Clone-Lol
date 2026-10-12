## Main — entry scene script (scenes/main.tscn). Switches between the main
## menu and a run. A run is a fresh Game node every time, so Restart is
## simply "free the old Game, build a new one" with the same RunConfig.
## Play opens the stage select (StageSelect) over the menu; choosing a stage
## opens the pre-run setup (PreRunSetup: difficulty level and run
## modifiers), which yields the RunConfig the run is built with. In autotest
## mode the menu is skipped and a run starts immediately on the --stage=
## stage (locks ignored) with --difficulty=, --modifiers=, --character= and
## --hyper (its unlock bypassed).
extends Node

## Current run (null while the menu is shown).
var _game: Game = null
## CanvasLayer holding the main menu (null while a run is active).
var _menu_layer: CanvasLayer = null
## Pre-run choices of the current / last run (reused by Restart).
var _run_config: RunConfig = null


func _ready() -> void:
	if GameState.autotest:
		_run_config = RunConfig.for_stage(GameState.autotest_stage)
		_run_config.set_difficulty(GameState.autotest_difficulty)
		_run_config.set_modifiers(GameState.autotest_modifiers)
		_run_config.set_character(GameState.autotest_character)
		_run_config.hyper = GameState.autotest_hyper
		_start_game()
	else:
		_show_menu()


## Frees whatever is shown and displays the main menu.
func _show_menu() -> void:
	_clear()
	_menu_layer = CanvasLayer.new()
	add_child(_menu_layer)
	var menu := MainMenu.new()
	menu.theme = UiTheme.get_theme()
	menu.stage_chosen.connect(_on_stage_chosen, CONNECT_DEFERRED)
	_menu_layer.add_child(menu)


## The stage select and pre-run setup confirmed a config: start a run with it.
func _on_stage_chosen(config: RunConfig) -> void:
	_run_config = config
	GameState.last_stage_id = config.stage_id
	_start_game()


## Frees whatever is shown and starts a new run with `_run_config`.
func _start_game() -> void:
	_clear()
	_game = Game.new()
	_game.run_config = _run_config.duplicate_config() if _run_config != null else RunConfig.new()
	_game.restart_requested.connect(_start_game, CONNECT_DEFERRED)
	_game.main_menu_requested.connect(_show_menu, CONNECT_DEFERRED)
	add_child(_game)


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
