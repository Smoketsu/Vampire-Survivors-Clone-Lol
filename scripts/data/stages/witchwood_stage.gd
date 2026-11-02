## WitchwoodStage — STAGE 20, THE WITCHWOOD (Act VII, the Sanguine Court; GDD
## §15.0 "Act VII foundation (phase 1)" and "The Witchwood (Act VII phase 2)";
## owner-approved proposal docs/act7/PROPOSAL.md "Stage 20: The Witchwood"). A
## black fen and a wood of hanging charms where the Court's witches keep their
## sabbath. Every number and event that belongs to this stage; StageRegistry
## exposes it to the run as `Game.stage_def` (the STAGE dictionary at the
## bottom; its keys are documented in StageRegistry). Unlocked by slaying Vargr
## on Ravensmoor.
##
## THE CLOCK IS AUTHORITATIVE, as on every stage since the Crimson March: four
## zones on fixed times (ZONES, run by MarchDirector: a zone banner, a sweep of
## mist, the obstacles and floor re-drawn as the next zone):
##   20:00  Zone I,   the Fen:             black peat and still pools of black
##                                         water that slow everyone (FenWater,
##                                         TerrainSlow); thralls, bats, the first
##                                         Bloated Thralls
##   15:00  Zone II,  the Hanging Wood:    dead trees hung with charms; the
##                                         Crimson Witches' first covens
##   10:00  Zone III, the Standing Stones: a heath of standing stones; the Bog
##                                         Mother at 9:00
##    5:00  Zone IV,  the Cauldron:        the witches' scorched clearing; the
##                                         most covens
##    3:00  Isolde Vane, the Witch of the Red Moon (BossIsolde, IsoldeData)
##    0:00  the Endless Feast (the shared Act VII Reckoning)
## Bloodfeast, Night Wings and the Blood Moon are the shared Court rules
## ("court": true; "moon": {} = the defaults). The witches' covens, hex circles,
## hex stones and blood pools are WitchHexes' (any stage). The stage systems run
## in WitchwoodDirector (WITCHWOOD): THE FEN, THE HEX STONES (three rise in
## each zone from 1:00: a coven near a standing stone casts without the moon,
## a broken stone's ground denies every coven), THE BOG MOTHER (the miniboss),
## and the coven events ("coven": tight triangles of three witches). Every
## rate, cap and weight is TUNING (not in GDD).
class_name WitchwoodStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "witchwood"

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act VII starts a step above Pandemonium's 1.75; the step goes in HP, not
## damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 1.85  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling
## (Pandemonium's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Acts III to VI: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 2 of Act VII

## The Blood Moon on this stage: {} = the defaults of CourtRulesData.BLOOD_MOON
## (any of its keys overrides them here). Isolde calls her own moon in her
## third phase (BloodMoon.force()).
const MOON := {}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Endless
## Feast, shared by every Act VII stage: the Blood Moon rises and never sets,
## feeding grows each minute, and coffins open and release nobles
## ("endless_feast": CourtRulesData.ENDLESS_FEAST keys; {} = those defaults);
## werewolves ("kind", beasts at once under the endless moon) come with thralls,
## bats and this wood's Bloated Thralls.
const RECKONING := {
	"banner": "THE ENDLESS FEAST: THE MOON WILL NOT SET",
	"kind": CourtEnemyData.WEREWOLF,  # The shared Endless Feast heavy.
	"endless_feast": {},  # CourtRulesData.ENDLESS_FEAST defaults.
	"companions": [{"kind": CourtEnemyData.VAMPIRE_BAT, "count": 8, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": CourtEnemyData.BLOOD_THRALL, "count": 4, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": WitchHexData.BLOATED, "count": 1, "growth": 1.0}],  # TUNING (not in GDD) the wood's swollen thralls: their pools feed the feast
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

## Continuous spawning segments, sorted by start time (keys as
## GraveyardStage.SEGMENTS). Blood thralls are the fodder, vampire bats the
## flying fodder (Night Wings), blood knights the soldiers, Bloated Thralls the
## heavies of the wood (they burst into healing pools: kill them away from the
## knights), Crimson Witches the support (rare alone: the covens come as events),
## werewolves and nobles the rare heavies and elites.
const SEGMENTS := [
	# Zone I, the Fen.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 1.0},
		"objective": "The Fen: the bitten servants wade toward you. The black water slows everyone"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.7, "vampire_bat": 0.3},
		"objective": "Bats fly over your ring: Archers, Mages and Gargoyles hit them in the air"},
	{"start": 150.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.55, "vampire_bat": 0.27, "blood_knight": 0.12, "bloated_thrall": 0.03},
		"objective": "Bloated Thralls burst into pools that heal the Court: kill them away from the knights"},
	# Zone II, the Hanging Wood: the witches.
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.46, "vampire_bat": 0.24, "blood_knight": 0.18, "bloated_thrall": 0.035, "crimson_witch": 0.03, "werewolf": 0.01, "vampire_noble": 0.01},
		"objective": "The Hanging Wood: break the covens. Kill one witch and the circle fails"},
	{"start": 450.0, "rate": 2.5, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.43, "vampire_bat": 0.24, "blood_knight": 0.2, "bloated_thrall": 0.035, "crimson_witch": 0.035, "werewolf": 0.012, "vampire_noble": 0.012},
		"objective": "Smash the hex stones: no coven casts on the ground of a broken stone"},
	# Zone III, the Standing Stones: the Bog Mother at 9:00.
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.4, "vampire_bat": 0.25, "blood_knight": 0.22, "bloated_thrall": 0.04, "crimson_witch": 0.035, "werewolf": 0.015, "vampire_noble": 0.015},
		"objective": "The Standing Stones: the stones power the covens. Break them"},
	{"start": 780.0, "rate": 2.85, "max_alive": 78,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.38, "vampire_bat": 0.25, "blood_knight": 0.23, "bloated_thrall": 0.04, "crimson_witch": 0.04, "werewolf": 0.018, "vampire_noble": 0.018},
		"objective": "The witches' sabbath gathers on the heath"},
	# Zone IV, the Cauldron: the density peak of the run.
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.36, "vampire_bat": 0.25, "blood_knight": 0.24, "bloated_thrall": 0.045, "crimson_witch": 0.04, "werewolf": 0.02, "vampire_noble": 0.02},
		"objective": "The Cauldron: the whole Court comes to the sabbath"},
	# 17:00, the boss: thinner, so the fight is the witch.
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"blood_thrall": 0.44, "vampire_bat": 0.28, "blood_knight": 0.2, "bloated_thrall": 0.03, "vampire_noble": 0.02},
		"objective": "Isolde has come for you: stay out of her circles, keep the thralls out of her pools"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave": formation + groups), plus the Witchwood's own (WitchwoodDirector):
##   "coven"      — `covens` covens of three Crimson Witches, each a tight
##                  triangle (coven_spread px) on the spawn ring, with the
##                  optional `escort` groups around each ({kind, count}).
##   "bog_mother" — the Bog Mother (kind `kind`) wades in on the spawn ring
##                  (the stage miniboss).
const EVENTS := [
	# Zone I: the Fen.
	{"time": 20.0, "type": "wave", "banner": "The bitten servants of the Court wade out of the fen!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "blood_thrall", "count": 16, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "A swarm of vampire bats! They fly over your ring!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_bat", "count": 10, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "BLOATED THRALLS! Kill them away from the knights: they burst into healing pools!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "bloated_thrall", "count": 2, "elite": false}, {"kind": "blood_thrall", "count": 10, "elite": false}]},
	{"time": 220.0, "type": "wave", "banner": "Blood Knights wade through the fen!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "blood_knight", "count": 4, "elite": false}, {"kind": "blood_thrall", "count": 8, "elite": false}]},
	{"time": 250.0, "type": "wave", "banner": "A werewolf hunter stalks you under the red moon!", "formation": "arc",  # TUNING (not in GDD) during the first Blood Moon
		"groups": [{"kind": "werewolf", "count": 1, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}]},
	# Zone II (5:00): the Hanging Wood.
	{"time": 320.0, "type": "coven", "covens": 1, "banner": "A COVEN of Crimson Witches! Kill one and their circle fails!",  # Owner-approved proposal (covens of three)
		"escort": [{"kind": "blood_thrall", "count": 6}]},
	{"time": 400.0, "type": "wave", "banner": "The swollen thralls lurch out of the trees!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "bloated_thrall", "count": 3, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}]},
	{"time": 470.0, "type": "coven", "covens": 2, "banner": "Two covens chant under the hanging charms!",  # TUNING (not in GDD) during the second Blood Moon
		"escort": [{"kind": "blood_knight", "count": 2}]},
	{"time": 540.0, "type": "wave", "banner": "A Vampire Noble! Burst her before she turns to mist!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_noble", "count": 1, "elite": false}, {"kind": "blood_knight", "count": 3, "elite": false}, {"kind": "blood_thrall", "count": 8, "elite": false}]},
	# Zone III (10:00): the Standing Stones; the Bog Mother at 9:00.
	{"time": 630.0, "type": "coven", "covens": 2, "banner": "The covens gather at the standing stones!",  # TUNING (not in GDD)
		"escort": [{"kind": "bloated_thrall", "count": 1}]},
	{"time": 660.0, "type": "bog_mother", "banner": "THE BOG MOTHER rises from the fen: she drags your dead into the black water!",  # Owner-approved proposal (miniboss); 9:00 left like the Gatekeeper
		"kind": "bog_mother", "elite": false},
	{"time": 720.0, "type": "wave", "banner": "Werewolves and their hunters!", "formation": "arc",  # TUNING (not in GDD) during the third Blood Moon
		"groups": [{"kind": "werewolf", "count": 2, "elite": false}, {"kind": "blood_thrall", "count": 12, "elite": false}]},
	{"time": 820.0, "type": "wave", "banner": "The nobles of the Court descend on the heath!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_noble", "count": 2, "elite": false}, {"kind": "blood_knight", "count": 4, "elite": false}, {"kind": "bloated_thrall", "count": 2, "elite": false}]},
	# Zone IV (15:00): the Cauldron.
	{"time": 920.0, "type": "coven", "covens": 3, "banner": "THE SABBATH: three covens around the cauldron!",  # TUNING (not in GDD)
		"escort": [{"kind": "blood_thrall", "count": 4}]},
	{"time": 980.0, "type": "wave", "banner": "The Court gathers for the sabbath!", "formation": "ring",  # TUNING (not in GDD) during the fourth Blood Moon
		"groups": [{"kind": "vampire_noble", "count": 2, "elite": false}, {"kind": "blood_knight", "count": 5, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}]},
	# 17:00 Isolde (BOSS_TIME).
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES
## (MarchDirector), plus `fen` (true: THE FEN's pools of black water lie on
## the ground and slow whoever wades them; WitchwoodDirector, WitchwoodGround).
## `ground` is a WitchwoodGround look:
##   style  — "fen" (black peat, still water), "hanging_wood" (dark leaf
##            litter and roots), "standing_stones" (a dark heath) or
##            "cauldron" (the scorched clearing).
##   base / line / accent / trim — colours of the code floor, its marks, its
##            stones and its red threads.
##   fen    — true: the floor draws the Fen's pools (the zone's own "fen").
## Obstacle kinds (WitchwoodGlyphs without art; obstacles/<kind>_<size>[_v]):
##   fen_snag       — the black stump of a drowned tree (circle)
##   standing_stone — a mossy grey-green standing stone (circle)
##   witch_cauldron — a black iron cauldron of red brew (circle)
##   charm_fence    — crooked stakes hung with charms and red threads (rect)
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Fen",  # Owner-approved proposal (zones)
		"blurb": "Black peat and still black water: it slows everyone",
		"fen": true,  # Owner-approved proposal: "the Fen (water slows everyone)"
		"ground": {"style": "fen", "fen": true, "base": Color(0.08, 0.10, 0.09), "line": Color(0.05, 0.06, 0.06),  # "fen": the floor draws the pools (WitchwoodGround)
			"accent": Color(0.13, 0.19, 0.12), "trim": Palette.COURT_BLOOD_DARK},
		"arena": {"density": 0.14, "clear_radius": 220.0, "layout_seed": 2020,  # TUNING (not in GDD) open: the water is the obstacle
			"kinds": {
				"fen_snag": {"weight": 0.75, "shape": "circle", "sizes": [12.0, 16.0, 20.0]},  # TUNING (not in GDD)
				"charm_fence": {"weight": 0.25, "shape": "rect", "sizes": [44.0, 56.0], "short": 20.0},  # TUNING (not in GDD)
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Hanging Wood",  # Owner-approved proposal (zones)
		"blurb": "Dead trees hung with charms, bones and red thread",
		"ground": {"style": "hanging_wood", "base": Color(0.09, 0.08, 0.07), "line": Color(0.06, 0.05, 0.04),
			"accent": Color(0.15, 0.12, 0.09), "trim": Palette.COURT_BLOOD},
		"arena": {"density": 0.22, "clear_radius": 220.0, "layout_seed": 2030,  # TUNING (not in GDD) a thick wood
			"kinds": {
				"fen_snag": {"weight": 0.5, "shape": "circle", "sizes": [12.0, 16.0, 20.0]},  # TUNING (not in GDD) dead trees
				"charm_fence": {"weight": 0.5, "shape": "rect", "sizes": [44.0, 56.0], "short": 20.0},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Standing Stones",  # Owner-approved proposal (zones)
		"blurb": "A dark heath where the stones hum with the witches' power",
		"ground": {"style": "standing_stones", "base": Color(0.08, 0.09, 0.08), "line": Color(0.05, 0.06, 0.05),
			"accent": Color(0.14, 0.15, 0.16), "trim": Palette.COURT_BLOOD_DARK},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 2040,  # TUNING (not in GDD)
			"kinds": {
				"standing_stone": {"weight": 0.7, "shape": "circle", "sizes": [12.0, 16.0, 22.0]},  # TUNING (not in GDD)
				"fen_snag": {"weight": 0.3, "shape": "circle", "sizes": [12.0, 16.0, 20.0]},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Cauldron",  # Owner-approved proposal (zones)
		"blurb": "The witches' scorched clearing around the great cauldron",
		"ground": {"style": "cauldron", "base": Color(0.09, 0.08, 0.08), "line": Color(0.05, 0.04, 0.04),
			"accent": Color(0.14, 0.10, 0.09), "trim": Palette.COURT_BLOOD},
		"arena": {"density": 0.17, "clear_radius": 220.0, "layout_seed": 2050,  # TUNING (not in GDD)
			"kinds": {
				"witch_cauldron": {"weight": 0.4, "shape": "circle", "sizes": [12.0, 16.0, 22.0]},  # TUNING (not in GDD)
				"charm_fence": {"weight": 0.35, "shape": "rect", "sizes": [44.0, 56.0], "short": 20.0},  # TUNING (not in GDD)
				"standing_stone": {"weight": 0.25, "shape": "circle", "sizes": [12.0, 16.0, 22.0]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "DEEPER INTO THE WITCHWOOD  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(0.878, 0.220, 0.306),  # Blood light (Palette.COURT_BLOOD_LIGHT), never the UI's soul-teal.
	"fog_color": Color(0.07, 0.08, 0.08),  # Fen mist.
	"fog_bank_color": Color(0.30, 0.34, 0.32),  # Grey-green mist banks.
	"zones": ZONES,
}

## The Witchwood's stage systems (WitchwoodDirector; StageRegistry
## "witchwood").
##   fen     — THE FEN (zones with "fen": true):
##     cell         — px of a grid cell; at most one pool per cell.
##     chance       — 0..1: share of cells holding a pool.
##     radius_min / radius_max — px of a pool.
##     seed         — salt of the pools' hash (fixed: the map is the same
##                    every run, as the obstacles' layout_seed).
##     check_every  — s between two checks of who wades.
##     linger       — s a slow outlasts the next check.
##     slow_player / slow_summon / slow_enemy — share of speed lost in the water.
##   stones  — THE HEX STONES:
##     first        — game s the first stones rise (then at every zone).
##     count        — stones per zone.
##     distance     — px from the necromancer they rise.
##     banner       — banner when they rise.
##   bog_mother_objective — HUD objective while the Bog Mother stands.
##   coven_spread — px from a coven event's centre each of its witches appears.
##   zones   — ZONES (the director reads "fen").
const WITCHWOOD := {
	"fen": {
		"cell": 300.0,  # TUNING (not in GDD) px
		"chance": 0.42,  # TUNING (not in GDD)
		"radius_min": 46.0,  # TUNING (not in GDD) px
		"radius_max": 92.0,  # TUNING (not in GDD) px
		"seed": 2020,  # TUNING (not in GDD)
		"check_every": 0.25,  # TUNING (not in GDD) s
		"linger": 0.2,  # TUNING (not in GDD) s
		"slow_player": 0.3,  # TUNING (not in GDD) (the Styx 0.35)
		"slow_summon": 0.3,  # TUNING (not in GDD)
		"slow_enemy": 0.3,  # TUNING (not in GDD) everyone: "water slows everyone"
	},
	"stones": {
		"first": 60.0,  # TUNING (not in GDD) s (the Fen gets its stones a minute in)
		"count": 3,  # TUNING (not in GDD)
		"distance": 380.0,  # TUNING (not in GDD) px
		"banner": "HEX STONES rise from the ground: they power the covens. Break them!",  # TUNING (not in GDD)
	},
	"bog_mother_objective": "Bring down the Bog Mother: keep your dead out of her reach and her black water",  # TUNING (not in GDD)
	"coven_spread": 34.0,  # TUNING (not in GDD) px
	"zones": ZONES,
}

## Isolde's arrival (keys as GraveyardStage.BOSS): her own IsoldeData.ARRIVAL
## (boss id "isolde"), whose `time` equals BOSS_TIME (17:00). Her script is
## scripts/enemies/court/boss_isolde.gd (loaded by her id).
const BOSS: Dictionary = IsoldeData.ARRIVAL

## Placeholder floor of the foundation stub (CourtGround "floor" key), kept for
## the other tools that read it; the stage draws WitchwoodGround ("ground").
const FLOOR := {
	"style": "fen",  # Black fen mud, still pools, red charm threads.
	"base": Color(0.09, 0.11, 0.10),  # TUNING (not in GDD) black fen mud
	"line": Color(0.13, 0.15, 0.13),  # TUNING (not in GDD)
	"accent": Color(0.05, 0.06, 0.07),  # TUNING (not in GDD) still pools
	"trim": Palette.COURT_BLOOD,  # TUNING (not in GDD) red charm threads
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Witchwood",
	"short_name": "The Witchwood",
	"chapter": "Chapter XX",
	"act": 7,  # Act VII, the Sanguine Court.
	"playable": false,  # Phase 2 built; hidden until the lead's integration and the owner's review (brief: keep "playable": false).
	"description": "A black fen and a wood of hanging charms where the Court's witches keep their sabbath, their circles drawn in blood on the standing stones.",
	"unlock": {"stage": "ravensmoor", "boss_kills": 1},  # Owner-approved: each Act VII stage opens the next
	"unlock_text": "Slay Vargr on Ravensmoor to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act VII stages.
	"consecration": {},  # A Covenant event: none in Act VII.
	"crypt_defender": {},  # None in Act VII.
	"arena": ZONES[0]["arena"],
	"ground": "witchwood",  # WitchwoodGround: the four zone floors and the Fen's water.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"witchwood": WITCHWOOD,  # WitchwoodDirector: the Fen, the hex stones, the Bog Mother, the covens.
	"court": true,  # Act VII: Bloodfeast, Night Wings, the Blood Moon (CourtRules).
	"moon": MOON,  # Act VII: this stage's Blood Moon overrides ({} = the defaults).
	"zones": ZONES,  # Act VII: the four zones.
	# Music: "Waltz of the Red Moon" (SoundData.SANGUINE_SCORE).
	"music": "sanguine",
}
