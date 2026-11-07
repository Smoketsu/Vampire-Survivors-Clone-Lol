## ParisArrowData — the fixed rules of the Paris's Arrow spell and its evolution
## Arrow of Fate (Act IV, the Shores of Ilion; owner-approved Act IV proposal
## "Rewards"; GDD §15.0 "Paris's Arrow, Mortal Heel and the Doomed Prophetess").
## The levelled numbers live in AbilityData.SPELLS "paris_arrow" and
## EvolutionData.EVOLUTIONS "arrow_of_fate"; these are the rules that do not
## level. Logic: ParisArrow. Data only (CLAUDE.md rule 2).
class_name ParisArrowData
extends RefCounted

## Seconds before the first volley once the spell is learned.
const FIRST_VOLLEY: float = 0.5  # TUNING (not in GDD)
## px past the target's body (straight behind it) the arrow's last stretch
## comes from: the hit's origin for CombatResolver.damage_enemy() (always
## behind its facing: a hit from behind).
const BEHIND: float = 16.0  # TUNING (not in GDD)
## px the arrow's curve swings out past and beside its target (the bend of its
## path around the target; drawing and the flight's shape only).
const SWING: float = 70.0  # TUNING (not in GDD)
## Share of the flight time a fated arrow takes for each jump (it is already
## close to its next target).
const JUMP_FLIGHT: float = 0.6  # TUNING (not in GDD)
## Most arrows in flight at once (a volley past it is cut short).
const MAX_ARROWS: int = 24  # TUNING (not in GDD)
## Trail points kept per arrow (drawing only).
const TRAIL: int = 5  # TUNING (not in GDD)
## The arrow's ghost-violet glow (the player's violet; drawing only).
const GLOW := Color(0.64, 0.36, 0.98)  # TUNING (not in GDD) Palette.VIOLET
## The arrow's pale core and bone head (drawing only).
const CORE := Color(0.87, 0.74, 1.0)  # TUNING (not in GDD) violet_flare
## The arrowhead (bone; drawing only).
const HEAD := Color(0.95, 0.92, 0.83)  # TUNING (not in GDD) bone
## Sound pitch of a volley's release (Sfx "bolt_cast"; audio only).
const LOOSE_PITCH: float = 1.35  # TUNING (not in GDD)
## Sound pitch of a strike (Sfx "bolt_hit" when it exists; audio only).
const HIT_PITCH: float = 1.2  # TUNING (not in GDD)
