## BoneBeetlesData — immutable rule constants of the Bone Beetles spell, its
## evolution Hive of Bone, its paired passive Chitin, the Broodbound's innate
## and Act IX's counter-passive Anchored on the Crash Site (Act IX, the Crash
## Site; GDD §15.0 "Bone Beetles, Hive of Bone, Chitin and the Broodbound (Act
## IX)"; owner-approved proposal: "Bone Beetles: slain enemies burst into bone
## beetles that bite the next enemy -> Hive of Bone (+ Chitin)"; unlocked by
## slaying the Hive Mother). Its per-level stat rows live in AbilityData.SPELLS
## and its evolution row in EvolutionData, like every spell; this file holds
## only the fixed rules the spell node (BoneBeetles) reads and the passives'
## ids and keys. Data only.
class_name BoneBeetlesData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "bone_beetles"
## Damage-source tag of the base spell's beetles.
const SOURCE: String = "bone_beetles"
## Damage-source tag of the evolved beetles (Hive of Bone).
const EVOLVED_SOURCE: String = "hive_of_bone"
## Sprite key of a bone beetle (assets/sprites/projectiles/; drawn flat, its
## head to the right; a code shape without it).
const SPRITE: String = "projectiles/bone_beetle"
## Hard cap of beetles alive at once, whatever the level's `cap` (the cost and
## the drawing stay flat).
const MAX_BEETLES: int = 48  # TUNING (not in GDD)
## px within which a beetle's bite lands (on top of the prey's body radius).
const BITE_REACH: float = 4.0  # TUNING (not in GDD)
## Most open foes a beetle compares when it picks its prey (the cost stays flat).
const PREY_SAMPLES: int = 12  # TUNING (not in GDD)
## px a burst's beetles scatter from the fallen foe before they turn on their prey.
const SCATTER: float = 10.0  # TUNING (not in GDD)
## Seconds a beetle's legs take for one scuttle cycle (drawing only).
const SCUTTLE_TIME: float = 0.12  # TUNING (not in GDD) drawing only

# --- Chitin (the paired passive) ---
## Passive id of Chitin (PassiveData, UnlockData).
const CHITIN: String = "chitin"
## Its level-row key: share (0..) more damage every beetle bite deals.
const CHITIN_KEY: String = "bite_bonus"

# --- The Broodbound's innate: Swarm Bride (Bone Beetles) ---
## Innate value key: extra beetles in every burst (CharacterData "broodbound";
## 0 for every other character).
const EXTRA_BEETLES_KEY: String = "beetle_extra"
