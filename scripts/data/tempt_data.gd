## TemptData — immutable rule constants of THE ENTHRALL PATH and of the spell
## Temptation and its evolution Unholy Desire (Act VI, the Palace of Silk and
## Ash; GDD §15.0 "Temptation, Unholy Desire, Velvet Chains and the Succubus
## Queen"; owner-approved proposal: "Temptation: charm the strongest nearby
## enemy to fight for you for 6 s"; unlocked by slaying Lilith). The spell's id
## is "tempt" (the Inferno's shared rule is "Temptation", class Temptation, and
## the enemy kinds must never meet a spell id). Its per-level rows live in
## AbilityData.SPELLS "tempt", its evolution row in EvolutionData
## "unholy_desire", its paired passive in PassiveData "velvet_chains"; this file
## holds the fixed rules TemptSpell and Enthrall read. The Succubus summon class
## (UnitData "bound_succubus") turns foes through the same Enthrall path.
## All numbers are TUNING (not in GDD) unless marked as the owner-approved
## proposal. Data only.
class_name TemptData
extends RefCounted

## Damage-source tag of a thrall the spell turned (its blows; stats dmg_tempt).
const SOURCE: String = "tempt"
## Damage-source tag of a thrall Unholy Desire turned.
const EVOLVED_SOURCE: String = "unholy_desire"
## Damage-source tag of Unholy Desire's burst when a thrall's charm ends.
const BURST_SOURCE: String = "desire_burst"
## Damage-source tag of the Succubus Queen's Heartbreaker (the returning foe's broken heart).
const HEARTBREAK_SOURCE: String = "tempt_heartbreak"
## Damage-source tag of a thrall a Succubus (the summon class) turned.
const CLASS_SOURCE: String = "bound_succubus_thrall"
## Paired passive of Unholy Desire (PassiveData id; owner-approved name).
const VELVET_CHAINS: String = "velvet_chains"
## Velvet Chains' level key: charms last this share longer (fraction).
const CHAIN_TIME_KEY: String = "chain_time"
## Velvet Chains' level key: thralls strike this share harder (fraction).
const CHAIN_POWER_KEY: String = "chain_power"
## The Succubus Queen's innate key (CharacterData): share of its max HP a foe
## loses when its charm ends (her Heartbreaker; 0 for every other character).
const HEARTBREAK_KEY: String = "tempt_heartbreak"

# --- The Enthrall path (Enthrall; HordeDirector.enthrall_foe()) ---------------------------------
## Glyph prefix of a thrall (SummonedUnit.glyph_kind "enthralled:<enemy kind>"):
## Glyphs.draw_summon() draws the foe's own art, tinted, a heart over it
## (SilkPalaceGlyphs.draw_enthralled()).
const GLYPH_PREFIX: String = "enthralled:"
## Summon class a melee foe fights as while enthralled (it body-blocks).
const MELEE_CLASS: String = "warrior"
## Summon class a ranged foe fights as (it shoots like an Archer).
const RANGED_CLASS: String = "archer"
## A foe whose attack range (px) is at least this fights as RANGED_CLASS.
const RANGED_MIN_RANGE: float = 100.0  # TUNING (not in GDD) as Hollow Puppet
## Least HP a thrall stands with, whatever the foe had left.
const MIN_HP: float = 20.0  # TUNING (not in GDD)
## Most thralls one army holds at once (every source together; a turn beyond it is refused).
const MAX_THRALLS: int = 6  # TUNING (not in GDD)
## Foe kinds never enthralled: the Eye's claimed dead and the illusions (they
## are not truly there).
const NEVER := ["drowned_thrall", "fox_fire", "kage_clone"]
## Seconds a thrall's temporary-summon life runs past its charm (Enthrall ends
## every charm itself; this only keeps the summon from crumbling first).
const LIFE_SLACK: float = 60.0
## Multiply tint of a thrall's body (charm pink over the foe's own colours: it
## reads as turned, never as the foe it was).
const TINT := Color(1.0, 0.70, 0.88)  # TUNING (not in GDD) visual
## Colour of the heart over a thrall (the necromancer's charm: violet-pink).
const HEART_COLOR := Color(0.85, 0.55, 1.0)  # TUNING (not in GDD) visual
## Seconds the cast's kiss is drawn reaching the foe (drawing only).
const CAST_FX_TIME: float = 0.4  # TUNING (not in GDD) visual
## px of Unholy Desire's burst around a thrall whose charm ended.
const BURST_RADIUS: float = 70.0  # TUNING (not in GDD)
