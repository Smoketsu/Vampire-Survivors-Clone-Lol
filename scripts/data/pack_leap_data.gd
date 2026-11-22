## PackLeapData — immutable rule constants of the Pack Leap spell, its evolution
## Apex Pack, its paired passive Pack Instinct and the Fern Huntress's innate
## (temporary Act XIV, the Fern Basin; GDD §15.0 "Pack Leap, Apex Pack, Pack
## Instinct and the Fern Huntress"; owner-approved proposal "Rewards": "Scarmaw
## | Pack Leap: three spectral raptors leap at marked enemies -> Apex Pack (+
## Pack Instinct) | The Fern Huntress (female, figure style)"; unlocked by
## slaying Scarmaw). Its per-level stat rows live in AbilityData.SPELLS and its
## evolution row in EvolutionData, like every spell; this file holds only the
## fixed rules the spell node (PackLeap) reads, the passive's id and keys and
## the innate key. Data only.
class_name PackLeapData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "pack_leap"
## Evolution id (EvolutionData).
const EVOLUTION_ID: String = "apex_pack"
## Damage-source tag of a leap (the base spell).
const SOURCE: String = "pack_leap"
## Damage-source tag of an evolved leap and its second leap (Apex Pack).
const EVOLVED_SOURCE: String = "apex_pack"
## Seconds between the marks showing and the raptors landing.
const MARK_TIME: float = 0.35  # TUNING (not in GDD) owner-approved proposal: "leap at marked enemies"
## Seconds a second leap (Apex Pack) lands after the first.
const CHAIN_DELAY: float = 0.25  # TUNING (not in GDD)
## Most raptors in flight at once (new ones are skipped beyond it).
const MAX_LEAPS: int = 24  # TUNING (not in GDD)
## Pitch of the cast sound (a startup-bank sound: the spell plays on every stage).
const LEAP_PITCH: float = 1.25  # TUNING (not in GDD)
## The raptors' colours (the necromancer's soul-teal with a bone-white core:
## never true gold). Visual only.
const SPIRIT := Color(0.45, 0.95, 0.85)  # TUNING (not in GDD) visual only
## The raptors' core. Visual only.
const CORE := Color(0.92, 0.98, 0.95)  # TUNING (not in GDD) visual only

# --- Pack Instinct (the paired passive) ---
## Passive id of Pack Instinct (PassiveData, UnlockData).
const PACK_INSTINCT: String = "pack_instinct"
## Its level-row key: share more damage on every leap (0..1).
const DAMAGE_KEY: String = "instinct_bonus"
## Its level-row key: px more pounce on every leap.
const POUNCE_KEY: String = "pounce_bonus"

# --- The Fern Huntress's innate: Hunter's Mark (PackLeap) ---
## Innate value key: raptors more on every cast (CharacterData
## "fern_huntress"; 0 for every other character).
const INNATE_KEY: String = "pack_leap_raptors"
