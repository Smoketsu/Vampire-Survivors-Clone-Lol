## StampedeData — immutable rule constants of the Stampede spell, its evolution
## Herd of Ages, its paired passive Calcified Hide and the Herd-Warden's innate
## (temporary Act XIV, the Great Plain; GDD §15.0 "Stampede, Herd of Ages,
## Calcified Hide and the Herd-Warden"; owner-approved proposal "Rewards": "Old
## Ironbrow | Stampede: a spectral horned charger tramples a line -> Herd of
## Ages (+ Calcified Hide) | The Herd-Warden (male)"; unlocked by slaying Old
## Ironbrow). Its per-level stat rows live in AbilityData.SPELLS and its
## evolution row in EvolutionData, like every spell; this file holds only the
## fixed rules the spell node (Stampede) reads, the passive's id and keys and
## the innate key. Data only.
class_name StampedeData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "stampede"
## Evolution id (EvolutionData).
const EVOLUTION_ID: String = "herd_of_ages"
## Damage-source tag of a charger (the base spell).
const SOURCE: String = "stampede"
## Damage-source tag of an evolved charger (Herd of Ages).
const EVOLVED_SOURCE: String = "herd_of_ages"
## px behind the necromancer a charger starts its run.
const BACK: float = 40.0  # TUNING (not in GDD)
## px round a candidate foe counted for the aim (the line goes where the foes are thickest).
const AIM_RADIUS: float = 90.0  # TUNING (not in GDD)
## Foes looked at as aim candidates (the first in the spatial hash's order).
const AIM_SAMPLES: int = 12  # TUNING (not in GDD)
## Knockback impulse (px/s, / the foe's mass) a charger gives every foe it crosses, along its run.
const KNOCK: float = 260.0  # TUNING (not in GDD)
## px between two chargers abreast (Herd of Ages).
const HERD_SPACING: float = 46.0  # TUNING (not in GDD)
## Most chargers running at once (new ones are skipped beyond it).
const MAX_RUNS: int = 12  # TUNING (not in GDD)
## Stun share kept on a boss or a miniboss / an elite (Herd of Ages' stun).
const STUN_BOSS_MULT: float = 0.3  # TUNING (not in GDD)
## Stun share kept on an elite (Herd of Ages' stun).
const STUN_ELITE_MULT: float = 0.6  # TUNING (not in GDD)
## Pitch of the cast sound (a startup-bank sound: the spell plays on every stage).
const CAST_PITCH: float = 0.7  # TUNING (not in GDD)
## The chargers' colours (the necromancer's soul-teal with a bone-white core:
## never true gold). Visual only.
const SPIRIT := Color(0.45, 0.95, 0.85)  # TUNING (not in GDD) visual only
## The chargers' horns. Visual only.
const CORE := Color(0.92, 0.98, 0.95)  # TUNING (not in GDD) visual only

# --- Calcified Hide (the paired passive) ---
## Passive id of Calcified Hide (PassiveData, UnlockData).
const CALCIFIED_HIDE: String = "calcified_hide"
## Its level-row key: share more damage on every charger (0..1).
const DAMAGE_KEY: String = "hide_bonus"
## Its level-row key: px more half width of every charger's path.
const WIDTH_KEY: String = "width_bonus"

# --- The Herd-Warden's innate: Lead Bull (Stampede) ---
## Innate value key: share more run length of every charger (CharacterData
## "herd_warden"; 0 for every other character).
const INNATE_KEY: String = "stampede_length_bonus"
