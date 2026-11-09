## FernBasinStage — STAGE 40 (temporary and final stage 40), THE FERN BASIN
## (temporary Act XIV, the Age of Titans, final slot XIV; GDD §15.0 "The Age
## of Titans foundation (phase 1)"; design docs/proposals/LAST_SIX_ACTS.md
## section XIV and docs/proposals/NEW_ACTS_AND_ORDER.md Part 2). A river basin
## deep in jungle, the day before the impact; the sky is still blue and the
## white streak is faint. Every number and event that belongs to this stage.
## StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (phase 1). The stage is registered, unlocked in the
## campaign chain, runs the act's three shared rules ("primeval": true: Packs,
## Herds, Scavengers) and plays a simple timeline of ALL the shared kinds (so
## every rule shows: the packs come in the events, the herds come from Herds,
## the Skyraiders in the segments) against a PLACEHOLDER boss script (the
## "vael" boss script under Scarmaw's name), with the Stampede of Ash
## Reckoning (herds from every side, volcanic bombs, doubled packs, Tyrants).
## It is hidden from the stage select ("playable": false) until phase 2 builds
## it: the Tar Seeps (TerrainSlow; trapped Longneck, free kills), the Bog Croc,
## Ironjaw the Nest Mother (the miniboss) and Scarmaw, the Great Raptor (the
## Hunt, the Ambush, Blood Up).
## Planned zones (ZONES; clock-driven like every stage): the Fern Floor, the
## Tar Seep, the River Ford and the Nesting Hollow.
## Scarmaw arrives with 3:00 left; the Reckoning at 0:00.
## Tuned for the act's FINAL slot XIV (docs/last_acts/PLAN.md: above the
## Concord of Stars), not its temporary number. Every rate, cap and weight is
## TUNING (not in GDD).
class_name FernBasinStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "fern_basin"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot XIV sits above the Concord: the Crash Site's 2.15 and up; the step is
## in HP).
const ENEMY_HP_MULT: float = 2.3  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling
## (the Crash Site's 1.5 and up).
const ENEMY_DAMAGE_MULT: float = 1.6  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to XIII (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 1 of the act

## The four zones phase 2 builds (names from the proposal), each from `start`
## game seconds. The stub has one placeholder floor.
const ZONES := [
	{"id": "fern_floor", "name": "The Fern Floor", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "tar_seep", "name": "The Tar Seep", "start": 300.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "river_ford", "name": "The River Ford", "start": 600.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "nesting_hollow", "name": "The Nesting Hollow", "start": 900.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
]

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the
## STAMPEDE OF ASH, shared by the first two Titans stages: the sky burns, herds
## stampede from every side, volcanic bombs fall, packs double and Tyrants
## roam ("kind": the Tyrant, with the shared kinds as companions;
## "stampede_of_ash": PrimevalRulesData.ASH keys; {} = those defaults).
const RECKONING := {
	"banner": "THE STAMPEDE OF ASH: THE SKY BURNS",
	"kind": PrimevalEnemyData.RECKONING_KIND,  # The shared Stampede of Ash heavy (the Tyrant).
	"stampede_of_ash": {},  # PrimevalRulesData.ASH defaults (phase 2 may tune them here).
	"companions": PrimevalEnemyData.RECKONING_COMPANIONS,  # Scuttlers, doubled packs, Frill-Spitters.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 1,  # TUNING (not in GDD) Tyrants
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE STAMPEDE OF ASH: the sky burns and every beast runs. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): a plain ramp
## of the shared kinds (placeholder). The packs come in the EVENTS (a pack is
## a group that arrives together), the herds from Herds, never from these
## weights.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.94, "frill_spitter": 0.06},
		"objective": "The Fern Floor: the beasts are hungry, and your army smells of meat"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.89, "frill_spitter": 0.08, "skyraider": 0.03},
		"objective": "Skyraiders dive on your crystals: shoot one down and its pile drops. Near you, nothing is taken"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.87, "frill_spitter": 0.1, "skyraider": 0.03},
		"objective": "The herds stampede when a fight comes close: shelter behind a rock, or lure the hunters into their path"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.86, "frill_spitter": 0.1, "skyraider": 0.04},
		"objective": "The Tar Seep: a pack circles, holds, then rushes. Kill the alpha first"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.84, "frill_spitter": 0.12, "skyraider": 0.04},
		"objective": "The River Ford: a fallen giant rises as a Fossil Giant for you"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.83, "frill_spitter": 0.12, "skyraider": 0.05},
		"objective": "The Nesting Hollow: the whole basin hunts you"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"scuttler": 0.86, "frill_spitter": 0.1, "skyraider": 0.04},
		"objective": "Scarmaw has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Each group of
## Razorclaws is a pack (its first is the alpha).
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A swarm of Scuttlers pours out of the ferns!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 75.0, "type": "wave", "banner": "A pack of Razorclaws is hunting you: kill the alpha!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 4, "elite": false}]},
	{"time": 150.0, "type": "wave", "banner": "Skyraiders circle over your crystals!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "skyraider", "count": 3, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 230.0, "type": "wave", "banner": "A bigger pack, and Frill-Spitters behind it!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 5, "elite": false}, {"kind": "frill_spitter", "count": 3, "elite": false}]},
	{"time": 340.0, "type": "wave", "banner": "Two packs at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 5, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 460.0, "type": "wave", "banner": "The Razorclaws come back with Skyraiders above them!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 6, "elite": false}, {"kind": "skyraider", "count": 3, "elite": false}]},
	{"time": 600.0, "type": "wave", "banner": "A Tyrant walks out of the river!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "tyrant", "count": 1, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 720.0, "type": "wave", "banner": "The great pack of the basin!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 8, "elite": false}, {"kind": "frill_spitter", "count": 4, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "Every flier in the basin dives at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "skyraider", "count": 5, "elite": false}, {"kind": "razorclaw", "count": 6, "elite": false}]},
	{"time": 980.0, "type": "wave", "banner": "The hunters gather before Scarmaw!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 8, "elite": false}, {"kind": "tyrant", "count": 1, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA): the normal scattered-obstacle
## arena; every obstacle is SHELTER from a stampede (Herds). Placeholder kinds
## drawn by PrimevalGlyphs until phase 2 brings the stage's art.
const ARENA := {
	"density": 0.2,  # TUNING (not in GDD)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 4040,  # TUNING (not in GDD)
	"kinds": {
		"primeval_rock": {"weight": 0.55, "shape": "circle", "sizes": [13.0, 18.0]},  # TUNING (not in GDD) placeholder art (a mossy boulder)
		"primeval_fossil": {"weight": 0.45, "shape": "rect", "sizes": [18.0, 26.0], "short": 11.0},  # TUNING (not in GDD) placeholder art (a fossil rib arch)
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script
## under Scarmaw's name until phase 2 adds
## scripts/enemies/primeval/boss_scarmaw.gd (then remove the "script" key).
const BOSS := {
	"id": "scarmaw",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_scarmaw.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "Scarmaw, the Great Raptor",
	"short_name": "Scarmaw",
	"arrive_banner": "Scarmaw, the Great Raptor, leaps out of the ferns with her pack!",
	"defeat_banner": "Scarmaw falls, and her pack scatters into the ferns! Hold out until the end...",
	"dead_objective": "Scarmaw is dead. Survive the Stampede of Ash... you cannot.",
}

## Placeholder floor (PrimevalGround, code-drawn) until phase 2 brings the
## stage's zone floors: base colour, line, accent, trim, style.
const FLOOR := {
	"style": "fern",  # jungle earth under ferns.
	"base": Color(0.13, 0.20, 0.11),  # TUNING (not in GDD)
	"line": Color(0.19, 0.28, 0.14),  # TUNING (not in GDD)
	"accent": Palette.PRIMEVAL_FERN,  # TUNING (not in GDD)
	"trim": Palette.PRIMEVAL_TAR,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Fern Basin",
	"short_name": "Fern Basin",
	"chapter": "Chapter XL",  # Temporary and final stage 40 (the reorder pass renumbers if it moves).
	"act": 14,  # Temporary Act XIV, the Age of Titans (final slot XIV; docs/last_acts/PLAN.md).
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "A river basin deep in jungle, the day before the sky falls: ferns, tar and beasts the size of houses, and every one that falls leaves a skeleton.",
	"unlock": {"stage": "empyrean", "boss_kills": 1},  # Plan: the Voice opens the act; each stage opens the next
	"unlock_text": "Defeat the Voice in the Empyrean to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Titans stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ARENA,
	"ground": "primeval",  # Placeholder PrimevalGround until phase 2.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector) if it wants them.
	"primeval": true,  # Packs, Herds, Scavengers (PrimevalRules).
	"packs": {},  # This stage's Packs overrides ({} = PrimevalRulesData.PACKS).
	"herds": {},  # This stage's Herds ({} = PrimevalRulesData.HERDS).
	"scavengers": {},  # This stage's Scavengers ({} = PrimevalRulesData.SCAVENGERS).
	"zones": ZONES,  # The planned zones (phase 2 builds them).
	# Music key FOR NOW: "starsong" (the Concord's "The Reaping Stars": the
	# Harvesters' log led here); the art + audio agent adds the act's own score
	# and the lead switches every Titans stage to it.
	"music": "starsong",
}
