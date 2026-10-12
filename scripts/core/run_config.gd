## RunConfig — everything chosen BEFORE a run starts (GDD §10.2 "Pre-Run
## Configuration"), handed from the menus (or the autotest) to Main and into
## Game (`Game.run_config`). Restart reuses the same config.
## It holds the stage (StageSelect), the difficulty level (GDD §8.4) and the
## optional run modifiers (GDD §8.5), both chosen on the pre-run setup
## screen (PreRunSetup) and remembered in the Meta save. The run reads the
## difficulty and modifiers only through DifficultyModifiers (the one
## difficulty path). Hyper mode (HyperData, an opt-in toggle stacking on the
## level, also read only through DifficultyModifiers) and the cosmetic skin
## (SkinData; never a stat) are chosen on the same screen.
class_name RunConfig
extends RefCounted

## StageRegistry id of the stage to play.
var stage_id: String = StageRegistry.DEFAULT_ID
## DifficultyData id of the difficulty level (default: Necromancer, today's game).
var difficulty_id: String = DifficultyData.DEFAULT_ID
## RunModifierData ids of the active run modifiers, in RunModifierData.ORDER
## (empty = none; set through set_modifiers(), which validates and sorts).
var modifiers: PackedStringArray = PackedStringArray()
## True when Hyper mode is on (HyperData; the setup screen only offers it once
## unlocked, the autotest's --hyper bypasses the lock).
var hyper: bool = false
## SkinData id of the cosmetic skin ("" = the character's default look).
## Purely visual: Game hands it to the Necromancer's drawing only.
var skin_id: String = ""


## A config for stage `id` (unknown ids fall back to the default stage),
## at the standard difficulty with no run modifiers.
static func for_stage(id: String) -> RunConfig:
	var c := RunConfig.new()
	c.stage_id = id if StageRegistry.STAGES.has(id) else StageRegistry.DEFAULT_ID
	return c


## The STAGE dictionary of the chosen stage (StageRegistry keys).
func stage_def() -> Dictionary:
	return StageRegistry.STAGES.get(stage_id, StageRegistry.STAGES[StageRegistry.DEFAULT_ID])


## Sets the difficulty level (unknown ids fall back to the default).
func set_difficulty(id: String) -> void:
	difficulty_id = id if DifficultyData.LEVELS.has(id) else DifficultyData.DEFAULT_ID


## Sets the active run modifiers: unknown ids and duplicates are dropped and
## the rest kept in RunModifierData.ORDER (so the same choice always gives
## the same config, summary and HUD text).
func set_modifiers(ids: PackedStringArray) -> void:
	modifiers = PackedStringArray()
	for id: String in RunModifierData.ORDER:
		if ids.has(id):
			modifiers.append(id)


## True when run modifier `id` is active.
func has_modifier(id: String) -> bool:
	return modifiers.has(id)


## The run's character id: `character_id` when the character system
## (CharacterData) has added that field, else SkinData.DEFAULT_CHARACTER
## (the Gravecaller, today's necromancer). Read dynamically so skins and
## Hyper clears work with or without characters.
func character_key() -> String:
	var v: Variant = get(&"character_id")  # null while no such field exists.
	return SkinData.character_or_default(String(v)) if typeof(v) == TYPE_STRING else SkinData.DEFAULT_CHARACTER


## A copy for a restart: the same stage, difficulty, modifiers, Hyper and skin.
func duplicate_config() -> RunConfig:
	var c := RunConfig.for_stage(stage_id)
	c.set_difficulty(difficulty_id)
	c.set_modifiers(modifiers)
	c.hyper = hyper
	c.skin_id = skin_id
	return c
