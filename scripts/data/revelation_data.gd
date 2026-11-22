## RevelationData — immutable rule constants of the Revelation spell, its
## evolution Be Not Afraid, its paired passive Seventh Seal and the Unveiled's
## innate (temporary Act XIII, the Empyrean; GDD §15.0 "Revelation, Be Not
## Afraid, Seventh Seal and the Unveiled"; owner-approved proposal "Rewards":
## "Revelation: a flash that stuns every enemy on screen for 1 s and weakens
## them through the one debuff path -> Be Not Afraid (+ Seventh Seal) | The
## Unveiled (female, figure style; an angel who looked on the necromancer and
## fell)"; unlocked by slaying the Voice). Its per-level stat rows live in
## AbilityData.SPELLS and its evolution row in EvolutionData, like every spell;
## this file holds only the fixed rules the spell node (Revelation) reads, the
## passive's id and keys and the innate key. Data only.
class_name RevelationData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "revelation"
## Evolution id (EvolutionData).
const EVOLUTION_ID: String = "be_not_afraid"
## Damage-source tag of the flash (the base spell; also its Grace kind).
const SOURCE: String = "revelation"
## Damage-source tag of an evolved flash and its second flash (Be Not Afraid).
const EVOLVED_SOURCE: String = "be_not_afraid"
## Px trimmed off each side of the view: the flash reaches what the player
## sees, not the foes just past the edge.
const EDGE_PAD: float = 16.0  # TUNING (not in GDD)
## Share of the stun a boss or a miniboss suffers (CombatResolver.stun_enemy()).
const STUN_BOSS: float = 0.25  # TUNING (not in GDD) as the Bound Oni's smash
## Share of the stun an elite suffers.
const STUN_ELITE: float = 0.5  # TUNING (not in GDD)
## Share of the weakening a boss or a miniboss suffers (CombatResolver.weaken_enemy()).
const WEAKEN_BOSS: float = 0.5  # TUNING (not in GDD)
## Most foes one flash strikes (the nearest first never matters: the grid's
## order; a cap so a packed late screen costs a bounded tick).
const MAX_TARGETS: int = 160  # TUNING (not in GDD)
## Seconds the flash's light is drawn round the necromancer (visual only).
const FLASH_SHOW: float = 0.35  # TUNING (not in GDD) visual only
## The flash's colour: soul-teal light (never the Host's starlight, never true
## gold). Visual only.
const LIGHT := Color(0.55, 1.0, 0.9)  # TUNING (not in GDD) visual only

# --- Seventh Seal (the paired passive) ---
## Passive id of Seventh Seal (PassiveData, UnlockData).
const SEVENTH_SEAL: String = "seventh_seal"
## Its level-row key: share more damage on every flash (0..1).
const DAMAGE_KEY: String = "seal_damage"
## Its level-row key: s more stun on every flash.
const STUN_KEY: String = "seal_stun"

# --- The Unveiled's innate: Lifted Veil (Revelation) ---
## Innate value key: s more stun on every flash (CharacterData "the_unveiled";
## 0 for every other character).
const INNATE_KEY: String = "revelation_stun_bonus"
