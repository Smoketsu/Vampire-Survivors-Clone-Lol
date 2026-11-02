## SkidRowStage — STAGE 22, SKID ROW (Act VIII, the Last Line; GDD §15.0 "Act
## VIII foundation (phase 1)", "Skid Row (Act VIII phase 2)" and the rows after
## it; owner-approved proposal docs/act8/PROPOSAL.md "Stage 22: Skid Row", with
## the owner's phase 2 answers of Nov 2, 2026). The docks and back streets of
## the last great city, where the dead first come up out of the sewers and the
## gangs own every block. Every number and event that belongs to this stage;
## StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
## Unlocked by slaying Queen Carmilla and the Elder in Castle Sanguis.
##
## THE MAP IS CITY BLOCKS (CityBlocks through Arena: buildings, streets and
## alleys), and THE CLOCK IS AUTHORITATIVE, as on every stage since the Crimson
## March: four zones on fixed times (ZONES, run by MarchDirector: a zone banner,
## a sweep of night smog, the same streets re-drawn as the next zone; a zone
## never moves a street, CityBlocks.set_zone()):
##   20:00  Zone I,   the Alleys:      tenements and fire escapes; the gangs
##   15:00  Zone II,  the Night Market: neon market stalls in the open lots;
##                                      the police came at 16:00 (4:00 elapsed)
##   10:00  Zone III, the Overpass:     an elevated road's shadow and its
##                                      pillars over the streets; SWAT and the
##                                      Guard came at 11:00; Big Sal at 9:30 left
##    5:00  Zone IV,  the Precinct:     the police precinct's roofs
##    3:00  Don Marrow, the Kingpin (BossDonMarrow, DonMarrowData)
##    0:00  Martial Law (the shared Act VIII Reckoning: every tier at once)
## THE LADDER IS CAPPED AT SWAT (owner, Nov 2, 2026: "Skid Row climbs gangs ->
## police -> SWAT and stops there"): the STAGE "escalation" ends at "swat" and
## the timeline spawns only gang, police and SWAT kinds; Martial Law's
## companions still bring every tier. Armour, Supers and Civilians are the
## shared City rules ("city": true); no Super comes before 0:00 here (the
## ladder never reaches the heroes). The stage systems run in SkidRowDirector
## (SKID_ROW): BIG SAL AND THE ARMOURED LIMO (the miniboss), the BOUNTY's
## doubled gangs while Don Marrow's board stands, and NO WITNESSES (the
## achievement). Every rate, cap and weight is TUNING (not in GDD).
class_name SkidRowStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "skid_row"

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act VIII starts a step above Castle Sanguis's 1.85; the step goes in HP,
## not damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 2.0  # TUNING (not in GDD) the foundation's step, kept
## Enemy damage multiplier of this stage on top of the shared time scaling
## (below Castle Sanguis's 1.5: the act's first stage, and the step up is in
## HP; Fort Kessler and Liberty Heights set their own).
const ENEMY_DAMAGE_MULT: float = 1.3  # TUNING (not in GDD) first pass 1.5 (the foundation's): the seed-2 army bot's ring broke at 8:00-10:00, lowest HP 3%
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) Acts III to VII: 7:00
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 1 of Act VIII

## The stage's city-block grid: {} = CityBlockData.DEFAULTS (any key overrides
## it here; the grid keys only here, never per zone).
const BLOCKS := {}
## The escalation on this stage (keys of CityRulesData.ESCALATION): the
## ladder stops at SWAT and the Guard (owner, Nov 2, 2026): gangs 0:00, police
## 4:00, SWAT 9:00 (a minute after the shared 8:00, so it no longer lands right
## on the stage's 7:00 HP / damage step).
const ESCALATION := {
	"last": "swat",  # Owner (Nov 2, 2026): "Skid Row climbs gangs -> police -> SWAT and stops there"
	"times": {"gangs": 0.0, "police": 240.0, "swat": 540.0},  # TUNING (not in GDD) first pass SWAT at 8:00 (the shared time): the seed-2 army bot's ring broke at 8:00-10:00
}
## The civilians on this stage: {} = CityRulesData.CIVILIANS (the army tier
## never comes, so their trickle runs until 0:00: intended, brief).
const CIVILIANS := {}
## The Supers the escalation would send here (it never reaches the heroes on
## Skid Row; Martial Law only brings back the Supers the run met).
const SUPERS: Array[String] = ["blitz"]

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): MARTIAL LAW,
## shared by every Act VIII stage: every tier's kinds at once (the tank as the
## heavy, a thug, a riot cop, a breacher and a rifleman squad as companions:
## every tier even here, owner's phase 2 answer), artillery lines walking along
## the streets ("martial_law": CityRulesData.MARTIAL_LAW keys; {} = those
## defaults), and every Super the run met returns, one every 20 s.
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

## Continuous spawning segments, sorted by start time (keys as
## GraveyardStage.SEGMENTS). Only the ladder's tiers: the gangs (street
## thugs, gang gunners), the police (riot cops, squad cars) from 4:00, SWAT and
## the Guard (breachers, field medics) from 9:00. Vehicles stay rare. While
## Don Marrow's bounty board stands, SkidRowDirector doubles the gang share of
## the live segment (the Bounty).
const SEGMENTS := [
	# Zone I, the Alleys: the gangs.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"street_thug": 1.0},
		"objective": "The Alleys: the gangs own these blocks. Civilians flee: each one you catch is XP"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"street_thug": 0.7, "gang_gunner": 0.3},
		"objective": "Gang gunners spray from the hip: blockers soak it"},
	# The police (4:00 elapsed).
	{"start": 240.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"street_thug": 0.45, "gang_gunner": 0.25, "riot_cop": 0.28, "squad_car": 0.02},
		"objective": "The police: shields to the front, tear gas on your ring. Flank the line; keep out of the headlights"},
	# Zone II, the Night Market (5:00).
	{"start": 300.0, "rate": 2.2, "max_alive": 56,  # TUNING (not in GDD)
		"weights": {"street_thug": 0.45, "gang_gunner": 0.25, "riot_cop": 0.28, "squad_car": 0.02},
		"objective": "The Night Market: the gangs hide among the stalls"},
	# SWAT and the Guard (9:00 elapsed).
	{"start": 540.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD) first pass from 8:00
		"weights": {"street_thug": 0.4, "gang_gunner": 0.22, "riot_cop": 0.26, "swat_breacher": 0.08, "field_medic": 0.03, "squad_car": 0.01},
		"objective": "SWAT: flashbangs stun your dead. Kill the breachers and the medics first"},
	# Zone III, the Overpass (10:00): Big Sal at 10:30.
	{"start": 600.0, "rate": 2.5, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"street_thug": 0.4, "gang_gunner": 0.22, "riot_cop": 0.26, "swat_breacher": 0.08, "field_medic": 0.03, "squad_car": 0.01},
		"objective": "The Overpass: SWAT holds the street under the deck"},
	# Zone IV, the Precinct (15:00).
	{"start": 900.0, "rate": 2.8, "max_alive": 76,  # TUNING (not in GDD)
		"weights": {"street_thug": 0.4, "gang_gunner": 0.22, "riot_cop": 0.26, "swat_breacher": 0.08, "field_medic": 0.03, "squad_car": 0.01},
		"objective": "The Precinct: the police make their stand at their own door"},
	# 17:00, the boss: thinner, so the fight is the Kingpin's.
	{"start": BOSS_TIME, "rate": 2.2, "max_alive": 60,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"street_thug": 0.55, "gang_gunner": 0.3, "riot_cop": 0.15},
		"objective": "Don Marrow has come for you: break his bounty board"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave": formation + groups), plus Skid Row's own (SkidRowDirector):
##   "big_sal" — Big Sal's Armoured Limo (kind `kind`) rolls in on the spawn
##               ring with `crew` gang gunners (the stage miniboss; he climbs
##               out of the wreck when it dies).
const EVENTS := [
	# Zone I: the Alleys.
	{"time": 20.0, "type": "wave", "banner": "A gang spills out of the alleys!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "street_thug", "count": 14, "elite": false}]},
	{"time": 120.0, "type": "wave", "banner": "Gunners on the corner!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "gang_gunner", "count": 6, "elite": false}, {"kind": "street_thug", "count": 8, "elite": false}]},
	{"time": 200.0, "type": "wave", "banner": "Two gangs meet in the street!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "street_thug", "count": 12, "elite": false}, {"kind": "gang_gunner", "count": 4, "elite": false}]},
	# The police (4:00).
	{"time": 250.0, "type": "wave", "banner": "A police line forms up! Flank the shields!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "riot_cop", "count": 6, "elite": false}]},
	# Zone II (5:00): the Night Market.
	{"time": 320.0, "type": "wave", "banner": "Squad cars! Keep out of the headlights!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "squad_car", "count": 2, "elite": false}, {"kind": "riot_cop", "count": 3, "elite": false}]},
	{"time": 400.0, "type": "wave", "banner": "The gangs rush the market!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "street_thug", "count": 12, "elite": false}, {"kind": "gang_gunner", "count": 6, "elite": false}]},
	{"time": 480.0, "type": "wave", "banner": "Riot police and a medic!", "formation": "line",  # TUNING (not in GDD) before SWAT (the medic comes with the riot line)
		"groups": [{"kind": "riot_cop", "count": 5, "elite": false}, {"kind": "field_medic", "count": 1, "elite": false}]},
	# SWAT and the Guard (9:00).
	{"time": 550.0, "type": "wave", "banner": "SWAT breaches the block!", "formation": "arc",  # TUNING (not in GDD) first pass 8:10
		"groups": [{"kind": "swat_breacher", "count": 3, "elite": false}, {"kind": "field_medic", "count": 1, "elite": false}]},
	# Zone III (10:00): the Overpass; Big Sal at 10:30.
	{"time": 630.0, "type": "big_sal", "banner": "BIG SAL'S ARMOURED LIMO! His crew shoots from the windows!",  # Owner-approved proposal (miniboss); TUNING (not in GDD) time
		"kind": "armoured_limo", "crew": 4},  # TUNING (not in GDD) gang gunners riding with him
	{"time": 720.0, "type": "wave", "banner": "The Guard holds the street!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "riot_cop", "count": 5, "elite": false}, {"kind": "swat_breacher", "count": 2, "elite": false}, {"kind": "squad_car", "count": 1, "elite": false}]},
	{"time": 820.0, "type": "wave", "banner": "The gangs and the police both want you dead!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "street_thug", "count": 12, "elite": false}, {"kind": "riot_cop", "count": 4, "elite": false}]},
	# Zone IV (15:00): the Precinct.
	{"time": 910.0, "type": "wave", "banner": "The precinct empties onto the street!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "riot_cop", "count": 6, "elite": false}, {"kind": "swat_breacher", "count": 2, "elite": false}, {"kind": "field_medic", "count": 1, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "Don Marrow's soldiers clear the street for him!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "street_thug", "count": 12, "elite": false}, {"kind": "gang_gunner", "count": 6, "elite": false}]},
	# 17:00 Don Marrow (BOSS_TIME).
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES
## (MarchDirector). `arena` keeps the stage's blocks layout and changes only its
## looks ("blocks": roof styles, open-lot looks; the open share stays the
## grid's 0.2, so no street or lot moves); `clear` is the clear circle (px)
## around the necromancer at the change. `ground` is a SkidRowGround look:
##   style    — the CityGround accents: "docks" (manholes, oil stains),
##              "market" (neon spill over the street), "overpass" (the
##              elevated road's shadow and its pillars beside the street) or
##              "precinct" (painted no-parking bars, blue kerb paint).
##   asphalt / sidewalk / lane / accent (/ accent2) — the code floor's colours.
## Roof styles: tenement / warehouse (the foundation's), "precinct" (Skid
## Row's own: tiles/city_roof_precinct, a blue-trimmed station roof). Open-lot
## looks: plaza / parking / park (the foundation's), "market" (Skid Row's own:
## rows of lit market stalls, SkidRowGround).
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Alleys",  # Owner-approved proposal (zones)
		"blurb": "Tenements, fire escapes and the sewers the dead climb out of",
		"ground": {"style": "docks", "asphalt": Palette.CITY_ASPHALT_DARK, "sidewalk": Palette.CITY_CONCRETE,
			"lane": Palette.CITY_SODIUM, "accent": Palette.CITY_NEON_PINK},
		"arena": {"density": 0.0, "clear_radius": 120.0, "layout_seed": 2222, "kinds": {},  # TUNING (not in GDD)
			"blocks": {"styles": {"tenement": 0.6, "warehouse": 0.4}, "open_styles": {"parking": 0.5, "plaza": 0.3, "park": 0.2}}}},  # TUNING (not in GDD)
	{"start": 300.0, "numeral": "II", "name": "The Night Market",  # Owner-approved proposal (zones)
		"blurb": "Neon stalls in every open lot, and nobody selling",
		"clear": 120.0,  # TUNING (not in GDD) px
		"ground": {"style": "market", "asphalt": Palette.CITY_ASPHALT_DARK, "sidewalk": Palette.CITY_CONCRETE,
			"lane": Palette.CITY_SODIUM, "accent": Palette.CITY_NEON_PINK, "accent2": Palette.CITY_NEON_CYAN},
		"arena": {"density": 0.0, "clear_radius": 120.0, "layout_seed": 2222, "kinds": {},  # TUNING (not in GDD)
			"blocks": {"styles": {"tenement": 0.75, "warehouse": 0.25}, "open_styles": {"market": 0.8, "parking": 0.2}}}},  # TUNING (not in GDD)
	{"start": 600.0, "numeral": "III", "name": "The Overpass",  # Owner-approved proposal (zones)
		"blurb": "The elevated road's shadow over the warehouses",
		"clear": 120.0,  # TUNING (not in GDD) px
		"ground": {"style": "overpass", "asphalt": Palette.CITY_ASPHALT_DARK, "sidewalk": Palette.CITY_CONCRETE,
			"lane": Palette.CITY_HAZARD, "accent": Palette.CITY_CONCRETE_LIGHT},
		"arena": {"density": 0.0, "clear_radius": 120.0, "layout_seed": 2222, "kinds": {},  # TUNING (not in GDD)
			"blocks": {"styles": {"warehouse": 0.7, "tenement": 0.3}, "open_styles": {"parking": 0.7, "plaza": 0.3}}}},  # TUNING (not in GDD)
	{"start": 900.0, "numeral": "IV", "name": "The Precinct",  # Owner-approved proposal (zones)
		"blurb": "The police precinct and its blue lamps",
		"clear": 120.0,  # TUNING (not in GDD) px
		"ground": {"style": "precinct", "asphalt": Palette.CITY_ASPHALT_DARK, "sidewalk": Palette.CITY_CONCRETE,
			"lane": Palette.CITY_SODIUM, "accent": Palette.CITY_POLICE_BLUE},
		"arena": {"density": 0.0, "clear_radius": 120.0, "layout_seed": 2222, "kinds": {},  # TUNING (not in GDD)
			"blocks": {"styles": {"precinct": 0.45, "tenement": 0.35, "warehouse": 0.2}, "open_styles": {"parking": 0.6, "plaza": 0.4}}}},  # TUNING (not in GDD)
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 120.0,  # TUNING (not in GDD) px: the start crossing's clear radius
	"zone_title": "SKID ROW  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(1.0, 0.31, 0.659),  # Neon pink (Palette.CITY_NEON_PINK), never the UI's soul-teal.
	"fog_color": Color(0.12, 0.11, 0.13),  # Night smog.
	"fog_bank_color": Color(0.42, 0.33, 0.22),  # Sodium-lit smog banks.
	"zones": ZONES,
}

## Skid Row's stage systems (SkidRowDirector; StageRegistry "skid_row").
##   sal_objective       — HUD objective while the limo drives.
##   sal_out_objective   — HUD objective once Big Sal is on foot.
##   sal_out_banner      — banner when Big Sal climbs out of the wreck.
##   sal_dead_banner     — banner when Big Sal falls.
##   sal_crew_spacing    — px between the limo's escort gunners on the ring.
##   bounty_gang_kinds   — the gang kinds the Bounty doubles (each segment's
##                         weights for these, x the segment rate).
##   bounty_cap_share    — share (0..1) of the hard cap the Bounty's extra
##                         gangs may fill (they never push the cap).
##   witnesses_banner    — banner when No Witnesses is earned.
const SKID_ROW := {
	"sal_objective": "Wreck Big Sal's Armoured Limo: hit it from the side, not the armoured front",  # TUNING (not in GDD)
	"sal_out_objective": "Big Sal climbs out of the wreck: finish him",  # TUNING (not in GDD)
	"sal_out_banner": "BIG SAL CLIMBS OUT OF THE BURNING LIMO!",  # TUNING (not in GDD)
	"sal_dead_banner": "Big Sal falls! The gangs lose their enforcer.",  # TUNING (not in GDD)
	"sal_crew_spacing": 26.0,  # TUNING (not in GDD) px
	"bounty_gang_kinds": ["street_thug", "gang_gunner"],  # Owner-approved proposal: "gang spawns double while his bounty board is up"
	"bounty_cap_share": 0.9,  # TUNING (not in GDD)
	"witnesses_banner": "NO WITNESSES: not one of the crowd got away!",  # TUNING (not in GDD)
}

## Don Marrow's arrival (keys as GraveyardStage.BOSS): his own
## DonMarrowData.ARRIVAL (boss id "don_marrow"), whose `time` equals BOSS_TIME
## (17:00). His script is scripts/enemies/city/boss_don_marrow.gd (loaded by
## his id).
const BOSS: Dictionary = DonMarrowData.ARRIVAL

## The foundation's floor look (CityGround "floor" key), kept for the tools
## that read it; the stage draws SkidRowGround ("ground") with the zones' looks.
const FLOOR := {
	"style": "docks",  # Docks asphalt: worn roads, oil stains, manhole covers.
	"asphalt": Palette.CITY_ASPHALT_DARK,  # TUNING (not in GDD)
	"sidewalk": Palette.CITY_CONCRETE,  # TUNING (not in GDD)
	"lane": Palette.CITY_SODIUM,  # TUNING (not in GDD) worn sodium-orange lane lines
	"accent": Palette.CITY_NEON_PINK,  # TUNING (not in GDD) neon spill from the Night Market
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Skid Row",
	"short_name": "Skid Row",
	"chapter": "Chapter XXII",
	"act": 8,  # Act VIII, the Last Line.
	"playable": false,  # Phase 2 built; hidden until the lead's integration and the owner's review (brief: keep "playable": false).
	"description": "The docks and back streets of the last great city, where the dead first come up out of the sewers and the gangs own every block.",
	"unlock": {"stage": "castle_sanguis", "boss_kills": 1},  # Owner-approved: Act VIII opens on Carmilla
	"unlock_text": "Slay Queen Carmilla in Castle Sanguis to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act VIII stages.
	"consecration": {},  # A Covenant event: none in Act VIII.
	"crypt_defender": {},  # None in Act VIII.
	"arena": ZONES[0]["arena"],
	"ground": "skid_row",  # SkidRowGround: the four zone looks over the city blocks.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"skid_row": SKID_ROW,  # SkidRowDirector: Big Sal and the Armoured Limo, the Bounty's gangs, No Witnesses.
	"city": true,  # Act VIII: Armour, Supers, Civilians, the escalation (CityRules).
	"blocks": BLOCKS,  # Act VIII: the city-block grid (CityBlocks; {} = the defaults).
	"escalation": ESCALATION,  # Act VIII: the ladder stops at SWAT.
	"civilians": CIVILIANS,  # Act VIII: this stage's civilians overrides ({} = the defaults).
	"supers": SUPERS,  # Act VIII: the Supers the escalation sends (never before 0:00 here).
	"zones": ZONES,  # Act VIII: the four zones.
	"music": "siren",  # Act VIII: "Sirens at Midnight" (SoundData.SIREN_SCORE); also renders the City pack.
}
