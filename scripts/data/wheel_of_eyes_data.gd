## WheelOfEyesData — immutable rule constants of the Wheel of Eyes spell, its
## evolution Ophanim, its paired passive All-Seeing and the Blind Saint's innate
## (temporary Act XIII, the Wheel of Thrones; GDD §15.0 "Wheel of Eyes, Ophanim,
## All-Seeing and the Blind Saint"; owner-approved proposal "Rewards": "Wheel of
## Eyes: a burning wheel rolls out in a line and rebounds off walls -> Ophanim
## (+ All-Seeing) | The Blind Saint (female, figure style)"; unlocked by slaying
## the Throne). Its per-level stat rows live in AbilityData.SPELLS and its
## evolution row in EvolutionData, like every spell; this file holds only the
## fixed rules the spell node (WheelOfEyes) reads, the passive's id and keys and
## the innate key. Data only.
class_name WheelOfEyesData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "wheel_of_eyes"
## Evolution id (EvolutionData).
const EVOLUTION_ID: String = "ophanim"
## Damage-source tag of a wheel (the base spell; also its Grace kind).
const SOURCE: String = "wheel_of_eyes"
## Damage-source tag of an evolved wheel and its rebound flare (Ophanim).
const EVOLVED_SOURCE: String = "ophanim"
## Seconds a wheel waits before it may strike the same foe again.
const HIT_GAP: float = 0.5  # TUNING (not in GDD)
## Most wheels rolling at once (a cap over every cast; the oldest ends first).
const MAX_WHEELS: int = 12  # TUNING (not in GDD)
## Px beyond the view's edge (round the necromancer) where a wheel rebounds:
## the "walls" of an open arena are the edges of the sight, and the obstacles.
const EDGE_PAD: float = -40.0  # TUNING (not in GDD) negative: a little inside the view
## Px a wheel's centre must keep from an obstacle (x its radius) before it
## rebounds off it.
const OBSTACLE_PAD: float = 0.5  # TUNING (not in GDD) share of its radius
## Px a foe may stand beyond the aim range for a cast to start.
const AIM_RANGE: float = 420.0  # TUNING (not in GDD)
## Degrees between two wheels of one cast (fanned round the aim).
const FAN_DEG: float = 22.0  # TUNING (not in GDD)
## The wheel's colours (soul-teal fire round a bone-white rim of closed eyes:
## never the Host's starlight, never true gold). Visual only.
const FIRE := Color(0.45, 0.95, 0.85)  # TUNING (not in GDD) visual only
## The rim's bone. Visual only.
const RIM := Color(0.90, 0.88, 0.80)  # TUNING (not in GDD) visual only
## Rim eyes drawn round a wheel (visual only).
const EYES: int = 6  # TUNING (not in GDD) visual only

# --- All-Seeing (the paired passive) ---
## Passive id of All-Seeing (PassiveData, UnlockData).
const ALL_SEEING: String = "all_seeing"
## Its level-row key: share more damage on every strike (0..1).
const DAMAGE_KEY: String = "wheel_damage"
## Its level-row key: share longer every wheel rolls (0..1).
const LIFE_KEY: String = "wheel_life"

# --- The Blind Saint's innate: Inner Sight (WheelOfEyes) ---
## Innate value key: px more radius on every wheel (CharacterData
## "blind_saint"; 0 for every other character).
const INNATE_KEY: String = "wheel_radius_bonus"
