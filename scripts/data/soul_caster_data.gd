## SoulCasterData — immutable rule constants of the Soul Caster spell, its
## evolution Apex Predator, its paired passive Trophy Rack and the Blooded's
## innate (Act IX, the Proving Moon; GDD §15.0 "Soul Caster, Apex Predator,
## Trophy Rack and the Blooded (Act IX)"; owner-approved proposal: "Soul
## Caster: a shoulder cannon that locks three targets with three red dots and
## fires -> Apex Predator (+ Trophy Rack)"; brief: the dots are in the spell's
## own soul colour, not the Vrask's red; unlocked by slaying Vrask'Tal). Its
## per-level stat rows live in AbilityData.SPELLS and its evolution row in
## EvolutionData, like every spell; this file holds only the fixed rules the
## spell node (SoulCaster) reads and the passive's ids and keys. Data only.
class_name SoulCasterData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData). Never an enemy kind, a structure,
## a source tag or a Concord sound / rule name.
const ID: String = "soul_caster"
## Damage-source tag of the base spell's shots.
const SOURCE: String = "soul_caster"
## Damage-source tag of the evolved shots (Apex Predator).
const EVOLVED_SOURCE: String = "apex_predator"
## The spell's own soul colour: its lock dots and its shot (never the Vrask's
## red / magenta lock, so a player never mistakes his lock for a hunter's).
const SOUL_COLOR := Color(0.36, 0.94, 0.86)  # TUNING (not in GDD) the necromancer's soul-teal light
## Px each of a target's three lock dots sits from its centre (a triangle).
const DOT_SPREAD: float = 6.0  # TUNING (not in GDD)
## Px radius of a lock dot (drawn).
const DOT_RADIUS: float = 2.0  # TUNING (not in GDD)
## Seconds a fired shot's line stays drawn (drawn only).
const SHOT_FADE: float = 0.18  # TUNING (not in GDD)
## Seconds a cast waits before trying again when no target stands in range.
const WAIT_RETRY: float = 0.3  # TUNING (not in GDD)
## Px the shot leaves from above the caster's shoulder (drawn only).
const SHOULDER: Vector2 = Vector2(-6.0, -18.0)  # TUNING (not in GDD)

# --- Trophy Rack (the paired passive) ---
## Passive id of Trophy Rack (PassiveData, UnlockData).
const TROPHY_RACK: String = "trophy_rack"
## Its level-row key: share (0..1) more Soul Caster damage per trophy.
const TROPHY_DMG_KEY: String = "trophy_dmg"
## Its level-row key: most trophies that count.
const TROPHY_CAP_KEY: String = "trophy_cap"

# --- The Blooded's innate: First Blood (Soul Caster) ---
## Innate value key: extra targets each Soul Caster lock takes (CharacterData
## "blooded"; 0 for every other character).
const EXTRA_TARGETS_KEY: String = "soul_caster_extra_targets"
