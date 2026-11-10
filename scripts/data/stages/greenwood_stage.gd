## GreenwoodStage — STAGE 43 (temporary and final stage 43), THE GREENWOOD
## (temporary Act XV, the Turning Year, final slot XV; GDD §15.0 "The Turning Year
## foundation (phase 1)"; design docs/proposals/LAST_SIX_ACTS.md section XV).
## An old forest that has never been cut. Every number and event that belongs to this stage.
## StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (phase 1). The stage is registered, unlocked in the
## campaign chain, runs the act's three shared rules ("wild": true: the Turning
## Year, Bloom and Blight, Overgrowth) and plays a simple timeline of the shared
## kinds (the season's own kinds join through the segments' "season_weights",
## the Winter Fae only in winter) against a PLACEHOLDER boss script (the "vael"
## boss script under The Stag King's name), with the Spring Returns Reckoning.
## It is hidden from the stage select ("playable": false) until phase 2 builds
## it: the sacred groves (rings of standing trees that heal the Wild; blighting one for 10 s kills it), the Huntsman of the Wild Hunt (the miniboss, three riders in a sweeping line) and the Stag King (the Hunt, the Rut, the Antler Crown).
## Planned zones (ZONES; clock-driven like every stage): The Glade, The Deep Wood, The Hunting Grounds and The Stag's Hollow.
## The Stag King arrives with 3:00 left in the dead of winter; the Reckoning at 0:00.
## Tuned for the act's FINAL slot XV (docs/last_acts/PLAN.md: the hardest act
## in the game), not its temporary number. Every rate, cap and weight is
## TUNING (not in GDD).
class_name GreenwoodStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "greenwood"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot XV is the hardest act: above the Age of Titans' 2.2; the step is in HP).
const ENEMY_HP_MULT: float = 2.4  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling
## (the Age of Titans' 1.4 and up).
const ENEMY_DAMAGE_MULT: float = 1.6  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to XIV (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 1 of the act

## The four zones phase 2 builds (names from the proposal), each from `start`
## game seconds. The stub has one placeholder floor.
const ZONES := [
	{"id": "glade", "name": "The Glade", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "deep_wood", "name": "The Deep Wood", "start": 300.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "hunting_grounds", "name": "The Hunting Grounds", "start": 600.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "stags_hollow", "name": "The Stag's Hollow", "start": 900.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
]

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): SPRING
## RETURNS (everything grows back at once and buries the dead: "kind" the
## Treant, its companions all of them; "spring_returns": WildRulesData.
## SPRING_RETURNS keys; {} = those defaults).
const RECKONING := {
	"banner": "SPRING RETURNS: EVERYTHING GROWS BACK",
	"kind": WildEnemyData.RECKONING_KIND,  # The shared Spring Returns heavy (the Treant).
	"spring_returns": {},  # WildRulesData.SPRING_RETURNS defaults (phase 2 may tune them here).
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
	"spring": {"treant": 0.03},  # TUNING (not in GDD)
	"summer": {"fae_knight": 0.06, "wild_rider": 0.015, "great_stag": 0.01},  # TUNING (not in GDD)
	"autumn": {"spore_mother": 0.05, "will_o_wisp": 0.05},  # TUNING (not in GDD)
	"winter": {"winter_fae": 0.12},  # TUNING (not in GDD) the Winter Court
}

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS, plus
## "season_weights": season id -> {kind: weight} added in that season through
## SeasonCycle.timeline_weights(), the one timeline helper): a plain ramp of
## the shared kinds (placeholder). The Winter Fae's row is winter only.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"thornling": 0.9, "dryad": 0.1},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The Greenwood: the world itself has come to take its dead back"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"thornling": 0.86, "dryad": 0.1, "will_o_wisp": 0.04},
		"season_weights": SEASON_WEIGHTS,
		"objective": "Spring: the roots grab whatever stands still for two seconds. Keep moving"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"thornling": 0.82, "dryad": 0.1, "will_o_wisp": 0.04, "treant": 0.04},
		"season_weights": SEASON_WEIGHTS,
		"objective": "Where your army stands, the ground dies into blight: the Wild cannot heal there"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"thornling": 0.78, "dryad": 0.1, "fae_knight": 0.08, "treant": 0.04},
		"season_weights": SEASON_WEIGHTS,
		"objective": "Summer: wildfires sweep the dry grass and burn the thickets. Step out of their path"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"thornling": 0.74, "dryad": 0.1, "fae_knight": 0.08, "spore_mother": 0.04, "treant": 0.04},
		"season_weights": SEASON_WEIGHTS,
		"objective": "Autumn: the dead rot in three seconds. Raise them fast"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"thornling": 0.72, "dryad": 0.1, "fae_knight": 0.1, "treant": 0.04, "spore_mother": 0.04},
		"season_weights": SEASON_WEIGHTS,
		"objective": "Winter: snow slows every step, and the Winter Court comes"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"thornling": 0.8, "dryad": 0.1, "fae_knight": 0.1},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The Stag King hunts you through the snow"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS).
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
	{"time": 780.0, "type": "wave", "banner": "Two Treants and their Dryads!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "treant", "count": 2, "elite": false}, {"kind": "dryad", "count": 3, "elite": false}]},
	{"time": 930.0, "type": "wave", "banner": "The Winter Court comes out of the snow!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "winter_fae", "count": 6, "elite": false}, {"kind": "fae_knight", "count": 4, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The Wild Hunt gathers before the Stag King!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "great_stag", "count": 1, "elite": false}, {"kind": "wild_rider", "count": 2, "elite": false}, {"kind": "thornling", "count": 12, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA): the normal scattered-obstacle
## arena; the thorn thickets grow into its empty cells (Thickets, through
## Arena.add_obstacle()). Placeholder kinds drawn by WildGlyphs until phase 2
## brings the stage's art.
const ARENA := {
	"density": 0.2,  # TUNING (not in GDD) (the thickets add more through the run)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 4343,  # TUNING (not in GDD)
	"kinds": {
		"wild_oak": {"weight": 0.6, "shape": "circle", "sizes": [14.0, 20.0]},  # TUNING (not in GDD) placeholder art (an old oak's trunk)
		"wild_stone": {"weight": 0.4, "shape": "rect", "sizes": [18.0, 26.0], "short": 12.0},  # TUNING (not in GDD) placeholder art (a mossy standing stone)
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script
## under The Stag King's name until phase 2 adds
## scripts/enemies/wild/boss_stag_king.gd (then remove the "script" key).
const BOSS := {
	"id": "stag_king",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_stag_king.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "The Stag King, Lord of the Greenwood",
	"short_name": "The Stag King",
	"arrive_banner": "The Stag King lowers his antlers in the dead of winter!",
	"defeat_banner": "The Stag King falls, and the Wild Hunt scatters! Hold out until the end...",
	"dead_objective": "The Stag King is dead. Spring is coming... endure.",
}

## Placeholder floor (WildGround, code-drawn) until phase 2 brings the stage's
## zone floors: base colour, line, accent, trim, style.
const FLOOR := {
	"style": "greenwood",  # moss, ferns and fallen leaves.
	"base": Color(0.12, 0.18, 0.10),  # TUNING (not in GDD)
	"line": Color(0.17, 0.25, 0.13),  # TUNING (not in GDD)
	"accent": Palette.WILD_MOSS,  # TUNING (not in GDD)
	"trim": Palette.WILD_BARK,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Greenwood",
	"short_name": "Greenwood",
	"chapter": "Chapter XLIII",  # Temporary and final stage 43 (the reorder pass renumbers if it moves).
	"act": 15,  # Temporary Act XV, the Turning Year (final slot XV; docs/last_acts/PLAN.md).
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "An old forest that has never been cut. The world remembers how to bury things, and it has come for your dead.",
	"unlock": {"stage": "last_day", "boss_kills": 1},  # Plan: defeating Old Gravejaw (the Age of Titans' finale) opens the Turning Year
	"unlock_text": "Defeat Old Gravejaw on the Last Day to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Wild stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ARENA,
	"ground": "wild",  # Placeholder WildGround until phase 2.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector) if it wants them.
	"wild": true,  # The Turning Year, Bloom and Blight, Overgrowth (WildRules).
	"seasons": {},  # This stage's year ({} = WildRulesData.SEASONS).
	"bloom": {},  # This stage's living ground ({} = WildRulesData.BLOOM).
	"thickets": {},  # This stage's thickets ({} = WildRulesData.THICKETS).
	"zones": ZONES,  # The planned zones (phase 2 builds them).
	# Music key: "wildwood" (the Turning Year's "The Turning Year", SoundData.WILDWOOD_SCORE; its sound pack "wild").
	"music": "wildwood",
}
