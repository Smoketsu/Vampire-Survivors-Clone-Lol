## BarrowGraspData — immutable rule constants of the Barrow Grasp spell, its
## evolution Barrow-Lord's Embrace, its paired passive Grave Frost and the
## Rune-Seer's innate (the Barrow Fields, the Hall of the Slain, temporarily Act
## XI; GDD §15.0 "Barrow Grasp, Barrow-Lord's Embrace, Grave Frost and the
## Rune-Seer"; owner-approved proposal "Rewards": "Barrow Grasp: cold hands
## burst from the ground in a ring and hold enemies -> Barrow-Lord's Embrace (+
## Grave Frost)"; unlocked by slaying Hrimgar). Its per-level stat rows live in
## AbilityData.SPELLS and its evolution row in EvolutionData, like every spell;
## this file holds only the fixed rules the spell node (BarrowGrasp) reads and
## the passive's and innate's ids and keys. Data only.
class_name BarrowGraspData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "barrow_grasp"
## Damage-source tag of the base spell's hands.
const SOURCE: String = "barrow_grasp"
## Damage-source tag of the evolved hands (Barrow-Lord's Embrace).
const EVOLVED_SOURCE: String = "barrow_lords_embrace"
## Share of a hold a stage boss or a miniboss keeps (CombatResolver.stun_enemy()
## boss_mult).
const BOSS_HOLD_MULT: float = 0.25  # TUNING (not in GDD)
## Share of a hold an elite keeps (stun_enemy() elite_mult).
const ELITE_HOLD_MULT: float = 0.6  # TUNING (not in GDD)
## Seconds a hand of the base spell stands (it grabs once, as it bursts up).
const HAND_LIFE: float = 0.5  # TUNING (not in GDD) visual length of the grab
## Seconds a hand takes to burst out of the ground (drawing only).
const RISE_TIME: float = 0.12  # TUNING (not in GDD) drawing only
## Seconds between two grabs of a lingering evolved hand.
const LINGER_TICK: float = 0.5  # TUNING (not in GDD)
## Share of `damage` a lingering hand's later grabs deal (the first grab is whole).
const LINGER_SHARE: float = 0.35  # TUNING (not in GDD)
## Slow share (0..1) a lingering hand's later grabs put on the foes in it (for
## 2 x LINGER_TICK s; the hold is the first grab's only, so nothing is held in a
## chain: the seed-7 forced run had a frost giant held 10 s on end).
const LINGER_SLOW: float = 0.5  # TUNING (not in GDD)
## Hard cap of hands standing at once, whatever the level (the cost and the
## drawing stay flat).
const MAX_HANDS: int = 40  # TUNING (not in GDD)
## Turn (rad) of the ring between two casts, so the gaps move (no RNG).
const RING_TURN: float = 0.61  # TUNING (not in GDD)
## Most foes one hand holds at a grab (the cost stays flat).
const GRAB_SAMPLES: int = 8  # TUNING (not in GDD)

# --- Grave Frost (the paired passive) ---
## Passive id of Grave Frost (PassiveData, UnlockData).
const GRAVE_FROST: String = "grave_frost"
## Its level-row key: share (0..) more damage AND longer hold of every hand.
const GRAVE_FROST_KEY: String = "frost_bonus"

# --- The Rune-Seer's innate: Rune of Binding (Barrow Grasp) ---
## Innate value key: extra hands in every ring (CharacterData "rune_seer"; 0
## for every other character).
const EXTRA_HANDS_KEY: String = "grasp_extra_hands"
