## LibertyHeightsStage — STAGE 24, LIBERTY HEIGHTS, the finale of Act VIII (the
## Last Line; GDD §15.0 "Act VIII foundation (phase 1)" and "Liberty Heights
## (Act VIII phase 2)"; owner-approved proposal docs/act8/PROPOSAL.md "Stage
## 24: Liberty Heights (the finale)"; brief docs/act8/BRIEF_PHASE2.md Agent C).
## The heart of the city: the plaza, the skyline and the Heroes' Tower, where
## the last heroes of the living make their stand. Every number and event that
## belongs to this stage; StageRegistry exposes it to the run as
## `Game.stage_def` (the STAGE dictionary at the bottom; its keys are
## documented in StageRegistry). Unlocked by defeating General Harrow at Fort
## Kessler.
##
## CITY BLOCKS ("blocks": a grid of buildings with streets and alleys,
## CityBlocks through Arena; the `tower` roof style and more open lots: plazas
## and parks) and the Last Line's three shared rules ("city": Armour, Supers,
## Civilians). THE CLOCK IS AUTHORITATIVE, as on every zoned stage: four zones
## on fixed times (ZONES, run by MarchDirector: a zone banner and new looks
## over the same streets, CityBlocks.set_zone()). The ESCALATION starts high
## (the proposal's "Stage 24 starts at 4 and reaches 5"): Act VIII pass 2,
## owner "Later army on Liberty Heights": police 0:00, SWAT 2:30, the army 5:00
## (was 0:00), the heroes from 15:00 (ESCALATION); the civilians' trickle now
## runs until 5:00 and the timeline spawns only the reached tiers' kinds (the
## police and SWAT first, then the army's kinds: the stage's own Conscripts, rifle squads of 4, tanks; Fort Kessler's
## Machine Gunners and Attack Helicopters as guests, merged at the integration):
##   20:00  Zone I,   the Plaza:       BLITZ leads the heroes (17:30)
##   15:00  Zone II,  the Rooftops:    AURORA, who flies (13:30)
##   10:00  Zone III, the Tower Lobby: ATLAS, who throws wrecks (8:30)
##    5:00  Zone IV,  the Watchtower:  the heroes tier; NIGHTJAR comes with it
##    3:00  PARAGON, THE LAST HERO (BossParagon, ParagonData): the Hero, Hope
##          (every roster Super not yet killed flies to his side), No Restraint
##    0:00  MARTIAL LAW (the shared Act VIII Reckoning; the met Supers return)
## Each zone's Super is its miniboss (LibertyHeightsDirector: the roster's next
## through SuperRoster.call_next(), promoted to the zone's leader).
## Every rate, cap and weight is TUNING (not in GDD) unless marked as the
## owner-approved proposal.
class_name LibertyHeightsStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "liberty_heights"

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act VIII starts a step above Castle Sanguis's 1.85; the step goes in HP,
## not damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 2.0  # TUNING (not in GDD) the foundation's placeholder, kept; tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling
## (Castle Sanguis's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.3  # TUNING (not in GDD) was 1.5 (the foundation's placeholder); Act VIII pass 3, owner: Stage damage x1.3
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) (Acts III to VII: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 3 of Act VIII

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES.
## `arena` is a city-block zone layout: its "blocks" dictionary changes only
## the looks over the stage's grid (rooftop styles, the open-lot share and its
## looks; CityBlocks.set_zone(): a zone never moves a street). `ground` is
## unused by the placeholder CityGround (kept for the shared keys; the floor is
## drawn from the blocks).
const ZONES := [
	{"id": "plaza", "start": 0.0, "numeral": "I", "name": "The Plaza",  # Owner-approved proposal zone I
		"blurb": "Fountains and bare flagpoles under the lit towers of the city's heart",
		"ground": {"style": "downtown"},
		"arena": {"density": 0.0, "clear_radius": 120.0, "layout_seed": 2424, "kinds": {},  # TUNING (not in GDD)
			"blocks": {"styles": {"tower": 0.5, "tenement": 0.5}, "open_share": 0.3,  # TUNING (not in GDD) brief: more open lots (plazas)
				"open_styles": {"plaza": 0.7, "park": 0.25, "parking": 0.05}}},
	},
	{"id": "rooftops", "start": 300.0, "numeral": "II", "name": "The Rooftops",  # Owner-approved proposal zone II
		"blurb": "The skyline itself: towers shoulder to shoulder, and a flier overhead",
		"ground": {"style": "downtown"},
		"arena": {"density": 0.0, "clear_radius": 220.0, "layout_seed": 2424, "kinds": {},  # TUNING (not in GDD)
			"blocks": {"styles": {"tower": 0.85, "tenement": 0.15}, "open_share": 0.22,  # TUNING (not in GDD) taller, denser
				"open_styles": {"plaza": 0.5, "parking": 0.3, "park": 0.2}}},
	},
	{"id": "tower_lobby", "start": 600.0, "numeral": "III", "name": "The Tower Lobby",  # Owner-approved proposal zone III
		"blurb": "The Heroes' Tower's forecourt: wide marble plazas and wrecked cars",
		"ground": {"style": "downtown"},
		"arena": {"density": 0.0, "clear_radius": 220.0, "layout_seed": 2424, "kinds": {},  # TUNING (not in GDD)
			"blocks": {"styles": {"tower": 1.0}, "open_share": 0.3,  # TUNING (not in GDD) open forecourts for Atlas's throws
				"open_styles": {"plaza": 0.8, "park": 0.2}}},
	},
	{"id": "watchtower", "start": 900.0, "numeral": "IV", "name": "The Watchtower",  # Owner-approved proposal zone IV
		"blurb": "The vigilante's perch above the last lit streets of the living",
		"ground": {"style": "downtown"},
		"arena": {"density": 0.0, "clear_radius": 240.0, "layout_seed": 2424, "kinds": {},  # TUNING (not in GDD)
			"blocks": {"styles": {"tower": 0.7, "tenement": 0.3}, "open_share": 0.25,  # TUNING (not in GDD) brief: 25% open lots
				"open_styles": {"plaza": 0.6, "park": 0.3, "parking": 0.1}}},
	},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 220.0,  # TUNING (not in GDD) px (no building within it around the necromancer)
	"zone_title": "LIBERTY HEIGHTS  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Palette.CITY_HERO_ORANGE,  # The heroes' bright orange.
	"fog_color": Color(0.07, 0.07, 0.09),  # Night smoke.
	"fog_bank_color": Color(0.32, 0.34, 0.40),  # Smoke between the towers.
	"zones": ZONES,
}

## The stage's city-block grid: {} = CityBlockData.DEFAULTS (any key overrides
## it here; the grid keys only here, never per zone).
const BLOCKS := {}
## The escalation on this stage (owner-approved proposal: "Stage 24 starts at
## 4 and reaches 5"; phase 2 answers: "Only Liberty Heights reaches the
## heroes"; the lead's suggestion, kept): the army from 0:00, the heroes from
## 15:00 (the Watchtower: its Super comes with the tier; a Super every 90 s
## after it while none stands, the proposal's five stars).
const ESCALATION := {
	"times": {"police": 0.0, "swat": 150.0, "army": 300.0, "heroes": 900.0},  # Act VIII pass 2, owner: Later army on Liberty Heights: police 0:00, SWAT 2:30, army 5:00, heroes 15:00 (was army 0:00, heroes 15:00; the brief's lead suggestion)
	"last": "heroes",  # Owner (Nov 2): only Liberty Heights reaches the heroes
}
## The civilians on this stage: {} = CityRulesData.CIVILIANS (the opening
## crowd at 0:00; the trickle stops at once with the army tier).
const CIVILIANS := {}
## The Supers the escalation sends here, in turn (brief: the roster, also the
## zones' order: the Plaza, the Rooftops, the Tower Lobby, the Watchtower).
const SUPERS: Array[String] = ["blitz", "aurora", "atlas", "nightjar"]

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): MARTIAL LAW,
## shared by every Act VIII stage: every tier's kinds at once (the tank as the
## heavy, a thug, a riot cop, a breacher and a rifleman squad as companions),
## artillery lines walking along the streets ("martial_law":
## CityRulesData.MARTIAL_LAW keys; {} = those defaults), and every Super the
## run met returns, one every 20 s.
const RECKONING := {
	"banner": "MARTIAL LAW: THE CITY BREAKS ITS LAST LINE ON YOU",
	"kind": CityEnemyData.TANK,  # The shared Martial Law heavy.
	"martial_law": {},  # CityRulesData.MARTIAL_LAW defaults.
	"companions": [{"kind": CityEnemyData.STREET_THUG, "count": 4, "growth": 1.0},  # TUNING (not in GDD) the gangs
		{"kind": CityEnemyData.RIOT_COP, "count": 2, "growth": 0.5},  # TUNING (not in GDD) the police
		{"kind": CityEnemyData.SWAT_BREACHER, "count": 1, "growth": 0.5},  # TUNING (not in GDD) SWAT
		{"kind": CityEnemyData.RIFLEMAN, "count": 4, "growth": 0.5}],  # TUNING (not in GDD) the army (a squad)
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 1,  # TUNING (not in GDD) tanks are heavy
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "MARTIAL LAW: every soldier in the city, the artillery and the heroes. Endure."

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): the army's
## kinds only (the brief: "your timeline spawns only your tiers' kinds"):
## Conscripts as the fodder, riflemen (squads come as events), tanks rare (a
## first pass at 0.02-0.03 of the trickle sent 97 tanks in the seed-7 army run,
## the top killer of the ring).
const SEGMENTS := [
	# Zone I, the Plaza.
	# Act VIII pass 2, owner: Later army on Liberty Heights: the police (0:00), SWAT (2:30), then the army (5:00); before, the army from 0:00.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD) Act VIII pass 2, owner: Later army on Liberty Heights: was conscripts 1.0 from 0:00
		"weights": {"riot_cop": 1.0},
		"objective": "The Plaza: the police hold the square. The fleeing crowd is XP"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD) Act VIII pass 2, owner: Later army on Liberty Heights: was conscript 0.82 / rifleman 0.18
		"weights": {"riot_cop": 0.97, "squad_car": 0.03},
		"objective": "Shields to the front: flank the riot line"},
	{"start": 150.0, "rate": 1.9, "max_alive": 46,  # TUNING (not in GDD) Act VIII pass 2, owner: Later army on Liberty Heights: SWAT at 2:30 (was the army's 1.7 / 40 until 3:00)
		"weights": {"riot_cop": 0.78, "swat_breacher": 0.15, "field_medic": 0.05, "squad_car": 0.02},
		"objective": "SWAT: flashbangs stun your dead. Kill the breachers and the medics first"},
	{"start": 300.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD) Act VIII pass 2, owner: Later army on Liberty Heights: the army at 5:00 starts at the old 3:00 step (was rate 2.3 / 60 at 5:00)
		"weights": {"conscript": 0.732, "rifleman": 0.26, "tank": 0.008},
		"objective": "The army marches in. Blitz can't turn: a wall, a wreck or a blocker stops him cold"},
	# Zone II, the Rooftops (the second step of the army, 6:00 here).
	{"start": 360.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"conscript": 0.692, "rifleman": 0.3, "tank": 0.008},
		"objective": "The Rooftops: a flier rules the sky. Stun her and she falls"},  # Act VIII pass 2, owner: Later army on Liberty Heights: start 5:00 -> 6:00
	{"start": 480.0, "rate": 2.5, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"conscript": 0.67, "rifleman": 0.32, "tank": 0.01},
		"objective": "Tanks have front armour: hit them from the side, or let them ram a wreck"},
	# Zone III, the Tower Lobby.
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"conscript": 0.66, "rifleman": 0.33, "tank": 0.01},
		"objective": "The Tower Lobby: the strongman lifts wrecks. Stun him while he winds up"},
	# Zone IV, the Watchtower.
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"conscript": 0.64, "rifleman": 0.35, "tank": 0.01},
		"objective": "The Watchtower: the vigilante must land to strike. Hold him with a blocker"},
	# 17:00, the boss: a thinner trickle so the fight stays readable.
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"conscript": 0.672, "rifleman": 0.32, "tank": 0.008},
		"objective": "Paragon has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Riflemen come in
## squads of 4 (owner-approved proposal).
const EVENTS := [
	# Zone I: the Plaza.
	{"time": 20.0, "type": "wave", "banner": "The riot police pour into the plaza!", "formation": "ring",  # TUNING (not in GDD) Act VIII pass 2, owner: Later army on Liberty Heights: was 14 conscripts
		"groups": [{"kind": "riot_cop", "count": 14, "elite": false}]},
	{"time": 100.0, "type": "wave", "banner": "A police line advances across the square!", "formation": "line",  # TUNING (not in GDD) Act VIII pass 2, owner: Later army on Liberty Heights: was a rifle squad of 4 and 8 conscripts
		"groups": [{"kind": "riot_cop", "count": 12, "elite": false}]},
	{"time": 210.0, "type": "wave", "banner": "SWAT breaches the fountains!", "formation": "arc",  # TUNING (not in GDD) Act VIII pass 2, owner: Later army on Liberty Heights: was a tank and 4 riflemen
		"groups": [{"kind": "swat_breacher", "count": 3, "elite": false}, {"kind": "field_medic", "count": 1, "elite": false}, {"kind": "riot_cop", "count": 6, "elite": false}]},
	{"time": 270.0, "type": "wave", "banner": "SWAT holds the plaza!", "formation": "ring",  # TUNING (not in GDD) Act VIII pass 2, owner: Later army on Liberty Heights: was 8 riflemen and 6 conscripts
		"groups": [{"kind": "swat_breacher", "count": 4, "elite": false}, {"kind": "riot_cop", "count": 8, "elite": false}]},
	# Zone II (5:00): the Rooftops.
	{"time": 330.0, "type": "wave", "banner": "The Guard drops from the skyline!", "formation": "ring",  # TUNING (not in GDD) Act VIII pass 2, owner: Later army on Liberty Heights: 5:30, the army is here from 5:00 (unchanged)
		"groups": [{"kind": "conscript", "count": 14, "elite": false}, {"kind": "rifleman", "count": 4, "elite": false}]},
	{"time": 450.0, "type": "wave", "banner": "Armour between the towers!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "tank", "count": 1, "elite": false}, {"kind": "rifleman", "count": 4, "elite": false}]},
	{"time": 540.0, "type": "wave", "banner": "Rifle squads on every corner!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "rifleman", "count": 8, "elite": false}, {"kind": "conscript", "count": 10, "elite": false}]},
	# Zone III (10:00): the Tower Lobby.
	{"time": 640.0, "type": "wave", "banner": "The Tower's guard charges with bayonets!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "conscript", "count": 18, "elite": false}]},
	{"time": 750.0, "type": "wave", "banner": "Two tanks guard the forecourt!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "tank", "count": 2, "elite": false}, {"kind": "rifleman", "count": 4, "elite": false}]},
	{"time": 840.0, "type": "wave", "banner": "Two rifle squads and a column of the Guard!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "rifleman", "count": 8, "elite": false}, {"kind": "conscript", "count": 10, "elite": false}]},
	# Zone IV (15:00): the Watchtower.
	{"time": 930.0, "type": "wave", "banner": "The city throws everything it has!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "rifleman", "count": 8, "elite": false}, {"kind": "tank", "count": 1, "elite": false}, {"kind": "conscript", "count": 12, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The last line forms before the Tower!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "conscript", "count": 16, "elite": false}, {"kind": "rifleman", "count": 4, "elite": false}]},
	# 17:00 Paragon (BOSS_TIME), plus two sallies.
	{"time": 1090.0, "type": "wave", "banner": "The Guard rallies to the Last Hero!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "rifleman", "count": 4, "elite": false}, {"kind": "conscript", "count": 12, "elite": false}]},
	{"time": 1160.0, "type": "wave", "banner": "Tanks roll in behind Paragon!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "tank", "count": 1, "elite": false}, {"kind": "rifleman", "count": 4, "elite": false}]},
]

## Liberty Heights's systems (LibertyHeightsDirector; StageRegistry
## "liberty_heights").
##   zone_supers — THE ZONE SUPERS, in the zones' (and the roster's) order:
##       id         — the Super leading the zone (a STAGE "supers" id);
##       time       — game s it is brought (SuperRoster.call_next());
##       escalation — true: the heroes tier brings it itself (the escalation's
##                    own call at its "heroes" time), the director only
##                    promotes it;
##       banner     — shown as it is promoted to the zone's leader;
##       objective  — the HUD objective while it leads.
##   leader_hp_mult — x the health of a promoted zone leader (a miniboss).
##   leaders_until  — game s after which no Super is promoted (Paragon's Hope
##       calls the rest as his allies, not as minibosses).
##   guest_* / guests — Fort Kessler's army kinds in small squads (as
##       CastleSanguisStage.CASTLE_SANGUIS): candidate ids per kind (the first
##       one this build knows; none = skipped) and a weight. The ids were
##       guessed while the three Act VIII stages were built in parallel; check
##       them at the Act VIII integration against CityEnemyData.
const LIBERTY_HEIGHTS := {
	"zone_supers": [
		{"id": "blitz", "time": 150.0,  # TUNING (not in GDD) 2:30 in the Plaza
			"banner": "BLITZ leads the heroes in the Plaza! Fast, but he can't turn: let him run into a wall",
			"objective": "Blitz: a wall, a wreck or a blocker in his line stops him cold. Then strike"},
		{"id": "aurora", "time": 390.0,  # TUNING (not in GDD) 6:30 on the Rooftops
			"banner": "AURORA rules the Rooftops! She flies... until a stun drops her out of the sky",
			"objective": "Aurora: stun her to bring her down, then strike while she is grounded"},
		{"id": "atlas", "time": 690.0,  # TUNING (not in GDD) 11:30 in the Tower Lobby
			"banner": "ATLAS guards the Tower Lobby! Strong, but slow to throw: stun him while he winds up",
			"objective": "Atlas: stun him during his long wind-up and he drops the car"},
		{"id": "nightjar", "time": 900.0, "escalation": true,  # Brief: the Watchtower's Super; it comes with the heroes tier at 15:00
			"banner": "NIGHTJAR swoops from the Watchtower! He grapples your dead, but he must land to strike",
			"objective": "Nightjar: when he lands, put a blocker on him"},
	],
	"leader_hp_mult": 1.25,  # TUNING (not in GDD) a zone's leader is a miniboss
	"leaders_until": BOSS_TIME,  # TUNING (not in GDD) Paragon's Hope calls the rest as allies
	"guest_first": 420.0,  # TUNING (not in GDD) no guests before 7:00
	"guest_interval": 80.0,  # TUNING (not in GDD)
	"guest_until": 1000.0,  # TUNING (not in GDD) the boss fight keeps its own roster
	"guest_count": 2,  # TUNING (not in GDD)
	"guest_growth": 0.25,  # TUNING (not in GDD)
	"guest_max": 4,  # TUNING (not in GDD)
	"guests": [
		{"ids": ["machine_gunner"], "weight": 0.6},  # Fort Kessler (Act VIII phase 2): the Machine Gunner (id checked at the integration: a real CityEnemyData row)
		{"ids": ["attack_helicopter"], "weight": 0.4},  # Fort Kessler: the Attack Helicopter (id checked at the integration: a real CityEnemyData row)
	],
}

## Obstacle layout of the first zone (keys as GraveyardStage.ARENA; every zone
## has its own in ZONES): CITY BLOCKS ("blocks": the Plaza's looks over the
## STAGE BLOCKS grid). With "blocks" Arena asks CityBlocks instead of the
## per-cell scatter, so "density" and "kinds" are unused.
const ARENA: Dictionary = ZONES[0]["arena"]

## Paragon's arrival (keys as GraveyardStage.BOSS): ParagonData.ARRIVAL (boss id
## "paragon", the ending line as the defeat banner), whose `time` equals
## BOSS_TIME (17:00). His script is scripts/enemies/city/boss_paragon.gd (found
## by the boss id).
const BOSS: Dictionary = ParagonData.ARRIVAL

## Floor look of the placeholder CityGround (code-drawn from the CityBlocks
## geometry, with the art pass's city tiles): its style and colours.
const FLOOR := {
	"style": "downtown",  # Downtown: clean asphalt, bright crosswalks, plaza paving.
	"asphalt": Palette.CITY_ASPHALT,  # TUNING (not in GDD)
	"sidewalk": Palette.CITY_CONCRETE,  # TUNING (not in GDD)
	"lane": Palette.CITY_SODIUM,  # TUNING (not in GDD) fresh sodium-orange lane lines
	"accent": Palette.CITY_NEON_CYAN,  # TUNING (not in GDD) the skyline's cyan neon
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Liberty Heights",
	"short_name": "Liberty Heights",
	"chapter": "Chapter XXIV",
	"act": 8,  # Act VIII, the Last Line.
	"playable": true,  # Owner decision (Nov 2026): "Ship it" after the art reviews and playtest passes (GDD §15.0 "Acts VI–IX go live").
	"description": "The heart of the city: the plaza, the skyline and the Heroes' Tower, where the last heroes of the living make their stand.",
	"unlock": {"stage": "fort_kessler", "boss_kills": 1},  # Owner-approved: each Act VIII stage opens the next
	"unlock_text": "Defeat General Harrow at Fort Kessler to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act VIII stages.
	"consecration": {},  # A Covenant event: none in Act VIII.
	"crypt_defender": {},  # None in Act VIII.
	"arena": ARENA,
	"ground": "city",  # CityGround (drawn from the city blocks).
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"liberty_heights": LIBERTY_HEIGHTS,  # LibertyHeightsDirector (the zone Supers, guests, the cracks).
	"city": true,  # Act VIII: Armour, Supers, Civilians, the escalation (CityRules).
	"blocks": BLOCKS,  # Act VIII: the city-block grid (CityBlocks; {} = the defaults).
	"escalation": ESCALATION,  # Act VIII: the army from 0:00, the heroes from 15:00.
	"civilians": CIVILIANS,  # Act VIII: this stage's civilians overrides ({} = the defaults).
	"supers": SUPERS,  # Act VIII: the roster (the zones' order).
	"zones": ZONES,  # The four zones (MarchDirector reads them through "march").
	"music": "siren",  # Act VIII: "Sirens at Midnight" (SoundData.SIREN_SCORE); also renders the City pack.
}
