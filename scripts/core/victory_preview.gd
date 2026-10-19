## VictoryPreview — the --victory-preview debug run (content wave 2, GDD §15.0
## "Victory screen (content wave 2)"): a way to see the last stand and the victory
## results card at once instead of after a 20-minute run (screenshots, layout
## checks). Game calls setup() at the start of such a run (a small army, from
## VictoryData.PREVIEW_CLASSES) and fire() once VictoryData.PREVIEW_DELAY game
## seconds have passed: the clock jumps past 0:00, the stage boss counts as slain,
## a few evolutions and chests are listed, and the necromancer falls through the
## normal death path (Necromancer.died -> Game._on_player_died() -> end_run()),
## so the victory flow is the real one. Debug only: never active unless the
## flag is given, and Meta.can_write() keeps the scripted run out of the save.
class_name VictoryPreview
extends RefCounted


## Raises the preview army at the start of the run.
static func setup(game: Game) -> void:
	for cls: String in VictoryData.PREVIEW_CLASSES:
		game.horde.set_class_level(cls, int(VictoryData.PREVIEW_CLASSES[cls]))


## Ends the run as a scripted victory (see the header). Does nothing once the
## run has ended.
static func fire(game: Game) -> void:
	if game.run_state != Game.RunState.PLAYING:
		return
	game.elapsed = WaveData.RUN_DURATION + VictoryData.PREVIEW_OVERTIME
	game.boss_defeated = true
	game.boss_kill_time = VictoryData.PREVIEW_BOSS_TIME
	for e: Array in VictoryData.PREVIEW_EVOLUTIONS:
		game.abilities.evolution_history.append("%s@%s" % [String(e[0]), String(e[1])])
	game.stats["chests_opened"] = float(VictoryData.PREVIEW_CHESTS)
	game.player.invulnerable = false
	game.player.hp = 0.0
	game.player.dead = true
	game.player.died.emit()
