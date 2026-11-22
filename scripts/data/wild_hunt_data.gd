## WildHuntData — immutable rule constants of the WILD HUNT spell, its evolution
## The Endless Hunt, its paired passive Horn of the Hunt and the Horned Herald's
## innate (temporary Act XV, the Greenwood; GDD §15.0 "Wild Hunt, The Endless
## Hunt, Horn of the Hunt and the Horned Herald"; owner-approved proposal
## "Rewards": "The Stag King | Wild Hunt: spectral riders sweep across the screen
## in a line -> The Endless Hunt (+ Horn of the Hunt) | The Horned Herald
## (male)"; unlocked by slaying the Stag King). Its per-level stat rows live in
## AbilityData.SPELLS and its evolution row in EvolutionData, like every spell;
## this file holds only the fixed rules the spell node (WildHunt) reads, the
## passive's id and keys and the innate key. Data only.
class_name WildHuntData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData). (The army synergy "The Wild Hunt"
## has the same id in SynergyData; the two never share a table or a stat.)
const ID: String = "wild_hunt"
## Evolution id (EvolutionData).
const EVOLUTION_ID: String = "the_endless_hunt"
## Damage-source tag of a rider (the base spell).
const SOURCE: String = "wild_hunt"
## Damage-source tag of an evolved rider (The Endless Hunt).
const EVOLVED_SOURCE: String = "the_endless_hunt"
## px behind the necromancer the line starts (it rides in from the screen's edge).
const BACK: float = 300.0  # TUNING (not in GDD)
## px between two riders abreast.
const RIDER_SPACING: float = 40.0  # TUNING (not in GDD)
## px round a candidate foe counted for the aim (the line rides where the foes are thickest).
const AIM_RADIUS: float = 90.0  # TUNING (not in GDD)
## Foes looked at as aim candidates (the first in the spatial hash's order).
const AIM_SAMPLES: int = 12  # TUNING (not in GDD)
## Knockback impulse (px/s, / the foe's mass) a rider gives every foe it crosses, along its ride.
const KNOCK: float = 180.0  # TUNING (not in GDD)
## Most lines riding at once (new ones are skipped beyond it).
const MAX_LINES: int = 6  # TUNING (not in GDD)
## Most riders in one line (the innate and the evolution included).
const MAX_RIDERS: int = 8  # TUNING (not in GDD)
## Pitch of the cast sound (a startup-bank sound: the spell plays on every stage).
const CAST_PITCH: float = 0.85  # TUNING (not in GDD)
## The riders' colours (the necromancer's soul-teal: spectral riders of his own
## hunt; never true gold). Visual only.
const SPIRIT := Color(0.45, 0.95, 0.85)  # TUNING (not in GDD) visual only
## The riders' antlered helms and spears. Visual only.
const CORE := Color(0.92, 0.98, 0.95)  # TUNING (not in GDD) visual only

# --- Horn of the Hunt (the paired passive) ---
## Passive id of Horn of the Hunt (PassiveData, UnlockData).
const HORN: String = "horn_of_the_hunt"
## Its level-row key: share more damage on every rider (0..1).
const DAMAGE_KEY: String = "horn_bonus"
## Its level-row key: px more reach round every rider.
const WIDTH_KEY: String = "width_bonus"

# --- The Horned Herald's innate: Call of the Horn (Wild Hunt) ---
## Innate value key: riders more in every line (CharacterData "horned_herald";
## 0 for every other character).
const INNATE_KEY: String = "wild_hunt_riders"
