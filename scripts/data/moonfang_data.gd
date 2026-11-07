## MoonfangData — immutable rule constants of the Moonfang spell, its evolution
## Wolf of the Red Moon, its paired passive Pack Blood, the Moon-Cursed
## Huntress's innate and Act VII's counter-passive Silver Bones (Act VII,
## Ravensmoor; GDD §15.0 "Moonfang, Wolf of the Red Moon, Pack Blood and the
## Moon-Cursed Huntress (Act VII)"; owner-approved proposal: "Moonfang:
## spectral wolf jaws snap at the nearest group and leave bleeds -> Wolf of the
## Red Moon (+ Pack Blood)"; unlocked by slaying Vargr). Its per-level stat rows
## live in AbilityData.SPELLS and its evolution row in EvolutionData, like every
## spell; this file holds only the fixed rules the spell node (Moonfang) reads
## and the passives' ids and keys. Data only.
class_name MoonfangData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "moonfang"
## Damage-source tag of the base spell's jaws.
const SOURCE: String = "moonfang"
## Damage-source tag of the evolved jaws (Wolf of the Red Moon).
const EVOLVED_SOURCE: String = "wolf_of_the_red_moon"
## Damage-source tag of the bleeds the jaws leave (both forms).
const BLEED_SOURCE: String = "moonfang_bleed"
## Seconds the spectral jaws take to close (the snap shows, then lands).
const SNAP_TIME: float = 0.22  # TUNING (not in GDD)
## Seconds between two ticks of the bleeds.
const BLEED_TICK: float = 0.5  # TUNING (not in GDD)
## Most foes bleeding at once (a new bleed past it is dropped).
const MAX_BLEEDS: int = 160  # TUNING (not in GDD)
## Most foes sampled as the centre of a group (the cost stays flat).
const GROUP_SAMPLES: int = 18  # TUNING (not in GDD)
## Px between two jaws' targets of one cast (a second jaw seeks another group;
## with fewer groups than jaws the rest snap again at the nearest).
const GROUP_APART: float = 60.0  # TUNING (not in GDD)
## Seconds the drawn jaws stay after they snap (drawn only).
const FADE_TIME: float = 0.25  # TUNING (not in GDD)

# --- Pack Blood (the paired passive) ---
## Passive id of Pack Blood (PassiveData, UnlockData).
const PACK_BLOOD: String = "pack_blood"
## Its level-row key: share more damage a BLEEDING foe takes from every hit
## (CombatResolver.damage_enemy(), Moonfang.bleeding()).
const PACK_KEY: String = "bleed_vulnerability"

# --- The Moon-Cursed Huntress's innate: Hunter's Moon (Moonfang) ---
## Innate value key: extra jaws in every Moonfang cast (CharacterData
## "moon_huntress"; 0 for every other character).
const EXTRA_JAWS_KEY: String = "moonfang_extra_jaws"

# --- Silver Bones (Act VII's counter-passive, earned by Coffin Nails) ---
## Passive id of Silver Bones (PassiveData; the foundation's hooks
## CourtRules.silver_bones_mult() / silver_mist_mult() read its two keys).
const SILVER_BONES: String = CourtRulesData.SILVER_BONES
