## KuroganeStage — STAGE 14, CASTLE KUROGANE (Act V, the Shogunate of the Rising
## Sun; GDD §15.0 "Act V foundation (phase 1)", owner-approved proposal
## docs/act5/PROPOSAL.md "Stage 14: Castle Kurogane"). The Shogun's fortress: stone walls, gates, courtyards and the keep.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (Act V phase 1). The stage is registered, unlocked
## in the campaign chain, runs the Shogunate's three shared rules
## ("shogunate": true: the Sun's Course, the Draw, From the Shadows) with the
## default Sun's Course ("sun": {}: day to 13:00 left, dusk to 7:00, then
## night), and plays a simple timeline of the shared kinds that follows the
## Sun's Course (ashigaru, samurai and teppo gunners by day; ninja ambushes from
## dusk through the "ambush" events and the segments' "ambush" trickle; the
## onryo and the oni only at night, through the segments' "night_weights" and
## the timeline helper) against a PLACEHOLDER boss script (the "alaric" boss script under the Shogun's name),
## with the Endless Night Reckoning (oni and onryo, the sun never rises). It is
## hidden from the stage select ("playable": false) until phase 2 builds it:
## the regiments and their banners, the Hatamoto, the General of the Left, its kinds, the Shogun and his army-health-bar.
## Planned zones (ZONES; clock-driven like every stage): The Outer Bailey, The Gatehouse, The Courtyards, The Keep.
## The Shogun arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD).
class_name KuroganeStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "kurogane"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act V starts a step above the Asphodel Underworld's 1.5; the step goes in HP,
## not damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 1.6  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling (the
## Underworld's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Acts III and IV: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 4.25  # TUNING (not in GDD) placeholder (the Burning Province x4.0)

## Game time (s) dusk falls: the timeline below starts its ambush trickle then.
## Must equal the Sun's Course's dusk_at (ShogunateRulesData.SUN, or this
## stage's SUN override); ShadowAmbush itself waits for dusk either way.
const DUSK: float = 420.0  # Owner-approved proposal: 13:00 left
## Game time (s) night falls: the night segment starts then (its night kinds
## join through the timeline helper whatever this says). Must equal night_at.
const NIGHT: float = 780.0  # Owner-approved proposal: 7:00 left

## The four zones phase 2 builds (names from the owner-approved proposal), each
## from `start` game seconds. The stub has one placeholder floor.
const ZONES := [
	{"id": "outer_bailey", "name": "The Outer Bailey", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "gatehouse", "name": "The Gatehouse", "start": 300.0},
	{"id": "courtyards", "name": "The Courtyards", "start": 600.0},
	{"id": "keep", "name": "The Keep", "start": 900.0},
]

## The Sun's Course on this stage: {} = the defaults of ShogunateRulesData.SUN
## (any of its keys overrides them here; phase 2 may move the dusk or the night).
const SUN := {}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Endless
## Night, shared by every Act V stage: the sun never rises; oni ("kind") with
## every night kind at once (the onryo as "companions"; phase 2 adds the
## kitsune and the kappa there), faster each minute ("endless_night":
## ShogunateRulesData.ENDLESS_NIGHT keys; {} = those defaults).
const RECKONING := {
	"banner": "THE ENDLESS NIGHT: THE SUN NEVER RISES",
	"kind": ShogunateEnemyData.ONI,  # The shared Endless Night kind.
	"endless_night": {},  # ShogunateRulesData.ENDLESS_NIGHT defaults (phase 2 may tune them here).
	"companions": [{"kind": ShogunateEnemyData.ONRYO, "count": 6, "growth": 1.0}],  # TUNING (not in GDD) every night kind at once
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) oni are heavy
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE ENDLESS NIGHT: the sun will not rise again. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS, plus the Act V
## keys "night_weights" (kinds that join only at night, through the timeline
## helper SunCourse.timeline_weights()) and "ambush" (ShadowAmbush's trickle: a
## squad of `count` `kind` every `every` s, from dusk on)): a plain ramp of the
## shared kinds that follows the Sun's Course (placeholder).
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"ashigaru": 1.0},
		"objective": "The Outer Bailey: the garrison's levies hold the walls"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.75, "samurai": 0.25},
		"objective": "Arquebus lines on the walls: rush the reload"},
	{"start": 240.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.6, "samurai": 0.28, "teppo_gunner": 0.12},
		"objective": "Arquebus lines on the walls: rush the reload"},
	{"start": DUSK, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.55, "samurai": 0.3, "teppo_gunner": 0.15},
		"ambush": {"every": 45.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "The Gatehouse: dusk falls; ninja in the gate's shadows"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.5, "samurai": 0.33, "teppo_gunner": 0.17},
		"ambush": {"every": 35.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "The Courtyards: samurai duelists draw in the failing light"},
	{"start": NIGHT, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.35, "samurai": 0.3, "teppo_gunner": 0.12},
		"night_weights": {"onryo": 0.5, "oni": 0.015},  # TUNING (not in GDD) the yokai join at night
		"ambush": {"every": 30.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "Night in the Keep: the oni guard the stair"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"ashigaru": 0.3, "samurai": 0.3, "teppo_gunner": 0.1},
		"night_weights": {"onryo": 0.5, "oni": 0.01},  # TUNING (not in GDD)
		"ambush": {"every": 40.0, "kind": "ninja", "count": 2},  # TUNING (not in GDD)
		"objective": "The Shogun takes the field"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus the Act V type
## "ambush": its groups go to ShadowAmbush, which waits for dusk and shows the
## banner when the squad appears). Wide spear ranks ("line"), arquebus lines,
## samurai with drawing elites, ninja ambushes from dusk, the yokai at night.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "Spear levies advance in wide ranks!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "ashigaru", "count": 16, "elite": false}]},
	{"time": 120.0, "type": "wave", "banner": "An arquebus line: rush them while they reload!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "teppo_gunner", "count": 5, "elite": false}, {"kind": "ashigaru", "count": 8, "elite": false}]},
	{"time": 200.0, "type": "wave", "banner": "A samurai lays his hand on the hilt: step out of the white line!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "samurai", "count": 1, "elite": true}, {"kind": "samurai", "count": 4, "elite": false}]},
	{"time": 330.0, "type": "wave", "banner": "The levies close in from every side!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "ashigaru", "count": 16, "elite": false}, {"kind": "samurai", "count": 1, "elite": true}, {"kind": "samurai", "count": 3, "elite": false}]},
	{"time": 440.0, "type": "ambush", "banner": "Ninja! Out of the shadows!",  # TUNING (not in GDD)
		"groups": [{"kind": "ninja", "count": 4, "elite": false}]},
	{"time": 540.0, "type": "wave", "banner": "Gunners and duelists in the dusk!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "teppo_gunner", "count": 8, "elite": false}, {"kind": "samurai", "count": 2, "elite": true}]},
	{"time": 660.0, "type": "ambush", "banner": "Smoke! They are among your dead!",  # TUNING (not in GDD)
		"groups": [{"kind": "ninja", "count": 5, "elite": false}]},
	{"time": 740.0, "type": "wave", "banner": "Duelists draw in the failing light!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "samurai", "count": 2, "elite": true}, {"kind": "samurai", "count": 3, "elite": false}, {"kind": "ashigaru", "count": 8, "elite": false}]},
	{"time": 800.0, "type": "wave", "banner": "The vengeful dead drift through the walls!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "onryo", "count": 14, "elite": false}]},
	{"time": 870.0, "type": "wave", "banner": "An oni walks the night!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "oni", "count": 1, "elite": false}, {"kind": "onryo", "count": 8, "elite": false}]},
	{"time": 960.0, "type": "wave", "banner": "The night host gathers!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "samurai", "count": 2, "elite": true}, {"kind": "samurai", "count": 4, "elite": false}, {"kind": "oni", "count": 2, "elite": false}, {"kind": "onryo", "count": 10, "elite": false}]},
	{"time": 990.0, "type": "ambush", "banner": "Ninja in the dark!",  # TUNING (not in GDD)
		"groups": [{"kind": "ninja", "count": 6, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA). Placeholder kinds drawn by
## ShogunateGlyphs until phase 2 brings the stage's own art; the stone lanterns
## use their sprites (obstacles/stone_lantern, _lit) when present.
const ARENA := {
	"density": 0.2,  # TUNING (not in GDD)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 1414,  # TUNING (not in GDD)
	"kinds": {
		"stone_lantern": {"weight": 0.3, "shape": "circle", "sizes": [10.0]},  # TUNING (not in GDD) the Sun's Course lights it at night (ShogunateGlyphs.LANTERN)
		"stone_wall": {"weight": 0.55, "shape": "rect", "sizes": [48.0, 64.0, 80.0], "short": 24.0},  # TUNING (not in GDD) placeholder art
		"bamboo_clump": {"weight": 0.15, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD) placeholder art
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "alaric" boss script under the Shogun's name
## until phase 2 adds scripts/enemies/shogunate/boss_shogun.gd (then
## remove the "script" key).
const BOSS := {
	"id": "shogun",
	"script": "alaric",  # PLACEHOLDER boss script until phase 2 adds boss_shogun.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "Shogun Kurogane",
	"short_name": "The Shogun",
	"arrive_banner": "Shogun Kurogane raises his war fan!",
	"defeat_banner": "Shogun Kurogane falls on his own blade! Hold out until the end...",
	"dead_objective": "The Shogun is dead. Survive until the night ends... it will not.",
}

## Placeholder floor (ShogunateGround, code-drawn) until phase 2 brings the
## stage's zone floors: base colour, joint lines, accent, trim, style.
const FLOOR := {
	"style": "castle",  # Grey castle flagstones in courses, moss in the joints.
	"base": Color(0.17, 0.17, 0.18),  # TUNING (not in GDD) castle stone
	"line": Color(0.11, 0.11, 0.12),  # TUNING (not in GDD)
	"accent": Color(0.42, 0.41, 0.40),  # TUNING (not in GDD) pale flagstones
	"trim": Color(0.30, 0.42, 0.22),  # TUNING (not in GDD) moss
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Castle Kurogane",
	"short_name": "Kurogane",
	"chapter": "Chapter XIV",
	"act": 5,  # Act V, the Shogunate of the Rising Sun.
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "The Shogun's fortress: stone walls, gates, courtyards and the keep. His regiments are his strength, and he waits on his command platform for the night.",
	"unlock": {"stage": "province", "boss_kills": 1},  # Owner-approved: each boss unlocks the next stage
	"unlock_text": "Slay Kage in the Burning Province to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act V stages.
	"consecration": {},  # A Covenant event: none in Act V.
	"crypt_defender": {},  # None in Act V.
	"arena": ARENA,
	"ground": "shogunate",  # Placeholder ShogunateGround until phase 2.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector).
	"shogunate": true,  # Act V: the Sun's Course, the Draw, From the Shadows (ShogunateRules).
	"sun": SUN,  # Act V: this stage's Sun's Course overrides ({} = the defaults).
	"zones": ZONES,  # Act V stub: the planned zone names (phase 2 builds them).
	# Music key "bronze" FOR NOW (the Act IV loop): the audio pass adds "sun"
	# ("The Setting Sun", SoundData.SUN_SCORE) and the lead switches this to
	# "sun" at the merge.
	"music": "bronze",
}
