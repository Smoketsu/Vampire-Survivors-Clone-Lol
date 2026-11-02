## CastleSanguisStage — STAGE 21, CASTLE SANGUIS, the finale of Act VII (the
## Sanguine Court; GDD §15.0 "Act VII foundation (phase 1)" and "Castle Sanguis
## (Act VII phase 2)"; owner-approved proposal docs/act7/PROPOSAL.md "Stage 21:
## Castle Sanguis"). The Court itself: a castle above the clouds of the moor,
## its banquet set for a thousand years. Every number and event that belongs to
## this stage; StageRegistry exposes it to the run as `Game.stage_def` (the
## STAGE dictionary at the bottom; its keys are documented in StageRegistry).
## Unlocked by slaying Isolde Vane in the Witchwood.
##
## THE CLOCK IS AUTHORITATIVE, as on every zoned stage: four zones on fixed
## times (ZONES, run by MarchDirector: a zone banner, a sweep of mist, the
## obstacles and floor re-drawn as the next zone), and the Sanguine Court's
## three shared rules run all along (Game.court: Bloodfeast, Night Wings, the
## Blood Moon at 4:00, 8:00, 12:00 and 16:00 elapsed):
##   20:00  Zone I,   the Courtyard:      moonlit flagstones, a well, gargoyle
##                                         statues, low castle walls; thralls,
##                                         bats, Blood Knights
##   15:00  Zone II,  the Banquet Hall:   the long tables, candelabra, wine
##                                         barrels; THE BANQUET: blood
##                                         fountains heal every Court enemy
##                                         standing in them (a Bone Wall or a
##                                         Bone Golem on one denies it); the
##                                         CHIROPTERANS glide in; nobles
##   10:00  Zone III, the Crypt Gallery:  sarcophagi, crypt pillars, blood
##                                         urns; werewolves
##    8:20  THE CHIROPTERAN KING, the miniboss (he carries summons off)
##    5:00  Zone IV,  the Throne of Blood: the fountains again before the
##                                         throne, gargoyles and candelabra
##    3:00  QUEEN CARMILLA AND THE ELDER (BossCarmilla, CarmillaData): the
##          Court, the Waking, the Elder; beaten, the Elder turns to ash
##    0:00  THE ENDLESS FEAST (the shared Act VII Reckoning)
## The other Act VII stages' kinds (Ravensmoor's Ghoul, the Witchwood's Crimson
## Witch and Bloated Thrall; never their minibosses) join as guest squads
## (CASTLE_SANGUIS "guests", CastleSanguisDirector), like Pandemonium's guests.
## Every rate, cap and weight is TUNING (not in GDD) unless marked as the
## owner-approved proposal.
class_name CastleSanguisStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "castle_sanguis"

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act VII starts a step above Pandemonium's 1.75; the step goes in HP, not
## damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 1.85  # TUNING (not in GDD) the foundation's placeholder, kept; tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling
## (Pandemonium's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) the foundation's placeholder, kept
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) (Acts III to VI: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 3 of Act VII

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES.
## `ground` is a CastleSanguisGround look: style "courtyard" (moonlit grey
## flagstones, moss, a scatter of feathers), "banquet" (dark boards under a
## blood-red runner, spilt wine), "crypt" (cold slabs, bones, candle stubs) or
## "throne" (black marble veined red, gold inlay, pooled blood); base / line /
## accent colours of the code floor (the tiles/castle_sanguis_<style> PNG
## replaces them when it exists). Obstacle kinds are drawn by
## CastleSanguisGlyphs (their obstacles/<kind> PNGs when they exist).
const ZONES := [
	{"id": "courtyard", "start": 0.0, "numeral": "I", "name": "The Courtyard",  # Owner-approved proposal zone I
		"blurb": "Moonlit flagstones above the clouds, where the Court's gargoyles keep watch",
		"ground": {"style": "courtyard", "base": Color(0.17, 0.17, 0.19), "line": Color(0.11, 0.11, 0.13),
			"accent": Palette.COURT_MOON_DARK},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 2101,  # TUNING (not in GDD)
			"kinds": {
				"castle_well": {"weight": 0.25, "shape": "circle", "sizes": [14.0, 18.0]},  # TUNING (not in GDD)
				"gargoyle_statue": {"weight": 0.35, "shape": "circle", "sizes": [12.0, 15.0]},  # TUNING (not in GDD)
				"castle_wall": {"weight": 0.4, "shape": "rect", "sizes": [44.0, 60.0], "short": 16.0},  # TUNING (not in GDD)
			}},
	},
	{"id": "banquet_hall", "start": 300.0, "numeral": "II", "name": "The Banquet Hall",  # Owner-approved proposal zone II
		"blurb": "A banquet set for a thousand years, and fountains running with blood",
		"ground": {"style": "banquet", "base": Color(0.11, 0.07, 0.07), "line": Color(0.07, 0.04, 0.04),
			"accent": Palette.COURT_BLOOD},
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 2102,  # TUNING (not in GDD) open: the fountains are the feature here
			"kinds": {
				"feast_table": {"weight": 0.5, "shape": "rect", "sizes": [44.0, 60.0], "short": 16.0},  # TUNING (not in GDD)
				"candelabra": {"weight": 0.25, "shape": "circle", "sizes": [10.0, 12.0]},  # TUNING (not in GDD)
				"wine_barrel": {"weight": 0.25, "shape": "circle", "sizes": [10.0, 12.0]},  # TUNING (not in GDD)
			}},
	},
	{"id": "crypt_gallery", "start": 600.0, "numeral": "III", "name": "The Crypt Gallery",  # Owner-approved proposal zone III
		"blurb": "The Court's dead lie in state here, and not all of them sleep",
		"ground": {"style": "crypt", "base": Color(0.09, 0.09, 0.11), "line": Color(0.05, 0.05, 0.07),
			"accent": Palette.BONE},
		"arena": {"density": 0.24, "clear_radius": 220.0, "layout_seed": 2103,  # TUNING (not in GDD)
			"kinds": {
				"sarcophagus": {"weight": 0.4, "shape": "rect", "sizes": [44.0, 60.0], "short": 16.0},  # TUNING (not in GDD)
				"crypt_pillar": {"weight": 0.35, "shape": "circle", "sizes": [14.0, 18.0, 22.0]},  # TUNING (not in GDD)
				"blood_urn": {"weight": 0.25, "shape": "circle", "sizes": [10.0, 12.0]},  # TUNING (not in GDD)
			}},
	},
	{"id": "throne_of_blood", "start": 900.0, "numeral": "IV", "name": "The Throne of Blood",  # Owner-approved proposal zone IV
		"blurb": "Black marble, red velvet and the Queen's throne, carved from one great clot",
		"ground": {"style": "throne", "base": Color(0.06, 0.04, 0.06), "line": Color(0.14, 0.06, 0.09),
			"accent": Palette.GOLD},
		"arena": {"density": 0.2, "clear_radius": 240.0, "layout_seed": 2104,  # TUNING (not in GDD)
			"kinds": {
				"gargoyle_statue": {"weight": 0.35, "shape": "circle", "sizes": [12.0, 15.0]},  # TUNING (not in GDD)
				"candelabra": {"weight": 0.3, "shape": "circle", "sizes": [10.0, 12.0]},  # TUNING (not in GDD)
				"blood_urn": {"weight": 0.35, "shape": "circle", "sizes": [10.0, 12.0]},  # TUNING (not in GDD)
			}},
	},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "DEEPER INTO CASTLE SANGUIS  -  ZONE %s",
	"zone_color": Palette.COURT_BLOOD_LIGHT,  # The Court's blood red.
	"fog_color": Color(0.08, 0.06, 0.09),  # Night mist.
	"fog_bank_color": Color(0.36, 0.38, 0.44),  # Cloud banks under the castle.
	"zones": ZONES,
}

## The Blood Moon on this stage: {} = the defaults of CourtRulesData.BLOOD_MOON
## (4:00, 8:00, 12:00, 16:00 for 45 s).
const MOON := {}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Endless
## Feast, shared by every Act VII stage: the Blood Moon rises and never sets,
## feeding grows each minute, and coffins open and release nobles
## ("endless_feast": CourtRulesData.ENDLESS_FEAST keys; {} = those defaults);
## werewolves ("kind", beasts at once under the endless moon) come with thralls,
## bats and the finale's own Chiropterans.
const RECKONING := {
	"banner": "THE ENDLESS FEAST: THE MOON WILL NOT SET",
	"kind": CourtEnemyData.WEREWOLF,  # The shared Endless Feast heavy.
	"endless_feast": {},  # CourtRulesData.ENDLESS_FEAST defaults.
	"companions": [{"kind": CourtEnemyData.VAMPIRE_BAT, "count": 8, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": CourtEnemyData.BLOOD_THRALL, "count": 4, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": CastleSanguisEnemyData.CHIROPTERAN, "count": 1, "growth": 0.5}],  # TUNING (not in GDD) the finale's own elite
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) werewolves are heavy
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE ENDLESS FEAST: the moon will not set, and the Court will feed. Endure."

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): thralls and
## bats first, then Blood Knights; the Chiropterans glide in with the Banquet
## Hall; nobles and werewolves stay rare (elites / heavies).
const SEGMENTS := [
	# Zone I, the Courtyard.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 1.0},
		"objective": "The Courtyard: the bitten servants stagger toward you. They feed on what they bite"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.7, "vampire_bat": 0.3},
		"objective": "Bats fly over your ring: Archers, Mages and Gargoyles hit them in the air"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.55, "vampire_bat": 0.28, "blood_knight": 0.17},
		"objective": "Blood Knights feed on every blow: Rot and Wither halve it"},
	# Zone II, the Banquet Hall.
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.47, "vampire_bat": 0.28, "blood_knight": 0.2, "chiropteran": 0.02, "vampire_noble": 0.015, "werewolf": 0.015},
		"objective": "The Banquet Hall: the fountains heal the Court. Fight them away from the blood"},
	{"start": 420.0, "rate": 2.5, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.43, "vampire_bat": 0.28, "blood_knight": 0.22, "chiropteran": 0.03, "vampire_noble": 0.02, "werewolf": 0.015},
		"objective": "Chiropterans shriek from above: step out of the cone"},
	# Zone III, the Crypt Gallery.
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.4, "vampire_bat": 0.27, "blood_knight": 0.25, "chiropteran": 0.03, "vampire_noble": 0.025, "werewolf": 0.02},
		"objective": "The Crypt Gallery: the nobles drain from afar. Burst them before they turn to mist"},
	# Zone IV, the Throne of Blood.
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.38, "vampire_bat": 0.28, "blood_knight": 0.26, "chiropteran": 0.035, "vampire_noble": 0.025, "werewolf": 0.02},
		"objective": "The Throne of Blood: the whole Court comes to feed"},
	# 17:00, the boss: a thinner trickle so the fight stays readable.
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.42, "vampire_bat": 0.3, "blood_knight": 0.22, "chiropteran": 0.03, "vampire_noble": 0.015, "werewolf": 0.015},
		"objective": "Bring down the Queen of the Court"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus the
## CastleSanguisDirector's "chiropteran_king" (the miniboss `kind` lands with
## its `escort` groups)). Vampire bats come in swarms of 10 (owner-approved
## proposal).
const EVENTS := [
	# Zone I: the Courtyard.
	{"time": 20.0, "type": "wave", "banner": "The bitten servants of the Court shamble across the courtyard!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "blood_thrall", "count": 16, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "A swarm of vampire bats pours off the battlements!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_bat", "count": 10, "elite": false}]},
	{"time": 190.0, "type": "wave", "banner": "Blood Knights stand guard at the castle gate!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "blood_knight", "count": 4, "elite": false}, {"kind": "blood_thrall", "count": 10, "elite": false}]},
	{"time": 250.0, "type": "wave", "banner": "A Chiropteran glides over the walls under the red moon!", "formation": "arc",  # TUNING (not in GDD) during the first Blood Moon
		"groups": [{"kind": "chiropteran", "count": 1, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}]},
	# Zone II (5:00): the Banquet Hall.
	{"time": 330.0, "type": "wave", "banner": "The Court rises from its banquet!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "blood_knight", "count": 4, "elite": false}, {"kind": "blood_thrall", "count": 12, "elite": false}]},
	{"time": 400.0, "type": "wave", "banner": "A Vampire Noble leaves the high table! Burst her before she turns to mist!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_noble", "count": 1, "elite": false}, {"kind": "chiropteran", "count": 1, "elite": false}, {"kind": "blood_thrall", "count": 8, "elite": false}]},
	{"time": 485.0, "type": "wave", "banner": "Chiropterans swoop from the rafters!", "formation": "ring",  # TUNING (not in GDD) during the second Blood Moon
		"groups": [{"kind": "chiropteran", "count": 2, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}, {"kind": "blood_knight", "count": 3, "elite": false}]},
	{"time": 555.0, "type": "wave", "banner": "A werewolf hunter stalks the banquet!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "werewolf", "count": 1, "elite": false}, {"kind": "blood_thrall", "count": 10, "elite": false}]},
	# Zone III (10:00): the Crypt Gallery.
	{"time": 630.0, "type": "wave", "banner": "The nobles rise from their sarcophagi!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_noble", "count": 2, "elite": false}, {"kind": "blood_knight", "count": 4, "elite": false}]},
	{"time": 700.0, "type": "chiropteran_king", "banner": "THE CHIROPTERAN KING descends on vast wings: he carries your dead away!", "kind": CastleSanguisEnemyData.KING,  # Owner-approved proposal: the miniboss
		"escort": [{"kind": "chiropteran", "count": 2, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}]},  # TUNING (not in GDD)
	{"time": 790.0, "type": "wave", "banner": "Werewolves in the crypt!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "werewolf", "count": 2, "elite": false}, {"kind": "blood_thrall", "count": 12, "elite": false}]},
	{"time": 850.0, "type": "wave", "banner": "Bat-folk and nobles!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "chiropteran", "count": 2, "elite": false}, {"kind": "vampire_noble", "count": 1, "elite": false}, {"kind": "blood_knight", "count": 4, "elite": false}]},
	# Zone IV (15:00): the Throne of Blood.
	{"time": 930.0, "type": "wave", "banner": "The Queen's guard bars the way to the throne!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "blood_knight", "count": 6, "elite": false}, {"kind": "blood_thrall", "count": 12, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The whole Court gathers for its last feast!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_noble", "count": 2, "elite": false}, {"kind": "blood_knight", "count": 5, "elite": false}, {"kind": "chiropteran", "count": 2, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}]},
	# 17:00 Queen Carmilla (BOSS_TIME), plus two sallies.
	{"time": 1090.0, "type": "wave", "banner": "The Court rallies to its Queen!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "blood_knight", "count": 5, "elite": false}, {"kind": "chiropteran", "count": 1, "elite": false}, {"kind": "blood_thrall", "count": 10, "elite": false}]},
	{"time": 1160.0, "type": "wave", "banner": "The bats darken the throne room!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_bat", "count": 10, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}]},
]

## Castle Sanguis's systems (CastleSanguisDirector; StageRegistry "castle_sanguis").
##   fountains — THE BANQUET (owner-approved proposal: "blood fountains in the
##       hall heal any Court enemy that stands in them; Bone Wall segments or a
##       Golem parked on a fountain deny it"):
##         windows      — [from, until, count] game-second windows in which
##                        `count` fountains stand (the Banquet Hall and the
##                        Throne of Blood); outside them none.
##         radius       — px of a fountain's pool (a Court enemy whose centre
##                        is inside it drinks).
##         heal         — share (0..1) of a drinker's max HP healed per second
##                        (CombatResolver.heal_enemy(), the enemy heal path).
##         boss_mult    — x that share for a boss or a miniboss.
##         tick         — s between two heals.
##         ring_min / ring_max — px from the necromancer a fountain rises.
##         keep         — px from the necromancer beyond which a fountain
##                        dries up and rises again nearer (the castle is
##                        endless; so is its feast).
##         spacing      — px at least between two fountains.
##         golem_classes — summon classes whose body on a fountain denies it
##                        (the Bone Golem; its evolution keeps its class).
##   guest_* / guests — the other Act VII stages' kinds in small squads (as
##       PandemoniumStage.PANDEMONIUM): candidate ids per kind (the first one
##       this build knows; none = skipped) and a weight. The ids were guessed
##       while the three Act VII stages were built in parallel (ghoul,
##       crimson_witch, bloated_thrall); minibosses are never guests.
const CASTLE_SANGUIS := {
	"fountains": {
		"windows": [[300.0, 600.0, 3], [900.0, 1e9, 2]],  # TUNING (not in GDD) the Banquet Hall (3), the Throne of Blood (2)
		"radius": 30.0,  # TUNING (not in GDD) px
		"heal": 0.03,  # TUNING (not in GDD) share of max HP per second; first pass 0.05 fed the werewolves 7000 HP in the seed-7 army run
		"boss_mult": 0.2,  # TUNING (not in GDD) a boss / miniboss drinks a fifth as much
		"tick": 0.5,  # TUNING (not in GDD) s
		"ring_min": 150.0,  # TUNING (not in GDD) px
		"ring_max": 300.0,  # TUNING (not in GDD) px
		"keep": 520.0,  # TUNING (not in GDD) px
		"spacing": 120.0,  # TUNING (not in GDD) px
		"golem_classes": ["bone_golem"],  # Owner-approved proposal: "a Golem parked on a fountain"
	},
	"guest_first": 300.0,  # TUNING (not in GDD) no guests before 5:00
	"guest_interval": 85.0,  # TUNING (not in GDD)
	"guest_until": 1000.0,  # TUNING (not in GDD) the boss fight keeps its own roster
	"guest_count": 3,  # TUNING (not in GDD)
	"guest_growth": 0.4,  # TUNING (not in GDD)
	"guest_max": 6,  # TUNING (not in GDD)
	"guests": [
		{"ids": ["ghoul"], "weight": 0.8},  # Ravensmoor (Act VII phase 2): the Ghouls (guessed id)
		{"ids": ["crimson_witch"], "weight": 0.4},  # The Witchwood: the Crimson Witches (guessed id)
		{"ids": ["bloated_thrall"], "weight": 0.5},  # The Witchwood: the Bloated Thralls (guessed id)
	],
}

## Obstacle layout of the first zone (keys as GraveyardStage.ARENA; every zone
## has its own in ZONES).
const ARENA: Dictionary = ZONES[0]["arena"]

## Queen Carmilla's arrival (keys as GraveyardStage.BOSS): CarmillaData.ARRIVAL
## (boss id "carmilla", the ending line as the defeat banner), whose `time`
## equals BOSS_TIME (17:00). Her script is scripts/enemies/court/
## boss_carmilla.gd (found by the boss id).
const BOSS: Dictionary = CarmillaData.ARRIVAL

## Floor look of the placeholder "court" ground (CourtGround; the stage now
## uses CastleSanguisGround and its ZONES, this stays for any caller of "floor").
const FLOOR := {
	"style": "castle",  # Castle stone, velvet runners, spilt wine.
	"base": Color(0.15, 0.13, 0.15),  # TUNING (not in GDD) castle stone
	"line": Color(0.21, 0.18, 0.21),  # TUNING (not in GDD)
	"accent": Palette.COURT_VELVET,  # TUNING (not in GDD) velvet runners
	"trim": Palette.COURT_BLOOD,  # TUNING (not in GDD) spilt wine
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Castle Sanguis",
	"short_name": "Castle Sanguis",
	"chapter": "Chapter XXI",
	"act": 7,  # Act VII, the Sanguine Court.
	"playable": false,  # Phase 2 built; hidden from the stage select until the lead's integration and the owner's go.
	"description": "The Court itself: a castle above the clouds of the moor, its banquet set for a thousand years, and in its crypt the coffin of the first vampire.",
	"unlock": {"stage": "witchwood", "boss_kills": 1},  # Owner-approved: each Act VII stage opens the next
	"unlock_text": "Slay Isolde Vane in the Witchwood to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act VII stages.
	"consecration": {},  # A Covenant event: none in Act VII.
	"crypt_defender": {},  # None in Act VII.
	"arena": ARENA,
	"ground": "castle_sanguis",  # CastleSanguisGround (the four zone floors).
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"castle_sanguis": CASTLE_SANGUIS,  # CastleSanguisDirector (the Banquet's fountains, the Chiropteran King, guests).
	"court": true,  # Act VII: Bloodfeast, Night Wings, the Blood Moon (CourtRules).
	"moon": MOON,  # Act VII: this stage's Blood Moon overrides ({} = the defaults).
	"zones": ZONES,  # The four zones (MarchDirector reads them through "march").
	# Music: "Waltz of the Red Moon" (SoundData.SANGUINE_SCORE).
	"music": "sanguine",
}
