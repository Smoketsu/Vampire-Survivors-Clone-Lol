## KuroganeStage — STAGE 14, CASTLE KUROGANE (Act V, the Shogunate of the Rising
## Sun; GDD §15.0 "Act V foundation (phase 1)" and "Castle Kurogane (Act V phase
## 2)"; owner-approved proposal docs/act5/PROPOSAL.md "Stage 14: Castle
## Kurogane"). The Shogun's fortress: stone walls, gates, courtyards and the
## keep. Every number and event that belongs to this stage; StageRegistry
## exposes it to the run as `Game.stage_def` (the STAGE dictionary at the
## bottom; its keys are documented in StageRegistry). Unlocked by slaying Kage
## in the Burning Province.
##
## THE CLOCK IS AUTHORITATIVE, as on every stage since the Crimson March: four
## zones on fixed times (ZONES, run by MarchDirector: a zone banner, a sweep of
## castle smoke, the obstacles and floor re-drawn as the next zone):
##   20:00  Zone I,   the Outer Bailey: trampled earth under the outer walls;
##                                      spear levies, arquebus lines, the first
##                                      Hatamoto under their banners
##   15:00  Zone II,  the Gatehouse:   granite paving among walls and gates;
##                                      the cavalry rides (Kiba-musha); dusk at
##                                      13:00 brings the ninja
##   10:00  Zone III, the Courtyards:  raked gravel among pines and lanterns;
##                                      the General of the Left at 9:00; night
##                                      at 7:00 brings the yokai
##    5:00  Zone IV,  the Keep:        dark floorboards among drums and sake
##    3:00  Shogun Kurogane (BossShogun): his army is his health bar
##    0:00  the Endless Night (the shared Act V Reckoning)
## The Sun's Course, the Draw and From the Shadows are the shared Shogunate
## rules ("shogunate": true; "sun": the defaults plus this castle's banners).
## The stage systems run in KuroganeDirector (KUROGANE): THE GENERAL OF THE
## LEFT (the miniboss) and the HUD objective of the Shogun's army. The Shogun's
## six regiments, his platform and his duel are his own (ShogunData,
## ShogunRegiments). A step harder than the Burning Province. Every rate, cap
## and weight is TUNING (not in GDD).
class_name KuroganeStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "kurogane"

# =====================================================================================
# Run structure
# =====================================================================================

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

## The Sun's Course on this stage: the defaults of ShogunateRulesData.SUN, plus
## this castle's own phase banners (SUN keys dusk_banner / night_banner).
const SUN := {
	"dusk_banner": "Dusk over the castle: the shadows of the walls lengthen. Beware ambushes!",  # TUNING (not in GDD)
	"night_banner": "Night falls on Castle Kurogane: the lanterns are lit, the yokai walk!",  # TUNING (not in GDD)
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Endless
## Night, shared by every Act V stage: the sun never rises; oni ("kind") with
## every night kind at once (the onryo as "companions"), faster each minute
## ("endless_night": ShogunateRulesData.ENDLESS_NIGHT keys; {} = those defaults).
const RECKONING := {
	"banner": "THE ENDLESS NIGHT: THE SUN NEVER RISES",
	"kind": ShogunateEnemyData.ONI,  # The shared Endless Night kind.
	"endless_night": {},  # ShogunateRulesData.ENDLESS_NIGHT defaults.
	"companions": [{"kind": ShogunateEnemyData.ONRYO, "count": 6, "growth": 1.0}],  # TUNING (not in GDD) every night kind at once
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) oni are heavy
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE ENDLESS NIGHT: the sun will not rise again. Endure."

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments, sorted by start time (keys as
## GraveyardStage.SEGMENTS, plus the Act V keys "night_weights" (kinds that join
## only at night, through SunCourse.timeline_weights()) and "ambush"
## (ShadowAmbush's trickle: a squad of `count` `kind` every `every` s, from dusk
## on)). Ashigaru are the fodder; samurai the soldiers; teppo gunners the
## ranged line; Kiba-musha the cavalry (from the Gatehouse); the Hatamoto the
## rare elite banners (always elite, their aura buffs the soldiers near them).
const SEGMENTS := [
	# Zone I, the Outer Bailey.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"ashigaru": 1.0},
		"objective": "The Outer Bailey: the garrison's levies hold the walls"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.78, "samurai": 0.22},
		"objective": "Spear levies in wide ranks: hold them on your blockers"},
	{"start": 150.0, "rate": 2.0, "max_alive": 48,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.62, "samurai": 0.25, "teppo_gunner": 0.12, "hatamoto": 0.01},
		"objective": "Arquebus lines on the walls: rush the reload"},
	{"start": 240.0, "rate": 2.2, "max_alive": 52,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.58, "samurai": 0.27, "teppo_gunner": 0.14, "hatamoto": 0.01},
		"objective": "A banner rises: kill the Hatamoto and his men falter"},
	# Zone II, the Gatehouse: the cavalry; dusk at 7:00.
	{"start": 300.0, "rate": 2.4, "max_alive": 58,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.5, "samurai": 0.26, "teppo_gunner": 0.14, "kiba_musha": 0.09, "hatamoto": 0.01},
		"objective": "The Gatehouse: the cavalry rides through the gates"},
	{"start": DUSK, "rate": 2.7, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.48, "samurai": 0.27, "teppo_gunner": 0.14, "kiba_musha": 0.1, "hatamoto": 0.012},
		"ambush": {"every": 45.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "Dusk in the Gatehouse: ninja in the gates' shadows"},
	{"start": 510.0, "rate": 3.0, "max_alive": 74,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.46, "samurai": 0.28, "teppo_gunner": 0.14, "kiba_musha": 0.11, "hatamoto": 0.012},
		"ambush": {"every": 40.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "Step out of the white lines and the charging lanes"},
	# Zone III, the Courtyards: the General of the Left at 9:00; night at 7:00.
	{"start": 600.0, "rate": 3.3, "max_alive": 82,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.44, "samurai": 0.29, "teppo_gunner": 0.14, "kiba_musha": 0.11, "hatamoto": 0.014},
		"ambush": {"every": 35.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "The Courtyards: samurai duelists draw among the pines"},
	{"start": 720.0, "rate": 3.6, "max_alive": 90,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.44, "samurai": 0.29, "teppo_gunner": 0.14, "kiba_musha": 0.11, "hatamoto": 0.014},
		"ambush": {"every": 35.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "The light fails over the courtyards"},
	{"start": NIGHT, "rate": 3.8, "max_alive": 96,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.36, "samurai": 0.28, "teppo_gunner": 0.12, "kiba_musha": 0.1, "hatamoto": 0.012},
		"night_weights": {"onryo": 0.45, "oni": 0.014},  # TUNING (not in GDD) the yokai join at night
		"ambush": {"every": 30.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "Night in the Courtyards: keep to the lanterns' light"},
	# Zone IV, the Keep: the density peak of the run.
	{"start": 900.0, "rate": 4.2, "max_alive": 104,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.36, "samurai": 0.3, "teppo_gunner": 0.12, "kiba_musha": 0.1, "hatamoto": 0.014},
		"night_weights": {"onryo": 0.45, "oni": 0.016},  # TUNING (not in GDD)
		"ambush": {"every": 30.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "The Keep: the Shogun's guard holds the stair"},
	{"start": 960.0, "rate": 4.4, "max_alive": 108,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.36, "samurai": 0.3, "teppo_gunner": 0.12, "kiba_musha": 0.1, "hatamoto": 0.014},
		"night_weights": {"onryo": 0.45, "oni": 0.016},  # TUNING (not in GDD)
		"ambush": {"every": 30.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "Taiko drums beat in the keep: the Shogun is coming"},
	# 17:00, the boss: his regiments ARE the fight; a thin trickle (its kills
	# take points off his bar too).
	{"start": BOSS_TIME, "rate": 1.4, "max_alive": 40,  # TUNING (not in GDD) thinner: the regiments fill the field
		"weights": {"ashigaru": 0.6, "samurai": 0.3, "teppo_gunner": 0.1},
		"night_weights": {"onryo": 0.4},  # TUNING (not in GDD)
		"objective": "Break the Shogun's regiments: kill their Hatamoto"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave": formation + groups; the Act V "ambush": its groups go to
## ShadowAmbush, which waits for dusk), plus Castle Kurogane's own
## (KuroganeDirector):
##   "general_left" — the General of the Left (kind `kind`) rides in on the
##                    spawn ring (the stage miniboss).
const EVENTS := [
	# Zone I: the Outer Bailey.
	{"time": 20.0, "type": "wave", "banner": "Spear levies advance in wide ranks!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "ashigaru", "count": 16, "elite": false}]},
	{"time": 100.0, "type": "wave", "banner": "An arquebus line on the wall: rush them while they reload!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "teppo_gunner", "count": 5, "elite": false}, {"kind": "ashigaru", "count": 8, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "A HATAMOTO raises his banner: his men fight harder while he stands. Kill the banner!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "hatamoto", "count": 1, "elite": true}, {"kind": "ashigaru", "count": 12, "elite": false}, {"kind": "samurai", "count": 3, "elite": false}]},
	{"time": 230.0, "type": "wave", "banner": "A samurai lays his hand on the hilt: step out of the white line!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "samurai", "count": 1, "elite": true}, {"kind": "samurai", "count": 4, "elite": false}]},
	# Zone II (5:00): the Gatehouse; cavalry; dusk at 7:00.
	{"time": 310.0, "type": "wave", "banner": "KIBA-MUSHA ride through the gate: step out of the charging lanes!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "kiba_musha", "count": 5, "elite": false}]},
	{"time": 380.0, "type": "wave", "banner": "The levies close in from every side!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "ashigaru", "count": 18, "elite": false}, {"kind": "samurai", "count": 1, "elite": true}, {"kind": "samurai", "count": 3, "elite": false}]},
	{"time": 440.0, "type": "ambush", "banner": "Ninja! Out of the gates' shadows!",  # TUNING (not in GDD)
		"groups": [{"kind": "ninja", "count": 4, "elite": false}]},
	{"time": 500.0, "type": "wave", "banner": "Two banners and their cavalry!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "hatamoto", "count": 2, "elite": true}, {"kind": "kiba_musha", "count": 4, "elite": false}, {"kind": "samurai", "count": 4, "elite": false}]},
	{"time": 560.0, "type": "wave", "banner": "Gunners and duelists in the dusk!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "teppo_gunner", "count": 8, "elite": false}, {"kind": "samurai", "count": 2, "elite": true}]},
	# Zone III (10:00): the Courtyards; the General of the Left at 9:00; night at 7:00.
	{"time": 620.0, "type": "ambush", "banner": "Smoke among the pines! They are among your dead!",  # TUNING (not in GDD)
		"groups": [{"kind": "ninja", "count": 5, "elite": false}]},
	{"time": 660.0, "type": "general_left", "banner": "THE GENERAL OF THE LEFT charges into the courtyards: step out of his lane!",  # Owner-approved proposal (miniboss); 9:00 left like Polyphemus
		"kind": "general_left", "elite": false},
	{"time": 740.0, "type": "wave", "banner": "Duelists draw in the failing light!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "samurai", "count": 2, "elite": true}, {"kind": "samurai", "count": 3, "elite": false}, {"kind": "ashigaru", "count": 8, "elite": false}]},
	{"time": 800.0, "type": "wave", "banner": "The vengeful dead drift through the castle walls!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "onryo", "count": 14, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "An oni walks the courtyards!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "oni", "count": 1, "elite": false}, {"kind": "onryo", "count": 8, "elite": false}, {"kind": "hatamoto", "count": 1, "elite": true}]},
	# Zone IV (15:00): the Keep.
	{"time": 910.0, "type": "wave", "banner": "THE KEEP: the cavalry of the guard rides down the stair!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "kiba_musha", "count": 6, "elite": false}, {"kind": "hatamoto", "count": 1, "elite": true}]},
	{"time": 960.0, "type": "wave", "banner": "The night host gathers before the keep!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "samurai", "count": 2, "elite": true}, {"kind": "samurai", "count": 4, "elite": false}, {"kind": "oni", "count": 2, "elite": false}, {"kind": "onryo", "count": 10, "elite": false}]},
	{"time": 990.0, "type": "ambush", "banner": "Ninja in the dark of the keep!",  # TUNING (not in GDD)
		"groups": [{"kind": "ninja", "count": 6, "elite": false}]},
	# 17:00 Shogun Kurogane (BOSS_TIME): his six regiments are his own (ShogunData).
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES.
## `ground` is a KuroganeGround look:
##   style  — "bailey" (trampled earth), "gatehouse" (granite paving),
##            "courtyard" (raked gravel) or "keep" (dark floorboards).
##   base / line / accent / trim — colours of the code floor, its joints, its
##            pebbles and its needles / moss.
## Obstacle kinds (KuroganeGlyphs without art; obstacles/<kind>_<size>[_v]):
##   castle_wall    — a length of the castle's stone wall, plaster and tiles (rect)
##   palisade_gate  — a timber gate fence, iron studs and a red beam (rect)
##   black_pine     — a twisted garden pine (circle)
##   garden_rock    — a mossy garden boulder (circle)
##   sake_barrels   — three straw-wrapped sake barrels (circle)
##   taiko_drum     — a red war drum on its stand (circle)
##   stone_lantern  — the shared Act V toro, lit by the Sun's Course at night (circle)
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Outer Bailey",  # Owner-approved proposal (zones)
		"blurb": "Trampled earth under the castle's outer walls",
		"ground": {"style": "bailey", "base": Color(0.13, 0.11, 0.09), "line": Color(0.08, 0.07, 0.055),
			"accent": Color(0.30, 0.30, 0.31), "trim": Color(0.25, 0.32, 0.18)},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 1411,  # TUNING (not in GDD)
			"kinds": {
				"castle_wall": {"weight": 0.3, "shape": "rect", "sizes": [64.0, 88.0], "short": 24.0},  # TUNING (not in GDD)
				"black_pine": {"weight": 0.25, "shape": "circle", "sizes": [14.0, 18.0]},  # TUNING (not in GDD)
				"garden_rock": {"weight": 0.25, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD)
				"stone_lantern": {"weight": 0.2, "shape": "circle", "sizes": [10.0]},  # TUNING (not in GDD) lit at night (ShogunateGlyphs.LANTERN)
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Gatehouse",  # Owner-approved proposal (zones)
		"blurb": "Granite paving among the walls and gates",
		"ground": {"style": "gatehouse", "base": Color(0.13, 0.13, 0.15), "line": Color(0.07, 0.07, 0.085),
			"accent": Color(0.33, 0.34, 0.37), "trim": Color(0.2, 0.26, 0.17)},
		"arena": {"density": 0.2, "clear_radius": 230.0, "layout_seed": 1422,  # TUNING (not in GDD) lanes between the walls
			"kinds": {
				"castle_wall": {"weight": 0.42, "shape": "rect", "sizes": [64.0, 88.0], "short": 24.0},  # TUNING (not in GDD)
				"palisade_gate": {"weight": 0.38, "shape": "rect", "sizes": [56.0, 76.0], "short": 20.0},  # TUNING (not in GDD)
				"stone_lantern": {"weight": 0.2, "shape": "circle", "sizes": [10.0]},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Courtyards",  # Owner-approved proposal (zones)
		"blurb": "Raked gravel among the pines and the stone lanterns",
		"ground": {"style": "courtyard", "base": Color(0.14, 0.145, 0.165), "line": Color(0.09, 0.095, 0.11),
			"accent": Color(0.36, 0.37, 0.40), "trim": Color(0.22, 0.3, 0.18)},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 1433,  # TUNING (not in GDD)
			"kinds": {
				"black_pine": {"weight": 0.28, "shape": "circle", "sizes": [14.0, 18.0]},  # TUNING (not in GDD)
				"garden_rock": {"weight": 0.27, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD)
				"stone_lantern": {"weight": 0.3, "shape": "circle", "sizes": [10.0]},  # TUNING (not in GDD) the night's lit pools
				"sake_barrels": {"weight": 0.15, "shape": "circle", "sizes": [12.0]},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Keep",  # Owner-approved proposal (zones)
		"blurb": "The dark floorboards of the Shogun's keep",
		"ground": {"style": "keep", "base": Color(0.14, 0.10, 0.075), "line": Color(0.07, 0.05, 0.035),
			"accent": Color(0.30, 0.22, 0.15), "trim": Color(0.42, 0.10, 0.10)},
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 1444,  # TUNING (not in GDD)
			"kinds": {
				"castle_wall": {"weight": 0.32, "shape": "rect", "sizes": [64.0, 88.0], "short": 24.0},  # TUNING (not in GDD)
				"taiko_drum": {"weight": 0.24, "shape": "circle", "sizes": [14.0]},  # TUNING (not in GDD)
				"sake_barrels": {"weight": 0.2, "shape": "circle", "sizes": [12.0]},  # TUNING (not in GDD)
				"stone_lantern": {"weight": 0.24, "shape": "circle", "sizes": [10.0]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "CASTLE KUROGANE  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(0.886, 0.349, 0.290),  # Lacquer light (Palette.SHOGUN_LACQUER_LIGHT), never the UI's soul-teal.
	"fog_color": Color(0.08, 0.07, 0.07),  # Castle smoke.
	"fog_bank_color": Color(0.30, 0.27, 0.26),  # Smoke banks.
	"zones": ZONES,
}

## Castle Kurogane's stage systems (KuroganeDirector; StageRegistry "kurogane").
##   general_objective — HUD objective while the General of the Left rides.
##   army_objective    — HUD objective while the Shogun commands from his
##                       platform (soldiers left, banners broken, regiments).
const KUROGANE := {
	"general_objective": "Bring down the General of the Left: step out of his charging lane",  # TUNING (not in GDD)
	"army_objective": "The Shogun's army: %d soldiers left | banners broken %d / %d",  # TUNING (not in GDD)
}

## Shogun Kurogane's arrival (keys as GraveyardStage.BOSS): his own
## ShogunData.ARRIVAL (boss id "shogun"), whose `time` equals BOSS_TIME (17:00).
## His script is scripts/enemies/shogunate/boss_shogun.gd (loaded by his id).
const BOSS: Dictionary = ShogunData.ARRIVAL

## Placeholder floor of the foundation stub (ShogunateGround "floor" key), kept
## for the other tools that read it; the stage draws KuroganeGround ("ground").
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
	"playable": false,  # Act V phase 2: built; the lead turns it on after the merge, the review and the owner's playtest.
	"description": "The Shogun's fortress: stone walls, gates, courtyards and the keep. His regiments are his strength: break their banners and he draws his own blade.",
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
	"arena": ZONES[0]["arena"],
	"ground": "kurogane",  # KuroganeGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"kurogane": KUROGANE,  # KuroganeDirector: the General of the Left, the army objective.
	"shogunate": true,  # Act V: the Sun's Course, the Draw, From the Shadows (ShogunateRules).
	"sun": SUN,  # Act V: this stage's Sun's Course overrides (the castle's phase banners).
	"music": "sun",  # "The Setting Sun" (SoundData.SUN_SCORE), which also loads the Shogunate sound pack
}
