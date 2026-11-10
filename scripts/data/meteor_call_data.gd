## MeteorCallData — immutable rule constants of the Meteor Call spell, its
## evolution Extinction Event, its paired passive Cosmic Dust and the
## Skywatcher's innate (temporary Act XIV, the Last Day; GDD §15.0 "Meteor
## Call, Extinction Event, Cosmic Dust and the Skywatcher"; owner-approved
## proposal "Rewards": "Old Gravejaw | Meteor Call: a telegraphed meteor lands
## on the densest group -> Extinction Event (+ Cosmic Dust) | The Skywatcher
## (female, figure style)"; unlocked by slaying Old Gravejaw before the
## impact). Its per-level stat rows live in AbilityData.SPELLS and its
## evolution row in EvolutionData, like every spell; this file holds only the
## fixed rules the spell node (MeteorCall) reads, the passive's id and keys and
## the innate key. Data only.
class_name MeteorCallData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "meteor_call"
## Evolution id (EvolutionData).
const EVOLUTION_ID: String = "extinction_event"
## Damage-source tag of a meteor (the base spell).
const SOURCE: String = "meteor_call"
## Damage-source tag of an evolved meteor (Extinction Event).
const EVOLVED_SOURCE: String = "extinction_event"
## px round a candidate foe counted for the aim (the meteor goes where the foes are densest).
const AIM_RADIUS: float = 80.0  # TUNING (not in GDD)
## Foes looked at as aim candidates (the first in the spatial hash's order).
const AIM_SAMPLES: int = 16  # TUNING (not in GDD)
## px two meteors of one cast must lie apart (Extinction Event picks distinct groups).
const SPACING: float = 120.0  # TUNING (not in GDD)
## Knockback impulse (px/s, / the foe's mass) a meteor gives every foe it strikes, away from its centre.
const KNOCK: float = 220.0  # TUNING (not in GDD)
## Most meteors falling at once (new ones are skipped beyond it).
const MAX_FALLING: int = 8  # TUNING (not in GDD)
## Pitch of the cast sound (a startup-bank sound: the spell plays on every stage).
const CAST_PITCH: float = 0.6  # TUNING (not in GDD)
## The meteor's colours (the necromancer's soul-teal fire with a bone-white
## core: never true gold, never the enemies' lava). Visual only.
const FIRE := Color(0.45, 0.95, 0.85)  # TUNING (not in GDD) visual only
## The meteor's core. Visual only.
const CORE := Color(0.92, 0.98, 0.95)  # TUNING (not in GDD) visual only

# --- Cosmic Dust (the paired passive) ---
## Passive id of Cosmic Dust (PassiveData, UnlockData).
const COSMIC_DUST: String = "cosmic_dust"
## Its level-row key: share more damage on every meteor (0..1).
const DAMAGE_KEY: String = "dust_bonus"
## Its level-row key: px more radius of every meteor.
const RADIUS_KEY: String = "dust_radius"

# --- The Skywatcher's innate: Star Reader (Meteor Call) ---
## Innate value key: share more radius of every meteor (CharacterData
## "skywatcher"; 0 for every other character).
const INNATE_KEY: String = "meteor_radius_bonus"
