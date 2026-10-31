## BurningGateStage — STAGE 16, THE BURNING GATE (Act VI, the Inferno; GDD §15.0
## "Act VI foundation (phase 1)" and "The Burning Gate (Act VI phase 2)";
## owner-approved proposal docs/act6/PROPOSAL.md "Stage 16: The Burning Gate").
## A plain of ash and obsidian before the gate of hell, the river of fire
## Phlegethon along its edge. Every number and event that belongs to this
## stage; StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
## Unlocked by putting out the sun on the Road to the Sun.
##
## THE CLOCK IS AUTHORITATIVE, as on every stage since the Crimson March: four
## zones on fixed times (ZONES, run by MarchDirector: a zone banner, a sweep of
## ash, the obstacles and floor re-drawn as the next zone; the Hell Pits draw a
## new table of fixed pits for each zone, STAGE "zones" = ZONES):
##   20:00  Zone I,   the Ash Plain:     grey ash and obsidian shards; the
##                                       damned, imps, the first hell knights
##   15:00  Zone II,  the Cages:         hanging iron cages of the damned;
##                                       Hellhound packs, Pit Cultists, succubi
##   10:00  Zone III, the River of Fire: Phlegethon's banks; the river runs
##                                       across the world in burning bands
##                                       with fords (HellPits' "band"); the
##                                       Gatekeeper at 9:00
##    5:00  Zone IV,  the Gate:          the black gate of hell, its pillars and
##                                       chains; the brutes, the most pits
##    3:00  Moloch, the Furnace King (BossMoloch, MolochData)
##    0:00  the Last Judgment (the shared Act VI Reckoning)
## The Hell Pits, the portals and Temptation are the shared Inferno rules
## ("inferno": true; "pits": this stage's overrides and the River of Fire;
## "portals": the defaults plus the Gate's own squad table). The stage systems
## run in BurningGateDirector (BURNING_GATE): THE GATEKEEPER (the miniboss) and
## GATE CRASHED (the achievement). Every rate, cap and weight is TUNING (not in
## GDD).
class_name BurningGateStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "burning_gate"

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
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 1 of Act VI

## The Hell Pits on this stage (any InfernoRulesData.PITS key overrides it):
## fewer loose fixed pits on the River of Fire (the river is the zone's fire),
## the most at the Gate; room for the Hellhounds' trails and Moloch's cracks;
## and THE RIVER OF FIRE ("band", HellPits._add_band(): in zone III, the
## River of Fire, burning bands east-west every `spacing` px with fords).
const PITS := {
	"fixed_chance": [0.28, 0.36, 0.16, 0.48],  # TUNING (not in GDD) per zone (Ash Plain, Cages, River, Gate)
	"max_pits": 40,  # TUNING (not in GDD) room for hound trails and Moloch's cracks (default 24)
	"band": {
		"zones": [2],  # Owner-approved proposal: zone III, "the River of Fire"
		"spacing": 1500.0,  # TUNING (not in GDD) px between two bands north-south (first pass 1150: the army lost most of its summons to the river)
		"amp": 90.0,  # TUNING (not in GDD) px of the meander
		"wavelength": 900.0,  # TUNING (not in GDD) px of one meander
		"radius": 34.0,  # TUNING (not in GDD) px of each burning circle (the band ~68 px wide)
		"step": 44.0,  # TUNING (not in GDD) px between two circles along the band
		"ford_every": 440,  # TUNING (not in GDD) px between two fords (first pass 520)
		"ford_width": 200,  # TUNING (not in GDD) px of a ford (the ring passes; first pass 140)
	},
}

## The demon portals on this stage: the defaults of InfernoRulesData.PORTALS,
## with the Gate's own squads (the stage's Hellhound packs join the pour).
const PORTALS := {
	"table": [
		{"kind": "imp", "count": 3, "weight": 1.0},  # TUNING (not in GDD)
		{"kind": "damned", "count": 4, "weight": 1.0},  # TUNING (not in GDD)
		{"kind": "hell_knight", "count": 1, "weight": 0.35},  # TUNING (not in GDD)
		{"kind": "lava_hound", "count": 3, "weight": 0.5},  # TUNING (not in GDD) a pack out of the gate
	],
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Last
## Judgment, shared by every Act VI stage: every portal opens at once, the pits
## open faster each minute and the Adversary's hand reaches up through the
## floor ("last_judgment": InfernoRulesData.LAST_JUDGMENT keys; {} = those
## defaults); demon brutes ("kind") step out with imps, the damned and this
## gate's Hellhounds.
const RECKONING := {
	"banner": "THE LAST JUDGMENT: THE PIT OPENS",
	"kind": InfernoEnemyData.DEMON_BRUTE,  # The shared Last Judgment heavy.
	"last_judgment": {},  # InfernoRulesData.LAST_JUDGMENT defaults.
	"companions": [{"kind": InfernoEnemyData.IMP, "count": 6, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": InfernoEnemyData.DAMNED, "count": 4, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": BurningGateEnemyData.LAVA_HOUND, "count": 3, "growth": 1.0}],  # TUNING (not in GDD) the gate's hounds
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

## Continuous spawning segments, sorted by start time (keys as
## GraveyardStage.SEGMENTS). The damned are the fodder (they burn in the pits:
## lead them through), imps the flying fodder, hell knights the soldiers,
## Hellhounds (lava_hound) the packs from the Cages on, Pit Cultists the rare
## priority targets (each opens a portal if he finishes his rite), succubi the
## rare charmers, demon brutes the heavies from the River.
const SEGMENTS := [
	# Zone I, the Ash Plain.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"damned": 1.0},
		"objective": "The Ash Plain: the damned shuffle toward you. Lead them through the pits"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"damned": 0.7, "imp": 0.3},
		"objective": "Imps fly over the pits: they never burn"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"damned": 0.55, "imp": 0.25, "hell_knight": 0.2},
		"objective": "Hell knights in ember armour: step out of the burning blade"},
	# Zone II, the Cages: the hounds and the cultists.
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"damned": 0.44, "imp": 0.2, "hell_knight": 0.22, "lava_hound": 0.12, "succubus": 0.015, "pit_cultist": 0.008},
		"objective": "The Cages: Hellhounds run in packs. Their trail burns"},
	{"start": 420.0, "rate": 2.5, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"damned": 0.42, "imp": 0.2, "hell_knight": 0.24, "lava_hound": 0.12, "succubus": 0.02, "pit_cultist": 0.01},
		"objective": "Kill the Pit Cultists before their rite opens a portal"},
	# Zone III, the River of Fire: the Gatekeeper at 9:00; the brutes join.
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"damned": 0.4, "imp": 0.2, "hell_knight": 0.26, "lava_hound": 0.12, "succubus": 0.02, "pit_cultist": 0.01, "demon_brute": 0.01},
		"objective": "The River of Fire: cross at the fords. Seal the portals"},
	{"start": 780.0, "rate": 2.85, "max_alive": 78,  # TUNING (not in GDD)
		"weights": {"damned": 0.38, "imp": 0.2, "hell_knight": 0.27, "lava_hound": 0.13, "succubus": 0.02, "pit_cultist": 0.01, "demon_brute": 0.012},
		"objective": "Phlegethon burns along the bank: keep your dead out of it"},
	# Zone IV, the Gate: the density peak of the run.
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"damned": 0.36, "imp": 0.2, "hell_knight": 0.28, "lava_hound": 0.14, "succubus": 0.025, "pit_cultist": 0.012, "demon_brute": 0.015},
		"objective": "The Gate: hell pours out to meet you"},
	# 17:00, the boss: thinner, so the fight is the furnace.
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"damned": 0.42, "imp": 0.26, "hell_knight": 0.22, "lava_hound": 0.08, "succubus": 0.02},
		"objective": "Moloch has come for you: stay out of his furnace's reach"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave": formation + groups), the Act VI type "portal" (`count` demon
## portals around the necromancer, DemonPortals.start_event()), plus the
## Burning Gate's own (BurningGateDirector):
##   "gatekeeper" — the Gatekeeper (kind `kind`) walks in on the spawn ring
##                  (the stage miniboss).
const EVENTS := [
	# Zone I: the Ash Plain.
	{"time": 20.0, "type": "wave", "banner": "The damned are dragged toward you in chains!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "damned", "count": 16, "elite": false}]},
	{"time": 90.0, "type": "portal", "count": 1, "banner": "A demon portal tears open! Stand in its ring to seal it!"},  # TUNING (not in GDD)
	{"time": 150.0, "type": "wave", "banner": "A swarm of imps!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "imp", "count": 12, "elite": false}]},
	{"time": 240.0, "type": "wave", "banner": "Hell knights advance in burning armour!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "hell_knight", "count": 4, "elite": false}, {"kind": "damned", "count": 10, "elite": false}]},
	# Zone II (5:00): the Cages.
	{"time": 310.0, "type": "wave", "banner": "HELLHOUNDS! The pack leaves a trail of fire!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "lava_hound", "count": 7, "elite": false}]},
	{"time": 360.0, "type": "wave", "banner": "PIT CULTISTS chant among the cages: kill them before the rite is done!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "pit_cultist", "count": 2, "elite": false}, {"kind": "damned", "count": 10, "elite": false}]},
	{"time": 420.0, "type": "portal", "count": 2, "banner": "Two portals open!"},  # TUNING (not in GDD)
	{"time": 480.0, "type": "wave", "banner": "A succubus! Kill her before she turns your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "succubus", "count": 1, "elite": false}, {"kind": "imp", "count": 8, "elite": false}, {"kind": "lava_hound", "count": 4, "elite": false}]},
	{"time": 550.0, "type": "wave", "banner": "The cultists and their hounds!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "pit_cultist", "count": 3, "elite": false}, {"kind": "lava_hound", "count": 6, "elite": false}, {"kind": "hell_knight", "count": 3, "elite": false}]},
	# Zone III (10:00): the River of Fire; the Gatekeeper at 9:00.
	{"time": 630.0, "type": "wave", "banner": "A demon brute wades out of Phlegethon!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "demon_brute", "count": 1, "elite": false}, {"kind": "imp", "count": 10, "elite": false}]},
	{"time": 660.0, "type": "gatekeeper", "banner": "THE GATEKEEPER drags his chains across the river: stay out of their reach!",  # Owner-approved proposal (miniboss); 9:00 left like the General of the Left
		"kind": "gatekeeper", "elite": false},
	{"time": 720.0, "type": "portal", "count": 2, "banner": "The portals multiply!"},  # TUNING (not in GDD)
	{"time": 800.0, "type": "wave", "banner": "The succubi descend!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "succubus", "count": 2, "elite": false}, {"kind": "hell_knight", "count": 3, "elite": false}, {"kind": "damned", "count": 10, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "Brutes and knights!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "demon_brute", "count": 2, "elite": false}, {"kind": "hell_knight", "count": 4, "elite": false}, {"kind": "pit_cultist", "count": 2, "elite": false}]},
	# Zone IV (15:00): the Gate.
	{"time": 930.0, "type": "portal", "count": 3, "banner": "Hell gapes open around you!"},  # TUNING (not in GDD)
	{"time": 960.0, "type": "wave", "banner": "The hounds of the gate are loosed!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "lava_hound", "count": 10, "elite": false}, {"kind": "pit_cultist", "count": 2, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The host of the Pit gathers!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "succubus", "count": 2, "elite": false}, {"kind": "hell_knight", "count": 5, "elite": false}, {"kind": "damned", "count": 14, "elite": false}]},
	# 17:00 Moloch (BOSS_TIME).
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES
## (MarchDirector; HellPits reads only "start"). `ground` is a
## BurningGateGround look:
##   style  — "ash_plain" (grey ash, obsidian shards), "cages" (cinder-black
##            earth under the cages), "river" (Phlegethon's scorched bank) or
##            "gate" (the black flagstones before the gate).
##   base / line / accent / trim — colours of the code floor, its cracks, its
##            shards and its embers.
## Obstacle kinds (BurningGateGlyphs without art; obstacles/<kind>_<size>[_v]):
##   ember_rock   — an obsidian boulder veined with glowing lava (circle)
##   damned_cage  — an iron cage of the damned on a bone-and-chain frame (rect)
##   gate_pillar  — a black pillar of the gate, chains and a horned skull (rect)
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Ash Plain",  # Owner-approved proposal (zones)
		"blurb": "Grey ash and obsidian before the gate of hell",
		"ground": {"style": "ash_plain", "base": Color(0.16, 0.15, 0.16), "line": Color(0.10, 0.09, 0.10),
			"accent": Palette.INFERNO_OBSIDIAN, "trim": Palette.INFERNO_LAVA_DARK},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 1616,  # TUNING (not in GDD) also salts the fixed Hell Pits
			"kinds": {
				"ember_rock": {"weight": 0.65, "shape": "circle", "sizes": [12.0, 16.0, 22.0]},  # TUNING (not in GDD)
				"damned_cage": {"weight": 0.35, "shape": "rect", "sizes": [44.0, 56.0], "short": 24.0},  # TUNING (not in GDD)
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Cages",  # Owner-approved proposal (zones)
		"blurb": "Iron cages of the damned hang over the cinders",
		"ground": {"style": "cages", "base": Color(0.13, 0.11, 0.11), "line": Color(0.08, 0.06, 0.06),
			"accent": Color(0.30, 0.28, 0.30), "trim": Palette.INFERNO_LAVA_DARK},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 1626,  # TUNING (not in GDD) lanes between the cages
			"kinds": {
				"damned_cage": {"weight": 0.6, "shape": "rect", "sizes": [44.0, 56.0], "short": 24.0},  # TUNING (not in GDD)
				"ember_rock": {"weight": 0.4, "shape": "circle", "sizes": [12.0, 16.0, 22.0]},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The River of Fire",  # Owner-approved proposal (zones)
		"blurb": "Phlegethon burns along the scorched bank",
		"ground": {"style": "river", "base": Color(0.15, 0.10, 0.09), "line": Color(0.09, 0.05, 0.04),
			"accent": Palette.INFERNO_OBSIDIAN_DARK, "trim": Palette.INFERNO_LAVA},
		"arena": {"density": 0.12, "clear_radius": 220.0, "layout_seed": 1636,  # TUNING (not in GDD) open banks: the river is the obstacle
			"kinds": {
				"ember_rock": {"weight": 0.75, "shape": "circle", "sizes": [12.0, 16.0, 22.0]},  # TUNING (not in GDD)
				"damned_cage": {"weight": 0.25, "shape": "rect", "sizes": [44.0, 56.0], "short": 24.0},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Gate",  # Owner-approved proposal (zones)
		"blurb": "Black flagstones before the gate of hell",
		"ground": {"style": "gate", "base": Color(0.11, 0.10, 0.13), "line": Color(0.06, 0.05, 0.08),
			"accent": Palette.INFERNO_OBSIDIAN_LIGHT, "trim": Palette.INFERNO_LAVA},
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 1646,  # TUNING (not in GDD)
			"kinds": {
				"gate_pillar": {"weight": 0.45, "shape": "rect", "sizes": [56.0, 72.0], "short": 24.0},  # TUNING (not in GDD)
				"ember_rock": {"weight": 0.35, "shape": "circle", "sizes": [12.0, 16.0, 22.0]},  # TUNING (not in GDD)
				"damned_cage": {"weight": 0.2, "shape": "rect", "sizes": [44.0, 56.0], "short": 24.0},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "THE BURNING GATE  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(1.0, 0.702, 0.278),  # Lava light (Palette.INFERNO_LAVA_LIGHT), never the UI's soul-teal.
	"fog_color": Color(0.09, 0.07, 0.07),  # Drifting ash.
	"fog_bank_color": Color(0.32, 0.28, 0.27),  # Ash banks.
	"zones": ZONES,
}

## The Burning Gate's stage systems (BurningGateDirector; StageRegistry
## "burning_gate").
##   gatekeeper_objective — HUD objective while the Gatekeeper stands.
##   gate_crashed_seals   — portals sealed in the run by the time Moloch
##                          falls for Gate Crashed (own decision on the rule:
##                          the brief's "e.g. beat Moloch having sealed N
##                          portals").
##   gate_crashed_banner  — banner when it is earned.
const BURNING_GATE := {
	"gatekeeper_objective": "Bring down the Gatekeeper: stay out of his chains, starve him of the damned",  # TUNING (not in GDD)
	"gate_crashed_seals": 5,  # TUNING (not in GDD) the foundation's army bot sealed 5 in a run
	"gate_crashed_banner": "GATE CRASHED: the portals are sealed and the Furnace King is dead!",  # TUNING (not in GDD)
}

## Moloch's arrival (keys as GraveyardStage.BOSS): his own MolochData.ARRIVAL
## (boss id "moloch"), whose `time` equals BOSS_TIME (17:00). His script is
## scripts/enemies/inferno/boss_moloch.gd (loaded by his id).
const BOSS: Dictionary = MolochData.ARRIVAL

## Placeholder floor of the foundation stub (InfernoGround "floor" key), kept
## for the other tools that read it; the stage draws BurningGateGround ("ground").
const FLOOR := {
	"style": "ash",  # Grey ash, obsidian shards, ember cracks.
	"base": Color(0.17, 0.16, 0.17),  # TUNING (not in GDD) grey ash
	"line": Color(0.22, 0.20, 0.22),  # TUNING (not in GDD)
	"accent": Palette.INFERNO_OBSIDIAN,  # TUNING (not in GDD) obsidian shards
	"trim": Palette.INFERNO_LAVA,  # TUNING (not in GDD) ember cracks
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Burning Gate",
	"short_name": "The Gate",
	"chapter": "Chapter XVI",
	"act": 6,  # Act VI, the Inferno.
	"playable": false,  # Phase 2 built; hidden until the lead's integration and the owner's review (brief: keep "playable": false).
	"description": "A plain of ash and obsidian before the gate of hell, the river of fire Phlegethon burning along its edge: here the Pit's collectors come for the souls you raised.",
	"unlock": {"stage": "sun_road", "boss_kills": 1},  # Owner-approved: Amaterasu's fall opens Act VI
	"unlock_text": "Put out the sun on the Road to the Sun to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act VI stages.
	"consecration": {},  # A Covenant event: none in Act VI.
	"crypt_defender": {},  # None in Act VI.
	"arena": ZONES[0]["arena"],
	"ground": "burning_gate",  # BurningGateGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"burning_gate": BURNING_GATE,  # BurningGateDirector: the Gatekeeper, Gate Crashed.
	"inferno": true,  # Act VI: the Hell Pits, the portals, Temptation (InfernoRules).
	"pits": PITS,  # Act VI: this stage's Hell Pits overrides and the River of Fire.
	"portals": PORTALS,  # Act VI: this stage's portal squads.
	"zones": ZONES,  # Act VI: the zone starts the fixed pits change with (HellPits).
	# Music key "brimstone": the Act VI loop "Hymn of the Pit" (SoundData.BRIMSTONE_SCORE).
	"music": "brimstone",
}
