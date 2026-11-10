## GreenwoodStage — STAGE 43 (temporary and final stage 43), THE GREENWOOD
## (temporary Act XV, the Turning Year, final slot XV; GDD §15.0 "The Turning Year
## foundation (phase 1)"; design docs/proposals/LAST_SIX_ACTS.md section XV).
## An old forest that has never been cut. Every number and event that belongs to this stage.
## StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
##
## STATUS: BUILT (phase 2), playable. Unlocked in the campaign chain (Old
## Gravejaw's fall on the Last Day opens it); it runs the act's three shared
## rules ("wild": true: the Turning Year, Bloom and Blight, Overgrowth) and its
## own systems (GreenwoodDirector, STAGE "greenwood"): THE SACRED GROVES (rings
## of standing trees that heal the Wild inside them; blighting one for 10 s
## kills it for the run), THE HUNTSMAN OF THE WILD HUNT (the miniboss, at 11:40,
## leading three riders in a sweeping line) and SCORCHED EARTH (the stage's
## achievement). Its boss is the Stag King (BossStagKing: the Hunt, the Rut, the
## Antler Crown). Spring Returns is its Reckoning.
## Zones (ZONES; clock-driven, MarchDirector): the Glade, the Deep Wood, the
## Hunting Grounds and the Stag's Hollow.
## The Stag King arrives with 3:00 left in the dead of winter; the Reckoning at 0:00.
## Tuned for the act's FINAL slot XV (docs/last_acts/PLAN.md: the hardest act
## in the game; as its first stage, the easiest of its three, above the Age of
## Titans), not its temporary number. Every rate, cap and weight is
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
const ENEMY_HP_MULT: float = 2.2  # TUNING (not in GDD) phase 2 (the stub's 2.4, a first pass 2.3: the naive bot died on seeds 3, 7 and 11 at about 10:00): the Titans' 2.2, the shared kinds' specials, the groves and the Huntsman are the step up
## Enemy damage multiplier of this stage on top of the shared time scaling
## (the Age of Titans' 1.4 and up).
const ENEMY_DAMAGE_MULT: float = 1.4  # TUNING (not in GDD) phase 2 (the stub's 1.6, first passes 1.5 and 1.45: the naive bot died on every seed, the army bot on seed 3): the Titans' 1.4; the shared kinds' specials, the groves and the Huntsman are the step up
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to XIV (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 1 of the act

## The obstacle kinds every zone shares (two sizes each: the Turning Year art's
## obstacles/<kind>_s / _l, WildGlyphs without art; the thorn thickets grow
## into the empty cells, Thickets through Arena.add_obstacle()):
##   wild_oak   — an old oak's trunk (circle of 14 / 20 px; art 40x40).
##   wild_stone — a mossy standing stone (rect 18 / 26 x 12 px; art 52x30, `_v`).
## Only the weights and the density change by zone.

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven, MarchDirector): its floor look ("ground": a
## GreenwoodGround style, the zone's floor tile tiles/greenwood_<style>, else
## the act's tiles/wild_greenwood) and its obstacle layout ("arena"):
##   glade           — the Glade: open moss and ferns under old oaks.
##   deep_wood       — the Deep Wood: the oaks close in (the densest zone).
##   hunting_grounds — the Hunting Grounds: wide clearings for the Hunt.
##   stags_hollow    — the Stag's Hollow: standing stones in a frosted hollow.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Glade", "id": "glade",  # Owner-approved proposal (zones)
		"blurb": "Open moss under oaks no axe has ever touched",
		"ground": {"style": "glade", "base": Color(0.12, 0.18, 0.10), "line": Color(0.17, 0.25, 0.13),
			"accent": Palette.WILD_MOSS, "trim": Palette.WILD_BARK},  # TUNING (not in GDD)
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 4343,  # TUNING (not in GDD)
			"kinds": {"wild_oak": {"weight": 0.65, "shape": "circle", "sizes": [14.0, 20.0]},
				"wild_stone": {"weight": 0.35, "shape": "rect", "sizes": [18.0, 26.0], "short": 12.0}}}},  # TUNING (not in GDD)
	{"start": 300.0, "numeral": "II", "name": "The Deep Wood", "id": "deep_wood",  # Owner-approved proposal (zones)
		"blurb": "The oaks close in, and the light goes green",
		"ground": {"style": "deep_wood", "base": Color(0.09, 0.14, 0.08), "line": Color(0.13, 0.20, 0.10),
			"accent": Palette.WILD_MOSS_DARK, "trim": Palette.WILD_BARK},  # TUNING (not in GDD)
		"arena": {"density": 0.24, "clear_radius": 220.0, "layout_seed": 4353,  # TUNING (not in GDD) the densest zone
			"kinds": {"wild_oak": {"weight": 0.8, "shape": "circle", "sizes": [14.0, 20.0]},
				"wild_stone": {"weight": 0.2, "shape": "rect", "sizes": [18.0, 26.0], "short": 12.0}}}},  # TUNING (not in GDD)
	{"start": 600.0, "numeral": "III", "name": "The Hunting Grounds", "id": "hunting_grounds",  # Owner-approved proposal (zones)
		"blurb": "Wide clearings where the Wild Hunt rides",
		"ground": {"style": "hunting_grounds", "base": Color(0.14, 0.17, 0.10), "line": Color(0.20, 0.23, 0.13),
			"accent": Palette.WILD_GOLD_LEAF, "trim": Palette.WILD_BARK},  # TUNING (not in GDD)
		"arena": {"density": 0.13, "clear_radius": 220.0, "layout_seed": 4363,  # TUNING (not in GDD) open ground for the sweeps
			"kinds": {"wild_oak": {"weight": 0.5, "shape": "circle", "sizes": [14.0, 20.0]},
				"wild_stone": {"weight": 0.5, "shape": "rect", "sizes": [18.0, 26.0], "short": 12.0}}}},  # TUNING (not in GDD)
	{"start": 900.0, "numeral": "IV", "name": "The Stag's Hollow", "id": "stags_hollow",  # Owner-approved proposal (zones)
		"blurb": "A hollow of standing stones, where the Stag King waits",
		"ground": {"style": "stags_hollow", "base": Color(0.13, 0.16, 0.12), "line": Color(0.19, 0.22, 0.17),
			"accent": Palette.WILD_FROST, "trim": Palette.WILD_ASH},  # TUNING (not in GDD)
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 4373,  # TUNING (not in GDD)
			"kinds": {"wild_stone": {"weight": 0.6, "shape": "rect", "sizes": [18.0, 26.0], "short": 12.0},
				"wild_oak": {"weight": 0.4, "shape": "circle", "sizes": [14.0, 20.0]}}}},  # TUNING (not in GDD)
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 220.0,  # TUNING (not in GDD)
	"zone_title": "THE GREENWOOD  -  %s",  # TUNING (not in GDD)
	"zone_color": Color(0.62, 0.86, 0.50),  # Moss green (Palette.WILD_MOSS's light): never the player's true gold.
	"fog_color": Color(0.07, 0.10, 0.06),  # Forest shade.
	"fog_bank_color": Color(0.60, 0.70, 0.58),  # Forest mist.
	"zones": ZONES,
}

## The Greenwood's stage systems (GreenwoodDirector; StageRegistry "greenwood"):
##   grove_cell    — px of one grove cell (each holds at most one grove).
##   grove_salt    — the cell hash's salt.
##   grove_chance  — 0..1 that a cell holds a grove.
##   grove_margin  — px a grove's ring keeps from its cell's border.
##   grove_radius  — px, a grove's ring (its trees stand on it; the heal and
##                   the blight read inside it).
##   grove_clear   — px round the arena's centre that never holds a grove.
##   grove_trees   — trees drawn on a grove's ring (drawing only).
##   grove_tree_art — sprite key of a grove tree (WildGlyphs-like discs until it exists).
##   grove_every   — s between two grove checks.
##   grove_heal    — share of max HP a second a living grove heals each Wild
##                   kind inside it (on top of the living ground's heal).
##   grove_blight  — 0..1 mean blight over a grove that counts as blighted.
##   grove_kill    — s a grove must stay blighted in a row to die.
##   grove_banner  — banner when a grove dies.
##   scorched_area — blight cells the Greenwood counts as its whole (Scorched
##                   Earth: a blight peak of half of it).
##   scorched_banner — banner of Scorched Earth.
##   huntsman_objective — HUD objective while the Huntsman rides.
const GREENWOOD := {
	"grove_cell": 900.0,  # TUNING (not in GDD) px
	"grove_salt": 4343,  # TUNING (not in GDD)
	"grove_chance": 0.45,  # TUNING (not in GDD)
	"grove_margin": 40.0,  # TUNING (not in GDD) px
	"grove_radius": 120.0,  # TUNING (not in GDD) px
	"grove_clear": 320.0,  # TUNING (not in GDD) px
	"grove_trees": 7,  # Owner-approved proposal: "rings of standing trees"; TUNING (not in GDD) the count
	"grove_tree_art": "obstacles/wild_grove_tree",  # docs/year/ART_MANIFEST.md (phase 2 art)
	"grove_every": 0.5,  # TUNING (not in GDD) s
	"grove_heal": 0.01,  # Owner-approved proposal: "heal the Wild inside them"; TUNING (not in GDD) share of max HP a second (first pass 0.02: the Treants piled up, seed 3)
	"grove_blight": 0.6,  # TUNING (not in GDD) 0..1
	"grove_kill": 10.0,  # Owner-approved proposal: "holding the ring in it for 10 s"
	"grove_banner": "A sacred grove withers under your army: it heals the Wild no more!",  # TUNING (not in GDD)
	"scorched_area": 1400,  # TUNING (not in GDD) blight cells (a 64 px cell): half is 700, under BloomField's 900-cell cap
	"scorched_banner": "SCORCHED EARTH: half the Greenwood lies dead under your army!",  # TUNING (not in GDD)
	"huntsman_objective": "The Huntsman of the Wild Hunt leads his riders in a line: step out of it, then bring him down",  # TUNING (not in GDD)
}

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
	"spring": {"treant": 0.02},  # TUNING (not in GDD) (the stub's 0.03: the Treants piled up, seed 3)
	"summer": {"fae_knight": 0.06, "wild_rider": 0.01, "great_stag": 0.01},  # TUNING (not in GDD) (the stub's riders 0.015: their sweeps were the naive bot's killer)
	"autumn": {"spore_mother": 0.03, "will_o_wisp": 0.05},  # TUNING (not in GDD) (the stub's spore mothers 0.05: with their spores, 14-17 alive rotted the whole ring, seed 11)
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
		"weights": {"thornling": 0.82, "dryad": 0.1, "will_o_wisp": 0.04, "treant": 0.025},
		"season_weights": SEASON_WEIGHTS,
		"objective": "Where your army stands, the ground dies into blight: the Wild cannot heal there"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"thornling": 0.78, "dryad": 0.1, "fae_knight": 0.08, "treant": 0.025},
		"season_weights": SEASON_WEIGHTS,
		"objective": "Summer: wildfires sweep the dry grass and burn the thickets. Step out of their path"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"thornling": 0.74, "dryad": 0.1, "fae_knight": 0.08, "spore_mother": 0.025, "treant": 0.025},
		"season_weights": SEASON_WEIGHTS,
		"objective": "Autumn: the dead rot in three seconds. Raise them fast"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"thornling": 0.72, "dryad": 0.1, "fae_knight": 0.1, "treant": 0.025, "spore_mother": 0.025},
		"season_weights": SEASON_WEIGHTS,
		"objective": "Winter: snow slows every step, and the Winter Court comes"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"thornling": 0.8, "dryad": 0.1, "fae_knight": 0.1},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The Stag King hunts you through the snow"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Plus the
## Greenwood's own (GreenwoodDirector):
##   "huntsman" — the Huntsman of the Wild Hunt (kind `kind`) comes in
##                huntsman_dist px ahead of the necromancer; he brings his
##                three riders himself (HuntsmanKit); the stage miniboss.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A swarm of Thornlings crawls out of the undergrowth!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "thornling", "count": 12, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "Dryads plant thorn seeds round you: kill them first!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "dryad", "count": 3, "elite": false}, {"kind": "thornling", "count": 12, "elite": false}]},
	{"time": 200.0, "type": "wave", "banner": "A Treant wakes: its branches root what they strike!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "treant", "count": 1, "elite": false}, {"kind": "thornling", "count": 12, "elite": false}]},
	{"time": 330.0, "type": "wave", "banner": "The Fae Knights blink through your ring: keep blockers inside it!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "fae_knight", "count": 5, "elite": false}, {"kind": "dryad", "count": 2, "elite": false}]},
	{"time": 480.0, "type": "wave", "banner": "The Wild Hunt sweeps past: step out of the riders' lines!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "wild_rider", "count": 1, "elite": false}, {"kind": "great_stag", "count": 1, "elite": false}]},  # The stub's two riders: with their hounds (phase 2) seven hunters at once killed the naive bot
	{"time": 640.0, "type": "wave", "banner": "Will-o'-Wisps lure your dead away, and Spore Mothers rot them!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "will_o_wisp", "count": 6, "elite": false}, {"kind": "spore_mother", "count": 3, "elite": false}]},
	{"time": 700.0, "type": "huntsman", "banner": "THE HUNTSMAN OF THE WILD HUNT! He leads three riders in a sweeping line: step out of it!",  # Owner-approved proposal (miniboss); 8:20 left
		"kind": GreenwoodEnemyData.HUNTSMAN, "huntsman_dist": 300.0, "elite": false},  # TUNING (not in GDD) px ahead of the necromancer
	{"time": 760.0, "type": "wave", "banner": "Corpse-Blooms open in the leaves: they feed on the dead. Break them!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "corpse_bloom", "count": 2, "elite": false}, {"kind": "thornling", "count": 12, "elite": false}]},
	{"time": 820.0, "type": "wave", "banner": "Two Treants and their Dryads!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "treant", "count": 2, "elite": false}, {"kind": "dryad", "count": 3, "elite": false}]},
	{"time": 930.0, "type": "wave", "banner": "The Winter Court comes out of the snow: their bolts chill your dead!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "winter_fae", "count": 6, "elite": false}, {"kind": "fae_knight", "count": 4, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The Wild Hunt gathers before the Stag King!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "great_stag", "count": 1, "elite": false}, {"kind": "thornling", "count": 12, "elite": false}]},
]

## The Stag King's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "stag_king"). His script is
## scripts/enemies/wild/boss_stag_king.gd (loaded by his id); his numbers are
## StagKingData's.
const BOSS := {
	"id": "stag_king",
	"time": BOSS_TIME,
	"display_name": "The Stag King, Lord of the Greenwood",
	"short_name": "The Stag King",
	"arrive_banner": "The Stag King lowers his antlers in the dead of winter!",
	"defeat_banner": "The Stag King falls, and the Wild Hunt scatters! Hold out until the end...",
	"dead_objective": "The Stag King is dead. Spring is coming... endure.",
}

## Placeholder floor of the foundation stub (WildGround "floor" key), kept for
## the other tools that read it; the stage draws GreenwoodGround ("ground").
const FLOOR := {
	"style": "greenwood",  # moss, ferns and fallen leaves.
	"base": Color(0.12, 0.18, 0.10),  # TUNING (not in GDD)
	"line": Color(0.17, 0.25, 0.13),  # TUNING (not in GDD)
	"accent": Palette.WILD_MOSS,  # TUNING (not in GDD)
	"trim": Palette.WILD_BARK,  # TUNING (not in GDD)
}

## This stage's thorn thickets (any key of WildRulesData.THICKETS): the act's
## first stage grows a gentler maze (phase 1's balance flag: the stub's army run
## filled the 30-thicket cap, the spread the main source).
const THICKETS := {
	"cap": 24,  # TUNING (not in GDD) (the default 30)
	"spread_every": 60.0,  # TUNING (not in GDD) s (the default 45)
}

## This stage's living ground (any key of WildRulesData.BLOOM): the act's first
## stage heals the Wild more gently (phase 2: at the default 1% a second the
## naive bot's small army never brought down a Treant, a Fae Knight or a Great
## Stag, and was overrun at about 12:00 on seeds 3, 7 and 11).
const BLOOM := {
	"heal": 0.006,  # TUNING (not in GDD) share of max HP a second (the default 0.01)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Greenwood",
	"short_name": "Greenwood",
	"chapter": "Chapter XLIII",  # Temporary and final stage 43 (the reorder pass renumbers if it moves).
	"act": 15,  # Temporary Act XV, the Turning Year (final slot XV; docs/last_acts/PLAN.md).
	"playable": true,  # Phase 2 built (GDD §15.0 "The Greenwood (Act XV phase 2)").
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
	"arena": ZONES[0]["arena"],
	"ground": "greenwood",  # GreenwoodGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"greenwood": GREENWOOD,  # GreenwoodDirector: the sacred groves, the Huntsman, Scorched Earth.
	"wild": true,  # The Turning Year, Bloom and Blight, Overgrowth (WildRules).
	"seasons": {},  # This stage's year ({} = WildRulesData.SEASONS).
	"bloom": BLOOM,  # This stage's living ground: a gentler heal than the default (the act's first stage).
	"thickets": THICKETS,  # This stage's thickets: gentler than the defaults (the act's first stage).
	"zones": ZONES,  # The four zones.
	# Music key: "wildwood" (the Turning Year's "The Turning Year", SoundData.WILDWOOD_SCORE; its sound pack "wild").
	"music": "wildwood",
}
