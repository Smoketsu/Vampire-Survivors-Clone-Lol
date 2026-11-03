## TractorLiftData — immutable rule constants of the Tractor Beam spell (id
## "tractor_lift": "tractor_beam" is a Concord sound and event id), its
## evolution Abduction (id "star_abduction": "abduction" is the Concord rule's
## source tag and class name; its display name stays "Abduction"), its paired
## passive Starseed and the Starborn's innate (Act IX, the Ark of the Concord;
## GDD §15.0 "Tractor Beam, Abduction, Starseed and the Starborn";
## owner-approved proposal: "Tractor Beam: lifts the strongest enemy into the
## air and slams it down -> Abduction (+ Starseed)"; unlocked by defeating the
## Harvester). Its per-level stat rows live in AbilityData.SPELLS and its
## evolution row in EvolutionData, like every spell; this file holds only the
## fixed rules the spell node (TractorLift) reads, the passive's id and keys
## and the innate key. Data only.
class_name TractorLiftData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "tractor_lift"
## Evolution id (EvolutionData; display name "Abduction").
const EVOLUTION_ID: String = "star_abduction"
## Damage-source tag of the slam (the base spell): the lifted foe and the
## foes round its landing.
const SOURCE: String = "tractor_lift"
## Damage-source tag of the evolved slam (Abduction).
const EVOLVED_SOURCE: String = "star_abduction"
## Damage-source tag of Abduction's quake: the foes it drags in round the slam.
const QUAKE_SOURCE: String = "star_abduction_quake"
## Px from the necromancer within which the beam picks the strongest foe.
const AIM_RANGE: float = 300.0  # TUNING (not in GDD) about half the screen's height
## Seconds before a slam in place lands on a foe too heavy to lift (a boss, a
## miniboss, a structure: brief "On them the spell slams in place").
const SLAM_IN_PLACE: float = 0.4  # TUNING (not in GDD)
## Px a lifted foe is drawn rising (visual only).
const LIFT_PX: float = 28.0  # TUNING (not in GDD) visual only
## Px half width of the lift column (visual only).
const COLUMN_HALF: float = 12.0  # TUNING (not in GDD) visual only
## Most foes lifted at once by one cast (the evolution and the innate included).
const MAX_LIFTS: int = 5  # TUNING (not in GDD)

# --- Starseed (the paired passive) ---
## Passive id of Starseed (PassiveData, UnlockData).
const STARSEED: String = "starseed"
## Its level-row key: share Tractor Beam's cooldown is shortened by
## (AbilityManager.apply_spell_mods(), on the spell rows' own keys).
const HASTE_KEY: String = "starseed_haste"
## Its level-row key: share the slam's radius grows by.
const REACH_KEY: String = "starseed_reach"

# --- The Starborn's innate: Deserter's Signal (TractorLift) ---
## Innate value key: extra foes lifted a cast (CharacterData "starborn"; 0 for
## every other character).
const EXTRA_KEY: String = "tractor_extra_lifts"
