## RavensmoorStage — STAGE 19, RAVENSMOOR (Act VII, the Sanguine Court; GDD
## §15.0 "Act VII foundation (phase 1)" and "Ravensmoor (Act VII phase 2)";
## owner-approved proposal docs/act7/PROPOSAL.md "Stage 19: Ravensmoor"). A
## cursed village on the moors below the Court's castle, its people long since
## turned to thralls. Every number and event that belongs to this stage;
## StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
## Unlocked by casting down the Morning Star in Pandemonium.
##
## THE CLOCK IS AUTHORITATIVE, as on every stage since the Crimson March: four
## zones on fixed times (ZONES, run by MarchDirector: a zone banner, a sweep of
## moor mist, the obstacles and floor re-drawn as the next zone). Each zone
## changes as a Blood Moon sets (the moon's defaults: up at 4:00, 8:00, 12:00
## and 16:00 for 45 s), so every zone has one moon to race:
##   20:00  Zone I,   the Moor:       heather and peat, grey cairns; the
##                                    thralls, the first bats and ghoul packs
##   15:15  Zone II,  the Village:    the thralls' cottages and fences; the
##                                    Blood Knights, the werewolf hunters
##   11:15  Zone III, the Old Church: the ruined church and its graves; the
##                                    nobles; Old Greymane at 9:00
##    7:15  Zone IV,  the Wolfwood:   black pines; the werewolves at their
##                                    thickest
##    3:00  Vargr, the Moon-Eater (BossVargr, VargrData)
##    0:00  the Endless Feast (the shared Act VII Reckoning)
## Bloodfeast, Night Wings and the Blood Moon are the shared Court rules
## ("court": true; "moon": {} = the defaults). The stage systems run in
## RavensmoorDirector (RAVENSMOOR): THE SLEEPING COFFINS (a wave in each zone,
## a Soul Ash bounty each if broken before the moon, a noble out of each one
## left whole when it rises), COFFIN NAILS (the achievement), THE GHOUL PACKS
## and OLD GREYMANE (the miniboss). Every rate, cap and weight is TUNING (not in
## GDD).
class_name RavensmoorStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "ravensmoor"

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act VII starts a step above Pandemonium's 1.75; the step goes in HP, not
## damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 1.85  # TUNING (not in GDD) the foundation's step, kept
## Enemy damage multiplier of this stage on top of the shared time scaling
## (Pandemonium's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) the foundation's, kept
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) Acts III to VI: 7:00
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 1 of Act VII

## The Blood Moon on this stage: {} = the defaults of CourtRulesData.BLOOD_MOON
## (owner-approved: every 4:00 for 45 s; the zones change as each one sets).
## Vargr calls his own moons through BloodMoon.force().
const MOON := {}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Endless
## Feast, shared by every Act VII stage: the Blood Moon rises and never sets,
## feeding grows each minute, and coffins open and release nobles
## ("endless_feast": CourtRulesData.ENDLESS_FEAST keys; {} = those defaults);
## werewolves ("kind", beasts at once under the endless moon) come with
## thralls, bats and the moor's ghouls.
const RECKONING := {
	"banner": "THE ENDLESS FEAST: THE MOON WILL NOT SET",
	"kind": CourtEnemyData.WEREWOLF,  # The shared Endless Feast heavy.
	"endless_feast": {},  # CourtRulesData.ENDLESS_FEAST defaults.
	"companions": [{"kind": CourtEnemyData.VAMPIRE_BAT, "count": 6, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": CourtEnemyData.BLOOD_THRALL, "count": 4, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": CourtEnemyData.GHOUL, "count": 4, "growth": 1.0}],  # TUNING (not in GDD) a pack of the moor's ghouls
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
## flying fodder (fewer than the stub's: their dives on the necromancer were
## the stub's sharpest danger), ghouls the packs (mostly from
## RavensmoorDirector's pack timer; a few strays here), Blood Knights the
## soldiers, werewolf hunters the heavies, vampire nobles the rare elites
## (every unbroken coffin adds one at a moon).
const SEGMENTS := [
	# Zone I, the Moor.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 1.0},
		"objective": "The Moor: the bitten servants stagger toward you. Break the sleeping coffins before the moon"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.75, "vampire_bat": 0.2, "ghoul": 0.05},
		"objective": "Bats fly over your ring: Archers, Mages and Gargoyles hit them in the air"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.6, "vampire_bat": 0.2, "ghoul": 0.05, "blood_knight": 0.15},
		"objective": "Ghouls eat the fallen: kill them before they reach the corpses"},
	# Zone II, the Village (4:45, as the first moon sets).
	{"start": 285.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.5, "vampire_bat": 0.2, "ghoul": 0.06, "blood_knight": 0.22, "werewolf": 0.015, "vampire_noble": 0.008},
		"objective": "The Village: burst the werewolf hunters before the moon turns them"},
	{"start": 420.0, "rate": 2.5, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.48, "vampire_bat": 0.2, "ghoul": 0.06, "blood_knight": 0.24, "werewolf": 0.018, "vampire_noble": 0.01},
		"objective": "Blood Knights feed on every blow: Rot and Wither halve it"},
	# Zone III, the Old Church (8:45): Old Greymane at 11:00.
	{"start": 525.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.45, "vampire_bat": 0.2, "ghoul": 0.06, "blood_knight": 0.26, "werewolf": 0.02, "vampire_noble": 0.012},
		"objective": "The Old Church: the nobles drain from afar. Burst them before they turn to mist"},
	# Zone IV, the Wolfwood (12:45): the werewolves at their thickest.
	{"start": 765.0, "rate": 2.9, "max_alive": 80,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.42, "vampire_bat": 0.2, "ghoul": 0.06, "blood_knight": 0.26, "werewolf": 0.03, "vampire_noble": 0.012},
		"objective": "The Wolfwood: the pack hunts among the pines"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"blood_thrall": 0.42, "vampire_bat": 0.2, "ghoul": 0.06, "blood_knight": 0.26, "werewolf": 0.03, "vampire_noble": 0.012},
		"objective": "The whole Court comes to feed"},
	# 17:00, the boss: thinner, so the fight is the hunt.
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"blood_thrall": 0.5, "vampire_bat": 0.18, "ghoul": 0.06, "blood_knight": 0.24, "vampire_noble": 0.01},
		"objective": "Vargr has come for you: watch for his lunge and his leap"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave": formation + groups; vampire bats come in swarms of 10 and ghouls in
## packs of 4, owner-approved proposal), plus Ravensmoor's own
## (RavensmoorDirector):
##   "greymane" — Old Greymane (kind `kind`) walks in on the spawn ring with
##                `pack` werewolf hunters (the stage miniboss).
const EVENTS := [
	# Zone I: the Moor.
	{"time": 20.0, "type": "wave", "banner": "The bitten servants of the Court shamble out of the dark!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "blood_thrall", "count": 16, "elite": false}]},
	{"time": 100.0, "type": "wave", "banner": "A swarm of vampire bats! They fly over your ring!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_bat", "count": 10, "elite": false}]},
	{"time": 150.0, "type": "wave", "banner": "GHOULS! They eat the fallen: kill them before they reach the corpses!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "ghoul", "count": 4, "elite": false}, {"kind": "ghoul", "count": 4, "elite": false}, {"kind": "blood_thrall", "count": 8, "elite": false}]},
	{"time": 210.0, "type": "wave", "banner": "Blood Knights advance in blood-red plate!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "blood_knight", "count": 4, "elite": false}, {"kind": "blood_thrall", "count": 10, "elite": false}]},
	# Zone II (4:45): the Village.
	{"time": 300.0, "type": "wave", "banner": "A werewolf hunter stalks the village!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "werewolf", "count": 1, "elite": false}, {"kind": "ghoul", "count": 4, "elite": false}]},
	{"time": 380.0, "type": "wave", "banner": "A Vampire Noble! Burst her before she turns to mist!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_noble", "count": 1, "elite": false}, {"kind": "blood_thrall", "count": 10, "elite": false}]},
	{"time": 470.0, "type": "wave", "banner": "The bats darken the sky!", "formation": "ring",  # TUNING (not in GDD) during the second Blood Moon
		"groups": [{"kind": "vampire_bat", "count": 10, "elite": false}, {"kind": "blood_knight", "count": 3, "elite": false}]},
	# Zone III (8:45): the Old Church; Old Greymane at 11:00.
	{"time": 560.0, "type": "wave", "banner": "Werewolves and their hunters!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "werewolf", "count": 2, "elite": false}, {"kind": "ghoul", "count": 4, "elite": false}, {"kind": "blood_thrall", "count": 10, "elite": false}]},
	{"time": 600.0, "type": "wave", "banner": "The nobles of the Court descend on the churchyard!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_noble", "count": 1, "elite": false}, {"kind": "blood_knight", "count": 4, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}]},
	{"time": 660.0, "type": "greymane", "banner": "OLD GREYMANE HOWLS: the pack's alpha turns his wolves into beasts!",  # Owner-approved proposal (miniboss); 9:00 left like the Gatekeeper
		"kind": "old_greymane", "pack": 3, "elite": false},
	# Zone IV (12:45): the Wolfwood.
	{"time": 800.0, "type": "wave", "banner": "The pack hunts among the pines!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "werewolf", "count": 2, "elite": false}, {"kind": "ghoul", "count": 4, "elite": false}, {"kind": "blood_knight", "count": 3, "elite": false}]},
	{"time": 900.0, "type": "wave", "banner": "A noble and her bats!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vampire_noble", "count": 1, "elite": false}, {"kind": "vampire_bat", "count": 10, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The Court gathers for its feast!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "blood_knight", "count": 5, "elite": false}, {"kind": "ghoul", "count": 4, "elite": false}, {"kind": "blood_thrall", "count": 10, "elite": false}]},
	# 17:00 Vargr (BOSS_TIME).
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative; each starts as a Blood Moon
## sets). Keys as CrimsonMarchStage.ZONES (MarchDirector). `ground` is a
## RavensmoorGround look:
##   style  — "moor" (dark heather and peat), "village" (a trodden mud lane and
##            cobbles), "old_church" (the churchyard's sunken flagstones) or
##            "wolfwood" (pine needles and roots).
##   base / line / accent / trim — colours of the code floor, its marks, its
##            stones and its red leaves.
## Obstacle kinds (RavensmoorGlyphs without art; obstacles/<kind>_<size>[_v]):
##   moor_cairn    — a heap of grey moor stones (circle)
##   moor_pine    — a black, wind-bent moor pine (circle; not Kurogane's black_pine)
##   grave_cross   — a leaning stone cross of the churchyard (circle)
##   village_fence — a rotten wooden fence (rect)
##   thatch_cottage — a thralls' cottage, sagging thatch (rect)
##   church_ruin   — a broken wall of the old church (rect)
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Moor",  # Owner-approved proposal (zones)
		"blurb": "Heather and peat under a low, cold moon",
		"ground": {"style": "moor", "base": Color(0.13, 0.11, 0.14), "line": Color(0.09, 0.07, 0.10),
			"accent": Palette.COURT_MOON_DARK, "trim": Palette.COURT_BLOOD_DARK},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 1919,  # TUNING (not in GDD)
			"kinds": {
				"moor_cairn": {"weight": 0.7, "shape": "circle", "sizes": [12.0, 16.0, 20.0]},  # TUNING (not in GDD)
				"moor_pine": {"weight": 0.3, "shape": "circle", "sizes": [14.0, 18.0]},  # TUNING (not in GDD)
			}}},
	{"start": 285.0, "numeral": "II", "name": "The Village",  # Owner-approved proposal (zones)
		"blurb": "The cottages of the turned, their lamps still lit",
		"ground": {"style": "village", "base": Color(0.14, 0.12, 0.11), "line": Color(0.09, 0.07, 0.07),
			"accent": Color(0.30, 0.27, 0.27), "trim": Palette.COURT_BLOOD_DARK},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 1929,  # TUNING (not in GDD) lanes between the cottages
			"kinds": {
				"thatch_cottage": {"weight": 0.4, "shape": "rect", "sizes": [56.0, 72.0], "short": 30.0},  # TUNING (not in GDD)
				"village_fence": {"weight": 0.35, "shape": "rect", "sizes": [44.0, 56.0], "short": 12.0},  # TUNING (not in GDD)
				"moor_cairn": {"weight": 0.25, "shape": "circle", "sizes": [12.0, 16.0, 20.0]},  # TUNING (not in GDD)
			}}},
	{"start": 525.0, "numeral": "III", "name": "The Old Church",  # Owner-approved proposal (zones)
		"blurb": "The ruined church and the graves the Court emptied",
		"ground": {"style": "old_church", "base": Color(0.13, 0.13, 0.15), "line": Color(0.08, 0.08, 0.10),
			"accent": Palette.COURT_MOON_DARK, "trim": Palette.COURT_BLOOD},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 1939,  # TUNING (not in GDD)
			"kinds": {
				"church_ruin": {"weight": 0.35, "shape": "rect", "sizes": [56.0, 72.0], "short": 18.0},  # TUNING (not in GDD)
				"grave_cross": {"weight": 0.65, "shape": "circle", "sizes": [10.0, 13.0]},  # TUNING (not in GDD)
			}}},
	{"start": 765.0, "numeral": "IV", "name": "The Wolfwood",  # Owner-approved proposal (zones)
		"blurb": "Black pines where the pack runs",
		"ground": {"style": "wolfwood", "base": Color(0.11, 0.12, 0.12), "line": Color(0.07, 0.08, 0.08),
			"accent": Color(0.24, 0.22, 0.20), "trim": Palette.COURT_BLOOD_DARK},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 1949,  # TUNING (not in GDD)
			"kinds": {
				"moor_pine": {"weight": 0.7, "shape": "circle", "sizes": [14.0, 18.0]},  # TUNING (not in GDD)
				"moor_cairn": {"weight": 0.3, "shape": "circle", "sizes": [12.0, 16.0, 20.0]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "RAVENSMOOR  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(0.878, 0.220, 0.306),  # Blood light (Palette.COURT_BLOOD_LIGHT), never the UI's soul-teal.
	"fog_color": Color(0.10, 0.09, 0.12),  # Moor mist at night.
	"fog_bank_color": Color(0.36, 0.38, 0.44),  # Moonlit mist banks.
	"zones": ZONES,
}

## Ravensmoor's stage systems (RavensmoorDirector; StageRegistry "ravensmoor").
##   coffins            — the sleeping coffin waves, one per zone just after
##                        it starts (so each has one Blood Moon to beat):
##                        {time (s), count, banner}.
##   coffin_dist_min / coffin_dist_max — px from the necromancer they lie
##                        (alternating).
##   coffin_bounty      — Soul Ash per coffin broken while closed (the run
##                        stat objective_ash).
##   coffins_open_banner — banner when the moon opens the ones left whole.
##   nails_banner       — banner when Coffin Nails is earned.
##   ghoul_packs        — {from (s), every (s), count}: a pack of ghouls on
##                        the spawn ring (until 0:00).
##   greymane_objective — HUD objective while Old Greymane stands.
const RAVENSMOOR := {
	"coffins": [
		{"time": 20.0, "count": 2, "banner": "Sleeping coffins lie on the moor: break them before the Blood Moon!"},  # TUNING (not in GDD)
		{"time": 290.0, "count": 2, "banner": "Coffins sleep in the village: break them before the next moon!"},  # TUNING (not in GDD)
		{"time": 530.0, "count": 2, "banner": "Coffins sleep in the churchyard: break them before the moon!"},  # TUNING (not in GDD)
		{"time": 770.0, "count": 2, "banner": "Coffins sleep among the pines: the last moon is coming!"},  # TUNING (not in GDD)
	],
	"coffin_dist_min": 240.0,  # TUNING (not in GDD) px
	"coffin_dist_max": 340.0,  # TUNING (not in GDD) px
	"coffin_bounty": 6,  # TUNING (not in GDD) Soul Ash each (8 coffins: 48, about a tenth of a good run's ~450)
	"coffins_open_banner": "The coffins open under the Blood Moon: the nobles climb out!",  # TUNING (not in GDD)
	"nails_banner": "COFFIN NAILS: not one coffin of Ravensmoor opened!",  # TUNING (not in GDD)
	"ghoul_packs": {"from": 150.0, "every": 45.0, "count": 4},  # Owner-approved proposal: "packs of 4"; timing TUNING (not in GDD)
	"greymane_objective": "Bring down Old Greymane before his howls turn the whole pack",  # TUNING (not in GDD)
}

## Vargr's arrival (keys as GraveyardStage.BOSS): his own VargrData.ARRIVAL
## (boss id "vargr"), whose `time` equals BOSS_TIME (17:00). His script is
## scripts/enemies/court/boss_vargr.gd (loaded by his id).
const BOSS: Dictionary = VargrData.ARRIVAL

## Placeholder floor of the foundation stub (CourtGround "floor" key), kept
## for the other tools that read it; the stage draws RavensmoorGround ("ground").
const FLOOR := {
	"style": "moor",  # Dark heather and peat, grey moor stones, red leaves.
	"base": Color(0.13, 0.12, 0.13),  # TUNING (not in GDD) dark heather and peat
	"line": Color(0.17, 0.15, 0.16),  # TUNING (not in GDD)
	"accent": Palette.COURT_MOON_DARK,  # TUNING (not in GDD) grey moor stones
	"trim": Palette.COURT_BLOOD,  # TUNING (not in GDD) red leaves
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Ravensmoor",
	"short_name": "Ravensmoor",
	"chapter": "Chapter XIX",
	"act": 7,  # Act VII, the Sanguine Court.
	"playable": false,  # Phase 2 built; hidden until the lead's integration and the owner's review (brief: keep "playable": false).
	"description": "A cursed village on the moors below the Court's castle, its people long since turned to thralls: here the starving Court first comes for the necromancer who emptied its table.",
	"unlock": {"stage": "pandemonium", "boss_kills": 1},  # Owner-approved: the Morning Star's fall opens Act VII
	"unlock_text": "Cast down the Morning Star in Pandemonium to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act VII stages.
	"consecration": {},  # A Covenant event: none in Act VII.
	"crypt_defender": {},  # None in Act VII.
	"arena": ZONES[0]["arena"],
	"ground": "ravensmoor",  # RavensmoorGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"ravensmoor": RAVENSMOOR,  # RavensmoorDirector: the sleeping coffins, Coffin Nails, the ghoul packs, Old Greymane.
	"court": true,  # Act VII: Bloodfeast, Night Wings, the Blood Moon (CourtRules).
	"moon": MOON,  # Act VII: this stage's Blood Moon overrides ({} = the defaults).
	"zones": ZONES,  # Act VII: the four zones.
	# Music: "Waltz of the Red Moon" (SoundData.SANGUINE_SCORE).
	"music": "sanguine",
}
