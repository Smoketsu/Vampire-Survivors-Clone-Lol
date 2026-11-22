## FeathersVerdictData — immutable rule constants of the Feather's Verdict spell,
## its evolution Heart Devoured, its paired passive Heavy Heart and the
## Pharaoh's Shade's innate (temporary Act XII, the Hall of Two Truths; GDD §15.0
## "Feather's Verdict, Heart Devoured, Heavy Heart and the Pharaoh's Shade";
## owner-approved proposal: "Feather's Verdict: a gold feather lands on the
## strongest enemy and executes weak enemies in a ring around it -> Heart
## Devoured (+ Heavy Heart) | The Pharaoh's Shade (male)"; unlocked by defeating
## Osiris and Ammit). Its per-level stat rows live in AbilityData.SPELLS and its
## evolution row in EvolutionData, like every spell; this file holds only the
## fixed rules the spell node (FeathersVerdict) reads, the passive's id and keys
## and the innate key. Data only.
class_name FeathersVerdictData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "feathers_verdict"
## Evolution id (EvolutionData).
const EVOLUTION_ID: String = "heart_devoured"
## Damage-source tag of the feather's blow on the strongest foe (the base spell).
const SOURCE: String = "feathers_verdict"
## Damage-source tag of an execution in its ring (the base spell).
const EXECUTE_SOURCE: String = "feathers_verdict_execute"
## Damage-source tag of the evolved blow (Heart Devoured).
const EVOLVED_SOURCE: String = "heart_devoured"
## Damage-source tag of an evolved execution.
const EVOLVED_EXECUTE_SOURCE: String = "heart_devoured_execute"
## Seconds the feather takes to fall onto its target (it follows it).
const FALL_TIME: float = 0.45  # TUNING (not in GDD)
## Px above its target the feather starts its fall (visual only).
const FALL_PX: float = 60.0  # TUNING (not in GDD) visual only
## x a foe's max HP dealt as an execution (enough to end any foe under the
## line through armour; bosses, minibosses and structures are never executed).
const EXECUTE_OVERKILL: float = 3.0  # TUNING (not in GDD)
## Most feathers one cast drops (the evolution's `feathers`).
const MAX_FEATHERS: int = 3  # TUNING (not in GDD)
## Seconds a landed feather's ring is drawn fading (visual only).
const RING_FADE: float = 0.45  # TUNING (not in GDD) visual only

# --- Heavy Heart (the paired passive) ---
## Passive id of Heavy Heart (PassiveData, UnlockData).
const HEAVY_HEART: String = "heavy_heart"
## Its level-row key: share of max HP added to the execute line
## (AbilityManager.apply_spell_mods(), on the spell rows' own keys).
const LINE_KEY: String = "heavy_line"
## Its level-row key: share the execute ring grows by.
const REACH_KEY: String = "heavy_reach"

# --- The Pharaoh's Shade's innate: Crook and Flail (FeathersVerdict) ---
## Innate value key: share of max HP added to the execute line (CharacterData
## "pharaohs_shade"; 0 for every other character).
const INNATE_KEY: String = "verdict_execute_bonus"
