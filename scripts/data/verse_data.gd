## VerseData — immutable rule constants of the Forbidden Verse spell and its
## evolution The Unwritten Word (Act II, unlocked by slaying the Archivist;
## GDD §15.0 "Act II: the Hollow Archive", owner-approved proposal
## "Unlockable spells and passives"), and of its paired passive Marginalia.
## The per-level stat rows live in AbilityData.SPELLS["forbidden_verse"] and
## the evolution row in EvolutionData, like every spell; this file holds only
## the fixed rules the ForbiddenVerse node reads (geometry, caps, the inscribe
## mark) and the one list Marginalia multiplies. All numbers are TUNING (not
## in GDD). Data only.
class_name VerseData
extends RefCounted

## Contact radius (px) of one orbiting page (an enemy's body radius adds).
const PAGE_RADIUS: float = 8.0  # TUNING (not in GDD)
## Seconds a page sweep lasts (the pages swing out to SWEEP_REACH x their
## orbit and back, once per `cooldown`).
const SWEEP_TIME: float = 0.7  # TUNING (not in GDD)
## Orbit radius multiplier at the height of a sweep.
const SWEEP_REACH: float = 1.7  # TUNING (not in GDD)
## Most ink bursts waiting to be released at once (the rest are dropped).
const BURST_QUEUE_MAX: int = 48  # TUNING (not in GDD)
## The Unwritten Word: the deepest chain of bursts (each burst sets off at
## most `chain` more, EvolutionData; a chain never runs longer than this).
const CHAIN_MAX_DEPTH: int = 6  # TUNING (not in GDD)
## Damage-source tag of a page cut (base spell / evolution) and of an ink burst.
const SOURCE: String = "verse"
const SOURCE_EVOLVED: String = "unwritten_word"
const SOURCE_BURST: String = "ink_burst"

## Marginalia (PassiveData "marginalia"): every ON-DEATH effect hits harder.
## These are the damage sources of an effect a death releases, multiplied
## once by (1 + on_death_damage) in CombatResolver.damage_enemy() (the one
## path): Forbidden Verse's ink bursts, Corpse Explosion and Grave Eruption
## (corpses detonating), the Winter Revenant's frozen shatter, the Bone
## Colossus's bone shrapnel, Doom Brand's detonation, Soul Rapture's burst
## and the Legion of Bones' bone burst.
const MARGINALIA_SOURCES := ["ink_burst", "corpse", "eruption", "eruption_spikes", "winter_revenant_shatter",
	"colossus_shrapnel", "doom_burst", "rapture_burst", "legion_burst",
	# --- Act III: the Assembly Halls --- (a Puppet King's puppet bursting, PuppetData.BURST_SOURCE)
	"puppet_burst"]
## Passive id and level key of Marginalia.
const MARGINALIA: String = "marginalia"
const MARGINALIA_KEY: String = "on_death_damage"

# --- The look (drawing only) -----------------------------------------------------------

const PAGE_COLOR: Color = Color(0.93, 0.89, 0.76)  # TUNING (not in GDD) parchment
const INK_COLOR: Color = Color(0.48, 0.30, 0.86)  # TUNING (not in GDD) the necromancer's violet ink
const BURST_COLOR: Color = Color(0.30, 0.18, 0.55)  # TUNING (not in GDD)
