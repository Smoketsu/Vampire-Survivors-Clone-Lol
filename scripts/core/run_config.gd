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
## The playable character (CharacterData id, chosen on the same screen's
## CharacterPicker, remembered in the Meta save) is `character_id`; the run
## reads it only through CharacterModifiers (the one character path), and
## everything else (skins, Hyper clears) through character_key().
## The ultimate (UltimateData id, content wave 2) is `ultimate_id`, chosen on
## the same screen under the character and skin; the run reads it only through
## UltimateSystem (game.ultimates).
class_name RunConfig
extends RefCounted

## StageRegistry id of the stage to play.
var stage_id: String = StageRegistry.DEFAULT_ID
## DifficultyData id of the difficulty level (default: Necromancer, today's game).
var difficulty_id: String = DifficultyData.DEFAULT_ID
## RunModifierData ids of the active run modifiers, in RunModifierData.ORDER
## (empty = none; set through set_modifiers(), which validates and sorts).
var modifiers: PackedStringArray = PackedStringArray()
## CharacterData id of the playable character (default: the Gravecaller,
## today's necromancer; set through set_character(), which validates).
var character_id: String = CharacterData.DEFAULT_ID
## True when Hyper mode is on (HyperData; the setup screen only offers it once
## unlocked, the autotest's --hyper bypasses the lock).
var hyper: bool = false
## SkinData id of the cosmetic skin ("" = the character's default look).
## Purely visual: Game hands it to the Necromancer's drawing only.
var skin_id: String = ""
## UltimateData id of the ultimate the soul meter casts (default: Dread Rally;
## set through set_ultimate(), which validates; locks are checked by the
## picker, Meta.prerun_config() and Game, --ultimate= bypasses them).
var ultimate_id: String = UltimateData.DEFAULT_ID


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


## Sets the playable character: an unknown id, or one whose starting spell is
## not in this build, falls back to the default. Locks are not checked here
## (the picker and Meta.prerun_config() do; --character= bypasses them).
func set_character(id: String) -> void:
	character_id = id if CharacterModifiers.is_available(id) else CharacterData.DEFAULT_ID


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


## Sets the ultimate (unknown ids fall back to Dread Rally).
func set_ultimate(id: String) -> void:
	ultimate_id = id if UltimateData.ULTIMATES.has(id) else UltimateData.DEFAULT_ID


## The run's character id (`character_id`, a CharacterData id; the one
## accessor skins and Hyper clears use).
func character_key() -> String:
	return character_id


## A copy for a restart: the same stage, difficulty, modifiers, character,
## Hyper, skin and ultimate.
func duplicate_config() -> RunConfig:
	var c := RunConfig.for_stage(stage_id)
	c.set_difficulty(difficulty_id)
	c.set_modifiers(modifiers)
	c.set_character(character_id)
	c.hyper = hyper
	c.skin_id = skin_id
	c.set_ultimate(ultimate_id)
	return c
