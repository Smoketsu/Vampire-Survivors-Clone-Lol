## BrimstoneData — immutable rule constants of the Brimstone spell, its
## evolution Rain of Fire, its paired passive Furnace Heart, the Furnace
## Priest's innate and Act VI's counter-passive Salt Circle (Act VI, the
## Burning Gate; GDD §15.0 "Brimstone, Rain of Fire, Furnace Heart and the
## Furnace Priest (Act VI)"; owner-approved proposal: "Brimstone: burning stones
## fall on the densest group and leave a short pit -> Rain of Fire (+ Furnace
## Heart)"; unlocked by slaying Moloch). Its per-level stat rows live in
## AbilityData.SPELLS and its evolution row in EvolutionData, like every spell;
## this file holds only the fixed rules the spell node (Brimstone) reads and the
## passives' ids and keys. Data only.
class_name BrimstoneData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "brimstone"
## Damage-source tag of the base spell's falling stones.
const SOURCE: String = "brimstone"
## Damage-source tag of the evolved stones (Rain of Fire).
const EVOLVED_SOURCE: String = "rain_of_fire"
## Damage-source tag of the burning pits the stones leave (both forms): the
## spell's own pits, which burn ENEMIES ONLY (never a summon or the
## necromancer; they are the spell's, not the Hell Pits').
const PIT_SOURCE: String = "brimstone_pit"
## Seconds a stone falls (its shadow grows on the ground) before it lands.
const FALL_TIME: float = 0.45  # TUNING (not in GDD)
## Seconds between two burns of the spell's pits.
const PIT_TICK: float = 0.25  # TUNING (not in GDD)
## Most of the spell's pits burning at once (the oldest goes out first).
const MAX_PITS: int = 14  # TUNING (not in GDD)
## Most foes sampled as the centre of a group (the cost stays flat).
const GROUP_SAMPLES: int = 18  # TUNING (not in GDD)
## Seconds a cooling pit takes to fade (drawn only).
const COOL_TIME: float = 0.5  # TUNING (not in GDD)
## Px between two stones' targets of one volley (a second stone seeks
## another group; with fewer groups than stones the rest scatter around the
## densest, `rain_spread` px for Rain of Fire, half the impact radius else).
const GROUP_APART: float = 70.0  # TUNING (not in GDD)

# --- Furnace Heart (the paired passive) ---
## Passive id of Furnace Heart (PassiveData, UnlockData).
const FURNACE_HEART: String = "furnace_heart"
## Its level-row key: share more damage of a SPELL hit on a foe standing in
## fire (CombatResolver.damage_enemy(), Brimstone.in_fire()).
const HEART_KEY: String = "heart_damage"

# --- The Furnace Priest's innate: Stoker (Brimstone) ---
## Innate value key: extra stones in every Brimstone volley (CharacterData
## "furnace_priest"; 0 for every other character).
const EXTRA_STONES_KEY: String = "brimstone_extra_stones"

# --- Salt Circle (Act VI's counter-passive) ---
## Passive id of Salt Circle (PassiveData; the foundation's hook
## InfernoRulesData.SALT_CIRCLE / SALT_CIRCLE_KEY, read by
## HellPits.salt_circle_mult()).
const SALT_CIRCLE: String = InfernoRulesData.SALT_CIRCLE
