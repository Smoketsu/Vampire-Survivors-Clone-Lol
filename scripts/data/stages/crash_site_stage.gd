## CrashSiteStage — STAGE 25, THE CRASH SITE (Act IX, the Concord of Stars;
## GDD §15.0 "Act IX foundation (phase 1)", owner-approved proposal
## docs/act9/PROPOSAL.md "Stage 25: The Crash Site"). A Harvester scout ship
## lies broken in the ruins of the capital, and the Brood is hatching from it.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (Act IX phase 1). The stage is registered, unlocked
## in the campaign chain (Paragon's fall at Liberty Heights opens it), runs the
## Concord's three shared rules ("concord": true: Beams, Abduction and
## Terraforming) and plays a simple timeline of the shared kinds of ALL FOUR
## RACES (so every rule shows; the Brood leads here, owner: one coalition)
## against a PLACEHOLDER boss script (the "vael" boss script under the Hive
## Mother's name), with the Final Harvest Reckoning (the mothership's eye opens
## over the arena, saucers fill the sky, the abduction cap is gone). It is
## hidden from the stage select ("playable": false) until phase 2 builds it:
## Infestation (the Brood's eggs), the Burrower and the Acid Spitter, the Brood
## Matriarch (the miniboss), the Hive Mother (the Brood, the Burrow, the
## Flight).
## Planned zones (ZONES; clock-driven like every stage): the Crater, the
## Hatchery, the Wreck, the Glass Spire.
## The Hive Mother arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD).
class_name CrashSiteStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "crash_site"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act IX starts a step above Liberty Heights's 2.0; the step goes in HP, not
## damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 2.15  # TUNING (not in GDD) brief: a step above Liberty Heights (placeholder, tuned in the balance pass)
## Enemy damage multiplier of this stage on top of the shared time scaling
## (Liberty Heights's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Acts III to VIII: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 1 of Act IX

## The four zones phase 2 builds (names from the owner-approved proposal), each
## from `start` game seconds. The stub has one placeholder floor.
const ZONES := [
	{"id": "crater", "name": "The Crater", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "hatchery", "name": "The Hatchery", "start": 300.0},  # The Hatchery
	{"id": "wreck", "name": "The Wreck", "start": 600.0},  # The Wreck
	{"id": "glass_spire", "name": "The Glass Spire", "start": 900.0},  # The Glass Spire
]

## Terraforming on this stage: {} = the defaults of
## ConcordRulesData.TERRAFORMING (any of its keys overrides them here; phase 2
## tunes it, and the Hive Mother's crater calls Terraforming.seed()).
const TERRAFORMING := {}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the FINAL
## HARVEST, shared by every Act IX stage: the mothership's eye opens over the
## arena and sweeps it with its beam, saucers fill the sky ("kind": the
## saucer, with the shared kinds as companions), and the abduction cap is gone
## ("final_harvest": ConcordRulesData.FINAL_HARVEST keys; {} = those
## defaults). The pods keep falling.
const RECKONING := {
	"banner": "THE FINAL HARVEST: THE MOTHERSHIP OPENS ITS EYE",
	"kind": ConcordEnemyData.RECKONING_KIND,  # The shared Final Harvest heavy (the saucer).
	"final_harvest": {},  # ConcordRulesData.FINAL_HARVEST defaults (phase 2 may tune them here).
	"companions": ConcordEnemyData.RECKONING_COMPANIONS,  # Broodlings, grey drones, a Vrask hunter, a Lumen Sentinel.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) saucers
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE FINAL HARVEST: the eye sweeps the world, and the saucers take your dead. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): a plain ramp
## of the shared kinds of all four races, the Brood leading (placeholder).
## Saucers and hunters stay rare (elites).
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"broodling": 1.0},
		"objective": "The Crater: the Brood swarms out of the wreck. Anything kills them"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"broodling": 0.75, "grey_drone": 0.25},
		"objective": "Grey drones aim their probes: a magenta line is a beam to come. Step out of it"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"broodling": 0.664, "grey_drone": 0.24, "lumen_sentinel": 0.066, "prism": 0.03},
		"objective": "Your Orb Shield and your Warders' barriers send a beam back at its firer"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"broodling": 0.628, "grey_drone": 0.22, "lumen_sentinel": 0.072, "prism": 0.03, "vrask_hunter": 0.03, "saucer": 0.02},
		"objective": "The Hatchery: saucers take your dead. Shoot them down with Archers, Gargoyles and spells"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"broodling": 0.613, "grey_drone": 0.22, "lumen_sentinel": 0.077, "prism": 0.03, "vrask_hunter": 0.035, "saucer": 0.025},
		"objective": "The Wreck: the alien ground heals the Concord. Burn it back with your spells"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"broodling": 0.597, "grey_drone": 0.22, "lumen_sentinel": 0.083, "prism": 0.03, "vrask_hunter": 0.04, "saucer": 0.03},
		"objective": "The Glass Spire: the whole coalition comes for your dead"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"broodling": 0.628, "grey_drone": 0.22, "lumen_sentinel": 0.072, "prism": 0.03, "vrask_hunter": 0.03, "saucer": 0.02},
		"objective": "The Hive Mother has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Broodlings come in
## swarms of 12 (owner-approved proposal), grey drones in squads.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "The Brood pours out of the crashed ship!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "A squad of grey drones raises its probes!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "grey_drone", "count": 5, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 160.0, "type": "wave", "banner": "A saucer drifts over your ring! Shoot it down before it takes your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "saucer", "count": 1, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 240.0, "type": "wave", "banner": "The Luminous! A Star-Seer splits their beams!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "lumen_sentinel", "count": 1, "elite": false}, {"kind": "prism", "count": 1, "elite": false}, {"kind": "grey_drone", "count": 4, "elite": false}]},
	{"time": 330.0, "type": "wave", "banner": "A shimmer in the ruins: a Vrask hunter stalks you!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vrask_hunter", "count": 1, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 450.0, "type": "wave", "banner": "Two swarms at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "broodling", "count": 12, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}, {"kind": "grey_drone", "count": 4, "elite": false}]},
	{"time": 560.0, "type": "wave", "banner": "Saucers over the Hatchery!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "saucer", "count": 2, "elite": false}, {"kind": "grey_drone", "count": 5, "elite": false}]},
	{"time": 680.0, "type": "wave", "banner": "The Luminous line their beams up!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "lumen_sentinel", "count": 2, "elite": false}, {"kind": "prism", "count": 2, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 800.0, "type": "wave", "banner": "The hunt is on: Vrask hunters in the Wreck!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vrask_hunter", "count": 2, "elite": false}, {"kind": "grey_drone", "count": 5, "elite": false}]},
	{"time": 930.0, "type": "wave", "banner": "The whole coalition comes!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "broodling", "count": 12, "elite": false}, {"kind": "saucer", "count": 1, "elite": false}, {"kind": "lumen_sentinel", "count": 1, "elite": false}, {"kind": "vrask_hunter", "count": 1, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The swarm thickens before its queen!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "broodling", "count": 12, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}, {"kind": "prism", "count": 1, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA): the normal scattered-obstacle
## arena (no city blocks). Placeholder kinds drawn by ConcordGlyphs until phase
## 2 brings the stage's own art.
const ARENA := {
	"density": 0.2,  # TUNING (not in GDD)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 2525,  # TUNING (not in GDD)
	"kinds": {
		"concord_rubble": {"weight": 0.55, "shape": "circle", "sizes": [12.0, 16.0, 20.0]},  # TUNING (not in GDD) placeholder art (the capital's ruins)
		"concord_hull_plate": {"weight": 0.45, "shape": "rect", "sizes": [22.0, 30.0], "short": 12.0},  # TUNING (not in GDD) placeholder art (the scout ship's torn hull)
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script
## under the Hive Mother's name until phase 2 adds
## scripts/enemies/concord/boss_hive_mother.gd (then remove the "script" key).
const BOSS := {
	"id": "hive_mother",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_hive_mother.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "The Hive Mother",
	"short_name": "Hive Mother",
	"arrive_banner": "The Hive Mother tears loose from the crater!",
	"defeat_banner": "The Hive Mother falls, and the swarm falters! Hold out until the end...",
	"dead_objective": "The Hive Mother is dead. Survive the Final Harvest... you cannot.",
}

## Placeholder floor (ConcordGround, code-drawn) until phase 2 brings the
## stage's zone floors: base colour, joint lines, accent, trim, style.
const FLOOR := {
	"style": "ruins",  # The capital's broken paving, glass and scorch marks round the crater.
	"base": Color(0.14, 0.14, 0.16),  # TUNING (not in GDD) ash-grey paving
	"line": Color(0.19, 0.19, 0.21),  # TUNING (not in GDD)
	"accent": Palette.CONCORD_GUNMETAL,  # TUNING (not in GDD) scattered hull shards
	"trim": Palette.CONCORD_PLASMA_DARK,  # TUNING (not in GDD) spilt plasma
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Crash Site",
	"short_name": "Crash Site",
	"chapter": "Chapter XXV",
	"act": 9,  # Act IX, the Concord of Stars.
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "A Harvester scout ship lies broken in the ruins of the capital, and the Brood is hatching from it: the Concord has come to find out why the dead no longer rise for its harvest.",
	"unlock": {"stage": "liberty_heights", "boss_kills": 1},  # Brief: Paragon's fall opens Act IX
	"unlock_text": "Defeat Paragon at Liberty Heights to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act IX stages.
	"consecration": {},  # A Covenant event: none in Act IX.
	"crypt_defender": {},  # None in Act IX.
	"arena": ARENA,
	"ground": "concord",  # Placeholder ConcordGround until phase 2.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector).
	"concord": true,  # Act IX: Beams, Abduction, Terraforming (ConcordRules).
	"terraforming": TERRAFORMING,  # Act IX: this stage's Terraforming overrides ({} = the defaults).
	"zones": ZONES,  # Act IX stub: the planned zones (phase 2 builds them).
	# Music: "The Reaping Stars" (SoundData.STARSONG_SCORE).
	"music": "starsong",
}
