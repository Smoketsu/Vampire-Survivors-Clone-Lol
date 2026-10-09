## Main — entry scene script (scenes/main.tscn). Switches between the main
## menu and a run. A run is a fresh Game node every time, so Restart is
## simply "free the old Game, build a new one". In autotest mode the menu is
## skipped and a run starts immediately.
extends Node

## Current run (null while the menu is shown).
var _game: Game = null
## CanvasLayer holding the main menu (null while a run is active).
var _menu_layer: CanvasLayer = null


func _ready() -> void:
	if GameState.autotest:
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
	menu.play_pressed.connect(_start_game, CONNECT_DEFERRED)
	_menu_layer.add_child(menu)


## Frees whatever is shown and starts a new run.
func _start_game() -> void:
	_clear()
	_game = Game.new()
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
