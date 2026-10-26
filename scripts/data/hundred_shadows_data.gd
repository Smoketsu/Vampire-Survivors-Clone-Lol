## HundredShadowsData — the fixed rules of the Hundred Shadows spell and its
## evolution Thousand Shadows (Act V, the Burning Province; owner-approved Act
## V proposal "Rewards": "Hundred Shadows: shadow clones of the necromancer that
## echo your next spell cast -> Thousand Shadows (+ Hidden Hand)"; GDD §15.0
## "Hundred Shadows, Hidden Hand and the Grave Kunoichi (Act V)"). The levelled
## numbers live in AbilityData.SPELLS "hundred_shadows" and
## EvolutionData.EVOLUTIONS "thousand_shadows"; these are the rules that do not
## level, and the one list of what counts as a SPELL hit (is_spell_source():
## the echo's trigger and Hidden Hand's test). Logic: HundredShadows. Data only
## (CLAUDE.md rule 2) but for the cached source set.
class_name HundredShadowsData
extends RefCounted

## AbilityData id of the spell.
const ID: String = "hundred_shadows"
## Damage source tag of the clones' shadow kunai (the base spell).
const SOURCE: String = "hundred_shadows"
## Damage source tag of the evolved clones' kunai and bursts (Thousand Shadows).
const EVOLVED_SOURCE: String = "thousand_shadows"
## Damage sources of the base spells cast by AbilityManager (Shadow Bolt and
## Void Barrage, the Orb Shield and Eclipse Ward, Shadow Blast and Abyssal
## Detonation, the Voidcaller's echo); every
## NecroSpellBook spell's sources join them (NecroSpellBook.SOURCES).
const BASE_SOURCES := ["bolt", "void", "orb", "eclipse", "blast", "abyss", "echo"]  # The base spells' stat tags (AbilityManager, OrbShield, the Voidcaller's echo)
## Seconds before the first clones once the spell is learned.
const FIRST_SPLIT: float = 0.8  # TUNING (not in GDD)
## px from the necromancer the clones stand (they follow him at their posts).
const POST_RADIUS: float = 58.0  # TUNING (not in GDD)
## Seconds between two echoes of one clone (an evolved clone echoes several
## times; a burst of damage-over-time ticks cannot spend them all at once).
const ECHO_GAP: float = 0.3  # TUNING (not in GDD)
## Seconds a shadow kunai flies from its clone to its target.
const FLIGHT: float = 0.16  # TUNING (not in GDD)
## Most clones at once (with the Grave Kunoichi's innate on top of the evolution).
const MAX_CLONES: int = 8  # TUNING (not in GDD)
## Most kunai in flight at once.
const MAX_KUNAI: int = 32  # TUNING (not in GDD)
## The clones' shadow tint over the necromancer's sprite (drawing only).
const TINT := Color(0.30, 0.24, 0.48, 0.72)  # TUNING (not in GDD) violet-black
## The kunai's streak (the player's violet; drawing only).
const GLOW := Color(0.64, 0.36, 0.98)  # TUNING (not in GDD) Palette.VIOLET

## Cached set of every spell source (built on first use from BASE_SOURCES and
## NecroSpellBook.SOURCES; the clones' own sources are left out).
static var _spell_sources: Dictionary = {}


## True when damage tagged `source` is one of the necromancer's spells (not a
## summon's blow, a hazard or Hundred Shadows' own kunai): the echo's trigger
## and Hidden Hand's test.
static func is_spell_source(source: String) -> bool:
	if _spell_sources.is_empty():
		for s: String in BASE_SOURCES:
			_spell_sources[s] = true
		for id: String in NecroSpellBook.SOURCES:
			for s: String in NecroSpellBook.SOURCES[id]:
				_spell_sources[s] = true
		_spell_sources.erase(SOURCE)
		_spell_sources.erase(EVOLVED_SOURCE)
	return _spell_sources.has(source)
