## MasteryData — designer-tunable data for the Ossuary's MASTERIES (Ossuary
## expansion step 4, owner decision Oct 2026, GDD §15.0 "Ossuary Masteries"):
## a small permanent bonus for ONE summon class, bought with Soul Ash. Data
## only, no logic beyond tiny lookups.
##
## Shape (one for every class): 3 levels, each +MasteryData.HP_PER_LEVEL max HP
## and +MasteryData.DAMAGE_PER_LEVEL damage for that class's summons only
## (temporary summons of the class included; a Profane Bishop counts as the
## better of Mender and Warder, an evolved form as its base class). The bonus
## is its own multiplier category (GDD §6.4) read by the one summon-stat path:
## MetaModifiers.mastery_value() -> HordeDirector.compute_stats().
##
## Unlock rule: a class's mastery opens for purchase once the player has taken
## that class to level MasteryData.UNLOCK_LEVEL (5) in any run (Meta
## [class_lv5]); older saves are filled from the summon evolutions they have
## already found (each needs its base class at Lv 5). Masteries are bought one
## level at a time (Meta [masteries]); there are no difficulty gates.
##
## Price: PRICES per level, the same for every class: 190 + 250 + 320 = 760, and
## 17 classes make 12,920 in all (the owner's budget: about 13,000). On a good
## Necromancer run (about 877 Soul Ash) that is about 15 runs.
class_name MasteryData
extends RefCounted

## Levels of a mastery (every class).
const MAX_LEVEL: int = 3  # TUNING (not in GDD) owner brief: 3 levels
## Class level a run must have reached to open that class's mastery.
const UNLOCK_LEVEL: int = 5  # TUNING (not in GDD) owner brief: "level 5 in any run"
## Soul Ash price of level 1, 2, 3 (index = level - 1; ints >= 1).
const PRICES: Array[int] = [190, 250, 320]  # TUNING (not in GDD) 760 a class (20 classes with the Archfiend = 15,200)
## Max HP bonus per level (fraction: 0.02 = +2% per level, +6% at level 3).
const HP_PER_LEVEL: float = 0.02  # TUNING (not in GDD) modest, one shape for all classes; was 0.04, trimmed by the balance batch
## Damage bonus per level (fraction: 0.02 = +2% per level, +6% at level 3).
const DAMAGE_PER_LEVEL: float = 0.02  # TUNING (not in GDD) modest, one shape for all classes; was 0.04, trimmed by the balance batch

## Every class that has a mastery, in tile order (UnitData ids). The evolved-only
## Profane Bishop has none of its own; it uses BASES_OF below.
const CLASSES: Array[String] = [
	"warrior", "archer", "mage", "mender", "warder",
	"abomination", "rogue", "gargoyle", "frost_wraith",
	"bone_hound", "banshee", "corpse_catapult",
	"fallen_seraph", "spawn_of_the_deep", "bone_golem", "grave_drone", "iron_revenant",
	"myrmidon_shade",
	# --- Act V: the Shogunate of the Rising Sun ---
	"bound_oni",
	# --- Act VI: Pandemonium ---
	"archfiend",
]  # TUNING (not in GDD) every offerable summon class of all five acts

## Evolved-only class -> the classes whose mastery it uses (the best level
## counts: the Profane Bishop is a Mender and a Warder in one).
const BASES_OF := {
	"bishop": ["mender", "warder"],
}  # TUNING (not in GDD)

## One short flavour line per class (the detail line under the tiles). The
## numbers are the shared shape; these only name what the class does best.
const FLAVOUR := {
	"warrior": "Shields that hold a little longer.",
	"archer": "A steadier hand on the string.",
	"mage": "The grave-fire burns hotter.",
	"mender": "Hands that mend and still bite.",
	"warder": "Wards backed by sturdier bones.",
	"abomination": "More flesh stitched on.",
	"rogue": "Blades that know the throat.",
	"gargoyle": "Stone that cracks later.",
	"frost_wraith": "A colder, harder chill.",
	"bone_hound": "A pack that bites deeper.",
	"banshee": "A wail with more behind it.",
	"corpse_catapult": "Heavier stones, thicker timber.",
	"fallen_seraph": "Grace fallen, not forgotten.",
	"spawn_of_the_deep": "The deep gives up more of itself.",
	"bone_golem": "Older bone, harder to break.",
	"grave_drone": "Salvaged plating, tuned guns.",
	"iron_revenant": "Rust made into resolve.",
	"myrmidon_shade": "A shade that remembers the phalanx.",
	"bound_oni": "An oni that remembers its chains.",  # TUNING (not in GDD) Act V's class
	# --- Act VI: Pandemonium ---
	"archfiend": "A demon that kneels only to you.",  # TUNING (not in GDD) Act VI's finale class
}  # TUNING (not in GDD) flavour only

## Autotest profile "max" owns every level of every mastery; "none" and "mid"
## own none (the measured Soul Ash economy was taken at "mid", so it stays put).
const MAX_PROFILE: String = "max"  # TUNING (not in GDD)


## True when `cls` has its own mastery (a CLASSES entry).
static func is_masterable(cls: String) -> bool:
	return cls in CLASSES


## Soul Ash price of level `level` (1-based; -1 when out of range).
static func price(level: int) -> int:
	if level < 1 or level > MAX_LEVEL:
		return -1
	return PRICES[level - 1]


## Soul Ash spent on levels 1..`level` of one class (clamped to 0..MAX_LEVEL).
static func cost_up_to(level: int) -> int:
	var total := 0
	for l in range(1, clampi(level, 0, MAX_LEVEL) + 1):
		total += PRICES[l - 1]
	return total


## Price of every level of every class.
static func total_cost() -> int:
	return CLASSES.size() * cost_up_to(MAX_LEVEL)


## Max HP bonus fraction at mastery level `level`.
static func hp_bonus(level: int) -> float:
	return HP_PER_LEVEL * float(clampi(level, 0, MAX_LEVEL))


## Damage bonus fraction at mastery level `level`.
static func damage_bonus(level: int) -> float:
	return DAMAGE_PER_LEVEL * float(clampi(level, 0, MAX_LEVEL))


## Class id -> mastery level for an autotest profile (see MAX_PROFILE).
static func autotest_levels(profile: String) -> Dictionary:
	var out := {}
	if profile == MAX_PROFILE:
		for cls: String in CLASSES:
			out[cls] = MAX_LEVEL
	return out
