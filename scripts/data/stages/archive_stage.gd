## ArchiveStage — STAGE 5, THE HOLLOW ARCHIVE (Act II, the Ancient Eye; GDD §15.0
## "Act II: the Ancient Eye", owner-approved proposal "The Drowned Choir" with
## the faction renamed the Ancient Eye). Every number and event that belongs
## to this stage. StageRegistry exposes it to the run as `Game.stage_def` (the
## STAGE dictionary at the bottom; its keys are documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (Act II phase 1). The stage is registered, unlocked
## in the campaign chain, runs Dread and Claims and plays a simple timeline of
## the Ancient Eye's shared kinds (Initiates, Chanter squads) against a
## PLACEHOLDER boss script ("vael" behind the boss id "archivist", shown under The Archivist's name). It is
## hidden from the stage select ("playable": false) until phase 2 builds it:
## rifts (RiftDirector), forbidden tomes, Scribe of the Unwritten, Ink Wraith, Pilgrim of the Spore, Gibbering Mass, the Librarian miniboss, the Archivist, Forbidden Verse + Marginalia, Iron Mind.
## Planned zones (clock-driven like the Crimson March and the Sanctum):
## 20:00 the Reading Halls, 15:00 the Ink Wells, 10:00 the Orrery, 5:00 the Unwritten Stacks; The Archivist arrives with 3:00 left.
## Every rate, cap and weight is TUNING (not in GDD).
class_name ArchiveStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "archive"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act II starts a little above the Sanctum's 1.1 and climbs stage by stage).
const ENEMY_HP_MULT: float = 1.2  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.2  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 240.0  # TUNING (not in GDD) placeholder
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 2.0  # TUNING (not in GDD) owner-approved proposal placeholder (Act I: x1.25, x1.5)

## The Reckoning of this stage (keys as GraveyardStage.RECKONING). Phase 2
## restyles it ("kind": the stage's own Reckoning kind).
const RECKONING := {
	"banner": "THE DEEP RISES: THE EYE OPENS UPON YOU",
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 3,  # TUNING (not in GDD)
	"count_growth": 2,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE DEEP RISES: the Eye opens upon you. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): a plain
## ramp of the Ancient Eye's shared kinds (placeholder).
const SEGMENTS := [
	{"start": 0.0, "rate": 1.6, "max_alive": 34,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 1.0},
		"objective": "The Ancient Eye gathers: hold your ground"},
	{"start": 120.0, "rate": 2.2, "max_alive": 52,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.94, "eye_chanter": 0.06},
		"objective": "Chanters lead the Initiates: kill them before they claim your dead"},
	{"start": 300.0, "rate": 2.8, "max_alive": 70,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.92, "eye_chanter": 0.08},
		"objective": "The congregation swells"},
	{"start": 540.0, "rate": 3.4, "max_alive": 88,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.9, "eye_chanter": 0.1},
		"objective": "The Eye's chant rises"},
	{"start": 780.0, "rate": 4.0, "max_alive": 104,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.9, "eye_chanter": 0.1},
		"objective": "The deep stirs"},
	{"start": BOSS_TIME, "rate": 2.6, "max_alive": 70,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"eye_initiate": 0.9, "eye_chanter": 0.1},
		"objective": "Slay The Archivist"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS): Chanter squads.
const EVENTS := [
	{"time": 15.0, "type": "wave", "banner": "Initiates of the Eye shamble in!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_initiate", "count": 8, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "A Chanter leads its squad: it claims the dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_chanter", "count": 1, "elite": false}, {"kind": "eye_initiate", "count": 10, "elite": false}]},
	{"time": 240.0, "type": "wave", "banner": "Two squads close in!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_chanter", "count": 2, "elite": false}, {"kind": "eye_initiate", "count": 18, "elite": false}]},
	{"time": 480.0, "type": "wave", "banner": "The congregation marches!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_chanter", "count": 2, "elite": true}, {"kind": "eye_initiate", "count": 24, "elite": false}]},
	{"time": 720.0, "type": "wave", "banner": "The chant surrounds you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_chanter", "count": 3, "elite": false}, {"kind": "eye_initiate", "count": 30, "elite": false}]},
	{"time": 960.0, "type": "wave", "banner": "The last congregation!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_chanter", "count": 4, "elite": true}, {"kind": "eye_initiate", "count": 34, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA). Placeholder: the
## Graveyard's kinds and art until phase 2 brings the stage's own.
const ARENA := {
	"density": 0.18,  # TUNING (not in GDD)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 5521,  # TUNING (not in GDD)
	"kinds": {
		"gravestone": {"weight": 0.5, "shape": "circle", "sizes": [11.0, 15.0]},  # TUNING (not in GDD) placeholder art
		"dead_tree": {"weight": 0.2, "shape": "circle", "sizes": [13.0, 15.0, 18.0]},  # TUNING (not in GDD) placeholder art
		"crypt_wall": {"weight": 0.3, "shape": "rect", "sizes": [64.0, 80.0, 96.0], "short": 20.0},  # TUNING (not in GDD) placeholder art
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script under The Archivist's name until phase 2 builds the
## stage's own boss.
const BOSS := {
	"id": "archivist",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_archivist.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "The Archivist, Keeper of the Unwritten",
	"short_name": "The Archivist",
	"arrive_banner": "The Archivist, Keeper of the Unwritten rises!",
	"defeat_banner": "The Archivist has fallen! Hold out until the end...",
	"dead_objective": "The Archivist is dead. Survive until the countdown ends.",
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Hollow Archive",
	"short_name": "Archive",
	"chapter": "Chapter V",
	"act": 2,  # Act II, the Ancient Eye.
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "A buried library and observatory under the cliffs where the Eye keeps its god's scripture. Rifts fold the stacks and open doors behind you; the Archivist, Keeper of the Unwritten, guards the last page.",
	"unlock": {"stage": "harbour", "boss_kills": 1},  # owner-approved: each boss unlocks the next stage
	"unlock_text": "Slay Abbot Merrow in Gullhaven Harbour to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act II stages.
	"consecration": {},  # A Covenant event: none in Act II.
	"crypt_defender": {},  # None in Act II.
	"arena": ARENA,
	"ground": "graveyard",  # Placeholder floor until phase 2.
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector).
	"dread": true,  # Act II: Dread on the necromancer (DreadMeter).
	"claims": true,  # Act II: the Ancient Eye claims the fallen (EyeClaims).
	"music": "tide",  # Act II run loop "Below the Tide" (RunLoopSynth).
}
