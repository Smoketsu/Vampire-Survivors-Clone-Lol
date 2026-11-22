## CannonadeData — the fixed rules of CANNONADE and its evolution DEAD MEN'S
## BROADSIDE (Act X, the Treasure Galleon; GDD §15.0 "Cannonade, Dead Men's
## Broadside, Black Powder and the Corsair Queen (Act X)"; owner-approved
## proposal: "Cannonade: spectral cannonballs arc down on three marked
## groups"). The per-level numbers are AbilityData.SPELLS["cannonade"] and
## EvolutionData.EVOLUTIONS["dead_mens_broadside"]; Black Powder's are its
## PassiveData row. Read by Cannonade. No logic here.
class_name CannonadeData
extends RefCounted

## Spell id (AbilityData.SPELLS).
const ID: String = "cannonade"
## Damage source of a cannonball's blast.
const SOURCE: String = "cannonade"
## Damage source of the evolution's blasts (Dead Men's Broadside).
const EVOLVED_SOURCE: String = "dead_mens_broadside"
## Seconds a marked group's circle shows before its ball lands (the arc).
const FALL_TIME: float = 0.75  # TUNING (not in GDD)
## Height (px) of a ball's drawn arc at its top.
const ARC_HEIGHT: float = 70.0  # TUNING (not in GDD) drawing only
## Enemies sampled when looking for the densest groups (first in the hash order).
const GROUP_SAMPLES: int = 40  # TUNING (not in GDD)
## px two marked groups keep apart.
const GROUP_APART: float = 70.0  # TUNING (not in GDD)
## Seconds the spell waits before it looks again when no foe is in range.
const WAIT_RETRY: float = 0.4  # TUNING (not in GDD)
## The spectral balls' colour: the necromancer's soul light over iron (never the Brotherhood's lantern amber).
const SOUL_COLOR := Color(0.55, 0.95, 0.84)  # TUNING (not in GDD)

# --- Black Powder (the paired passive) ---
## PassiveData id of Black Powder.
const BLACK_POWDER: String = "black_powder"
## Its key: share wider every cannonball's blast (0.1 = +10%).
const BLAST_KEY: String = "powder_blast_radius"
## Its key: px every cannonball knocks the foes it hits outward from the blast.
const KNOCK_KEY: String = "powder_knock"

# --- The Corsair Queen's innate: Queen's Ransom (Cannonade) ---
## CharacterData innate key: extra marked groups each volley.
const EXTRA_MARKS_KEY: String = "cannonade_extra_marks"
