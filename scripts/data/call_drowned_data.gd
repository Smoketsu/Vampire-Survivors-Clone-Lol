## CallDrownedData — immutable rule constants of the Call of the Drowned spell
## and its evolution Tidecaller's Host (Act II, GDD §15.0 "Ul-Thalos, the
## Risen Spire"; unlocked by slaying Vhal'Neth). Its per-level stat rows live
## in AbilityData.SPELLS and its evolution row in EvolutionData, like every
## spell; this file holds only the fixed rules the spell node
## (CallOfTheDrowned) reads. All numbers are TUNING (not in GDD). Data only.
class_name CallDrownedData
extends RefCounted

## Seconds the tendrils' ring is shown under a target before they rise.
const TENDRIL_DELAY: float = 0.45  # TUNING (not in GDD) a short, readable telegraph
## Fraction (0..1) of speed removed from every foe the tendrils strike ...
const SLOW: float = 0.5  # TUNING (not in GDD)
## ... for this many seconds (CombatResolver.slow_enemy(): Spirit Binding and Mournsong apply).
const SLOW_TIME: float = 1.5  # TUNING (not in GDD)
## Most tendrils rising at once (a cast skips new ones beyond it).
const MAX_PENDING: int = 8  # TUNING (not in GDD)
## Summon class a Drowned Thrall rises as (base kit, drawn as the Thrall).
const THRALL_CLASS: String = "warrior"  # TUNING (not in GDD)
## Summon class a Tidecaller's Host Thrall rises as: the Spawn of the Deep
## class's kit (its Grasp: it seizes and holds a foe), bigger than a Thrall.
const HOST_CLASS: String = "spawn_of_the_deep"  # Proposal: "your Thralls rise as Spawns of the Deep"
## Most Drowned Thralls standing at once (the Tide Widow's innate adds to it).
const THRALL_MAX: int = 6  # TUNING (not in GDD)
## Most Tidecaller's Host Spawns standing at once (the innate adds to it too).
const HOST_MAX: int = 6  # TUNING (not in GDD)
## Damage-source tag and glyph of a Drowned Thrall (PassiveData.MINION_EXTRA_TAGS:
## a minion attack for crits; sprite summons/drowned_thrall_ally).
const THRALL_TAG: String = "drowned_thrall_ally"
## Damage-source tag of a Tidecaller's Host Spawn (PassiveData.MINION_EXTRA_TAGS).
const HOST_TAG: String = "tide_host_spawn"
## Glyph of a Tidecaller's Host Spawn: the Spawn of the Deep's art, drowned-tinted
## (SpireGlyphs.HOST_TINT), so it reads apart from the summon class's own units.
const HOST_GLYPH: String = "tide_spawn"
## Damage-source tags of the tendrils (base spell / evolution).
const SOURCE: String = "drowned_tendril"
## Damage-source tag of the evolved tendrils.
const HOST_SOURCE: String = "tide_tendril"
## Enemy kinds that never rise as the necromancer's Thralls (the Eye's own
## Thralls are already the dead).
const NEVER_RISE := ["drowned_thrall"]
## Seconds the tendril ring is drawn after it rises (drawing only).
const RISE_FX_TIME: float = 0.35  # TUNING (not in GDD) visual
