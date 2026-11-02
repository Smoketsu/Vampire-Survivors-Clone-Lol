## WitchCircleData — immutable rule constants of the Hex Circle spell, its
## evolution Witches' Sabbath, its paired passive Moonlit Rite, the Hedge
## Witch's innate and Act VII's counter-passive Embalmed (Act VII, the
## Witchwood; GDD §15.0 "Hex Circle, Witches' Sabbath, Moonlit Rite and the
## Hedge Witch (Act VII)"; owner-approved proposal: "Hex Circle: a crimson
## circle under the necromancer that drains every enemy inside -> Witches'
## Sabbath (+ Moonlit Rite) | The Hedge Witch"; unlocked by slaying Isolde). Its
## per-level stat rows live in AbilityData.SPELLS and its evolution row in
## EvolutionData, like every spell; this file holds only the fixed rules the
## spell node (WitchCircle) reads and the passives' ids and keys. The spell id
## is "witch_circle" (the brief: an id other than any enemy kind or the
## witches' own circle, whose damage tag is WitchHexData.CIRCLE_SOURCE
## "hex_circle"). Data only.
class_name WitchCircleData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "witch_circle"
## Damage-source tag of the base circle's drain.
const SOURCE: String = "witch_circle"
## Damage-source tag of the evolved circles' drain (Witches' Sabbath).
const EVOLVED_SOURCE: String = "witches_sabbath"
## Most HP the drain may bank for later heals, in seconds of heal_cap (like
## Soul Siphon's and the Necrotic Blight's leaky budget).
const BUDGET_SECONDS: float = 2.0  # TUNING (not in GDD)
## Seconds the pulse flash takes to fade (drawn only).
const FLASH_FADE: float = 0.4  # TUNING (not in GDD)

# --- Moonlit Rite (the paired passive) ---
## Passive id of Moonlit Rite (PassiveData, UnlockData).
const MOONLIT_RITE: String = "moonlit_rite"
## Its level-row key: share more damage of a SPELL hit on a foe standing inside
## one of the necromancer's hex circles (CombatResolver.damage_enemy(),
## WitchCircle.in_circle()).
const RITE_KEY: String = "rite_damage"

# --- The Hedge Witch's innate: Hedge Lore (Hex Circle) ---
## Innate value key: share wider every hex circle of the spell (CharacterData
## "hedge_witch"; 0 for every other character).
const RADIUS_KEY: String = "witch_circle_radius"

# --- Embalmed (Act VII's counter-passive) ---
## Passive id of Embalmed (PassiveData; the foundation's hook
## CourtRulesData.EMBALMED / EMBALMED_KEY, read by Bloodfeast.embalmed_mult()).
const EMBALMED: String = CourtRulesData.EMBALMED

# --- The Coven Breaks (the stage's achievement) ---
## Achievement id (MetaData).
const ACHIEVEMENT: String = "the_coven_breaks"
