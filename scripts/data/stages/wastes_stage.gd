## WastesStage — STAGE 7, THE SCRAP WASTES (Act III, the Electronic Empire;
## GDD §15.0 "Act III foundation (phase 1)" and "The Scrap Wastes (Act III
## phase 2)", owner-approved proposal "Necropathy: Act III Proposal (The
## Electronic Empire)", "Stage 7: The Scrap Wastes"). The Empire's old
## battlefield: slag hills, rusting war machines the size of buildings, and red
## signal masts on the ridges. Every number and event that belongs to this
## stage; StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
## Unlocked by slaying Vhal'Neth once (the first stage of Act III).
##
## THE CLOCK IS AUTHORITATIVE, as on every stage since the Crimson March: four
## zones on fixed times (ZONES, run by MarchDirector: a zone banner, a sweep of
## grit, the obstacles and floor re-drawn as the next zone):
##   20:00  Zone I,   the Slag Fields:  open ground of cooled slag; drones, the
##                                       first Aegis Bots and Line Troopers
##   15:00  Zone II,  the Wreck Gullies: narrow paths between fallen titans
##                                       (good ground for blockers); Mortar Walkers
##   10:00  Zone III, Pylon Ridge:       ash rock under the signal masts; three
##                                       Signal Pylons; the Trojan Horse at 9:00
##    5:00  Zone IV,  the Outer Wall:    the Empire's broken frontier wall
##    3:00  Kestrel, the Dead Pixel (BossKestrel)
##    0:00  the Purge Protocol (the shared Act III Reckoning: kill-drones and
##          orbital strikes)
## The stage systems run in WastesDirector (WASTES): SIGNAL PYLONS (structures
## with a Soul Ash bounty that lengthen the Empire's guns near them, and shorten
## them there for the rest of the run once destroyed) and SCRAP STORMS (every
## few minutes, 20 s of dust that halves the Empire's sight: a window to close
## in). About 60% of the Empire's soldiers here attack from range (the drones,
## Line Troopers, Spotters and Mortar Walkers); the Aegis Bots are the melee
## screen in front of them (owner-approved: "with your melee kinds the act
## reaches about 60% ranged"). A step harder than Ul-Thalos. Every rate, cap
## and weight is TUNING (not in GDD).
class_name WastesStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "wastes"

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act III starts a step above Act II's last stage, Ul-Thalos 1.2).
const ENEMY_HP_MULT: float = 1.25  # TUNING (not in GDD) placeholder, tuned in the lead's balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.2  # TUNING (not in GDD) placeholder, tuned in the lead's balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them): Zone II, as on the Archive and Ul-Thalos.
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) (the Archive and Ul-Thalos: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 2.5  # TUNING (not in GDD) placeholder (Ul-Thalos x2.25)

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Purge
## Protocol, shared by every Act III stage: kill-drones pour in from every edge
## ("kind") while orbital strikes rain on telegraphed circles, faster each
## minute ("orbital": EmpireRulesData.PURGE keys; {} = those defaults).
const RECKONING := {
	"banner": "PURGE PROTOCOL: ORBITAL STRIKES INBOUND",
	"kind": EmpireEnemyData.KILL_DRONE,  # The shared Purge Protocol kind.
	"orbital": {},  # EmpireRulesData.PURGE defaults.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 4,  # TUNING (not in GDD) kill-drones come in numbers
	"count_growth": 3,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "PURGE PROTOCOL: the Empire deletes you. Endure."

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments, sorted by start time (keys as
## GraveyardStage.SEGMENTS). The drones, Line Troopers, Spotters and Mortar
## Walkers are the ranged share (about 60-64% of the trickle); the Aegis Bots
## the melee screen. Spotters stay rare in the trickle (their waves bring them).
const SEGMENTS := [
	# Zone I, the Slag Fields: drones and the first Aegis Bots, then the riflemen.
	{"start": 0.0, "rate": 1.3, "max_alive": 28,  # TUNING (not in GDD) the stub's opening: drones alone for the first minute (shields and rifles starve the starting army)
		"weights": {"scout_drone": 1.0},
		"objective": "The Slag Fields: drones sweep in, Aegis Bots raise their shields"},
	{"start": 60.0, "rate": 1.6, "max_alive": 38,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.74, "aegis_bot": 0.16, "line_trooper": 0.1},
		"objective": "Hit the Aegis Bots from the side: their shields stop your shots"},
	{"start": 120.0, "rate": 1.9, "max_alive": 46,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.56, "aegis_bot": 0.24, "line_trooper": 0.2},
		"objective": "Line Troopers march in firing: your dead are cover"},
	{"start": 180.0, "rate": 2.2, "max_alive": 54,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.46, "aegis_bot": 0.29, "line_trooper": 0.25},
		"objective": "Keep your dead between you and the guns"},
	{"start": 240.0, "rate": 2.5, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.38, "aegis_bot": 0.34, "line_trooper": 0.27, "spotter": 0.01},
		"objective": "Spotters paint their targets: step out of the red line"},
	# Zone II, the Wreck Gullies: Mortar Walkers lob shells over the wrecks.
	{"start": 300.0, "rate": 2.7, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.31, "aegis_bot": 0.37, "line_trooper": 0.28, "mortar_walker": 0.02, "spotter": 0.02},
		"objective": "The Wreck Gullies: blockers hold the narrow paths"},
	{"start": 390.0, "rate": 3.0, "max_alive": 74,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.3, "aegis_bot": 0.37, "line_trooper": 0.28, "mortar_walker": 0.03, "spotter": 0.02},
		"objective": "Mortar shells fall on the red circles: keep moving"},
	{"start": 480.0, "rate": 3.3, "max_alive": 82,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.29, "aegis_bot": 0.37, "line_trooper": 0.29, "mortar_walker": 0.03, "spotter": 0.02},
		"objective": "The Empire salvages its dead and sends them back"},
	{"start": 540.0, "rate": 3.4, "max_alive": 84,  # TUNING (not in GDD) lull before the ridge
		"weights": {"scout_drone": 0.29, "aegis_bot": 0.37, "line_trooper": 0.29, "mortar_walker": 0.03, "spotter": 0.02},
		"objective": "Signal masts glow on the ridge ahead"},
	# Zone III, Pylon Ridge: the Signal Pylons and the Trojan Horse.
	{"start": 600.0, "rate": 3.6, "max_alive": 90,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.28, "aegis_bot": 0.36, "line_trooper": 0.3, "mortar_walker": 0.03, "spotter": 0.03},
		"objective": "Pylon Ridge: tear down the Signal Pylons"},
	{"start": 690.0, "rate": 3.9, "max_alive": 98,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.28, "aegis_bot": 0.36, "line_trooper": 0.3, "mortar_walker": 0.03, "spotter": 0.03},
		"objective": "The ridge bristles with guns"},
	{"start": 780.0, "rate": 4.2, "max_alive": 106,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.27, "aegis_bot": 0.36, "line_trooper": 0.31, "mortar_walker": 0.03, "spotter": 0.03},
		"objective": "The Outer Wall lies beyond the ridge"},
	{"start": 840.0, "rate": 4.1, "max_alive": 104,  # TUNING (not in GDD) lull
		"weights": {"scout_drone": 0.27, "aegis_bot": 0.36, "line_trooper": 0.31, "mortar_walker": 0.03, "spotter": 0.03},
		"objective": "The Empire masses on its wall"},
	# Zone IV, the Outer Wall: the density peak of the run.
	{"start": 900.0, "rate": 4.5, "max_alive": 112,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.26, "aegis_bot": 0.36, "line_trooper": 0.31, "mortar_walker": 0.04, "spotter": 0.03},
		"objective": "The Outer Wall: break through the Empire's frontier"},
	{"start": 960.0, "rate": 4.8, "max_alive": 118,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.26, "aegis_bot": 0.36, "line_trooper": 0.31, "mortar_walker": 0.04, "spotter": 0.03},
		"objective": "A sniper's laser sweeps the wall"},
	# 17:00, the boss: a thinner trickle so the fight stays readable.
	{"start": BOSS_TIME, "rate": 3.0, "max_alive": 80,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.3, "aegis_bot": 0.36, "line_trooper": 0.3, "mortar_walker": 0.02, "spotter": 0.02},
		"objective": "Delete Kestrel, the Dead Pixel"},
	{"start": 1110.0, "rate": 3.6, "max_alive": 92,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.29, "aegis_bot": 0.36, "line_trooper": 0.3, "mortar_walker": 0.03, "spotter": 0.02},
		"objective": "Delete Kestrel, the Dead Pixel"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave": formation + groups), plus the Scrap Wastes' own (WastesDirector):
##   "pylons" — `count` Signal Pylons (kind `kind`) rise `distance_min`..
##              `distance_max` px from the necromancer, spread evenly, each with
##              `guards`; each one destroyed pays `reward_xp` in
##              `reward_crystals` and WASTES.ash_per_pylon Soul Ash.
##   "storm"  — a scrap storm rolls in for WASTES.storm_duration s.
##   "trojan" — the Trojan Horse (kind `kind`) arrives on the spawn ring.
const EVENTS := [
	# Zone I: the Slag Fields.
	{"time": 20.0, "type": "wave", "banner": "A drone swarm sweeps over the slag!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "scout_drone", "count": 10, "elite": false}]},
	{"time": 80.0, "type": "wave", "banner": "An Aegis line advances: hit them from the side!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "aegis_bot", "count": 4, "elite": false}]},
	{"time": 105.0, "type": "pylons", "banner": "A SIGNAL PYLON lengthens the Empire's guns: tear it down!",  # Owner-approved proposal (Signal Pylons)
		"kind": "signal_pylon", "count": 1, "distance_min": 300.0, "distance_max": 400.0,  # TUNING (not in GDD)
		"reward_xp": 20, "reward_crystals": 5,  # TUNING (not in GDD)
		"guards": [{"kind": "aegis_bot", "count": 2, "elite": false}, {"kind": "line_trooper", "count": 2, "elite": false}]},  # TUNING (not in GDD)
	{"time": 140.0, "type": "wave", "banner": "A firing line marches behind its shields!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "aegis_bot", "count": 5, "elite": false}, {"kind": "line_trooper", "count": 5, "elite": false}]},
	{"time": 200.0, "type": "wave", "banner": "A Spotter paints you: get behind your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 1, "elite": false}, {"kind": "line_trooper", "count": 5, "elite": false}, {"kind": "aegis_bot", "count": 4, "elite": false}]},
	{"time": 245.0, "type": "storm", "banner": "A SCRAP STORM rolls in: their guns are half blind, close in!"},  # Owner-approved proposal (scrap storms, 20 s)
	{"time": 275.0, "type": "wave", "banner": "Drones and shields close in from every side!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "scout_drone", "count": 12, "elite": false}, {"kind": "aegis_bot", "count": 6, "elite": false}]},
	# Zone II (5:00): the Wreck Gullies; Mortar Walkers.
	{"time": 305.0, "type": "wave", "banner": "MORTAR WALKERS lob shells over the wrecks: keep moving!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "mortar_walker", "count": 2, "elite": false}, {"kind": "aegis_bot", "count": 6, "elite": false}, {"kind": "line_trooper", "count": 4, "elite": false}]},
	{"time": 360.0, "type": "pylons", "banner": "Two Signal Pylons rise among the wrecks!",  # Owner-approved proposal (Signal Pylons)
		"kind": "signal_pylon", "count": 2, "distance_min": 320.0, "distance_max": 440.0,  # TUNING (not in GDD)
		"reward_xp": 24, "reward_crystals": 6,  # TUNING (not in GDD)
		"guards": [{"kind": "aegis_bot", "count": 2, "elite": false}, {"kind": "line_trooper", "count": 2, "elite": false}]},  # TUNING (not in GDD)
	{"time": 420.0, "type": "wave", "banner": "Two Spotter teams take the high wrecks!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 2, "elite": false}, {"kind": "line_trooper", "count": 8, "elite": false}, {"kind": "aegis_bot", "count": 6, "elite": false}]},
	{"time": 470.0, "type": "wave", "banner": "An elite Aegis wall pushes down the gully!", "formation": "line",  # TUNING (not in GDD) first elite
		"groups": [{"kind": "aegis_bot", "count": 1, "elite": true}, {"kind": "aegis_bot", "count": 9, "elite": false}, {"kind": "line_trooper", "count": 6, "elite": false}]},
	{"time": 505.0, "type": "storm", "banner": "Another SCRAP STORM: close the distance while they are blind!"},  # Owner-approved proposal (scrap storms)
	{"time": 545.0, "type": "wave", "banner": "Mortars and drones blot out the sky!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "mortar_walker", "count": 3, "elite": false}, {"kind": "scout_drone", "count": 14, "elite": false}, {"kind": "aegis_bot", "count": 6, "elite": false}]},
	# Zone III (10:00): Pylon Ridge; the Signal Pylons; the Trojan Horse.
	{"time": 605.0, "type": "pylons", "banner": "PYLON RIDGE: three Signal Pylons broadcast over the ridge!",  # Owner-approved proposal (Pylon Ridge)
		"kind": "signal_pylon", "count": 3, "distance_min": 320.0, "distance_max": 460.0,  # TUNING (not in GDD)
		"reward_xp": 28, "reward_crystals": 7,  # TUNING (not in GDD)
		"guards": [{"kind": "aegis_bot", "count": 2, "elite": false}, {"kind": "line_trooper", "count": 2, "elite": false}]},  # TUNING (not in GDD)
	{"time": 640.0, "type": "wave", "banner": "Riflemen hold the ridge line!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 1, "elite": false}, {"kind": "line_trooper", "count": 10, "elite": false}, {"kind": "aegis_bot", "count": 8, "elite": false}]},
	{"time": 660.0, "type": "trojan", "banner": "THE TROJAN HORSE stomps in: shoot down its rockets!",  # Owner-approved proposal (miniboss); 9:00 left like the Harbourmaster
		"kind": "trojan_horse", "elite": false},
	{"time": 740.0, "type": "wave", "banner": "Mortar Walkers shell the ridge!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "mortar_walker", "count": 3, "elite": false}, {"kind": "aegis_bot", "count": 8, "elite": false}, {"kind": "line_trooper", "count": 6, "elite": false}]},
	{"time": 765.0, "type": "storm", "banner": "A SCRAP STORM howls over the ridge: close in!"},  # Owner-approved proposal (scrap storms)
	{"time": 800.0, "type": "wave", "banner": "Three Spotters paint the ridge red!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 3, "elite": false}, {"kind": "line_trooper", "count": 10, "elite": false}, {"kind": "aegis_bot", "count": 8, "elite": false}, {"kind": "mortar_walker", "count": 2, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "Drones blot out the sky!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "scout_drone", "count": 22, "elite": false}, {"kind": "line_trooper", "count": 6, "elite": true}]},
	# Zone IV (15:00): the Outer Wall.
	{"time": 905.0, "type": "pylons", "banner": "THE OUTER WALL: two Signal Pylons crown the wall!",  # Owner-approved proposal (the Outer Wall)
		"kind": "signal_pylon", "count": 2, "distance_min": 320.0, "distance_max": 440.0,  # TUNING (not in GDD)
		"reward_xp": 30, "reward_crystals": 7,  # TUNING (not in GDD)
		"guards": [{"kind": "aegis_bot", "count": 3, "elite": false}, {"kind": "mortar_walker", "count": 1, "elite": false}]},  # TUNING (not in GDD)
	{"time": 935.0, "type": "wave", "banner": "The wall's garrison marches out behind its shields!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "aegis_bot", "count": 12, "elite": false}, {"kind": "line_trooper", "count": 10, "elite": false}, {"kind": "mortar_walker", "count": 2, "elite": false}]},
	{"time": 975.0, "type": "storm", "banner": "The last SCRAP STORM before the wall: close in!"},  # Owner-approved proposal (scrap storms)
	{"time": 995.0, "type": "wave", "banner": "The last battalion!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 3, "elite": false}, {"kind": "line_trooper", "count": 14, "elite": false}, {"kind": "scout_drone", "count": 12, "elite": false}]},
	# 17:00 Kestrel (BOSS_TIME), plus two sallies.
	{"time": 1080.0, "type": "wave", "banner": "Kestrel calls in her spotters!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 2, "elite": false}, {"kind": "aegis_bot", "count": 8, "elite": false}, {"kind": "line_trooper", "count": 6, "elite": false}]},
	{"time": 1140.0, "type": "wave", "banner": "The Empire throws its last shields at you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "aegis_bot", "count": 10, "elite": false}, {"kind": "mortar_walker", "count": 2, "elite": false}, {"kind": "scout_drone", "count": 12, "elite": false}]},
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES.
## `ground` is a WastesGround look:
##   style  — "slag" (cooled black slag crust), "gullies" (packed rust grit
##            between the wrecks), "ridge" (dark ash rock with dead cables) or
##            "wall" (cracked concrete slabs with old hazard paint).
##   base / line / accent / trim — colours of the code floor, its joints, its
##            scrap plates and its dead signal lights.
## Obstacle kinds (WastesGlyphs without art; obstacles/<kind>_<size>[_v]):
##   slag_mound    — a heap of cooled slag (circle)
##   wreck_plate   — a slab of rusted armour plate half sunk in the ground (rect)
##   titan_hull    — a section of a fallen war titan's hull (rect, long)
##   ridge_boulder — a dark ash boulder (circle)
##   wall_segment  — a broken length of the Empire's concrete wall (rect)
##   tank_trap     — a rusted steel tank trap (circle)
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Slag Fields",  # Owner-approved proposal (zones)
		"blurb": "Open ground of cooled slag under a dead sky",
		"ground": {"style": "slag", "base": Color(0.105, 0.09, 0.085), "line": Color(0.06, 0.05, 0.05),
			"accent": Color(0.26, 0.31, 0.39), "trim": Color(1.0, 0.682, 0.102)},
		"arena": {"density": 0.12, "clear_radius": 220.0, "layout_seed": 7711,  # TUNING (not in GDD) open ground
			"kinds": {
				"slag_mound": {"weight": 0.6, "shape": "circle", "sizes": [13.0, 17.0, 21.0]},  # TUNING (not in GDD)
				"wreck_plate": {"weight": 0.4, "shape": "rect", "sizes": [44.0, 60.0], "short": 22.0},  # TUNING (not in GDD)
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Wreck Gullies",  # Owner-approved proposal: "narrow paths between fallen titans, good for blockers"
		"blurb": "Narrow paths between fallen titans of steel",
		"ground": {"style": "gullies", "base": Color(0.12, 0.09, 0.07), "line": Color(0.07, 0.05, 0.04),
			"accent": Color(0.30, 0.22, 0.15), "trim": Color(1.0, 0.682, 0.102)},
		"arena": {"density": 0.3, "clear_radius": 230.0, "layout_seed": 7722,  # TUNING (not in GDD) dense: the wrecks leave lanes
			"kinds": {
				"titan_hull": {"weight": 0.55, "shape": "rect", "sizes": [80.0, 96.0], "short": 34.0},  # TUNING (not in GDD) long hull sections
				"wreck_plate": {"weight": 0.25, "shape": "rect", "sizes": [44.0, 60.0], "short": 22.0},  # TUNING (not in GDD)
				"slag_mound": {"weight": 0.2, "shape": "circle", "sizes": [13.0, 17.0]},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "Pylon Ridge",  # Owner-approved proposal (zones)
		"blurb": "Ash rock under the Empire's red signal masts",
		"ground": {"style": "ridge", "base": Color(0.10, 0.10, 0.105), "line": Color(0.06, 0.06, 0.065),
			"accent": Color(0.22, 0.24, 0.28), "trim": Color(0.878, 0.224, 0.118)},
		"arena": {"density": 0.17, "clear_radius": 220.0, "layout_seed": 7733,  # TUNING (not in GDD)
			"kinds": {
				"ridge_boulder": {"weight": 0.65, "shape": "circle", "sizes": [15.0, 19.0, 23.0]},  # TUNING (not in GDD)
				"tank_trap": {"weight": 0.35, "shape": "circle", "sizes": [11.0, 14.0]},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Outer Wall",  # Owner-approved proposal (zones)
		"blurb": "The broken frontier wall of the Electronic Empire",
		"ground": {"style": "wall", "base": Color(0.115, 0.115, 0.115), "line": Color(0.07, 0.07, 0.07),
			"accent": Color(0.26, 0.31, 0.39), "trim": Color(1.0, 0.682, 0.102)},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 7744,  # TUNING (not in GDD)
			"kinds": {
				"wall_segment": {"weight": 0.55, "shape": "rect", "sizes": [76.0, 92.0], "short": 30.0},  # TUNING (not in GDD)
				"tank_trap": {"weight": 0.45, "shape": "circle", "sizes": [11.0, 14.0]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "THE MARCH INLAND  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(1.0, 0.75, 0.35),  # Signal amber light (EmpirePalette), never the UI's soul-teal.
	"fog_color": Color(0.12, 0.09, 0.06),  # Blowing grit.
	"fog_bank_color": Color(0.30, 0.22, 0.14),
	"zones": ZONES,
}

## The Scrap Wastes' stage systems (WastesDirector; StageRegistry "wastes").
##   pylon_radius       — px around a standing Signal Pylon in which Empire
##                        shooters fire from farther (its signal's reach).
##   pylon_boost        — x their range there (owner-approved: "30% farther").
##   dead_zone_radius   — px around a destroyed pylon's spot in which their
##                        range shrinks for the rest of the run.
##   dead_zone_mult     — x their range there (owner-approved: "shrinks").
##   ash_per_pylon      — Soul Ash per destroyed pylon ("objective_ash";
##                        owner-approved "a structure with a Soul Ash bounty").
##   placement_tries    — attempts to find spaced, obstacle-free spots.
##   structure_spacing  — px; least distance between two pylons of one event.
##   storm_duration     — s a scrap storm lasts (owner-approved: 20 s).
##   storm_reach_mult   — x the Empire's sight during a storm (owner-approved:
##                        "cuts everyone's sight range in half").
##   storm_fade         — s the dust veil takes to fade in and out (visual only).
##   storm_clear_radius — px around the necromancer the veil leaves clear (visual).
##   storm_color        — the dust's colour (visual only).
##   reach_min          — the least reach multiplier any mix allows.
const WASTES := {
	"pylon_radius": 440.0,  # TUNING (not in GDD) px, about the riflemen's range
	"pylon_boost": 1.3,  # Owner-approved proposal: "enemies near it fire from 30% farther away"
	"dead_zone_radius": 440.0,  # TUNING (not in GDD) px ("in that area")
	"dead_zone_mult": 0.8,  # TUNING (not in GDD) owner-approved "shrinks their range in that area for the rest of the run"
	"ash_per_pylon": 8,  # TUNING (not in GDD) like a dream pillar's
	"placement_tries": 8,  # TUNING (not in GDD)
	"structure_spacing": 260.0,  # TUNING (not in GDD) px
	"storm_duration": 20.0,  # Owner-approved proposal: "for 20 s"
	"storm_reach_mult": 0.5,  # Owner-approved proposal: "cuts everyone's sight range in half"
	"storm_fade": 2.5,  # TUNING (not in GDD) s, visual
	"storm_clear_radius": 230.0,  # TUNING (not in GDD) px, visual
	"storm_color": Color(0.36, 0.25, 0.14),  # TUNING (not in GDD) rust-ochre dust, visual
	"reach_min": 0.4,  # TUNING (not in GDD)
}

## Kestrel's arrival (keys as GraveyardStage.BOSS): her own KestrelData.ARRIVAL
## (boss id "kestrel"), whose `time` equals BOSS_TIME (17:00). Her script is
## scripts/enemies/empire/boss_kestrel.gd (loaded by her id).
const BOSS: Dictionary = KestrelData.ARRIVAL

## Placeholder floor of the foundation stub (EmpireGround "floor" key), kept
## for the other tools that read it; the stage draws WastesGround ("ground").
const FLOOR := {
	"style": "scrap",  # Rusted dirt with scattered plates.
	"base": Color(0.11, 0.095, 0.085),  # TUNING (not in GDD) dark rust earth
	"line": Color(0.16, 0.14, 0.12),  # TUNING (not in GDD)
	"accent": Color(0.26, 0.31, 0.39),  # TUNING (not in GDD) chrome scrap plates
	"trim": Color(1.0, 0.682, 0.102),  # TUNING (not in GDD) signal amber
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Scrap Wastes",
	"short_name": "Scrap Wastes",
	"chapter": "Chapter VII",
	"act": 3,  # Act III, the Electronic Empire.
	"playable": false,  # Hidden from the stage select until the lead's balance pass and the owner's playtest.
	"description": "The Empire's old battlefield: slag hills, rusting war machines the size of buildings and red signal masts on the ridges. It saw the beacons of Ul-Thalos burning and came for the one who lit them; Kestrel, the Dead Pixel, hunts the wastes.",
	"unlock": {"stage": "spire", "boss_kills": 1},  # Owner-approved: Act III opens when Vhal'Neth falls
	"unlock_text": "Slay Vhal'Neth on Ul-Thalos to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act III stages.
	"consecration": {},  # A Covenant event: none in Act III.
	"crypt_defender": {},  # None in Act III.
	"arena": ZONES[0]["arena"],
	"ground": "wastes",  # WastesGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"wastes": WASTES,  # WastesDirector: Signal Pylons, scrap storms, the Trojan Horse.
	"empire": true,  # Act III: Line of Fire, Lock-On, Steel has no soul (EmpireRules).
	"music": "iron",  # Act III run loop "Iron Requiem" (RunLoopSynth).
}
