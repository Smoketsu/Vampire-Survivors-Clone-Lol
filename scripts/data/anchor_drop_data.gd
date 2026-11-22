## AnchorDropData — immutable rule constants of the Anchor Drop spell, its
## evolution Abyssal Mooring, its paired passive Dead Reckoning and the Ghost
## Helmsman's innate (Act X, the Maelstrom; GDD §15.0 "Anchor Drop, Abyssal
## Mooring, Dead Reckoning and the Ghost Helmsman"; owner-approved proposal:
## "Anchor Drop: a spectral anchor slams the strongest enemy, stuns it and
## shocks a ring around it (no pull) -> Abyssal Mooring (+ Dead Reckoning)";
## unlocked by defeating Vandermere). Its per-level stat rows live in
## AbilityData.SPELLS and its evolution row in EvolutionData, like every spell;
## this file holds only the fixed rules the spell node (AnchorDrop) reads, the
## passive's id and keys and the innate key. Data only.
class_name AnchorDropData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "anchor_drop"
## Damage-source tag of the anchor's slam (the base spell).
const SOURCE: String = "anchor_drop"
## Damage-source tag of the shock ring round the anchor.
const RING_SOURCE: String = "anchor_drop_shock"
## Damage-source tag of the evolved anchor's slam (Abyssal Mooring).
const EVOLVED_SOURCE: String = "abyssal_mooring"
## Damage-source tag of the moored anchor's pulses (Abyssal Mooring).
const MOOR_SOURCE: String = "abyssal_mooring_shock"
## Px from the necromancer within which the anchor picks the strongest foe.
const AIM_RANGE: float = 300.0  # TUNING (not in GDD) as Hero's Fist
## Seconds the anchor takes to come down (drawn falling; the slam lands after it).
const FALL_TIME: float = 0.4  # TUNING (not in GDD)
## Most anchors at once (the evolution and the innate included).
const MAX_ANCHORS: int = 4  # TUNING (not in GDD)
## Stun share on a boss or a miniboss (CombatResolver.stun_enemy()).
const STUN_BOSS_MULT: float = 0.25  # TUNING (not in GDD)
## Stun share on an elite.
const STUN_ELITE_MULT: float = 0.6  # TUNING (not in GDD)
## Px of a drawn anchor (visual only).
const ANCHOR_SIZE: float = 22.0  # TUNING (not in GDD) visual only
## Sprite key of the drawn anchor (the spell's badge; visual only).
const ANCHOR_ICON: String = "icons/anchor_drop"

# --- Dead Reckoning (the paired passive) ---
## Passive id of Dead Reckoning (PassiveData, UnlockData).
const DEAD_RECKONING: String = "dead_reckoning"
## Its level-row key: share the anchor's cooldown is shortened by
## (AbilityManager.apply_spell_mods(), on the spell rows' own keys).
const HASTE_KEY: String = "reckoning_haste"
## Its level-row key: share the anchor's stun is lengthened by.
const STUN_KEY: String = "reckoning_stun"

# --- The Ghost Helmsman's innate: Second Anchor (AnchorDrop) ---
## Innate value key: extra anchors a cast (CharacterData "ghost_helmsman"; 0
## for every other character).
const EXTRA_KEY: String = "anchor_extra"
