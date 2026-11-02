## LibertyHeightsStage — STAGE 24, LIBERTY HEIGHTS (Act VIII, the Last Line; GDD §15.0 "Act
## VIII foundation (phase 1)", owner-approved proposal docs/act8/PROPOSAL.md
## "Stage 24: Liberty Heights (the finale)"). The heart of the city: the
## plaza, the skyline and the Heroes' Tower.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (Act VIII phase 1). The stage is registered, unlocked
## in the campaign chain, laid out as CITY BLOCKS ("blocks": a grid of
## buildings with streets and alleys, CityBlocks through Arena), runs the Last
## Line's three shared rules ("city": true: Armour, Supers, Civilians) on the
## full default escalation ladder (gangs -> police -> SWAT -> army -> heroes;
## "escalation": {} = the defaults, so every rule shows), and plays a simple
## timeline of the shared kinds against a PLACEHOLDER boss script (the "vael"
## boss script under Paragon's name), with the Martial Law Reckoning (every
## tier at once, artillery lines along the streets, the met Supers return;
## tanks). It is hidden from the stage select ("playable": false) until phase 2
## builds it: the Supers leading each zone (Blitz, Atlas, Aurora, Nightjar),
## Paragon, the Last Hero (the Hero, Hope, No Restraint), and its ladder from
## the army to the heroes.
## Planned zones (ZONES; clock-driven like every stage): The Plaza, The
## Rooftops, The Tower Lobby, The Watchtower.
## Paragon arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD).
class_name LibertyHeightsStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "liberty_heights"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act VIII starts a step above Castle Sanguis's 1.85; the step goes in HP,
## not damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 2.0  # TUNING (not in GDD) brief: HP x2.0; tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling
## (Castle Sanguis's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) brief: damage 1.5
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Acts III to VII: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 3 of Act VIII

## The four zones phase 2 builds (names from the owner-approved proposal), each
## from `start` game seconds. The stub has one placeholder floor and one
## block layout (a zone change keeps the grid: CityBlocks).
const ZONES := [
	{"id": "plaza", "name": "The Plaza", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "rooftops", "name": "The Rooftops", "start": 300.0},  # The Rooftops
	{"id": "tower_lobby", "name": "The Tower Lobby", "start": 600.0},  # The Tower Lobby
	{"id": "watchtower", "name": "The Watchtower", "start": 900.0},  # The Watchtower
]

## The stage's city-block grid: {} = CityBlockData.DEFAULTS (any key overrides
## it here; the grid keys only here, never per zone).
const BLOCKS := {}
## The escalation on this stage: {} = CityRulesData.ESCALATION (the full
## ladder; phase 2 starts Liberty Heights at the army).
const ESCALATION := {}
## The civilians on this stage: {} = CityRulesData.CIVILIANS.
const CIVILIANS := {}
## The Supers the escalation sends here, in turn (phase 2: the stage's own).
const SUPERS: Array[String] = ["blitz"]

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): MARTIAL LAW,
## shared by every Act VIII stage: every tier's kinds at once (the tank as the
## heavy, a thug, a riot cop, a breacher and a rifleman squad as companions),
## artillery lines walking along the streets ("martial_law":
## CityRulesData.MARTIAL_LAW keys; {} = those defaults), and every Super the
## run met returns, one every 20 s.
const RECKONING := {
	"banner": "MARTIAL LAW: THE CITY BREAKS ITS LAST LINE ON YOU",
	"kind": CityEnemyData.TANK,  # The shared Martial Law heavy.
	"martial_law": {},  # CityRulesData.MARTIAL_LAW defaults (phase 2 may tune them here).
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

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): the shared
## kinds on the escalation clock (placeholder). Vehicles stay rare.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"street_thug": 1.0},
		"objective": "The Plaza: the crowds scatter. Each civilian you catch is XP"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"street_thug": 0.7, "gang_gunner": 0.3},
		"objective": "Gang gunners spray from the hip: blockers soak it"},
	{"start": 240.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD) the police
		"weights": {"street_thug": 0.45, "gang_gunner": 0.25, "riot_cop": 0.28, "squad_car": 0.02},
		"objective": "The police: shields to the front. Flank the line; keep out of the headlights"},
	{"start": 480.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD) SWAT and the Guard
		"weights": {"street_thug": 0.35, "gang_gunner": 0.2, "riot_cop": 0.25, "swat_breacher": 0.13, "field_medic": 0.05, "squad_car": 0.02},
		"objective": "SWAT: flashbangs stun your dead. Kill the breachers and the medics first"},
	{"start": 720.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD) the army
		"weights": {"street_thug": 0.25, "gang_gunner": 0.15, "riot_cop": 0.2, "swat_breacher": 0.13, "field_medic": 0.05, "rifleman": 0.2, "squad_car": 0.01, "tank": 0.01},
		"objective": "The army: rifle squads and tanks. Let a tank ram a wreck"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD) the heroes
		"weights": {"street_thug": 0.22, "gang_gunner": 0.13, "riot_cop": 0.2, "swat_breacher": 0.14, "field_medic": 0.05, "rifleman": 0.24, "squad_car": 0.01, "tank": 0.01},
		"objective": "The heroes: read a Super's weakness, then strike"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"street_thug": 0.25, "gang_gunner": 0.15, "riot_cop": 0.2, "swat_breacher": 0.13, "field_medic": 0.05, "rifleman": 0.2, "squad_car": 0.01, "tank": 0.01},
		"objective": "Paragon has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS), on the
## escalation clock. Riflemen come in squads of 4 (owner-approved proposal).
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A gang spills out of the alleys!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "street_thug", "count": 14, "elite": false}]},
	{"time": 120.0, "type": "wave", "banner": "Gunners on the corner!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "gang_gunner", "count": 6, "elite": false}, {"kind": "street_thug", "count": 8, "elite": false}]},
	{"time": 250.0, "type": "wave", "banner": "A police line forms up! Flank the shields!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "riot_cop", "count": 6, "elite": false}]},
	{"time": 300.0, "type": "wave", "banner": "Squad cars! Keep out of the headlights!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "squad_car", "count": 2, "elite": false}, {"kind": "riot_cop", "count": 3, "elite": false}]},
	{"time": 490.0, "type": "wave", "banner": "SWAT breaches the block!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "swat_breacher", "count": 4, "elite": false}, {"kind": "field_medic", "count": 1, "elite": false}]},
	{"time": 620.0, "type": "wave", "banner": "The Guard holds the street!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "riot_cop", "count": 5, "elite": false}, {"kind": "swat_breacher", "count": 3, "elite": false}, {"kind": "squad_car", "count": 1, "elite": false}]},
	{"time": 730.0, "type": "wave", "banner": "A rifle squad advances!", "formation": "line",  # TUNING (not in GDD) a squad of 4
		"groups": [{"kind": "rifleman", "count": 4, "elite": false}]},
	{"time": 780.0, "type": "wave", "banner": "A tank rolls down the street!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "tank", "count": 1, "elite": false}, {"kind": "rifleman", "count": 4, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "Two rifle squads and a medic!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "rifleman", "count": 8, "elite": false}, {"kind": "field_medic", "count": 1, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The city throws everything it has!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "rifleman", "count": 4, "elite": false}, {"kind": "swat_breacher", "count": 3, "elite": false}, {"kind": "tank", "count": 1, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA): CITY BLOCKS ("blocks": this
## zone's looks over the STAGE BLOCKS grid; {} = the defaults). With "blocks"
## Arena asks CityBlocks instead of the per-cell scatter, so "density" and
## "kinds" are unused (kept for the shared keys).
const ARENA := {
	"density": 0.0,  # Unused on a blocks layout.
	"clear_radius": 120.0,  # TUNING (not in GDD) px: the start crossing stays open (no building within it)
	"layout_seed": 2424,  # TUNING (not in GDD)
	"kinds": {},  # Unused on a blocks layout.
	"blocks": {"styles": {"tower": 0.6, "tenement": 0.4}, "open_share": 0.25, "open_styles": {"plaza": 0.6, "park": 0.3, "parking": 0.1}},  # TUNING (not in GDD) downtown towers and plazas
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script
## under Paragon's name until phase 2 adds
## scripts/enemies/city/boss_paragon.gd (then remove the "script" key).
const BOSS := {
	"id": "paragon",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_paragon.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "Paragon, the Last Hero",
	"short_name": "Paragon",
	"arrive_banner": "Paragon descends from the Heroes' Tower!",
	"defeat_banner": "The Last Hero falls! Hold out until the end...",
	"dead_objective": "No one is left to defend the living. Survive Martial Law... you cannot.",
}

## Placeholder floor (CityGround, code-drawn from the CityBlocks geometry) until
## phase 2 brings the stage's zone floors: its style and colours.
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
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
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
	"ground": "city",  # Placeholder CityGround until phase 2.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector).
	"city": true,  # Act VIII: Armour, Supers, Civilians, the escalation (CityRules).
	"blocks": BLOCKS,  # Act VIII: the city-block grid (CityBlocks; {} = the defaults).
	"escalation": ESCALATION,  # Act VIII: this stage's escalation overrides ({} = the defaults).
	"civilians": CIVILIANS,  # Act VIII: this stage's civilians overrides ({} = the defaults).
	"supers": SUPERS,  # Act VIII: the Supers the escalation sends.
	"zones": ZONES,  # Act VIII stub: the planned zones (phase 2 builds them).
	# Music key "sanguine" FOR NOW (the Act VII loop): the audio pass adds
	# "siren" ("Sirens at Midnight", SoundData.SIREN_SCORE) and the lead
	# switches this to "siren" at the merge.
	"music": "sanguine",
}
