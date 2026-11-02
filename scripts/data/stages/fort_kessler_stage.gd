## FortKesslerStage — STAGE 23, FORT KESSLER (Act VIII, the Last Line; GDD §15.0
## "Fort Kessler (Act VIII phase 2)" and the rows after it; owner-approved
## proposal docs/act8/PROPOSAL.md "Stage 23: Fort Kessler", with the owner's
## phase 2 answers of Nov 2, 2026). A military base on the edge of the city,
## the army's last line against the dead.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## The stage is laid out as CITY BLOCKS ("blocks": a grid of buildings with
## streets and alleys, CityBlocks through Arena) and runs the Last Line's three
## shared rules ("city": true: Armour, Supers, Civilians). Its ESCALATION climbs
## gangs -> police -> SWAT -> the army and STOPS there ("last": "army", the
## owner's tier caps; no Super ever comes on the clock), and its timeline spawns
## only those tiers' kinds; the Martial Law Reckoning still throws every tier.
## Four clock-driven zones (ZONES, MarchDirector; FortKesslerGround draws their
## looks over the same block grid): THE CHECKPOINTS (sandbags and barrier booms
## at the crossings), THE MINEFIELD (FortKesslerDirector's Minefields: blinking
## mines in the open lots and on chosen streets that blow up under anyone),
## THE AIRFIELD (open concrete aprons; attack helicopters; Mammoth, the
## miniboss) and THE COMMAND BUNKER (bunker roofs, sandbags). The army's new
## kinds join here: the Machine Gunner and the Attack Helicopter (CityEnemyData),
## and Mammoth (FortKesslerEnemyData). General Vance Harrow, the Hammer
## (BossHarrow, HarrowData) arrives with 3:00 left: the command vehicle and
## carpet bombing, the power armour and the tank column, Broken Arrow; the
## Reckoning at 0:00. Hidden from the stage select ("playable": false) until the
## lead's integration pass.
## Every rate, cap and weight is TUNING (not in GDD).
class_name FortKesslerStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "fort_kessler"

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
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 2 of Act VIII

## Damage tag of a minefield mine's blast (Minefields; both armies).
const MINE_SOURCE: String = "kessler_mine"
## Sprite key of a mine (assets/sprites/structures/kessler_mine.png; never the
## spell Bone Mines' id).
const MINE_SPRITE: String = "structures/kessler_mine"

## Obstacle layout of the first zone (keys as GraveyardStage.ARENA): CITY
## BLOCKS (the Checkpoints' "blocks"; each later zone has its own in ZONES).
## With "blocks" Arena asks CityBlocks instead of the per-cell scatter, so
## "density" and "kinds" are unused (kept for the shared keys).
const ARENA := {"density": 0.0, "clear_radius": 120.0, "layout_seed": 2323, "kinds": {},  # TUNING (not in GDD) the start crossing stays open
	"blocks": {"styles": {"bunker": 0.45, "warehouse": 0.55}, "open_share": 0.2,  # TUNING (not in GDD) the base's bunkers and hangars
		"open_styles": {"parking": 0.6, "plaza": 0.4}}}  # TUNING (not in GDD) motor pools and parade grounds

## The Checkpoints' floor look (FortKesslerGround reads each zone's "ground").
const FLOOR := {"style": "checkpoints", "asphalt": Palette.CITY_ASPHALT, "sidewalk": Palette.CITY_CONCRETE, "lane": Palette.CITY_HAZARD, "accent": Palette.CITY_OLIVE}  # TUNING (not in GDD)

## The four zones (owner-approved proposal names), each from `start` game
## seconds (MarchDirector: the zone banner, the fog sweep, Arena.set_layout()
## and FortKesslerGround.set_zone()). A zone changes only the looks and the
## open-lot share (CityBlocks.set_zone(): a zone never moves a street).
##   ground — FortKesslerGround's look: style (checkpoints / minefield /
##            airfield / bunker: its decals and open-lot looks) and the code
##            floor's colours.
##   arena  — the zone's obstacle layout: the city blocks' looks ("blocks").
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Checkpoints",  # Owner-approved proposal (zones)
		"blurb": "Sandbags and barrier booms at every crossing",
		"ground": FLOOR, "arena": ARENA},
	{"start": 240.0, "numeral": "II", "name": "The Minefield",  # Owner-approved proposal (zones)
		"blurb": "Blinking mines in the lots and the streets: lure the soldiers over them",
		"ground": {"style": "minefield", "asphalt": Palette.CITY_ASPHALT, "sidewalk": Palette.CITY_CONCRETE, "lane": Palette.CITY_HAZARD, "accent": Palette.CITY_SIREN_RED},
		"arena": {"density": 0.0, "clear_radius": 160.0, "layout_seed": 2323, "kinds": {},  # TUNING (not in GDD)
			"blocks": {"styles": {"bunker": 0.6, "warehouse": 0.4}, "open_share": 0.3,  # TUNING (not in GDD) more open ground to mine
				"open_styles": {"field": 1.0}}}},
	{"start": 600.0, "numeral": "III", "name": "The Airfield",  # Owner-approved proposal (zones)
		"blurb": "Concrete aprons and hangars: helicopters overhead, and Mammoth",
		"ground": {"style": "airfield", "asphalt": Palette.CITY_CONCRETE, "sidewalk": Palette.CITY_CONCRETE_LIGHT, "lane": Palette.CITY_HAZARD, "accent": Palette.CITY_HAZARD},
		"arena": {"density": 0.0, "clear_radius": 160.0, "layout_seed": 2323, "kinds": {},  # TUNING (not in GDD)
			"blocks": {"styles": {"warehouse": 0.8, "bunker": 0.2}, "open_share": 0.4,  # TUNING (not in GDD) the hangars, the aprons
				"open_styles": {"apron": 1.0}}}},
	{"start": 840.0, "numeral": "IV", "name": "The Command Bunker",  # Owner-approved proposal (zones)
		"blurb": "The General's bunkers, behind sandbag walls",
		"ground": {"style": "bunker", "asphalt": Palette.CITY_ASPHALT_DARK, "sidewalk": Palette.CITY_CONCRETE, "lane": Palette.CITY_HAZARD, "accent": Palette.CITY_OLIVE_DARK},
		"arena": {"density": 0.0, "clear_radius": 160.0, "layout_seed": 2323, "kinds": {},  # TUNING (not in GDD)
			"blocks": {"styles": {"bunker": 0.9, "warehouse": 0.1}, "open_share": 0.2,  # TUNING (not in GDD)
				"open_styles": {"parking": 0.5, "plaza": 0.5}}}},
]

## The clock-driven zones (MarchDirector; keys as RavensmoorStage.MARCH).
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 160.0,  # TUNING (not in GDD) px: no new building this near the necromancer
	"zone_title": "FORT KESSLER  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(0.949, 0.769, 0.094),  # Hazard yellow (Palette.CITY_HAZARD), never the UI's soul-teal.
	"fog_color": Color(0.12, 0.13, 0.11),  # Smoke over the base.
	"fog_bank_color": Color(0.36, 0.38, 0.30),  # Olive smoke banks.
	"zones": ZONES,
}

## The stage's city-block grid: {} = CityBlockData.DEFAULTS (any key overrides
## it here; the grid keys only here, never per zone).
const BLOCKS := {}
## The escalation on this stage (owner, Nov 2, 2026: "Fort Kessler climbs up to
## the army"): gangs -> police -> SWAT -> the army, sooner than the defaults
## (the army is the stage's own: its riflemen reach the Minefield).
const ESCALATION := {
	"last": "army",  # Owner answer (Nov 2, 2026): the tier cap
	"times": {"gangs": 0.0, "police": 150.0, "swat": 300.0, "army": 450.0},  # TUNING (not in GDD) 0:00, 2:30, 5:00, 7:30
}
## The civilians on this stage: {} = CityRulesData.CIVILIANS (their trickle
## stops when the army comes, at 7:30).
const CIVILIANS := {}
## The Supers the escalation sends here: none (the ladder stops at the army;
## Martial Law brings back only Supers met, so none here).
const SUPERS: Array[String] = []

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): MARTIAL LAW,
## shared by every Act VIII stage: every tier's kinds at once (the tank as the
## heavy, a thug, a riot cop, a breacher, a rifleman squad and, at the army's
## base, a machine gunner as companions), artillery lines walking along the
## streets ("martial_law": CityRulesData.MARTIAL_LAW keys; {} = those
## defaults), and every Super the run met returns, one every 20 s.
const RECKONING := {
	"banner": "MARTIAL LAW: THE CITY BREAKS ITS LAST LINE ON YOU",
	"kind": CityEnemyData.TANK,  # The shared Martial Law heavy.
	"martial_law": {},  # CityRulesData.MARTIAL_LAW defaults.
	"companions": [{"kind": CityEnemyData.STREET_THUG, "count": 4, "growth": 1.0},  # TUNING (not in GDD) the gangs
		{"kind": CityEnemyData.RIOT_COP, "count": 2, "growth": 0.5},  # TUNING (not in GDD) the police
		{"kind": CityEnemyData.SWAT_BREACHER, "count": 1, "growth": 0.5},  # TUNING (not in GDD) SWAT
		{"kind": CityEnemyData.RIFLEMAN, "count": 4, "growth": 0.5},  # TUNING (not in GDD) the army (a squad)
		{"kind": CityEnemyData.MACHINE_GUNNER, "count": 1, "growth": 0.25}],  # TUNING (not in GDD) the base's guns
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 1,  # TUNING (not in GDD) tanks are heavy
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "MARTIAL LAW: every soldier in the city and the artillery. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS) on the
## escalation clock: only the kinds of the stage's tiers (gangs, police, SWAT,
## the army). Vehicles stay rare; the helicopters and the machine gunners come
## mostly in the events.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"street_thug": 1.0},
		"objective": "The Checkpoints: the gangs run the base's outskirts. Civilians flee to the gates: each one you catch is XP"},
	{"start": 45.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"street_thug": 0.7, "gang_gunner": 0.3},
		"objective": "Gang gunners spray from the hip: blockers soak it"},
	{"start": 150.0, "rate": 2.0, "max_alive": 48,  # TUNING (not in GDD) the police
		"weights": {"street_thug": 0.45, "gang_gunner": 0.25, "riot_cop": 0.28, "squad_car": 0.02},
		"objective": "The police: shields to the front. Flank the line; keep out of the headlights"},
	{"start": 300.0, "rate": 2.2, "max_alive": 56,  # TUNING (not in GDD) SWAT and the Guard
		"weights": {"street_thug": 0.35, "gang_gunner": 0.2, "riot_cop": 0.25, "swat_breacher": 0.13, "field_medic": 0.05, "squad_car": 0.02},
		"objective": "The Minefield: anyone who steps on a mine sets it off. Lure the soldiers over them"},
	{"start": 450.0, "rate": 2.4, "max_alive": 62,  # TUNING (not in GDD) the army
		"weights": {"street_thug": 0.26, "gang_gunner": 0.12, "riot_cop": 0.18, "swat_breacher": 0.12, "field_medic": 0.05, "rifleman": 0.22, "machine_gunner": 0.03, "squad_car": 0.01},
		"objective": "The army: rifle squads and machine-gun nests. Step out of a gunner's lane, or wall it"},
	{"start": 600.0, "rate": 2.6, "max_alive": 70,  # TUNING (not in GDD) the Airfield
		"weights": {"street_thug": 0.22, "gang_gunner": 0.1, "riot_cop": 0.17, "swat_breacher": 0.12, "field_medic": 0.05, "rifleman": 0.24, "machine_gunner": 0.04, "squad_car": 0.01, "tank": 0.01},
		"objective": "The Airfield: helicopters strafe the streets. Gargoyles, Archers and spells bring them down"},
	{"start": 840.0, "rate": 2.8, "max_alive": 76,  # TUNING (not in GDD) the Command Bunker
		"weights": {"street_thug": 0.2, "gang_gunner": 0.1, "riot_cop": 0.16, "swat_breacher": 0.12, "field_medic": 0.05, "rifleman": 0.26, "machine_gunner": 0.05, "squad_car": 0.01, "tank": 0.01},
		"objective": "The Command Bunker: the General's last line"},
	{"start": BOSS_TIME, "rate": 2.2, "max_alive": 60,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"street_thug": 0.25, "gang_gunner": 0.12, "riot_cop": 0.18, "swat_breacher": 0.12, "field_medic": 0.05, "rifleman": 0.24, "machine_gunner": 0.04},
		"objective": "General Harrow has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus "mammoth":
## FortKesslerDirector's miniboss, with an "escort" list of {kind, count}), on
## the escalation clock. Riflemen come in squads of 4 (owner-approved
## proposal); machine gunners in nests of 2 with a squad.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A gang spills out of the alleys!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "street_thug", "count": 14, "elite": false}]},
	{"time": 100.0, "type": "wave", "banner": "Gunners on the corner!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "gang_gunner", "count": 6, "elite": false}, {"kind": "street_thug", "count": 8, "elite": false}]},
	{"time": 160.0, "type": "wave", "banner": "A police line forms up at the checkpoint! Flank the shields!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "riot_cop", "count": 6, "elite": false}]},
	{"time": 220.0, "type": "wave", "banner": "Squad cars! Keep out of the headlights!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "squad_car", "count": 2, "elite": false}, {"kind": "riot_cop", "count": 3, "elite": false}]},
	{"time": 310.0, "type": "wave", "banner": "SWAT breaches the minefield!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "swat_breacher", "count": 4, "elite": false}, {"kind": "field_medic", "count": 1, "elite": false}]},
	{"time": 390.0, "type": "wave", "banner": "The Guard holds the street!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "riot_cop", "count": 5, "elite": false}, {"kind": "swat_breacher", "count": 3, "elite": false}, {"kind": "squad_car", "count": 1, "elite": false}]},
	{"time": 460.0, "type": "wave", "banner": "A rifle squad advances across the minefield!", "formation": "line",  # TUNING (not in GDD) a squad of 4
		"groups": [{"kind": "rifleman", "count": 4, "elite": false}]},
	{"time": 520.0, "type": "wave", "banner": "A machine-gun nest! Step out of the lane, or wall it!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "machine_gunner", "count": 2, "elite": false}, {"kind": "rifleman", "count": 4, "elite": false}]},
	{"time": 610.0, "type": "wave", "banner": "Attack helicopters over the airfield!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "attack_helicopter", "count": 2, "elite": false}, {"kind": "rifleman", "count": 4, "elite": false}]},
	{"time": 690.0, "type": "mammoth", "banner": "MAMMOTH rolls off the airfield! Let it ram a wreck!", "kind": "mammoth",  # TUNING (not in GDD) the miniboss
		"escort": [{"kind": "rifleman", "count": 4}]},
	{"time": 780.0, "type": "wave", "banner": "A tank and a machine-gun nest!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "tank", "count": 1, "elite": false}, {"kind": "machine_gunner", "count": 2, "elite": false}]},
	{"time": 870.0, "type": "wave", "banner": "Two rifle squads and a gunship!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "rifleman", "count": 8, "elite": false}, {"kind": "attack_helicopter", "count": 1, "elite": false}, {"kind": "field_medic", "count": 1, "elite": false}]},
	{"time": 960.0, "type": "wave", "banner": "The bunker empties its guns!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "rifleman", "count": 4, "elite": false}, {"kind": "machine_gunner", "count": 2, "elite": false}, {"kind": "tank", "count": 1, "elite": false}]},
]

## The stage boss's arrival (keys as GraveyardStage.BOSS): General Vance
## Harrow (BossHarrow, scripts/enemies/city/boss_harrow.gd, loaded by his id).
const BOSS := HarrowData.ARRIVAL

## Fort Kessler's stage systems (FortKesslerDirector; StageRegistry
## "fort_kessler").
##   minefields — Minefields' numbers:
##     zones           — zone indices (ZONES) that have mines (the Minefield).
##     seed            — salt of the layout hash (the arena's layout seed).
##     lot_chance      — share (0..1) of open lots that are minefields.
##     lot_cols / lot_rows — the grid of mines in a mined lot.
##     lot_inset       — px a lot's mines keep from its edges.
##     street_chance   — share (0..1) of street segments (between two
##                       crossings) that hold a row of mines.
##     street_mines    — mines in a mined street segment (a zig-zag row).
##     street_offset   — px each side of the street's centre line they zig-zag.
##     crossing_clear  — px past a crossing's edge before the first one.
##     active_radius   — px from a necromancer within which mines are live.
##     refresh         — s between two rebuilds of the live mines.
##     start_clear     — px around where a necromancer stood at the zone's
##                       start with no mine.
##     arm_time        — s from the zone's start before they can go off.
##     check_every     — s between two trigger checks.
##     trigger         — px from a mine within which a foot sets it off.
##     fuse            — s from the trigger to the blast.
##     radius          — px of the blast.
##     damage          — blast damage before the time scaling (both armies).
##     avoid_margin    — px a Bone Ring post keeps from a mine.
##     danger_reach    — px the autotest bot keeps from a mine.
##     blink_hz        — the mines' slow blink (<= 1 Hz: the act's light rule).
##   mammoth_objective      — the HUD objective while Mammoth stands.
##   broken_arrow_objective — the HUD countdown text while Broken Arrow counts
##                            down (%d: seconds left).
const FORT_KESSLER := {
	"minefields": {
		"zones": [1],  # Owner-approved proposal: the Minefield zone
		"seed": 2323,  # TUNING (not in GDD) the arena's layout seed
		"lot_chance": 0.6,  # TUNING (not in GDD)
		"lot_cols": 4,  # TUNING (not in GDD)
		"lot_rows": 3,  # TUNING (not in GDD)
		"lot_inset": 30.0,  # TUNING (not in GDD) px
		"street_chance": 0.2,  # TUNING (not in GDD)
		"street_mines": 5,  # TUNING (not in GDD)
		"street_offset": 34.0,  # TUNING (not in GDD) px
		"crossing_clear": 24.0,  # TUNING (not in GDD) px
		"active_radius": 950.0,  # TUNING (not in GDD) px
		"refresh": 1.0,  # TUNING (not in GDD) s
		"start_clear": 220.0,  # TUNING (not in GDD) px
		"arm_time": 3.0,  # TUNING (not in GDD) s
		"check_every": 0.1,  # TUNING (not in GDD) s
		"trigger": 12.0,  # TUNING (not in GDD) px
		"fuse": 0.45,  # TUNING (not in GDD) s
		"radius": 56.0,  # TUNING (not in GDD) px
		"damage": 22.0,  # TUNING (not in GDD) before the time scaling (both armies)
		"avoid_margin": 34.0,  # TUNING (not in GDD) px
		"danger_reach": 64.0,  # TUNING (not in GDD) px
		"blink_hz": 0.6,  # TUNING (not in GDD) owner rule: at most 1 Hz, a soft fade
	},
	"mammoth_objective": "Mammoth rolls in: hit it from the side or behind, and let it ram a wreck",  # TUNING (not in GDD)
	"broken_arrow_objective": "BROKEN ARROW in %d s: kill General Harrow to call it off!",  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Fort Kessler",
	"short_name": "Fort Kessler",
	"chapter": "Chapter XXIII",
	"act": 8,  # Act VIII, the Last Line.
	"playable": false,  # Phase 2 built; the lead's integration pass opens it.
	"description": "A military base on the edge of the city: checkpoints, minefields and an airfield, the army's last line against the dead.",
	"unlock": {"stage": "skid_row", "boss_kills": 1},  # Owner-approved: each Act VIII stage opens the next
	"unlock_text": "Bring down Don Marrow on Skid Row to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act VIII stages.
	"consecration": {},  # A Covenant event: none in Act VIII.
	"crypt_defender": {},  # None in Act VIII.
	"arena": ARENA,
	"ground": "fort_kessler",  # FortKesslerGround: the four zone looks over CityGround.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"city": true,  # Act VIII: Armour, Supers, Civilians, the escalation (CityRules).
	"blocks": BLOCKS,  # Act VIII: the city-block grid (CityBlocks; {} = the defaults).
	"escalation": ESCALATION,  # Act VIII: capped at the army.
	"civilians": CIVILIANS,  # Act VIII: this stage's civilians overrides ({} = the defaults).
	"supers": SUPERS,  # Act VIII: none on Fort Kessler.
	"zones": ZONES,  # Act VIII: the four zones.
	"fort_kessler": FORT_KESSLER,  # FortKesslerDirector: the minefields, Mammoth, Broken Arrow's countdown.
	"music": "siren",  # Act VIII: "Sirens at Midnight" (SoundData.SIREN_SCORE); also renders the City pack.
}
