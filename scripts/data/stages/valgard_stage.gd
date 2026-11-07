## ValgardStage — STAGE 17 (final order), VALGARD, THE HALL OF HEROES (the Hall of the
## Slain, temporarily Act XI, final slot VI; GDD §15.0 "The Hall of the Slain
## foundation (phase 1)"; the act's section "Stage 17: Valgard, the Hall of Heroes" of
## docs/proposals/LAST_SIX_ACTS.md). A vast feast hall at the edge of the sky, long tables and shields on the walls. The benches stand empty, and every warrior who dies well here is carried back to them.
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
## Sigrun's name), with the Ragnarok Reckoning (the sun swallowed, the
## Einherjar of the hall march, the fire-giants, every valkyrie dives). It is hidden from
## the stage select ("playable": false) until phase 2 builds it: the Feast (Einherjar at the long tables wake on every horn), the Einherjar Champion (the miniboss) and Sigrun, the Shield-Queen (the Charge, the Holmgang, the Doors of the Hall: every Einherjar of the hall marches out at her side, a scripted wave).
## Planned zones (ZONES; clock-driven like every stage): The Shield Yard, The Mead Hall, The Hall of Spears, The Valkyries' Gate.
## The boss arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD), tuned for the act's final
## slot VI (between the Shogunate and Olympus).
class_name ValgardStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "valgard"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (final slot VI: a hair above the Shogunate's 1.55 / 1.6 / 1.65; the step
## between the stages goes in HP, the Act IV lesson).
const ENEMY_HP_MULT: float = 1.65  # TUNING (not in GDD) placeholder, tuned in the act's bot passes
## Enemy damage multiplier of this stage on top of the shared time scaling
## (between Olympus's 1.3 and the Shogunate's 1.5).
const ENEMY_DAMAGE_MULT: float = 1.45  # TUNING (not in GDD) placeholder, tuned in the act's bot passes
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) 7:00, as Acts III to IX
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 2 of the act

## The four zones phase 2 builds (names from the proposal), each from `start`
## game seconds. The stub has one placeholder floor.
const ZONES := [
	{"id": "shield_yard", "name": "The Shield Yard", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "mead_hall", "name": "The Mead Hall", "start": 300.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "hall_of_spears", "name": "The Hall of Spears", "start": 600.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "valkyries_gate", "name": "The Valkyries' Gate", "start": 900.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
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
		"weights": {"raider": 1.0},
		"objective": "The Shield Yard: the hall's warriors come for you. Keep near the braziers"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"raider": 0.777, "shield_maiden": 0.194, "valkyrie": 0.029},
		"objective": "Shield-maidens! Their bash throws your dead out of the ring"},
	{"start": 150.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"raider": 0.602, "shield_maiden": 0.194, "draugr": 0.117, "wolf_of_the_wastes": 0.058, "valkyrie": 0.029},
		"objective": "Draugr from the barrows: armoured, and their touch is cold"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"raider": 0.485, "shield_maiden": 0.175, "draugr": 0.136, "wolf_of_the_wastes": 0.097, "skald": 0.039, "seer": 0.039, "valkyrie": 0.029},
		"objective": "Skalds sing their warriors faster; seers douse braziers and re-carve the stones you take"},
	{"start": 480.0, "rate": 2.6, "max_alive": 70,  # TUNING (not in GDD)
		"weights": {"raider": 0.447, "shield_maiden": 0.175, "draugr": 0.136, "wolf_of_the_wastes": 0.097, "skald": 0.039, "seer": 0.039, "berserker": 0.024, "valkyrie": 0.044},
		"objective": "Wounded warriors go berserk: finish them in one blow"},
	{"start": 720.0, "rate": 2.9, "max_alive": 80,  # TUNING (not in GDD)
		"weights": {"raider": 0.427, "shield_maiden": 0.175, "draugr": 0.136, "wolf_of_the_wastes": 0.097, "skald": 0.039, "seer": 0.039, "berserker": 0.029, "valkyrie": 0.049, "frost_giant": 0.01},
		"objective": "Frost giants douse the braziers they pass. Stand by one to relight it"},
	{"start": 900.0, "rate": 3.1, "max_alive": 88,  # TUNING (not in GDD)
		"weights": {"raider": 0.408, "shield_maiden": 0.175, "draugr": 0.136, "wolf_of_the_wastes": 0.097, "skald": 0.039, "seer": 0.049, "berserker": 0.034, "valkyrie": 0.049, "frost_giant": 0.015},
		"objective": "The whole north comes south"},
	{"start": BOSS_TIME, "rate": 2.5, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"raider": 0.447, "shield_maiden": 0.175, "draugr": 0.136, "wolf_of_the_wastes": 0.097, "skald": 0.039, "seer": 0.039, "berserker": 0.024, "valkyrie": 0.044},
		"objective": "Sigrun, the Shield-Queen has come for you"},
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
	"layout_seed": 1717,  # TUNING (not in GDD)
	"kinds": {
		"norse_long_table": {"weight": 0.45, "shape": "rect", "sizes": [40.0, 56.0], "short": 12.0},  # TUNING (not in GDD) placeholder art (feast tables)
		"norse_pillar": {"weight": 0.55, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD) placeholder art (carved pillars)
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script
## under Sigrun's name until phase 2 adds
## scripts/enemies/norse/boss_sigrun.gd (then remove the "script" key).
const BOSS := {
	"id": "sigrun",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_sigrun.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "Sigrun, the Shield-Queen",
	"short_name": "Sigrun",
	"arrive_banner": "Sigrun, the Shield-Queen, leads her valkyrie wing down!",
	"defeat_banner": "Sigrun falls, and the hall's doors swing shut! Hold out until the end...",
	"dead_objective": "Sigrun is dead. Survive Ragnarok... you cannot.",
}

## Placeholder floor (NorseGround, code-drawn) until phase 2 brings the stage's
## zone floors: base colour, joint lines, accent, trim, style.
const FLOOR := {
	"style": "hall",  # The feast hall's broad planks, rushes and hearth embers.
	"base": Color(0.24, 0.16, 0.10),  # TUNING (not in GDD)
	"line": Color(0.17, 0.11, 0.07),  # TUNING (not in GDD)
	"accent": Palette.NORSE_HEARTH_DARK,  # TUNING (not in GDD)
	"trim": Palette.NORSE_HEARTH,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Valgard, the Hall of Heroes",
	"short_name": "Valgard",
	"chapter": "Chapter XVII",
	"act": 11,  # The Hall of the Slain: TEMPORARY act number 11 (final slot VI; the reorder pass renumbers it).
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "A vast feast hall at the edge of the sky, long tables and shields on the walls. The benches stand empty, and every warrior who dies well here is carried back to them.",
	"unlock": {"stage": "barrow_fields", "boss_kills": 1},
	"unlock_text": "Defeat Hrimgar the Draugr-King in the Barrow Fields to unlock.",
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
