## FallFromGraceData — immutable rule constants of the Fall from Grace spell,
## its evolution Lightbringer, its paired passive Pride and the Fallen Saint's
## innate (Act VI, Pandemonium; GDD §15.0 "Fall from Grace, Lightbringer, Pride
## and the Fallen Saint"; owner-approved proposal: "Fall from Grace: a fallen
## star crashes on the strongest enemy -> Lightbringer (+ Pride)"; unlocked by
## defeating the Morning Star). Its per-level stat rows live in
## AbilityData.SPELLS and its evolution row in EvolutionData, like every spell;
## this file holds only the fixed rules the spell node (FallFromGrace) reads,
## the passive's id and keys. Data only.
class_name FallFromGraceData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "fall_from_grace"
## Damage-source tag of the base spell's falling star.
const SOURCE: String = "fall_from_grace"
## Damage-source tag of the evolved stars (Lightbringer).
const EVOLVED_SOURCE: String = "lightbringer"
## Damage-source tag of Lightbringer's flare ring around each crash.
const FLARE_SOURCE: String = "lightbringer_flare"
## Px from the necromancer within which the strongest foe is chosen.
const AIM_RANGE: float = 380.0  # TUNING (not in GDD) about the visible half-height and a bit
## The flare ring's radius, as a multiple of the crash radius (Lightbringer).
const FLARE_RADIUS_MULT: float = 1.6  # TUNING (not in GDD) first pass 1.9
## Px above (and behind) the target a star starts its fall (drawing only).
const FALL_FROM: Vector2 = Vector2(-70.0, -190.0)  # TUNING (not in GDD) visual only
## Seconds a crash's light stays drawn after it lands (visual only).
const CRASH_SHOW: float = 0.3  # TUNING (not in GDD)
## Most stars in the sky at once (pooled; a cast past it waits).
const MAX_STARS: int = 12  # TUNING (not in GDD)

# --- Pride (the paired passive) ---
## Passive id of Pride (PassiveData, UnlockData).
const PRIDE: String = "pride"
## Its level-row key: share Fall from Grace's cooldown is shortened by
## (AbilityManager.apply_spell_mods(), on the spell rows' own keys).
const HASTE_KEY: String = "star_haste"
## Its level-row key: extra share of a star's damage on an ELITE, a miniboss or
## a boss (the proud; the spell's effective stat "pride_bonus", read by
## FallFromGrace).
const PROUD_KEY: String = "pride_bonus"

# --- The Fallen Saint's innate: Second Fall (FallFromGrace) ---
## Innate value key: share of a star's damage a SECOND star deals on the
## next-strongest foe (CharacterData "fallen_saint"; 0 for every other character).
const SECOND_KEY: String = "grace_second_star"
