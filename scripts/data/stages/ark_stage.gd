## ArkStage — STAGE 27, THE ARK OF THE CONCORD, the finale of Act IX (the
## Concord of Stars; GDD §15.0 "Act IX foundation (phase 1)", owner-approved
## proposal docs/act9/PROPOSAL.md "Stage 27: The Ark of the Concord (the
## finale)"). The mothership in orbit over the dead world: the Concord's
## capital and its harvest vault.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (Act IX phase 1). The stage is registered, unlocked
## in the campaign chain (Vrask'Tal's fall on the Proving Moon opens it), runs the
## Concord's three shared rules ("concord": true: Beams, Abduction and
## Terraforming) and plays a simple timeline of the shared kinds of ALL FOUR
## RACES (so every rule shows; the Harvesters lead here, owner: one
## coalition) against a PLACEHOLDER boss script (the "vael" boss script under
## the Harvester's name), with the Final Harvest Reckoning (the mothership's eye opens
## over the arena, saucers fill the sky, the abduction cap is gone). It is
## hidden from the stage select ("playable": false) until phase 2 builds it:
## the Specimen Vaults (break the tanks to free beasts that attack everyone),
## the Grey Overseer, the Luminous Archon (the miniboss), the Harvester (the
## Council, the Reaping, the Gardener; a plain finale, owner).
## Planned zones (ZONES; clock-driven like every stage): the Hangar, the
## Specimen Vaults, the Reactor, the Bridge of Stars.
## The Harvester arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD).
class_name ArkStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "ark"

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
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 3 of Act IX

## The four zones phase 2 builds (names from the owner-approved proposal), each
## from `start` game seconds. The stub has one placeholder floor.
const ZONES := [
	{"id": "hangar", "name": "The Hangar", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "specimen_vaults", "name": "The Specimen Vaults", "start": 300.0},  # The Specimen Vaults
	{"id": "reactor", "name": "The Reactor", "start": 600.0},  # The Reactor
	{"id": "bridge_of_stars", "name": "The Bridge of Stars", "start": 900.0},  # The Bridge of Stars
]

## Terraforming on this stage: {} = the defaults of
## ConcordRulesData.TERRAFORMING (any of its keys overrides them here; phase 2
## tunes it, and the Ark's vents call Terraforming.seed()).
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
		"weights": {"broodling": 0.6, "grey_drone": 0.4},
		"objective": "The Hangar: the Harvesters' greys and their Brood come for you"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"broodling": 0.5, "grey_drone": 0.46, "saucer": 0.04},
		"objective": "Grey drones aim their probes: a magenta line is a beam to come. Step out of it"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"broodling": 0.504, "grey_drone": 0.36, "lumen_sentinel": 0.066, "prism": 0.03, "saucer": 0.04},
		"objective": "Your Orb Shield and your Warders' barriers send a beam back at its firer"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"broodling": 0.628, "grey_drone": 0.22, "lumen_sentinel": 0.072, "prism": 0.03, "vrask_hunter": 0.03, "saucer": 0.02},
		"objective": "The Specimen Vaults: saucers take your dead. Shoot them down with Archers, Gargoyles and spells"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"broodling": 0.613, "grey_drone": 0.22, "lumen_sentinel": 0.077, "prism": 0.03, "vrask_hunter": 0.035, "saucer": 0.025},
		"objective": "The Reactor: the alien ground heals the Concord. Burn it back with your spells"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"broodling": 0.597, "grey_drone": 0.22, "lumen_sentinel": 0.083, "prism": 0.03, "vrask_hunter": 0.04, "saucer": 0.03},
		"objective": "The Bridge of Stars: the whole coalition comes for your dead"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"broodling": 0.628, "grey_drone": 0.22, "lumen_sentinel": 0.072, "prism": 0.03, "vrask_hunter": 0.03, "saucer": 0.02},
		"objective": "The Harvester has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Broodlings come in
## swarms of 12 (owner-approved proposal), grey drones in squads.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "The hangar doors open on the Brood!", "formation": "ring",  # TUNING (not in GDD)
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
	{"time": 990.0, "type": "wave", "banner": "The Concord gathers before the Harvester!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "broodling", "count": 12, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}, {"kind": "prism", "count": 1, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA): the normal scattered-obstacle
## arena (no city blocks). Placeholder kinds drawn by ConcordGlyphs until phase
## 2 brings the stage's own art.
const ARENA := {
	"density": 0.2,  # TUNING (not in GDD)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 2727,  # TUNING (not in GDD)
	"kinds": {
		"concord_conduit": {"weight": 0.5, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD) placeholder art (the Ark's power conduits)
		"concord_specimen_tank": {"weight": 0.5, "shape": "rect", "sizes": [20.0, 28.0], "short": 14.0},  # TUNING (not in GDD) placeholder art (sealed specimen tanks)
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script
## under the Harvester's name until phase 2 adds
## scripts/enemies/concord/boss_harvester.gd (then remove the "script" key).
const BOSS := {
	"id": "harvester",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_harvester.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "The Harvester",
	"short_name": "Harvester",
	"arrive_banner": "The Harvester descends from its throne of rings!",
	"defeat_banner": "The Harvester falls, and the stars go dark! Hold out until the end...",
	"dead_objective": "The Harvester is dead. Survive the Final Harvest... you cannot.",
}

## Placeholder floor (ConcordGround, code-drawn) until phase 2 brings the
## stage's zone floors: base colour, joint lines, accent, trim, style.
const FLOOR := {
	"style": "hull",  # The mothership's deck: hull-white plates, gunmetal seams, plasma lights.
	"base": Color(0.17, 0.19, 0.22),  # TUNING (not in GDD) deck plating in the dark
	"line": Palette.CONCORD_GUNMETAL_DARK,  # TUNING (not in GDD) plate seams
	"accent": Palette.CONCORD_GUNMETAL,  # TUNING (not in GDD) hatch plates
	"trim": Palette.CONCORD_PLASMA,  # TUNING (not in GDD) deck lights
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Ark of the Concord",
	"short_name": "The Ark",
	"chapter": "Chapter XXVII",
	"act": 9,  # Act IX, the Concord of Stars.
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "The mothership in orbit over the dead world: the Concord's capital and its harvest vault, where the one who planted the world waits.",
	"unlock": {"stage": "proving_moon", "boss_kills": 1},  # Brief: each Act IX stage opens the next
	"unlock_text": "Defeat Vrask'Tal on the Proving Moon to unlock.",
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
	# Music key "siren" FOR NOW (the Act VIII loop): the audio pass adds
	# "starsong" ("The Reaping Stars", SoundData.STARSONG_SCORE) and the lead
	# switches this to "starsong" at the merge.
	"music": "siren",
}
