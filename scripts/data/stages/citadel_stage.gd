## CitadelStage — STAGE 9, THE IRON CITADEL (Act III, the Electronic Empire;
## GDD §15.0 "Act III foundation (phase 1)", owner-approved proposal
## "Necropathy: Act III Proposal (The Electronic Empire)"). Every number and
## event that belongs to this stage. StageRegistry exposes it to the run as
## `Game.stage_def` (the STAGE dictionary at the bottom; its keys are
## documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (Act III phase 1). The stage is registered, unlocked
## in the campaign chain (the Motherboard's fall opens it), runs the Empire's three
## shared rules (Line of Fire, Lock-On, Steel has no soul: "empire": true) and
## plays a simple timeline of the Empire's shared kinds (Scout Drones, Line
## Troopers, Spotters) against a PLACEHOLDER boss script ("seraphine" behind the
## boss id "deus_ex_machina", shown under Deus Ex Machina's name), with the Purge Protocol
## Reckoning (kill-drones and orbital strikes). It is hidden from the stage
## select ("playable": false) until phase 2 builds it: its four zones and
## floors, obstacles, its kinds, Deus Ex Machina with Varn, the Root User.
## Planned zones (clock-driven like every stage): four, changing with the
## clock; Deus Ex Machina descends with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD).
class_name CitadelStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "citadel"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act III starts at Act II's last step and climbs stage by stage).
const ENEMY_HP_MULT: float = 1.35  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.3  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (the Archive and Ul-Thalos: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 3.0  # TUNING (not in GDD) placeholder (the Assembly Halls x2.75)

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Purge
## Protocol, shared by every Act III stage: kill-drones pour in from every edge
## ("kind") while orbital strikes rain on telegraphed circles, faster each
## minute ("orbital": EmpireRulesData.PURGE keys; {} = those defaults).
const RECKONING := {
	"banner": "PURGE PROTOCOL: ORBITAL STRIKES INBOUND",
	"kind": EmpireEnemyData.KILL_DRONE,  # The shared Purge Protocol kind.
	"orbital": {},  # EmpireRulesData.PURGE defaults (phase 2 may tune them here).
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 4,  # TUNING (not in GDD) kill-drones come in numbers
	"count_growth": 3,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "PURGE PROTOCOL: the Empire deletes you. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): a plain
## ramp of the Empire's shared kinds (placeholder). Drones are the fodder, the
## Line Troopers the bulk of the fire, Spotters the rare elites.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.3, "max_alive": 28,  # TUNING (not in GDD)
		"weights": {"scout_drone": 1.0},
		"objective": "The Citadel's drones rise: hold your ground"},
	{"start": 60.0, "rate": 1.6, "max_alive": 38,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.9, "line_trooper": 0.1},
		"objective": "Line Troopers march in firing: your dead are cover"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.8, "line_trooper": 0.2},
		"objective": "Keep your dead between you and the guns"},
	{"start": 300.0, "rate": 2.4, "max_alive": 62,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.66, "line_trooper": 0.32, "spotter": 0.02},
		"objective": "Spotters paint their targets: step out of the red line"},
	{"start": 540.0, "rate": 3.0, "max_alive": 80,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.6, "line_trooper": 0.37, "spotter": 0.03},
		"objective": "The Empire advances"},
	{"start": 780.0, "rate": 3.5, "max_alive": 94,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.56, "line_trooper": 0.4, "spotter": 0.04},
		"objective": "Steel without end"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"scout_drone": 0.6, "line_trooper": 0.37, "spotter": 0.03},
		"objective": "Bring down Deus Ex Machina"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS): drone swarms,
## firing lines and Spotter teams.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A drone swarm sweeps in!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "scout_drone", "count": 10, "elite": false}]},
	{"time": 120.0, "type": "wave", "banner": "A firing line marches on you!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "line_trooper", "count": 4, "elite": false}, {"kind": "scout_drone", "count": 6, "elite": false}]},
	{"time": 210.0, "type": "wave", "banner": "A Spotter paints you: get behind your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 1, "elite": false}, {"kind": "line_trooper", "count": 6, "elite": false}]},
	{"time": 330.0, "type": "wave", "banner": "Two Spotter teams close in!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 2, "elite": false}, {"kind": "line_trooper", "count": 10, "elite": false}, {"kind": "scout_drone", "count": 10, "elite": false}]},
	{"time": 480.0, "type": "wave", "banner": "The Empire's line advances!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "line_trooper", "count": 16, "elite": false}, {"kind": "spotter", "count": 2, "elite": false}]},
	{"time": 720.0, "type": "wave", "banner": "Drones blot out the sky!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "scout_drone", "count": 30, "elite": false}, {"kind": "line_trooper", "count": 10, "elite": true}]},
	{"time": 960.0, "type": "wave", "banner": "The last battalion!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 3, "elite": false}, {"kind": "line_trooper", "count": 22, "elite": false}, {"kind": "scout_drone", "count": 16, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA). Placeholder kinds drawn by
## EmpireTerrainGlyphs until phase 2 brings the stage's own art.
const ARENA := {
	"density": 0.16,  # TUNING (not in GDD)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 7913,  # TUNING (not in GDD)
	"kinds": {
		"scrap_heap": {"weight": 0.55, "shape": "circle", "sizes": [13.0, 16.0, 20.0]},  # TUNING (not in GDD) placeholder art
		"steel_crate": {"weight": 0.3, "shape": "rect", "sizes": [44.0, 60.0, 76.0], "short": 26.0},  # TUNING (not in GDD) placeholder art
		"signal_pylon": {"weight": 0.15, "shape": "circle", "sizes": [10.0, 12.0]},  # TUNING (not in GDD) placeholder art
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "seraphine" boss
## script under Deus Ex Machina's name until phase 2 adds
## scripts/enemies/empire/boss_deus_ex_machina.gd (then remove the "script" key).
const BOSS := {
	"id": "deus_ex_machina",
	"script": "seraphine",  # PLACEHOLDER boss script until phase 2 adds boss_deus_ex_machina.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "Deus Ex Machina",
	"short_name": "Deus Ex Machina",
	"arrive_banner": "Deus Ex Machina descends, Varn, the Root User, at the controls!",
	"defeat_banner": "Deus Ex Machina falls! Hold out until the end...",
	"dead_objective": "Deus Ex Machina is scrap. Survive until the countdown ends.",
}

## Placeholder floor (EmpireGround, code-drawn) until phase 2 brings the
## stage's zone floors: base colour, joint lines, accent stripes, style.
const FLOOR := {
	"style": "citadel",  # Dark iron panels with glowing signal lines.
	"base": Color(0.075, 0.08, 0.10),  # TUNING (not in GDD) dark iron
	"line": Color(0.12, 0.13, 0.17),  # TUNING (not in GDD)
	"accent": Color(0.26, 0.31, 0.39),  # TUNING (not in GDD) chrome scrap plates
	"trim": Color(1.0, 0.682, 0.102),  # TUNING (not in GDD) signal amber
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Iron Citadel",
	"short_name": "Iron Citadel",
	"chapter": "Chapter IX",
	"act": 3,  # Act III, the Electronic Empire.
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "The Empire's throne of iron, where death was conquered with steel. Varn, the Root User, waits at its summit inside Deus Ex Machina, the god it built.",
	"unlock": {"stage": "assembly", "boss_kills": 1},  # Owner-approved: each boss unlocks the next stage
	"unlock_text": "Shut down the Motherboard in the Assembly Halls to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act III stages.
	"consecration": {},  # A Covenant event: none in Act III.
	"crypt_defender": {},  # None in Act III.
	"arena": ARENA,
	"ground": "empire",  # Placeholder EmpireGround until phase 2.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector).
	"empire": true,  # Act III: Line of Fire, Lock-On, Steel has no soul (EmpireRules).
	"music": "iron",  # Act III run loop "Iron Requiem" (RunLoopSynth).
}
