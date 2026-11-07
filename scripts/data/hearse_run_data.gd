## HearseRunData — immutable rule constants of the Hearse Run spell, its
## evolution Funeral Procession, its paired passive Black Car, the Undertaker's
## innate and Act VIII's counter-passive Kevlar Bones (Act VIII, Skid Row; GDD
## §15.0 "Hearse Run, Funeral Procession, Black Car and the Undertaker (Act
## VIII)"; owner-approved proposal: "Hearse Run: a spectral hearse drives a lane
## through the enemies -> Funeral Procession (+ Black Car)"; unlocked by
## slaying Don Marrow). Its per-level stat rows live in AbilityData.SPELLS and
## its evolution row in EvolutionData, like every spell; this file holds only
## the fixed rules the spell node (HearseRun) reads and the passives' ids and
## keys. Data only.
class_name HearseRunData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "hearse_run"
## Damage-source tag of the base spell's hearses.
const SOURCE: String = "hearse_run"
## Damage-source tag of the evolved hearses (Funeral Procession).
const EVOLVED_SOURCE: String = "funeral_procession"
## Sprite key of the spectral hearse (assets/sprites/projectiles/; drawn
## faded, its nose to the right; SkidRowGlyphs.draw_hearse() without it).
const SPRITE: String = "projectiles/spectral_hearse"
## Most hearses on the road at once (the drawing and the cost stay flat).
const MAX_HEARSES: int = 12  # TUNING (not in GDD)
## Px between two lanes picked in one cast (a second hearse seeks another group).
const LANE_APART: float = 90.0  # TUNING (not in GDD)
## Most foes sampled as a lane's target (the cost stays flat).
const TARGET_SAMPLES: int = 18  # TUNING (not in GDD)
## Seconds a hearse fades in at its start and out at its end (drawn only).
const FADE_TIME: float = 0.2  # TUNING (not in GDD)
## px a struck foe is shoved off the hearse's line (knockback, not bosses).
const SHOVE: float = 160.0  # TUNING (not in GDD) px/s of knockback
## Half length and half width (px) of a hearse's body (the drawing; the hit
## band is the stat `width`).
const BODY := Vector2(26.0, 12.0)  # TUNING (not in GDD)
## Pallbearers (Funeral Procession): the summon class each risen pallbearer
## is (HordeDirector.spawn_temporary(), the one temporary-summon path).
const PALLBEARER_CLASS: String = "warrior"
## Seconds a pallbearer stands.
const PALLBEARER_TIME: float = 7.0  # TUNING (not in GDD)
## HP and damage multipliers of a pallbearer (x the class's effective stats).
const PALLBEARER_MULT: float = 0.6  # TUNING (not in GDD)

# --- Black Car (the paired passive) ---
## Passive id of Black Car (PassiveData, UnlockData).
const BLACK_CAR: String = "black_car"
## Its level-row key: share (0..1) of move speed a foe the hearse struck loses
## (CombatResolver.slow_enemy(), the one enemy slow path) ...
const BLACK_CAR_KEY: String = "hearse_slow"
## ... for this many seconds.
const BLACK_CAR_SLOW_TIME: float = 2.5  # TUNING (not in GDD)

# --- The Undertaker's innate: Last Ride (Hearse Run) ---
## Innate value key: extra hearses in every Hearse Run cast (CharacterData
## "undertaker"; 0 for every other character).
const EXTRA_HEARSES_KEY: String = "hearse_extra"

# --- Kevlar Bones (Act VIII's counter-passive, earned by No Witnesses) ---
## Passive id of Kevlar Bones (PassiveData; the foundation's hook
## Armour.kevlar_mult() reads its key).
const KEVLAR_BONES: String = CityRulesData.KEVLAR_BONES
