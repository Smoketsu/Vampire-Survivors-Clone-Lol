## LionessTempleStage — STAGE 35 (temporary number; final stage 20), THE TEMPLE OF THE LIONESS
## (temporary Act XII, the Necropolis Dynasty, final slot VII; GDD §15.0 "The
## Necropolis Dynasty foundation (phase 1)"; proposal
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 3). A sun-baked temple of colonnades and statue-lined courts, sacred to the goddess of war and plague.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (phase 1). The stage is registered, unlocked in the
## campaign chain, runs the Dynasty's three shared rules ("dynasty": true:
## Rebirth, the Black Land, Heka) and plays a simple timeline of ALL the shared
## kinds (so every rule shows) against a PLACEHOLDER boss script (the "vael"
## boss script under Sekhmet's name), with the Devourer's Hour Reckoning
## (Rebirth without limit, the endless Sandstorm, the Devourer's lanes). It is
## hidden from the stage select ("playable": false) until phase 2 builds it:
## the Awakening Statues (obstacle rows that wake as Ushabti and Sand Colossi), the Bastet Hunter and the Ushabti Statue, the Lion Warden (the miniboss), Sekhmet, the Lioness of Retribution (the Hunt, the Red Wind through Sandstorm.force() and Heka.set_jump_speed(), the Feast and its wine jars).
## Planned zones (ZONES; clock-driven like every stage): The Avenue of Statues, The Courtyard, The Hypostyle Hall and The Sanctuary.
## Sekhmet arrives with 3:00 left; the Reckoning at 0:00.
## Tuned for the act's FINAL slot VII (docs/last_acts/PLAN.md: the Shogunate /
## Olympus level), not its temporary number. Every rate, cap and weight is
## TUNING (not in GDD).
class_name LionessTempleStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "lioness_temple"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot VII sits between the Shogunate's 1.55-1.65 and Olympus's 1.45; a
## little lower than both, because Rebirth gives an uncountered body up to
## 1 + 0.7 + 0.7 of its HP again).
const ENEMY_HP_MULT: float = 1.45  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling
## (a returned body hits x1.2 per return on top).
const ENEMY_DAMAGE_MULT: float = 1.35  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to IX (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 2 of the act

## The four zones phase 2 builds (names from the proposal), each from `start`
## game seconds. The stub has one placeholder floor.
const ZONES := [
	{"id": "avenue", "name": "The Avenue of Statues", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "courtyard", "name": "The Courtyard", "start": 300.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "hypostyle", "name": "The Hypostyle Hall", "start": 600.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "sanctuary", "name": "The Sanctuary", "start": 900.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
]

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the
## DEVOURER'S HOUR, shared by every Dynasty stage: every sarcophagus opens
## ("kind": the khopesh guard, with the shared kinds as companions), Rebirth
## has no limit, the Sandstorm becomes permanent and the Devourer sweeps its
## lanes ("devourers_hour": DynastyRulesData.DEVOURER keys; {} = those
## defaults).
const RECKONING := {
	"banner": "THE DEVOURER'S HOUR: EVERY SARCOPHAGUS OPENS",
	"kind": DynastyEnemyData.RECKONING_KIND,  # The shared Devourer's Hour heavy (the khopesh guard).
	"devourers_hour": {},  # DynastyRulesData.DEVOURER defaults (phase 2 may tune them here).
	"companions": DynastyEnemyData.RECKONING_COMPANIONS,  # Mummies, scarabs, a Heka priest.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) guards
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE DEVOURER'S HOUR: the dead rise without end, and the Devourer eats its lanes. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): a plain ramp
## of the shared kinds (placeholder); the priests stay rare.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"mummy": 0.6, "mummy_female": 0.4},
		"objective": "The Avenue of Statues: the wrapped dead walk. A fallen mummy's Name waits over it: smash it or raise it"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"mummy": 0.45, "mummy_female": 0.3, "scarab_swarm": 0.25},
		"objective": "Scarabs gnaw your Warders' barriers. A Name left alone for 6 s stands up again"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"mummy": 0.4, "mummy_female": 0.27, "scarab_swarm": 0.18, "khopesh_guard": 0.1, "heka_priest": 0.05},
		"objective": "Heka priests curse your dead. A Mender's heal or a Warder's barrier clears the glyph"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"mummy": 0.36, "mummy_female": 0.25, "scarab_swarm": 0.17, "khopesh_guard": 0.12, "heka_priest": 0.05, "embalmer": 0.05},
		"objective": "The Courtyard: Embalmers hasten the Names, and the Canopic Jars hold them. Break the jars"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"mummy": 0.34, "mummy_female": 0.24, "scarab_swarm": 0.16, "khopesh_guard": 0.14, "heka_priest": 0.06, "embalmer": 0.06},
		"objective": "The Hypostyle Hall: when the sand blows, every bow and spell reaches half as far"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"mummy": 0.32, "mummy_female": 0.23, "scarab_swarm": 0.16, "khopesh_guard": 0.16, "heka_priest": 0.07, "embalmer": 0.06},
		"objective": "The Sanctuary: the Dynasty comes for its dead, and for yours"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"mummy": 0.36, "mummy_female": 0.25, "scarab_swarm": 0.17, "khopesh_guard": 0.12, "heka_priest": 0.05, "embalmer": 0.05},
		"objective": "Sekhmet has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS).
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "The wrapped dead rise from the sand!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "mummy", "count": 8, "elite": false}, {"kind": "mummy_female", "count": 6, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "A swarm of scarabs pours out of a tomb!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "scarab_swarm", "count": 5, "elite": false}, {"kind": "mummy", "count": 6, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "A Heka priest raises his hands: a glyph for your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "heka_priest", "count": 1, "elite": false}, {"kind": "khopesh_guard", "count": 3, "elite": false}]},
	{"time": 260.0, "type": "wave", "banner": "An Embalmer walks with the dead: their Names return faster!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "embalmer", "count": 1, "elite": false}, {"kind": "mummy", "count": 8, "elite": false}, {"kind": "mummy_female", "count": 6, "elite": false}]},
	{"time": 380.0, "type": "wave", "banner": "The guard of the tombs advances!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "khopesh_guard", "count": 5, "elite": false}, {"kind": "heka_priest", "count": 1, "elite": false}]},
	{"time": 480.0, "type": "wave", "banner": "Two swarms at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "scarab_swarm", "count": 5, "elite": false}, {"kind": "scarab_swarm", "count": 5, "elite": false}, {"kind": "mummy", "count": 6, "elite": false}]},
	{"time": 640.0, "type": "wave", "banner": "The priesthood comes to wrap its dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "heka_priest", "count": 2, "elite": false}, {"kind": "embalmer", "count": 2, "elite": false}, {"kind": "mummy", "count": 10, "elite": false}]},
	{"time": 780.0, "type": "wave", "banner": "A procession of the dead!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "mummy", "count": 12, "elite": false}, {"kind": "mummy_female", "count": 10, "elite": false}, {"kind": "khopesh_guard", "count": 3, "elite": false}]},
	{"time": 930.0, "type": "wave", "banner": "The whole Dynasty comes!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "khopesh_guard", "count": 4, "elite": false}, {"kind": "heka_priest", "count": 2, "elite": false}, {"kind": "embalmer", "count": 1, "elite": false}, {"kind": "scarab_swarm", "count": 5, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The dead gather before their master!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "mummy", "count": 12, "elite": false}, {"kind": "mummy_female", "count": 10, "elite": false}, {"kind": "embalmer", "count": 1, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA): the normal scattered-obstacle
## arena. Placeholder kinds drawn by DynastyGlyphs until phase 2 brings the
## stage's own art.
const ARENA := {
	"density": 0.2,  # TUNING (not in GDD)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 3535,  # TUNING (not in GDD) (also salts the quicksand)
	"kinds": {
		"dynasty_column": {"weight": 0.60, "shape": "circle", "sizes": [12.0, 14.0]},  # TUNING (not in GDD) placeholder art (a painted column of the colonnade)
		"dynasty_statue": {"weight": 0.40, "shape": "rect", "sizes": [20.0, 26.0], "short": 14.0},  # TUNING (not in GDD) placeholder art (a seated lioness statue on its plinth)
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script
## under Sekhmet's name until phase 2 adds
## scripts/enemies/dynasty/boss_sekhmet.gd (then remove the "script" key).
const BOSS := {
	"id": "sekhmet",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_sekhmet.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "Sekhmet, the Lioness of Retribution",
	"short_name": "Sekhmet",
	"arrive_banner": "Sekhmet, the Lioness of Retribution, leaps down from her pillar!",
	"defeat_banner": "Sekhmet falls, and the temple is still! Hold out until the end...",
	"dead_objective": "Sekhmet is dead. Survive the Devourer's Hour... you cannot.",
}

## Placeholder floor (DynastyGround, code-drawn) until phase 2 brings the
## stage's zone floors: base colour, joint lines, accent, trim, style.
const FLOOR := {
	"style": "temple",  # sun-baked sandstone flagstones, carnelian inlay.
	"base": Color(0.50, 0.40, 0.27),  # TUNING (not in GDD)
	"line": Color(0.40, 0.31, 0.20),  # TUNING (not in GDD)
	"accent": Palette.DYN_SAND_LIGHT,  # TUNING (not in GDD)
	"trim": Palette.DYN_CARNELIAN,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Temple of the Lioness",
	"short_name": "Lioness Temple",
	"chapter": "Chapter XXXV",  # Temporary (the reorder pass renumbers; final stage 20).
	"act": 12,  # Temporary Act XII, the Necropolis Dynasty (final slot VII; docs/last_acts/PLAN.md).
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "A sun-baked temple of colonnades and statue-lined courts, sacred to the goddess of war and plague: here the stone itself walks.",
	"unlock": {"stage": "necropolis", "boss_kills": 1},  # Brief: each stage opens the next
	"unlock_text": "Defeat Anubis at the Necropolis of Sand to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Dynasty stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ARENA,
	"ground": "dynasty",  # Placeholder DynastyGround until phase 2.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector) if it wants them.
	"dynasty": true,  # Rebirth, the Black Land, Heka (DynastyRules).
	"rebirth": {},  # This stage's Rebirth overrides ({} = DynastyRulesData.REBIRTH).
	"jars": {},  # This stage's jar clock ({} = DynastyRulesData.JARS: the stub's own jars).
	"quicksand": {},  # This stage's quicksand ({} = DynastyRulesData.QUICKSAND).
	"sandstorm": {},  # This stage's Sandstorm ({} = DynastyRulesData.SANDSTORM).
	"heka": {},  # This stage's Heka ({} = DynastyRulesData.HEKA).
	"zones": ZONES,  # The planned zones (phase 2 builds them).
	# Music key "bronze" FOR NOW ("Hymn of Bronze", an ancient-world loop that
	# exists): the Dynasty's own score comes from the art and audio pass and
	# the lead switches this key at the merge.
	"music": "bronze",
}
