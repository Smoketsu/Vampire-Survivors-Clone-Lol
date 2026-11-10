## WorldTreeStage — STAGE 45 (temporary and final stage 45), THE WORLD-TREE
## (temporary Act XV, the Turning Year, its finale and the campaign finale, final slot XV; GDD §15.0 "The World-Tree
## (Act XV phase 2)"; design docs/proposals/LAST_SIX_ACTS.md section XV).
## The tree at the centre of the world, its roots in the dead and its crown in the sky; all four seasons, twice. Every number and event that belongs to this stage.
## StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
##
## STATUS: BUILT (phase 2), playable. Unlocked in the campaign chain (the Summer
## Queen's fall at the Fae Court opens it); it runs the act's three shared rules
## ("wild": true: the Turning Year, twice as fast here, STAGE "seasons" length
## 150; Bloom and Blight; Overgrowth) and its own systems (WorldTreeDirector,
## STAGE "world_tree"): THE GARDENER OF ROOTS (the miniboss, at 11:20, who calls
## every root in reach in any season). Its boss is the Green Mother
## (BossGreenMother: the Turning, the Burial, THE LAST CLAIM, LastClaim). Its
## Reckoning is Spring Returns, or, with the Green Mother beaten before 0:00, THE
## FIRST SPRING (RECKONING "first_spring", WildRules.first_spring: the planted
## dead rise to the necromancer and the campaign ends in victory).
## Zones (ZONES; clock-driven, MarchDirector): the Roots, the Trunk Stair, the
## Crown and the Seed.
## The Green Mother arrives with 3:00 left; the Reckoning at 0:00.
## Tuned for the act's FINAL slot XV (docs/last_acts/PLAN.md: the hardest act
## in the game; its finale, the hardest stage), not its temporary number. Every
## rate, cap and weight is TUNING (not in GDD).
class_name WorldTreeStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "world_tree"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot XV is the hardest act: above the Age of Titans' 2.2; the step is in HP).
const ENEMY_HP_MULT: float = 2.3  # TUNING (not in GDD) phase 2 (the stub's 2.6: the naive bot died at ~8:30): the Fae Court's 2.2 and up; the Gardener, the Turning, the Burial and the Last Claim are the step up
## Enemy damage multiplier of this stage on top of the shared time scaling
## (the Age of Titans' 1.4 and up).
const ENEMY_DAMAGE_MULT: float = 1.45  # TUNING (not in GDD) phase 2 (the stub's 1.8): the Fae Court's 1.4 and up
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to XIV (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 3 of the act

## The obstacle kinds the zones share (the Turning Year art's obstacles/<kind>_s /
## _l, or _m for a one-size kind; WildGlyphs without art; the thorn thickets grow
## into the empty cells, Thickets through Arena.add_obstacle()):
##   wild_great_root — a great root of the tree (rect, one size: 92 x 22 px;
##                     art 96x28, `_m` and `_m_v`).
##   wild_oak        — an old oak's trunk (circle of 14 / 20 px; art 40x40).
##   wild_stone      — a mossy standing stone (rect 18 / 26 x 12 px; art 52x30, `_v`).
## Only the weights and the density change by zone.

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven, MarchDirector): its floor look ("ground": a
## WorldTreeGround style, the zone's floor tile tiles/world_tree_<style>, else
## the act's tiles/wild_tree) and its obstacle layout ("arena"):
##   roots       — the Roots: great roots of the tree across dark soil (the densest).
##   trunk_stair — the Trunk Stair: bark ledges climbing the trunk.
##   crown       — the Crown: branches and leaves high in the sky.
##   seed        — the Seed: the heart of the tree, where the Green Mother waits.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Roots", "id": "roots",  # Owner-approved proposal (zones)
		"blurb": "The tree's roots run through the dead of every age",
		"ground": {"style": "roots", "base": Color(0.11, 0.12, 0.09), "line": Color(0.20, 0.16, 0.11),
			"accent": Palette.WILD_MOSS, "trim": Palette.WILD_BARK},  # TUNING (not in GDD)
		"arena": {"density": 0.15, "clear_radius": 220.0, "layout_seed": 4545,  # TUNING (not in GDD) the densest zone
			"kinds": {"wild_great_root": {"weight": 0.5, "shape": "rect", "sizes": [46.0], "short": 11.0},
				"wild_oak": {"weight": 0.5, "shape": "circle", "sizes": [14.0, 20.0]}}}},  # TUNING (not in GDD)
	{"start": 300.0, "numeral": "II", "name": "The Trunk Stair", "id": "trunk_stair",  # Owner-approved proposal (zones)
		"blurb": "Ledges of bark climbing the great trunk",
		"ground": {"style": "trunk_stair", "base": Color(0.15, 0.12, 0.09), "line": Color(0.24, 0.18, 0.12),
			"accent": Palette.WILD_GOLD_LEAF, "trim": Palette.WILD_BARK},  # TUNING (not in GDD)
		"arena": {"density": 0.13, "clear_radius": 220.0, "layout_seed": 4555,  # TUNING (not in GDD)
			"kinds": {"wild_great_root": {"weight": 0.4, "shape": "rect", "sizes": [46.0], "short": 11.0},
				"wild_stone": {"weight": 0.3, "shape": "rect", "sizes": [18.0, 26.0], "short": 12.0},
				"wild_oak": {"weight": 0.3, "shape": "circle", "sizes": [14.0, 20.0]}}}},  # TUNING (not in GDD)
	{"start": 600.0, "numeral": "III", "name": "The Crown", "id": "crown",  # Owner-approved proposal (zones)
		"blurb": "Branches wide as roads, and leaves that turn with every season",
		"ground": {"style": "crown", "base": Color(0.13, 0.16, 0.10), "line": Color(0.19, 0.23, 0.13),
			"accent": Palette.WILD_BLOSSOM, "trim": Palette.WILD_MOSS},  # TUNING (not in GDD)
		"arena": {"density": 0.12, "clear_radius": 220.0, "layout_seed": 4565,  # TUNING (not in GDD) open boughs
			"kinds": {"wild_oak": {"weight": 0.6, "shape": "circle", "sizes": [14.0, 20.0]},
				"wild_great_root": {"weight": 0.4, "shape": "rect", "sizes": [46.0], "short": 11.0}}}},  # TUNING (not in GDD)
	{"start": 900.0, "numeral": "IV", "name": "The Seed", "id": "seed",  # Owner-approved proposal (zones)
		"blurb": "The heart of the tree, where the whole year sleeps in one seed",
		"ground": {"style": "seed", "base": Color(0.14, 0.13, 0.10), "line": Color(0.22, 0.19, 0.13),
			"accent": Palette.WILD_FROST, "trim": Palette.WILD_GOLD_LEAF},  # TUNING (not in GDD)
		"arena": {"density": 0.12, "clear_radius": 240.0, "layout_seed": 4575,  # TUNING (not in GDD) room for her fight
			"kinds": {"wild_great_root": {"weight": 0.5, "shape": "rect", "sizes": [46.0], "short": 11.0},
				"wild_stone": {"weight": 0.5, "shape": "rect", "sizes": [18.0, 26.0], "short": 12.0}}}},  # TUNING (not in GDD)
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 220.0,  # TUNING (not in GDD)
	"zone_title": "THE WORLD-TREE  -  %s",  # TUNING (not in GDD)
	"zone_color": Color(0.70, 0.88, 0.55),  # Living green (GreenMotherData.BLOOM's kin): never the player's true gold.
	"fog_color": Color(0.08, 0.09, 0.07),  # Deep bark shade.
	"fog_bank_color": Color(0.74, 0.82, 0.66),  # Pollen and frost haze.
	"zones": ZONES,
}

## The World-Tree's stage systems (WorldTreeDirector; StageRegistry "world_tree"):
##   gardener_objective — HUD objective while the Gardener of Roots lives.
const WORLD_TREE := {
	"gardener_objective": "The Gardener of Roots calls every root in reach, in any season: keep moving near him, and bring him down",  # TUNING (not in GDD)
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): SPRING
## RETURNS (everything grows back at once and buries the dead: "kind" the
## Treant, its companions all of them; "spring_returns": WildRulesData.
## SPRING_RETURNS keys; {} = those defaults), or, with the Green Mother beaten
## before 0:00, THE FIRST SPRING ("first_spring": WildRulesData.FIRST_SPRING
## keys; {} = those defaults: the planted dead rise and the run ends in victory).
const RECKONING := {
	"banner": "SPRING RETURNS: EVERYTHING GROWS BACK",
	"kind": WildEnemyData.RECKONING_KIND,  # The shared Spring Returns heavy (the Treant).
	"spring_returns": {},  # WildRulesData.SPRING_RETURNS defaults.
	"first_spring": {},  # WildRulesData.FIRST_SPRING defaults (the ending: only with the Green Mother beaten).
	"companions": WildEnemyData.RECKONING_COMPANIONS,  # Thornlings, Dryads, Fae Knights.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 1,  # TUNING (not in GDD) Treants
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "SPRING RETURNS: the year turns back to its start and the earth buries your dead. Endure."

## Each season's own kinds, added to every segment's weights in that season
## (owner-approved proposal, "Who comes": spring thornlings, dryads, treants;
## summer fae knights, the Wild Hunt; autumn spore mothers, wisps,
## corpse-blooms (not in the trickle: a structure); winter the Winter Court).
const SEASON_WEIGHTS := {
	"spring": {"treant": 0.012},  # TUNING (not in GDD) (the stub's 0.03: 135 Treants, the army bot's worst foe, seed 7)
	"summer": {"fae_knight": 0.04, "wild_rider": 0.006, "great_stag": 0.006},  # TUNING (not in GDD) (the stub's 0.06 / 0.015 / 0.01)
	"autumn": {"spore_mother": 0.05, "will_o_wisp": 0.05},  # TUNING (not in GDD)
	"winter": {"winter_fae": 0.12},  # TUNING (not in GDD) the Winter Court
}

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS, plus
## "season_weights": season id -> {kind: weight} added in that season through
## SeasonCycle.timeline_weights(), the one timeline helper): a ramp of the
## shared kinds, each season's own joining in turn (twice a year here). The
## Winter Fae's row is winter only.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"thornling": 0.9, "dryad": 0.1},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The World-Tree: the year turns twice as fast here"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"thornling": 0.86, "dryad": 0.1, "will_o_wisp": 0.04},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The roots grab whatever stands still in spring. Keep moving"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"thornling": 0.84, "dryad": 0.1, "will_o_wisp": 0.04, "treant": 0.015},
		"season_weights": SEASON_WEIGHTS,
		"objective": "Where your army stands, the ground dies into blight: the Wild cannot heal there"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"thornling": 0.82, "dryad": 0.1, "fae_knight": 0.05, "treant": 0.015},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The Trunk Stair: every season comes twice as fast"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"thornling": 0.79, "dryad": 0.1, "fae_knight": 0.05, "spore_mother": 0.025, "treant": 0.015},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The Crown: in autumn the dead rot in three seconds. Raise them fast"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"thornling": 0.77, "dryad": 0.1, "fae_knight": 0.06, "treant": 0.015, "spore_mother": 0.025},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The Seed: the year turns for the last time"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"thornling": 0.85, "dryad": 0.15},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The Green Mother remembers every power that ever claimed the dead"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Plus the
## World-Tree's own (WorldTreeDirector):
##   "gardener" — the Gardener of Roots (kind `kind`) comes in gardener_dist px
##                ahead of the necromancer; the stage miniboss.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A swarm of Thornlings crawls out of the undergrowth!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "thornling", "count": 12, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "Dryads plant thorn seeds round you: kill them first!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "dryad", "count": 3, "elite": false}, {"kind": "thornling", "count": 12, "elite": false}]},
	{"time": 200.0, "type": "wave", "banner": "A Treant wakes!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "treant", "count": 1, "elite": false}, {"kind": "thornling", "count": 12, "elite": false}]},
	{"time": 330.0, "type": "wave", "banner": "The Fae Knights ride out of the summer wood!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "fae_knight", "count": 5, "elite": false}, {"kind": "dryad", "count": 2, "elite": false}]},
	{"time": 480.0, "type": "wave", "banner": "The Wild Hunt sweeps past!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "wild_rider", "count": 2, "elite": false}, {"kind": "great_stag", "count": 1, "elite": false}]},
	{"time": 640.0, "type": "wave", "banner": "Will-o'-Wisps and Spore Mothers drift through the falling leaves!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "will_o_wisp", "count": 6, "elite": false}, {"kind": "spore_mother", "count": 3, "elite": false}]},
	{"time": 680.0, "type": "gardener", "banner": "THE GARDENER OF ROOTS wakes! Near him the roots grab in every season!",  # Owner-approved proposal (miniboss); 8:40 left
		"kind": WorldTreeEnemyData.GARDENER, "gardener_dist": 300.0, "elite": false},  # TUNING (not in GDD) px ahead of the necromancer
	{"time": 800.0, "type": "wave", "banner": "A Treant and its Dryads climb the trunk!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "treant", "count": 1, "elite": false}, {"kind": "dryad", "count": 3, "elite": false}]},
	{"time": 930.0, "type": "wave", "banner": "The Winter Court comes out of the snow!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "winter_fae", "count": 6, "elite": false}, {"kind": "fae_knight", "count": 4, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "Every creature of the Wild gathers before the Green Mother!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "great_stag", "count": 1, "elite": false}, {"kind": "wild_rider", "count": 2, "elite": false}, {"kind": "thornling", "count": 12, "elite": false}]},
]

## The Green Mother's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "green_mother"). Her script is
## scripts/enemies/wild/boss_green_mother.gd (loaded by her id); her numbers are
## GreenMotherData's.
const BOSS := {
	"id": "green_mother",
	"time": BOSS_TIME,
	"display_name": "The Green Mother",
	"short_name": "The Green Mother",
	"arrive_banner": "The Green Mother wakes in the World-Tree!",
	"defeat_banner": "The Green Mother sinks into the roots, and gives you the last claim! Hold out until spring...",
	"dead_objective": "The Green Mother has given you the last claim. Endure until spring.",
}

## Placeholder floor of the foundation stub (WildGround "floor" key), kept for
## the other tools that read it; the stage draws WorldTreeGround ("ground").
const FLOOR := {
	"style": "tree",  # great roots, bark and leaf litter.
	"base": Color(0.13, 0.15, 0.10),  # TUNING (not in GDD)
	"line": Color(0.22, 0.17, 0.11),  # TUNING (not in GDD)
	"accent": Palette.WILD_GOLD_LEAF,  # TUNING (not in GDD)
	"trim": Palette.WILD_BARK,  # TUNING (not in GDD)
}

## This stage's thorn thickets (any key of WildRulesData.THICKETS): the act's
## cap, spreading a little slower (the World-Tree's maze without walling the
## ring in).
const THICKETS := {
	"cap": 28,  # TUNING (not in GDD) (the default 30)
	"spread_every": 50.0,  # TUNING (not in GDD) s (the default 45)
}

## This stage's living ground (any key of WildRulesData.BLOOM): the Fae Court's
## gentler heal (the act's 1% overran the naive bot).
const BLOOM := {
	"heal": 0.006,  # TUNING (not in GDD) share of max HP a second (the default 0.01)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The World-Tree",
	"short_name": "World-Tree",
	"chapter": "Chapter XLV",  # Temporary and final stage 45 (the reorder pass renumbers if it moves).
	"act": 15,  # Temporary Act XV, the Turning Year (final slot XV; docs/last_acts/PLAN.md).
	"playable": true,  # Phase 2 built (GDD §15.0 "The World-Tree (Act XV phase 2)").
	"description": "The tree at the centre of the world. Its roots are in the dead, its crown in the sky, and the Green Mother grows from it.",
	"unlock": {"stage": "fae_court", "boss_kills": 1},  # Plan: each stage opens the next
	"unlock_text": "Defeat the Summer Queen at the Fae Court to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Wild stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ZONES[0]["arena"],
	"ground": "world_tree",  # WorldTreeGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"world_tree": WORLD_TREE,  # WorldTreeDirector: the Gardener of Roots.
	"wild": true,  # The Turning Year, Bloom and Blight, Overgrowth (WildRules).
	"seasons": {"length": 150.0},  # This stage's year ({} = WildRulesData.SEASONS the World-Tree: the year turns twice as fast, owner-approved proposal "2:30 a season").
	"bloom": BLOOM,  # This stage's living ground.
	"thickets": THICKETS,  # This stage's thickets.
	"zones": ZONES,  # The four zones.
	# Music key: "wildwood" (the Turning Year's "The Turning Year", SoundData.WILDWOOD_SCORE; its sound pack "wild").
	"music": "wildwood",
}
