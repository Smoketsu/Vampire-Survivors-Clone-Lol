## HyperData — designer-tunable data for HYPER MODE (owner-approved; not in the
## GDD, so every number here is TUNING). Hyper is an opt-in toggle on the
## pre-run setup screen, next to the difficulty level and the run modifiers,
## that stacks on top of whichever level is chosen:
##   * the GROWTH part of the enemy HP and damage time scaling is multiplied
##     by GROWTH_MULT on top of the level's own hp_scaling / damage_scaling
##     (WaveData: HP x (1 + hp_scaling * GROWTH_MULT * (0.10 m + 0.013 m^2)));
##     the Reckoning is built from the same time scaling, so it grows too,
##   * the stage boss's HP is multiplied by BOSS_HP_MULT,
##   * Soul Ash: its own end-screen line worth ASH_BONUS x the run subtotal.
## It is unlocked the first time UNLOCK_BOSS_ID (Grand Inquisitor Seraphine,
## the Sanctum's boss) is slain on any difficulty, and a Hyper CLEAR (the run
## reached the Reckoning, i.e. a victory, with Hyper on) earns the stage a gold
## badge, recorded per stage and per character (Meta [hyper_clears]).
## No logic here: DifficultyModifiers (the one difficulty path) reads it.
class_name HyperData
extends RefCounted

## Multiplier on the growth part of the enemy HP and damage time scaling,
## applied on top of the difficulty level's hp_scaling / damage_scaling
## (Necromancer 20:00: HP x8.2 -> x15.4, damage x3.6 -> x6.2).
const GROWTH_MULT: float = 2.0  # TUNING (not in GDD) owner: "doubles the growth"
## Multiplier on the stage boss's HP, on top of the level's boss_hp.
const BOSS_HP_MULT: float = 1.5  # TUNING (not in GDD) owner-approved
## Soul Ash reward: an extra end-screen line worth this fraction of the run
## subtotal (1.0 = +100%, i.e. "Soul Ash x2").
const ASH_BONUS: float = 1.0  # TUNING (not in GDD) owner-approved
## Boss id (StageRegistry.BOSS_ARRIVALS) whose first defeat unlocks Hyper.
const UNLOCK_BOSS_ID: String = "seraphine"  # TUNING (not in GDD) owner-approved
## Stage whose Hyper clear unlocks each character's Hyper skin (SkinData).
const SKIN_STAGE_ID: String = "sanctum"  # TUNING (not in GDD) owner-approved

## UI name of the mode (setup screen, HUD "Difficulty: Lich + Hyper", end screen).
const DISPLAY_NAME: String = "Hyper"
## Setup-screen line under the toggle.
const TAGLINE: String = "Foes grow twice as fast, the boss has +50% HP. Soul Ash x2."
## Lock text shown on the toggle until it is unlocked.
const LOCK_TEXT: String = "Defeat Grand Inquisitor Seraphine (any difficulty) to unlock"
## End-screen banner the run that unlocks it shows.
const UNLOCK_BANNER: String = "HYPER MODE UNLOCKED"
