## ValkyrieSpearData — the fixed rules of the Valkyrie Spear spell and its
## evolution Chooser of the Slain (Valgard's reward; the Hall of the Slain,
## temporarily Act XI; GDD §15.0 "Valkyrie Spear, Chooser of the Slain,
## Einherjar's Oath and the Shield-Maiden (Valgard)"), read by ValkyrieSpear.
## Its level numbers are AbilityData.SPELLS "valkyrie_spear" and
## EvolutionData.EVOLUTIONS "chooser_of_the_slain"; its paired passive
## Einherjar's Oath is PassiveData "einherjars_oath"; the Shield-Maiden's innate
## value is CharacterData "valkyrie_spear_extra_jumps". Data only.
class_name ValkyrieSpearData
extends RefCounted

## Spell id (AbilityData.SPELLS).
const ID: String = "valkyrie_spear"
## Damage-source stat tag of the base spell (CombatResolver "dmg_<tag>").
const SOURCE: String = "valkyrie_spear"
## Damage-source stat tag of the evolution.
const EVOLVED_SOURCE: String = "chooser_of_the_slain"
## The spear's spectral colour (a pale soul-white, never the valkyries' gold).
const SPEAR_COLOR := Color(0.80, 0.95, 0.98)  # TUNING (not in GDD) visual only
## Seconds the spear falls from the sky onto its first target.
const FALL_TIME: float = 0.18  # TUNING (not in GDD)
## Px above its target the spear starts its fall (drawing only).
const FALL_HEIGHT: float = 80.0  # TUNING (not in GDD) visual only
## Seconds between two strikes of one chain (the spear leaps).
const CHAIN_GAP: float = 0.09  # TUNING (not in GDD)
## Seconds a strike's flash line fades over (drawing only).
const FLASH_FADE: float = 0.22  # TUNING (not in GDD) visual only
## Seconds before a cast retries when no target stood in range.
const WAIT_RETRY: float = 0.3  # TUNING (not in GDD)
## Summon class a foe the evolved spear chooses rises as (a temporary Warrior,
## HordeDirector.spawn_temporary()).
const RISEN_CLASS: String = "warrior"  # TUNING (not in GDD)

# --- Einherjar's Oath (the paired passive) ---
## Passive id of Einherjar's Oath.
const OATH: String = "einherjars_oath"
## Its value key: extra leaps a spear makes.
const OATH_JUMPS_KEY: String = "oath_jumps"
## Its value key: + share of the spear's damage.
const OATH_DAMAGE_KEY: String = "oath_damage"

# --- The Shield-Maiden's innate: Shield-Sister (Valkyrie Spear) ---
## CharacterData innate value key: extra leaps a spear makes.
const EXTRA_KEY: String = "valkyrie_spear_extra_jumps"
