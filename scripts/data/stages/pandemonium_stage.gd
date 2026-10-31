## PandemoniumStage — STAGE 18, PANDEMONIUM, the finale of Act VI (the
## Inferno) and of Part One (GDD §15.0 "Act VI foundation (phase 1)" and
## "Pandemonium (Act VI phase 2)"; owner-approved proposal
## docs/act6/PROPOSAL.md "Stage 18: Pandemonium"). The capital of hell: an
## obsidian cathedral city, chains, rivers of lava, and the throne. Every number
## and event that belongs to this stage; StageRegistry exposes it to the run as
## `Game.stage_def` (the STAGE dictionary at the bottom; its keys are documented
## in StageRegistry). Unlocked by slaying Lilith in the Palace of Silk and Ash.
##
## THE CLOCK IS AUTHORITATIVE, as on every zoned stage: four zones on fixed
## times (ZONES, run by MarchDirector: a zone banner, a sweep of smoke, the
## obstacles and floor re-drawn as the next zone), and the Inferno's three
## shared rules run all along (Game.inferno: the Hell Pits with one fixed table
## per zone, the demon portals, Temptation):
##   20:00  Zone I,   the Iron City:        iron braziers, chain posts, spiked
##                                           iron walls; the damned, imps, hell
##                                           knights
##   15:00  Zone II,  the Chain Bridges:    chain bridges over rivers of lava
##                                           (the most fixed pits of the run),
##                                           obsidian shards; succubi and the
##                                           FALLEN ANGELS, who dive from above
##   10:00  Zone III, the Cathedral of Ash: ash columns, burning censers, pews;
##                                           demon brutes
##    8:20  THE FALLEN SERAPH GENERAL, the miniboss
##    5:00  Zone IV,  the Throne:            skull pillars, obsidian shards,
##                                           braziers before the throne
##    3:00  THE MORNING STAR (BossMorningStar, MorningStarData): the Angel, then
##          the Beast; when he falls, the necromancer takes the throne
##    0:00  THE LAST JUDGMENT (the shared Act VI Reckoning)
## The other Act VI stages' kinds (the Burning Gate's, the Palace of Silk and
## Ash's) join as guest squads once this build knows them (PANDEMONIUM
## "guests"), like the Road to the Sun's guests. Every rate, cap and weight is
## TUNING (not in GDD) unless marked as the owner-approved proposal.
class_name PandemoniumStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "pandemonium"

# =====================================================================================
# Run structure
# =====================================================================================

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
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 3 of Act VI

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES
## (the Hell Pits read the same list: one fixed-pit table per zone, from each
## `start`). `ground` is a PandemoniumGround look: style "iron" (obsidian
## paving with iron plates and lava seams), "bridges" (black planks and chains
## over the lava glow), "cathedral" (ash-stone flagstones and scorch marks) or
## "throne" (polished obsidian with gold inlay and bone); base / line / accent
## colours of the code floor (the tiles/pandemonium_<style> PNG replaces them
## when it exists). Obstacle kinds are drawn by PandemoniumGlyphs (their
## obstacles/<kind> PNGs when they exist).
const ZONES := [
	{"id": "iron_city", "start": 0.0, "numeral": "I", "name": "The Iron City",  # Owner-approved proposal zone I
		"blurb": "Streets of black iron and obsidian, where the damned are herded in chains",
		"ground": {"style": "iron", "base": Color(0.07, 0.065, 0.085), "line": Color(0.13, 0.12, 0.15),
			"accent": Palette.INFERNO_LAVA},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 1881,  # TUNING (not in GDD) also salts the fixed Hell Pits
			"kinds": {
				"iron_brazier": {"weight": 0.35, "shape": "circle", "sizes": [12.0, 15.0]},  # TUNING (not in GDD)
				"chain_post": {"weight": 0.3, "shape": "circle", "sizes": [10.0, 12.0]},  # TUNING (not in GDD)
				"iron_wall": {"weight": 0.35, "shape": "rect", "sizes": [44.0, 60.0], "short": 16.0},  # TUNING (not in GDD)
			}},
	},
	{"id": "chain_bridges", "start": 300.0, "numeral": "II", "name": "The Chain Bridges",  # Owner-approved proposal zone II
		"blurb": "Bridges of black planks and chains slung over rivers of lava",
		"ground": {"style": "bridges", "base": Color(0.09, 0.06, 0.06), "line": Color(0.16, 0.10, 0.08),
			"accent": Palette.INFERNO_LAVA_LIGHT},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 1882,  # TUNING (not in GDD) open: the lava is the hazard here
			"kinds": {
				"bridge_rail": {"weight": 0.45, "shape": "rect", "sizes": [44.0, 60.0], "short": 16.0},  # TUNING (not in GDD)
				"chain_post": {"weight": 0.3, "shape": "circle", "sizes": [10.0, 12.0]},  # TUNING (not in GDD)
				"obsidian_shard": {"weight": 0.25, "shape": "circle", "sizes": [12.0, 15.0, 18.0]},  # TUNING (not in GDD)
			}},
	},
	{"id": "cathedral_of_ash", "start": 600.0, "numeral": "III", "name": "The Cathedral of Ash",  # Owner-approved proposal zone III
		"blurb": "A burnt cathedral of the Pit, its pews full of ash and its censers still burning",
		"ground": {"style": "cathedral", "base": Color(0.12, 0.115, 0.13), "line": Color(0.08, 0.075, 0.09),
			"accent": Color(0.55, 0.53, 0.55)},
		"arena": {"density": 0.24, "clear_radius": 220.0, "layout_seed": 1883,  # TUNING (not in GDD)
			"kinds": {
				"ash_column": {"weight": 0.4, "shape": "circle", "sizes": [14.0, 18.0, 22.0]},  # TUNING (not in GDD)
				"burning_censer": {"weight": 0.25, "shape": "circle", "sizes": [10.0, 12.0]},  # TUNING (not in GDD)
				"ash_pew": {"weight": 0.35, "shape": "rect", "sizes": [44.0, 60.0], "short": 16.0},  # TUNING (not in GDD)
			}},
	},
	{"id": "throne", "start": 900.0, "numeral": "IV", "name": "The Throne",  # Owner-approved proposal zone IV
		"blurb": "Before the throne of the Adversary: obsidian, gold and the bones of the proud",
		"ground": {"style": "throne", "base": Color(0.06, 0.05, 0.08), "line": Color(0.14, 0.12, 0.17),
			"accent": Palette.GOLD},
		"arena": {"density": 0.22, "clear_radius": 240.0, "layout_seed": 1884,  # TUNING (not in GDD)
			"kinds": {
				"skull_pillar": {"weight": 0.35, "shape": "circle", "sizes": [12.0, 15.0]},  # TUNING (not in GDD)
				"obsidian_shard": {"weight": 0.35, "shape": "circle", "sizes": [12.0, 15.0, 18.0]},  # TUNING (not in GDD)
				"iron_brazier": {"weight": 0.3, "shape": "circle", "sizes": [12.0, 15.0]},  # TUNING (not in GDD)
			}},
	},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "DEEPER INTO PANDEMONIUM  -  ZONE %s",
	"zone_color": Palette.INFERNO_LAVA,  # The lava's orange.
	"fog_color": Color(0.08, 0.05, 0.06),  # Brimstone smoke.
	"fog_bank_color": Color(0.30, 0.22, 0.22),  # Ash banks.
	"zones": ZONES,
}

## The Hell Pits on this stage (any InfernoRulesData.PITS key; the rest are the
## defaults): one fixed-pit chance per zone. The Chain Bridges run over rivers
## of lava (the most fixed pits), the Throne's floor is breaking.
const PITS := {
	"fixed_chance": [0.28, 0.55, 0.38, 0.48],  # TUNING (not in GDD) Iron City, Chain Bridges, Cathedral of Ash, Throne
}

## The demon portals on this stage: any InfernoRulesData.PORTALS key ({} = the
## defaults); "table" is the squads its portals pour.
const PORTALS := {"table": [{"kind": "imp", "count": 3, "weight": 1.0}, {"kind": "damned", "count": 3, "weight": 0.7},  # TUNING (not in GDD) this stage's squads
	{"kind": "hell_knight", "count": 2, "weight": 0.6}, {"kind": "fallen_angel", "count": 1, "weight": 0.2}]}  # TUNING (not in GDD) a fallen angel now and then

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Last
## Judgment, shared by every Act VI stage: every portal opens at once, the pits
## open faster each minute and the Adversary's hand reaches up through the
## floor ("last_judgment": InfernoRulesData.LAST_JUDGMENT keys; {} = those
## defaults); demon brutes ("kind") step out with imps, the damned and the
## Fallen Angels.
const RECKONING := {
	"banner": "THE LAST JUDGMENT: THE PIT OPENS",
	"kind": InfernoEnemyData.DEMON_BRUTE,  # The shared Last Judgment heavy.
	"last_judgment": {},  # InfernoRulesData.LAST_JUDGMENT defaults.
	"companions": [{"kind": InfernoEnemyData.IMP, "count": 6, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": InfernoEnemyData.DAMNED, "count": 4, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": PandemoniumEnemyData.FALLEN_ANGEL, "count": 1, "growth": 0.5}],  # TUNING (not in GDD) the finale's own elite
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) brutes are heavy
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE LAST JUDGMENT: the Pit has come for every soul. Endure."

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): the damned
## and imps first, then hell knights; succubi and the Fallen Angels on the
## bridges; demon brutes in the cathedral. Succubi stay rare (Temptation holds
## at most 3 summons at once).
const SEGMENTS := [
	# Zone I, the Iron City.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"damned": 1.0},
		"objective": "The Iron City: the damned shuffle toward you. Lead them through the pits"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"damned": 0.7, "imp": 0.3},
		"objective": "Imps fly over the pits: they never burn"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"damned": 0.55, "imp": 0.25, "hell_knight": 0.2},
		"objective": "Hell knights in ember armour: step out of the burning blade"},
	# Zone II, the Chain Bridges.
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"damned": 0.46, "imp": 0.25, "hell_knight": 0.26, "succubus": 0.02, "fallen_angel": 0.01},
		"objective": "The Chain Bridges: lava below, angels above. Your gargoyles and archers answer them"},
	{"start": 420.0, "rate": 2.5, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"damned": 0.42, "imp": 0.25, "hell_knight": 0.28, "succubus": 0.025, "fallen_angel": 0.02},
		"objective": "Fallen Angels dive with burning spears: step out of the ring"},
	# Zone III, the Cathedral of Ash.
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"damned": 0.4, "imp": 0.24, "hell_knight": 0.3, "succubus": 0.02, "fallen_angel": 0.025, "demon_brute": 0.01},
		"objective": "The Cathedral of Ash: the brutes come. Seal the portals"},
	# Zone IV, the Throne.
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"damned": 0.36, "imp": 0.24, "hell_knight": 0.32, "succubus": 0.025, "fallen_angel": 0.03, "demon_brute": 0.015},
		"objective": "The Throne: all of hell stands between you and it"},
	# 17:00, the boss: a thinner trickle so the fight stays readable.
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"damned": 0.4, "imp": 0.3, "hell_knight": 0.25, "succubus": 0.02, "fallen_angel": 0.02, "demon_brute": 0.01},
		"objective": "Cast down the Morning Star"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus the Act VI type
## "portal" (DemonPortals.start_event(): count / banner / distance_min /
## distance_max / table / pour_every) and the PandemoniumDirector's
## "seraph_general" (the miniboss `kind` lands with its `escort` groups)).
const EVENTS := [
	# Zone I: the Iron City.
	{"time": 20.0, "type": "wave", "banner": "The damned are dragged toward you in chains!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "damned", "count": 16, "elite": false}]},
	{"time": 90.0, "type": "portal", "count": 1, "banner": "A demon portal tears open! Stand in its ring to seal it!"},  # TUNING (not in GDD)
	{"time": 150.0, "type": "wave", "banner": "A swarm of imps over the iron streets!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "imp", "count": 12, "elite": false}]},
	{"time": 240.0, "type": "wave", "banner": "Hell knights march out of the Iron City!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "hell_knight", "count": 5, "elite": false}, {"kind": "damned", "count": 10, "elite": false}]},
	# Zone II (5:00): the Chain Bridges.
	{"time": 330.0, "type": "wave", "banner": "A Fallen Angel dives from the burning sky!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "fallen_angel", "count": 1, "elite": false}, {"kind": "imp", "count": 8, "elite": false}]},
	{"time": 400.0, "type": "portal", "count": 2, "banner": "Two portals open on the bridges!"},  # TUNING (not in GDD)
	{"time": 480.0, "type": "wave", "banner": "Succubi on the bridges! Kill them before they turn your dead!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "succubus", "count": 2, "elite": false}, {"kind": "hell_knight", "count": 4, "elite": false}, {"kind": "damned", "count": 10, "elite": false}]},
	{"time": 550.0, "type": "wave", "banner": "The fallen descend: a flight of angels!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "fallen_angel", "count": 3, "elite": false}, {"kind": "hell_knight", "count": 3, "elite": false}]},
	# Zone III (10:00): the Cathedral of Ash.
	{"time": 630.0, "type": "wave", "banner": "A demon brute shoulders through the cathedral doors!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "demon_brute", "count": 1, "elite": false}, {"kind": "imp", "count": 10, "elite": false}]},
	{"time": 700.0, "type": "seraph_general", "banner": "THE FALLEN SERAPH GENERAL descends on burning wings: step out of his cleave!", "kind": PandemoniumEnemyData.SERAPH_GENERAL,  # Owner-approved proposal: the miniboss
		"escort": [{"kind": "hell_knight", "count": 6, "elite": false}]},  # TUNING (not in GDD)
	{"time": 780.0, "type": "portal", "count": 2, "banner": "The portals multiply in the cathedral!"},  # TUNING (not in GDD)
	{"time": 840.0, "type": "wave", "banner": "Brutes and angels!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "demon_brute", "count": 2, "elite": false}, {"kind": "fallen_angel", "count": 2, "elite": false}, {"kind": "succubus", "count": 1, "elite": false}]},
	# Zone IV (15:00): the Throne.
	{"time": 930.0, "type": "portal", "count": 3, "banner": "Hell gapes open before the throne!"},  # TUNING (not in GDD)
	{"time": 990.0, "type": "wave", "banner": "The host of the Pit gathers before the throne!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "succubus", "count": 2, "elite": false}, {"kind": "hell_knight", "count": 5, "elite": false}, {"kind": "fallen_angel", "count": 2, "elite": false}, {"kind": "damned", "count": 14, "elite": false}]},
	# 17:00 the Morning Star (BOSS_TIME), plus two sallies.
	{"time": 1090.0, "type": "wave", "banner": "The throne's guard rallies to its lord!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "hell_knight", "count": 6, "elite": false}, {"kind": "fallen_angel", "count": 1, "elite": false}, {"kind": "imp", "count": 10, "elite": false}]},
	{"time": 1160.0, "type": "portal", "count": 2, "banner": "The Adversary tears the floor open!"},  # TUNING (not in GDD)
]

## Pandemonium's systems (PandemoniumDirector; StageRegistry "pandemonium").
##   guest_* / guests — the other Act VI stages' kinds in small squads (as
##            SunRoadStage.SUN_ROAD): candidate ids per kind (the first one this
##            build knows; none = skipped) and a weight. The ids were guessed
##            while the three Act VI stages were built in parallel (the Burning
##            Gate's hellhound and pit cultist, the Palace's lilim witch); check
##            them at the Act VI integration.
const PANDEMONIUM := {
	"guest_first": 300.0,  # TUNING (not in GDD) no guests before 5:00
	"guest_interval": 85.0,  # TUNING (not in GDD)
	"guest_until": 1000.0,  # TUNING (not in GDD) the boss fight keeps its own roster
	"guest_count": 3,  # TUNING (not in GDD)
	"guest_growth": 0.4,  # TUNING (not in GDD)
	"guest_max": 6,  # TUNING (not in GDD)
	"guests": [
		{"ids": ["hellhound", "hell_hound", "lava_hound"], "weight": 0.8},  # The Burning Gate (Act VI phase 2)
		{"ids": ["pit_cultist", "cultist"], "weight": 0.4},  # The Burning Gate (they open portals)
		{"ids": ["lilim_witch", "lilim"], "weight": 0.5},  # The Palace of Silk and Ash (Act VI phase 2)
	],
}

## Obstacle layout of the first zone (keys as GraveyardStage.ARENA; every zone
## has its own in ZONES).
const ARENA: Dictionary = ZONES[0]["arena"]

## The Morning Star's arrival (keys as GraveyardStage.BOSS): MorningStarData
## .ARRIVAL (boss id "morning_star", the ending line as the defeat banner),
## whose `time` equals BOSS_TIME (17:00). His script is
## scripts/enemies/inferno/boss_morning_star.gd (found by the boss id).
const BOSS: Dictionary = MorningStarData.ARRIVAL

## Floor look of the placeholder "inferno" ground (InfernoGround; the stage now
## uses PandemoniumGround and its ZONES, this stays for any caller of "floor").
const FLOOR := {
	"style": "obsidian",  # Obsidian paving, chain links, lava seams.
	"base": Color(0.10, 0.09, 0.12),  # TUNING (not in GDD) obsidian paving
	"line": Color(0.17, 0.15, 0.20),  # TUNING (not in GDD)
	"accent": Palette.INFERNO_OBSIDIAN,  # TUNING (not in GDD) chain links
	"trim": Palette.INFERNO_LAVA,  # TUNING (not in GDD) lava seams
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Pandemonium",
	"short_name": "Pandemonium",
	"chapter": "Chapter XVIII",
	"act": 6,  # Act VI, the Inferno.
	"playable": false,  # Phase 2 built; hidden from the stage select until the lead's integration and the owner's go.
	"description": "The capital of hell: an obsidian cathedral city of chains and lava rivers, and at its heart the throne of the Adversary himself.",
	"unlock": {"stage": "silk_palace", "boss_kills": 1},  # Owner-approved: each Act VI stage opens the next
	"unlock_text": "Slay Lilith in the Palace of Silk and Ash to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act VI stages.
	"consecration": {},  # A Covenant event: none in Act VI.
	"crypt_defender": {},  # None in Act VI.
	"arena": ARENA,
	"ground": "pandemonium",  # PandemoniumGround (the four zone floors).
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"pandemonium": PANDEMONIUM,  # PandemoniumDirector (the Fallen Seraph General, guests).
	"inferno": true,  # Act VI: the Hell Pits, the portals, Temptation (InfernoRules).
	"pits": PITS,  # Act VI: this stage's Hell Pits overrides.
	"portals": PORTALS,  # Act VI: this stage's portal overrides.
	"zones": ZONES,  # The four zones (MarchDirector reads them through "march"; the Hell Pits' fixed tables).
	# Music key "brimstone": the Act VI loop "Hymn of the Pit" (SoundData.BRIMSTONE_SCORE).
	"music": "brimstone",
}
