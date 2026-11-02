## HerosFistData — immutable rule constants of the Hero's Fist spell, its
## evolution Doomsday, its paired passive Secret Identity and the Revenant
## Heroine's innate (Act VIII, Liberty Heights; GDD §15.0 "Hero's Fist,
## Doomsday, Secret Identity and the Revenant Heroine"; owner-approved
## proposal: "Hero's Fist: a spectral fist slams the strongest enemy and sends
## it flying through the rest -> Doomsday (+ Secret Identity)"; unlocked by
## defeating Paragon). Its per-level stat rows live in AbilityData.SPELLS and
## its evolution row in EvolutionData, like every spell; this file holds only
## the fixed rules the spell node (HerosFist) reads, the passive's id and keys
## and the innate key. Data only.
class_name HerosFistData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "heros_fist"
## Damage-source tag of the fist's slam (the base spell).
const SOURCE: String = "heros_fist"
## Damage-source tag of the flung foe striking the others on its way.
const FLING_SOURCE: String = "heros_fist_fling"
## Damage-source tag of the evolved fist's slam (Doomsday).
const EVOLVED_SOURCE: String = "doomsday"
## Damage-source tag of Doomsday's crater where the flung foe lands.
const CRATER_SOURCE: String = "doomsday_crater"
## Px from the necromancer within which the fist picks the strongest foe.
const AIM_RANGE: float = 300.0  # TUNING (not in GDD) about half the screen's height
## Seconds the fist takes to come down on its foe (drawn falling; the hit
## lands after it).
const FALL_TIME: float = 0.25  # TUNING (not in GDD)
## Seconds the struck foe flies.
const FLING_TIME: float = 0.35  # TUNING (not in GDD)
## Px each side of the flung foe's path within which the others are struck.
const FLING_WIDTH: float = 16.0  # TUNING (not in GDD)
## Knockback impulse (px/s, divided by mass) on a foe the flung one strikes,
## sideways off its path.
const FLING_SHOVE: float = 140.0  # TUNING (not in GDD)
## Px of the shockwave ring around a foe too heavy to fling (a boss, a
## miniboss, a structure, a vehicle): the others there take the fling share.
const UNMOVED_RADIUS: float = 48.0  # TUNING (not in GDD)
## Most fists at once (the evolution and the innate included).
const MAX_FISTS: int = 4  # TUNING (not in GDD)
## Px of a drawn fist's radius (visual only).
const FIST_SIZE: float = 9.0  # TUNING (not in GDD) visual only

# --- Secret Identity (the paired passive) ---
## Passive id of Secret Identity (PassiveData, UnlockData).
const SECRET_IDENTITY: String = "secret_identity"
## Its level-row key: share the fist's cooldown is shortened by
## (AbilityManager.apply_spell_mods(), on the spell rows' own keys).
const HASTE_KEY: String = "fist_haste"
## Its level-row key: added to the spell's fling_share (the flung foe strikes
## the others harder).
const FLING_KEY: String = "fist_fling"

# --- The Revenant Heroine's innate: Back From the Dead (HerosFist) ---
## Innate value key: extra fists a cast (CharacterData "revenant_heroine"; 0
## for every other character).
const EXTRA_KEY: String = "fist_extra_fists"
