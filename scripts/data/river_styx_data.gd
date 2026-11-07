## RiverStyxData — immutable rule constants of the River Styx spell, its
## evolution Lethe's Flood, its paired passive Ferryman's Toll and the
## Ferrywoman's innate (Act IV, the Asphodel Underworld; GDD §15.0 "River Styx,
## Lethe's Flood, Ferryman's Toll and the Ferrywoman"; owner-approved proposal:
## "River Styx: a black river line that drains and slows whatever crosses it
## -> Lethe's Flood (+ Ferryman's Toll)"; unlocked by defeating Hades). Its
## per-level stat rows live in AbilityData.SPELLS and its evolution row in
## EvolutionData, like every spell; this file holds only the fixed rules the
## spell node (RiverStyx) reads, the passive's id and keys and the innate's
## numbers. Data only.
class_name RiverStyxData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "river_styx"
## Damage-source tag of the river's drain (base spell).
const SOURCE: String = "river_styx"
## Damage-source tag of the evolved river's drain (Lethe's Flood).
const EVOLVED_SOURCE: String = "lethes_flood"
## Rivers on the field at most (older ones dry up first).
const MAX_RIVERS: int = 6  # TUNING (not in GDD)
## Px the river may lie ahead of the necromancer at most (toward the nearest
## foe, so the foes must cross it to reach him).
const MAX_OFFSET: float = 90.0  # TUNING (not in GDD)
## Share of the distance to the nearest foe at which the river is laid (at
## most MAX_OFFSET px from the necromancer).
const OFFSET_SHARE: float = 0.55  # TUNING (not in GDD)
## Px the spell looks for the foe it lays the river against.
const AIM_RANGE: float = 380.0  # TUNING (not in GDD)
## Seconds a river takes to fill (drawing only; it works at once).
const FILL_TIME: float = 0.35  # TUNING (not in GDD)
## Lethe's Flood: share of the stun a boss or a miniboss suffers.
const FORGET_BOSS_MULT: float = 0.25  # TUNING (not in GDD)
## Lethe's Flood: share of the stun an elite suffers.
const FORGET_ELITE_MULT: float = 0.5  # TUNING (not in GDD)

# --- Ferryman's Toll (the paired passive) ---
## Passive id of Ferryman's Toll (PassiveData, UnlockData).
const TOLL: String = "ferrymans_toll"
## Its level-row key: HP the necromancer heals per foe slain while slowed
## (CombatResolver._kill_enemy(), the one kill path).
const TOLL_HEAL_KEY: String = "toll_heal"
## Its level-row key: Dread Rally soul points per foe slain while slowed.
const TOLL_RALLY_KEY: String = "toll_rally"
## Most HP Ferryman's Toll heals per second (a dense kill wave stays fair).
const TOLL_HEAL_CAP_PER_S: float = 6.0  # TUNING (not in GDD)

# --- The Ferrywoman's innate: Ferry of Souls (RiverStyx) ---
## Class of the Risen a foe slain in her river rises as (a temporary summon,
## HordeDirector.spawn_temporary(), the one temporary-summon path).
const FERRY_CLASS: String = "warrior"
