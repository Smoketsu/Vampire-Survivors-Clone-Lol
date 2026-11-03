## CrashSiteStage — STAGE 25, THE CRASH SITE (Act IX, the Concord of Stars;
## GDD §15.0 "Act IX foundation (phase 1)", owner-approved proposal
## docs/act9/PROPOSAL.md "Stage 25: The Crash Site"). A Harvester scout ship
## lies broken in the ruins of the capital, and the Brood is hatching from it.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: LIVE (GDD §15.0 "The Crash Site (Act IX phase 2)", "Acts VI–IX
## go live"). Unlocked in the campaign chain
## (Paragon's fall at Liberty Heights opens it); it runs the Concord's three
## shared rules ("concord": true: Beams, Abduction and Terraforming) with the
## Brood leading the timeline (broodlings, the Burrower, the Acid Spitter; the
## Harvesters, a Vrask hunter now and then and the Luminous mixed in: owner,
## one coalition), and its own systems (CrashSiteDirector, STAGE
## "crash_site"): the crater's turf seeded at the start, INFESTATION (owner
## answer, Nov 3, 2026: an egg where every Concord enemy falls, cleared by any
## hit, else a broodling hatches), NOTHING HATCHED, the Brood Matriarch (the
## miniboss, at 10:30). Its boss is the Hive Mother (BossHiveMother: the
## Brood, the Burrow, the Flight). The Final Harvest is its Reckoning (the
## mothership's eye opens over the arena, saucers fill the sky, the abduction
## cap is gone).
## Zones (ZONES; clock-driven, MarchDirector): the Crater, the Hatchery, the
## Wreck, the Glass Spire.
## The Hive Mother arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD).
class_name CrashSiteStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "crash_site"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act IX starts a step above Liberty Heights's 2.0; the step goes in HP, not
## damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 2.15  # TUNING (not in GDD) brief: a step above Liberty Heights (placeholder, tuned in the balance pass)
## Enemy damage multiplier of this stage on top of the shared time scaling
## (Liberty Heights's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Acts III to VIII: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 1 of Act IX

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven, MarchDirector): its floor look ("ground": a
## CrashSiteGround style over the ruins, the zone's floor tile
## tiles/crash_site_<style>) and its obstacle layout ("arena"):
##   crater      — the Crater: glassed black rock round the scout ship's
##                 impact, rubble and torn hull shards (the crater's live turf
##                 is seeded at the start, CrashSiteDirector).
##   hatchery    — the Hatchery: green-black resin over the paving, where the
##                 Brood hatches; rubble mounds.
##   wreck       — the Wreck: the scout ship's buckled hull plates; hull shards.
##   ruins       — the Glass Spire: the capital's broken paving round a
##                 glassed spire; tall glass shards and rubble.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Crater", "id": "crater",  # Owner-approved proposal (zones)
		"blurb": "Glassed rock round the broken scout ship",
		"ground": {"style": "crater", "base": Color(0.10, 0.10, 0.12), "line": Color(0.16, 0.15, 0.18),
			"accent": Palette.CONCORD_GUNMETAL, "trim": Palette.CONCORD_PLASMA_DARK},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 2525,  # TUNING (not in GDD)
			"kinds": {
				"crash_rubble": {"weight": 0.6, "shape": "circle", "sizes": [12.0, 16.0, 20.0]},  # TUNING (not in GDD)
				"crash_hull_shard": {"weight": 0.4, "shape": "rect", "sizes": [24.0, 32.0], "short": 12.0},  # TUNING (not in GDD)
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Hatchery", "id": "hatchery",  # Owner-approved proposal (zones)
		"blurb": "Resin over the paving, where the Brood hatches",
		"ground": {"style": "hatchery", "base": Color(0.09, 0.12, 0.10), "line": Color(0.06, 0.08, 0.07),
			"accent": Palette.CONCORD_CHITIN_LIGHT, "trim": Palette.CONCORD_PLASMA_DARK},
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 2535,  # TUNING (not in GDD)
			"kinds": {
				"crash_rubble": {"weight": 0.75, "shape": "circle", "sizes": [12.0, 16.0, 20.0]},  # TUNING (not in GDD)
				"crash_hull_shard": {"weight": 0.25, "shape": "rect", "sizes": [24.0, 32.0], "short": 12.0},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Wreck", "id": "wreck",  # Owner-approved proposal (zones)
		"blurb": "The scout ship's buckled hull",
		"ground": {"style": "wreck", "base": Color(0.17, 0.18, 0.20), "line": Color(0.11, 0.12, 0.14),
			"accent": Palette.CONCORD_HULL_SHADE, "trim": Palette.CONCORD_PLASMA_DARK},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 2545,  # TUNING (not in GDD)
			"kinds": {
				"crash_hull_shard": {"weight": 0.65, "shape": "rect", "sizes": [24.0, 32.0], "short": 12.0},  # TUNING (not in GDD)
				"crash_rubble": {"weight": 0.35, "shape": "circle", "sizes": [12.0, 16.0, 20.0]},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Glass Spire", "id": "glass_spire",  # Owner-approved proposal (zones)
		"blurb": "The capital's broken paving round a spire of glass",
		"ground": {"style": "ruins", "base": Color(0.14, 0.14, 0.16), "line": Color(0.19, 0.19, 0.21),
			"accent": Palette.CONCORD_GUNMETAL, "trim": Palette.CONCORD_LUMEN},
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 2555,  # TUNING (not in GDD)
			"kinds": {
				"glass_spire": {"weight": 0.5, "shape": "circle", "sizes": [10.0, 14.0]},  # TUNING (not in GDD)
				"crash_rubble": {"weight": 0.5, "shape": "circle", "sizes": [12.0, 16.0, 20.0]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 220.0,  # TUNING (not in GDD)
	"zone_title": "THE CRASH SITE  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(0.235, 1.0, 0.416),  # Plasma green (Palette.CONCORD_PLASMA), never the UI's soul-teal.
	"fog_color": Color(0.08, 0.09, 0.10),  # Smoke over the ruins.
	"fog_bank_color": Color(0.30, 0.34, 0.30),  # Green-lit smoke banks.
	"zones": ZONES,
}

## The Crash Site's stage systems (CrashSiteDirector; StageRegistry "crash_site").
##   crater          — the crater's live turf seeded at the start
##                     (Terraforming.seed(), tag "crater"): {offset (px from
##                     the necromancer's start), radius (px)}.
##   egg_cap         — most Infestation eggs alive at once (brief: for example
##                     24; over it no egg is laid, counted as skipped).
##   matriarch_objective — HUD objective while the Brood Matriarch stands.
##   nothing_hatched_limit — most Infestation eggs that may hatch before the
##                     Hive Mother falls for Nothing Hatched still to be earned
##                     (eggs, >= 0; owner, Act IX playtest pass 1: "at most 10";
##                     it was 0, no egg at all).
##   nothing_hatched_banner — banner when Nothing Hatched is earned.
const CRASH_SITE := {
	"crater": {"offset": Vector2(0.0, -420.0), "radius": 200.0},  # TUNING (not in GDD) the crater north of the start, out of the clear circle
	"egg_cap": 24,  # TUNING (not in GDD) brief: "for example 24"
	"matriarch_objective": "Bring down the Brood Matriarch: clear her eggs before they hatch",  # TUNING (not in GDD)
	"nothing_hatched_limit": 10,  # TUNING (not in GDD) owner decision Nov 2026, Act IX playtest pass 1 (was 0: no egg hatched)
	"nothing_hatched_banner": "NOTHING HATCHED: the Brood's eggs were burned before they broke open!",  # TUNING (not in GDD)
}

## Terraforming on this stage: {} = the defaults of
## ConcordRulesData.TERRAFORMING (any of its keys overrides them here).
const TERRAFORMING := {}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the FINAL
## HARVEST, shared by every Act IX stage: the mothership's eye opens over the
## arena and sweeps it with its beam, saucers fill the sky ("kind": the
## saucer, with the shared kinds as companions), and the abduction cap is gone
## ("final_harvest": ConcordRulesData.FINAL_HARVEST keys; {} = those
## defaults). The pods keep falling.
const RECKONING := {
	"banner": "THE FINAL HARVEST: THE MOTHERSHIP OPENS ITS EYE",
	"kind": ConcordEnemyData.RECKONING_KIND,  # The shared Final Harvest heavy (the saucer).
	"final_harvest": {},  # ConcordRulesData.FINAL_HARVEST defaults (phase 2 may tune them here).
	"companions": ConcordEnemyData.RECKONING_COMPANIONS,  # Broodlings, grey drones, a Vrask hunter, a Lumen Sentinel.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) saucers
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE FINAL HARVEST: the eye sweeps the world, and the saucers take your dead. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): the Brood
## leads (broodlings, Burrowers, Acid Spitters: over three quarters of the
## weight from 3:00), the Harvesters' grey drones and saucers, a Vrask hunter
## now and then and the Luminous mixed in (owner: one coalition). Saucers and
## hunters stay rare (elites).
const SEGMENTS := [
	# Zone I, the Crater.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"broodling": 1.0},
		"objective": "The Crater: the Brood swarms out of the wreck. Clear the eggs where they fall"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"broodling": 0.7, "grey_drone": 0.2, "burrower": 0.1},
		"objective": "A mound of dirt in your ring: a Burrower bursts up there. Keep blockers inside the ring"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"broodling": 0.56, "burrower": 0.1, "acid_spitter": 0.08, "grey_drone": 0.17, "lumen_sentinel": 0.06, "prism": 0.03},
		"objective": "Acid Spitters lob over your ring: kill them on approach, and step out of the puddles"},
	# Zone II, the Hatchery (5:00).
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"broodling": 0.54, "burrower": 0.11, "acid_spitter": 0.09, "grey_drone": 0.14, "lumen_sentinel": 0.06, "prism": 0.025, "vrask_hunter": 0.02, "saucer": 0.015},
		"objective": "The Hatchery: every Concord death leaves an egg. Any spell or blow clears it"},
	{"start": 420.0, "rate": 2.5, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"broodling": 0.53, "burrower": 0.11, "acid_spitter": 0.1, "grey_drone": 0.14, "lumen_sentinel": 0.06, "prism": 0.025, "vrask_hunter": 0.02, "saucer": 0.015},
		"objective": "Saucers take your dead. Shoot them down with Archers, Gargoyles and spells"},
	# Zone III, the Wreck (10:00): the Brood Matriarch at 10:30.
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"broodling": 0.5, "burrower": 0.12, "acid_spitter": 0.1, "grey_drone": 0.14, "lumen_sentinel": 0.065, "prism": 0.03, "vrask_hunter": 0.025, "saucer": 0.02},
		"objective": "The Wreck: the alien ground heals the Concord. Burn it back with your spells"},
	# Zone IV, the Glass Spire (15:00).
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"broodling": 0.49, "burrower": 0.12, "acid_spitter": 0.1, "grey_drone": 0.14, "lumen_sentinel": 0.07, "prism": 0.03, "vrask_hunter": 0.03, "saucer": 0.02},
		"objective": "The Glass Spire: the whole coalition comes for your dead"},
	# 17:00, the boss: thinner, so the fight is the queen.
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"broodling": 0.62, "burrower": 0.03, "acid_spitter": 0.05, "grey_drone": 0.16, "lumen_sentinel": 0.07, "prism": 0.03, "vrask_hunter": 0.02, "saucer": 0.02},  # first pass burrower 0.06, acid_spitter 0.08 (she brings her own burrowers and acid)
		"objective": "The Hive Mother has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Broodlings come in
## swarms of 12 (owner-approved proposal), grey drones in squads, plus the
## Crash Site's own (CrashSiteDirector):
##   "matriarch" — the Brood Matriarch (kind `kind`) flies in on the spawn ring
##                 with an `escort` (groups of {kind, count}); the stage
##                 miniboss.
const EVENTS := [
	# Zone I: the Crater.
	{"time": 20.0, "type": "wave", "banner": "The Brood pours out of the crashed ship!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "Mounds of dirt rise around you: Burrowers!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "burrower", "count": 3, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 150.0, "type": "wave", "banner": "A squad of grey drones raises its probes!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "grey_drone", "count": 5, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 220.0, "type": "wave", "banner": "Acid Spitters! Their acid arcs over your ring!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "acid_spitter", "count": 3, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 270.0, "type": "wave", "banner": "The Luminous! A Star-Seer splits their beams!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "lumen_sentinel", "count": 1, "elite": false}, {"kind": "prism", "count": 1, "elite": false}, {"kind": "grey_drone", "count": 4, "elite": false}]},
	# Zone II: the Hatchery.
	{"time": 330.0, "type": "wave", "banner": "The Hatchery wakes: two swarms at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "broodling", "count": 12, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}, {"kind": "burrower", "count": 2, "elite": false}]},
	{"time": 400.0, "type": "wave", "banner": "A saucer drifts over your ring! Shoot it down before it takes your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "saucer", "count": 1, "elite": false}, {"kind": "acid_spitter", "count": 2, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 470.0, "type": "wave", "banner": "A shimmer in the ruins: a Vrask hunter stalks you!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vrask_hunter", "count": 1, "elite": false}, {"kind": "burrower", "count": 3, "elite": false}]},
	{"time": 540.0, "type": "wave", "banner": "Burrowers from every side!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "burrower", "count": 4, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	# Zone III: the Wreck.
	{"time": 630.0, "type": "matriarch", "banner": "THE BROOD MATRIARCH! Her egg sacs fall into your ring: clear them before they hatch!",  # Owner-approved proposal (miniboss); 9:30 left
		"kind": "brood_matriarch", "elite": false,
		"escort": [{"kind": "broodling", "count": 12}, {"kind": "acid_spitter", "count": 2}]},  # TUNING (not in GDD)
	{"time": 720.0, "type": "wave", "banner": "The Luminous line their beams up!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "lumen_sentinel", "count": 2, "elite": false}, {"kind": "prism", "count": 1, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 800.0, "type": "wave", "banner": "Saucers over the Wreck!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "saucer", "count": 2, "elite": false}, {"kind": "grey_drone", "count": 5, "elite": false}, {"kind": "acid_spitter", "count": 2, "elite": false}]},
	# Zone IV: the Glass Spire.
	{"time": 930.0, "type": "wave", "banner": "The whole coalition comes!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "broodling", "count": 12, "elite": false}, {"kind": "burrower", "count": 3, "elite": false}, {"kind": "lumen_sentinel", "count": 1, "elite": false}, {"kind": "vrask_hunter", "count": 1, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The swarm thickens before its queen!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "broodling", "count": 12, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}, {"kind": "acid_spitter", "count": 2, "elite": false}]},
]

## The Hive Mother's arrival (keys as GraveyardStage.BOSS): her own
## HiveMotherData.ARRIVAL (boss id "hive_mother"), whose `time` equals
## BOSS_TIME (17:00). Her script is scripts/enemies/concord/boss_hive_mother.gd
## (loaded by her id).
const BOSS: Dictionary = HiveMotherData.ARRIVAL

## Placeholder floor of the foundation stub (ConcordGround "floor" key), kept
## for the other tools that read it; the stage draws CrashSiteGround ("ground").
const FLOOR := {
	"style": "ruins",  # The capital's broken paving, glass and scorch marks round the crater.
	"base": Color(0.14, 0.14, 0.16),  # TUNING (not in GDD) ash-grey paving
	"line": Color(0.19, 0.19, 0.21),  # TUNING (not in GDD)
	"accent": Palette.CONCORD_GUNMETAL,  # TUNING (not in GDD) scattered hull shards
	"trim": Palette.CONCORD_PLASMA_DARK,  # TUNING (not in GDD) spilt plasma
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Crash Site",
	"short_name": "Crash Site",
	"chapter": "Chapter XXV",
	"act": 9,  # Act IX, the Concord of Stars.
	"playable": true,  # Owner decision (Nov 2026): "Ship it" after the art reviews and playtest passes (GDD §15.0 "Acts VI–IX go live").
	"description": "A Harvester scout ship lies broken in the ruins of the capital, and the Brood is hatching from it: the Concord has come to find out why the dead no longer rise for its harvest.",
	"unlock": {"stage": "liberty_heights", "boss_kills": 1},  # Brief: Paragon's fall opens Act IX
	"unlock_text": "Defeat Paragon at Liberty Heights to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act IX stages.
	"consecration": {},  # A Covenant event: none in Act IX.
	"crypt_defender": {},  # None in Act IX.
	"arena": ZONES[0]["arena"],
	"ground": "crash_site",  # CrashSiteGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"crash_site": CRASH_SITE,  # CrashSiteDirector: the crater, Infestation's eggs, Nothing Hatched, the Brood Matriarch.
	"concord": true,  # Act IX: Beams, Abduction, Terraforming (ConcordRules).
	"terraforming": TERRAFORMING,  # Act IX: this stage's Terraforming overrides ({} = the defaults).
	"zones": ZONES,  # Act IX: the four zones.
	# Music: "The Reaping Stars" (SoundData.STARSONG_SCORE).
	"music": "starsong",
}
