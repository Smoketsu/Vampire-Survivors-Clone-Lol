## BurningEyeData — the fixed rules of the BURNING EYE spell and its
## evolution EYE OF RETRIBUTION (temporary Act XII, the Temple of the Lioness;
## GDD §15.0 "Burning Eye, Eye of Retribution, Desert Fury and the
## Lion-Priestess (Dynasty phase 2)"; proposal docs/proposals/NEW_ACTS_AND_ORDER.md
## Part 3 "Rewards": "Burning Eye: a solar eye fires a beam that sweeps a 90°
## arc -> Eye of Retribution (+ Desert Fury)"). The per-level numbers are in
## AbilityData.SPELLS "burning_eye" and EvolutionData.EVOLUTIONS
## "eye_of_retribution"; Desert Fury's in PassiveData. Read by BurningEye. Data
## only, no logic.
class_name BurningEyeData
extends RefCounted

## Spell id (AbilityData.SPELLS key, NecroSpellBook dispatch).
const ID: String = "burning_eye"
## Evolution id (EvolutionData.EVOLUTIONS key; detected by its "retribution" key).
const EVOLUTION: String = "eye_of_retribution"
## Paired passive id (PassiveData.PASSIVES key).
const PASSIVE: String = "desert_fury"
## Damage tag of the base beam (stats "dmg_burning_eye"; a FIRE source for the
## Dynasty's mummies, DynastyRulesData.FIRE_SOURCES).
const SOURCE: String = "burning_eye"
## Damage tag of the evolved beam (a FIRE source too).
const EVOLVED_SOURCE: String = "eye_of_retribution"
## The Lion-Priestess's innate key (CharacterData "eye_reach_bonus": x 1 + it
## on the beam's length; 0 for every other character).
const INNATE_KEY: String = "eye_reach_bonus"

## Seconds before the first sweep after the spell is learned.
const FIRST_SWEEP: float = 1.0  # TUNING (not in GDD)
## Least seconds between the end of one sweep and the start of the next.
const MIN_GAP: float = 0.5  # TUNING (not in GDD)
## px beyond the beam's length a foe may stand and still start a sweep.
const TRIGGER_SLACK: float = 20.0  # TUNING (not in GDD)
## Least distance (px) used in the angular hit test (a foe on top of the eye).
const MIN_HIT_DIST: float = 12.0  # TUNING (not in GDD)
## px the eye floats above the necromancer's centre (drawn only; the beam
## leaves the necromancer).
const EYE_HEIGHT: float = 44.0  # TUNING (not in GDD)
## Radius (px) of the drawn eye.
const EYE_RADIUS: float = 7.0  # TUNING (not in GDD)
## Angle (rad) of the fading afterglow drawn behind the beam.
const TRAIL_ANGLE: float = 0.22  # TUNING (not in GDD)
## Beam core colour (the player's own solar eye: sun-white).
const CORE: Color = Color(1.0, 0.97, 0.82)  # TUNING (not in GDD)
## Beam glow colour (a solar orange-gold; the eye is the player's, so the warm
## gold is right here).
const GLOW: Color = Color(1.0, 0.62, 0.18)  # TUNING (not in GDD)
## Eye pupil colour (the necromancer's soul-teal, so it reads as his).
const PUPIL: Color = Color(0.36, 0.94, 0.86)  # TUNING (not in GDD) Palette soul-teal
## Pitch of the sweep sound.
const SWEEP_PITCH: float = 0.7  # TUNING (not in GDD)
## Eye of Retribution: least seconds between two sweeps when a hit on the
## necromancer calls the eye at once (its "retribution" stat overrides it per
## level; this is the floor).
const RETRIBUTION_FLOOR: float = 0.8  # TUNING (not in GDD)
