## SunRoadStage — STAGE 15, THE ROAD TO THE SUN, the finale of Act V (the
## Shogunate of the Rising Sun; GDD §15.0 "Act V foundation (phase 1)" and "The
## Road to the Sun (Act V phase 2)"; owner-approved proposal
## docs/act5/PROPOSAL.md "Stage 15: The Road to the Sun"). A pilgrim road of
## torii gates climbing to the sun goddess's shrine above the clouds. Every
## number and event that belongs to this stage; StageRegistry exposes it to the
## run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys are
## documented in StageRegistry). Unlocked by defeating Shogun Kurogane.
##
## THE CLOCK IS AUTHORITATIVE, as on every zoned stage: four zones on fixed
## times (ZONES, run by MarchDirector: a zone banner, a sweep of mist, the
## obstacles and floor re-drawn as the next zone), and the Shogunate's shared
## rules follow the Sun's Course (day to 13:00 left, dusk to 7:00, then night):
##   20:00  Zone I,   the Torii Road:      vermilion torii posts, stone markers
##                                          and lanterns; spear levies, samurai,
##                                          warrior monks (the Sōhei)
##   15:00  Zone II,  the Sacred Forest:   giant roped cedars, mossy rocks;
##                                          dusk from 13:00 (ninja ambushes)
##   10:00  Zone III, the Shrine Steps:    stone steps, guardian lion-dogs
##    8:20  THE KIRIN, the miniboss (a holy beast of light)
##    7:00  night: the onryō, the oni and the KITSUNE (fox-fire illusions)
##    5:00  Zone IV,  the High Plain of Heaven: above the clouds; cloud rocks,
##                                          sun mirrors and lanterns (the shade
##                                          of Amaterasu's noon)
##    3:00  AMATERASU, the Sun Goddess (BossAmaterasu, AmaterasuData): her place
##          in the sky is the phase (dawn east, noon overhead, sunset west),
##          through the Sun's Course's one override; the night kinds hold back
##          while her sun is up
##    0:00  THE ENDLESS NIGHT (the shared Act V Reckoning: the sun never rises)
## The other Act V stages' kinds (the Burning Province's, Castle Kurogane's)
## join as guest squads once this build knows them (SUN_ROAD "guests"), like
## the Asphodel Underworld's guests. Every rate, cap and weight is TUNING (not
## in GDD) unless marked as the owner-approved proposal.
class_name SunRoadStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "sun_road"

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act V starts a step above the Asphodel Underworld's 1.5; the step goes in HP,
## not damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 1.65  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling
## (below the Underworld's and the other Act V stages' 1.5 since the Act V
## integration balance: the finale's step up is in HP and in Amaterasu).
const ENEMY_DAMAGE_MULT: float = 1.35  # TUNING (not in GDD) Act V integration balance: 1.5 -> 1.35 (the army bot's ring broke at 7:00, under the Kirin and in Amaterasu's first minute on 3 of 3 seeds; the step up stays in HP)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Acts III and IV: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 4.5  # TUNING (not in GDD) placeholder (Castle Kurogane x4.25)

## Game time (s) dusk falls: the timeline below starts its ambush trickle then.
## Must equal the Sun's Course's dusk_at (ShogunateRulesData.SUN, or this
## stage's SUN override); ShadowAmbush itself waits for dusk either way.
const DUSK: float = 420.0  # Owner-approved proposal: 13:00 left
## Game time (s) night falls: the night segment starts then (its night kinds
## join through the timeline helper whatever this says). Must equal night_at.
const NIGHT: float = 780.0  # Owner-approved proposal: 7:00 left

## The Sun's Course on this stage: the default clock (ShogunateRulesData.SUN)
## with the road's own banners. Amaterasu takes the sky from 17:00 through the
## Sun's Course's override (AmaterasuData.SKY), not through these keys.
const SUN := {
	"dusk_banner": "Dusk on the pilgrim road: the cedars' shadows lengthen. Beware ambushes!",  # TUNING (not in GDD)
	"night_banner": "Night on the holy mountain: the yokai walk. Keep to the lantern light!",  # TUNING (not in GDD)
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Endless
## Night, shared by every Act V stage: the sun never rises (and here it has
## just gone out); oni ("kind") with every night kind at once (the onryō and
## the Kitsune as "companions"), faster each minute ("endless_night":
## ShogunateRulesData.ENDLESS_NIGHT keys; {} = those defaults).
const RECKONING := {
	"banner": "THE ENDLESS NIGHT: THE SUN HAS GONE OUT",
	"kind": ShogunateEnemyData.ONI,  # The shared Endless Night kind.
	"endless_night": {},  # ShogunateRulesData.ENDLESS_NIGHT defaults.
	"companions": [{"kind": ShogunateEnemyData.ONRYO, "count": 6, "growth": 1.0},  # TUNING (not in GDD) every night kind at once
		{"kind": SunRoadEnemyData.KITSUNE, "count": 1, "growth": 0.5}],  # TUNING (not in GDD) the Road's own night kind
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) oni are heavy
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE ENDLESS NIGHT: the sun is gone and will not rise again. Endure."

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS, plus the Act V
## keys "night_weights" (kinds that join only at night, through the timeline
## helper SunCourse.timeline_weights()) and "ambush" (ShadowAmbush's trickle: a
## squad of `count` `kind` every `every` s, from dusk on)). Pilgrim levies,
## samurai, warrior monks and arquebus lines by day; ninja from dusk; the
## onryō, the Kitsune and the oni at night.
const SEGMENTS := [
	# Zone I, the Torii Road.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"ashigaru": 1.0},
		"objective": "The Torii Road: spear levies bar the pilgrim way"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.72, "samurai": 0.16, "sohei": 0.12},
		"objective": "Warrior monks guard the gates: step out of the naginata's arc"},
	{"start": 180.0, "rate": 2.0, "max_alive": 48,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.58, "samurai": 0.18, "sohei": 0.14, "teppo_gunner": 0.10},
		"objective": "Samurai and monks hold the road: step out of the white line"},
	# Zone II, the Sacred Forest (dusk from 7:00 elapsed).
	{"start": 300.0, "rate": 2.2, "max_alive": 56,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.52, "samurai": 0.2, "sohei": 0.16, "teppo_gunner": 0.12},
		"objective": "The Sacred Forest: the old cedars watch"},
	{"start": DUSK, "rate": 2.4, "max_alive": 62,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.5, "samurai": 0.2, "sohei": 0.17, "teppo_gunner": 0.13},
		"ambush": {"every": 42.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "Dusk in the forest: ninja in the cedars' shadows"},
	# Zone III, the Shrine Steps.
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.46, "samurai": 0.22, "sohei": 0.19, "teppo_gunner": 0.13},
		"ambush": {"every": 34.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "The Shrine Steps: the sun is setting on the climb"},
	{"start": NIGHT, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.33, "samurai": 0.24, "sohei": 0.18, "teppo_gunner": 0.1},
		"night_weights": {"onryo": 0.45, "kitsune": 0.06, "oni": 0.015},  # TUNING (not in GDD) the yokai join at night
		"ambush": {"every": 30.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "Night on the steps: fox-fire illusions lure your dead away"},
	# Zone IV, the High Plain of Heaven.
	{"start": 900.0, "rate": 3.2, "max_alive": 90,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.3, "samurai": 0.25, "sohei": 0.2, "teppo_gunner": 0.1},
		"night_weights": {"onryo": 0.45, "kitsune": 0.07, "oni": 0.015},  # TUNING (not in GDD)
		"ambush": {"every": 30.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "The High Plain of Heaven: above the clouds, the shrine of the sun"},
	# 17:00, the boss: a thinner trickle so the fight stays readable. Her sun is
	# up: the night kinds hold back while it shines (the timeline helper).
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.32, "samurai": 0.28, "sohei": 0.22, "teppo_gunner": 0.1},
		"night_weights": {"onryo": 0.5, "kitsune": 0.06, "oni": 0.01},  # TUNING (not in GDD)
		"ambush": {"every": 40.0, "kind": "ninja", "count": 2},  # TUNING (not in GDD)
		"objective": "Put out the sun"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus the Act V type
## "ambush" (its groups go to ShadowAmbush, which waits for dusk) and the
## SunRoadDirector's "kirin" (the miniboss `kind` steps out of the light with
## its `escort` groups)).
const EVENTS := [
	# Zone I: the Torii Road.
	{"time": 20.0, "type": "wave", "banner": "Spear levies advance in wide ranks!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "ashigaru", "count": 16, "elite": false}]},
	{"time": 110.0, "type": "wave", "banner": "Warrior monks bar the torii: step out of the naginata's arc!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "sohei", "count": 5, "elite": false}, {"kind": "ashigaru", "count": 8, "elite": false}]},
	{"time": 200.0, "type": "wave", "banner": "A samurai lays his hand on the hilt: step out of the white line!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "samurai", "count": 1, "elite": true}, {"kind": "samurai", "count": 3, "elite": false}, {"kind": "sohei", "count": 2, "elite": false}]},
	{"time": 270.0, "type": "wave", "banner": "An arquebus line on the road: rush them while they reload!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "teppo_gunner", "count": 6, "elite": false}, {"kind": "ashigaru", "count": 10, "elite": false}]},
	# Zone II (5:00): the Sacred Forest.
	{"time": 340.0, "type": "wave", "banner": "The forest's guardians close in from every side!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "ashigaru", "count": 14, "elite": false}, {"kind": "sohei", "count": 6, "elite": false}, {"kind": "samurai", "count": 1, "elite": true}]},
	{"time": 440.0, "type": "ambush", "banner": "Ninja! Out of the cedars' shadows!",  # TUNING (not in GDD)
		"groups": [{"kind": "ninja", "count": 4, "elite": false}]},
	{"time": 540.0, "type": "wave", "banner": "Gunners and duelists in the dusk!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "teppo_gunner", "count": 8, "elite": false}, {"kind": "samurai", "count": 2, "elite": true}, {"kind": "sohei", "count": 4, "elite": false}]},
	# Zone III (10:00): the Shrine Steps.
	{"time": 615.0, "type": "wave", "banner": "The shrine's warrior monks hold the steps!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "sohei", "count": 10, "elite": false}, {"kind": "sohei", "count": 1, "elite": true}, {"kind": "ashigaru", "count": 10, "elite": false}]},
	{"time": 660.0, "type": "ambush", "banner": "Smoke! They are among your dead!",  # TUNING (not in GDD)
		"groups": [{"kind": "ninja", "count": 5, "elite": false}]},
	{"time": 700.0, "type": "kirin", "banner": "THE KIRIN descends in a blaze of light: step out of its golden lane!", "kind": SunRoadEnemyData.KIRIN,  # Owner-approved proposal: the miniboss
		"escort": [{"kind": "sohei", "count": 6, "elite": false}]},  # TUNING (not in GDD)
	{"time": 800.0, "type": "wave", "banner": "Fox-fire on the steps: the Kitsune's illusions lure your dead!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "kitsune", "count": 3, "elite": false}, {"kind": "onryo", "count": 12, "elite": false}]},
	{"time": 870.0, "type": "wave", "banner": "An oni walks the night!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "oni", "count": 1, "elite": false}, {"kind": "onryo", "count": 8, "elite": false}, {"kind": "sohei", "count": 4, "elite": false}]},
	# Zone IV (15:00): the High Plain of Heaven.
	{"time": 920.0, "type": "wave", "banner": "Above the clouds, the night host gathers!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "samurai", "count": 2, "elite": true}, {"kind": "samurai", "count": 4, "elite": false}, {"kind": "kitsune", "count": 2, "elite": false}, {"kind": "onryo", "count": 10, "elite": false}]},
	{"time": 975.0, "type": "ambush", "banner": "Ninja in the dark!",  # TUNING (not in GDD)
		"groups": [{"kind": "ninja", "count": 6, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The last guard of the shrine!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "sohei", "count": 8, "elite": false}, {"kind": "oni", "count": 1, "elite": false}, {"kind": "kitsune", "count": 2, "elite": false}]},
	# 17:00 Amaterasu (BOSS_TIME), plus two sallies (her sun is up: no night kinds).
	{"time": 1090.0, "type": "wave", "banner": "The shrine's guard rallies to its goddess!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "sohei", "count": 8, "elite": false}, {"kind": "samurai", "count": 1, "elite": true}, {"kind": "ashigaru", "count": 10, "elite": false}]},
	{"time": 1160.0, "type": "wave", "banner": "Gunners on the cloud plain!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "teppo_gunner", "count": 6, "elite": false}, {"kind": "sohei", "count": 6, "elite": false}]},
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES.
## `ground` is a SunRoadGround look: style "torii" (packed earth and gravel,
## sakura petals), "forest" (moss and cedar needles), "steps" (grey stone
## steps) or "heaven" (the pale cloud plain); base / line / accent colours of
## the code floor (the tiles/sun_road_<style> PNG replaces them when it
## exists). Obstacle kinds are drawn by SunRoadGlyphs (their obstacles/<kind>
## PNGs when they exist); the stone lanterns are the Sun's Course's (lit at
## night). Zone IV is dense: its obstacles' shadows are the only safe ground
## at Amaterasu's noon.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Torii Road",  # Owner-approved proposal zone I
		"blurb": "A pilgrim road climbing through a thousand vermilion gates",
		"ground": {"style": "torii", "base": Color(0.27, 0.23, 0.19), "line": Color(0.22, 0.19, 0.16),
			"accent": Color(0.894, 0.580, 0.675)},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 1531,  # TUNING (not in GDD)
			"kinds": {
				"torii_post": {"weight": 0.42, "shape": "circle", "sizes": [9.0, 11.0]},  # TUNING (not in GDD)
				"stone_marker": {"weight": 0.28, "shape": "rect", "sizes": [30.0, 40.0], "short": 16.0},  # TUNING (not in GDD)
				"stone_lantern": {"weight": 0.3, "shape": "circle", "sizes": [10.0]},  # TUNING (not in GDD) the Sun's Course lights it at night
			}},
	},
	{"start": 300.0, "numeral": "II", "name": "The Sacred Forest",  # Owner-approved proposal zone II
		"blurb": "Giant cedars bound with sacred rope, older than the Shogunate",
		"ground": {"style": "forest", "base": Color(0.10, 0.13, 0.10), "line": Color(0.08, 0.10, 0.08),
			"accent": Color(0.30, 0.44, 0.26)},
		"arena": {"density": 0.28, "clear_radius": 220.0, "layout_seed": 1532,  # TUNING (not in GDD) dense: shadows for the ninja
			"kinds": {
				"sacred_cedar": {"weight": 0.5, "shape": "circle", "sizes": [14.0, 18.0, 22.0]},  # TUNING (not in GDD)
				"moss_rock": {"weight": 0.3, "shape": "circle", "sizes": [11.0, 14.0]},  # TUNING (not in GDD)
				"stone_lantern": {"weight": 0.2, "shape": "circle", "sizes": [10.0]},  # TUNING (not in GDD)
			}},
	},
	{"start": 600.0, "numeral": "III", "name": "The Shrine Steps",  # Owner-approved proposal zone III
		"blurb": "Worn stone steps up the mountain, watched by guardian lion-dogs",
		"ground": {"style": "steps", "base": Color(0.25, 0.25, 0.26), "line": Color(0.16, 0.16, 0.17),
			"accent": Color(0.30, 0.40, 0.26)},
		"arena": {"density": 0.22, "clear_radius": 220.0, "layout_seed": 1533,  # TUNING (not in GDD)
			"kinds": {
				"komainu": {"weight": 0.35, "shape": "circle", "sizes": [12.0, 14.0]},  # TUNING (not in GDD)
				"step_wall": {"weight": 0.33, "shape": "rect", "sizes": [44.0, 60.0], "short": 16.0},  # TUNING (not in GDD)
				"stone_lantern": {"weight": 0.32, "shape": "circle", "sizes": [10.0]},  # TUNING (not in GDD)
			}},
	},
	{"start": 900.0, "numeral": "IV", "name": "The High Plain of Heaven",  # Owner-approved proposal zone IV
		"blurb": "Above the clouds, the sun goddess's shrine and her bronze mirrors",
		"ground": {"style": "heaven", "base": Color(0.40, 0.42, 0.48), "line": Color(0.34, 0.36, 0.42),
			"accent": Color(1.0, 0.82, 0.30)},
		"arena": {"density": 0.34, "clear_radius": 240.0, "layout_seed": 1534,  # TUNING (not in GDD) dense: the shade of Amaterasu's noon
			"kinds": {
				"cloud_rock": {"weight": 0.45, "shape": "circle", "sizes": [14.0, 18.0, 22.0]},  # TUNING (not in GDD)
				"sun_mirror": {"weight": 0.2, "shape": "circle", "sizes": [11.0, 13.0]},  # TUNING (not in GDD)
				"stone_lantern": {"weight": 0.35, "shape": "circle", "sizes": [10.0]},  # TUNING (not in GDD)
			}},
	},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "HIGHER UP THE ROAD TO THE SUN  -  ZONE %s",
	"zone_color": Color(1.0, 0.82, 0.30),  # The sun's gold.
	"fog_color": Color(0.10, 0.09, 0.12),  # Mountain mist.
	"fog_bank_color": Color(0.80, 0.80, 0.86),  # Cloud banks.
	"zones": ZONES,
}

## The Road's systems (SunRoadDirector; StageRegistry "sun_road").
##   guest_* / guests — the other Act V stages' kinds in small squads (as
##            UnderworldStage.UNDERWORLD): candidate ids per kind (the first
##            one this build knows; none = skipped) and a weight. The ids were
##            guessed while the three stages were built in parallel and checked
##            at the Act V integration against ProvinceEnemyData (kunoichi,
##            kappa) and KuroganeEnemyData (hatamoto, kiba_musha; its General of
##            the Left is a miniboss, never a guest).
const SUN_ROAD := {
	"guest_first": 300.0,  # TUNING (not in GDD) no guests before 5:00
	"guest_interval": 85.0,  # TUNING (not in GDD)
	"guest_until": 1000.0,  # TUNING (not in GDD) the boss fight keeps its own roster
	"guest_count": 3,  # TUNING (not in GDD)
	"guest_growth": 0.4,  # TUNING (not in GDD)
	"guest_max": 6,  # TUNING (not in GDD)
	"guests": [
		{"ids": ["kunoichi"], "weight": 0.8},  # The Burning Province (Act V phase 2)
		{"ids": ["kappa"], "weight": 0.6},  # The Burning Province (night: only at night)
		{"ids": ["hatamoto"], "weight": 0.4},  # Castle Kurogane (Act V phase 2)
		{"ids": ["kiba_musha"], "weight": 0.6},  # Castle Kurogane (the Kiba-musha cavalry)
	],
}

## Amaterasu's arrival (keys as GraveyardStage.BOSS): AmaterasuData.ARRIVAL
## (boss id "amaterasu", the ending line as the defeat banner), whose `time`
## equals BOSS_TIME (17:00).
const BOSS: Dictionary = AmaterasuData.ARRIVAL

## Floor look of the placeholder "shogunate" ground (ShogunateGround; the stage
## now uses SunRoadGround and its ZONES, this stays for any caller of "floor").
const FLOOR := {
	"style": "gravel",  # Raked shrine gravel, stepping stones, fallen sakura petals.
	"base": Color(0.24, 0.23, 0.21),  # TUNING (not in GDD) pale shrine gravel
	"line": Color(0.30, 0.29, 0.27),  # TUNING (not in GDD)
	"accent": Color(0.40, 0.39, 0.37),  # TUNING (not in GDD) stepping stones
	"trim": Color(0.894, 0.580, 0.675),  # TUNING (not in GDD) sakura petals
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Road to the Sun",
	"short_name": "The Sun Road",
	"chapter": "Chapter XV",
	"act": 5,  # Act V, the Shogunate of the Rising Sun.
	"playable": false,  # Phase 2 built; hidden from the stage select until the lead's merge, review and the owner's playtest.
	"description": "A pilgrim road of torii gates climbing to the sun goddess's shrine above the clouds. The sun crosses the sky as you climb, and when it sets, it will not rise again.",
	"unlock": {"stage": "kurogane", "boss_kills": 1},  # Owner-approved: each boss unlocks the next stage
	"unlock_text": "Defeat Shogun Kurogane in his castle to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act V stages.
	"consecration": {},  # A Covenant event: none in Act V.
	"crypt_defender": {},  # None in Act V.
	"arena": ZONES[0]["arena"],
	"ground": "sun_road",  # SunRoadGround (the four zone floors).
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,
	"sun_road": SUN_ROAD,  # SunRoadDirector (the Kirin, guests).
	"shogunate": true,  # Act V: the Sun's Course, the Draw, From the Shadows (ShogunateRules).
	"sun": SUN,  # Act V: this stage's Sun's Course overrides (the road's banners).
	"zones": ZONES,  # The four zones (MarchDirector reads them through "march").
	"music": "sun",  # "The Setting Sun" (SoundData.SUN_SCORE), which also loads the Shogunate sound pack
}
