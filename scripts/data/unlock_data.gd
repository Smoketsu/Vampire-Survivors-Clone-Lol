## UnlockData — level-up items that must be UNLOCKED before a run offers them
## (GDD §15.0 "Act II: the Ancient Eye", owner-approved "Unlockable spells and
## passives"): Act II's three abyssal spells (each unlocked by slaying one of
## the act's bosses), its two counter-passives (each earned by an Act II
## achievement) and the two new summon classes. An id absent here is always
## open, so every Act I item, and a fresh save's card pool, is exactly as
## before. Unlocks are kept in the Meta [unlocks] save section
## (MetaProgress.unlocked_items), read through the ONE helper Unlocks.is_open(),
## and announced by an end-screen unlock plate; the Codex shows a locked item
## as a silhouette naming its unlock (`text`).
## Keys of a row:
##   type        — "spell" (AbilityData), "passive" (PassiveData) or "class"
##                 (UnitData): which card table the id belongs to.
##   boss        — boss script id (StageRegistry.BOSS_ARRIVALS): slaying it in
##                 any run unlocks the item; or
##   achievement — MetaData.ACHIEVEMENTS id: earning it unlocks the item.
##   text        — the unlock condition, for the Codex and the plate.
## Act-only items (offered only on one act's stages) are marked by their own
## card row's "act" key (PassiveData / AbilityData / UnitData), not here.
## Rows are added by each Act II stage as its items are built.
class_name UnlockData
extends RefCounted

## Item id -> unlock row (keys above).
const UNLOCKS := {
	# --- Act II: the Hollow Archive ---
	"forbidden_verse": {"type": "spell", "boss": "archivist", "text": "Slay the Archivist in the Hollow Archive to unlock."},  # Owner-approved proposal
	"marginalia": {"type": "passive", "boss": "archivist", "text": "Slay the Archivist in the Hollow Archive to unlock."},  # Forbidden Verse's paired passive, unlocked with it
	"iron_mind": {"type": "passive", "achievement": "nothing_unwritten", "text": "Earn Nothing Unwritten: burn every forbidden tome in one Hollow Archive run."},  # Owner-approved proposal
}

## End-screen plate heading of a newly unlocked item, by type.
const PLATE_HEADINGS := {
	"spell": "Spell unlocked",  # TUNING (not in GDD)
	"passive": "Passive unlocked",  # TUNING (not in GDD)
	"class": "Summon unlocked",  # TUNING (not in GDD)
}
