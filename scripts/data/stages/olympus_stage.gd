## OlympusStage — STAGE 11, MOUNT OLYMPUS, THE PANTHEON TRIAL (Act IV, the
## Olympian Republic; GDD §15.0 "Act IV foundation (phase 1)" and "Mount
## Olympus (Act IV phase 2)", owner-approved proposal docs/act4/PROPOSAL.md
## "Stage 11: Mount Olympus, the Pantheon Trial", the owner's boss rush). The
## stage climbs the mountain under Zeus's storm, and each zone has its god.
## Every number and event that belongs to this stage; StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry). Unlocked by slaying Achilles on the Shores
## of Ilion.
##
## THE CLOCK IS AUTHORITATIVE, as on every stage since the Crimson March: four
## zones on fixed times (ZONES, run by MarchDirector: a zone banner, a sweep of
## storm cloud, the obstacles and floor re-drawn as the next zone; the zone
## names are the foundation's, kept), one god each (OlympusDirector's "god"
## events, the owner-approved trial times):
##   20:00  Zone I,   the Field of Ares:        the mountain's war-trampled
##                                               foot; shield walls, centaurs
##   14:00            ARES, God of War arrives (a third of Zeus's HP, a chest)
##    9:30  Zone II,  the Groves of Artemis:    moonlit cypress groves;
##                                               ARTEMIS, the Huntress, at a grove
##    6:00  Zone III, the Terraces of Poseidon: wet marble terraces and
##                                               fountains; POSEIDON, Lord of the Sea
##    3:00  Zone IV,  the Summit:               storm-dark marble under the
##                                               thrones; ZEUS (BossZeus)
##    0:00  the Twilight of the Gods (the shared Act IV Reckoning)
## The Wrath of the Gods here is Zeus's lightning (DivineWrath, STAGE "wrath":
## bronze draws it, so the counterplay is luring the bronze under the storm).
## The trial's systems run in OlympusDirector (OLYMPUS): the gods, the HUD bar,
## Artemis's groves. Kinds: the shared Shades, Hoplites and Heroes, and the
## stage's own Centaur Archers, Amazons and Gorgons (OlympusEnemyData).
## A step harder than the Iron Citadel. Every rate, cap and weight is TUNING
## (not in GDD).
class_name OlympusStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "olympus"

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act IV starts a step above the Iron Citadel's 1.35 and climbs stage by stage).
const ENEMY_HP_MULT: float = 1.45  # TUNING (not in GDD) placeholder, tuned in the lead's balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.3  # TUNING (not in GDD) lead's integration pass: 1.4 -> 1.3 (the army bot died to the stacked lightning, beam and arrows of the Zeus fight on 1 of 3 seeds)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Act III: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 3.5  # TUNING (not in GDD) placeholder (Ilion x3.25)

## Wrath of the Gods on this stage (DivineWrath): Zeus's lightning. Any other
## key overrides PantheonRulesData.WRATH["lightning"] ({} = those defaults).
const WRATH := {
	"kind": "lightning",  # Owner-approved proposal: Zeus's lightning (Olympus)
	"dmg_player": 6.0,  # TUNING (not in GDD) lead's integration pass: 9 -> 6 on this stage only (a salvo every 6 s all run; the shared default stays for the Twilight)
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Twilight
## of the Gods, shared by every Act IV stage: Bronze Titans step out of the
## ground ("kind") while every wrath kind fires together, faster each minute
## ("twilight": PantheonRulesData.TWILIGHT keys; {} = those defaults).
const RECKONING := {
	"banner": "THE TWILIGHT OF THE GODS: THE SKY SPLITS",
	"kind": PantheonEnemyData.BRONZE_TITAN,  # The shared Twilight kind.
	"twilight": {},  # PantheonRulesData.TWILIGHT defaults.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) Titans are few and huge
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE TWILIGHT OF THE GODS: the heavens fall on you. Endure."

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments, sorted by start time (keys as
## GraveyardStage.SEGMENTS). Shades are the fodder, Hoplites the bulk and the
## shield walls, Centaur Archers the ranged share, Amazons and Gorgons the
## stage's elites, Heroes the rare Glory elites. The trickle thins while a god
## fights (the trial is the point).
const SEGMENTS := [
	# Zone I, the Field of Ares.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 1.0},
		"objective": "The Field of Ares: the dead flee up the mountain"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.78, "hoplite": 0.2, "centaur_archer": 0.02},
		"objective": "Hoplites lock shields: strike the walls from the flanks"},
	{"start": 150.0, "rate": 2.0, "max_alive": 46,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.66, "hoplite": 0.26, "centaur_archer": 0.08},
		"objective": "Centaurs gallop in shooting: kill them on approach"},
	{"start": 240.0, "rate": 2.4, "max_alive": 54,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.56, "hoplite": 0.3, "centaur_archer": 0.12, "amazon": 0.01},  # TUNING (not in GDD) smoke run: Gorgons x0.35, Amazons x0.5 (87 Gorgons petrified 1,072 summons)
		"objective": "Amazons leap over your front row: keep blockers by you"},
	{"start": 360.0, "rate": 2.2, "max_alive": 50,  # TUNING (not in GDD) thinner while Ares fights
		"weights": {"shade_of_dead": 0.56, "hoplite": 0.3, "centaur_archer": 0.11, "amazon": 0.01, "hero": 0.01},  # TUNING (not in GDD) smoke run: Gorgons x0.35, Amazons x0.5 (87 Gorgons petrified 1,072 summons)
		"objective": "Ares, God of War: put a blocker in his charge"},
	{"start": 480.0, "rate": 2.9, "max_alive": 70,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.5, "hoplite": 0.3, "centaur_archer": 0.14, "amazon": 0.015, "gorgon": 0.007, "hero": 0.01},  # TUNING (not in GDD) smoke run: Gorgons x0.35, Amazons x0.5 (87 Gorgons petrified 1,072 summons)
		"objective": "Gorgons turn your dead to stone: kill them first"},
	{"start": 570.0, "rate": 3.2, "max_alive": 78,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.48, "hoplite": 0.3, "centaur_archer": 0.15, "amazon": 0.015, "gorgon": 0.01, "hero": 0.01},  # TUNING (not in GDD) smoke run: Gorgons x0.35, Amazons x0.5 (87 Gorgons petrified 1,072 summons)
		"objective": "Moonlight glows in the groves above"},
	# Zone II (9:30 left), the Groves of Artemis.
	{"start": 630.0, "rate": 2.9, "max_alive": 72,  # TUNING (not in GDD) thinner while Artemis fights
		"weights": {"shade_of_dead": 0.48, "hoplite": 0.28, "centaur_archer": 0.16, "amazon": 0.02, "gorgon": 0.01, "hero": 0.01},  # TUNING (not in GDD) smoke run: Gorgons x0.35, Amazons x0.5 (87 Gorgons petrified 1,072 summons)
		"objective": "The Groves of Artemis: the Huntress strikes from the trees"},
	{"start": 720.0, "rate": 3.5, "max_alive": 86,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.46, "hoplite": 0.28, "centaur_archer": 0.17, "amazon": 0.02, "gorgon": 0.014, "hero": 0.01},  # TUNING (not in GDD) smoke run: Gorgons x0.35, Amazons x0.5 (87 Gorgons petrified 1,072 summons)
		"objective": "Lure the bronze under the storm: the lightning chains through it"},
	# Zone III (6:00 left), the Terraces of Poseidon.
	{"start": 840.0, "rate": 3.2, "max_alive": 82,  # TUNING (not in GDD) thinner while Poseidon fights
		"weights": {"shade_of_dead": 0.46, "hoplite": 0.28, "centaur_archer": 0.16, "amazon": 0.02, "gorgon": 0.014, "hero": 0.02},  # TUNING (not in GDD) smoke run: Gorgons x0.35, Amazons x0.5 (87 Gorgons petrified 1,072 summons)
		"objective": "The Terraces of Poseidon: the sea climbs the mountain"},
	{"start": 930.0, "rate": 3.9, "max_alive": 96,  # TUNING (not in GDD) the density peak
		"weights": {"shade_of_dead": 0.44, "hoplite": 0.29, "centaur_archer": 0.16, "amazon": 0.025, "gorgon": 0.014, "hero": 0.02},  # TUNING (not in GDD) smoke run: Gorgons x0.35, Amazons x0.5 (87 Gorgons petrified 1,072 summons)
		"objective": "The summit is close: the storm thickens"},
	# Zone IV (3:00 left), the Summit: Zeus. A thinner trickle so the fight stays readable.
	{"start": BOSS_TIME, "rate": 2.6, "max_alive": 70,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.5, "hoplite": 0.28, "centaur_archer": 0.14, "amazon": 0.02, "gorgon": 0.01, "hero": 0.01},  # TUNING (not in GDD) smoke run: Gorgons x0.35, Amazons x0.5 (87 Gorgons petrified 1,072 summons)
		"objective": "Topple Zeus from his summit"},
	{"start": 1110.0, "rate": 3.2, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.48, "hoplite": 0.29, "centaur_archer": 0.15, "amazon": 0.02, "gorgon": 0.01, "hero": 0.01},  # TUNING (not in GDD) smoke run: Gorgons x0.35, Amazons x0.5 (87 Gorgons petrified 1,072 summons)
		"objective": "Topple Zeus from his summit"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave": formation + groups; "line" rows lock as they arrive), plus Mount
## Olympus's own (OlympusDirector):
##   "god" — the god `kind` of the Pantheon Trial arrives (OlympusEnemyData
##           .GODS), on the spawn ring, or at one of Artemis's moonlit groves
##           when `groves` is true (laid then).
const EVENTS := [
	# Zone I: the Field of Ares.
	{"time": 20.0, "type": "wave", "banner": "The dead flee up the mountain!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "shade_of_dead", "count": 12, "elite": false}]},
	{"time": 100.0, "type": "wave", "banner": "A shield wall advances: strike its flanks!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "hoplite", "count": 6, "elite": false}]},
	{"time": 160.0, "type": "wave", "banner": "CENTAUR ARCHERS gallop down the slope, shooting!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "centaur_archer", "count": 4, "elite": false}, {"kind": "shade_of_dead", "count": 8, "elite": false}]},
	{"time": 220.0, "type": "wave", "banner": "A Hero takes the field: kill it before it wins Glory!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 1, "elite": false}, {"kind": "hoplite", "count": 6, "elite": false}]},
	{"time": 290.0, "type": "wave", "banner": "AMAZONS charge: they leap over your front row!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "amazon", "count": 2, "elite": false}, {"kind": "hoplite", "count": 8, "elite": false}, {"kind": "shade_of_dead", "count": 10, "elite": false}]},
	{"time": 360.0, "type": "god", "kind": "ares", "banner": "ARES, GOD OF WAR, takes the field!"},  # Owner-approved proposal: Ares at 14:00 left
	{"time": 420.0, "type": "wave", "banner": "Ares's host closes in!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "hoplite", "count": 12, "elite": false}, {"kind": "centaur_archer", "count": 3, "elite": false}]},
	{"time": 500.0, "type": "wave", "banner": "GORGONS slither in: their gaze turns your dead to stone!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "gorgon", "count": 2, "elite": false}, {"kind": "shade_of_dead", "count": 14, "elite": false}]},
	{"time": 580.0, "type": "wave", "banner": "Heroes lead the host!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 2, "elite": false}, {"kind": "hoplite", "count": 10, "elite": false}, {"kind": "centaur_archer", "count": 4, "elite": false}]},
	# Zone II (9:30 left): the Groves of Artemis.
	{"time": 630.0, "type": "god", "kind": "artemis", "groves": true, "banner": "ARTEMIS, THE HUNTRESS, steps out of the groves!"},  # Owner-approved proposal: Artemis at 9:30 left
	{"time": 700.0, "type": "wave", "banner": "The phalanx marches through the groves!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "hoplite", "count": 18, "elite": false}]},
	{"time": 770.0, "type": "wave", "banner": "Amazons and Gorgons hunt with the goddess!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "amazon", "count": 3, "elite": false}, {"kind": "gorgon", "count": 2, "elite": false}, {"kind": "shade_of_dead", "count": 16, "elite": false}]},
	# Zone III (6:00 left): the Terraces of Poseidon.
	{"time": 840.0, "type": "god", "kind": "poseidon", "banner": "POSEIDON, LORD OF THE SEA, rises from the terraces!"},  # Owner-approved proposal: Poseidon at 6:00 left
	{"time": 900.0, "type": "wave", "banner": "Centaurs thunder down the terraces!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "centaur_archer", "count": 8, "elite": false}, {"kind": "hoplite", "count": 10, "elite": false}]},
	{"time": 960.0, "type": "wave", "banner": "The last host of Olympus!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 3, "elite": false}, {"kind": "hoplite", "count": 16, "elite": false}, {"kind": "amazon", "count": 2, "elite": false}, {"kind": "gorgon", "count": 2, "elite": false}]},
	# 17:00 Zeus (BOSS_TIME), plus two sallies.
	{"time": 1080.0, "type": "wave", "banner": "Zeus's honour guard locks shields!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "hoplite", "count": 14, "elite": false}, {"kind": "centaur_archer", "count": 4, "elite": false}]},
	{"time": 1140.0, "type": "wave", "banner": "Olympus throws its last champions at you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "amazon", "count": 2, "elite": false}, {"kind": "gorgon", "count": 2, "elite": false}, {"kind": "shade_of_dead", "count": 16, "elite": false}]},
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES.
## `ground` is an OlympusGround look:
##   style  — "field" (the Field of Ares: trampled mountain earth and scorched
##            grass), "grove" (the Groves of Artemis: moonlit moss and fallen
##            cypress needles), "terrace" (the Terraces of Poseidon: wet marble
##            flagstones with water runnels) or "summit" (the Summit: storm-
##            dark marble with gold inlay).
##   base / line / accent / trim — colours of the code floor, its joints, its
##            stones and its glints.
## Obstacle kinds (OlympusGlyphs without art; obstacles/<kind>_<size>[_v]):
##   war_trophy     — a trophy of captured shields and spears on a post (circle)
##   chariot_wreck  — a broken bronze war chariot on its side (rect)
##   cypress        — a dark cypress tree (circle)
##   moon_shrine    — a small marble shrine with a silver crescent (circle)
##   fountain       — a marble fountain basin with water (circle)
##   balustrade     — a marble balustrade of the terraces (rect)
##   broken_column / marble_block / bronze_brazier — the summit's broken marble
##                    and bronze braziers (circle / rect / circle; the
##                    foundation stub's kinds, PantheonGlyphs without art)
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Field of Ares",  # Foundation's name, kept (owner-approved: Ares at 14:00 left)
		"blurb": "The war-trampled foot of the mountain",
		"ground": {"style": "field", "base": Color(0.17, 0.13, 0.10), "line": Color(0.11, 0.08, 0.06),
			"accent": Color(0.42, 0.27, 0.14), "trim": Color(0.878, 0.663, 0.333)},
		"arena": {"density": 0.13, "clear_radius": 220.0, "layout_seed": 1123,  # TUNING (not in GDD) open ground
			"kinds": {
				"war_trophy": {"weight": 0.6, "shape": "circle", "sizes": [11.0, 14.0, 17.0]},  # TUNING (not in GDD)
				"chariot_wreck": {"weight": 0.4, "shape": "rect", "sizes": [44.0, 60.0], "short": 24.0},  # TUNING (not in GDD)
			}}},
	{"start": 630.0, "numeral": "II", "name": "The Groves of Artemis",  # Foundation's name, kept (owner-approved: Artemis at 9:30 left)
		"blurb": "Moonlit cypress groves on the mountainside",
		"ground": {"style": "grove", "base": Color(0.09, 0.12, 0.11), "line": Color(0.06, 0.08, 0.07),
			"accent": Color(0.20, 0.27, 0.22), "trim": Color(0.957, 0.945, 0.918)},
		"arena": {"density": 0.24, "clear_radius": 230.0, "layout_seed": 1134,  # TUNING (not in GDD) dense trees: lanes between them
			"kinds": {
				"cypress": {"weight": 0.75, "shape": "circle", "sizes": [12.0, 15.0, 18.0]},  # TUNING (not in GDD)
				"moon_shrine": {"weight": 0.25, "shape": "circle", "sizes": [13.0, 16.0]},  # TUNING (not in GDD)
			}}},
	{"start": 840.0, "numeral": "III", "name": "The Terraces of Poseidon",  # Foundation's name, kept (owner-approved: Poseidon at 6:00 left)
		"blurb": "Wet marble terraces where the sea climbs the mountain",
		"ground": {"style": "terrace", "base": Color(0.15, 0.17, 0.19), "line": Color(0.10, 0.12, 0.14),
			"accent": Color(0.557, 0.541, 0.525), "trim": Color(0.435, 0.714, 0.910)},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 1145,  # TUNING (not in GDD)
			"kinds": {
				"fountain": {"weight": 0.45, "shape": "circle", "sizes": [15.0, 19.0]},  # TUNING (not in GDD)
				"balustrade": {"weight": 0.55, "shape": "rect", "sizes": [52.0, 70.0, 86.0], "short": 18.0},  # TUNING (not in GDD)
			}}},
	{"start": 1020.0, "numeral": "IV", "name": "The Summit",  # Foundation's name, kept (owner-approved: Zeus at 3:00 left)
		"blurb": "The storm-dark marble under the thrones of the gods",
		"ground": {"style": "summit", "base": Color(0.16, 0.16, 0.17), "line": Color(0.24, 0.24, 0.25),
			"accent": Color(0.557, 0.541, 0.525), "trim": Color(1.0, 0.82, 0.3)},
		"arena": {"density": 0.14, "clear_radius": 240.0, "layout_seed": 1156,  # TUNING (not in GDD) room for the boss fight
			"kinds": {
				"broken_column": {"weight": 0.5, "shape": "circle", "sizes": [11.0, 14.0, 18.0]},  # TUNING (not in GDD)
				"marble_block": {"weight": 0.3, "shape": "rect", "sizes": [40.0, 56.0, 72.0], "short": 26.0},  # TUNING (not in GDD)
				"bronze_brazier": {"weight": 0.2, "shape": "circle", "sizes": [9.0, 11.0]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "THE CLIMB  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(1.0, 0.82, 0.3),  # Gold: the gods' light (Palette.GOLD), never the UI's soul-teal.
	"fog_color": Color(0.08, 0.10, 0.16),  # Storm cloud.
	"fog_bank_color": Color(0.30, 0.34, 0.44),  # Grey-blue cloud banks.
	"zones": ZONES,
}

## Mount Olympus's stage systems (OlympusDirector; StageRegistry "olympus").
##   grove_count — moonlit groves laid at Artemis's arrival (her teleports).
##   grove_min / grove_max — px from the necromancer the groves are laid
##                 (alternating near and far).
##   grove_reach — px: a grove farther than this from the necromancer is
##                 not used; when none is within it, the groves are laid again
##                 around him.
##   objectives  — HUD objective while each god lives (the newest living one).
const OLYMPUS := {
	"grove_count": 4,  # TUNING (not in GDD)
	"grove_min": 250.0,  # TUNING (not in GDD) px
	"grove_max": 340.0,  # TUNING (not in GDD) px
	"grove_reach": 520.0,  # TUNING (not in GDD) px
	"objectives": {
		"ares": "Ares, God of War: put a blocker in his charge, and the war-cry passes",  # TUNING (not in GDD)
		"artemis": "Artemis, the Huntress: she vanishes into the groves; corner her",  # TUNING (not in GDD)
		"poseidon": "Poseidon, Lord of the Sea: ride out his flood, dodge the trident",  # TUNING (not in GDD)
	},
}

## Zeus's arrival (keys as GraveyardStage.BOSS): his own ZeusData.ARRIVAL (boss
## id "zeus"), whose `time` equals BOSS_TIME (17:00). His script is
## scripts/enemies/pantheon/boss_zeus.gd (loaded by his id).
const BOSS: Dictionary = ZeusData.ARRIVAL

## Placeholder floor of the foundation stub (PantheonGround "floor" key), kept
## for the other tools that read it; the stage draws OlympusGround ("ground").
const FLOOR := {
	"style": "marble",  # Marble flagstones with gold inlay, storm-dark.
	"base": Color(0.16, 0.16, 0.17),  # TUNING (not in GDD) storm-shadowed marble
	"line": Color(0.24, 0.24, 0.25),  # TUNING (not in GDD) flagstone joints
	"accent": Color(0.557, 0.541, 0.525),  # TUNING (not in GDD) marble_dark slabs
	"trim": Color(0.878, 0.663, 0.333),  # TUNING (not in GDD) bronze_light inlay
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Mount Olympus",
	"short_name": "Olympus",
	"chapter": "Chapter XI",
	"act": 4,  # Act IV, the Olympian Republic.
	"playable": false,  # Hidden from the stage select until the lead's Act IV pass and the owner's playtest.
	"description": "The Pantheon Trial: climb the mountain under Zeus's storm while Ares, Artemis and Poseidon come down one by one, and Zeus waits at the summit.",
	"unlock": {"stage": "ilion", "boss_kills": 1},  # Owner-approved: each boss unlocks the next stage
	"unlock_text": "Slay Achilles on the Shores of Ilion to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act IV stages.
	"consecration": {},  # A Covenant event: none in Act IV.
	"crypt_defender": {},  # None in Act IV.
	"arena": ZONES[0]["arena"],
	"ground": "olympus",  # OlympusGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"olympus": OLYMPUS,  # OlympusDirector: the Pantheon Trial's gods, Artemis's groves.
	"pantheon": true,  # Act IV: Wrath of the Gods, Phalanx, Glory (PantheonRules).
	"wrath": WRATH,  # Act IV: this stage's wrath kind (DivineWrath).
	"zones": ZONES,  # The zones (also MARCH's), kept for the tools that read the stub's key.
	"music": "bronze",  # "Hymn of Bronze" (SoundData.BRONZE_SCORE), which also loads the Pantheon sound pack
}
