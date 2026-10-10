## RunConfig — everything chosen BEFORE a run starts (GDD §10.2 "Pre-Run
## Configuration"), handed from the menus (or the autotest) to Main and into
## Game (`Game.run_config`). Restart reuses the same config.
## Today it only holds the stage. PRE-RUN SETTINGS HOOK: the planned pre-run
## settings step (GDD §8.4 difficulty, §8.5 run modifiers, §10.2 skin) adds
## its choices as fields here, and the run reads them from
## `game.run_config` (difficulty and modifiers through DifficultyModifiers,
## the one difficulty path).
class_name RunConfig
extends RefCounted

## StageRegistry id of the stage to play.
var stage_id: String = StageRegistry.DEFAULT_ID


## A config for stage `id` (unknown ids fall back to the default stage).
static func for_stage(id: String) -> RunConfig:
	var c := RunConfig.new()
	c.stage_id = id if StageRegistry.STAGES.has(id) else StageRegistry.DEFAULT_ID
	return c


## The STAGE dictionary of the chosen stage (StageRegistry keys).
func stage_def() -> Dictionary:
	return StageRegistry.STAGES.get(stage_id, StageRegistry.STAGES[StageRegistry.DEFAULT_ID])


## A copy for a restart (a later pre-run settings step copies its fields too).
func duplicate_config() -> RunConfig:
	return RunConfig.for_stage(stage_id)
