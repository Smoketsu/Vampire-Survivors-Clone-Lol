## BarrowFieldsStage — STAGE 16 (final order), THE BARROW FIELDS (the Hall of the
## Slain, temporarily Act XI, final slot VI; GDD §15.0 "The Hall of the Slain
## foundation (phase 1)"; the act's section "Stage 16: The Barrow Fields" of
## docs/proposals/LAST_SIX_ACTS.md). Snowfields of burial mounds above a frozen fjord. The barrows are cracking open: the hall's dead walk south, and the living march with them to fill its empty benches.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (phase 1). The stage is registered, unlocked in the
## campaign chain, runs the act's three shared rules ("norse": true: the Long
## Winter, Berserkergang and the Rune-Stones) and plays a simple timeline of
## the shared kinds (every rule shows: six braziers and the cold rising every
## 5:00, frost giants and seers dousing, berserkers and the wounded in the
## fury, four rune-stones raised by the "rune_stone" event)
## against a PLACEHOLDER boss script (the "vael" boss script under
## Hrimgar's name), with the Ragnarok Reckoning (the sun swallowed, the
## Einherjar of the hall march, the fire-giants, every valkyrie dives). It is hidden from
## the stage select ("playable": false) until phase 2 builds it: the open barrows, the Barrow-Wight (the miniboss) and Hrimgar the Draugr-King (the Grave, the Barrow Lord, the Last Rising; he rises three times unless his barrow is broken).
## Planned zones (ZONES; clock-driven like every stage): The Longshore, The Barrows, The Frozen Fjord, The Jarl's Hall.
## The boss arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD), tuned for the act's final
## slot VI (between the Shogunate and Olympus).
## CHAIN: the act opens after the Black Tide's last boss (Vandermere, stage `maelstrom`; set at the wave 1 integration).
class_name BarrowFieldsStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "barrow_fields"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (final slot VI: a hair above the Shogunate's 1.55 / 1.6 / 1.65; the step
## between the stages goes in HP, the Act IV lesson).
const ENEMY_HP_MULT: float = 1.6  # TUNING (not in GDD) placeholder, tuned in the act's bot passes
## Enemy damage multiplier of this stage on top of the shared time scaling
## (between Olympus's 1.3 and the Shogunate's 1.5).
const ENEMY_DAMAGE_MULT: float = 1.4  # TUNING (not in GDD) placeholder, tuned in the act's bot passes
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) 7:00, as Acts III to IX
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 1 of the act

## The four zones phase 2 builds (names from the proposal), each from `start`
## game seconds. The stub has one placeholder floor.
const ZONES := [
	{"id": "longshore", "name": "The Longshore", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "barrows", "name": "The Barrows", "start": 300.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "frozen_fjord", "name": "The Frozen Fjord", "start": 600.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "jarls_hall", "name": "The Jarl's Hall", "start": 900.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
]

## The Long Winter on this stage: {} = the defaults of
## NorseRulesData.LONG_WINTER (any of its keys overrides them here; "points":
## the braziers' offsets (px) from the start, else a seeded ring; phase 2 places
## them by the stage's map).
const LONG_WINTER := {}
## The Rune-Stones on this stage: {} = the defaults of NorseRulesData.RUNE_STONES
## (any of its keys overrides them here; e.g. a stage's own horn "table").
const RUNE_STONES := {}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): RAGNAROK,
## shared by every stage of the act: the wolf swallows the sun (a dark red
## sky), the Einherjar of the hall march at once, fire-giants step out of the
## south edge, every valkyrie dives at the ring ("ragnarok":
## NorseRulesData.RAGNAROK keys; {} = those defaults). Its waves' heavy is the
## fire-giant, with raiders, berserkers, wolves and a valkyrie.
const RECKONING := {
	"banner": "RAGNAROK: THE WOLF SWALLOWS THE SUN",
	"kind": NorseEnemyData.RECKONING_KIND,  # The shared Ragnarok heavy (the fire-giant).
	"ragnarok": {},  # NorseRulesData.RAGNAROK defaults (phase 2 may tune them here).
	"companions": NorseEnemyData.RECKONING_COMPANIONS,  # Raiders, berserkers, wolves, a valkyrie.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) fire-giants
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "RAGNAROK: the sun is gone, the hall's heroes march and the giants burn the field. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): a plain ramp
## of the shared kinds (placeholder), the stage's lead kind weighted up.
## Berserkers, valkyries and giants stay rare (elites and heavies).
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"raider": 0.8, "draugr": 0.2},
		"objective": "The Longshore: raiders come up from the fjord. Keep near the braziers: the cold is coming"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"raider": 0.64, "shield_maiden": 0.16, "draugr": 0.2},
		"objective": "Shield-maidens! Their bash throws your dead out of the ring"},
	{"start": 150.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"raider": 0.496, "shield_maiden": 0.16, "draugr": 0.296, "wolf_of_the_wastes": 0.048},
		"objective": "Draugr from the barrows: armoured, and their touch is cold"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"raider": 0.4, "shield_maiden": 0.144, "draugr": 0.312, "wolf_of_the_wastes": 0.08, "skald": 0.032, "seer": 0.032},
		"objective": "Skalds sing their warriors faster; seers douse braziers and re-carve the stones you take"},
	{"start": 480.0, "rate": 2.6, "max_alive": 70,  # TUNING (not in GDD)
		"weights": {"raider": 0.368, "shield_maiden": 0.144, "draugr": 0.312, "wolf_of_the_wastes": 0.08, "skald": 0.032, "seer": 0.032, "berserker": 0.02, "valkyrie": 0.012},
		"objective": "Wounded warriors go berserk: finish them in one blow"},
	{"start": 720.0, "rate": 2.9, "max_alive": 80,  # TUNING (not in GDD)
		"weights": {"raider": 0.352, "shield_maiden": 0.144, "draugr": 0.312, "wolf_of_the_wastes": 0.08, "skald": 0.032, "seer": 0.032, "berserker": 0.024, "valkyrie": 0.016, "frost_giant": 0.008},
		"objective": "Frost giants douse the braziers they pass. Stand by one to relight it"},
	{"start": 900.0, "rate": 3.1, "max_alive": 88,  # TUNING (not in GDD)
		"weights": {"raider": 0.336, "shield_maiden": 0.144, "draugr": 0.312, "wolf_of_the_wastes": 0.08, "skald": 0.032, "seer": 0.04, "berserker": 0.028, "valkyrie": 0.016, "frost_giant": 0.012},
		"objective": "The whole north comes south"},
	{"start": BOSS_TIME, "rate": 2.5, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"raider": 0.368, "shield_maiden": 0.144, "draugr": 0.312, "wolf_of_the_wastes": 0.08, "skald": 0.032, "seer": 0.032, "berserker": 0.02, "valkyrie": 0.012},
		"objective": "Hrimgar the Draugr-King has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus the type
## "rune_stone": `count` stones rise around the necromancer, RuneStones
## .start_event()). Wolves come in packs of 5 (owner-approved proposal).
const EVENTS := [
	{"time": 25.0, "type": "wave", "banner": "A raiding party comes up from the shore!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "raider", "count": 8, "elite": false}]},
	{"time": 45.0, "type": "rune_stone", "count": 1, "banner": "A rune-stone rises! Stand by it with your army to take it"},  # TUNING (not in GDD) rule 3: a stone the hall holds
	{"time": 120.0, "type": "wave", "banner": "Wolves of the wastes, hunting in packs!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "wolf_of_the_wastes", "count": 5, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}]},
	{"time": 200.0, "type": "wave", "banner": "A shield line, and a skald to sing it on!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "shield_maiden", "count": 4, "elite": false}, {"kind": "skald", "count": 1, "elite": false}, {"kind": "raider", "count": 6, "elite": false}]},
	{"time": 270.0, "type": "rune_stone", "count": 1, "banner": "Another rune-stone is carved! Its horn will call the hall"},  # TUNING (not in GDD) rule 3: a stone the hall holds
	{"time": 330.0, "type": "wave", "banner": "A berserker! Wound him and he is already in the fury", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "berserker", "count": 1, "elite": false}, {"kind": "raider", "count": 8, "elite": false}]},
	{"time": 420.0, "type": "wave", "banner": "A valkyrie! Bring her down with arrows and spells", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "valkyrie", "count": 1, "elite": false}, {"kind": "draugr", "count": 5, "elite": false}]},
	{"time": 520.0, "type": "rune_stone", "count": 1, "banner": "A seer carves a new stone!"},  # TUNING (not in GDD) rule 3: a stone the hall holds
	{"time": 540.0, "type": "wave", "banner": "Seers walk to the stones you took!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "seer", "count": 2, "elite": false}, {"kind": "shield_maiden", "count": 3, "elite": false}]},
	{"time": 600.0, "type": "wave", "banner": "A frost giant strides out of the snow!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "frost_giant", "count": 1, "elite": false}, {"kind": "draugr", "count": 6, "elite": false}]},
	{"time": 700.0, "type": "wave", "banner": "Two valkyries circle the ring!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "valkyrie", "count": 2, "elite": false}, {"kind": "raider", "count": 8, "elite": false}]},
	{"time": 780.0, "type": "rune_stone", "count": 1, "banner": "The last rune-stone rises!"},  # TUNING (not in GDD) rule 3: a stone the hall holds
	{"time": 840.0, "type": "wave", "banner": "Berserkers, and a skald to drive them!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "berserker", "count": 2, "elite": false}, {"kind": "skald", "count": 1, "elite": false}, {"kind": "raider", "count": 8, "elite": false}]},
	{"time": 930.0, "type": "wave", "banner": "Giants and wolves together!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "frost_giant", "count": 1, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The war-host gathers before its lord!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "raider", "count": 10, "elite": false}, {"kind": "shield_maiden", "count": 4, "elite": false}, {"kind": "valkyrie", "count": 1, "elite": false}, {"kind": "berserker", "count": 1, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA): the normal scattered-obstacle
## arena. Placeholder kinds drawn by NorseGlyphs until phase 2 brings the
## stage's own art.
const ARENA := {
	"density": 0.2,  # TUNING (not in GDD)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 1616,  # TUNING (not in GDD)
	"kinds": {
		"norse_barrow": {"weight": 0.45, "shape": "circle", "sizes": [18.0, 24.0, 30.0]},  # TUNING (not in GDD) placeholder art (burial mounds)
		"norse_pine": {"weight": 0.35, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD) placeholder art (snowy pines)
		"norse_boulder": {"weight": 0.2, "shape": "circle", "sizes": [10.0, 14.0]},  # TUNING (not in GDD) placeholder art (boulders)
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script
## under Hrimgar's name until phase 2 adds
## scripts/enemies/norse/boss_hrimgar.gd (then remove the "script" key).
const BOSS := {
	"id": "hrimgar",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_hrimgar.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "Hrimgar the Draugr-King",
	"short_name": "Hrimgar",
	"arrive_banner": "Hrimgar the Draugr-King rises from his barrow!",
	"defeat_banner": "Hrimgar sinks into his barrow for good! Hold out until the end...",
	"dead_objective": "Hrimgar is dead. Survive Ragnarok... you cannot.",
}

## Placeholder floor (NorseGround, code-drawn) until phase 2 brings the stage's
## zone floors: base colour, joint lines, accent, trim, style.
const FLOOR := {
	"style": "snow",  # Snowfields between the barrows, drifts and dead grass, frozen puddles.
	"base": Palette.NORSE_FROST_SHADE,  # TUNING (not in GDD)
	"line": Palette.NORSE_FROST,  # TUNING (not in GDD)
	"accent": Palette.NORSE_PINE_LIGHT,  # TUNING (not in GDD)
	"trim": Palette.NORSE_RUNE,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Barrow Fields",
	"short_name": "Barrow Fields",
	"chapter": "Chapter XVI",
	"act": 11,  # The Hall of the Slain: TEMPORARY act number 11 (final slot VI; the reorder pass renumbers it).
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "Snowfields of burial mounds above a frozen fjord. The barrows are cracking open: the hall's dead walk south, and the living march with them to fill its empty benches.",
	"unlock": {"stage": "maelstrom", "boss_kills": 1},  # Wave 1 integration: the chain runs ... -> Vandermere -> Hrimgar
	"unlock_text": "Defeat Captain Vandermere in the Maelstrom to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on the act's stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ARENA,
	"ground": "norse",  # Placeholder NorseGround until phase 2.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector).
	"norse": true,  # The Hall of the Slain: the Long Winter, Berserkergang, the Rune-Stones (NorseRules).
	"long_winter": LONG_WINTER,  # This stage's Long Winter overrides ({} = the defaults).
	"rune_stones": RUNE_STONES,  # This stage's Rune-Stone overrides ({} = the defaults).
	"zones": ZONES,  # Stub: the planned zones (phase 2 builds them).
	# Music key "bronze" FOR NOW (the Act IV hymn, whose lazy pack also renders
	# the horn and boulder sounds NorseRulesData.SOUNDS borrows): the audio pass
	# adds the act's own score and the lead switches this at the merge.
	"music": "valhall",  # Wave 1 integration: the act's own score (SoundData.SCORES; its pack renders with it)
}
