## CitadelStage — STAGE 9, THE IRON CITADEL, the finale of Act III and of the
## campaign (the Electronic Empire; GDD §15.0 "Act III foundation (phase 1)" and
## "The Iron Citadel (Act III phase 2)"; owner-approved proposal "Necropathy: Act
## III Proposal (The Electronic Empire)"). The cyber fortress itself: chrome
## walls, shield gates, laser courts and the core at its heart, where the
## Empire's founder lives on inside Deus Ex Machina. Every number and event that
## belongs to this stage; StageRegistry exposes it to the run as `Game.stage_def`
## (the STAGE dictionary at the bottom; its keys are documented in
## StageRegistry). Unlocked by shutting down the Motherboard once.
##
## THE CLOCK IS AUTHORITATIVE, as on every zoned stage: four zones on fixed
## times (ZONES, run by MarchDirector: a zone banner, a sweep of smoke, the
## obstacles and floor re-drawn as the next zone), and the fortress's systems
## (CitadelDirector, CITADEL) read the current zone:
##   20:00  Zone I,   the Shield Gates:  a Shield Gate seals the way (its two
##                                        generators); the Citadel's guns wake
##   15:00  Zone II,  the Laser Courts:  laser grids sweep the courts on a fixed
##                                        rhythm (they hurt the Empire's own too);
##                                        another gate; Sentry emplacements
##   10:00  Zone III, the Spire Lifts:   the guns fire faster; the last gate;
##                                        VALKYRIE 2.0 (12:30), the miniboss
##    5:00  Zone IV,  the Core:          the guns at their fastest, lasers again
##    3:00  Deus Ex Machina, with Varn, the Root User (BossDeusExMachina)
##    0:00  the PURGE PROTOCOL (the shared Act III Reckoning: kill-drones and
##          orbital strikes, here at their fiercest)
## A gate still standing when its zone ends locks the Citadel down (a last
## garrison wave, faster guns for the next zone). The kinds of the earlier Act
## III stages join as guest squads when their data exists in the build
## (CITADEL.guests): each kind stays in play on the stages after it, and their
## melee kinds (the Aegis Bot, the Juggernaut) bring the act to its ~60%
## ranged share. It is the hardest timeline of the campaign. Every rate, cap and
## weight is TUNING (not in GDD).
class_name CitadelStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "citadel"

# =====================================================================================
# Stage 9 kinds
# =====================================================================================

## Stage-local enemy kind aliases (StageRegistry "kind_aliases"): every
## timeline entry names its kinds by these short keys;
## EnemyDirector.resolve_kind() maps them to the real kind.
##   drone     -> Scout Drone       (EmpireEnemyData)
##   trooper   -> Line Trooper      (EmpireEnemyData)
##   spotter   -> Spotter           (EmpireEnemyData)
##   duelist   -> Valkyrie Duelist  (CitadelEnemyData)
##   turret    -> Sentry Turret     (CitadelEnemyData)
##   valkyrie  -> Valkyrie 2.0      (CitadelEnemyData, the miniboss)
const KINDS := {
	"drone": "scout_drone",
	"trooper": "line_trooper",
	"spotter": "spotter",
	"duelist": CitadelEnemyData.DUELIST,
	"turret": CitadelEnemyData.TURRET,
	"valkyrie": CitadelEnemyData.VALKYRIE,
}

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act III starts at Act II's last step and climbs stage by stage).
const ENEMY_HP_MULT: float = 1.35  # TUNING (not in GDD) placeholder, tuned in the lead's balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.3  # TUNING (not in GDD) placeholder, tuned in the lead's balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) 7:00 (the Archive and Ul-Thalos)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 3.0  # TUNING (not in GDD) placeholder (the Assembly Halls x2.75)

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Purge
## Protocol, shared by every Act III stage: kill-drones pour in from every edge
## ("kind") while orbital strikes rain on telegraphed circles, faster each
## minute ("orbital": EmpireRulesData.PURGE keys overridden here). The finale's
## sky is the fiercest: salvos come a little faster and land wider.
const RECKONING := {
	"banner": "PURGE PROTOCOL: THE CITADEL TURNS ITS GUNS ON YOU",
	"kind": EmpireEnemyData.KILL_DRONE,  # The shared Purge Protocol kind.
	"orbital": {"interval": 3.5, "scatter": 300.0},  # TUNING (not in GDD) the finale's sky (defaults 4.0 s, 260 px)
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 4,  # TUNING (not in GDD) kill-drones come in numbers
	"count_growth": 3,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
	"companions": [{"kind": "duelist", "count": 1, "growth": 0.5}],  # TUNING (not in GDD) Valkyrie Duelists dive in with them
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "PURGE PROTOCOL: the Citadel deletes you. Endure."

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments, sorted by start time (keys as
## GraveyardStage.SEGMENTS; kind keys are KINDS aliases). Drones are the fodder,
## Line Troopers the bulk of the fire, Spotters the rare elites, Valkyrie
## Duelists the melee elites that dive the ring; the gates, the turrets and the
## guests add to it. Drones alone for the first minute (the Act III foundation's
## lesson: early fire starves the starting army).
const SEGMENTS := [
	# Zone I, the Shield Gates.
	{"start": 0.0, "rate": 1.1, "max_alive": 24,  # TUNING (not in GDD) balance pass 3: 1.3 / 28 -> 1.1 / 24 (drone fire through a two-unit army killed the bot by 2:20)
		"weights": {"drone": 1.0},
		"objective": "The Iron Citadel's drones rise: hold your ground"},
	{"start": 60.0, "rate": 1.3, "max_alive": 30,  # TUNING (not in GDD) balance pass 3: 1.6 / 38 -> 1.3 / 30
		"weights": {"drone": 0.92, "trooper": 0.08},  # TUNING (not in GDD) balance pass 3: troopers 0.12 -> 0.08 (the naive bot died at 2:50 to rifle fire)
		"objective": "Line Troopers march in firing: your dead are cover"},
	{"start": 120.0, "rate": 1.6, "max_alive": 40,  # TUNING (not in GDD) balance pass 3: 1.9 / 46 -> 1.6 / 40
		"weights": {"drone": 0.86, "trooper": 0.14},  # TUNING (not in GDD) balance pass 3: 0.2 -> 0.14
		"objective": "Keep your dead between you and the guns"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD) balance pass 3: 2.2 / 54 -> 2.0 / 50
		"weights": {"drone": 0.8, "trooper": 0.2},  # TUNING (not in GDD) balance pass 3: troopers 0.24 -> 0.2, no Duelist before 4:00 (the army bot died at 3:30)
		"objective": "The Citadel's guns wake: step out of the red circles"},
	{"start": 240.0, "rate": 2.3, "max_alive": 56,  # TUNING (not in GDD) balance pass 3: 2.5 / 60 -> 2.3 / 56
		"weights": {"drone": 0.74, "trooper": 0.2, "duelist": 0.06},  # TUNING (not in GDD) balance pass 3: troopers 0.26 -> 0.2
		"objective": "The Laser Courts lie beyond the gates"},
	# Zone II, the Laser Courts: laser grids, emplacements.
	{"start": 300.0, "rate": 2.7, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"drone": 0.6, "trooper": 0.3, "duelist": 0.08, "spotter": 0.02},
		"objective": "The Laser Courts: step into the gaps of the grid"},
	{"start": 420.0, "rate": 3.0, "max_alive": 74,  # TUNING (not in GDD)
		"weights": {"drone": 0.56, "trooper": 0.32, "duelist": 0.09, "spotter": 0.03},
		"objective": "The grid burns the Empire's own: lead them into it"},
	{"start": 540.0, "rate": 3.2, "max_alive": 80,  # TUNING (not in GDD)
		"weights": {"drone": 0.55, "trooper": 0.33, "duelist": 0.09, "spotter": 0.03},
		"objective": "The Spire Lifts rise ahead"},
	# Zone III, the Spire Lifts: faster guns, the last gate, Valkyrie 2.0.
	{"start": 600.0, "rate": 3.4, "max_alive": 86,  # TUNING (not in GDD)
		"weights": {"drone": 0.53, "trooper": 0.33, "duelist": 0.1, "spotter": 0.04},
		"objective": "The Spire Lifts: the fortress fires on you from above"},
	{"start": 720.0, "rate": 3.6, "max_alive": 92,  # TUNING (not in GDD)
		"weights": {"drone": 0.52, "trooper": 0.34, "duelist": 0.1, "spotter": 0.04},
		"objective": "Valkyrie 2.0 leads the Citadel's guard"},
	{"start": 840.0, "rate": 3.8, "max_alive": 98,  # TUNING (not in GDD)
		"weights": {"drone": 0.5, "trooper": 0.35, "duelist": 0.11, "spotter": 0.04},
		"objective": "The Core lies at the top of the lifts"},
	# Zone IV, the Core.
	{"start": 900.0, "rate": 4.0, "max_alive": 102,  # TUNING (not in GDD)
		"weights": {"drone": 0.48, "trooper": 0.36, "duelist": 0.11, "spotter": 0.05},
		"objective": "The Core: the god the Empire built wakes beneath you"},
	{"start": 960.0, "rate": 4.2, "max_alive": 106,  # TUNING (not in GDD)
		"weights": {"drone": 0.48, "trooper": 0.36, "duelist": 0.11, "spotter": 0.05},
		"objective": "Deus Ex Machina rises in the Core"},
	# 17:00, the boss: a thinner trickle so the fight stays readable.
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"drone": 0.6, "trooper": 0.3, "duelist": 0.07, "spotter": 0.03},
		"objective": "Break Deus Ex Machina"},
	{"start": 1110.0, "rate": 2.8, "max_alive": 76,  # TUNING (not in GDD)
		"weights": {"drone": 0.58, "trooper": 0.31, "duelist": 0.08, "spotter": 0.03},
		"objective": "Break Deus Ex Machina"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave": formation + groups; kind keys are KINDS aliases), plus the
## CitadelDirector's:
##   "gate"     — a Shield Gate rises across the necromancer's path (CITADEL.gate);
##                `garrison`: the groups that pour out of it every
##                gate.garrison_interval s while it holds.
##   "turrets"  — `count` Sentry Turrets `distance_min`..`distance_max` px around
##                the necromancer, with an optional `escort` wave.
##   "valkyrie" — the miniboss (`kind`) arrives with her `escort` groups.
const EVENTS := [
	# Zone I: the Shield Gates.
	{"time": 40.0, "type": "wave", "banner": "A drone swarm sweeps off the walls!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "drone", "count": 6, "elite": false}]},  # TUNING (not in GDD) balance pass 3: 10 -> 6
	{"time": 120.0, "type": "wave", "banner": "A firing line marches down from the walls!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "trooper", "count": 3, "elite": false}, {"kind": "drone", "count": 6, "elite": false}]},  # TUNING (not in GDD) balance pass 3: 4 -> 3 Troopers
	{"time": 200.0, "type": "gate", "banner": "A SHIELD GATE seals the way: destroy its two generators!",  # Owner-approved proposal: shield gates
		"garrison": [{"kind": "drone", "count": 3, "elite": false}]},  # TUNING (not in GDD) balance pass 3: 0:50 -> 3:20, drones only at the first gate (was 3 drones + a Trooper every 8 s)
	{"time": 215.0, "type": "wave", "banner": "A Spotter paints you from the battlements!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 1, "elite": false}, {"kind": "trooper", "count": 4, "elite": false}]},  # TUNING (not in GDD) balance pass 3: 6 -> 4 Troopers
	{"time": 245.0, "type": "wave", "banner": "Valkyrie Duelists lunge through your ring: keep a blocker between you!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "duelist", "count": 2, "elite": false}, {"kind": "drone", "count": 6, "elite": false}]},
	{"time": 265.0, "type": "wave", "banner": "The gate's guard closes in!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "trooper", "count": 8, "elite": false}, {"kind": "drone", "count": 10, "elite": false}, {"kind": "duelist", "count": 1, "elite": false}]},
	# Zone II (5:00): the Laser Courts.
	{"time": 330.0, "type": "gate", "banner": "A SHIELD GATE bars the courts: break its generators!",  # Owner-approved proposal: shield gates
		"garrison": [{"kind": "drone", "count": 2, "elite": false}, {"kind": "trooper", "count": 2, "elite": false}]},  # TUNING (not in GDD)
	{"time": 385.0, "type": "wave", "banner": "Two Spotter teams take the high courts!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 2, "elite": false}, {"kind": "trooper", "count": 8, "elite": false}, {"kind": "drone", "count": 8, "elite": false}]},
	{"time": 450.0, "type": "turrets", "banner": "Sentry emplacements rise from the court floor: siege them!", "count": 3,  # Owner-approved proposal: Sentry Turrets
		"distance_min": 240.0, "distance_max": 340.0,  # TUNING (not in GDD)
		"escort": {"formation": "arc", "groups": [{"kind": "trooper", "count": 4, "elite": false}]}},
	{"time": 490.0, "type": "wave", "banner": "The Empire's line advances!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "trooper", "count": 14, "elite": false}, {"kind": "spotter", "count": 2, "elite": false}, {"kind": "duelist", "count": 2, "elite": false}]},
	{"time": 560.0, "type": "wave", "banner": "A Valkyrie squad dives from the walls!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "duelist", "count": 4, "elite": false}, {"kind": "drone", "count": 8, "elite": false}]},
	# Zone III (10:00): the Spire Lifts.
	{"time": 615.0, "type": "gate", "banner": "THE LAST GATE guards the lifts: tear down its generators!",  # Owner-approved proposal: shield gates
		"garrison": [{"kind": "trooper", "count": 2, "elite": false}, {"kind": "duelist", "count": 1, "elite": false}, {"kind": "drone", "count": 2, "elite": false}]},  # TUNING (not in GDD)
	{"time": 680.0, "type": "wave", "banner": "Drones blot out the sky!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "drone", "count": 26, "elite": false}, {"kind": "trooper", "count": 8, "elite": true}]},
	{"time": 750.0, "type": "valkyrie", "banner": "VALKYRIE 2.0 descends on her jets: the Citadel's champion!", "kind": "valkyrie",  # Owner-approved proposal: the miniboss
		"escort": [{"kind": "duelist", "count": 2, "elite": false}]},  # TUNING (not in GDD)
	{"time": 820.0, "type": "turrets", "banner": "Sentry turrets lock onto the lifts!", "count": 3,  # TUNING (not in GDD)
		"distance_min": 260.0, "distance_max": 360.0,  # TUNING (not in GDD)
		"escort": {"formation": "arc", "groups": [{"kind": "spotter", "count": 1, "elite": false}, {"kind": "trooper", "count": 6, "elite": false}]}},
	{"time": 870.0, "type": "wave", "banner": "The lift guard surrounds you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "trooper", "count": 14, "elite": false}, {"kind": "duelist", "count": 3, "elite": false}, {"kind": "drone", "count": 12, "elite": false}]},
	# Zone IV (15:00): the Core.
	{"time": 905.0, "type": "wave", "banner": "THE CORE: the Empire's last legion stands before its god!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 3, "elite": false}, {"kind": "trooper", "count": 16, "elite": false}, {"kind": "duelist", "count": 3, "elite": false}]},
	{"time": 960.0, "type": "wave", "banner": "The last battalion!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "spotter", "count": 2, "elite": false}, {"kind": "trooper", "count": 18, "elite": false}, {"kind": "drone", "count": 16, "elite": false}]},
	# 17:00 Deus Ex Machina (BOSS_TIME), plus two sallies.
	{"time": 1080.0, "type": "wave", "banner": "The Citadel's guard rallies to its god!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "trooper", "count": 8, "elite": false}, {"kind": "duelist", "count": 2, "elite": false}]},
	{"time": 1150.0, "type": "wave", "banner": "Drones pour from the Core's vents!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "drone", "count": 16, "elite": false}, {"kind": "spotter", "count": 1, "elite": false}]},
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES
## plus the CitadelDirector's per-zone systems:
##   guns   — the Citadel's orbital strikes ({} = none): `first` s into the
##            zone, then every `interval` s (x boss_mult while the boss
##            fights) `count` strikes (one on the necromancer, the rest within
##            `scatter` px), `radius` px circles telegraphed `telegraph` s,
##            `damage` to him and `summon_damage` to each summon (time-scaled);
##            EmpireRules.strike(), the Purge Protocol's path.
##   lasers — the laser grid ({} = none): `first` s into the zone, then every
##            `interval` s a grid of `beams` parallel beams `spacing` px apart
##            and `length` px long across the necromancer's ground, telegraphed
##            `telegraph` s, then each sweeps `sweep` px in `sweep_time` s
##            (`width` px wide), hitting each body once: `damage_player`,
##            `damage_summon` (time-scaled) and `damage_enemy` (x the enemies'
##            HP scaling); the sweep normal turns through `angles` (degrees).
## `ground` is a CitadelGround look: style "gates" (dark riveted iron plates,
## amber trim), "courts" (polished court tiles cut by red grid lines), "lifts"
## (steel grating over the lift shafts, hazard stripes) or "core" (black floor
## veined with glowing circuit traces); base / line / accent / glow colours of
## the code floor (the tiles/citadel_<style> PNG replaces them when it exists).
## Obstacle kinds are drawn by CitadelGlyphs without art.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Shield Gates",  # Owner-approved proposal zone I
		"blurb": "Chrome walls and humming energy gates bar the way in",
		"ground": {"style": "gates", "base": Color(0.075, 0.085, 0.105), "line": Color(0.12, 0.13, 0.17),
			"accent": Color(0.20, 0.25, 0.32), "glow": Color(1.0, 0.682, 0.102)},
		"arena": {"density": 0.17, "clear_radius": 220.0, "layout_seed": 9101,  # TUNING (not in GDD)
			"kinds": {
				"iron_barricade": {"weight": 0.5, "shape": "rect", "sizes": [52.0, 68.0, 84.0], "short": 26.0},  # TUNING (not in GDD)
				"signal_bollard": {"weight": 0.5, "shape": "circle", "sizes": [11.0, 14.0, 17.0]},  # TUNING (not in GDD)
			}},
		"guns": {"first": 180.0, "interval": 16.0, "count": 1, "scatter": 220.0, "radius": 48.0, "telegraph": 1.5,  # TUNING (not in GDD) the guns wake after the first gate (balance pass 3: first 30 -> 180 s)
			"damage": 9.0, "summon_damage": 4.0, "boss_mult": 1.5},  # TUNING (not in GDD) passes 1-2: 16 -> 7 -> 4 on summons (undead do not dodge: the guns ate the ring, 22k summon damage a run)
		"lasers": {}},
	{"start": 300.0, "numeral": "II", "name": "The Laser Courts",  # Owner-approved proposal zone II
		"blurb": "Polished courts crossed by sweeping laser grids",
		"ground": {"style": "courts", "base": Color(0.085, 0.09, 0.11), "line": Color(0.30, 0.10, 0.07),
			"accent": Color(0.16, 0.18, 0.23), "glow": Color(0.878, 0.224, 0.118)},
		"arena": {"density": 0.14, "clear_radius": 220.0, "layout_seed": 9202,  # TUNING (not in GDD) open courts
			"kinds": {
				"emitter_pylon": {"weight": 0.55, "shape": "circle", "sizes": [12.0, 15.0, 18.0]},  # TUNING (not in GDD)
				"iron_barricade": {"weight": 0.45, "shape": "rect", "sizes": [52.0, 68.0, 84.0], "short": 26.0},  # TUNING (not in GDD)
			}},
		"guns": {"first": 12.0, "interval": 12.0, "count": 2, "scatter": 240.0, "radius": 48.0, "telegraph": 1.5,  # TUNING (not in GDD)
			"damage": 9.0, "summon_damage": 4.0, "boss_mult": 1.5},  # TUNING (not in GDD) passes 1-2: 16 -> 7 -> 4 on summons (undead do not dodge: the guns ate the ring, 22k summon damage a run)
		"lasers": {"first": 8.0, "interval": 9.0, "beams": 3, "spacing": 170.0, "length": 1500.0, "telegraph": 1.0,  # Owner-approved proposal: "telegraphed a second before they fire"
			"sweep": 60.0, "sweep_time": 0.5, "width": 10.0, "damage_player": 9.0, "damage_summon": 3.0, "damage_enemy": 30.0,  # TUNING (not in GDD) passes 1-2: 12 -> 5 -> 3 on summons (they cannot step out)
			"angles": [0.0, 90.0, 45.0, 135.0]}},
	{"start": 600.0, "numeral": "III", "name": "The Spire Lifts",  # Owner-approved proposal zone III
		"blurb": "Steel gratings over the lift shafts, the guns above",
		"ground": {"style": "lifts", "base": Color(0.07, 0.08, 0.095), "line": Color(0.14, 0.16, 0.20),
			"accent": Color(0.22, 0.27, 0.34), "glow": Color(1.0, 0.682, 0.102)},
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 9303,  # TUNING (not in GDD)
			"kinds": {
				"citadel_crate": {"weight": 0.5, "shape": "rect", "sizes": [48.0, 64.0, 80.0], "short": 30.0},  # TUNING (not in GDD)
				"lift_winch": {"weight": 0.5, "shape": "circle", "sizes": [13.0, 16.0, 19.0]},  # TUNING (not in GDD)
			}},
		"guns": {"first": 10.0, "interval": 9.0, "count": 2, "scatter": 260.0, "radius": 50.0, "telegraph": 1.4,  # TUNING (not in GDD) faster deeper in
			"damage": 10.0, "summon_damage": 4.0, "boss_mult": 1.5},  # TUNING (not in GDD) passes 1-2: 18 -> 8 -> 4
		"lasers": {}},
	{"start": 900.0, "numeral": "IV", "name": "The Core",  # Owner-approved proposal zone IV
		"blurb": "A black floor veined with light around the god the Empire built",
		"ground": {"style": "core", "base": Color(0.06, 0.065, 0.085), "line": Color(0.10, 0.12, 0.16),
			"accent": Color(0.15, 0.18, 0.24), "glow": Color(1.0, 0.682, 0.102)},
		"arena": {"density": 0.1, "clear_radius": 240.0, "layout_seed": 9404,  # TUNING (not in GDD) sparse: the boss arena
			"kinds": {
				"core_conduit": {"weight": 1.0, "shape": "circle", "sizes": [12.0, 15.0]},  # TUNING (not in GDD)
			}},
		"guns": {"first": 8.0, "interval": 7.0, "count": 3, "scatter": 280.0, "radius": 50.0, "telegraph": 1.4,  # TUNING (not in GDD) the guns at their fastest ("more often the deeper you go")
			"damage": 10.0, "summon_damage": 4.0, "boss_mult": 1.6},  # TUNING (not in GDD) passes 1-2: 18 -> 8 -> 4
		"lasers": {"first": 14.0, "interval": 13.0, "beams": 2, "spacing": 210.0, "length": 1500.0, "telegraph": 1.0,  # TUNING (not in GDD) rarer in the Core
			"sweep": 60.0, "sweep_time": 0.5, "width": 10.0, "damage_player": 9.0, "damage_summon": 3.0, "damage_enemy": 30.0,  # TUNING (not in GDD) passes 1-2: 12 -> 5 -> 3 on summons (they cannot step out)
			"angles": [45.0, 135.0, 0.0, 90.0]}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "THE CITADEL OPENS  -  ZONE %s",
	"zone_color": Color(1.0, 0.682, 0.102),  # Signal amber (Palette.EMPIRE_SIGNAL_AMBER).
	"fog_color": Color(0.04, 0.05, 0.07),  # Cold smoke.
	"fog_bank_color": Color(0.16, 0.19, 0.24),  # Chrome-grey smoke banks.
	"zones": ZONES,
}

## The fortress's systems (CitadelDirector; StageRegistry "citadel").
##   zones           — the ZONES list (each zone's guns and lasers).
##   gate            — Shield Gates:
##     distance         px ahead of the necromancer the wall rises (along his
##                      movement, a random direction when he stands still).
##     wall_length / wall_thickness — px; the wall is solid for the necromancer.
##     generator_back   px the generators stand behind the wall's ends.
##     turrets / turret_spread / turret_back — Sentry Turrets placed behind the
##                      wall (count, px apart along it, px behind it).
##     garrison_first / garrison_interval — s to the first garrison squad / between two.
##     active_radius    px; the garrison pours out only while he is this close.
##     despawn_distance px; a gate left this far behind powers down (no reward).
##     reward_xp / reward_crystals / ash — what breaking it pays.
##     lockdown_groups  the last wave of a gate still holding at its zone's end.
##     lockdown_gun_mult gun interval x this for the next zone after a lockdown.
##   turrets         — Sentry Turrets: max_alive at once, despawn_distance px.
##   guest_first / guest_interval / guest_until — game s of the first guest squad,
##                     between two, and the last one.
##   guest_count / guest_growth / guest_max — kinds per squad: count +
##                     floor(squads x growth), at most guest_max.
##   guests          — the earlier Act III stages' kinds, each a list of candidate
##                     kind ids (the first one this build knows; none = skipped)
##                     and a weight. Their melee kinds (Aegis Bot, Juggernaut)
##                     weigh most: they carry the act's melee share.
const CITADEL := {
	"zones": ZONES,
	"gate": {
		"distance": 300.0,  # TUNING (not in GDD) px, about half a screen ahead
		"wall_length": 460.0,  # TUNING (not in GDD) px: going round is a real detour
		"wall_thickness": 18.0,  # TUNING (not in GDD) px
		"generator_back": 18.0,  # TUNING (not in GDD) px
		"turrets": 1,  # Owner-approved proposal: "fixed emplacements behind shield walls"; TUNING (not in GDD) balance pass 3: 2 -> 1 (the first gate's pair shot the naive bot down in its second minute)
		"turret_spread": 170.0,  # TUNING (not in GDD) px
		"turret_back": 90.0,  # TUNING (not in GDD) px
		"garrison_first": 4.0,  # TUNING (not in GDD) s
		"garrison_interval": 14.0,  # TUNING (not in GDD) s ("enemies pour out of the gate while it holds"); balance pass 3: 8 -> 14 (the first gate's drones shot the starting army's necromancer down by 2:20)
		"active_radius": 900.0,  # TUNING (not in GDD) px
		"despawn_distance": 1800.0,  # TUNING (not in GDD) px
		"reward_xp": 40,  # TUNING (not in GDD)
		"reward_crystals": 8,  # TUNING (not in GDD)
		"ash": 10,  # TUNING (not in GDD) Soul Ash per gate broken (objective_ash)
		"lockdown_groups": [{"kind": "trooper", "count": 8, "elite": false}, {"kind": "duelist", "count": 2, "elite": false}, {"kind": "drone", "count": 8, "elite": false}],  # TUNING (not in GDD)
		"lockdown_gun_mult": 0.65,  # TUNING (not in GDD) the next zone's guns fire about 1.5x as often
	},
	"turrets": {
		"max_alive": 8,  # TUNING (not in GDD)
		"despawn_distance": 1700.0,  # TUNING (not in GDD) px
	},
	"guest_first": 150.0,  # TUNING (not in GDD)
	"guest_interval": 75.0,  # TUNING (not in GDD)
	"guest_until": 1000.0,  # TUNING (not in GDD) the boss fight keeps its own roster
	"guest_count": 3,  # TUNING (not in GDD)
	"guest_growth": 0.4,  # TUNING (not in GDD)
	"guest_max": 8,  # TUNING (not in GDD)
	"guests": [
		{"ids": ["aegis_bot"], "weight": 1.2},  # The Scrap Wastes (Act III phase 2): melee shield bots
		{"ids": ["mortar_walker"], "weight": 0.5},
		{"ids": ["arc_engineer"], "weight": 0.5},  # The Assembly Halls (Act III phase 2)
		{"ids": ["juggernaut"], "weight": 0.6},
	],
}

## Deus Ex Machina's arrival (keys as GraveyardStage.BOSS): its own
## DeusData.ARRIVAL (boss id "deus_ex_machina", the ending text as the defeat
## banner), whose `time` equals BOSS_TIME (17:00).
const BOSS: Dictionary = DeusData.ARRIVAL

## Floor look of the placeholder "empire" ground (EmpireGround; the stage now
## uses CitadelGround and its ZONES, this stays for any caller of "floor").
const FLOOR := {
	"style": "citadel",  # Dark iron panels with glowing signal lines.
	"base": Color(0.075, 0.08, 0.10),  # TUNING (not in GDD) dark iron
	"line": Color(0.12, 0.13, 0.17),  # TUNING (not in GDD)
	"accent": Color(0.26, 0.31, 0.39),  # TUNING (not in GDD) chrome scrap plates
	"trim": Color(1.0, 0.682, 0.102),  # TUNING (not in GDD) signal amber
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Iron Citadel",
	"short_name": "Iron Citadel",
	"chapter": "Chapter IX",
	"act": 3,  # Act III, the Electronic Empire.
	"playable": false,  # Built (Act III phase 2); the lead flips it after the multi-seed check and the owner's playtest.
	"description": "The Empire's throne of iron, where death was conquered with steel. Varn, the Root User, waits at its summit inside Deus Ex Machina, the god it built.",
	"unlock": {"stage": "assembly", "boss_kills": 1},  # Owner-approved: each boss unlocks the next stage
	"unlock_text": "Shut down the Motherboard in the Assembly Halls to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act III stages.
	"consecration": {},  # A Covenant event: none in Act III.
	"crypt_defender": {},  # None in Act III.
	"arena": ZONES[0]["arena"],
	"ground": "citadel",  # CitadelGround (the four zone floors).
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,
	"citadel": CITADEL,  # CitadelDirector (gates, lasers, guns, turrets, Valkyrie 2.0, guests).
	"kind_aliases": KINDS,
	"empire": true,  # Act III: Line of Fire, Lock-On, Steel has no soul (EmpireRules).
	"music": "iron",  # Act III run loop "Iron Requiem" (RunLoopSynth).
}
