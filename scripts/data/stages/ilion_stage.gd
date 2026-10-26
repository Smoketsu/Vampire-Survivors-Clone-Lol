## IlionStage — STAGE 10, THE SHORES OF ILION (Act IV, the Olympian Republic;
## GDD §15.0 "Act IV foundation (phase 1)" and "The Shores of Ilion (Act IV
## phase 2)"; owner-approved proposal docs/act4/PROPOSAL.md "Stage 10: The Shores
## of Ilion"). The beach below a besieged city: beached warships, a siege camp,
## and the great walls of Troy. Every number and event that belongs to this
## stage; StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
## Unlocked by defeating Deus Ex Machina once (the first stage of Act IV).
##
## THE CLOCK IS AUTHORITATIVE, as on every stage since the Crimson March: four
## zones on fixed times (ZONES, run by MarchDirector: a zone banner, a sweep of
## sea mist, the obstacles and floor re-drawn as the next zone):
##   20:00  Zone I,   the Beachhead:   wet sand among the beached warships; the
##                                      dead flee the Underworld, wolves and the
##                                      first shield walls
##   15:00  Zone II,  the Siege Camp:  tents and palisades; Legionaries lock the
##                                      testudo, the first siege towers roll
##   10:00  Zone III, the Scaean Gate: the paved road before the gate;
##                                      Cyclopes, Polyphemus at 9:00
##    5:00  Zone IV,  the Walls:       the foot of the walls of Troy; the last
##                                      siege towers
##    3:00  Achilles, the Unkillable (BossAchilles)
##    0:00  the Twilight of the Gods (the shared Act IV Reckoning: Bronze Titans,
##          every wrath at once)
## Wrath of the Gods here is Poseidon's waves (DivineWrath, "wrath"): a wall of
## water rolls across the arena every 90 s, shown 3 s ahead as a foam line. The
## stage systems run in IlionDirector (ILION): SIEGE TOWERS (structures rolling
## past the necromancer toward the walls; destroyed, they spill their garrison
## and pay a Soul Ash bounty; at the walls, their garrison marches out stronger)
## and POLYPHEMUS THE CYCLOPS (the miniboss). The Republic is a melee army
## (owner-approved roster: shields, wolves, giants and heroes; only the
## Cyclopes throw), led into the waves and broken from the flanks. A step harder
## than the Iron Citadel. Every rate, cap and weight is TUNING (not in GDD).
class_name IlionStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "ilion"

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act IV starts a step above the Iron Citadel's 1.35 and climbs stage by stage).
const ENEMY_HP_MULT: float = 1.4  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.35  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Act III: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 1 of Act IV

## Wrath of the Gods on this stage (DivineWrath): Poseidon's waves. Any other
## key overrides PantheonRulesData.WRATH["waves"] ({} = those defaults).
const WRATH := {
	"kind": "waves",  # Owner-approved proposal: Poseidon's waves (Ilion)
	"first": 75.0,  # TUNING (not in GDD) the first wave at 18:45 left, after the opening swarm
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
## GraveyardStage.SEGMENTS). Shades are the fodder; every Wolf of Rome the
## trickle picks leads a pack of five (WolfKit), so its weight is small;
## Hoplites and Legionaries the shield walls; Cyclopes the heavies; Heroes the
## rare elites.
const SEGMENTS := [
	# Zone I, the Beachhead.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 1.0},
		"objective": "The Beachhead: the dead flee the Underworld onto the sand"},
	{"start": 60.0, "rate": 1.6, "max_alive": 38,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.82, "wolf_of_rome": 0.03, "hoplite": 0.15},
		"objective": "Bronze wolves hunt in packs of five: hold them on your blockers"},
	{"start": 150.0, "rate": 1.9, "max_alive": 46,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.7, "wolf_of_rome": 0.04, "hoplite": 0.25, "hero": 0.01},
		"objective": "Hoplites lock shields: break the wall from the flanks"},
	{"start": 240.0, "rate": 2.2, "max_alive": 52,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.62, "wolf_of_rome": 0.04, "hoplite": 0.3, "legionary": 0.03, "hero": 0.01},
		"objective": "Lure them into Poseidon's waves"},
	# Zone II, the Siege Camp: the Legionaries and the first siege towers.
	{"start": 300.0, "rate": 2.4, "max_alive": 58,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.52, "wolf_of_rome": 0.04, "hoplite": 0.22, "legionary": 0.21, "hero": 0.01},
		"objective": "The Siege Camp: Legionaries close the testudo against your arrows"},
	{"start": 420.0, "rate": 2.8, "max_alive": 68,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.48, "wolf_of_rome": 0.04, "hoplite": 0.22, "legionary": 0.245, "hero": 0.015},
		"objective": "Burn the siege towers before they reach the walls"},
	{"start": 510.0, "rate": 3.1, "max_alive": 76,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.46, "wolf_of_rome": 0.045, "hoplite": 0.22, "legionary": 0.26, "hero": 0.015},
		"objective": "Strike the testudo with blades and stomps"},
	# Zone III, the Scaean Gate: the Cyclopes, Polyphemus.
	{"start": 600.0, "rate": 3.4, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.44, "wolf_of_rome": 0.04, "hoplite": 0.22, "legionary": 0.26, "cyclops": 0.012, "hero": 0.015},
		"objective": "The Scaean Gate: step out of the boulders' circles"},
	{"start": 720.0, "rate": 3.8, "max_alive": 94,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.42, "wolf_of_rome": 0.04, "hoplite": 0.22, "legionary": 0.27, "cyclops": 0.015, "hero": 0.02},
		"objective": "The gate's host marches out"},
	{"start": 840.0, "rate": 4.0, "max_alive": 100,  # TUNING (not in GDD) lull before the walls
		"weights": {"shade_of_dead": 0.42, "wolf_of_rome": 0.04, "hoplite": 0.22, "legionary": 0.27, "cyclops": 0.015, "hero": 0.02},
		"objective": "The walls of Troy rise ahead"},
	# Zone IV, the Walls: the density peak of the run.
	{"start": 900.0, "rate": 4.4, "max_alive": 110,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.4, "wolf_of_rome": 0.04, "hoplite": 0.23, "legionary": 0.28, "cyclops": 0.015, "hero": 0.02},
		"objective": "The Walls: the last siege towers roll for the gate"},
	{"start": 960.0, "rate": 4.7, "max_alive": 116,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.4, "wolf_of_rome": 0.04, "hoplite": 0.23, "legionary": 0.28, "cyclops": 0.015, "hero": 0.02},
		"objective": "A golden helmet gleams on the ships"},
	# 17:00, the boss: a thinner trickle so the fight stays readable.
	{"start": BOSS_TIME, "rate": 2.8, "max_alive": 76,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.5, "wolf_of_rome": 0.03, "hoplite": 0.2, "legionary": 0.24, "cyclops": 0.01, "hero": 0.01},
		"objective": "Strike Achilles from behind: only his heel is mortal"},
	{"start": 1110.0, "rate": 3.4, "max_alive": 88,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.48, "wolf_of_rome": 0.03, "hoplite": 0.2, "legionary": 0.25, "cyclops": 0.012, "hero": 0.015},
		"objective": "Strike Achilles from behind: only his heel is mortal"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave": formation + groups; a wolf_of_rome group's `count` is a count of
## PACKS: each wolf it spawns leads four more, WolfKit), plus the Shores of
## Ilion's own (IlionDirector):
##   "siege_towers" — `count` siege towers roll past the necromancer toward the
##                    walls (ILION pass_distance / pass_offset); each destroyed
##                    spills `garrison` (groups, stunned ILION spill_stun s),
##                    pays ILION.ash_per_tower Soul Ash and `reward_xp` in
##                    `reward_crystals`; one that reaches the walls marches its
##                    garrison out ILION.reach_garrison_mult times as many.
##   "polyphemus"   — Polyphemus the Cyclops (kind `kind`) arrives on the spawn ring.
const EVENTS := [
	# Zone I: the Beachhead.
	{"time": 20.0, "type": "wave", "banner": "The dead flee across the sand!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "shade_of_dead", "count": 12, "elite": false}]},
	{"time": 70.0, "type": "wave", "banner": "Bronze WOLVES OF ROME: a pack of five lopes in!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "wolf_of_rome", "count": 1, "elite": false}, {"kind": "shade_of_dead", "count": 6, "elite": false}]},
	{"time": 110.0, "type": "wave", "banner": "A shield wall advances: strike its flanks!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "hoplite", "count": 6, "elite": false}]},
	{"time": 160.0, "type": "wave", "banner": "A Hero takes the field: kill it before it wins Glory!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 1, "elite": false}, {"kind": "shade_of_dead", "count": 8, "elite": false}]},
	{"time": 205.0, "type": "wave", "banner": "LEGIONARIES lock the testudo: your arrows glance off their roof of shields!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "legionary", "count": 6, "elite": false}]},
	{"time": 255.0, "type": "wave", "banner": "Two wolf packs circle the beach!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "wolf_of_rome", "count": 2, "elite": false}, {"kind": "hoplite", "count": 8, "elite": false}]},
	# Zone II (5:00): the Siege Camp; siege towers.
	{"time": 310.0, "type": "siege_towers", "banner": "A SIEGE TOWER rolls for the walls: burn it before it gets there!",  # Owner-approved proposal (siege towers)
		"kind": "siege_tower", "count": 1, "reward_xp": 22, "reward_crystals": 5,  # TUNING (not in GDD)
		"garrison": [{"kind": "legionary", "count": 4, "elite": false}, {"kind": "hoplite", "count": 2, "elite": false}]},  # TUNING (not in GDD)
	{"time": 360.0, "type": "wave", "banner": "The camp's cohort marches in testudo!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "legionary", "count": 12, "elite": false}]},
	{"time": 420.0, "type": "wave", "banner": "Heroes lead the host!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 2, "elite": false}, {"kind": "legionary", "count": 8, "elite": false}, {"kind": "shade_of_dead", "count": 12, "elite": false}]},
	{"time": 470.0, "type": "siege_towers", "banner": "Two siege towers roll through the camp!",  # Owner-approved proposal (siege towers)
		"kind": "siege_tower", "count": 2, "reward_xp": 24, "reward_crystals": 6,  # TUNING (not in GDD)
		"garrison": [{"kind": "legionary", "count": 4, "elite": false}, {"kind": "hoplite", "count": 2, "elite": false}]},  # TUNING (not in GDD)
	{"time": 545.0, "type": "wave", "banner": "The wolves of Rome run in force!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "wolf_of_rome", "count": 3, "elite": false}, {"kind": "shade_of_dead", "count": 10, "elite": false}]},
	# Zone III (10:00): the Scaean Gate; Cyclopes, Polyphemus.
	{"time": 605.0, "type": "wave", "banner": "CYCLOPES hurl boulders from the gate: step out of the circles!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "cyclops", "count": 2, "elite": false}, {"kind": "hoplite", "count": 8, "elite": false}]},
	{"time": 660.0, "type": "polyphemus", "banner": "POLYPHEMUS THE CYCLOPS shakes the shore: boulders fall!",  # Owner-approved proposal (miniboss); 9:00 left like the Trojan Horse
		"kind": "polyphemus", "elite": false},
	{"time": 725.0, "type": "siege_towers", "banner": "Siege towers roll for the Scaean Gate!",  # Owner-approved proposal (siege towers)
		"kind": "siege_tower", "count": 2, "reward_xp": 28, "reward_crystals": 7,  # TUNING (not in GDD)
		"garrison": [{"kind": "legionary", "count": 5, "elite": false}, {"kind": "hoplite", "count": 3, "elite": false}]},  # TUNING (not in GDD)
	{"time": 780.0, "type": "wave", "banner": "Two shield walls close in from both sides!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "legionary", "count": 12, "elite": false}, {"kind": "hoplite", "count": 10, "elite": false}]},
	{"time": 845.0, "type": "wave", "banner": "Heroes and giants storm out of the gate!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 2, "elite": false}, {"kind": "cyclops", "count": 2, "elite": false}, {"kind": "wolf_of_rome", "count": 2, "elite": false}]},
	# Zone IV (15:00): the Walls.
	{"time": 905.0, "type": "siege_towers", "banner": "THE WALLS: the last three siege towers roll for Troy!",  # Owner-approved proposal (siege towers)
		"kind": "siege_tower", "count": 3, "reward_xp": 30, "reward_crystals": 7,  # TUNING (not in GDD)
		"garrison": [{"kind": "legionary", "count": 5, "elite": false}, {"kind": "hoplite", "count": 3, "elite": false}, {"kind": "hero", "count": 1, "elite": false}]},  # TUNING (not in GDD)
	{"time": 945.0, "type": "wave", "banner": "The phalanx of the walls marches on you!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "legionary", "count": 16, "elite": false}, {"kind": "hoplite", "count": 10, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The last host of Troy!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 3, "elite": false}, {"kind": "cyclops", "count": 2, "elite": false}, {"kind": "shade_of_dead", "count": 16, "elite": false}]},
	# 17:00 Achilles (BOSS_TIME), plus two sallies.
	{"time": 1080.0, "type": "wave", "banner": "The Achaeans pour off the ships!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "legionary", "count": 8, "elite": false}, {"kind": "wolf_of_rome", "count": 2, "elite": false}]},
	{"time": 1140.0, "type": "wave", "banner": "The gods throw their last host at you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hoplite", "count": 10, "elite": false}, {"kind": "cyclops", "count": 2, "elite": false}, {"kind": "shade_of_dead", "count": 12, "elite": false}]},
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES.
## `ground` is an IlionGround look:
##   style  — "beach" (dark wet sand with foam lines), "camp" (trampled earth
##            and straw), "gate" (the worn flagstones of the road before the
##            Scaean Gate) or "walls" (cut limestone slabs at the foot of the walls).
##   base / line / accent / trim — colours of the code floor, its joints, its
##            stones and its foam / straw / inlay.
## Obstacle kinds (IlionGlyphs without art; obstacles/<kind>_<size>[_v]):
##   beached_warship — a Greek trireme pulled up on the sand (rect, long)
##   sea_rock        — a wet sea rock with a bronze anchor (circle)
##   siege_tent      — a striped army tent (circle)
##   palisade        — a length of sharpened stakes (rect)
##   troy_wall       — a broken length of the walls of Troy (rect)
##   fallen_column   — a fallen column on cut stones (circle)
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Beachhead",  # Owner-approved proposal (zones)
		"blurb": "Wet sand among the beached warships of the Achaeans",
		"ground": {"style": "beach", "base": Color(0.122, 0.102, 0.075), "line": Color(0.082, 0.071, 0.055),
			"accent": Color(0.29, 0.26, 0.22), "trim": Color(0.435, 0.714, 0.910)},
		"arena": {"density": 0.13, "clear_radius": 220.0, "layout_seed": 1011,  # TUNING (not in GDD) open sand
			"kinds": {
				"beached_warship": {"weight": 0.45, "shape": "rect", "sizes": [80.0, 96.0], "short": 32.0},  # TUNING (not in GDD)
				"sea_rock": {"weight": 0.55, "shape": "circle", "sizes": [14.0, 18.0]},  # TUNING (not in GDD)
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Siege Camp",  # Owner-approved proposal (zones)
		"blurb": "Tents and palisades of the army that besieges Troy",
		"ground": {"style": "camp", "base": Color(0.11, 0.09, 0.07), "line": Color(0.07, 0.06, 0.043),
			"accent": Color(0.30, 0.22, 0.15), "trim": Color(0.24, 0.2, 0.125)},
		"arena": {"density": 0.24, "clear_radius": 230.0, "layout_seed": 1022,  # TUNING (not in GDD) a crowded camp: lanes between the tents
			"kinds": {
				"siege_tent": {"weight": 0.5, "shape": "circle", "sizes": [18.0, 22.0]},  # TUNING (not in GDD)
				"palisade": {"weight": 0.5, "shape": "rect", "sizes": [56.0, 76.0], "short": 18.0},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Scaean Gate",  # Owner-approved proposal (zones)
		"blurb": "The old paved road before the great gate of Troy",
		"ground": {"style": "gate", "base": Color(0.137, 0.129, 0.118), "line": Color(0.078, 0.075, 0.063),
			"accent": Color(0.557, 0.541, 0.525), "trim": Color(0.659, 0.439, 0.18)},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 1033,  # TUNING (not in GDD)
			"kinds": {
				"fallen_column": {"weight": 0.6, "shape": "circle", "sizes": [14.0, 18.0]},  # TUNING (not in GDD)
				"troy_wall": {"weight": 0.4, "shape": "rect", "sizes": [76.0, 92.0], "short": 30.0},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Walls",  # Owner-approved proposal (zones)
		"blurb": "The foot of the great walls of Troy",
		"ground": {"style": "walls", "base": Color(0.149, 0.141, 0.125), "line": Color(0.082, 0.075, 0.063),
			"accent": Color(0.557, 0.541, 0.525), "trim": Color(0.173, 0.467, 0.722)},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 1044,  # TUNING (not in GDD)
			"kinds": {
				"troy_wall": {"weight": 0.6, "shape": "rect", "sizes": [76.0, 92.0], "short": 30.0},  # TUNING (not in GDD)
				"fallen_column": {"weight": 0.4, "shape": "circle", "sizes": [14.0, 18.0]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "THE SHORES OF ILION  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(0.878, 0.663, 0.333),  # Bronze light (Palette.PANTHEON_BRONZE_LIGHT), never the UI's soul-teal.
	"fog_color": Color(0.16, 0.22, 0.28),  # Sea mist.
	"fog_bank_color": Color(0.32, 0.42, 0.5),
	"zones": ZONES,
}

## The Shores of Ilion's stage systems (IlionDirector; StageRegistry "ilion").
##   walls_dir           — unit world direction toward the walls of Troy: the
##                         siege towers roll this way (up the beach).
##   pass_distance       — px each side of the necromancer a tower's run
##                         starts and ends (it rolls 2 x this).
##   pass_offset         — px off his line the first tower passes (the next
##                         ones further, alternating sides).
##   arrive_slack        — px from its end point at which a tower has reached
##                         the walls.
##   ash_per_tower       — Soul Ash per destroyed tower ("objective_ash";
##                         owner-approved "pays a bounty").
##   spill_stun          — s the garrison of a destroyed tower lies stunned.
##   reach_garrison_mult — x the garrison of a tower that reached the walls
##                         (own decision: it marches out stronger).
const ILION := {
	"walls_dir": Vector2(0.0, -1.0),  # TUNING (not in GDD) the city lies up the beach (world north)
	"pass_distance": 520.0,  # TUNING (not in GDD) px; about 43 s of rolling at 24 px/s
	"pass_offset": 150.0,  # TUNING (not in GDD) px
	"arrive_slack": 8.0,  # TUNING (not in GDD) px
	"ash_per_tower": 8,  # TUNING (not in GDD) like a Signal Pylon's
	"spill_stun": 1.5,  # TUNING (not in GDD) s
	"reach_garrison_mult": 1.5,  # TUNING (not in GDD) own decision
}

## Achilles' arrival (keys as GraveyardStage.BOSS): his own AchillesData.ARRIVAL
## (boss id "achilles"), whose `time` equals BOSS_TIME (17:00). His script is
## scripts/enemies/pantheon/boss_achilles.gd (loaded by his id).
const BOSS: Dictionary = AchillesData.ARRIVAL

## Placeholder floor of the foundation stub (PantheonGround "floor" key), kept
## for the other tools that read it; the stage draws IlionGround ("ground").
const FLOOR := {
	"style": "sand",  # Wet beach sand with foam lines and broken marble.
	"base": Color(0.20, 0.17, 0.12),  # TUNING (not in GDD) dark wet sand
	"line": Color(0.25, 0.21, 0.15),  # TUNING (not in GDD)
	"accent": Color(0.557, 0.541, 0.525),  # TUNING (not in GDD) marble_dark fragments
	"trim": Color(0.435, 0.714, 0.910),  # TUNING (not in GDD) aegean_light foam
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Shores of Ilion",
	"short_name": "Ilion",
	"chapter": "Chapter X",
	"act": 4,  # Act IV, the Olympian Republic.
	"playable": true,  # Owner decision (Oct 25, 2026): "Ship it!" after the art review and three playtest passes (GDD §15.0 "Act IV goes live").
	"description": "The beach below a besieged city: beached warships, a siege camp and the great walls of Troy. The gods have come down to take the dead back, and Achilles leads their host.",
	"unlock": {"stage": "citadel", "boss_kills": 1},  # Owner-approved: Deus Ex Machina's fall opens Act IV
	"unlock_text": "Bring down Deus Ex Machina in the Iron Citadel to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act IV stages.
	"consecration": {},  # A Covenant event: none in Act IV.
	"crypt_defender": {},  # None in Act IV.
	"arena": ZONES[0]["arena"],
	"ground": "ilion",  # IlionGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"ilion": ILION,  # IlionDirector: siege towers, Polyphemus.
	"pantheon": true,  # Act IV: Wrath of the Gods, Phalanx, Glory (PantheonRules).
	"wrath": WRATH,  # Act IV: this stage's wrath kind (DivineWrath).
	"music": "bronze",  # "Hymn of Bronze" (SoundData.BRONZE_SCORE), which also loads the Pantheon sound pack
}
