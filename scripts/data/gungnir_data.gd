## GungnirData — the fixed rules of the GUNGNIR spell and its evolution SPEAR
## OF THE HANGED (Vigrid, the Hall of the Slain's finale, temporarily Act XI;
## GDD §15.0 "Gungnir, Spear of the Hanged, Runecraft and the Berserker";
## owner-approved proposal: "Gungnir: a spear thrown at the strongest enemy on
## screen that pierces everything in its line -> Spear of the Hanged (+
## Runecraft)"; unlocked by defeating Odin, UnlockData). The level numbers are
## AbilityData.SPELLS "gungnir" and EvolutionData "spear_of_the_hanged"; the
## logic is Gungnir. Data only (CLAUDE.md rule 2).
class_name GungnirData
extends RefCounted

## Spell id (AbilityData.SPELLS; never Odin's "odin_gungnir" damage tag).
const ID: String = "gungnir"
## Its evolution's id (EvolutionData).
const EVOLUTION_ID: String = "spear_of_the_hanged"
## Damage tag of the thrown spear.
const SOURCE: String = "gungnir"
## Damage tag of the evolved spear (its throw and its return).
const EVOLVED_SOURCE: String = "spear_of_the_hanged"
## Px from the necromancer within which the spear looks for the strongest foe
## ("on screen": about half the view's width).
const AIM_RANGE: float = 620.0  # TUNING (not in GDD)
## Most spears one cast throws (the evolution's `spears` plus the Berserker's
## innate), each at the next strongest foe.
const MAX_SPEARS: int = 4  # TUNING (not in GDD)
## Seconds a thrown spear's streak shows (drawing only).
const STREAK_TIME: float = 0.28  # TUNING (not in GDD) visual only
## Colour of the spear's soul-light (drawing only; the necromancer's soul-teal,
## never Odin's gold, so a player never mistakes his own spear for the god's).
const COLOR: Color = Color(0.62, 0.95, 0.86)  # TUNING (not in GDD) visual only

# --- Runecraft (the paired passive) ---
## Passive id of Runecraft (PassiveData, UnlockData).
const RUNECRAFT: String = "runecraft"
## Runecraft's level key: share (0..1) cut from Gungnir's cooldown.
const HASTE_KEY: String = "runecraft_haste"
## Runecraft's level key: + share of the spear's width (its line).
const WIDTH_KEY: String = "runecraft_width"

# --- The Berserker's innate: Bear-Shirt (Gungnir) ---
## CharacterData innate value key: spears more each cast.
const EXTRA_KEY: String = "gungnir_extra_spears"
