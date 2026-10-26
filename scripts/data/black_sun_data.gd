## BlackSunData — immutable rule constants of the Black Sun spell, its
## evolution Eclipse of Heaven, its paired passive Stolen Dawn and the Shrine
## Maiden of Night's innate (Act V, the Road to the Sun; GDD §15.0 "Black Sun,
## Eclipse of Heaven, Stolen Dawn and the Shrine Maiden of Night";
## owner-approved proposal: "Black Sun: a dark sun orbits the necromancer and
## fires a short beam at the nearest group -> Eclipse of Heaven (+ Stolen
## Dawn)"; unlocked by defeating Amaterasu). Its per-level stat rows live in
## AbilityData.SPELLS and its evolution row in EvolutionData, like every spell;
## this file holds only the fixed rules the spell node (BlackSun) reads, the
## passive's id and keys. Data only.
class_name BlackSunData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "black_sun"
## Damage-source tag of the base spell's beams.
const SOURCE: String = "black_sun"
## Damage-source tag of the evolved beams (Eclipse of Heaven).
const EVOLVED_SOURCE: String = "eclipse_of_heaven"
## Damage-source tag of Eclipse of Heaven's corona burst at a beam's end.
const CORONA_SOURCE: String = "eclipse_corona"
## Px from the necromancer at which the dark sun(s) orbit.
const ORBIT_RADIUS: float = 34.0  # TUNING (not in GDD)
## Rad per s of the orbit (game time; several suns are spread evenly).
const ORBIT_SPEED: float = 1.6  # TUNING (not in GDD)
## Px from a dark sun within which it looks for the nearest foe.
const AIM_RANGE: float = 300.0  # TUNING (not in GDD)
## Px of Eclipse of Heaven's corona burst at a beam's end.
const CORONA_RADIUS: float = 44.0  # TUNING (not in GDD)
## Seconds a fired beam stays drawn (visual only; it struck at once).
const BEAM_SHOW: float = 0.22  # TUNING (not in GDD)
## Most foes the group centroid is averaged over (the cost stays flat).
const GROUP_MAX: int = 12  # TUNING (not in GDD)

# --- Stolen Dawn (the paired passive) ---
## Passive id of Stolen Dawn (PassiveData, UnlockData).
const STOLEN_DAWN: String = "stolen_dawn"
## Its level-row key: share Black Sun's cooldown is shortened by
## (AbilityManager.apply_spell_mods(), on the Black Sun rows' own keys).
const HASTE_KEY: String = "beam_haste"
## Its level-row key: HP healed per volley of beams that strikes a foe (the
## spell's effective stat "beam_heal", read by BlackSun).
const HEAL_KEY: String = "beam_heal"

# --- The Shrine Maiden of Night's innate: Night Prayer (BlackSun) ---
## Innate value key: share of a beam's damage its second beam deals at another
## group (CharacterData "shrine_maiden"; 0 for every other character).
const FORK_KEY: String = "black_sun_fork"
