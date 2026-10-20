## PuppetData — immutable rule constants of the Hollow Puppet spell and its
## evolution Puppet King (Act III, the Assembly Halls; GDD §15.0 "The Assembly
## Halls (Act III phase 2)"; unlocked by slaying the Motherboard). Its per-level
## stat rows live in AbilityData.SPELLS and its evolution row in EvolutionData,
## like every spell; this file holds only the fixed rules the spell node
## (HollowPuppet) reads. All numbers are TUNING (not in GDD). Data only.
class_name PuppetData
extends RefCounted

## Damage-source tag of a puppet's hits (PassiveData.MINION_EXTRA_TAGS: a minion
## attack for crits; NecroSpellBook.SOURCES).
const SOURCE: String = "hollow_puppet"
## Damage-source tag of a Puppet King's death burst (an on-death effect:
## VerseData.MARGINALIA_SOURCES).
const BURST_SOURCE: String = "puppet_burst"
## Summon class a melee foe's puppet fights as (it body-blocks like a Warrior).
const MELEE_CLASS: String = "warrior"
## Summon class a ranged foe's puppet fights as (it shoots like an Archer).
const RANGED_CLASS: String = "archer"
## A foe whose attack range (px) is at least this is puppeted as RANGED_CLASS.
const RANGED_MIN_RANGE: float = 100.0  # TUNING (not in GDD)
## Least HP (before the summon passives) a puppet rises with, whatever the foe had left.
const MIN_HP: float = 20.0  # TUNING (not in GDD)
## Most puppets dancing at once (a cast skips new ones beyond it).
const MAX_PUPPETS: int = 4  # TUNING (not in GDD)
## Glyph prefix of a puppet (SummonedUnit.glyph_kind "puppet:<enemy kind>"):
## Glyphs.draw_summon() draws the foe's own art on soul strings (AssemblyGlyphs).
const GLYPH_PREFIX: String = "puppet:"
## Multiply tint of a puppet's body (a hollowed, violet-shadowed husk: it reads
## as the necromancer's, never as the foe it was).
const TINT := Color(0.72, 0.62, 0.92)  # TUNING (not in GDD) visual
## Colour of the soul strings it dances on (soul glow).
const STRING_COLOR := Color(0.66, 1.0, 0.82, 0.85)  # TUNING (not in GDD) visual
## Foe kinds never puppeted (the Eye's claimed dead are already ours).
const NEVER := ["drowned_thrall"]
## Seconds the cast's soul strings are drawn reaching the foe (drawing only).
const CAST_FX_TIME: float = 0.4  # TUNING (not in GDD) visual
