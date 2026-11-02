## BoneMinesData — immutable rule constants of the Bone Mines spell, its
## evolution Killing Ground, its paired passive Tripwire and the Fallen
## Sergeant's innate (Act VIII, Fort Kessler; GDD §15.0 "Bone Mines, Killing
## Ground, Tripwire and the Fallen Sergeant (Act VIII)"; owner-approved
## proposal: "Bone Mines: bone mines dropped along the necromancer's path,
## triggered by enemies -> Killing Ground (+ Tripwire)"; unlocked by slaying
## General Harrow). Its per-level stat rows live in AbilityData.SPELLS and its
## evolution row in EvolutionData, like every spell; this file holds only the
## fixed rules the spell node (BoneMines) reads and the passive's ids and keys.
## Data only.
class_name BoneMinesData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData). Never an enemy kind or a
## structure: the minefield's mines are "kessler_mine".
const ID: String = "bone_mines"
## Damage-source tag of the base spell's blasts.
const SOURCE: String = "bone_mines"
## Damage-source tag of the evolved blasts (Killing Ground).
const EVOLVED_SOURCE: String = "killing_ground"
## Damage-source tag of Killing Ground's bone shards.
const SHARD_SOURCE: String = "killing_ground_shards"
## Seconds a dropped mine takes to arm (it cannot go off before).
const ARM_TIME: float = 0.5  # TUNING (not in GDD)
## Seconds between two checks of the mines' triggers.
const CHECK_EVERY: float = 0.1  # TUNING (not in GDD)
## Seconds a cast waits before trying again when the necromancer has not
## moved `spacing` px from his last mine.
const WAIT_RETRY: float = 0.2  # TUNING (not in GDD)
## Px a second mine (the Fallen Sergeant's Sapper's Hands) lies to the side of
## the first.
const PAIR_OFFSET: float = 26.0  # TUNING (not in GDD)
## Seconds the drawn blast stays (drawn only).
const FADE_TIME: float = 0.3  # TUNING (not in GDD)
## The mines blink slowly (Hz; the act's light rule: at most 1 Hz, a soft fade).
const BLINK_HZ: float = 0.5  # TUNING (not in GDD)

# --- Tripwire (the paired passive) ---
## Passive id of Tripwire (PassiveData, UnlockData).
const TRIPWIRE: String = "tripwire"
## Its level-row key: px more trigger reach for every bone mine.
const TRIP_REACH_KEY: String = "trip_reach"
## Its level-row key: share (0..1) every foe caught in a bone mine's blast is
## slowed by (CombatResolver.slow_enemy(), the one slow path).
const TRIP_SLOW_KEY: String = "trip_slow"
## Seconds Tripwire's slow lasts (before Spirit Binding and Mournsong).
const TRIP_SLOW_TIME: float = 2.0  # TUNING (not in GDD)

# --- The Fallen Sergeant's innate: Sapper's Hands (Bone Mines) ---
## Innate value key: extra mines laid beside each dropped one (CharacterData
## "fallen_sergeant"; 0 for every other character).
const EXTRA_MINES_KEY: String = "bone_mines_extra"
