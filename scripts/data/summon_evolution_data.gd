## SummonEvolutionData — immutable design data for the summon evolutions (user
## request; GDD §4.2 / §6.1 name one evolution per summon class). Runtime
## logic lives in SummonEvolutions (owned by HordeDirector).
##
## Recipes (user rules, recorded in GDD §15.0):
##   Skeleton Warrior Lv 5 + Dark Command Lv 5        = Death Knight
##       (GDD "Dreadguard Legion"; the user named it Death Knight)
##   Undead Mage Lv 5      + Forbidden Knowledge Lv 5 = Lich
##       (GDD "Lich Conclave")
##   Grave Mender Lv 5 + Crypt Warder Lv 5 + Dark Benediction Lv 5
##                                                     = Profane Bishop
##       (GDD §4.2 priest evolution; the split priest classes MERGE into one)
## Owner rule: every evolution, spell or summon, needs its paired passive at
## Lv 5 (EvolutionData.PASSIVE_LEVEL_REQUIRED); `passive_level` below is 5
## for every recipe.
##
## Delivery is the same as the spell evolutions (EvolutionData): once a recipe
## holds and the run has reached EvolutionData.MIN_ELAPSED (8:00), the next
## treasure chest grants it first (AbilityManager.ready_evolutions() /
## chest_rewards() include these ids). Evolutions never appear on level-up
## cards.
##
## Two modes:
##   "transform" — the base class keeps its id, slot, level and capacity; its
##                 stats get the evolution overlay below and every existing
##                 unit transforms in place (full heal + transformation FX).
##                 Its card / HUD / slot identity becomes the evolution's.
##   "merge"     — every base class is removed (level 0, never offered again,
##                 its active slot is freed) and the `result` class takes
##                 over at RESULT_LEVEL. Existing units convert in place up to
##                 the result's capacity; the rest dissolve into it.
## All numbers are TUNING (not in GDD) unless tagged otherwise.
class_name SummonEvolutionData
extends RefCounted

## Display / check order of the summon evolutions.
const ORDER := ["death_knight", "lich", "profane_bishop"]

## Summon skill level every base class needs (user rule: Lv 5).
const BASE_LEVEL_REQUIRED: int = 5  # TUNING (not in GDD) user rule
## Skill level the merged result class is created at (its LEVELS table has
## a single row; this keeps it "maxed" for synergies, cards and the HUD).
const RESULT_LEVEL: int = 5  # TUNING (not in GDD)
## Seconds each unit shows its transformation glow.
const TRANSFORM_FX_TIME: float = 1.2  # TUNING (not in GDD)

## Evolution definitions.
##   mode          — "transform" | "merge" (see header).
##   bases         — base class ids (UnitData.CLASS_ORDER) that must all be at
##                   BASE_LEVEL_REQUIRED.
##   passive       — paired passive id (PassiveData.PASSIVES key).
##   passive_level — passive level required (5 = max, 1 = owned).
##   result        — "merge" only: the class id that replaces the bases.
##   display_name  — UI name (singular), plural — UI name (plural).
##   icon          — IconGlyph kind of the evolved class (SummonGlyphs).
##   description   — card / banner text.
##   mult          — "transform" only: effective-stat key -> multiplier
##                   (its own stacking category, GDD §6.4).
##   set           — "transform" only: effective-stat key -> absolute value.
## Death Knight keys (SummonAbilities.after_melee):
##   cleave_radius   — px around the struck enemy; other enemies inside take
##                     cleave_fraction of the hit (source "death_knight_cleave").
##   lifesteal       — fraction of all melee damage dealt healed back.
##   engaged_speed_mult — enemies touching a Death Knight move this slowly
##                     (the "dread" of its presence; a slow, not a fear, so
##                     enemies still always advance, GDD §15.0).
## Lich keys:
##   raise — the raise-the-dead effect (SummonEvolutions.on_enemy_killed):
##     chance     — expected raises per Lich kill (deterministic accumulator,
##                  no RNG: every 1/chance kills one foe rises),
##     class      — summon class of the risen skeleton (base stats, no evolution),
##     duration   — s a risen skeleton lasts before it crumbles,
##     hp_mult / damage_mult — multipliers on that class's current stats,
##     max_alive  — at most this many risen skeletons at once.
const EVOLUTIONS := {
	"death_knight": {
		"mode": "transform",
		"bases": ["warrior"],
		"passive": "dark_command",
		"passive_level": 5,  # TUNING (not in GDD) user rule: Dark Command at max level
		"display_name": "Death Knight",
		"plural": "Death Knights",
		"icon": "death_knight",
		"description": "Your warriors rise as armoured Death Knights: cleaving blows, life drain and a dread wall foes cannot pass.",
		"mult": {
			"max_hp": 1.5,  # TUNING (not in GDD)
			"damage": 1.35,  # TUNING (not in GDD)
			"bash_damage": 2.0,  # TUNING (not in GDD)
		},
		"set": {
			"radius": 12.0,  # TUNING (not in GDD) bigger silhouette
			"block_radius": 15.0,  # TUNING (not in GDD) <= UnitData.MAX_BLOCK_RADIUS
			"block_mass": 5.0,  # TUNING (not in GDD) warriors are 3
			"engaged_speed_mult": 0.45,  # TUNING (not in GDD) warriors are 0.6
			"bash_cooldown": 1.5,  # TUNING (not in GDD) warriors are 2.0
			"bash_knockback": 220.0,  # TUNING (not in GDD) warriors are 160
			"cleave_radius": 32.0,  # TUNING (not in GDD)
			"cleave_fraction": 0.5,  # TUNING (not in GDD)
			"lifesteal": 0.12,  # TUNING (not in GDD)
		},
	},
	"lich": {
		"mode": "transform",
		"bases": ["mage"],
		"passive": "forbidden_knowledge",
		"passive_level": 5,  # TUNING (not in GDD) user rule: Forbidden Knowledge maxed
		"display_name": "Lich",
		"plural": "Liches",
		"icon": "lich",
		"description": "Your mages ascend as Liches: deadlier blasts, sturdier bodies, and the foes they slay rise as skeletons.",
		"mult": {
			"max_hp": 1.4,  # TUNING (not in GDD)
			# Combined balance pass: 1.35 (on top of Forbidden Knowledge's +40% damage and +25%
			# splash) left Liches at 29% of all damage in the summon build, up to 45% in one
			# run (plus 12% from the mages before they evolved).
			"damage": 1.2,  # TUNING (not in GDD) was 1.35; 1.5 made Liches 36% of all damage in the summon build
			# Combined balance pass: 1.25 -> 1.0. With Grave Dominion a summon build fields up
			# to 8 Liches, and splash width decides who lands the kills (Forbidden Knowledge
			# still adds up to +25%).
			"splash_radius": 1.0,  # TUNING (not in GDD) was 1.25
			# Combined balance pass: 0.85 (casts 15% faster) -> 1.0. Strong summon builds kill
			# everything that spawns, so the damage cut alone barely moved the Lich's share
			# (its splash lands most kills first: 37% of all damage, up to 43%); fewer casts
			# land fewer of them.
			"attack_interval": 1.0,  # TUNING (not in GDD) was 0.85
		},
		"set": {
			"radius": 11.0,  # TUNING (not in GDD)
		},
		"raise": {
			"chance": 0.2,  # TUNING (not in GDD)
			"class": "warrior",  # TUNING (not in GDD)
			"duration": 12.0,  # TUNING (not in GDD)
			"hp_mult": 0.6,  # TUNING (not in GDD)
			"damage_mult": 0.8,  # TUNING (not in GDD)
			"max_alive": 6,  # TUNING (not in GDD)
		},
	},
	"profane_bishop": {
		"mode": "merge",
		"bases": ["mender", "warder"],
		"passive": "dark_benediction",
		"passive_level": 5,  # TUNING (not in GDD) owner rule: Dark Benediction at max level (was 1, owned)
		"result": "bishop",
		"display_name": "Profane Bishop",  # GDD §4.2
		"plural": "Bishops",
		"icon": "profane_bishop",
		"description": "Menders and Warders merge into Profane Bishops: stronger heals, wards and barriers, a healing aura that burns foes, and one free active slot.",
	},
}
