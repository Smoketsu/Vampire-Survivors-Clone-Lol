## ProvinceStage — STAGE 13, THE BURNING PROVINCE (Act V, the Shogunate of the
## Rising Sun; GDD §15.0 "Act V foundation (phase 1)" and "The Burning Province
## (Act V phase 2)"; owner-approved proposal docs/act5/PROPOSAL.md "Stage 13:
## The Burning Province"). Rice terraces, bamboo groves, a village in flames:
## the war has reached the countryside. Every number and event that belongs to
## this stage; StageRegistry exposes it to the run as `Game.stage_def` (the
## STAGE dictionary at the bottom; its keys are documented in StageRegistry).
## Unlocked by making Hades kneel once (the first stage of Act V).
##
## THE CLOCK IS AUTHORITATIVE, as on every stage since the Crimson March: four
## zones on fixed times (ZONES, run by MarchDirector: a zone banner, a sweep of
## smoke, the obstacles and floor re-drawn as the next zone). The Sun's Course
## (the act's rule) runs over it: day to 13:00 left, dusk to 7:00, then night.
##   20:00  Zone I,   the Paddies:          flooded rice terraces; the paddy
##                                          water slows everyone but the kappa
##   15:00  Zone II,  the Bamboo Grove:     dense bamboo, ninja heaven; dusk
##                                          falls at 13:00 and the ambushes
##                                          come thick and fast
##   10:00  Zone III, the Burning Village:  burning houses; fire flares beside
##                                          them; night falls at 7:00, the
##                                          kappa leave the irrigation ponds
##    6:00  Shuten-dōji, the Oni King (night only)
##    5:00  Zone IV,  the Mountain Shrine:  the shrine's stone lanterns light
##                                          the night
##    3:00  Kage, Mistress of the Hidden Hand (BossKage)
##    0:00  the Endless Night (the shared Act V Reckoning: the sun never rises)
## The stage systems run in ProvinceDirector (PROVINCE): THE PADDIES (the
## water through TerrainSlow, the one ground-slow path), THE VILLAGE FIRES
## (fire patches beside the burning houses, drawn as textures:
## ProvinceHazards), SHUTEN-DŌJI (the miniboss event) and the achievement NO
## SHADOW UNLIT (lanterns lit). Every rate, cap and weight is TUNING (not in GDD).
class_name ProvinceStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "province"

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act V starts a step above the Asphodel Underworld's 1.5; the step goes in HP,
## not damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 1.55  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling (the
## Underworld's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Acts III and IV: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 1 of Act V

## Game time (s) dusk falls: the timeline below starts its ambush trickle then.
## Must equal the Sun's Course's dusk_at (ShogunateRulesData.SUN, or this
## stage's SUN override); ShadowAmbush itself waits for dusk either way.
const DUSK: float = 420.0  # Owner-approved proposal: 13:00 left
## Game time (s) night falls: the night segment starts then (its night kinds
## join through the timeline helper whatever this says). Must equal night_at.
const NIGHT: float = 780.0  # Owner-approved proposal: 7:00 left

## The Sun's Course on this stage: {} = the defaults of ShogunateRulesData.SUN,
## plus the stage's own dusk and night banners.
const SUN := {
	"dusk_banner": "Dusk over the bamboo: the shadows lengthen. Ninja!",  # TUNING (not in GDD)
	"night_banner": "Night falls on the burning village: the oni and the kappa walk. Keep to the light!",  # TUNING (not in GDD)
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Endless
## Night, shared by every Act V stage: the sun never rises; oni ("kind") with
## every night kind at once (the onryo and this stage's kappa as
## "companions"), faster each minute ("endless_night":
## ShogunateRulesData.ENDLESS_NIGHT keys; {} = those defaults).
const RECKONING := {
	"banner": "THE ENDLESS NIGHT: THE SUN NEVER RISES",
	"kind": ShogunateEnemyData.ONI,  # The shared Endless Night kind.
	"endless_night": {},  # ShogunateRulesData.ENDLESS_NIGHT defaults.
	"companions": [
		{"kind": ShogunateEnemyData.ONRYO, "count": 6, "growth": 1.0},  # TUNING (not in GDD) every night kind at once
		{"kind": ProvinceEnemyData.KAPPA, "count": 4, "growth": 1.0},  # TUNING (not in GDD) the Province's night yokai (the brief: phase 2 adds the kappa)
	],
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
## GraveyardStage.SEGMENTS, plus the Act V keys "night_weights" (kinds that
## join only at night, through the timeline helper SunCourse.timeline_weights())
## and "ambush" (ShadowAmbush's trickle: a squad of `count` `kind` every
## `every` s, from dusk on)). Ashigaru are the fodder, samurai the soldiers,
## teppo gunners the ranged line; from dusk the ninja come out of the shadows
## (most often in the Bamboo Grove); at night the onryo, the kappa and the oni.
const SEGMENTS := [
	# Zone I, the Paddies (day).
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"ashigaru": 1.0},
		"objective": "The Paddies: spear levies wade in through the water"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.78, "samurai": 0.22},
		"objective": "The paddy water slows everyone: fight on the dikes"},
	{"start": 180.0, "rate": 2.0, "max_alive": 48,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.62, "samurai": 0.26, "teppo_gunner": 0.12},
		"objective": "Samurai close in: when one draws, step out of the white line"},
	# Zone II, the Bamboo Grove (day, then dusk: ninja heaven).
	{"start": 300.0, "rate": 2.2, "max_alive": 54,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.58, "samurai": 0.28, "teppo_gunner": 0.14},
		"objective": "The Bamboo Grove: the stalks hide the gunners"},
	{"start": DUSK, "rate": 2.4, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.55, "samurai": 0.3, "teppo_gunner": 0.15},
		"ambush": {"every": 22.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD) the grove is ninja heaven (the stub's 45)
		"objective": "Dusk in the bamboo: ninja come out of every shadow"},
	{"start": 510.0, "rate": 2.6, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.52, "samurai": 0.32, "teppo_gunner": 0.16},
		"ambush": {"every": 20.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "Keep your blockers inside the ring: the ninja strike from the smoke"},
	# Zone III, the Burning Village (dusk, then night).
	{"start": 600.0, "rate": 2.8, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.5, "samurai": 0.33, "teppo_gunner": 0.17},
		"ambush": {"every": 32.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "The Burning Village: keep out of the flames"},
	{"start": NIGHT, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.36, "samurai": 0.3, "teppo_gunner": 0.12},
		"night_weights": {"onryo": 0.42, "kappa": 0.3, "oni": 0.012},  # TUNING (not in GDD) the yokai join at night
		"ambush": {"every": 30.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "Night: the kappa leave the ponds, the oni walk"},
	# Zone IV, the Mountain Shrine (night).
	{"start": 900.0, "rate": 3.3, "max_alive": 92,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.32, "samurai": 0.3, "teppo_gunner": 0.12},
		"night_weights": {"onryo": 0.42, "kappa": 0.26, "oni": 0.014},  # TUNING (not in GDD)
		"ambush": {"every": 28.0, "kind": "ninja", "count": 3},  # TUNING (not in GDD)
		"objective": "The Mountain Shrine: fight in the lanterns' light"},
	# 17:00, the boss: a thinner trickle so the fight stays readable.
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"ashigaru": 0.3, "samurai": 0.3, "teppo_gunner": 0.1},
		"night_weights": {"onryo": 0.4, "kappa": 0.2, "oni": 0.008},  # TUNING (not in GDD)
		"ambush": {"every": 40.0, "kind": "ninja", "count": 2},  # TUNING (not in GDD)
		"objective": "Only one Kage is real: the light shows her shadows false"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave": formation + groups), plus the Act V type "ambush" (its groups go to
## ShadowAmbush, which waits for dusk and shows the banner when the squad
## appears) and the Burning Province's own (ProvinceDirector):
##   "shuten_doji" — Shuten-dōji, the Oni King (kind `kind`) staggers in from
##                   the spawn ring; NIGHT ONLY (owner-approved proposal): an
##                   event before nightfall waits for the night.
const EVENTS := [
	# Zone I: the Paddies.
	{"time": 20.0, "type": "wave", "banner": "Spear levies wade through the paddies in wide ranks!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "ashigaru", "count": 16, "elite": false}]},
	{"time": 110.0, "type": "wave", "banner": "An arquebus line on the dikes: rush them while they reload!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "teppo_gunner", "count": 5, "elite": false}, {"kind": "ashigaru", "count": 8, "elite": false}]},
	{"time": 200.0, "type": "wave", "banner": "A samurai lays his hand on the hilt: step out of the white line!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "samurai", "count": 1, "elite": true}, {"kind": "samurai", "count": 4, "elite": false}]},
	{"time": 270.0, "type": "wave", "banner": "The levies close in from every side!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "ashigaru", "count": 16, "elite": false}, {"kind": "samurai", "count": 1, "elite": true}, {"kind": "samurai", "count": 3, "elite": false}]},
	# Zone II (5:00): the Bamboo Grove; dusk at 7:00.
	{"time": 330.0, "type": "wave", "banner": "Gunners fire through the bamboo!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "teppo_gunner", "count": 7, "elite": false}, {"kind": "ashigaru", "count": 10, "elite": false}]},
	{"time": 435.0, "type": "ambush", "banner": "Ninja! Out of the bamboo shadows!",  # TUNING (not in GDD)
		"groups": [{"kind": "ninja", "count": 4, "elite": false}]},
	{"time": 480.0, "type": "ambush", "banner": "A KUNOICHI: her smoke blinds your dead!",  # TUNING (not in GDD) the Kunoichi's first entrance
		"groups": [{"kind": "kunoichi", "count": 1, "elite": true}, {"kind": "ninja", "count": 2, "elite": false}]},
	{"time": 540.0, "type": "wave", "banner": "Duelists in the dusk!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "samurai", "count": 2, "elite": true}, {"kind": "samurai", "count": 3, "elite": false}, {"kind": "ashigaru", "count": 8, "elite": false}]},
	{"time": 575.0, "type": "ambush", "banner": "Smoke! They are among your dead!",  # TUNING (not in GDD)
		"groups": [{"kind": "kunoichi", "count": 1, "elite": true}, {"kind": "ninja", "count": 4, "elite": false}]},
	# Zone III (10:00): the Burning Village; night at 13:00.
	{"time": 640.0, "type": "wave", "banner": "Gunners and duelists among the burning houses!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "teppo_gunner", "count": 8, "elite": false}, {"kind": "samurai", "count": 2, "elite": true}]},
	{"time": 700.0, "type": "ambush", "banner": "Ninja in the smoke of the village!",  # TUNING (not in GDD)
		"groups": [{"kind": "kunoichi", "count": 2, "elite": true}, {"kind": "ninja", "count": 3, "elite": false}]},
	{"time": 750.0, "type": "wave", "banner": "Duelists draw in the failing light!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "samurai", "count": 2, "elite": true}, {"kind": "samurai", "count": 3, "elite": false}, {"kind": "ashigaru", "count": 10, "elite": false}]},
	{"time": 800.0, "type": "wave", "banner": "KAPPA crawl out of the irrigation ponds!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "kappa", "count": 12, "elite": false}, {"kind": "onryo", "count": 8, "elite": false}]},
	{"time": 840.0, "type": "shuten_doji", "banner": "SHUTEN-DŌJI, THE ONI KING, staggers out of the night: sake barrels fall!",  # Owner-approved proposal (miniboss, night only); 6:00 left
		"kind": "shuten_doji", "elite": false},
	{"time": 870.0, "type": "ambush", "banner": "Kunoichi in the dark!",  # TUNING (not in GDD)
		"groups": [{"kind": "kunoichi", "count": 2, "elite": true}, {"kind": "ninja", "count": 4, "elite": false}]},
	# Zone IV (15:00): the Mountain Shrine.
	{"time": 920.0, "type": "wave", "banner": "An oni walks the shrine steps!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "oni", "count": 1, "elite": false}, {"kind": "onryo", "count": 10, "elite": false}, {"kind": "kappa", "count": 6, "elite": false}]},
	{"time": 965.0, "type": "wave", "banner": "The night host gathers at the shrine!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "samurai", "count": 2, "elite": true}, {"kind": "samurai", "count": 4, "elite": false}, {"kind": "oni", "count": 2, "elite": false}, {"kind": "kappa", "count": 8, "elite": false}]},
	{"time": 995.0, "type": "ambush", "banner": "Kage's kunoichi come for you!",  # TUNING (not in GDD)
		"groups": [{"kind": "kunoichi", "count": 2, "elite": true}, {"kind": "ninja", "count": 4, "elite": false}]},
	# 17:00 Kage (BOSS_TIME), plus two sallies.
	{"time": 1085.0, "type": "ambush", "banner": "Her ninja strike from the smoke!",  # TUNING (not in GDD)
		"groups": [{"kind": "ninja", "count": 4, "elite": false}]},
	{"time": 1145.0, "type": "wave", "banner": "The last of the night host!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "samurai", "count": 4, "elite": false}, {"kind": "kappa", "count": 8, "elite": false}, {"kind": "onryo", "count": 10, "elite": false}]},
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES.
## `ground` is a ProvinceGround look:
##   style  — "paddies" (dark mud on the dikes), "bamboo" (leaf litter and
##            roots), "village" (trampled earth, ash and cinders) or "shrine"
##            (raked gravel and stepping stones).
##   base / line / accent / trim — colours of the code floor, its lines, its
##            stones / shoots and its water glint / embers / petals.
##   paddy  — share (0..1) of the terrace cells that hold paddy water
##            (ProvinceDirector.in_paddy(): the one geometry; the ground draws
##            the same cells; 0 = dry).
## A zone's `fires` (true) lets fire flare beside its burning houses
## (ProvinceDirector, PROVINCE fire_*).
## Obstacle kinds (ProvinceGlyphs without art; obstacles/<kind>_<size>[_v]):
##   stone_lantern — the shared tōrō the Sun's Course lights at night (circle)
##   rice_sheaves  — stacked straw rice sheaves on a drying frame (circle)
##   bamboo_stand  — a dense stand of tall bamboo (circle)
##   burning_house — a thatched farmhouse in flames (rect)
##   shrine_hall   — a small mountain shrine hall, red pillars, a curved roof (rect)
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Paddies",  # Owner-approved proposal (zones)
		"blurb": "Flooded rice terraces: the water slows every body but the kappa",
		"ground": {"style": "paddies", "base": Color(0.165, 0.145, 0.098), "line": Color(0.10, 0.09, 0.06),
			"accent": Color(0.30, 0.42, 0.22), "trim": Color(0.416, 0.510, 0.753), "paddy": 0.62},  # TUNING (not in GDD) most terraces flooded
		"arena": {"density": 0.12, "clear_radius": 220.0, "layout_seed": 1301,  # TUNING (not in GDD) open terraces
			"kinds": {
				"rice_sheaves": {"weight": 0.7, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD)
				"stone_lantern": {"weight": 0.3, "shape": "circle", "sizes": [10.0]},  # TUNING (not in GDD) the Sun's Course lights it at night
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Bamboo Grove",  # Owner-approved proposal (zones)
		"blurb": "Dense bamboo, deep shadows: ninja heaven",
		"ground": {"style": "bamboo", "base": Color(0.10, 0.12, 0.08), "line": Color(0.06, 0.075, 0.05),
			"accent": Color(0.36, 0.44, 0.22), "trim": Color(0.56, 0.52, 0.30), "paddy": 0.0},
		"arena": {"density": 0.34, "clear_radius": 230.0, "layout_seed": 1302,  # TUNING (not in GDD) dense obstacles (owner-approved "dense obstacles, ninja heaven")
			"kinds": {
				"bamboo_stand": {"weight": 0.88, "shape": "circle", "sizes": [12.0, 16.0, 20.0]},  # TUNING (not in GDD)
				"stone_lantern": {"weight": 0.12, "shape": "circle", "sizes": [10.0]},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Burning Village", "fires": true,  # Owner-approved proposal (zones)
		"blurb": "Thatched farmhouses burn; fire flares beside them",
		"ground": {"style": "village", "base": Color(0.13, 0.105, 0.085), "line": Color(0.07, 0.055, 0.045),
			"accent": Color(0.34, 0.30, 0.26), "trim": Color(0.886, 0.349, 0.290), "paddy": 0.16},  # TUNING (not in GDD) the village's irrigation ponds (the kappa's water at night)
		"arena": {"density": 0.2, "clear_radius": 230.0, "layout_seed": 1303,  # TUNING (not in GDD)
			"kinds": {
				"burning_house": {"weight": 0.55, "shape": "rect", "sizes": [56.0, 72.0], "short": 40.0},  # TUNING (not in GDD)
				"rice_sheaves": {"weight": 0.3, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD)
				"stone_lantern": {"weight": 0.15, "shape": "circle", "sizes": [10.0]},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Mountain Shrine",  # Owner-approved proposal (zones)
		"blurb": "The mountain shrine and its rows of stone lanterns",
		"ground": {"style": "shrine", "base": Color(0.17, 0.165, 0.16), "line": Color(0.10, 0.095, 0.09),
			"accent": Color(0.46, 0.45, 0.43), "trim": Color(0.894, 0.580, 0.675), "paddy": 0.08},  # TUNING (not in GDD) a few shrine ponds
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 1304,  # TUNING (not in GDD)
			"kinds": {
				"stone_lantern": {"weight": 0.55, "shape": "circle", "sizes": [10.0]},  # TUNING (not in GDD) rows of lanterns (No Shadow Unlit)
				"shrine_hall": {"weight": 0.45, "shape": "rect", "sizes": [52.0, 64.0], "short": 40.0},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "THE BURNING PROVINCE  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(0.886, 0.349, 0.290),  # Lacquer light (Palette.SHOGUN_LACQUER_LIGHT), never the UI's soul-teal.
	"fog_color": Color(0.16, 0.14, 0.13),  # Smoke of the burning countryside.
	"fog_bank_color": Color(0.30, 0.26, 0.24),
	"zones": ZONES,
}

## The Burning Province's stage systems (ProvinceDirector; StageRegistry "province").
##   paddy_cell        — px of one terrace cell (the paddy geometry, in_paddy()).
##   paddy_dike        — px of dry dike around each flooded paddy.
##   paddy_check       — s between two checks of who wades the water.
##   paddy_slow_player — fraction of speed the necromancer loses in the water
##                       (TerrainSlow, before Brinewalker).
##   paddy_slow_summon — fraction a summon loses (TerrainSlow).
##   paddy_slow_enemy  — fraction an enemy loses (Enemy.apply_slow(); a
##                       "swimmer" row, a floating body, a structure, the boss and
##                       a miniboss are never slowed).
##   paddy_linger      — s a slow lasts past the check.
##   fire_every        — s between two village fire flares (a zone with "fires").
##   fire_scan         — px around the necromancer the burning houses are searched.
##   fire_max          — village fires burning at once at most.
##   fire_radius       — px of one village fire.
##   fire_life         — s it burns.
##   fire_tick         — s between two burns.
##   fire_dmg_player / fire_dmg_summon / fire_dmg_enemy — damage of one burn
##                       (before the time scaling; the fire burns every body).
##   fire_gap          — px from the house's edge the fire flares.
##   no_shadow_lanterns — stone lanterns that must be lit in one Province run
##                       that slays Kage (the achievement No Shadow Unlit).
const PROVINCE := {
	"paddy_cell": 168.0,  # TUNING (not in GDD) px
	"paddy_dike": 18.0,  # TUNING (not in GDD) px
	"paddy_check": 0.25,  # TUNING (not in GDD) s
	"paddy_slow_player": 0.3,  # TUNING (not in GDD) (the harbour tide 0.3)
	"paddy_slow_summon": 0.3,  # TUNING (not in GDD)
	"paddy_slow_enemy": 0.3,  # TUNING (not in GDD) owner-approved "water slows everyone"
	"paddy_linger": 0.35,  # TUNING (not in GDD) s
	"fire_every": 2.2,  # TUNING (not in GDD) s
	"fire_scan": 460.0,  # TUNING (not in GDD) px
	"fire_max": 10,  # TUNING (not in GDD)
	"fire_radius": 30.0,  # TUNING (not in GDD) px
	"fire_life": 6.0,  # TUNING (not in GDD) s
	"fire_tick": 0.5,  # TUNING (not in GDD) s
	"fire_dmg_player": 2.5,  # TUNING (not in GDD) per burn
	"fire_dmg_summon": 2.5,  # TUNING (not in GDD) per burn
	"fire_dmg_enemy": 5.0,  # TUNING (not in GDD) per burn: lure them into the flames
	"fire_gap": 6.0,  # TUNING (not in GDD) px
	"no_shadow_lanterns": 20,  # TUNING (not in GDD) own decision on the owner-approved achievement name
}

## Kage's arrival (keys as GraveyardStage.BOSS): her own KageData.ARRIVAL (boss
## id "kage"), whose `time` equals BOSS_TIME (17:00). Her script is
## scripts/enemies/shogunate/boss_kage.gd (loaded by her id).
const BOSS: Dictionary = KageData.ARRIVAL

## Placeholder floor of the foundation stub (ShogunateGround "floor" key), kept
## for the other tools that read it; the stage draws ProvinceGround ("ground").
const FLOOR := {
	"style": "paddy",  # Dark paddy mud, rows of rice shoots, still water.
	"base": Color(0.19, 0.17, 0.11),  # TUNING (not in GDD) dark paddy mud
	"line": Color(0.19, 0.17, 0.12),  # TUNING (not in GDD)
	"accent": Color(0.30, 0.42, 0.22),  # TUNING (not in GDD) rice-shoot green
	"trim": Color(0.416, 0.510, 0.753),  # TUNING (not in GDD) indigo_light water glint
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Burning Province",
	"short_name": "The Province",
	"chapter": "Chapter XIII",
	"act": 5,  # Act V, the Shogunate of the Rising Sun.
	"playable": true,  # Owner decision (Oct 26, 2026): "Ship the curve" after the art review (four rounds) and three playtest passes (GDD §15.0 "Act V goes live").
	"description": "Rice terraces, bamboo groves and a village in flames: the Shogunate's armies have reached the countryside, and by night the old stories walk with them.",
	"unlock": {"stage": "underworld", "boss_kills": 1},  # Owner-approved: Hades's fall opens Act V
	"unlock_text": "Make Hades kneel in the Asphodel Underworld to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act V stages.
	"consecration": {},  # A Covenant event: none in Act V.
	"crypt_defender": {},  # None in Act V.
	"arena": ZONES[0]["arena"],
	"ground": "province",  # ProvinceGround: the four zone floors and the paddy water.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"province": PROVINCE,  # ProvinceDirector: the paddies, the village fires, Shuten-dōji, No Shadow Unlit.
	"shogunate": true,  # Act V: the Sun's Course, the Draw, From the Shadows (ShogunateRules).
	"sun": SUN,  # Act V: this stage's Sun's Course overrides (banners only).
	"zones": ZONES,  # Act V: the four zones (MarchDirector runs them through "march").
	"music": "sun",  # "The Setting Sun" (SoundData.SUN_SCORE), which also loads the Shogunate sound pack
}
