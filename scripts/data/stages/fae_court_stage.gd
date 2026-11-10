## FaeCourtStage — STAGE 44 (temporary and final stage 44), THE FAE COURT
## (temporary Act XV, the Turning Year, final slot XV; GDD §15.0 "The Turning Year
## foundation (phase 1)"; design docs/proposals/LAST_SIX_ACTS.md section XV).
## A court of endless summer under a sky that never sets. Every number and event that belongs to this stage.
## StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
##
## STATUS: BUILT (phase 2), playable. Unlocked in the campaign chain (the Stag
## King's fall in the Greenwood opens it); it runs the act's three shared rules
## ("wild": true: the Turning Year, Bloom and Blight, Overgrowth) and its own
## systems (FaeCourtDirector, STAGE "fae_court"): THE ENDLESS SUMMER (the year
## held at Summer the whole run through SeasonCycle.set_override(), its
## wildfires spaced out by STAGE "seasons" "wildfire_every"), THE FAIRY RINGS
## (mushroom circles where time runs at half speed for whatever is inside, both
## armies), THE WINTER PRINCE (the miniboss, at 11:40, with his one minute of
## winter) and A FAIR BARGAIN (the stage's achievement). Its boss is the Summer
## Queen (BossSummerQueen: the Masque, the Bargain, the Court in Bloom). Spring
## Returns is its Reckoning.
## Zones (ZONES; clock-driven, MarchDirector): the Rose Maze, the Revel, the
## Mirror Lake and the Throne of Blossoms.
## The Summer Queen arrives with 3:00 left, in her own summer; the Reckoning at 0:00.
## Tuned for the act's FINAL slot XV (docs/last_acts/PLAN.md: the hardest act
## in the game; its second stage, a little harder than the Greenwood), not its
## temporary number. Every rate, cap and weight is TUNING (not in GDD).
class_name FaeCourtStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "fae_court"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot XV is the hardest act: the Greenwood's 2.2 and up; the step is in HP).
const ENEMY_HP_MULT: float = 2.3  # TUNING (not in GDD) phase 2 (the stub's 2.5): a little over the Greenwood's 2.2
## Enemy damage multiplier of this stage on top of the shared time scaling
## (the Greenwood's 1.4 and up).
const ENEMY_DAMAGE_MULT: float = 1.45  # TUNING (not in GDD) phase 2 (the stub's 1.7): a little over the Greenwood's 1.4
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to XIV (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 2 of the act

## The obstacle kinds the zones share (the Turning Year art's obstacles/<kind>_s /
## _l, or _m for a one-size kind; WildGlyphs without art; the thorn thickets grow
## into the empty cells, Thickets through Arena.add_obstacle()):
##   wild_rose_hedge — a rose-maze hedge segment (rect, one size: 92 x 24 px;
##                     art 96x32, `_m` and `_m_v`).
##   wild_oak        — an old oak's trunk (circle of 14 / 20 px; art 40x40).
##   wild_stone      — a mossy standing stone (rect 18 / 26 x 12 px; art 52x30, `_v`).
## Only the weights and the density change by zone.

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven, MarchDirector): its floor look ("ground": a
## FaeCourtGround style, the zone's floor tile tiles/fae_court_<style>, else
## the act's tiles/wild_fae) and its obstacle layout ("arena"):
##   rose_maze          — the Rose Maze: rose hedges close the lanes (the densest zone).
##   revel              — the Revel: open lawns where the court dances.
##   mirror_lake        — the Mirror Lake: standing stones on a still, pale shore.
##   throne_of_blossoms — the Throne of Blossoms: hedges and stones round her court.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Rose Maze", "id": "rose_maze",  # Owner-approved proposal (zones)
		"blurb": "Hedges of roses that never wilt, and lanes that close behind you",
		"ground": {"style": "rose_maze", "base": Color(0.13, 0.17, 0.11), "line": Color(0.18, 0.24, 0.14),
			"accent": Palette.WILD_BLOSSOM, "trim": Palette.WILD_MOSS_DARK},  # TUNING (not in GDD)
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 4444,  # TUNING (not in GDD) the densest zone
			"kinds": {"wild_rose_hedge": {"weight": 0.7, "shape": "rect", "sizes": [46.0], "short": 12.0},
				"wild_oak": {"weight": 0.3, "shape": "circle", "sizes": [14.0, 20.0]}}}},  # TUNING (not in GDD)
	{"start": 300.0, "numeral": "II", "name": "The Revel", "id": "revel",  # Owner-approved proposal (zones)
		"blurb": "Open lawns where the court dances under a sun that never sets",
		"ground": {"style": "revel", "base": Color(0.15, 0.18, 0.11), "line": Color(0.21, 0.25, 0.14),
			"accent": Palette.WILD_GOLD_LEAF, "trim": Palette.WILD_BLOSSOM},  # TUNING (not in GDD)
		"arena": {"density": 0.13, "clear_radius": 220.0, "layout_seed": 4454,  # TUNING (not in GDD) open lawns
			"kinds": {"wild_oak": {"weight": 0.5, "shape": "circle", "sizes": [14.0, 20.0]},
				"wild_rose_hedge": {"weight": 0.3, "shape": "rect", "sizes": [46.0], "short": 12.0},
				"wild_stone": {"weight": 0.2, "shape": "rect", "sizes": [18.0, 26.0], "short": 12.0}}}},  # TUNING (not in GDD)
	{"start": 600.0, "numeral": "III", "name": "The Mirror Lake", "id": "mirror_lake",  # Owner-approved proposal (zones)
		"blurb": "A still lake that shows every face but your own",
		"ground": {"style": "mirror_lake", "base": Color(0.12, 0.16, 0.15), "line": Color(0.17, 0.22, 0.21),
			"accent": Palette.WILD_FROST, "trim": Palette.WILD_MOSS},  # TUNING (not in GDD)
		"arena": {"density": 0.15, "clear_radius": 220.0, "layout_seed": 4464,  # TUNING (not in GDD)
			"kinds": {"wild_stone": {"weight": 0.6, "shape": "rect", "sizes": [18.0, 26.0], "short": 12.0},
				"wild_rose_hedge": {"weight": 0.4, "shape": "rect", "sizes": [46.0], "short": 12.0}}}},  # TUNING (not in GDD)
	{"start": 900.0, "numeral": "IV", "name": "The Throne of Blossoms", "id": "throne_of_blossoms",  # Owner-approved proposal (zones)
		"blurb": "Her court of roses, where the Summer Queen waits",
		"ground": {"style": "throne_of_blossoms", "base": Color(0.15, 0.15, 0.12), "line": Color(0.22, 0.20, 0.16),
			"accent": Palette.WILD_BLOSSOM, "trim": Palette.WILD_GOLD_LEAF},  # TUNING (not in GDD)
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 4474,  # TUNING (not in GDD)
			"kinds": {"wild_rose_hedge": {"weight": 0.6, "shape": "rect", "sizes": [46.0], "short": 12.0},
				"wild_stone": {"weight": 0.4, "shape": "rect", "sizes": [18.0, 26.0], "short": 12.0}}}},  # TUNING (not in GDD)
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 220.0,  # TUNING (not in GDD)
	"zone_title": "THE FAE COURT  -  %s",  # TUNING (not in GDD)
	"zone_color": Color(0.98, 0.70, 0.82),  # Blossom pink (Palette.WILD_BLOSSOM's light): never the player's true gold.
	"fog_color": Color(0.10, 0.09, 0.08),  # Summer dusk shade.
	"fog_bank_color": Color(0.86, 0.74, 0.80),  # Pink pollen haze.
	"zones": ZONES,
}

## The Fae Court's stage systems (FaeCourtDirector; StageRegistry "fae_court"):
##   summer_until   — game s the endless summer holds (the run's end: Spring
##                    Returns then takes the year).
##   summer_banner  — banner when the summer comes back after the Winter Prince's minute.
##   ring_cell      — px of one fairy-ring cell (each holds at most one ring).
##   ring_salt      — the cell hash's salt.
##   ring_chance    — 0..1 that a cell holds a ring.
##   ring_margin    — px a ring keeps from its cell's border.
##   ring_radius    — px, a ring's radius (inside it time runs at half speed).
##   ring_clear     — px round the arena's centre that never holds a ring.
##   ring_every     — s between two ring checks.
##   ring_slow      — 0..1 the move slow inside a ring (both armies).
##   ring_linger    — s a slow lasts after a check (to the next check and a little more).
##   ring_mushrooms — mushrooms drawn on a ring (drawing only).
##   ring_art       — tile key of a fairy ring's patch (disc textures until it exists).
##   prince_objective — HUD objective while the Winter Prince's winter holds.
const FAE_COURT := {
	"summer_until": WaveData.RUN_DURATION,  # Owner-approved proposal: "a court of endless summer under a sky that never sets"
	"summer_banner": "The Winter Prince's minute is over: the endless summer returns.",  # TUNING (not in GDD)
	"ring_cell": 640.0,  # TUNING (not in GDD) px
	"ring_salt": 4444,  # TUNING (not in GDD)
	"ring_chance": 0.5,  # TUNING (not in GDD)
	"ring_margin": 30.0,  # TUNING (not in GDD) px
	"ring_radius": 80.0,  # TUNING (not in GDD) px
	"ring_clear": 260.0,  # TUNING (not in GDD) px
	"ring_every": 0.25,  # TUNING (not in GDD) s
	"ring_slow": 0.5,  # Owner-approved proposal: "time runs at half speed for whatever is inside, both armies" (the move speed; see GDD §15.0 "The Fae Court")
	"ring_linger": 0.35,  # TUNING (not in GDD) s
	"ring_mushrooms": 12,  # TUNING (not in GDD) drawing only
	"ring_art": "tiles/wild_fairy_ring",  # docs/year/ART_MANIFEST.md (phase 2 art)
	"prince_objective": "The Winter Prince brings a minute of winter into the summer: bring him down",  # TUNING (not in GDD)
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): SPRING
## RETURNS (everything grows back at once and buries the dead: "kind" the
## Treant, its companions all of them; "spring_returns": WildRulesData.
## SPRING_RETURNS keys; {} = those defaults).
const RECKONING := {
	"banner": "SPRING RETURNS: EVERYTHING GROWS BACK",
	"kind": WildEnemyData.RECKONING_KIND,  # The shared Spring Returns heavy (the Treant).
	"spring_returns": {},  # WildRulesData.SPRING_RETURNS defaults.
	"companions": WildEnemyData.RECKONING_COMPANIONS,  # Thornlings, Dryads, Fae Knights.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 1,  # TUNING (not in GDD) Treants
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "SPRING RETURNS: the endless summer breaks and the earth buries your dead. Endure."

## Each season's own kinds, added to every segment's weights in that season
## (owner-approved proposal, "Who comes": summer the fae knights and the Wild
## Hunt, winter the Winter Court). The Fae Court is summer all run but for the
## Winter Prince's minute, so only these two seasons come.
const SEASON_WEIGHTS := {
	"summer": {"fae_knight": 0.07, "wild_rider": 0.008, "great_stag": 0.008},  # TUNING (not in GDD) the court's knights
	"winter": {"winter_fae": 0.15},  # TUNING (not in GDD) the Winter Court comes with its prince
}

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS, plus
## "season_weights": season id -> {kind: weight} added in that season through
## SeasonCycle.timeline_weights(), the one timeline helper).
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"thornling": 0.9, "dryad": 0.1},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The Fae Court: endless summer, and every face a mask"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"thornling": 0.86, "dryad": 0.1, "will_o_wisp": 0.04},
		"season_weights": SEASON_WEIGHTS,
		"objective": "Fairy rings: time runs at half speed inside the mushroom circles, for both armies"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"thornling": 0.82, "dryad": 0.1, "will_o_wisp": 0.04, "treant": 0.02},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The summer never ends here: wildfires sweep the lawns. Step out of their path"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"thornling": 0.78, "dryad": 0.1, "will_o_wisp": 0.03, "treant": 0.02},
		"season_weights": SEASON_WEIGHTS,
		"objective": "Where your army stands, the ground dies into blight: the Wild cannot heal there"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"thornling": 0.74, "dryad": 0.1, "spore_mother": 0.02, "treant": 0.02, "will_o_wisp": 0.03},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The Mirror Lake: the court's knights blink through your ring. Keep blockers inside it"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"thornling": 0.72, "dryad": 0.1, "treant": 0.025, "spore_mother": 0.025},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The Throne of Blossoms: the Summer Queen is near"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"thornling": 0.85, "dryad": 0.15},
		"season_weights": SEASON_WEIGHTS,
		"objective": "The Summer Queen holds court"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Plus the Fae
## Court's own (FaeCourtDirector):
##   "winter_prince" — the Winter Prince (kind `kind`) comes in prince_dist px
##                     ahead of the necromancer and brings one minute of winter
##                     (his row's winter_time); the stage miniboss.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A swarm of Thornlings crawls out of the rose hedges!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "thornling", "count": 12, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "Dryads plant thorn seeds round you: kill them first!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "dryad", "count": 3, "elite": false}, {"kind": "thornling", "count": 12, "elite": false}]},
	{"time": 200.0, "type": "wave", "banner": "The Fae Knights of the court ride to the revel: they blink through your ring!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "fae_knight", "count": 5, "elite": false}, {"kind": "dryad", "count": 2, "elite": false}]},
	{"time": 330.0, "type": "wave", "banner": "A Treant wakes in the revel: its branches root what they strike!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "treant", "count": 1, "elite": false}, {"kind": "thornling", "count": 12, "elite": false}]},
	{"time": 480.0, "type": "wave", "banner": "The Wild Hunt rides through the court: step out of the rider's line!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "wild_rider", "count": 1, "elite": false}, {"kind": "fae_knight", "count": 4, "elite": false}]},
	{"time": 620.0, "type": "wave", "banner": "Will-o'-Wisps rise from the Mirror Lake: they lure your dead away!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "will_o_wisp", "count": 6, "elite": false}, {"kind": "fae_knight", "count": 3, "elite": false}]},
	{"time": 700.0, "type": "winter_prince", "banner": "THE WINTER PRINCE! The Summer Queen's rival brings one minute of winter into her summer!",  # Owner-approved proposal (miniboss); 8:20 left
		"kind": FaeCourtEnemyData.WINTER_PRINCE, "prince_dist": 300.0, "elite": false},  # TUNING (not in GDD) px ahead of the necromancer
	{"time": 820.0, "type": "wave", "banner": "Two Treants and their Dryads!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "treant", "count": 2, "elite": false}, {"kind": "dryad", "count": 3, "elite": false}]},
	{"time": 930.0, "type": "wave", "banner": "The Summer Queen's knights gather at her throne!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "fae_knight", "count": 6, "elite": false}, {"kind": "great_stag", "count": 1, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "Her court comes out to greet you, masks and all!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "masked_courtier", "count": 4, "elite": false}, {"kind": "thornling", "count": 12, "elite": false}]},
]

## The Summer Queen's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "summer_queen"). Her script is
## scripts/enemies/wild/boss_summer_queen.gd (loaded by her id); her numbers are
## SummerQueenData's.
const BOSS := {
	"id": "summer_queen",
	"time": BOSS_TIME,
	"display_name": "The Summer Queen of the Fae",
	"short_name": "The Summer Queen",
	"arrive_banner": "The Summer Queen rises from her throne of roses!",
	"defeat_banner": "The Summer Queen falls, and her court wilts! Hold out until the end...",
	"dead_objective": "The Summer Queen is dead. The summer ends... endure.",
}

## Placeholder floor of the foundation stub (WildGround "floor" key), kept for
## the other tools that read it; the stage draws FaeCourtGround ("ground").
const FLOOR := {
	"style": "fae",  # blossom petals and mushroom rings.
	"base": Color(0.14, 0.17, 0.12),  # TUNING (not in GDD)
	"line": Color(0.20, 0.24, 0.16),  # TUNING (not in GDD)
	"accent": Palette.WILD_BLOSSOM,  # TUNING (not in GDD)
	"trim": Palette.WILD_BARK,  # TUNING (not in GDD)
}

## This stage's year (any key of WildRulesData.SEASONS): the endless summer's
## wildfires come further apart than a five-minute Summer's (twenty minutes of
## them; the one key the season path reads for it).
const SEASONS := {
	"wildfire_every": 40.0,  # TUNING (not in GDD) s between two fronts (the act's 24)
}

## This stage's thorn thickets (any key of WildRulesData.THICKETS): a little
## more than the Greenwood's maze (cap 24, a spread every 60 s).
const THICKETS := {
	"cap": 26,  # TUNING (not in GDD) (the default 30)
	"spread_every": 55.0,  # TUNING (not in GDD) s (the default 45)
}

## This stage's living ground (any key of WildRulesData.BLOOM): a little more
## heal than the Greenwood's 0.6% (the act's 1% overran the naive bot there).
const BLOOM := {
	"heal": 0.007,  # TUNING (not in GDD) share of max HP a second (the default 0.01)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Fae Court",
	"short_name": "Fae Court",
	"chapter": "Chapter XLIV",  # Temporary and final stage 44 (the reorder pass renumbers if it moves).
	"act": 15,  # Temporary Act XV, the Turning Year (final slot XV; docs/last_acts/PLAN.md).
	"playable": true,  # Phase 2 built (GDD §15.0 "The Fae Court (Act XV phase 2)").
	"description": "A court of endless summer under a sky that never sets. The Summer Queen will offer you a bargain.",
	"unlock": {"stage": "greenwood", "boss_kills": 1},  # Plan: each stage opens the next
	"unlock_text": "Defeat the Stag King in the Greenwood to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Wild stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ZONES[0]["arena"],
	"ground": "fae_court",  # FaeCourtGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"fae_court": FAE_COURT,  # FaeCourtDirector: the endless summer, the fairy rings, the Winter Prince, A Fair Bargain.
	"wild": true,  # The Turning Year, Bloom and Blight, Overgrowth (WildRules).
	"seasons": SEASONS,  # This stage's year: the endless summer's fronts further apart.
	"bloom": BLOOM,  # This stage's living ground.
	"thickets": THICKETS,  # This stage's thickets.
	"zones": ZONES,  # The four zones.
	# Music key: "wildwood" (the Turning Year's "The Turning Year", SoundData.WILDWOOD_SCORE; its sound pack "wild").
	"music": "wildwood",
}
