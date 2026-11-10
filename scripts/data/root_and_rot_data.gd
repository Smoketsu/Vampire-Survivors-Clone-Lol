## RootAndRotData — immutable rule constants of the Root and Rot spell, its
## evolution Return to Earth, its paired passive Compost Heart and the
## Gravegardener's innate (temporary Act XV, the World-Tree; GDD §15.0 "Root and
## Rot, Return to Earth, Compost Heart and the Gravegardener"; owner-approved
## proposal "Rewards": "The Green Mother | Root and Rot: a ring of roots grows at
## the strongest enemy and rots everything inside -> Return to Earth (+ Compost
## Heart) | The Gravegardener (female, figure style)"; unlocked by slaying the
## Green Mother). Its per-level stat rows live in AbilityData.SPELLS and its
## evolution row in EvolutionData, like every spell; this file holds only the
## fixed rules the spell node (RootAndRot) reads, the passive's id and keys and
## the innate key. Data only.
class_name RootAndRotData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "root_and_rot"
## Evolution id (EvolutionData).
const EVOLUTION_ID: String = "return_to_earth"
## Damage-source tag of a ring's roots (the base spell).
const SOURCE: String = "root_and_rot"
## Damage-source tag of an evolved ring's roots (Return to Earth).
const EVOLVED_SOURCE: String = "return_to_earth"
## Seconds between two ticks of a ring (its rot, its root slow, the evolved bite).
const TICK: float = 0.5  # TUNING (not in GDD)
## Foes looked at as aim candidates (the first in the spatial hash's order).
const AIM_SAMPLES: int = 16  # TUNING (not in GDD)
## Most rings standing at once (new ones are skipped beyond it).
const MAX_RINGS: int = 6  # TUNING (not in GDD)
## px two rings of one cast must lie apart (Return to Earth picks distinct foes).
const SPACING: float = 100.0  # TUNING (not in GDD)
## Pitch of the cast sound (a startup-bank sound: the spell plays on every stage).
const CAST_PITCH: float = 0.75  # TUNING (not in GDD)
## Roots drawn round a ring (drawing only).
const ROOTS_DRAWN: int = 10  # TUNING (not in GDD) visual only
## The ring's colours: the necromancer's soul-teal life in dead roots (never
## true gold, never the Wild's living green). Visual only.
const ROOT := Color(0.42, 0.34, 0.26)  # TUNING (not in GDD) visual only
## The rot's soul-teal glow. Visual only.
const ROT := Color(0.45, 0.95, 0.85)  # TUNING (not in GDD) visual only

# --- Compost Heart (the paired passive) ---
## Passive id of Compost Heart (PassiveData, UnlockData).
const COMPOST_HEART: String = "compost_heart"
## Its level-row key: + rot amplification of every ring (0..1, added to the spell's `rot`).
const ROT_KEY: String = "compost_rot"
## Its level-row key: s more every ring stands.
const TIME_KEY: String = "compost_time"

# --- The Gravegardener's innate: Green Thumb (Root and Rot) ---
## Innate value key: share more radius of every ring (CharacterData
## "gravegardener"; 0 for every other character).
const INNATE_KEY: String = "root_and_rot_radius_bonus"
