## HarbourStage — STAGE 4, GULLHAVEN HARBOUR (Act II, the Ancient Eye; GDD §15.0
## "Act II: the Ancient Eye" and "Gullhaven Harbour (Act II phase 2)",
## owner-approved proposal "The Drowned Choir" with the faction renamed the
## Ancient Eye). A fishing town at low tide, at night, where the Eye has lived
## in the open for generations. Every number and event that belongs to this
## stage. StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
##
## Like the Crimson March and the Sanctum, THE CLOCK IS AUTHORITATIVE: four
## battle zones on fixed times (ZONES, run by MarchDirector: a zone banner, a
## sweep of sea mist, the ground and obstacles around the necromancer re-drawn
## as the next zone):
##   20:00 (0:00)  I   The Mudflats        low tide, open ground; Initiates and
##                                         Deep Kin trickle in; the bell buoys
##   15:00 (5:00)  II  The Fish Market     narrow lanes between stalls; the
##                                         first Tide Callers and the first surge;
##                                         the smugglers' caches
##   10:00 (10:00) III The Chapel of the Deep  the tide reaches the square;
##                                         Netcasters and the Harbourmaster (9:00)
##   5:00 (15:00)  IV  The Seawall         high tide: a long strip of dry stone;
##                                         Abbot Merrow arrives with 3:00 left
## The stage's own mechanics:
##   * The tide (TideDirector, TIDE below): water rises on the clock and floods
##     more of the town each zone; tide surges every 4 min sweep a telegraphed
##     band of the map. Water slows everyone in it (undead, necromancer and
##     cultists alike) except the swimmers (Deep Kin and their kin).
##   * The bell buoys, the smugglers' caches and the Harbourmaster
##     (HarbourDirector, HARBOUR below, "buoys" / "caches" / "harbourmaster"
##     timeline events).
##   * The Ancient Eye's Claims: Chanter-led Initiate squads (EyeEnemyData).
##   * The Reckoning restyled as "The Deep Rises": Heralds of the Deep (the
##     stage's own Reckoning kind, HarbourEnemyData) with Deep Kin, and the sea
##     floods everything but the seawall.
## The stage starts a little above the Sanctum (its kinds carry the step up:
## leaps, nets, knock-backs, the water) and climbs. Every rate, cap and weight
## is TUNING (not in GDD).
class_name HarbourStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "harbour"

## Stage-local enemy kind aliases (StageRegistry "kind_aliases";
## EnemyDirector.resolve_kind()): the timeline names the Ancient Eye's shared
## kinds by these short keys; the stage's own kinds use their real ids.
##   initiate -> Initiate of the Eye (EyeEnemyData)
##   chanter  -> Chanter of the Eye  (EyeEnemyData, a Claims squad leader)
const KINDS := {
	"initiate": "eye_initiate",  # GDD §15.0 Act II
	"chanter": "eye_chanter",  # GDD §15.0 Act II Claims
}

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which Abbot Silas Merrow appears (3:00 left; the run
## structure of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (the Sanctum's is 1.1: Act II starts a little above it and climbs).
const ENEMY_HP_MULT: float = 1.15  # TUNING (not in GDD)
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.15  # TUNING (not in GDD)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them): Zone II, the Fish Market (the
## Sanctum's from Zone III; from 0:00 they would lift an Initiate past the
## starting Shadow Bolt's one-shot, the March's lesson).
const ENEMY_MULT_FROM: float = 300.0  # TUNING (not in GDD)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.75  # TUNING (not in GDD) owner-approved proposal placeholder (Act I: x1.25, x1.5)

## "The Deep Rises": the Harbour's Reckoning (same escalation as every stage;
## keys as GraveyardStage.RECKONING) with the stage's own main kind:
##   kind        — the Reckoning's main kind (HarbourEnemyData "deep_herald",
##                 a swimmer) instead of the Reckoning Inquisitor.
##   companions  — Deep Kin march with every wave (keys as SanctumStage.RECKONING).
## At 0:00 the TideDirector also floods everything but the seawall's top
## (TIDE "reckoning_flood").
const RECKONING := {
	"banner": "THE DEEP RISES: THE EYE OPENS UPON YOU",
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 3,  # TUNING (not in GDD)
	"count_growth": 2,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
	"kind": "deep_herald",  # TUNING (not in GDD) the stage's own Reckoning kind (HarbourEnemyData)
	"companions": [{"kind": "deep_kin", "count": 1, "growth": 0.5}],  # TUNING (not in GDD) Deep Kin swim with the Heralds
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE DEEP RISES: the sea swallows Gullhaven. Endure."

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments, sorted by start time (keys as
## GraveyardStage.SEGMENTS; kind keys may be KINDS aliases). Deep Kin trickle
## from 2:00, Tide Callers from the Fish Market, Netcasters from the Chapel
## (all at low weights: the scripted waves carry their numbers).
const SEGMENTS := [
	# Zone I, the Mudflats: Initiates first (fodder the starting army can cut).
	{"start": 0.0, "rate": 1.6, "max_alive": 34,  # TUNING (not in GDD) a little above the Sanctum's 1.5 / 32
		"weights": {"initiate": 1.0},
		"objective": "The Mudflats: the Ancient Eye gathers on the sand"},
	{"start": 60.0, "rate": 1.8, "max_alive": 42,  # TUNING (not in GDD)
		"weights": {"initiate": 1.0},
		"objective": "Chanters lead the Initiates: kill them before they claim your dead"},
	{"start": 120.0, "rate": 2.2, "max_alive": 54,  # TUNING (not in GDD)
		"weights": {"initiate": 0.93, "chanter": 0.04, "deep_kin": 0.03},
		"objective": "Deep Kin crawl out of the tide pools"},
	{"start": 180.0, "rate": 2.4, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"initiate": 0.90, "chanter": 0.05, "deep_kin": 0.05},
		"objective": "Bell buoys toll out on the flats: sink them to thin the Eye's waves"},
	{"start": 240.0, "rate": 2.7, "max_alive": 68,  # TUNING (not in GDD)
		"weights": {"initiate": 0.88, "chanter": 0.05, "deep_kin": 0.07},
		"objective": "The tide is turning"},
	# Zone II, the Fish Market: the first Tide Callers, the first surge.
	{"start": 300.0, "rate": 3.0, "max_alive": 78,  # TUNING (not in GDD)
		"weights": {"initiate": 0.80, "chanter": 0.05, "deep_kin": 0.11, "tide_caller": 0.04},
		"objective": "The Fish Market: Tide Callers raise the water between the stalls"},
	{"start": 360.0, "rate": 3.2, "max_alive": 86,  # TUNING (not in GDD)
		"weights": {"initiate": 0.79, "chanter": 0.05, "deep_kin": 0.12, "tide_caller": 0.04},
		"objective": "Smugglers' caches on the piers: break them open for treasure"},
	{"start": 420.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD) lull
		"weights": {"initiate": 0.79, "chanter": 0.05, "deep_kin": 0.12, "tide_caller": 0.04},
		"objective": "Fight through the market lanes"},
	{"start": 480.0, "rate": 3.5, "max_alive": 96,  # TUNING (not in GDD)
		"weights": {"initiate": 0.77, "chanter": 0.06, "deep_kin": 0.12, "tide_caller": 0.05},
		"objective": "The congregation follows the water"},
	{"start": 540.0, "rate": 3.8, "max_alive": 106,  # TUNING (not in GDD)
		"weights": {"initiate": 0.77, "chanter": 0.06, "deep_kin": 0.12, "tide_caller": 0.05},
		"objective": "The chapel bell answers the buoys"},
	# Zone III, the Chapel of the Deep: Netcasters; the Harbourmaster at 9:00 left.
	{"start": 600.0, "rate": 4.1, "max_alive": 118,  # TUNING (not in GDD)
		"weights": {"initiate": 0.72, "chanter": 0.06, "deep_kin": 0.12, "tide_caller": 0.05, "netcaster": 0.05},
		"objective": "The Chapel of the Deep: Netcasters snare your dead"},
	{"start": 660.0, "rate": 4.3, "max_alive": 124,  # TUNING (not in GDD)
		"weights": {"initiate": 0.72, "chanter": 0.06, "deep_kin": 0.12, "tide_caller": 0.05, "netcaster": 0.05},
		"objective": "The Harbourmaster drags his anchor up the chapel steps"},
	{"start": 720.0, "rate": 4.0, "max_alive": 120,  # TUNING (not in GDD) lull
		"weights": {"initiate": 0.72, "chanter": 0.06, "deep_kin": 0.12, "tide_caller": 0.05, "netcaster": 0.05},
		"objective": "The tide fills the chapel square"},
	{"start": 780.0, "rate": 4.7, "max_alive": 134,  # TUNING (not in GDD)
		"weights": {"initiate": 0.70, "chanter": 0.06, "deep_kin": 0.13, "tide_caller": 0.05, "netcaster": 0.06},
		"objective": "The Eye's faithful wade in from the sea"},
	{"start": 840.0, "rate": 5.0, "max_alive": 142,  # TUNING (not in GDD)
		"weights": {"initiate": 0.70, "chanter": 0.06, "deep_kin": 0.13, "tide_caller": 0.05, "netcaster": 0.06},
		"objective": "High tide is coming"},
	# Zone IV, the Seawall: high tide, a long strip of dry stone.
	{"start": 900.0, "rate": 5.5, "max_alive": 152,  # TUNING (not in GDD) the density peak of the run
		"weights": {"initiate": 0.68, "chanter": 0.07, "deep_kin": 0.13, "tide_caller": 0.06, "netcaster": 0.06},
		"objective": "The Seawall: hold the last dry stone"},
	{"start": 960.0, "rate": 5.2, "max_alive": 150,  # TUNING (not in GDD)
		"weights": {"initiate": 0.68, "chanter": 0.07, "deep_kin": 0.13, "tide_caller": 0.06, "netcaster": 0.06},
		"objective": "The Voice of the Deep approaches"},
	# 17:00, the boss: a thinner trickle so the duel stays readable.
	{"start": BOSS_TIME, "rate": 3.4, "max_alive": 104,  # TUNING (not in GDD)
		"weights": {"initiate": 0.74, "chanter": 0.06, "deep_kin": 0.12, "netcaster": 0.04, "tide_caller": 0.04},
		"objective": "Slay Abbot Silas Merrow"},
	{"start": 1110.0, "rate": 4.2, "max_alive": 124,  # TUNING (not in GDD)
		"weights": {"initiate": 0.72, "chanter": 0.06, "deep_kin": 0.13, "netcaster": 0.05, "tide_caller": 0.04},
		"objective": "Slay Abbot Silas Merrow"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave" entries: formation + groups; kind keys may be KINDS aliases), plus
## the Harbour types run by HarbourDirector:
##   "buoys"         — `count` bell buoys (kind `kind`) out on the flats,
##                     `distance_min`..`distance_max` px from the necromancer
##                     (in the water when a flooded spot is found). While one
##                     stands it tolls every HARBOUR.toll_interval s and sends
##                     HARBOUR.toll_groups from the sea; each one sunk makes the
##                     Eye's later waves smaller (HARBOUR.wave_cut_per_buoy).
##                     `reward_xp` / `reward_crystals`: XP burst per buoy.
##   "caches"        — `count` smugglers' caches (kind `kind`) on piers
##                     `distance_min`..`distance_max` px away, each with its
##                     `guards`; a broken cache drops a treasure chest.
##   "harbourmaster" — the Harbourmaster miniboss (`kind`) from the spawn ring
##                     (its kit shows it on the miniboss bar; ChestManager drops
##                     its chest).
const EVENTS := [
	# Zone I: the Mudflats.
	{"time": 15.0, "type": "wave", "banner": "Initiates of the Eye shamble up from the beach!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "initiate", "count": 8, "elite": false}]},
	{"time": 60.0, "type": "wave", "banner": "The congregation rings the flats!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "initiate", "count": 10, "elite": false}]},
	{"time": 95.0, "type": "wave", "banner": "A Chanter leads its squad: it claims the dead!", "formation": "arc",  # TUNING (not in GDD) the stub's Claims beat (the first army is fragile)
		"groups": [{"kind": "chanter", "count": 1, "elite": false}, {"kind": "initiate", "count": 9, "elite": false}]},
	{"time": 125.0, "type": "wave", "banner": "A Deep Kin leaps from the tide pools!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "deep_kin", "count": 1, "elite": false}, {"kind": "initiate", "count": 8, "elite": false}]},
	{"time": 150.0, "type": "buoys", "banner": "Three bell buoys toll out on the flats: sink them to thin the Eye's waves!",  # owner-approved proposal "Bell buoys"
		"kind": "bell_buoy", "count": 3, "distance_min": 320.0, "distance_max": 440.0,  # TUNING (not in GDD)
		"reward_xp": 24, "reward_crystals": 5},  # TUNING (not in GDD)
	{"time": 190.0, "type": "wave", "banner": "A great Deep Kin leads the pod!", "formation": "arc",  # TUNING (not in GDD) first elite
		"groups": [{"kind": "deep_kin", "count": 1, "elite": true}, {"kind": "initiate", "count": 10, "elite": false}]},
	{"time": 240.0, "type": "wave", "banner": "Two squads close in from the dunes!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "chanter", "count": 2, "elite": false}, {"kind": "initiate", "count": 16, "elite": false}, {"kind": "deep_kin", "count": 1, "elite": false}]},
	# Zone II: the Fish Market.
	{"time": 310.0, "type": "wave", "banner": "Tide Callers raise the water between the stalls!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "tide_caller", "count": 3, "elite": false}, {"kind": "initiate", "count": 8, "elite": false}]},
	{"time": 360.0, "type": "caches", "banner": "Smugglers' caches on the piers: break them open for treasure!",  # owner-approved proposal "Smugglers' caches"
		"kind": "smuggler_cache", "count": 2, "distance_min": 300.0, "distance_max": 380.0,  # TUNING (not in GDD)
		"reward_xp": 12, "reward_crystals": 3,  # TUNING (not in GDD)
		"guards": [{"kind": "deep_kin", "count": 1, "elite": false}, {"kind": "initiate", "count": 3, "elite": false}]},  # TUNING (not in GDD)
	{"time": 400.0, "type": "wave", "banner": "The market crowd turns on you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "chanter", "count": 2, "elite": false}, {"kind": "initiate", "count": 14, "elite": false}, {"kind": "deep_kin", "count": 2, "elite": false}]},
	{"time": 450.0, "type": "wave", "banner": "Deep Kin and Tide Callers surge through the lanes!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "tide_caller", "count": 2, "elite": false}, {"kind": "deep_kin", "count": 3, "elite": false}, {"kind": "initiate", "count": 6, "elite": false}]},
	{"time": 495.0, "type": "wave", "banner": "A procession of the Eye marches from the fish hall!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "chanter", "count": 2, "elite": true}, {"kind": "initiate", "count": 20, "elite": false}]},
	{"time": 550.0, "type": "wave", "banner": "The fishwives of the Eye come with the tide!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "tide_caller", "count": 3, "elite": false}, {"kind": "deep_kin", "count": 2, "elite": false}, {"kind": "initiate", "count": 8, "elite": false}]},
	# Zone III: the Chapel of the Deep.
	{"time": 610.0, "type": "wave", "banner": "Netcasters cast from the chapel steps!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "netcaster", "count": 3, "elite": false}, {"kind": "initiate", "count": 10, "elite": false}]},
	{"time": 640.0, "type": "wave", "banner": "The chapel's congregation surrounds you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "chanter", "count": 2, "elite": false}, {"kind": "initiate", "count": 18, "elite": false}, {"kind": "tide_caller", "count": 2, "elite": false}]},
	# "The Harbourmaster (miniboss, 9:00)": 9:00 left on the countdown.
	{"time": 660.0, "type": "harbourmaster", "banner": "THE HARBOURMASTER hauls his anchor out of the deep!",  # owner-approved proposal
		"kind": "harbourmaster", "elite": false},  # its HP, XP burst and chest: HarbourEnemyData / HarbourmasterKit / ChestManager
	{"time": 700.0, "type": "caches", "banner": "More smugglers' caches wash up on the old pier!",  # TUNING (not in GDD)
		"kind": "smuggler_cache", "count": 1, "distance_min": 300.0, "distance_max": 380.0,  # TUNING (not in GDD)
		"reward_xp": 18, "reward_crystals": 4,  # TUNING (not in GDD)
		"guards": [{"kind": "netcaster", "count": 1, "elite": false}, {"kind": "deep_kin", "count": 1, "elite": false}]},  # TUNING (not in GDD)
	{"time": 740.0, "type": "wave", "banner": "Deep Kin and Netcasters rise from the flooded square!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "deep_kin", "count": 4, "elite": false}, {"kind": "netcaster", "count": 2, "elite": false}, {"kind": "initiate", "count": 8, "elite": false}]},
	{"time": 790.0, "type": "wave", "banner": "The whole chapel chants your name!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "initiate", "count": 22, "elite": false}, {"kind": "chanter", "count": 3, "elite": false}, {"kind": "deep_kin", "count": 1, "elite": true}]},
	{"time": 840.0, "type": "wave", "banner": "Callers and Netcasters work the tide together!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "tide_caller", "count": 3, "elite": false}, {"kind": "netcaster", "count": 3, "elite": false}, {"kind": "deep_kin", "count": 3, "elite": false}]},
	# Zone IV: the Seawall.
	{"time": 905.0, "type": "wave", "banner": "The congregation storms the seawall!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "initiate", "count": 24, "elite": false}, {"kind": "chanter", "count": 2, "elite": false}, {"kind": "deep_kin", "count": 2, "elite": false}]},
	{"time": 950.0, "type": "wave", "banner": "The deep sends its kin over the wall!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "deep_kin", "count": 4, "elite": false}, {"kind": "netcaster", "count": 2, "elite": false}, {"kind": "tide_caller", "count": 2, "elite": false},
			{"kind": "chanter", "count": 1, "elite": true}, {"kind": "initiate", "count": 12, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The faithful gather for their Abbot!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "tide_caller", "count": 3, "elite": false}, {"kind": "initiate", "count": 14, "elite": false}, {"kind": "chanter", "count": 1, "elite": true}]},
	# 17:00 Abbot Merrow (BOSS_TIME), plus two sallies.
	{"time": 1080.0, "type": "wave", "banner": "The Abbot's flock wades to his side!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "initiate", "count": 16, "elite": false}, {"kind": "deep_kin", "count": 3, "elite": false}, {"kind": "netcaster", "count": 2, "elite": false}]},
	{"time": 1140.0, "type": "wave", "banner": "The last of Gullhaven rises from the sea!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "initiate", "count": 18, "elite": false}, {"kind": "deep_kin", "count": 3, "elite": false}, {"kind": "chanter", "count": 2, "elite": true}]},
]

# =====================================================================================
# Battle zones and their look
# =====================================================================================

## Battle zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES;
## `ground` is a HarbourGround look:
##   style  — "mudflats" (wet sand and shell grit), "market" (wet cobbles,
##            scales and rope), "chapel" (slimed flagstones, coral growth) or
##            "seawall" (dressed stone paving of the promenade).
##   base / line / accent / trim — colours of the code floor, its joints, the
##            zone's decoration and its highlight.
## Obstacle kinds are drawn from their sprites (obstacles/<kind>_<size>.png)
## or by HarbourGlyphs. Every Harbour obstacle is round (one drawing per size,
## no vertical variants).
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Mudflats",  # owner-approved proposal
		"blurb": "Low tide: wet sand, wrecks and tide pools under a drowned moon",
		"ground": {"style": "mudflats", "base": Color(0.17, 0.16, 0.14), "line": Color(0.13, 0.12, 0.11),
			"accent": Color(0.24, 0.22, 0.19), "trim": Color(0.36, 0.42, 0.40)},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 4413,  # TUNING (not in GDD) open ground
			"kinds": {
				"mooring_post": {"weight": 0.40, "shape": "circle", "sizes": [9.0, 12.0]},  # TUNING (not in GDD)
				"wreck_ribs": {"weight": 0.25, "shape": "circle", "sizes": [24.0, 30.0]},  # TUNING (not in GDD)
				"net_pile": {"weight": 0.35, "shape": "circle", "sizes": [14.0, 18.0]},  # TUNING (not in GDD)
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Fish Market",  # owner-approved proposal
		"blurb": "Narrow lanes between the stalls, slick with scales",
		"ground": {"style": "market", "base": Color(0.16, 0.16, 0.17), "line": Color(0.12, 0.12, 0.13),
			"accent": Color(0.22, 0.24, 0.24), "trim": Color(0.48, 0.52, 0.50)},
		"arena": {"density": 0.34, "clear_radius": 220.0, "layout_seed": 4524,  # TUNING (not in GDD) lanes between stalls
			"kinds": {
				"fish_stall": {"weight": 0.45, "shape": "circle", "sizes": [20.0, 24.0, 28.0]},  # TUNING (not in GDD)
				"barrel_stack": {"weight": 0.30, "shape": "circle", "sizes": [12.0, 15.0]},  # TUNING (not in GDD)
				"crate_stack": {"weight": 0.25, "shape": "circle", "sizes": [14.0, 17.0]},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Chapel of the Deep",  # owner-approved proposal
		"blurb": "The tide fills the square before the Eye's chapel",
		"ground": {"style": "chapel", "base": Color(0.15, 0.17, 0.17), "line": Color(0.11, 0.13, 0.13),
			"accent": Color(0.18, 0.26, 0.25), "trim": Color(0.40, 0.30, 0.52)},
		"arena": {"density": 0.24, "clear_radius": 220.0, "layout_seed": 4635,  # TUNING (not in GDD)
			"kinds": {
				"drowned_idol": {"weight": 0.35, "shape": "circle", "sizes": [16.0, 20.0]},  # TUNING (not in GDD)
				"coral_pillar": {"weight": 0.40, "shape": "circle", "sizes": [13.0, 16.0]},  # TUNING (not in GDD)
				"tide_font": {"weight": 0.25, "shape": "circle", "sizes": [20.0, 24.0]},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Seawall",  # owner-approved proposal
		"blurb": "High tide: a long strip of dry stone between the sea and the drowned town",
		"ground": {"style": "seawall", "base": Color(0.18, 0.18, 0.18), "line": Color(0.13, 0.13, 0.13),
			"accent": Color(0.25, 0.25, 0.24), "trim": Color(0.44, 0.46, 0.44)},
		"arena": {"density": 0.13, "clear_radius": 220.0, "layout_seed": 4746,  # TUNING (not in GDD) room to fight on the strip
			"kinds": {
				"bollard": {"weight": 0.45, "shape": "circle", "sizes": [8.0, 10.0]},  # TUNING (not in GDD)
				"anchor_monument": {"weight": 0.20, "shape": "circle", "sizes": [20.0, 24.0]},  # TUNING (not in GDD)
				"lobster_pots": {"weight": 0.35, "shape": "circle", "sizes": [12.0, 15.0]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the Harbour's sea-mist zone change.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "THE TIDE TURNS  -  ZONE %s",
	"zone_color": Color(0.55, 0.88, 0.80),  # Drowned teal (EyeEnemyData.CLAIM tint family), apart from the UI soul-teal by its lightness.
	"fog_color": Color(0.06, 0.12, 0.13),  # Sea mist.
	"fog_bank_color": Color(0.16, 0.26, 0.27),
	"zones": ZONES,
}

# =====================================================================================
# The tide (TideDirector)
# =====================================================================================

## The tide, run by TideDirector (scripts/enemies/tide_director.gd). The town's
## ground has a fixed "height" h(p) in about 0..1 (a sum of the `field` waves,
## h = 0.5 + sum amp * sin(p.x * kx + p.y * ky + phase)); a point is under
## water while h(p) < the tide level. The same function runs on the GPU
## (scripts/fx/tide_water.gdshader), so what is drawn is what slows.
##   field          — [kx, ky, phase, amp] per wave (rad/px, rad/px, rad, h).
##   levels         — [elapsed s, level] keyframes, linearly interpolated (the
##                    tide rises on the clock; each zone change steps it up).
##                    Measured shares of flooded ground (200,000 random
##                    points): 0.17 ~4%, 0.22 ~8%, 0.30 ~17%, 0.35 ~23%,
##                    0.42 ~34%, 0.46 ~40%.
##   slow           — fraction of move speed lost in the water (everyone but
##                    the `swimmers`; owner-approved "25%").
##   swimmers       — enemy kinds that swim at full speed.
##   tick           — s between two water checks of every body.
##   linger         — s a water slow outlasts its check (a little over `tick`).
##   seawall        — the Seawall zone: from `start` s only a strip of dry
##                    stone `half_width` px each side of a line along x through
##                    the necromancer stays dry (plus islands where h(p) >
##                    `island_level`); its sea edge is the wall itself.
##   high_water     — Abbot Merrow's High Water and the Reckoning: the dry strip
##                    shrinks to the seawall's top, `half_width` px each side of
##                    a line `half_width` px inside the sea edge, easing over
##                    `ease` s (Merrow below MerrowData "high_water_hp").
##   reckoning_flood — true: the Reckoning brings the high water too.
##   surge          — tide surges: from `first` s every `interval` s a band
##                    `half_width` px each side of a line through a point within
##                    `offset_max` px of the necromancer is telegraphed for
##                    `telegraph` s, then a wave front sweeps along it at `speed`
##                    px/s over `length` px. Bodies the front passes are shoved
##                    `push` px along it (the necromancer `push_player` px), and
##                    the band behind the front stays flooded for `linger` s.
const TIDE := {
	"field": [
		[0.0061, 0.0023, 0.7, 0.20],  # TUNING (not in GDD) ~1,030 px swell
		[-0.0029, 0.0071, 2.1, 0.16],  # TUNING (not in GDD) ~885 px
		[0.0113, 0.0087, 4.2, 0.10],  # TUNING (not in GDD) ~556 px
		[0.0171, -0.0149, 1.3, 0.06],  # TUNING (not in GDD) ~367 px pools
	],
	"levels": [[0.0, 0.17], [290.0, 0.22], [305.0, 0.30], [590.0, 0.35], [605.0, 0.42], [890.0, 0.46]],  # TUNING (not in GDD) ~4% -> ~45% flooded
	"slow": 0.25,  # owner-approved proposal "Water slows everyone in it by 25%"
	"swimmers": ["deep_kin", "harbourmaster", "deep_herald"],  # owner-approved "Deep Kin are the exception"
	"tick": 0.2,  # TUNING (not in GDD) s
	"linger": 0.3,  # TUNING (not in GDD) s
	"seawall": {"start": 900.0, "half_width": 230.0, "island_level": 0.80},  # TUNING (not in GDD) owner-approved "a long strip of dry stone"
	"high_water": {"half_width": 64.0, "ease": 3.0},  # TUNING (not in GDD) owner-approved "the seawall at its edge"
	"reckoning_flood": true,  # TUNING (not in GDD) the Deep Rises
	"surge": {"first": 330.0, "interval": 240.0, "telegraph": 2.5, "half_width": 120.0, "length": 1500.0,  # owner-approved "every 4 minutes"; sizes TUNING (not in GDD)
		"speed": 650.0, "linger": 10.0, "push": 60.0, "push_player": 40.0, "offset_max": 110.0},  # TUNING (not in GDD)
	# Look (purely visual, TideDirector / tide_water.gdshader).
	"water_color": Color(0.05, 0.16, 0.18, 0.78),  # TUNING (not in GDD) drowned teal, the floor faintly seen through
	"deep_color": Color(0.03, 0.09, 0.12, 0.88),  # TUNING (not in GDD) far from the shore
	"foam_color": Color(0.62, 0.78, 0.74, 0.55),  # TUNING (not in GDD) the waterline
	"glint_color": Color(0.55, 0.85, 0.80, 0.35),  # TUNING (not in GDD) moonlit ripples
	"surge_color": Color(0.60, 0.92, 0.86, 0.85),  # TUNING (not in GDD) the wave crest and its telegraph
}

# =====================================================================================
# Stage events (HarbourDirector)
# =====================================================================================

## Harbour objectives, run by HarbourDirector (scripts/enemies/harbour_director.gd).
##   toll_interval      — s between two tolls of a standing bell buoy.
##   toll_radius        — px; a buoy only tolls while the necromancer is this close.
##   toll_groups        — the squad each toll calls up from the sea beside it.
##   wave_cut_per_buoy  — each sunk buoy makes every LATER scripted wave this
##                        much smaller (additive: 3 buoys = -36%; counts round
##                        down, at least one of each group).
##   trickle_cut_per_buoy — and the trickle rate this much lower.
##   ash_per_buoy / ash_per_cache — Soul Ash per sunk buoy / broken cache
##                        (the "objective_ash" stat, a Soul Ash part).
##   pier_length / pier_width — px of the dry pier each cache stands at the
##                        end of (it runs back toward the necromancer).
##   placement_tries    — attempts to find spaced, flooded, obstacle-free spots.
##   structure_spacing  — px; minimum distance between two buoys / caches.
const HARBOUR := {
	"toll_interval": 22.0,  # TUNING (not in GDD) "ring to call reinforcements"
	"toll_radius": 760.0,  # TUNING (not in GDD)
	"toll_groups": [{"kind": "initiate", "count": 3, "elite": false}, {"kind": "deep_kin", "count": 1, "elite": false}],  # TUNING (not in GDD)
	"wave_cut_per_buoy": 0.12,  # TUNING (not in GDD) owner-approved "each one you sink makes the cult's wave smaller"
	"trickle_cut_per_buoy": 0.05,  # TUNING (not in GDD)
	"ash_per_buoy": 8,  # TUNING (not in GDD) "small", like an altar
	"ash_per_cache": 6,  # TUNING (not in GDD)
	"pier_length": 150.0,  # TUNING (not in GDD)
	"pier_width": 40.0,  # TUNING (not in GDD)
	"placement_tries": 10,  # TUNING (not in GDD)
	"structure_spacing": 170.0,  # TUNING (not in GDD)
}

## Abbot Silas Merrow's arrival (keys as GraveyardStage.BOSS): his own
## MerrowData.ARRIVAL (boss id "merrow", loaded by name from
## scripts/enemies/eye/boss_merrow.gd), whose `time` equals BOSS_TIME.
const BOSS: Dictionary = MerrowData.ARRIVAL

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Gullhaven Harbour",
	"short_name": "Gullhaven",
	"chapter": "Chapter IV",
	"act": 2,  # Act II, the Ancient Eye.
	"playable": false,  # The lead flips it after the integration and the owner's playtest.
	"description": "A fishing town at low tide, at night, where the Ancient Eye has lived in the open for generations. The tide rises on the clock and floods the lanes; sink the bell buoys, raid the smugglers' caches and silence Abbot Silas Merrow, Voice of the Deep.",
	"unlock": {"stage": "sanctum", "boss_kills": 1},  # owner-approved: each boss unlocks the next stage
	"unlock_text": "Slay Grand Inquisitor Seraphine in the Sanctum of Judgment to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act II stages.
	"consecration": {},  # A Covenant event: none in Act II.
	"crypt_defender": {},  # None in Act II.
	"arena": ZONES[0]["arena"],
	"ground": "harbour",  # HarbourGround.
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The clock-driven zones (MarchDirector).
	"tide": TIDE,  # The tide (TideDirector).
	"harbour": HARBOUR,  # Buoys, caches, the Harbourmaster (HarbourDirector).
	"kind_aliases": KINDS,
	"dread": true,  # Act II: Dread on the necromancer (DreadMeter).
	"claims": true,  # Act II: the Ancient Eye claims the fallen (EyeClaims).
	"music": "tide",  # Act II run loop "Below the Tide" (RunLoopSynth).
}
