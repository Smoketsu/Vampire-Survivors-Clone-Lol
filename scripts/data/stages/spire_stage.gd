## SpireStage — STAGE 6, UL-THALOS, THE RISEN SPIRE, the finale of Act II (the
## Ancient Eye; GDD §15.0 "Act II: the Ancient Eye" and "Ul-Thalos, the Risen
## Spire", owner-approved proposal with the faction renamed the Ancient Eye).
## The god's city surfaces in the open ocean: wet green stone and wrong angles
## around a spire where the god lies dreaming. Every number and event that
## belongs to this stage; StageRegistry exposes it to the run as
## `Game.stage_def` (the STAGE dictionary at the bottom; its keys are
## documented in StageRegistry). Unlocked by slaying the Archivist once.
##
## THE CLOCK IS AUTHORITATIVE, as on the Crimson March and in the Sanctum:
## four zones on fixed times (ZONES, run by MarchDirector: a zone banner, a
## sweep of sea mist, the obstacles and floor re-drawn as the next zone), and
## at each zone change THE SINKING (SinkingDirector, SINKING): the island is a
## circle around the spire (the world origin) whose outer ring floods. The new
## shoreline is telegraphed SINKING.telegraph_lead s before the zone starts,
## then the sea rises over SINKING.flood_time s. Deep water cannot be walked:
## it works like the edge of the world (Arena push-out), so nobody is ever
## left in it, and the cultists climb out of the sea at the shore.
##   20:00  Zone I,   the Breakwater:    the full island, the Eye's last free congregation
##   15:00  Zone II,  the Sunken Steps:  the outer ring floods; Spawns of the Deep appear
##   10:00  Zone III, the Dream Gate:    half the island gone; Hierophants guard the gate;
##                                        three dream pillars rise (optional, SpireDirector)
##    5:00  Zone IV,  the Spire:         a small island around the spire
##    3:00  Vhal'Neth, the Dreaming Mother (BossVhalneth; one more Dreaming arm
##          per dream pillar still standing)
##    0:00  THE WAKING: the stage's Reckoning (its own kind, the Dreamspawn), and
##          the last of the island sinks (SINKING.waking_radius).
## No miniboss: the Hierophants are elites and the stage saves its weight for
## the finale. Kinds of the earlier Act II stages (Gullhaven, the Archive)
## join as guest squads when their data exists in the build (SpireDirector,
## SPIRE.guests): each kind stays in play on the stages after it. It is the
## hardest timeline of the act. Every rate, cap and weight is TUNING (not in GDD).
class_name SpireStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "spire"

# =====================================================================================
# Stage 6 kinds
# =====================================================================================

## Stage-local enemy kind aliases (StageRegistry "kind_aliases"): every
## timeline entry names its Ancient Eye kinds by these short keys;
## EnemyDirector.resolve_kind() maps them to the real kind.
##   initiate   -> Initiate of the Eye     (EyeEnemyData)
##   chanter    -> Chanter of the Eye      (EyeEnemyData)
##   siren      -> Siren of the Eye        (SpireEnemyData)
##   spawn      -> Spawn of the Deep       (SpireEnemyData)
##   hierophant -> Hierophant of the Eye   (SpireEnemyData)
##   pillar     -> Dream Pillar            (SpireEnemyData)
##   waking     -> Dreamspawn of the Waking (SpireEnemyData, the Reckoning)
const KINDS := {
	"initiate": "eye_initiate",
	"chanter": "eye_chanter",
	"siren": "eye_siren",
	"spawn": "eye_spawn",
	"hierophant": "eye_hierophant",
	"pillar": "dream_pillar",
	"waking": "eye_waking_horror",
}

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (the last stage of Act II: above the Sanctum's 1.1).
const ENEMY_HP_MULT: float = 1.25  # TUNING (not in GDD) the act climbs stage by stage
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.25  # TUNING (not in GDD)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies: Zone II, the Sunken Steps (the boss always gets them). From 0:00
## they would lift an Initiate past the starting Shadow Bolt's one-shot.
const ENEMY_MULT_FROM: float = 300.0  # TUNING (not in GDD) Zone II
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 2.25  # TUNING (not in GDD) owner-approved proposal placeholder (Act I: x1.25, x1.5)

## The Waking: the Reckoning of Ul-Thalos (keys as GraveyardStage.RECKONING
## plus "kind", the main wave's kind alias, and "companions" as the
## Sanctum's): the Dreamspawn of the Waking march with Spawns of the Deep,
## and the island sinks to SINKING.waking_radius.
const RECKONING := {
	"banner": "THE WAKING: VHAL'NETH'S DREAM SWALLOWS THE ISLAND",
	"kind": "waking",  # The Dreamspawn of the Waking (SpireEnemyData).
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 3,  # TUNING (not in GDD)
	"count_growth": 2,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
	"companions": [{"kind": "spawn", "count": 1, "growth": 0.5}],  # TUNING (not in GDD) Spawns of the Deep rise with them
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE WAKING: the god's dream drowns the island. Endure."

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments, sorted by start time (keys as
## GraveyardStage.SEGMENTS; kind keys are KINDS aliases). The elites (Sirens,
## Hierophants) come only in the scripted waves; Spawns of the Deep trickle
## from the Sunken Steps on (thinly: 2.5-6.5%; balance pass 1 cut them by
## about 40%, they and their grabs dealt most of the damage to the army). The Spire's caps stay below the Sanctum's peak:
## the island is small by then and every cultist climbs out at its shore.
const SEGMENTS := [
	# Zone I, the Breakwater: the Eye's last free congregation.
	{"start": 0.0, "rate": 1.6, "max_alive": 36,  # TUNING (not in GDD)
		"weights": {"initiate": 0.95, "chanter": 0.05},
		"objective": "The Breakwater: the Eye's last congregation gathers"},
	{"start": 60.0, "rate": 2.0, "max_alive": 46,  # TUNING (not in GDD)
		"weights": {"initiate": 0.93, "chanter": 0.07},
		"objective": "Chanters lead the faithful: kill them before they claim your dead"},
	{"start": 120.0, "rate": 2.4, "max_alive": 56,  # TUNING (not in GDD)
		"weights": {"initiate": 0.91, "chanter": 0.09},
		"objective": "Sirens sing from the breakwater"},
	{"start": 180.0, "rate": 2.7, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"initiate": 0.91, "chanter": 0.09},
		"objective": "The sea is rising: watch the shoreline"},
	{"start": 240.0, "rate": 3.0, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"initiate": 0.9, "chanter": 0.1},
		"objective": "The outer ring will flood: fall back toward the spire"},
	# Zone II, the Sunken Steps: Spawns of the Deep.
	{"start": 300.0, "rate": 3.2, "max_alive": 80,  # TUNING (not in GDD)
		"weights": {"initiate": 0.875, "chanter": 0.1, "spawn": 0.025},
		"objective": "The Sunken Steps: Spawns of the Deep crawl out of the flood"},
	{"start": 360.0, "rate": 3.5, "max_alive": 90,  # TUNING (not in GDD)
		"weights": {"initiate": 0.87, "chanter": 0.1, "spawn": 0.03},
		"objective": "Break the grip of the deep"},
	{"start": 420.0, "rate": 3.3, "max_alive": 88,  # TUNING (not in GDD) lull
		"weights": {"initiate": 0.87, "chanter": 0.1, "spawn": 0.03},
		"objective": "The steps descend into the sea"},
	{"start": 480.0, "rate": 3.8, "max_alive": 98,  # TUNING (not in GDD)
		"weights": {"initiate": 0.855, "chanter": 0.1, "spawn": 0.045},
		"objective": "The Dream Gate lies beyond the steps"},
	{"start": 540.0, "rate": 4.1, "max_alive": 106,  # TUNING (not in GDD)
		"weights": {"initiate": 0.855, "chanter": 0.1, "spawn": 0.045},
		"objective": "The sea is rising again: half the island will go"},
	# Zone III, the Dream Gate: Hierophants (waves) and the dream pillars.
	{"start": 600.0, "rate": 4.3, "max_alive": 112,  # TUNING (not in GDD)
		"weights": {"initiate": 0.85, "chanter": 0.1, "spawn": 0.05},
		"objective": "The Dream Gate: Hierophants guard it; break their Ascension"},
	{"start": 660.0, "rate": 4.6, "max_alive": 120,  # TUNING (not in GDD)
		"weights": {"initiate": 0.845, "chanter": 0.1, "spawn": 0.055},
		"objective": "Topple the dream pillars to weaken the god's dream"},
	{"start": 720.0, "rate": 4.4, "max_alive": 118,  # TUNING (not in GDD) lull
		"weights": {"initiate": 0.845, "chanter": 0.1, "spawn": 0.055},
		"objective": "The god dreams beneath the gate"},
	{"start": 780.0, "rate": 4.9, "max_alive": 128,  # TUNING (not in GDD)
		"weights": {"initiate": 0.84, "chanter": 0.1, "spawn": 0.06},
		"objective": "The faithful pour through the Dream Gate"},
	{"start": 840.0, "rate": 5.2, "max_alive": 134,  # TUNING (not in GDD)
		"weights": {"initiate": 0.84, "chanter": 0.1, "spawn": 0.06},
		"objective": "The sea is rising: only the spire will remain"},
	# Zone IV, the Spire: a small island; the density peak of the run.
	{"start": 900.0, "rate": 5.0, "max_alive": 124,  # TUNING (not in GDD) a small island: a lower cap, a higher pace
		"weights": {"initiate": 0.835, "chanter": 0.1, "spawn": 0.065},
		"objective": "The Spire: the last stone above the sea"},
	{"start": 960.0, "rate": 5.4, "max_alive": 130,  # TUNING (not in GDD)
		"weights": {"initiate": 0.835, "chanter": 0.1, "spawn": 0.065},
		"objective": "The Dreaming Mother stirs beneath the spire"},
	# 17:00, the boss: a thinner trickle so the fight stays readable.
	{"start": BOSS_TIME, "rate": 3.0, "max_alive": 86,  # TUNING (not in GDD)
		"weights": {"initiate": 0.87, "chanter": 0.08, "spawn": 0.05},
		"objective": "Sever her arms and break the Dreaming Mother"},
	{"start": 1110.0, "rate": 3.6, "max_alive": 98,  # TUNING (not in GDD)
		"weights": {"initiate": 0.86, "chanter": 0.08, "spawn": 0.06},
		"objective": "Sever her arms and break the Dreaming Mother"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave": formation + groups; kind keys are KINDS aliases), plus:
##   "pillars" — SpireDirector raises `count` dream pillars (kind `kind`)
##               `distance_min`..`distance_max` px from the island's centre
##               (always inside the Spire's last shoreline, so they never
##               sink), spread evenly, each with `guards` beside it. Optional:
##               each one toppled pays `reward_xp` in `reward_crystals` and
##               SPIRE.ash_per_pillar Soul Ash; each one still standing when
##               Vhal'Neth arrives gives her opening phase one more arm.
const EVENTS := [
	# Zone I: the Breakwater. Initiates only at first (the Act I lesson:
	# armoured kinds in the first minute starve the starting army).
	{"time": 15.0, "type": "wave", "banner": "Initiates of the Eye wade up the breakwater!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "initiate", "count": 8, "elite": false}]},
	{"time": 50.0, "type": "wave", "banner": "A Chanter leads its squad: it claims the dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "chanter", "count": 1, "elite": false}, {"kind": "initiate", "count": 10, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "The congregation rises out of the surf!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "initiate", "count": 14, "elite": false}]},
	{"time": 125.0, "type": "wave", "banner": "An elder Chanter marches on the spire!", "formation": "line",  # TUNING (not in GDD) first elite
		"groups": [{"kind": "chanter", "count": 1, "elite": true}, {"kind": "initiate", "count": 12, "elite": false}]},
	{"time": 150.0, "type": "wave", "banner": "A Siren of the Eye sings: her song lures your dead!", "formation": "arc",  # TUNING (not in GDD) GDD §15.0 Siren of the Eye
		"groups": [{"kind": "siren", "count": 1, "elite": false}, {"kind": "initiate", "count": 8, "elite": false}]},
	{"time": 200.0, "type": "wave", "banner": "Two squads close in from the sea!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "chanter", "count": 2, "elite": false}, {"kind": "initiate", "count": 16, "elite": false}]},
	{"time": 250.0, "type": "wave", "banner": "Sirens lead the faithful along the breakwater!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "siren", "count": 2, "elite": false}, {"kind": "chanter", "count": 1, "elite": false}, {"kind": "initiate", "count": 10, "elite": false}]},
	# Zone II, the Sunken Steps (5:00): Spawns of the Deep.
	{"time": 305.0, "type": "wave", "banner": "SPAWNS OF THE DEEP crawl up the sunken steps!", "formation": "line",  # GDD §15.0 zone II
		"groups": [{"kind": "spawn", "count": 3, "elite": false}, {"kind": "initiate", "count": 10, "elite": false}]},
	{"time": 345.0, "type": "wave", "banner": "The congregation surrounds the steps!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "initiate", "count": 22, "elite": false}, {"kind": "chanter", "count": 2, "elite": false}]},
	{"time": 390.0, "type": "wave", "banner": "Sirens sing over the drowned steps!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "siren", "count": 2, "elite": false}, {"kind": "spawn", "count": 2, "elite": false}, {"kind": "initiate", "count": 8, "elite": false}]},
	{"time": 440.0, "type": "wave", "banner": "Chanters gather the faithful!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "chanter", "count": 1, "elite": true}, {"kind": "chanter", "count": 1, "elite": false}, {"kind": "initiate", "count": 20, "elite": false}]},
	{"time": 480.0, "type": "wave", "banner": "The deep sends its heavy spawn!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "spawn", "count": 4, "elite": false}, {"kind": "siren", "count": 1, "elite": false}]},
	{"time": 530.0, "type": "wave", "banner": "The faithful flood the steps!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "initiate", "count": 26, "elite": false}, {"kind": "chanter", "count": 3, "elite": false}]},
	{"time": 570.0, "type": "wave", "banner": "A choir of Sirens sings for the god!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "siren", "count": 3, "elite": false}, {"kind": "initiate", "count": 10, "elite": false}]},
	# Zone III, the Dream Gate (10:00): Hierophants and the dream pillars.
	{"time": 605.0, "type": "wave", "banner": "HIEROPHANTS guard the Dream Gate: break their Ascension!", "formation": "ring",  # GDD §15.0 zone III
		"groups": [{"kind": "hierophant", "count": 2, "elite": false}, {"kind": "chanter", "count": 1, "elite": false}, {"kind": "initiate", "count": 12, "elite": false}]},
	{"time": 625.0, "type": "pillars", "banner": "Three dream pillars feed the god's dream: topple them to weaken her!",  # GDD §15.0 dream pillars
		"kind": "pillar", "count": 3, "distance_min": 240.0, "distance_max": 330.0,  # TUNING (not in GDD) inside the Spire's last shoreline (SINKING)
		"reward_xp": 30, "reward_crystals": 6,  # TUNING (not in GDD)
		"guards": [{"kind": "hierophant", "count": 1, "elite": false}, {"kind": "initiate", "count": 3, "elite": false}]},  # TUNING (not in GDD)
	{"time": 680.0, "type": "wave", "banner": "Spawns of the Deep climb through the gate!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "spawn", "count": 4, "elite": false}, {"kind": "initiate", "count": 14, "elite": false}]},
	{"time": 720.0, "type": "wave", "banner": "Hierophants and Sirens lead the rite!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "hierophant", "count": 2, "elite": false}, {"kind": "siren", "count": 2, "elite": false}, {"kind": "initiate", "count": 6, "elite": false}]},
	{"time": 765.0, "type": "wave", "banner": "The whole congregation kneels at the gate!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "initiate", "count": 28, "elite": false}, {"kind": "chanter", "count": 3, "elite": false}, {"kind": "spawn", "count": 2, "elite": false}]},
	{"time": 820.0, "type": "wave", "banner": "Three Hierophants begin the Ascension!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "hierophant", "count": 3, "elite": false}, {"kind": "spawn", "count": 2, "elite": false}]},
	{"time": 865.0, "type": "wave", "banner": "The Sirens' song rolls across the gate!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "siren", "count": 3, "elite": false}, {"kind": "initiate", "count": 16, "elite": false}]},
	# Zone IV, the Spire (15:00): the last stone above the sea.
	{"time": 905.0, "type": "wave", "banner": "THE SPIRE: the Eye's last faithful rise around the god's dream!", "formation": "ring",  # GDD §15.0 zone IV
		"groups": [{"kind": "hierophant", "count": 2, "elite": false}, {"kind": "spawn", "count": 4, "elite": false}, {"kind": "initiate", "count": 14, "elite": false}]},
	{"time": 945.0, "type": "wave", "banner": "Sirens call from the spire's steps!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "siren", "count": 3, "elite": false}, {"kind": "chanter", "count": 2, "elite": false}, {"kind": "initiate", "count": 16, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The last congregation kneels before the spire!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hierophant", "count": 2, "elite": false}, {"kind": "spawn", "count": 3, "elite": false}, {"kind": "initiate", "count": 18, "elite": false}]},
	# 17:00 Vhal'Neth (BOSS_TIME), plus two sallies.
	{"time": 1080.0, "type": "wave", "banner": "The faithful throw themselves before their god!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "spawn", "count": 3, "elite": false}, {"kind": "siren", "count": 2, "elite": false}, {"kind": "initiate", "count": 14, "elite": false}]},
	{"time": 1140.0, "type": "wave", "banner": "Hierophants pray for the Waking!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hierophant", "count": 2, "elite": false}, {"kind": "initiate", "count": 20, "elite": false}]},
]

# =====================================================================================
# Zones, the sinking and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES
## plus `shore` (px: the island's radius once this zone's flood is over;
## SinkingDirector). `ground` is a SpireGround look:
##   style  — "breakwater" (wet green flagstones and tide pools), "steps"
##            (terraced stone stepping down into the sea), "gate" (dark basalt
##            veined with the dream's glow) or "spire" (the spiral stone of
##            the spire's foot).
##   base / line / accent / glow — colours of the code floor, its joints,
##            its decorations and the biolume veins.
## Obstacle kinds (cyclopean stone) are drawn by SpireTerrainGlyphs without art.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Breakwater", "shore": 1650.0,  # GDD §15.0 zone I; TUNING (not in GDD) radius
		"blurb": "Wet green stone and wrong angles, risen from the sea",
		"ground": {"style": "breakwater", "base": Color(0.10, 0.15, 0.14), "line": Color(0.07, 0.11, 0.10),
			"accent": Color(0.14, 0.22, 0.18), "glow": Color(0.42, 0.22, 0.48)},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 6611,  # TUNING (not in GDD)
			"kinds": {
				"cyclopean_block": {"weight": 0.45, "shape": "rect", "sizes": [56.0, 72.0, 88.0], "short": 30.0},  # TUNING (not in GDD)
				"barnacle_pillar": {"weight": 0.35, "shape": "circle", "sizes": [12.0, 15.0, 18.0]},  # TUNING (not in GDD)
				"fallen_idol": {"weight": 0.20, "shape": "rect", "sizes": [44.0, 56.0], "short": 24.0},  # TUNING (not in GDD)
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Sunken Steps", "shore": 1250.0,  # GDD §15.0 zone II "the outer ring floods"
		"blurb": "Terraces of green stone stepping down into the sea",
		"ground": {"style": "steps", "base": Color(0.09, 0.14, 0.14), "line": Color(0.06, 0.10, 0.10),
			"accent": Color(0.13, 0.20, 0.19), "glow": Color(0.42, 0.22, 0.48)},
		"arena": {"density": 0.24, "clear_radius": 220.0, "layout_seed": 6622,  # TUNING (not in GDD)
			"kinds": {
				"step_ruin": {"weight": 0.5, "shape": "rect", "sizes": [64.0, 80.0, 96.0], "short": 22.0},  # TUNING (not in GDD)
				"barnacle_pillar": {"weight": 0.3, "shape": "circle", "sizes": [12.0, 15.0, 18.0]},  # TUNING (not in GDD)
				"sunken_idol": {"weight": 0.2, "shape": "circle", "sizes": [20.0, 24.0]},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Dream Gate", "shore": 880.0,  # GDD §15.0 zone III "half the island is gone"
		"blurb": "Dark basalt veined with the light of the god's dream",
		"ground": {"style": "gate", "base": Color(0.10, 0.11, 0.13), "line": Color(0.07, 0.07, 0.09),
			"accent": Color(0.14, 0.15, 0.18), "glow": Color(0.52, 0.26, 0.58)},
		"arena": {"density": 0.22, "clear_radius": 220.0, "layout_seed": 6633,  # TUNING (not in GDD)
			"kinds": {
				"gate_pylon": {"weight": 0.5, "shape": "circle", "sizes": [14.0, 17.0, 20.0]},  # TUNING (not in GDD)
				"toppled_arch": {"weight": 0.5, "shape": "rect", "sizes": [60.0, 76.0], "short": 20.0},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Spire", "shore": 520.0,  # GDD §15.0 zone IV "a small island around the spire"
		"blurb": "The last stone above the sea, around the dreaming god",
		"ground": {"style": "spire", "base": Color(0.11, 0.12, 0.13), "line": Color(0.07, 0.08, 0.09),
			"accent": Color(0.15, 0.17, 0.18), "glow": Color(0.56, 0.28, 0.62)},
		"arena": {"density": 0.12, "clear_radius": 220.0, "layout_seed": 6644,  # TUNING (not in GDD) sparse: the island is small
			"kinds": {
				"spire_shard": {"weight": 1.0, "shape": "circle", "sizes": [11.0, 14.0]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "THE CITY SINKS  -  ZONE %s",
	"zone_color": Color(0.55, 0.85, 0.80),  # Drowned teal light (EyePalette), never the UI's soul-teal hue.
	"fog_color": Color(0.05, 0.10, 0.11),  # Sea mist.
	"fog_bank_color": Color(0.16, 0.28, 0.29),
	"zones": ZONES,
}

## The sinking (SinkingDirector; StageRegistry "sinking"). The island is a
## circle of ZONES[i].shore px around `center`.
##   center           — the spire: the island's centre (world px; the run starts here).
##   telegraph_lead   — s before a zone's start that its new shoreline is shown.
##   flood_time       — s the sea takes to rise to the new shoreline.
##   waking_radius    — px: the island at the end of the Waking's flood (0:00).
##   waking_flood_time — s that last flood takes.
##   obstacle_margin  — px: no obstacle centre this close to (or beyond) the
##                      shoreline being flooded to, so the shore stays free
##                      and nothing stands in the sea.
##   spawn_inset      — px: a cultist climbing out of the sea appears this far
##                      inside the shore.
##   spawn_gap        — px: least distance from the necromancer of such a
##                      shore spawn (it walks around the coast to find one).
##   emerge_interval  — s between two emerge splashes (drawing only).
##   contain_interval — physics ticks between the passes that move drops
##                      (crystals, power-ups, chests) out of the sea.
##   water / deep / foam / telegraph — colours (drawing only; the water tile
##                      tiles/spire_water replaces water / deep when it exists).
const SINKING := {
	"center": Vector2.ZERO,
	"telegraph_lead": 8.0,  # TUNING (not in GDD) proposal "the new shoreline telegraphed first"
	"flood_time": 20.0,  # Proposal: "the outer ring floods over 20 s"
	"waking_radius": 320.0,  # TUNING (not in GDD)
	"waking_flood_time": 45.0,  # TUNING (not in GDD)
	"obstacle_margin": 70.0,  # TUNING (not in GDD) >= the largest obstacle half-extent (48) + a body
	"spawn_inset": 26.0,  # TUNING (not in GDD)
	"spawn_gap": 300.0,  # TUNING (not in GDD) about half a screen
	"emerge_interval": 0.12,  # TUNING (not in GDD) visual
	"contain_interval": 6,  # TUNING (not in GDD)
	"water": Color(0.05, 0.14, 0.16),  # TUNING (not in GDD) drowned teal, darkest shade
	"deep": Color(0.02, 0.06, 0.08),  # TUNING (not in GDD)
	"foam": Color(0.50, 0.71, 0.67),  # TUNING (not in GDD) drowned_light
	"telegraph": Color(0.69, 0.30, 0.75),  # TUNING (not in GDD) the Eye's biolume (never gold, never the player's violet)
}

## Stage objectives run by SpireDirector (dream pillars, guest squads).
##   pillar_dread          — Dread per second on a necromancer within
##                           pillar_dread_radius px of a standing pillar ("it
##                           feeds the dream"; game.dread.add(.., "pillar")).
##   ash_per_pillar        — Soul Ash per toppled pillar ("objective_ash").
##   placement_tries       — attempts to find spaced, obstacle-free spots.
##   structure_spacing     — px; least distance between two pillars.
##   guest_first / guest_interval — game s of the first guest squad / between two.
##   guest_until           — no guest squad after this game time.
##   guest_count / guest_growth — kinds in a squad: count + floor(squads x growth), at most guest_max.
##   guests                — the earlier Act II stages' kinds, each a list of
##                           candidate kind ids (the first one this build knows,
##                           EnemyDirector.is_known_kind(); none = skipped) and a weight.
const SPIRE := {
	"pillar_dread": 2.5,  # TUNING (not in GDD)
	"pillar_dread_radius": 220.0,  # TUNING (not in GDD)
	"ash_per_pillar": 8,  # TUNING (not in GDD) "small"
	"placement_tries": 8,  # TUNING (not in GDD)
	"structure_spacing": 200.0,  # TUNING (not in GDD)
	"guest_first": 150.0,  # TUNING (not in GDD)
	"guest_interval": 80.0,  # TUNING (not in GDD)
	"guest_until": 1000.0,  # TUNING (not in GDD) the boss fight keeps its own roster
	"guest_count": 3,  # TUNING (not in GDD)
	"guest_growth": 0.4,  # TUNING (not in GDD)
	"guest_max": 8,  # TUNING (not in GDD)
	"guests": [
		{"ids": ["eye_deep_kin", "deep_kin"], "weight": 1.0},  # Gullhaven Harbour (Act II phase 2)
		{"ids": ["eye_tide_caller", "tide_caller"], "weight": 0.6},
		{"ids": ["eye_netcaster", "netcaster"], "weight": 0.6},
		{"ids": ["eye_scribe", "scribe", "scribe_of_the_unwritten"], "weight": 0.5},  # The Hollow Archive (Act II phase 2)
		{"ids": ["eye_ink_wraith", "ink_wraith"], "weight": 0.7},
		{"ids": ["eye_spore_pilgrim", "eye_pilgrim", "pilgrim_of_the_spore", "spore_pilgrim"], "weight": 0.6},
		{"ids": ["eye_gibbering_mass", "gibbering_mass"], "weight": 0.5},
	],
}

## Vhal'Neth's arrival (keys as GraveyardStage.BOSS): her own
## VhalnethData.ARRIVAL (boss id "vhalneth", the ending text as the defeat
## banner), whose `time` equals BOSS_TIME (17:00).
const BOSS: Dictionary = VhalnethData.ARRIVAL

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Ul-Thalos, the Risen Spire",
	"short_name": "Ul-Thalos",
	"chapter": "Chapter VI",
	"act": 2,  # Act II, the Ancient Eye.
	"playable": false,  # The lead flips it after integration (Act II phase 2 gate).
	"description": "The god's city surfaces mid-ocean: wet green stone and wrong angles around the spire where it lies dreaming. The city sinks back as the clock runs; at its heart Vhal'Neth, the Dreaming Mother, wakes. She is dead. Raise her.",
	"unlock": {"stage": "archive", "boss_kills": 1},  # owner-approved: each boss unlocks the next stage
	"unlock_text": "Slay the Archivist in the Hollow Archive to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act II stages.
	"consecration": {},  # A Covenant event: none in Act II.
	"crypt_defender": {},  # None in Act II.
	"arena": ZONES[0]["arena"],
	"ground": "spire",
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,
	"sinking": SINKING,  # SinkingDirector (the island shrinks with the zones).
	"spire": SPIRE,  # SpireDirector (dream pillars, guest squads).
	"kind_aliases": KINDS,
	"dread": true,  # Act II: Dread on the necromancer (DreadMeter).
	"claims": true,  # Act II: the Ancient Eye claims the fallen (EyeClaims).
	"music": "tide",  # Act II run loop "Below the Tide" (RunLoopSynth).
}
