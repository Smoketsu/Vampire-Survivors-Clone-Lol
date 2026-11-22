## GlamourData — immutable rule constants of the GLAMOUR spell, its evolution
## Court of Masks, its paired passive Changeling and the Changeling Princess's
## innate (temporary Act XV, the Fae Court; GDD §15.0 "Glamour, Court of Masks,
## Changeling and the Changeling Princess"; owner-approved proposal "Rewards":
## "The Summer Queen | Glamour: illusory copies of the necromancer draw enemy
## attacks -> Court of Masks (+ Changeling) | The Changeling Princess (female,
## figure style)"; unlocked by slaying the Summer Queen). Its per-level stat rows
## live in AbilityData.SPELLS and its evolution row in EvolutionData, like every
## spell; this file holds only the fixed rules the spell node (Glamour) reads,
## the passive's id and keys and the innate key. Data only.
class_name GlamourData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "glamour"
## Evolution id (EvolutionData).
const EVOLUTION_ID: String = "court_of_masks"
## Damage-source tag of a copy's shattering (the base spell).
const SOURCE: String = "glamour"
## Damage-source tag of an evolved copy's shattering (Court of Masks).
const EVOLVED_SOURCE: String = "court_of_masks"
## Summon class a copy is raised as (HordeDirector.spawn_temporary(): the
## Warrior's body and blocking, its own HP share, no blows of its own).
const COPY_CLASS: String = "warrior"
## Prefix of a copy's glyph kind (SummonedUnit.glyph_kind = GLYPH_PREFIX + the
## caster's sprite key: Glyphs.draw_summon() draws the caster's own art in the
## glamour's tint).
const GLYPH_PREFIX: String = "glamour:"
## px from the necromancer the copies stand (round him, turning with each cast).
const POST_RADIUS: float = 70.0  # TUNING (not in GDD) inside the Bone Ring's 60-150 px
## Seconds a copy's own blows wait: longer than any copy lives, so it never strikes.
const NO_BLOWS: float = 999.0  # TUNING (not in GDD)
## Most copies standing at once (the innate and the evolution included).
const MAX_COPIES: int = 8  # TUNING (not in GDD)
## Pitch of the cast sound (a startup-bank sound: the spell plays on every stage).
const CAST_PITCH: float = 1.25  # TUNING (not in GDD)
## The copies' glamour (the necromancer's own art in pale violet light,
## half seen; never true gold). Visual only.
const TINT := Color(0.86, 0.74, 1.0, 0.62)  # TUNING (not in GDD) visual only
## The shattering's colour (a burst of violet-pink glass). Visual only.
const SHATTER := Color(0.95, 0.70, 0.95)  # TUNING (not in GDD) visual only

# --- Changeling (the paired passive) ---
## Passive id of Changeling (PassiveData, UnlockData).
const CHANGELING: String = "changeling"
## Its level-row key: s more each copy lasts.
const LIFE_KEY: String = "copy_life"
## Its level-row key: share more HP on every copy (0..1).
const HP_KEY: String = "copy_hp"

# --- The Changeling Princess's innate: Many Faces (Glamour) ---
## Innate value key: copies more in every cast (CharacterData
## "changeling_princess"; 0 for every other character).
const INNATE_KEY: String = "glamour_copies"
