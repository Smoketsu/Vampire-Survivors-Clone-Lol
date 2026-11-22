## FlamingSwordData — immutable rule constants of the Flaming Sword spell, its
## evolution Sword at the Gate, its paired passive Fallen Light and the Fallen
## Herald's innate (temporary Act XIII, the Silver Stair; GDD §15.0 "Flaming
## Sword, Sword at the Gate, Fallen Light and the Fallen Herald"; owner-approved
## proposal "Rewards": "Flaming Sword: a spectral sword sweeps a wide arc in
## front of the necromancer -> Sword at the Gate (+ Fallen Light) | The Fallen
## Herald (male)"; unlocked by slaying Seraiel). Its per-level stat rows live in
## AbilityData.SPELLS and its evolution row in EvolutionData, like every spell;
## this file holds only the fixed rules the spell node (FlamingSword) reads, the
## passive's id and keys and the innate key. Data only.
class_name FlamingSwordData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "flaming_sword"
## Evolution id (EvolutionData).
const EVOLUTION_ID: String = "sword_at_the_gate"
## Damage-source tag of a sweep (the base spell; also its Grace kind).
const SOURCE: String = "flaming_sword"
## Damage-source tag of an evolved sweep and its echo (Sword at the Gate).
const EVOLVED_SOURCE: String = "sword_at_the_gate"
## Seconds the drawn blade takes to cross its arc (visual only: the hit lands
## on the cast, every foe in the sector at once).
const SWEEP_SHOW: float = 0.2  # TUNING (not in GDD) visual only
## Px beyond the sword's reach a foe may stand for a cast to start (aim slack).
const AIM_SLACK: float = 30.0  # TUNING (not in GDD)
## Px under which a foe's angular width is measured as at this distance (a foe
## on top of the necromancer is always in the arc).
const MIN_HIT_DIST: float = 6.0  # TUNING (not in GDD)
## Sweep pitch of the cast sound (a startup-bank sound: the spell plays on
## every stage).
const SWEEP_PITCH: float = 0.8  # TUNING (not in GDD)
## The blade's colours (the necromancer's soul-teal flame with a bone-white
## core: never the Host's starlight, never true gold). Visual only.
const FLAME := Color(0.45, 0.95, 0.85)  # TUNING (not in GDD) visual only
## The blade's core. Visual only.
const CORE := Color(0.92, 0.98, 0.95)  # TUNING (not in GDD) visual only

# --- Fallen Light (the paired passive) ---
## Passive id of Fallen Light (PassiveData, UnlockData).
const FALLEN_LIGHT: String = "fallen_light"
## Its level-row key: share more damage on every sweep (0..1).
const EDGE_KEY: String = "edge_bonus"
## Its level-row key: degrees more arc on every sweep.
const ARC_KEY: String = "arc_bonus"

# --- The Fallen Herald's innate: Torn Wing (FlamingSword) ---
## Innate value key: px more reach on every sweep (CharacterData
## "fallen_herald"; 0 for every other character).
const INNATE_KEY: String = "sword_reach_bonus"
