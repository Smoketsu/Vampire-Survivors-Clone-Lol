## AssemblyStage — STAGE 8, THE ASSEMBLY HALLS (Act III, the Electronic Empire;
## GDD §15.0 "Act III foundation (phase 1)" and "The Assembly Halls (Act III
## phase 2)", owner-approved proposal "Necropathy: Act III Proposal (The
## Electronic Empire)"). The factory where the Empire builds its soldiers:
## conveyor floors, robotic arms, sparks and molten metal. Every number and
## event that belongs to this stage. StageRegistry exposes it to the run as
## `Game.stage_def` (the STAGE dictionary at the bottom; its keys are
## documented in StageRegistry).
##
## Like every Act II stage, THE CLOCK IS AUTHORITATIVE: four battle zones on
## fixed times (ZONES, run by MarchDirector: a zone banner, a sweep of furnace
## smoke, the ground and obstacles around the necromancer re-drawn as the next
## zone):
##   20:00 (0:00)  I   The Loading Docks     open decks between cargo crates and
##                                           fuel drums; one slow belt; the first
##                                           fabricators
##   15:00 (5:00)  II  The Conveyor Floor    belt lanes everywhere drag both armies
##                                           out of position; Juggernauts
##   10:00 (10:00) III The Fabricator Hall   robot arms and servo cabinets; the most
##                                           fabricators; the Beta Build (9:00)
##   5:00 (15:00)  IV  The Furnace           furnace channels burn on a rhythm;
##                                           the Motherboard boots with 3:00 left
## The stage's own mechanics (AssemblyDirector, ASSEMBLY below, the zones'
## "belts" / "channels"):
##   * Conveyors: belt lanes carry everyone standing on them along at a steady
##     push, through the one ground path (TerrainSlow.push_*).
##   * Fabricators: structures that build a new enemy every few seconds until
##     smashed; each one destroyed thins the waves and the trickle for the rest
##     of the run. Destroying every fabricator of one run earns Cold Assembly.
##   * Furnace channels: floor strips that flare on a telegraphed rhythm and
##     burn anything standing in them, enemies included.
##   * The Beta Build (miniboss, "beta_build" event): it patches itself from
##     every fabricator still standing.
##   * The Electronic Empire's three shared rules ("empire": true; EmpireRules):
##     Line of Fire, Lock-On, Steel has no soul; the Purge Protocol Reckoning.
## Guests: the Scrap Wastes' Aegis Bots and Mortar Walkers march here too
## (ASSEMBLY "guests": a timeline alias that resolves to the real kind once its
## table exists, EnemyDirector.is_known_kind(), else to a fallback kind; so the
## stage needs no edit when the Wastes' table merges; own decision, like
## Ul-Thalos's guest squads). With them, about 60% of the stage's enemies
## attack from range (owner-approved proposal).
## A step harder than Ul-Thalos. Every rate, cap and weight is TUNING (not in GDD).
class_name AssemblyStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "assembly"

## Stage-local enemy kind aliases (StageRegistry "kind_aliases";
## EnemyDirector.resolve_kind()): the guest aliases of ASSEMBLY "guests" are
## added at run start by AssemblyDirector.guest_aliases(); none is fixed here.
const KINDS := {}

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the Motherboard boots (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act III starts at Act II's last step and climbs stage by stage).
const ENEMY_HP_MULT: float = 1.35  # TUNING (not in GDD) a step above Ul-Thalos (1.2) (Act III balance: 1.3 -> 1.35; the act's danger is its ranged fire, so each stage's step above Ul-Thalos is in HP, not in damage: the naive bot bled to death between 8:00 and 12:00)
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.1  # TUNING (not in GDD) (Act III balance: 1.25 -> 1.1; the act's danger is its ranged fire, so each stage's step above Ul-Thalos is in HP, not in damage: the naive bot bled to death between 8:00 and 12:00)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them): Zone II.
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as the Archive and Ul-Thalos (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 2.75  # TUNING (not in GDD) placeholder (the Scrap Wastes x2.5)

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
## GraveyardStage.SEGMENTS; "aegis" / "mortar" are the guest aliases of
## ASSEMBLY "guests"). Drones are the fodder, the Line Troopers the bulk of the
## fire, the Aegis Bots the melee line in front of them; Arc Engineers from
## 2:30, Juggernauts from the Conveyor Floor (rare: the scripted waves carry
## their numbers).
const SEGMENTS := [
	# Zone I, the Loading Docks.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD) the stub's 1.3 / 28, a little up
		"weights": {"scout_drone": 1.0},
		"objective": "The Loading Docks: drones sweep the decks"},
	{"start": 60.0, "rate": 1.7, "max_alive": 38,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.82, "aegis": 0.15, "line_trooper": 0.03},  # TUNING (not in GDD) Act III balance (the shared Act III opening): was {"scout_drone": 0.75, "aegis": 0.15, "line_trooper": 0.10}
		"objective": "Line Troopers march in firing: your dead are cover"},
	{"start": 150.0, "rate": 2.0, "max_alive": 48,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.73, "aegis": 0.18, "line_trooper": 0.05, "arc_engineer": 0.04},  # TUNING (not in GDD) Act III balance (the shared Act III opening): was {"scout_drone": 0.56, "aegis": 0.2, "line_trooper": 0.2, "arc_engineer": 0.04}
		"objective": "Fabricators build the Empire's soldiers: smash them"},
	{"start": 240.0, "rate": 2.3, "max_alive": 56,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.59, "aegis": 0.26, "line_trooper": 0.1, "arc_engineer": 0.05},  # TUNING (not in GDD) Act III balance (the shared Act III opening): was {"scout_drone": 0.47, "aegis": 0.22, "line_trooper": 0.24, "arc_engineer": 0.05, "spotter": 0.02}
		"objective": "Arc Engineers repair the machines: cut them down first"},
	# Zone II, the Conveyor Floor.
	{"start": 300.0, "rate": 2.6, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.44, "aegis": 0.357, "line_trooper": 0.112, "arc_engineer": 0.05, "juggernaut": 0.007, "spotter": 0.003},  # TUNING (not in GDD) Act III balance (Spotters x0.15, Juggernauts x0.5, Troopers x0.6, the rest to the drones (the Zone II ramp), Troopers x0.75, the rest to the Aegis Bots (the ranged share), Aegis +0.08 from the drones): was {"scout_drone": 0.42, "aegis": 0.24, "line_trooper": 0.25, "arc_engineer": 0.05, "juggernaut": 0.015, "spotter": 0.02}
		"objective": "The Conveyor Floor: the belts drag everyone out of position"},
	{"start": 420.0, "rate": 2.9, "max_alive": 74,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.362, "aegis": 0.372, "line_trooper": 0.156, "arc_engineer": 0.05, "juggernaut": 0.01, "spotter": 0.003, "mortar": 0.02},  # TUNING (not in GDD) Act III balance (Spotters x0.15, Juggernauts x0.5, Troopers x0.8, the rest to the drones (the Zone II ramp), Troopers x0.75, the rest to the Aegis Bots (the ranged share), Aegis +0.08 from the drones): was {"scout_drone": 0.39, "aegis": 0.24, "line_trooper": 0.26, "arc_engineer": 0.05, "juggernaut": 0.02, "spotter": 0.02, "mortar": 0.02}
		"objective": "Keep your dead between you and the guns"},
	{"start": 540.0, "rate": 3.2, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.3, "aegis": 0.385, "line_trooper": 0.195, "arc_engineer": 0.05, "juggernaut": 0.01, "spotter": 0.004, "mortar": 0.02},  # TUNING (not in GDD) Act III balance (Spotters x0.15, Juggernauts x0.5, Troopers x0.75, the rest to the Aegis Bots (the ranged share), Aegis +0.08 from the drones): was {"scout_drone": 0.38, "aegis": 0.24, "line_trooper": 0.26, "arc_engineer": 0.05, "juggernaut": 0.02, "spotter": 0.03, "mortar": 0.02}
		"objective": "The line never stops"},
	# Zone III, the Fabricator Hall.
	{"start": 600.0, "rate": 3.4, "max_alive": 92,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.27, "aegis": 0.395, "line_trooper": 0.195, "arc_engineer": 0.06, "juggernaut": 0.01, "spotter": 0.004, "mortar": 0.02},  # TUNING (not in GDD) Act III balance (Spotters x0.15, Juggernauts x0.5, Troopers x0.75, the rest to the Aegis Bots (the ranged share), Aegis +0.08 from the drones): was {"scout_drone": 0.35, "aegis": 0.25, "line_trooper": 0.26, "arc_engineer": 0.06, "juggernaut": 0.02, "spotter": 0.03, "mortar": 0.02}
		"objective": "The Fabricator Hall: every bay builds another soldier"},
	{"start": 720.0, "rate": 3.6, "max_alive": 100,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.27, "aegis": 0.395, "line_trooper": 0.195, "arc_engineer": 0.06, "juggernaut": 0.01, "spotter": 0.004, "mortar": 0.02},  # TUNING (not in GDD) Act III balance (Spotters x0.15, Juggernauts x0.5, Troopers x0.75, the rest to the Aegis Bots (the ranged share), Aegis +0.08 from the drones): was {"scout_drone": 0.35, "aegis": 0.25, "line_trooper": 0.26, "arc_engineer": 0.06, "juggernaut": 0.02, "spotter": 0.03, "mortar": 0.02}
		"objective": "Smash the fabricators and the Beta Build has nothing to patch itself with"},
	{"start": 840.0, "rate": 3.9, "max_alive": 108,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.26, "aegis": 0.398, "line_trooper": 0.203, "arc_engineer": 0.06, "juggernaut": 0.01, "spotter": 0.004, "mortar": 0.02},  # TUNING (not in GDD) Act III balance (Spotters x0.15, Juggernauts x0.5, Troopers x0.75, the rest to the Aegis Bots (the ranged share), Aegis +0.08 from the drones): was {"scout_drone": 0.34, "aegis": 0.25, "line_trooper": 0.27, "arc_engineer": 0.06, "juggernaut": 0.02, "spotter": 0.03, "mortar": 0.02}
		"objective": "The heat rises from the furnaces below"},
	# Zone IV, the Furnace.
	{"start": 900.0, "rate": 4.2, "max_alive": 116,  # TUNING (not in GDD) the density peak of the run
		"weights": {"scout_drone": 0.26, "aegis": 0.398, "line_trooper": 0.203, "arc_engineer": 0.06, "juggernaut": 0.01, "spotter": 0.004, "mortar": 0.02},  # TUNING (not in GDD) Act III balance (Spotters x0.15, Juggernauts x0.5, Troopers x0.75, the rest to the Aegis Bots (the ranged share), Aegis +0.08 from the drones): was {"scout_drone": 0.34, "aegis": 0.25, "line_trooper": 0.27, "arc_engineer": 0.06, "juggernaut": 0.02, "spotter": 0.03, "mortar": 0.02}
		"objective": "The Furnace: keep out of the channels when they flare"},
	{"start": 960.0, "rate": 4.4, "max_alive": 122,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.26, "aegis": 0.398, "line_trooper": 0.203, "arc_engineer": 0.06, "juggernaut": 0.01, "spotter": 0.004, "mortar": 0.02},  # TUNING (not in GDD) Act III balance (Spotters x0.15, Juggernauts x0.5, Troopers x0.75, the rest to the Aegis Bots (the ranged share), Aegis +0.08 from the drones): was {"scout_drone": 0.34, "aegis": 0.25, "line_trooper": 0.27, "arc_engineer": 0.06, "juggernaut": 0.02, "spotter": 0.03, "mortar": 0.02}
		"objective": "Something vast is booting up in the furnace hall"},
	# 17:00, the boss: a thinner trickle so the duel stays readable.
	{"start": BOSS_TIME, "rate": 2.7, "max_alive": 80,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.34, "aegis": 0.385, "line_trooper": 0.195, "arc_engineer": 0.05, "spotter": 0.004},  # TUNING (not in GDD) Act III balance (Spotters x0.15, Troopers x0.75, the rest to the Aegis Bots (the ranged share), Aegis +0.08 from the drones): was {"scout_drone": 0.42, "aegis": 0.24, "line_trooper": 0.26, "arc_engineer": 0.05, "spotter": 0.03}
		"objective": "Shut down the Motherboard"},
	{"start": 1110.0, "rate": 3.2, "max_alive": 90,  # TUNING (not in GDD)
		"weights": {"scout_drone": 0.32, "aegis": 0.395, "line_trooper": 0.195, "arc_engineer": 0.05, "juggernaut": 0.005, "spotter": 0.004},  # TUNING (not in GDD) Act III balance (Spotters x0.15, Juggernauts x0.5, Troopers x0.75, the rest to the Aegis Bots (the ranged share), Aegis +0.08 from the drones): was {"scout_drone": 0.4, "aegis": 0.25, "line_trooper": 0.26, "arc_engineer": 0.05, "juggernaut": 0.01, "spotter": 0.03}
		"objective": "Shut down the Motherboard"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave" entries: formation + groups; "aegis" / "mortar" are guest aliases),
## plus the Assembly types run by AssemblyDirector:
##   "fabricators" — `count` fabricators (kind `kind`) placed around the
##                   necromancer, `distance_min`..`distance_max` px away, each
##                   building the kinds of `builds` in turn (FabricatorKit,
##                   AssemblyDirector.fabricate()) with its `guards` beside it.
##                   `reward_xp` / `reward_crystals`: XP burst per fabricator.
##   "beta_build"  — the Beta Build miniboss (`kind`) from the spawn ring (its
##                   kit shows it on the miniboss bar; ChestManager drops its chest).
const EVENTS := [
	# Zone I: the Loading Docks.
	{"time": 20.0, "type": "wave", "banner": "A drone swarm sweeps the docks!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "scout_drone", "count": 10, "elite": false}]},
	{"time": 95.0, "type": "wave", "banner": "Aegis Bots shield a firing line!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "aegis", "count": 4, "elite": false}, {"kind": "line_trooper", "count": 2, "elite": false}]},  # TUNING (not in GDD) Act III balance: 4 -> 2 riflemen (the shared opening: at most 3 in a wave before 5:00)
	{"time": 150.0, "type": "fabricators", "banner": "Two fabricators power up on the docks: smash them before they build an army!",  # owner-approved proposal "Fabricators"
		"kind": "fabricator", "count": 2, "distance_min": 320.0, "distance_max": 420.0,  # TUNING (not in GDD)
		"builds": ["scout_drone", "scout_drone", "line_trooper"],  # TUNING (not in GDD) what they build, in turn
		"reward_xp": 24, "reward_crystals": 5,  # TUNING (not in GDD)
		"guards": [{"kind": "scout_drone", "count": 3, "elite": false}]},  # TUNING (not in GDD)
	{"time": 210.0, "type": "wave", "banner": "A Spotter paints you: get behind your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 1, "elite": false}, {"kind": "line_trooper", "count": 3, "elite": false}, {"kind": "aegis", "count": 3, "elite": false}]},  # TUNING (not in GDD) Act III balance: 5 -> 3 riflemen
	{"time": 255.0, "type": "wave", "banner": "Arc Engineers patch the machines as they come!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "arc_engineer", "count": 2, "elite": false}, {"kind": "scout_drone", "count": 10, "elite": false}]},
	# Zone II: the Conveyor Floor.
	{"time": 330.0, "type": "wave", "banner": "A Juggernaut stomps off the line: its armour shrugs off light blows!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "juggernaut", "count": 1, "elite": false}, {"kind": "line_trooper", "count": 6, "elite": false}]},
	{"time": 360.0, "type": "fabricators", "banner": "Fabricators rise between the belts!",  # owner-approved proposal
		"kind": "fabricator", "count": 2, "distance_min": 320.0, "distance_max": 440.0,  # TUNING (not in GDD)
		"builds": ["line_trooper", "scout_drone", "aegis"],  # TUNING (not in GDD)
		"reward_xp": 30, "reward_crystals": 6,  # TUNING (not in GDD)
		"guards": [{"kind": "aegis", "count": 2, "elite": false}, {"kind": "arc_engineer", "count": 1, "elite": false}]},  # TUNING (not in GDD)
	{"time": 420.0, "type": "wave", "banner": "The production line marches on you!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "aegis", "count": 8, "elite": false}, {"kind": "line_trooper", "count": 8, "elite": false}, {"kind": "arc_engineer", "count": 1, "elite": false}]},
	{"time": 490.0, "type": "wave", "banner": "Two Spotter teams lock on!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 2, "elite": false}, {"kind": "line_trooper", "count": 8, "elite": false}, {"kind": "scout_drone", "count": 10, "elite": false}]},
	{"time": 560.0, "type": "wave", "banner": "Juggernauts roll off the belt!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "juggernaut", "count": 2, "elite": false}, {"kind": "arc_engineer", "count": 2, "elite": false}, {"kind": "aegis", "count": 4, "elite": false}]},
	# Zone III: the Fabricator Hall.
	{"time": 615.0, "type": "fabricators", "banner": "The Fabricator Hall wakes: three bays start building!",  # owner-approved proposal
		"kind": "fabricator", "count": 3, "distance_min": 330.0, "distance_max": 460.0,  # TUNING (not in GDD)
		"builds": ["line_trooper", "aegis", "scout_drone", "arc_engineer"],  # TUNING (not in GDD)
		"reward_xp": 36, "reward_crystals": 6,  # TUNING (not in GDD)
		"guards": [{"kind": "aegis", "count": 2, "elite": false}, {"kind": "line_trooper", "count": 2, "elite": false}]},  # TUNING (not in GDD)
	# "The Beta Build (miniboss)": 9:00 left on the countdown.
	{"time": 660.0, "type": "beta_build", "banner": "THE BETA BUILD lurches out of its bay, still half assembled!",  # owner-approved proposal
		"kind": "beta_build", "elite": false},  # its HP, patching, XP burst and chest: AssemblyEnemyData / BetaBuildKit / ChestManager
	{"time": 735.0, "type": "wave", "banner": "A whole platoon off the line!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "aegis", "count": 10, "elite": false}, {"kind": "line_trooper", "count": 10, "elite": false}, {"kind": "spotter", "count": 1, "elite": true}]},
	{"time": 790.0, "type": "fabricators", "banner": "More fabricators come online!",  # TUNING (not in GDD)
		"kind": "fabricator", "count": 2, "distance_min": 330.0, "distance_max": 460.0,  # TUNING (not in GDD)
		"builds": ["line_trooper", "aegis", "juggernaut", "scout_drone"],  # TUNING (not in GDD)
		"reward_xp": 40, "reward_crystals": 7,  # TUNING (not in GDD)
		"guards": [{"kind": "juggernaut", "count": 1, "elite": false}, {"kind": "arc_engineer", "count": 1, "elite": false}]},  # TUNING (not in GDD)
	{"time": 850.0, "type": "wave", "banner": "Engineers and Juggernauts push together!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "juggernaut", "count": 2, "elite": false}, {"kind": "arc_engineer", "count": 3, "elite": false}, {"kind": "line_trooper", "count": 8, "elite": false}]},
	# Zone IV: the Furnace.
	{"time": 905.0, "type": "wave", "banner": "The furnace crews storm out of the heat!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "aegis", "count": 12, "elite": false}, {"kind": "line_trooper", "count": 10, "elite": false}, {"kind": "mortar", "count": 1, "elite": false}]},
	{"time": 960.0, "type": "wave", "banner": "The last shift reports for duty!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 2, "elite": false}, {"kind": "line_trooper", "count": 14, "elite": false}, {"kind": "scout_drone", "count": 14, "elite": false},
			{"kind": "juggernaut", "count": 1, "elite": false}]},
	# 17:00 the Motherboard (BOSS_TIME), plus two sallies.
	{"time": 1080.0, "type": "wave", "banner": "The Motherboard calls its line to defend it!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "aegis", "count": 8, "elite": false}, {"kind": "line_trooper", "count": 8, "elite": false}, {"kind": "arc_engineer", "count": 2, "elite": false}]},
	{"time": 1140.0, "type": "wave", "banner": "Every bay empties at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "scout_drone", "count": 16, "elite": false}, {"kind": "line_trooper", "count": 10, "elite": false}, {"kind": "juggernaut", "count": 1, "elite": true}]},
]

# =====================================================================================
# Belts, channels, battle zones and their look
# =====================================================================================

## Conveyor belt lanes of each zone (AssemblyDirector; Arena "free_bands", so
## no obstacle stands on one). A lane is a strip running ALONG `axis` ("x":
## horizontal strips), centred on offset + k * period across it, `half` px
## each side; lane k carries everyone on it at `speed` px/s along the axis,
## +x for an even k and -x for an odd one (neighbouring belts run opposite
## ways). {} = no belts in that zone.
const BELTS_DOCKS := {"axis": "x", "period": 960.0, "offset": 480.0, "half": 34.0, "speed": 26.0}  # TUNING (not in GDD) one slow belt to meet the rule
const BELTS_CONVEYOR := {"axis": "x", "period": 340.0, "offset": 170.0, "half": 40.0, "speed": 26.0}  # Owner-approved proposal "belt lanes everywhere"; sizes TUNING (not in GDD); Act III balance: speed 36 -> 26 (below the slowest walker, 30 px/s: a Mortar Walker on a 36 px/s belt stood still for 20 s)
const BELTS_HALL := {"axis": "x", "period": 720.0, "offset": 360.0, "half": 36.0, "speed": 24.0}  # TUNING (not in GDD) fewer belts between the bays; Act III balance: speed 30 -> 24 (below the slowest walker)
## Furnace channels of each zone (AssemblyDirector; Arena "free_bands"): strips
## running along `axis` ("y": vertical strips), keys as the belts' without a
## speed; their rhythm is ASSEMBLY "furnace". {} = none.
const CHANNELS_HALL := {"axis": "y", "period": 900.0, "offset": 450.0, "half": 16.0}  # TUNING (not in GDD) the furnace heat reaches up into the hall
const CHANNELS_FURNACE := {"axis": "y", "period": 380.0, "offset": 190.0, "half": 18.0}  # Owner-approved proposal "furnace channels"; sizes TUNING (not in GDD)

## Battle zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES,
## plus `belts` / `channels` (above). `ground` is an AssemblyGround look:
##   style  — "docks" (scuffed deck plates and painted bay lines), "conveyor"
##            (grated walkways between the belts), "fabricator" (polished
##            panels around the build bays) or "furnace" (soot-black cast iron
##            and slag).
##   base / line / accent / trim — colours of the code floor, its joints, the
##            zone's decoration and its signal highlight.
## Obstacle kinds are drawn from their sprites (obstacles/<kind>_<size>[_v].png,
## tools/assembly_props.py) or by AssemblyGlyphs; the rect kinds have both
## orientations.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Loading Docks",  # owner-approved proposal
		"blurb": "Cargo decks under hard amber light, where the parts come in",
		"ground": {"style": "docks", "base": Color(0.10, 0.11, 0.13), "line": Color(0.15, 0.17, 0.21),
			"accent": Color(0.25, 0.29, 0.36), "trim": Color(1.0, 0.682, 0.102)},
		"belts": BELTS_DOCKS, "channels": {},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 8113,  # TUNING (not in GDD) open decks
			"free_bands": [BELTS_DOCKS],
			"kinds": {
				"cargo_crate": {"weight": 0.55, "shape": "rect", "sizes": [44.0, 60.0], "short": 30.0},  # TUNING (not in GDD)
				"fuel_drum": {"weight": 0.45, "shape": "circle", "sizes": [10.0, 13.0]},  # TUNING (not in GDD)
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Conveyor Floor",  # owner-approved proposal
		"blurb": "Belt lanes run everywhere, and everyone rides them",
		"ground": {"style": "conveyor", "base": Color(0.09, 0.10, 0.12), "line": Color(0.14, 0.16, 0.20),
			"accent": Color(0.22, 0.27, 0.34), "trim": Color(1.0, 0.682, 0.102)},
		"belts": BELTS_CONVEYOR, "channels": {},
		"arena": {"density": 0.20, "clear_radius": 220.0, "layout_seed": 8224,  # TUNING (not in GDD) machines between the lanes
			"free_bands": [BELTS_CONVEYOR],
			"kinds": {
				"press_machine": {"weight": 0.5, "shape": "rect", "sizes": [40.0, 52.0], "short": 32.0},  # TUNING (not in GDD)
				"parts_bin": {"weight": 0.5, "shape": "circle", "sizes": [13.0, 16.0]},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Fabricator Hall",  # owner-approved proposal
		"blurb": "Robot arms over the build bays: every bay makes another soldier",
		"ground": {"style": "fabricator", "base": Color(0.11, 0.12, 0.15), "line": Color(0.17, 0.20, 0.25),
			"accent": Color(0.30, 0.36, 0.45), "trim": Color(0.878, 0.224, 0.118)},
		"belts": BELTS_HALL, "channels": CHANNELS_HALL,
		"arena": {"density": 0.22, "clear_radius": 220.0, "layout_seed": 8335,  # TUNING (not in GDD)
			"free_bands": [BELTS_HALL, CHANNELS_HALL],
			"kinds": {
				"servo_cabinet": {"weight": 0.5, "shape": "rect", "sizes": [36.0, 48.0], "short": 26.0},  # TUNING (not in GDD)
				"robot_arm": {"weight": 0.5, "shape": "circle", "sizes": [14.0, 18.0]},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Furnace",  # owner-approved proposal
		"blurb": "Molten metal runs in channels under the halls; the Motherboard waits",
		"ground": {"style": "furnace", "base": Color(0.09, 0.08, 0.08), "line": Color(0.14, 0.12, 0.11),
			"accent": Color(0.30, 0.18, 0.12), "trim": Color(1.0, 0.55, 0.15)},
		"belts": {}, "channels": CHANNELS_FURNACE,
		"arena": {"density": 0.15, "clear_radius": 220.0, "layout_seed": 8446,  # TUNING (not in GDD) room to fight between the channels
			"free_bands": [CHANNELS_FURNACE],
			"kinds": {
				"crucible": {"weight": 0.45, "shape": "circle", "sizes": [16.0, 20.0]},  # TUNING (not in GDD)
				"ingot_stack": {"weight": 0.55, "shape": "rect", "sizes": [40.0, 52.0], "short": 26.0},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the Assembly's furnace-smoke zone change.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "THE LINE ADVANCES  -  ZONE %s",
	"zone_color": Color(1.0, 0.682, 0.102),  # Signal amber (the Empire's light, never the player's violet).
	"fog_color": Color(0.08, 0.07, 0.07),  # Furnace smoke.
	"fog_bank_color": Color(0.20, 0.16, 0.13),
	"zones": ZONES,
}

# =====================================================================================
# Stage systems (AssemblyDirector)
# =====================================================================================

## The Assembly Halls' systems, run by AssemblyDirector
## (scripts/enemies/empire/assembly_director.gd).
##   fabricators — wave_cut / trickle_cut: each fabricator destroyed makes every
##                 LATER scripted wave / the trickle this much smaller
##                 (additive, at least `min_mult` of the original);
##                 ash: Soul Ash per fabricator (the "objective_ash" stat);
##                 spacing / placement_tries: placement rules;
##                 build_cap_margin: a fabricator builds only while the living
##                 enemies stay this many below the trickle's soft cap.
##   furnace     — the channels' rhythm: each channel lies `dormant` s cold,
##                 glows for `warning` s (the telegraph) and burns for
##                 `burning` s; channel k is offset by k x `stagger` s, so
##                 neighbours never flare together. While it burns, every body
##                 in it takes damage every `tick` s: the necromancer
##                 `damage_player`, a summon `damage_summon` (both x the time
##                 scaling of enemy hits), an enemy `damage_enemy` x the enemy
##                 HP scaling (a boss / miniboss `boss_share` of it); flying
##                 drones and structures pass over.
##   guests      — timeline aliases of other stages' kinds: `alias` -> the first
##                 of `ids` that exists (EnemyDirector.is_known_kind()), else
##                 `fallback` (AssemblyDirector.guest_aliases()).
const ASSEMBLY := {
	"fabricators": {
		"wave_cut": 0.06,  # TUNING (not in GDD) owner-approved "each one destroyed thins the waves for the rest of the run"
		"trickle_cut": 0.03,  # TUNING (not in GDD)
		"min_mult": 0.4,  # TUNING (not in GDD) the waves never thin below 40%
		"ash": 8,  # TUNING (not in GDD) "small", like a bell buoy
		"spacing": 220.0,  # TUNING (not in GDD) px between two fabricators
		"placement_tries": 10,  # TUNING (not in GDD)
		"build_cap_margin": 4,  # TUNING (not in GDD) enemies below the soft cap
	},
	"furnace": {
		"dormant": 4.0,  # TUNING (not in GDD) s cold
		"warning": 1.2,  # TUNING (not in GDD) s the channel glows before it flares (the telegraph)
		"burning": 2.4,  # TUNING (not in GDD) s it burns
		"stagger": 1.9,  # TUNING (not in GDD) s between neighbouring channels' rhythms
		"tick": 0.25,  # TUNING (not in GDD) s between two burn ticks
		"damage_player": 2.5,  # TUNING (not in GDD) per tick (10 / s) before the time scaling
		"damage_summon": 3.0,  # TUNING (not in GDD) per tick (12 / s) before the time scaling
		"damage_enemy": 5.0,  # TUNING (not in GDD) per tick x the enemy HP scaling: the furnace burns the Empire too
		"boss_share": 0.5,  # TUNING (not in GDD) share a boss or miniboss takes
	},
	"guests": [
		{"alias": "aegis", "ids": ["aegis_bot"], "fallback": "scout_drone"},  # The Scrap Wastes' melee soldier (Act III phase 2, its own table)
		{"alias": "mortar", "ids": ["mortar_walker"], "fallback": "line_trooper"},  # The Scrap Wastes' heavy
	],
}

## The Motherboard's arrival (keys as GraveyardStage.BOSS): its own
## MotherboardData.ARRIVAL (boss id "motherboard", loaded by name from
## scripts/enemies/empire/boss_motherboard.gd), whose `time` equals BOSS_TIME.
const BOSS: Dictionary = MotherboardData.ARRIVAL

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Assembly Halls",
	"short_name": "Assembly Halls",
	"chapter": "Chapter VIII",
	"act": 3,  # Act III, the Electronic Empire.
	"playable": false,  # The lead flips it after the multi-seed check and the owner's playtest.
	"description": "The Empire's endless factory floors, where the fallen are rebuilt on moving lines under hard amber light. Ride out the conveyors, smash the fabricators, keep clear of the furnace channels and shut down the Motherboard.",
	"unlock": {"stage": "wastes", "boss_kills": 1},  # Owner-approved: each boss unlocks the next stage
	"unlock_text": "Delete Kestrel in the Scrap Wastes to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act III stages.
	"consecration": {},  # A Covenant event: none in Act III.
	"crypt_defender": {},  # None in Act III.
	"arena": ZONES[0]["arena"],
	"ground": "assembly",  # AssemblyGround (the four zone floors).
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The clock-driven zones (MarchDirector).
	"assembly": ASSEMBLY,  # Conveyors, fabricators, furnace channels, the Beta Build (AssemblyDirector).
	"kind_aliases": KINDS,
	"empire": true,  # Act III: Line of Fire, Lock-On, Steel has no soul (EmpireRules).
	"music": "iron",  # Act III run loop "Iron Requiem" (RunLoopSynth).
}
