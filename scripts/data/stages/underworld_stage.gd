## UnderworldStage — STAGE 12, THE ASPHODEL UNDERWORLD (the Act IV finale) (Act IV, the Olympian Republic;
## GDD §15.0 "Act IV foundation (phase 1)", owner-approved proposal
## docs/act4/PROPOSAL.md "Stage 12: The Asphodel Underworld"). Grey fields of
## asphodel, the River Styx, Charon's ferry and the gates of Tartarus.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (Act IV phase 1). The stage is registered, unlocked
## in the campaign chain (Zeus's fall on Olympus opens it), runs the Olympian
## Republic's three shared rules ("pantheon": true: Wrath of the Gods, Phalanx,
## Glory) with Hades' fissures as its wrath ("wrath": {"kind": "fissures"}), and
## plays a simple timeline of the shared kinds (Shades of the Dead, Hoplites,
## Heroes) against a PLACEHOLDER boss script ("seraphine" behind the boss
## id "hades", shown under Hades' name), with the Twilight of the Gods
## Reckoning (Bronze Titans, every wrath at once). It is hidden from the stage
## select ("playable": false) until phase 2 builds it: its four zones and
## floors, the Styx, Cerberus, its kinds, Hades.
## Planned zones (ZONES; clock-driven like every stage): the Asphodel Fields,
## the Styx Crossing, the Judges' Hall, the Throne of Hades. Hades arrives
## with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD).
class_name UnderworldStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "underworld"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act IV starts a step above the Iron Citadel's 1.35 and climbs stage by stage).
const ENEMY_HP_MULT: float = 1.5  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.45  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Act III: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 3.75  # TUNING (not in GDD) placeholder (Mount Olympus x3.5)

## The four zones phase 2 builds (names from the owner-approved proposal), each
## from `start` game seconds. The stub has one placeholder floor; the trickle's
## objective lines already follow the zones.
const ZONES := [
	{"id": "asphodel_fields", "name": "The Asphodel Fields", "start": 0.0},  # Owner-approved proposal; TUNING (not in GDD) times
	{"id": "styx_crossing", "name": "The Styx Crossing", "start": 300.0},
	{"id": "judges_hall", "name": "The Judges' Hall", "start": 600.0},
	{"id": "throne_of_hades", "name": "The Throne of Hades", "start": 900.0},
]

## Wrath of the Gods on this stage (DivineWrath): Hades' fissures. Any other
## key overrides PantheonRulesData.WRATH["fissures"] ({} = those defaults).
const WRATH := {
	"kind": "fissures",  # Owner-approved proposal: Hades' fissures (Underworld)
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Twilight
## of the Gods, shared by every Act IV stage: Bronze Titans step out of the
## ground ("kind") while every wrath kind fires together, faster each minute
## ("twilight": PantheonRulesData.TWILIGHT keys; {} = those defaults).
const RECKONING := {
	"banner": "THE TWILIGHT OF THE GODS: THE SKY SPLITS",
	"kind": PantheonEnemyData.BRONZE_TITAN,  # The shared Twilight kind.
	"twilight": {},  # PantheonRulesData.TWILIGHT defaults (phase 2 may tune them here).
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) Titans are few and huge
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE TWILIGHT OF THE GODS: the heavens fall on you. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): a plain ramp
## of the shared kinds (placeholder). Shades are the fodder, Hoplites the bulk
## and the shield walls, Heroes the rare elites.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 1.0},
		"objective": "The Asphodel Fields: the dead wander the grey flowers"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.8, "hoplite": 0.2},
		"objective": "Hoplites lock shields: break the wall from the flanks"},
	{"start": 300.0, "rate": 2.1, "max_alive": 54,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.66, "hoplite": 0.33, "hero": 0.01},
		"objective": "The Styx Crossing: kill the Heroes before they win Glory"},
	{"start": 600.0, "rate": 2.6, "max_alive": 70,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.6, "hoplite": 0.385, "hero": 0.015},
		"objective": "The Judges' Hall: lure the hosts over the fissures"},
	{"start": 900.0, "rate": 3.2, "max_alive": 88,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.56, "hoplite": 0.42, "hero": 0.02},
		"objective": "The Throne of Hades"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"shade_of_dead": 0.6, "hoplite": 0.385, "hero": 0.015},
		"objective": "Make the Lord of the Dead kneel"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS): shade swarms,
## shield walls ("line": rows 26 px apart, so a wall locks as it arrives) and
## Heroes.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "The dead rise from the asphodel!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "shade_of_dead", "count": 12, "elite": false}]},
	{"time": 100.0, "type": "wave", "banner": "A shield wall advances: strike its flanks!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "hoplite", "count": 6, "elite": false}]},
	{"time": 160.0, "type": "wave", "banner": "A Hero takes the field: kill it before it wins Glory!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 1, "elite": false}, {"kind": "shade_of_dead", "count": 8, "elite": false}]},
	{"time": 270.0, "type": "wave", "banner": "Two shield walls close in!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "hoplite", "count": 14, "elite": false}]},
	{"time": 420.0, "type": "wave", "banner": "Heroes lead the host!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 2, "elite": false}, {"kind": "hoplite", "count": 10, "elite": false}, {"kind": "shade_of_dead", "count": 12, "elite": false}]},
	{"time": 600.0, "type": "wave", "banner": "The phalanx marches on you!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "hoplite", "count": 24, "elite": false}]},
	{"time": 780.0, "type": "wave", "banner": "The dead pour out of the Underworld!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "shade_of_dead", "count": 30, "elite": false}, {"kind": "hero", "count": 2, "elite": false}]},
	{"time": 960.0, "type": "wave", "banner": "The last host of the Underworld!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 3, "elite": false}, {"kind": "hoplite", "count": 20, "elite": false}, {"kind": "shade_of_dead", "count": 16, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA). Placeholder kinds drawn by
## PantheonGlyphs until phase 2 brings the stage's own art.
const ARENA := {
	"density": 0.14,  # TUNING (not in GDD)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 1231,  # TUNING (not in GDD)
	"kinds": {
		"broken_column": {"weight": 0.55, "shape": "circle", "sizes": [11.0, 14.0, 18.0]},  # TUNING (not in GDD) placeholder art
		"marble_block": {"weight": 0.3, "shape": "rect", "sizes": [40.0, 56.0, 72.0], "short": 26.0},  # TUNING (not in GDD) placeholder art
		"bronze_brazier": {"weight": 0.15, "shape": "circle", "sizes": [9.0, 11.0]},  # TUNING (not in GDD) placeholder art
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "seraphine" boss
## script under Hades' name until phase 2 adds
## scripts/enemies/pantheon/boss_hades.gd (then remove the "script" key).
const BOSS := {
	"id": "hades",
	"script": "seraphine",  # PLACEHOLDER boss script until phase 2 adds boss_hades.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "Hades, Lord of the Dead",
	"short_name": "Hades",
	"arrive_banner": "Hades, Lord of the Dead, rises from his throne!",
	"defeat_banner": "Hades kneels and gives up his crown! Hold out until the end...",
	"dead_objective": "The Lord of the Dead kneels. Survive until the countdown ends.",
}

## Placeholder floor (PantheonGround, code-drawn) until phase 2 brings the
## stage's zone floors: base colour, joint lines, accent stones, trim, style.
const FLOOR := {
	"style": "asphodel",  # Grey ash fields with pale asphodel flowers.
	"base": Color(0.11, 0.11, 0.12),  # TUNING (not in GDD) grey underworld ash
	"line": Color(0.15, 0.15, 0.16),  # TUNING (not in GDD)
	"accent": Color(0.812, 0.796, 0.769),  # TUNING (not in GDD) marble asphodel petals
	"trim": Color(0.659, 0.439, 0.180),  # TUNING (not in GDD) bronze flower hearts
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Asphodel Underworld",
	"short_name": "Underworld",
	"chapter": "Chapter XII",
	"act": 4,  # Act IV, the Olympian Republic.
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "With Olympus silent, go down to the god who started it all: grey fields of asphodel, the River Styx, Charon's ferry and the gates of Tartarus. Hades waits on his throne.",
	"unlock": {"stage": "olympus", "boss_kills": 1},  # Owner-approved: each boss unlocks the next stage
	"unlock_text": "Topple Zeus on Mount Olympus to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act IV stages.
	"consecration": {},  # A Covenant event: none in Act IV.
	"crypt_defender": {},  # None in Act IV.
	"arena": ARENA,
	"ground": "pantheon",  # Placeholder PantheonGround until phase 2.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector).
	"pantheon": true,  # Act IV: Wrath of the Gods, Phalanx, Glory (PantheonRules).
	"wrath": WRATH,  # Act IV: this stage's wrath kind (DivineWrath).
	"zones": ZONES,  # Act IV stub: the planned zone names (phase 2 builds them).
	"music": "bronze",  # "Hymn of Bronze" (SoundData.BRONZE_SCORE), which also loads the Pantheon sound pack
}
