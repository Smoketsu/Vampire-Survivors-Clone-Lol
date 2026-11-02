## CastleSanguisStage — STAGE 21, CASTLE SANGUIS (Act VII, the Sanguine Court;
## GDD §15.0 "Act VII foundation (phase 1)", owner-approved proposal
## docs/act7/PROPOSAL.md "Stage 21: Castle Sanguis"). The Court itself: a castle above the clouds of the moor, its banquet set for a thousand years.
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
## boss script under Carmilla's name), with the Endless Feast Reckoning (the
## Blood Moon never sets, feeding grows each minute, coffins open and release
## nobles; werewolves). It is hidden from the stage select ("playable": false)
## until phase 2 builds it: the Banquet's blood fountains, the Chiropterans and their King, Queen Carmilla and the Elder (the Court, the Waking, the Elder).
## Planned zones (ZONES; clock-driven like every stage): The Courtyard, The Banquet Hall, The Crypt Gallery, The Throne of Blood.
## Carmilla arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD).
class_name CastleSanguisStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "castle_sanguis"

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
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 3 of Act VII

## The four zones phase 2 builds (names from the owner-approved proposal), each
## from `start` game seconds. The stub has one placeholder floor.
const ZONES := [
	{"id": "courtyard", "name": "The Courtyard", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "banquet_hall", "name": "The Banquet Hall", "start": 300.0},  # The Banquet Hall
	{"id": "crypt_gallery", "name": "The Crypt Gallery", "start": 600.0},  # The Crypt Gallery
	{"id": "throne_of_blood", "name": "The Throne of Blood", "start": 900.0},  # The Throne of Blood
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
		"objective": "The Courtyard: the bitten servants stagger toward you. They feed on what they bite"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.7, "vampire_bat": 0.3},
		"objective": "Bats fly over your ring: Archers, Mages and Gargoyles hit them in the air"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.55, "vampire_bat": 0.28, "blood_knight": 0.17},
		"objective": "Blood Knights feed on every blow: Rot and Wither halve it"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.49, "vampire_bat": 0.28, "blood_knight": 0.2, "werewolf": 0.015, "vampire_noble": 0.015},
		"objective": "The Banquet Hall: burst the werewolves before the moon turns them"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.44, "vampire_bat": 0.28, "blood_knight": 0.24, "werewolf": 0.02, "vampire_noble": 0.02},
		"objective": "The Crypt Gallery: the nobles drain from afar. Burst them before they turn to mist"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.4, "vampire_bat": 0.3, "blood_knight": 0.26, "werewolf": 0.02, "vampire_noble": 0.02},
		"objective": "The Throne of Blood: the whole Court comes to feed"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"blood_thrall": 0.42, "vampire_bat": 0.3, "blood_knight": 0.24, "werewolf": 0.02, "vampire_noble": 0.02},
		"objective": "Carmilla has come for you"},
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
	"layout_seed": 2121,  # TUNING (not in GDD)
	"kinds": {
		"castle_pillar": {"weight": 0.5, "shape": "circle", "sizes": [14.0, 18.0]},  # TUNING (not in GDD) placeholder art
		"banquet_table": {"weight": 0.5, "shape": "rect", "sizes": [44.0, 60.0], "short": 16.0},  # TUNING (not in GDD) placeholder art (the Banquet Hall)
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script
## under Carmilla's name until phase 2 adds scripts/enemies/court/boss_carmilla.gd
## (then remove the "script" key).
const BOSS := {
	"id": "carmilla",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_carmilla.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "Queen Carmilla and the Elder",
	"short_name": "Carmilla",
	"arrive_banner": "Queen Carmilla descends from the Throne of Blood!",
	"defeat_banner": "The Court's queen falls! Hold out until the end...",
	"dead_objective": "The Court is broken. Survive the Endless Feast... you cannot.",
}

## Placeholder floor (CourtGround, code-drawn) until phase 2 brings the
## stage's zone floors: base colour, joint lines, accent, trim, style.
const FLOOR := {
	"style": "castle",  # Castle stone, velvet runners, spilt wine.
	"base": Color(0.15, 0.13, 0.15),  # TUNING (not in GDD) castle stone
	"line": Color(0.21, 0.18, 0.21),  # TUNING (not in GDD)
	"accent": Palette.COURT_VELVET,  # TUNING (not in GDD) velvet runners
	"trim": Palette.COURT_BLOOD,  # TUNING (not in GDD) spilt wine
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Castle Sanguis",
	"short_name": "Castle Sanguis",
	"chapter": "Chapter XXI",
	"act": 7,  # Act VII, the Sanguine Court.
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "The Court itself: a castle above the clouds of the moor, its banquet set for a thousand years, and in its crypt the coffin of the first vampire.",
	"unlock": {"stage": "witchwood", "boss_kills": 1},  # Owner-approved: each Act VII stage opens the next
	"unlock_text": "Slay Isolde Vane in the Witchwood to unlock.",
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
	# Music: "Waltz of the Red Moon" (SoundData.SANGUINE_SCORE).
	"music": "sanguine",
}
