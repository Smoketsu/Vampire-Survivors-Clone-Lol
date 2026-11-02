## WitchwoodStage — STAGE 20, THE WITCHWOOD (Act VII, the Sanguine Court;
## GDD §15.0 "Act VII foundation (phase 1)", owner-approved proposal
## docs/act7/PROPOSAL.md "Stage 20: The Witchwood"). A black fen and a wood of hanging charms where the Court's witches keep their sabbath.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (Act VII phase 1). The stage is registered, unlocked
## in the campaign chain, runs the Sanguine Court's three shared rules
## ("court": true: Bloodfeast, Night Wings through the vampire bats, and the
## Blood Moon on its clock ("moon": {} = the defaults)) and plays a simple
## timeline of the shared kinds (blood thralls, vampire bats, blood knights,
## werewolves, vampire nobles) against a PLACEHOLDER boss script (the "vael"
## boss script under Isolde's name), with the Endless Feast Reckoning (the
## Blood Moon never sets, feeding grows each minute, coffins open and release
## nobles; werewolves). It is hidden from the stage select ("playable": false)
## until phase 2 builds it: the fen water that slows everyone, the hex stones that power the covens' circles, the Crimson Witch covens, the Bog Mother, Isolde Vane (three sisters, her own Blood Moon).
## Planned zones (ZONES; clock-driven like every stage): The Fen, The Hanging Wood, The Standing Stones, The Cauldron.
## Isolde arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD).
class_name WitchwoodStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "witchwood"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act VII starts a step above Pandemonium's 1.75; the step goes in HP, not
## damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 1.85  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling
## (Pandemonium's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Acts III to VI: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 2 of Act VII

## The four zones phase 2 builds (names from the owner-approved proposal), each
## from `start` game seconds. The stub has one placeholder floor.
const ZONES := [
	{"id": "fen", "name": "The Fen", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "hanging_wood", "name": "The Hanging Wood", "start": 300.0},  # The Hanging Wood
	{"id": "standing_stones", "name": "The Standing Stones", "start": 600.0},  # The Standing Stones
	{"id": "cauldron", "name": "The Cauldron", "start": 900.0},  # The Cauldron
]

## The Blood Moon on this stage: {} = the defaults of CourtRulesData.BLOOD_MOON
## (any of its keys overrides them here; phase 2 tunes it, and its boss calls
## its own moon through BloodMoon.force()).
const MOON := {}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Endless
## Feast, shared by every Act VII stage: the Blood Moon rises and never sets,
## feeding grows each minute, and coffins open and release nobles
## ("endless_feast": CourtRulesData.ENDLESS_FEAST keys; {} = those defaults);
## werewolves ("kind", beasts at once under the endless moon) come with thralls
## and bats.
const RECKONING := {
	"banner": "THE ENDLESS FEAST: THE MOON WILL NOT SET",
	"kind": CourtEnemyData.WEREWOLF,  # The shared Endless Feast heavy.
	"endless_feast": {},  # CourtRulesData.ENDLESS_FEAST defaults (phase 2 may tune them here).
	"companions": [{"kind": CourtEnemyData.VAMPIRE_BAT, "count": 8, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": CourtEnemyData.BLOOD_THRALL, "count": 4, "growth": 1.0}],  # TUNING (not in GDD)
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) werewolves are heavy
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE ENDLESS FEAST: the moon will not set, and the Court will feed. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): a plain ramp
## of the shared kinds (placeholder). Nobles stay rare (elites).
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 1.0},
		"objective": "The Fen: the bitten servants stagger toward you. They feed on what they bite"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.7, "vampire_bat": 0.3},
		"objective": "Bats fly over your ring: Archers, Mages and Gargoyles hit them in the air"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.55, "vampire_bat": 0.28, "blood_knight": 0.17},
		"objective": "Blood Knights feed on every blow: Rot and Wither halve it"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.49, "vampire_bat": 0.28, "blood_knight": 0.2, "werewolf": 0.015, "vampire_noble": 0.015},
		"objective": "The Hanging Wood: burst the werewolves before the moon turns them"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.44, "vampire_bat": 0.28, "blood_knight": 0.24, "werewolf": 0.02, "vampire_noble": 0.02},
		"objective": "The Standing Stones: the nobles drain from afar. Burst them before they turn to mist"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.4, "vampire_bat": 0.3, "blood_knight": 0.26, "werewolf": 0.02, "vampire_noble": 0.02},
		"objective": "The Cauldron: the whole Court comes to feed"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"blood_thrall": 0.42, "vampire_bat": 0.3, "blood_knight": 0.24, "werewolf": 0.02, "vampire_noble": 0.02},
		"objective": "Isolde has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Vampire bats come
## in swarms of 10 (owner-approved proposal).
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "The bitten servants of the Court shamble out of the dark!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "blood_thrall", "count": 16, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "A swarm of vampire bats! They fly over your ring!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_bat", "count": 10, "elite": false}]},
	{"time": 200.0, "type": "wave", "banner": "Blood Knights advance in blood-red plate!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "blood_knight", "count": 4, "elite": false}, {"kind": "blood_thrall", "count": 10, "elite": false}]},
	{"time": 250.0, "type": "wave", "banner": "A werewolf hunter stalks you under the red moon!", "formation": "arc",  # TUNING (not in GDD) during the first Blood Moon
		"groups": [{"kind": "werewolf", "count": 1, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}]},
	{"time": 360.0, "type": "wave", "banner": "A Vampire Noble! Burst her before she turns to mist!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_noble", "count": 1, "elite": false}, {"kind": "blood_thrall", "count": 10, "elite": false}]},
	{"time": 480.0, "type": "wave", "banner": "The bats darken the sky!", "formation": "ring",  # TUNING (not in GDD) during the second Blood Moon
		"groups": [{"kind": "vampire_bat", "count": 10, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}, {"kind": "blood_knight", "count": 3, "elite": false}]},
	{"time": 600.0, "type": "wave", "banner": "Werewolves and their hunters!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "werewolf", "count": 2, "elite": false}, {"kind": "blood_thrall", "count": 12, "elite": false}]},
	{"time": 700.0, "type": "wave", "banner": "The nobles of the Court descend!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_noble", "count": 2, "elite": false}, {"kind": "blood_knight", "count": 4, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}]},
	{"time": 840.0, "type": "wave", "banner": "The pack hunts under the moon!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "werewolf", "count": 2, "elite": false}, {"kind": "blood_knight", "count": 4, "elite": false}, {"kind": "vampire_noble", "count": 1, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The Court gathers for its feast!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_noble", "count": 2, "elite": false}, {"kind": "blood_knight", "count": 5, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA). Placeholder kinds drawn by
## CourtGlyphs until phase 2 brings the stage's own art.
const ARENA := {
	"density": 0.2,  # TUNING (not in GDD)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 2020,  # TUNING (not in GDD)
	"kinds": {
		"dead_tree": {"weight": 0.55, "shape": "circle", "sizes": [12.0, 16.0, 20.0]},  # TUNING (not in GDD) placeholder art
		"hanging_charm": {"weight": 0.45, "shape": "rect", "sizes": [20.0, 28.0], "short": 10.0},  # TUNING (not in GDD) placeholder art (the Hanging Wood)
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script
## under Isolde's name until phase 2 adds scripts/enemies/court/boss_isolde.gd
## (then remove the "script" key).
const BOSS := {
	"id": "isolde",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_isolde.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "Isolde Vane, the Witch of the Red Moon",
	"short_name": "Isolde",
	"arrive_banner": "Isolde Vane, the Witch of the Red Moon, steps out of the cauldron smoke!",
	"defeat_banner": "Isolde falls, her coven with her! Hold out until the end...",
	"dead_objective": "Isolde is dead. Survive the Endless Feast... you cannot.",
}

## Placeholder floor (CourtGround, code-drawn) until phase 2 brings the
## stage's zone floors: base colour, joint lines, accent, trim, style.
const FLOOR := {
	"style": "fen",  # Black fen mud, still pools, red charm threads.
	"base": Color(0.09, 0.11, 0.10),  # TUNING (not in GDD) black fen mud
	"line": Color(0.13, 0.15, 0.13),  # TUNING (not in GDD)
	"accent": Color(0.05, 0.06, 0.07),  # TUNING (not in GDD) still pools
	"trim": Palette.COURT_BLOOD,  # TUNING (not in GDD) red charm threads
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Witchwood",
	"short_name": "The Witchwood",
	"chapter": "Chapter XX",
	"act": 7,  # Act VII, the Sanguine Court.
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "A black fen and a wood of hanging charms where the Court's witches keep their sabbath, their circles drawn in blood on the standing stones.",
	"unlock": {"stage": "ravensmoor", "boss_kills": 1},  # Owner-approved: each Act VII stage opens the next
	"unlock_text": "Slay Vargr on Ravensmoor to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act VII stages.
	"consecration": {},  # A Covenant event: none in Act VII.
	"crypt_defender": {},  # None in Act VII.
	"arena": ARENA,
	"ground": "court",  # Placeholder CourtGround until phase 2.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector).
	"court": true,  # Act VII: Bloodfeast, Night Wings, the Blood Moon (CourtRules).
	"moon": MOON,  # Act VII: this stage's Blood Moon overrides ({} = the defaults).
	"zones": ZONES,  # Act VII stub: the planned zones (phase 2 builds them).
	# Music key "brimstone" FOR NOW (the Act VI loop): the audio pass adds
	# "sanguine" ("Waltz of the Red Moon", SoundData.SANGUINE_SCORE) and the lead
	# switches this to "sanguine" at the merge.
	"music": "brimstone",
}
