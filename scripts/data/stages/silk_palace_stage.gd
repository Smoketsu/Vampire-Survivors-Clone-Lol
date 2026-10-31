## SilkPalaceStage — STAGE 17, THE PALACE OF SILK AND ASH (Act VI, the Inferno; GDD §15.0
## "Act VI foundation (phase 1)", owner-approved proposal docs/act6/PROPOSAL.md
## "Stage 17: The Palace of Silk and Ash"). The court of desire: velvet halls, mirrors, rose gardens of black thorns, a ballroom over a lava lake.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (Act VI phase 1). The stage is registered, unlocked
## in the campaign chain, runs the Inferno's three shared rules ("inferno":
## true: the Hell Pits with this stage's fixed pits per zone ("pits": {} = the
## defaults), the demon portals (timeline "portal" events), Temptation through
## the succubi) and plays a simple timeline of the shared kinds (the damned,
## imps, hell knights, succubi, demon brutes) against a PLACEHOLDER boss script
## (the "vael" boss script under Lilith's name), with the Last Judgment
## Reckoning (every portal opens at once, the pits open faster, the Adversary's
## hand; demon brutes). It is hidden from the stage select ("playable": false)
## until phase 2 builds it: the Hall of Mirrors (reflections that confuse summon targeting), the ballroom over the lava lake, the Twin Succubi, the Lilim Witch, Lilith.
## Planned zones (ZONES; clock-driven like every stage): The Rose Garden, The Hall of Mirrors, The Ballroom, The Queen's Chamber.
## Lilith arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD).
class_name SilkPalaceStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "silk_palace"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act VI starts a step above the Road to the Sun's 1.65; the step goes in HP,
## not damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 1.75  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling (the
## Road to the Sun's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Acts III to V: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 2 of Act VI

## The four zones phase 2 builds (names from the owner-approved proposal), each
## from `start` game seconds. The stub has one placeholder floor; the Hell Pits
## draw a new table of fixed pits for each zone (HellPits).
const ZONES := [
	{"id": "rose_garden", "name": "The Rose Garden", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "hall_of_mirrors", "name": "The Hall of Mirrors", "start": 300.0},
	{"id": "ballroom", "name": "The Ballroom", "start": 600.0},
	{"id": "queens_chamber", "name": "The Queen's Chamber", "start": 900.0},
]

## The Hell Pits on this stage: {} = the defaults of InfernoRulesData.PITS
## (any of its keys overrides them here; phase 2 tunes each zone's fixed pits).
const PITS := {}

## The demon portals on this stage: any InfernoRulesData.PORTALS key ({} = the
## defaults); "table" is the squads its portals pour.
const PORTALS := {"table": [{"kind": "imp", "count": 3, "weight": 1.0}, {"kind": "damned", "count": 3, "weight": 0.8}, {"kind": "succubus", "count": 1, "weight": 0.25}]}  # TUNING (not in GDD) this stage's squads

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Last
## Judgment, shared by every Act VI stage: every portal opens at once, the pits
## open faster each minute and the Adversary's hand reaches up through the
## floor ("last_judgment": InfernoRulesData.LAST_JUDGMENT keys; {} = those
## defaults); demon brutes ("kind") step out with imps and the damned.
const RECKONING := {
	"banner": "THE LAST JUDGMENT: THE PIT OPENS",
	"kind": InfernoEnemyData.DEMON_BRUTE,  # The shared Last Judgment heavy.
	"last_judgment": {},  # InfernoRulesData.LAST_JUDGMENT defaults (phase 2 may tune them here).
	"companions": [{"kind": InfernoEnemyData.IMP, "count": 6, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": InfernoEnemyData.DAMNED, "count": 4, "growth": 1.0}],  # TUNING (not in GDD)
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) brutes are heavy
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE LAST JUDGMENT: the Pit has come for every soul. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): a plain ramp
## of the shared kinds (placeholder). Succubi stay rare (Temptation holds at
## most 3 summons at once anyway).
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"damned": 1.0},
		"objective": "The Rose Garden: the damned shuffle toward you. Lead them through the pits"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"damned": 0.7, "imp": 0.3},
		"objective": "Imps fly over the pits: they never burn"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"damned": 0.55, "imp": 0.25, "hell_knight": 0.2},
		"objective": "Hell knights in ember armour: step out of the burning blade"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"damned": 0.47, "imp": 0.25, "hell_knight": 0.26, "succubus": 0.02},
		"objective": "The Hall of Mirrors: kill the succubi before they kiss your dead"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"damned": 0.42, "imp": 0.25, "hell_knight": 0.3, "succubus": 0.02, "demon_brute": 0.01},
		"objective": "The Ballroom: the brutes come. Seal the portals"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"damned": 0.38, "imp": 0.25, "hell_knight": 0.33, "succubus": 0.025, "demon_brute": 0.015},
		"objective": "The Queen's Chamber: hell pours out to meet you"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"damned": 0.4, "imp": 0.3, "hell_knight": 0.25, "succubus": 0.02, "demon_brute": 0.01},
		"objective": "Lilith has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus the Act VI
## type "portal": `count` demon portals around the necromancer, DemonPortals
## .start_event(), keys count / banner / distance_min / distance_max / table /
## pour_every).
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "The damned are dragged toward you in chains!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "damned", "count": 16, "elite": false}]},
	{"time": 90.0, "type": "portal", "count": 1, "banner": "A demon portal tears open! Stand in its ring to seal it!"},  # TUNING (not in GDD)
	{"time": 150.0, "type": "wave", "banner": "A swarm of imps!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "imp", "count": 12, "elite": false}]},
	{"time": 240.0, "type": "wave", "banner": "Hell knights advance in burning armour!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "hell_knight", "count": 4, "elite": false}, {"kind": "damned", "count": 10, "elite": false}]},
	{"time": 330.0, "type": "wave", "banner": "A succubus! Kill her before she turns your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "succubus", "count": 1, "elite": false}, {"kind": "imp", "count": 8, "elite": false}]},
	{"time": 420.0, "type": "portal", "count": 2, "banner": "Two portals open!"},  # TUNING (not in GDD)
	{"time": 540.0, "type": "wave", "banner": "The succubi descend!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "succubus", "count": 2, "elite": false}, {"kind": "hell_knight", "count": 3, "elite": false}, {"kind": "damned", "count": 10, "elite": false}]},
	{"time": 660.0, "type": "wave", "banner": "A demon brute shoulders through!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "demon_brute", "count": 1, "elite": false}, {"kind": "imp", "count": 10, "elite": false}]},
	{"time": 720.0, "type": "portal", "count": 2, "banner": "The portals multiply!"},  # TUNING (not in GDD)
	{"time": 840.0, "type": "wave", "banner": "Brutes and knights!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "demon_brute", "count": 2, "elite": false}, {"kind": "hell_knight", "count": 4, "elite": false}, {"kind": "succubus", "count": 1, "elite": false}]},
	{"time": 930.0, "type": "portal", "count": 3, "banner": "Hell gapes open around you!"},  # TUNING (not in GDD)
	{"time": 990.0, "type": "wave", "banner": "The host of the Pit gathers!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "succubus", "count": 2, "elite": false}, {"kind": "hell_knight", "count": 5, "elite": false}, {"kind": "damned", "count": 14, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA). Placeholder kinds drawn by
## InfernoGlyphs until phase 2 brings the stage's own art.
const ARENA := {
	"density": 0.2,  # TUNING (not in GDD)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 1717,  # TUNING (not in GDD) also salts the fixed Hell Pits (HellPits)
	"kinds": {
		"marble_column": {"weight": 0.5, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD) placeholder art
		"velvet_divan": {"weight": 0.5, "shape": "rect", "sizes": [40.0, 52.0], "short": 20.0},  # TUNING (not in GDD) placeholder art
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script
## under Lilith's name until phase 2 adds scripts/enemies/inferno/boss_lilith.gd
## (then remove the "script" key).
const BOSS := {
	"id": "lilith",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_lilith.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "Lilith, Queen of the Night",
	"short_name": "Lilith",
	"arrive_banner": "Lilith, Queen of the Night, Mother of Demons, descends!",
	"defeat_banner": "Lilith falls, her court with her! Hold out until the end...",
	"dead_objective": "Lilith is dead. Survive the Last Judgment... you cannot.",
}

## Placeholder floor (InfernoGround, code-drawn) until phase 2 brings the
## stage's zone floors: base colour, joint lines, accent, trim, style.
const FLOOR := {
	"style": "velvet",  # Rose-veined marble, velvet runners, black-rose petals.
	"base": Color(0.22, 0.17, 0.20),  # TUNING (not in GDD) rose-veined marble
	"line": Color(0.28, 0.22, 0.26),  # TUNING (not in GDD)
	"accent": Palette.INFERNO_DEMON_DARK,  # TUNING (not in GDD) velvet runners
	"trim": Color(0.10, 0.05, 0.08),  # TUNING (not in GDD) black-rose petals
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Palace of Silk and Ash",
	"short_name": "The Palace",
	"chapter": "Chapter XVII",
	"act": 6,  # Act VI, the Inferno.
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "The court of desire: velvet halls, mirrors, rose gardens of black thorns and a ballroom over a lava lake, where every smile is a snare for your dead.",
	"unlock": {"stage": "burning_gate", "boss_kills": 1},  # Owner-approved: each Act VI stage opens the next
	"unlock_text": "Slay Moloch at the Burning Gate to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act VI stages.
	"consecration": {},  # A Covenant event: none in Act VI.
	"crypt_defender": {},  # None in Act VI.
	"arena": ARENA,
	"ground": "inferno",  # Placeholder InfernoGround until phase 2.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector).
	"inferno": true,  # Act VI: the Hell Pits, the portals, Temptation (InfernoRules).
	"pits": PITS,  # Act VI: this stage's Hell Pits overrides ({} = the defaults).
	"portals": PORTALS,  # Act VI: this stage's portal overrides.
	"zones": ZONES,  # Act VI stub: the planned zones (phase 2 builds them; the fixed pits change with each).
	# Music key "brimstone": the Act VI loop "Hymn of the Pit" (SoundData.BRIMSTONE_SCORE).
	"music": "brimstone",
}
