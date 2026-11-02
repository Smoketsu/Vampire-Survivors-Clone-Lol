## NightSwarmData — immutable rule constants of the Night Swarm spell, its
## evolution Nocturne, its paired passive Old Blood and the Dhampir's innate
## (Act VII, Castle Sanguis; GDD §15.0 "Night Swarm, Nocturne, Old Blood and the
## Dhampir"; owner-approved proposal: "Night Swarm: a cloud of spectral bats
## circles the necromancer and darts at enemies -> Nocturne (+ Old Blood)";
## unlocked by defeating Queen Carmilla and the Elder). Its per-level stat rows
## live in AbilityData.SPELLS and its evolution row in EvolutionData, like every
## spell; this file holds only the fixed rules the spell node (NightSwarm)
## reads, the passive's id and keys and the innate key. Data only.
class_name NightSwarmData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "night_swarm"
## Damage-source tag of a spectral bat's bite (the base spell).
const SOURCE: String = "night_swarm"
## Damage-source tag of an evolved bat's bite (Nocturne).
const EVOLVED_SOURCE: String = "nocturne"
## Damage-source tag of Nocturne's leap on to the next foe.
const CHAIN_SOURCE: String = "nocturne_leap"
## Px from the necromancer within which a bat picks the nearest foe.
const AIM_RANGE: float = 240.0  # TUNING (not in GDD) about a third of the screen's height
## Radians per second the swarm circles the necromancer.
const ORBIT_SPEED: float = 2.2  # TUNING (not in GDD)
## Px per second of a darting (and returning) bat.
const DART_SPEED: float = 420.0  # TUNING (not in GDD)
## Px from its target's edge at which a darting bat bites.
const BITE_REACH: float = 4.0  # TUNING (not in GDD)
## Px within which Nocturne's bat leaps on to another foe after a bite.
const CHAIN_RANGE: float = 110.0  # TUNING (not in GDD)
## Most seconds a bat may spend away from the swarm (a dart that finds nothing
## turns back).
const DART_MAX_TIME: float = 1.2  # TUNING (not in GDD)
## Most bats in the swarm (the evolution, the innate and Old Blood included).
const MAX_BATS: int = 14  # TUNING (not in GDD)
## Px of a drawn bat's half-span (visual only).
const BAT_SIZE: float = 5.0  # TUNING (not in GDD) visual only

# --- Old Blood (the paired passive) ---
## Passive id of Old Blood (PassiveData, UnlockData).
const OLD_BLOOD: String = "old_blood"
## Its level-row key: share the bats' dart cooldown is shortened by
## (AbilityManager.apply_spell_mods(), on the spell rows' own keys).
const HASTE_KEY: String = "swarm_haste"
## Its level-row key: share of a bite's damage healed to the necromancer (the
## spell's effective stat "bite_heal", read by NightSwarm; healed through
## CombatResolver.heal_player(), at most HEAL_CAP_PER_S HP per second).
const HEAL_KEY: String = "bite_heal"
## Most HP Old Blood heals the necromancer per second (the bites are many).
const HEAL_CAP_PER_S: float = 3.0  # TUNING (not in GDD)

# --- The Dhampir's innate: Half-Blood (NightSwarm) ---
## Innate value key: extra bats in the swarm (CharacterData "dhampir"; 0 for
## every other character).
const EXTRA_KEY: String = "swarm_extra_bats"
